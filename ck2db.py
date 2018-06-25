#!/usr/bin/env python3
# Frederick Hornsey
# CS 434
# Summer 2018

# Loads is loading data from file and/or another datasource
# Stores is taking that info and putting it in the database
# Imports is loading and then storing data

import sys
import os
import _mysql_exceptions
import subprocess
from pathlib import Path
import json
from inspect import formatargspec, getfullargspec
import collections

ck2_path = Path(os.getenv('HOME')) / ".steam/steam/steamapps/common/Crusader Kings II"

def read_json(path):
    '''Load Json, specifically from ck2json'''
    with open(path, encoding='iso8859_10', errors='replace') as f:
        return json.load(f)

def connect(user, password):
    '''Return connection to database
    '''
    import MySQLdb

    # Ignore Warnings because all are from INSERT IGNORE
    from warnings import filterwarnings
    filterwarnings('ignore', category = MySQLdb.Warning)

    db = MySQLdb.connect(user=user, passwd=password)
    c = db.cursor()
    return db, c

def execute_sql_file(cursor, filepath):
    '''Pull SQL Commands from a file and execute them
    '''
    with open(filepath, 'r') as sql:
        statements = ' '.join(sql.readlines()).split(';')
        for line in statements:
            if not line.isspace():
                c.execute(line)

def remove_from_dict(d, *keys):
    for k in keys:
        try:
            del d[k]
        except:
            pass

def get_str_else(d, k, default):
    return '"{}"'.format(d[k]) if k in d else default

def yield_all(it):
    for i in it.values():
        yield i

def store(c, save, get_next, sql, defer=False):
    if not defer:
        for row in get_next(save):
            try:
                c.execute(sql, row)
            except Exception as e:
                print("\nrow is", row, file=sys.stderr)
                raise e
        return
    deferred_rows = []
    for row in get_next(save):
        try:
            c.execute(sql, row)
        except _mysql_exceptions.IntegrityError as e:
            deferred_rows.insert(0, row)
        except Exception as e:
            print("\nrow is", row, file=sys.stderr)
            raise e
    last_size = len(deferred_rows)
    deferred_rows.insert(0, None)
    while True:
        row = deferred_rows.pop()
        if row is None:
            current_size = len(deferred_rows)
            if current_size == last_size and current_size > 0:
                sys.exit("Could not defer all the rows")
            elif current_size:
                last_size = len(deferred_rows)
                deferred_rows.insert(0, None)
                continue
            else:
                break
        try:
            c.execute(sql, row)
        except _mysql_exceptions.IntegrityError as e:
            deferred_rows.insert(0, row)
        except Exception as e:
            print("\nrow is", row, file=sys.stderr)
            raise e

def load_loc():
    '''Load Game Localization, allowing us to convert name internal to the
    game into the actual names, or at least what the game displays for
    English.
    '''
    import csv
    locdb = {}
    for csv_file in ck2_path.glob('localisation/**/*.csv'):
        with csv_file.open(encoding='iso8859_10', errors='replace') as f:
            csv_data = csv.reader(f, delimiter=';')
            for row in csv_data:
                if len(row) >= 2:
                    locdb[row[0]] = row[1]
    return locdb

def yield_id_and_names(values):
    for i, n in values.items():
        yield {'id': i, 'name': n}

def load_cultures(loc):
    '''Return dict of id string to name string of Cultures'''
    culture_groups = {}
    for cul_file in ck2_path.glob('common/cultures/**/*.txt'):
        culture_groups.update(json.loads(
            subprocess.check_output(["./ck2json", str(cul_file)]).decode("utf-8")))
    cultures = {}
    for group in culture_groups.values():
        for culture in group.keys():
            cultures[culture] = loc.get(culture, culture)
    remove_from_dict(cultures, 'graphical_cultures')
    return cultures

def store_cultures(db, c, cultures):
    '''Store cultures in database'''
    store(c, cultures, yield_id_and_names,
        'insert into Cultures (id, name) values (%(id)s, %(name)s)')
    return len(cultures)

