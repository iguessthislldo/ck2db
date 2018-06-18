# Frederick Hornsey
# CS 434
# Summer 2018

import sys

def read_json(path):
    import yaml
    import yamlloader

    with open(path, encoding='utf-8', errors='backslashreplace') as f:
        return yaml.load(f, Loader=yamlloader.ordereddict.CLoader)

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

def insert_character(c, cid, cdict):
    c.execute('INSERT INTO Characters VALUES ({}, "{}", {}, {}, NULL, NULL);'.format(
        cid,
        cdict['b_d'],
        "NULL" if 'd_d' not in cdict else '"{}"'.format(cdict['d_d']),
        "TRUE"
    ))

if __name__ == "__main__":
    print('Reading Save Game...', end='')
    sys.stdout.flush()
    save = read_json('/dev/stdin')
    print(' DONE')
    print(len(save['character']))
    # print('Connecting to Database...',end='')
    # db, c = connect('ck2', 'ck2password')
    # print(' DONE')
    # c.execute('use ck2;')

    # print('Loading Characters Basic Info...', end='')
    # for cid, cdict in save['character'].items():
    #     insert_character(c, cid, cdict)
    # db.commit()
    # print(' DONE')

    # c.close()
    # db.close()

