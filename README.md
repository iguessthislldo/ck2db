# ck2db

University Project based on analysing [Crusader Kings 2](https://en.wikipedia.org/wiki/Crusader_Kings_II)
save files for a database class.

## Requirements

Building the tools requires make, gcc, inotify, iconv, bison and flex. To build them, just run `make`.

ck2db.py requires Python3 and the [mysqlclient](https://github.com/PyMySQL/mysqlclient-python) python package and optionally ipython.

## capture\_autosaves

Program that monitors the default save location for Crusadar Kings 2 for Steam on Ubuntu and when a new autosave file has been written, it copies it to the new destination directory passed as an argument. The file is renamed as the date in the save in YYYY-MM-DD format.

## ck2json

Bison/Flex based converter that converts many of the files used in Crusadar Kings 2 into JSON.
Characters that are not [ISO 8859-10/Latin 6](https://en.wikipedia.org/wiki/ISO/IEC_8859-10) are stripped as Crusadar Kings 2 has some custom codepoints.
Entries with the same name are combined into one entry with a list so that it works as JSON. Sometimes order matters so it might be helpful if the JSON reader can keep the entries in the same order as the file.
Has bugs relating to Bison handles string tokens, might or might not be my fault.

## ck2db.py

Python3 script for loading a subset of the data of game and multiple save files into a MariaDB >= 10.3 database.