def load_religions(loc):
    '''Return dict of id string to name string of Religions'''
    religion_groups = {}
    for p in ck2_path.glob('common/religions/**/*.txt'):
        religion_groups.update(json.loads(
            subprocess.check_output(["./ck2json", str(p)]).decode("utf-8")))
    religions = {}
    for group in religion_groups.values():
        for religion in group.keys():
            religions[religion] = loc.get(religion, religion)
    remove_from_dict(religions,
        'has_coa_on_barony_only', 'graphical_culture', 'crusade_cb',
        'playable', 'ai_peaceful', 'ai_convert_same_group',
        'ai_convert_other_group', 'color', 'male_names', 'female_names',
        'ai_fabricate_claims', 'hostile_within_group', 'secret_religion'
    )
    return religions

def store_religions(db, c, religions):
    '''Store religions in database'''
    store(c, religions, yield_id_and_names,
        'insert into Religions (id, name) values (%(id)s, %(name)s)')
    return len(religions)

def char_key_stats(save):
    def dict_inc(d, key, inc=1):
        if key in d:
            d[key] += inc
        else:
            d[key] = 1

    num_chars = len(save['character'])
    all_keys = set()
    key_totals = {}
    key_max = {}
    for cid, cdict in save['character'].items():
        keys_this_char = {}
        for k in cdict.keys():
            all_keys = all_keys | {k}
            if k not in keys_this_char:
                dict_inc(key_totals, k)
            dict_inc(keys_this_char, k)
        for k, v in keys_this_char.items():
            if k in key_max:
                if v > key_max[k]:
                    key_max[k] = v
            else:
                key_max[k] = v

    print("all keys ============================================================")
    print(all_keys)
    print("key totals ============================================================")
    print("Num chars:", num_chars)
    sort = []
    for k, v in key_totals.items():
        sort.append((k, v))
    sort = sorted(sort, key = lambda i: i[1])
    for k, v in sort:
        print(k, "ALL" if v == num_chars else v)
    print("key max ============================================================")
    for k, v in key_max.items():
        if v > 1:
            print(k, v)

def load_save(path):
    print('Reading', path, '...', end='')
    sys.stdout.flush()
    save = read_json(path)
    print(' DONE', save['date'])
    return save

def load_fixed_characters():
    characters = {}
    for f in ck2_path.glob('history/characters/**/*.txt'):
        try:
            characters.update(json.loads(
                subprocess.check_output(["./ck2json", str(f)]).decode("utf-8")))
        except Exception as e:
            print('File is', str(f), file=sys.stderr)
            raise e
    return characters

def int_or_none(value):
    if value is None:
        return None
    return int(value)

def load_characters(save, fixed):
    characters = {}
    for cid, cdict in save['character'].items():

        # Character
        r = {'id': int(cid), 'birth': cdict['b_d'], 'real_father_id': None}
        if 'fat' in cdict:
            r['real_father_id'] = int_or_none(cdict['fat'])
        if 'rfat' in cdict:
            r['real_father_id'] = int_or_none(cdict['rfat'])
        r['death'] = cdict.get('d_d', None)
        r['is_female'] = 'fem' in cdict and cdict['fem']
        r['mother_id'] = int_or_none(cdict.get('mot', None))

        # Character Status
        r['character_id'] = int(cid)
        r['date'] = save['date']
        r['name'] = cdict.get('bn', '')
        r['health'] = cdict.get('health', 0.0)
        r['wealth'] = cdict.get('wealth', 0.0)
        r['piety'] = cdict.get('piety', 0.0)
        r['prestige'] = cdict.get('prs', 0.0)
        if 'att' in cdict:
            r['diplomacy'] = cdict['att'][0]
            r['martial'] = cdict['att'][1]
            r['stewardship'] = cdict['att'][2]
            r['intrigue'] = cdict['att'][3]
            r['learning'] = cdict['att'][4]
        else:
            r['diplomacy'] = 0
            r['martial'] = 0
            r['stewardship'] = 0
            r['intrigue'] = 0
            r['learning'] = 0
        r['dynasty_id'] = int_or_none(cdict.get('dnt', None))
        # culture = None
        # if 'cul' in cdict:
        #     culture = cdict['cul']
        # elif cid in fixed:
        #     culture = fixed[cid].get('culture', None)
        # r['culture_id'] = culture
        # religion = None
        # if 'rel' in cdict:
        #     religion = cdict['rel']
        # elif cid in fixed:
        #     religion = fixed[cid].get('religion', None)
        # if religion == "noreligion":
        #     religion = None
        # r['religion_id'] = religion
        r['traits'] = cdict.get('traits', [])
        r['perceived_father_id'] = int_or_none(cdict.get('fat', None))
        r['spouse_id'] = cdict.get('spouse', [])

        characters[cid] = r
    return characters

