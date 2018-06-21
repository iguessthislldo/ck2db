# Frederick Hornsey
# CS 434
# Summer 2018

import sys
import os
import _mysql_exceptions

steam_path = os.getenv('HOME')

def read_json(path):
    import json
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

def get_else(d, k, default):
    return d[k] if k in d else default

def get_str_else(d, k, default):
    return '"{}"'.format(d[k]) if k in d else default

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

def get_save(path):
    print('Reading', path, '...', end='')
    sys.stdout.flush()
    save = read_json(path)
    print(' DONE')
    return save

def import_characters(save):
    for cid, cdict in save['character'].items():
        r = dict(real_father_id=None)
        if 'fat' in cdict:
            r['real_father_id'] = cdict['fat']
        if 'rfat' in cdict:
            r['real_father_id'] = cdict['rfat']
        r['id'] = cid
        r['birth'] = cdict['b_d']
        r['death'] = get_else(cdict, 'd_d', None)
        r['is_female'] = 'fem' in cdict and cdict['fem']
        r['mother_id'] = get_else(cdict, 'mot', None)
        yield r

def import_into_db(c, save, get_next, sql):
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
            if current_size == last_size:
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

def import_db(save):
    print('Connecting to Database...',end='')
    db, c = connect('ck2', 'ck2password')
    print(' DONE')
    c.execute('use ck2;')

    print('Loading Characters Basic Info...', end='')
    sys.stdout.flush()
    import_into_db(c, save, import_characters, 'insert into Characters (id, birth, death, is_female, mother_id, real_father_id) values (%(id)s, %(birth)s, %(death)s, %(is_female)s, %(mother_id)s, %(real_father_id)s)')
    db.commit()
    print(' DONE')

    c.close()
    db.close()

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print("Invalid Arguments", file=sys.stderr)
        sys.exit(1)

    if sys.argv[1] == 'import':
        import_db(get_save('/dev/stdin'))
    elif sys.argv[1] == 'charfields':
        char_key_stats(get_save('/dev/stdin'))
    else:
        print("Invalid Arguments", file=sys.stderr)
        sys.exit(1)

