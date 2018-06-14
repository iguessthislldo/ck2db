all: capture_autosaves read_ck2

capture_autosaves: capture_autosaves.c
	gcc $^ -o $@

read_ck2.tab.c: read_ck2.y
	bison -t -d $^

read_ck2.yy.c: read_ck2.l
	flex -o $@ $^

read_ck2: read_ck2.tab.c read_ck2.yy.c
	gcc $^ -o $@ -lfl 

.PHONY: clean
clean:
	rm -fr capture_autosaves read_ck2 read_ck2.tab.h read_ck2.tab.c read_ck2.yy.c