character_status_fields = (
    'character_id', 'date', 'name',
    'health', 'wealth', 'piety', 'prestige',
    'diplomacy', 'martial', 'stewardship', 'intrigue', 'learning',
    'dynasty_id',
    # 'culture_id', 'religion_id',
    'perceived_father_id'
)
character_status_sql = 'insert into Character_Status ({}) values ({})'.format(
    ', '.join(character_status_fields),
    ', '.join(['%(' + f + ')s' for f in character_status_fields])
)

def insert_marriage(c, date, this_is_female, this_id, other_id):
    row = (
        other_id if this_is_female else this_id,
        this_id if this_is_female else other_id,
        date
    )
    try:
        c.execute("""
            insert into Marriages (husband_id, wife_id, date)
                values (%s, %s, %s)
                on duplicate key update date=date""",
            row
        )
    except Exception as e:
        print(row, file=sys.stderr)
        raise e

def remove_dead(characters):
    # Ignore Dead Characters
    alive = {}
    for cid, cdict in characters.items():
        if cdict['death'] is None:
            alive[cid] = cdict
    characters = alive

    # Ignore Dead Spouses
    new_dict = {}
    for cid, cdict in characters.items():
        spouses = []
        spouse_ids = cdict.get('spouse_id', [])
        if spouse_ids:
            if type(spouse_ids) is list:
                for spouse_id in spouse_ids:
                    if str(spouse_id) in characters:
                        spouses.append(spouse_id)
            else:
                if str(spouse_ids) in characters:
                    spouses = [spouse_ids]
        cdict['spouse_id'] = spouses
        new_dict[cid] = cdict

    return characters

def store_characters(c, characters):

    # Character
    print('    Basic Character Information...',end='')
    sys.stdout.flush()
    store(c, characters, yield_all, '''
        insert into Characters (id, birth, death, is_female, mother_id, real_father_id)
            values (%(id)s, %(birth)s, %(death)s, %(is_female)s,
                %(mother_id)s, %(real_father_id)s)
            on duplicate key update death=death
    ''', defer=True)
    print(' DONE')

    characters = remove_dead(characters)

    # Character Status
    print('    Temporal Character Information...',end='')
    sys.stdout.flush()
    store(c, characters, yield_all, character_status_sql)
    print(' DONE')

    # Marriages
    print('    Marriages...',end='')
    sys.stdout.flush()
    for character in characters.values():
        for spouse_id in character['spouse_id']:
            insert_marriage(c, character['date'],
                character['is_female'], character['id'], spouse_id)
    print(' DONE')

    # Traits
    print('    Traits...',end='')
    sys.stdout.flush()
    for character in characters.values():
        traits = character.get('traits', [])
        for trait in traits:
            c.execute('''insert
                into Character_Traits (character_id, date, trait_id)
                values (%s, %s, %s)''', (character['id'], character['date'], trait))
    print(' DONE')

    return len(characters)

def load_titles(save, loc):

    titles = {}
    for title_id, title in save['title'].items():
        titles[title_id] = {
            'holder_id': title.get('holder', None),
            'name': title.get('name', loc.get(title_id, title_id)),
            'de_jure': title.get('de_jure_liege', None),
            'de_facto': title.get('liege', None),
        }

    return titles

def store_titles(c, titles):
    for tid, tdict in titles.items():
        prefix = tid[0]
        if prefix == "b":
            pass
        elif prefix == "c":
            pass
        elif prefix == "d":
            pass
        elif prefix == "k":
            pass
        elif prefix == "e":
            pass

