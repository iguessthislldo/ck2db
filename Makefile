all: capture_autosaves ck2json

capture_autosaves: capture_autosaves.c
	gcc $^ -o $@

ck2json.tab.c: ck2json.y
	bison -t -d $^

ck2json.yy.c: ck2json.l
	flex -o $@ $^

ck2json: ck2json.tab.c ck2json.yy.c ck2json.c
	gcc -g $^ -o $@ -lfl 

.PHONY: clean
clean:
	rm -fr capture_autosaves ck2json ck2json.tab.h ck2json.tab.c ck2json.yy.c
