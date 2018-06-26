#!/bin/bash
set -e


if [ $# -ne 2 ]
then
    echo "arguments: SAVES_SRC JSON_DEST" 1>&2
    exit 1
fi

mkdir -p $2

for i in $1/*.ck2
do
    output="$2/$(basename -s '.ck2' $i).json"
    echo "$i : $output"

    # Create Json
    ./ck2json "$i" > "$output"

    # Validate Json Syntax
    printf "import sys\nimport json\nwith open(sys.argv[1]) as f:\n    json.load(f)\n" | python3 - "$output"
done