def load_game_dynasties():
    '''Return dict of id string to name string of Dynasties from gamedata'''

    fulldynasties = {}
    for f in ck2_path.glob('common/dynasties/**/*.txt'):
        fulldynasties.update(json.loads(
            subprocess.check_output(["./ck2json", str(f)]).decode("utf-8")))

    dynasties = {}
    for did, dinfo in fulldynasties.items():
        dynasties[int(did)] = dinfo.get('name', "")

    return dynasties

def load_save_dynasties(save):
    '''Return dict of id string to name string of Dynasties from save data'''

    dynasties = {}
    for did, dinfo in save['dynasties'].items():
        if 'name' in dinfo:
            dynasties[int(did)] = dinfo['name']
    return dynasties

def store_dynasties(c, dynasties):
    '''Store dynasties in database'''

    store(c, dynasties, yield_id_and_names, '''
        insert into Dynasties(id, name)
            values (%(id)s, %(name)s)
            on duplicate key update id=id
    ''')

    return len(dynasties)

def load_traits(loc):
    traits = []

    for f in sorted(ck2_path.glob('common/traits/**/*.txt')):
        traits.extend(json.loads(
            subprocess.check_output(["./ck2json", str(f)]).decode("utf-8"),
            object_pairs_hook=collections.OrderedDict
        ).keys())

    rv = {}
    i = 1
    missing = 0
    for t_name in traits:
        if t_name in loc:
            rv[i] = loc[t_name]
        else:
            missing += 1
            rv[i] = t_name
        i += 1

    return rv

def store_traits(c, traits):
    store(c, traits, yield_id_and_names, '''
        insert into Traits(id, name) values (%(id)s, %(name)s)''')

def import_savefile(save_path):
    '''Imports Save Data'''
    print('Connecting to Database...',end='')
    db, c = connect('ck2', 'ck2password')
    print(' DONE')
    c.execute('use ck2;')

    save = load_save(save_path)

    c.execute('insert into Snapshots (date) values (%s);', (save['date'],))

    print('Importing dynasties...', end='')
    sys.stdout.flush()
    store_dynasties(c, load_save_dynasties(save))
    print(' DONE')

    print('Importing characters:')
    store_characters(c, load_characters(save, load_fixed_characters()))

    db.commit()
    db.close()

def import_gamedata():
    '''Import Required Data from the game files into the database'''

    print('Connecting to Database...',end='')
    db, c = connect('ck2', 'ck2password')
    print(' DONE')
    c.execute('use ck2;')

    print('Loading Localization...', end='')
    sys.stdout.flush()
    loc = load_loc()
    print(' DONE', len(loc), 'strings')

    # print('Importing Cultures...', end='')
    # sys.stdout.flush()
    # n = store_cultures(db, c, load_cultures(loc))
    # print(' DONE', n, 'cultures')

    # print('Importing Religions...', end='')
    # sys.stdout.flush()
    # n = store_religions(db, c, load_religions(loc))
    # print(' DONE', n, 'religions')

    print('Importing Fixed Dynasties...', end='')
    sys.stdout.flush()
    n = store_dynasties(c, load_game_dynasties())
    print(' DONE', n, 'dynasties')

    print('Importing Traits...', end='')
    sys.stdout.flush()
    traits = load_traits(loc)
    store_traits(c, traits)
    print(' DONE', len(traits), 'traits')

    db.commit()
    db.close()

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("Invalid Arguments", file=sys.stderr)
        sys.exit(1)

    if sys.argv[1] == 'savefile':
        import_savefile(sys.argv[2])
    elif sys.argv[1] == 'gamedata':
        import_gamedata()
    elif sys.argv[1] == 'charfields':
        char_key_stats(load_save('/dev/stdin'))
    elif sys.argv[1] == 'shell':
        import IPython
        print("Selctions of Functions:")
        for f in [
            read_json, connect, char_key_stats, store,

            load_save, load_loc,
            # load_cultures, store_cultures,
            # load_religions, store_religions,
            load_game_dynasties, load_save_dynasties, store_dynasties,

            load_characters, store_characters,

            import_savefile, import_gamedata,
        ]:
            print((f.__name__ + formatargspec(*getfullargspec(f))) +
                ('' if f.__doc__ is None else ':\n    ' + f.__doc__.strip()))
        print()
        IPython.embed()
    else:
        print("Invalid Arguments", file=sys.stderr)
        sys.exit(1)

