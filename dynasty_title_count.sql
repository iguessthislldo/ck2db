use ck2;

/*
    Test Case:
    6392 (Charlemange) at 0770-01-01 has 8
    Dynasty is 25061 (Karling)
    Charlemange has 9 titles, Karlomam has 5 for a total of 14 of Karling Dynasty
*/

create or replace function count_char_titles(cid int unsigned, snapshot char(10))
    returns int unsigned
    return (
        select count(*)
            from Title_Status
            where holder_id = cid and date = snapshot
    );

create or replace function count_dynasty_titles(did int unsigned, snapshot char(10))
    returns int unsigned
    return (
        select sum(count_char_titles(c.character_id, snapshot))
            from Character_Status c
            where c.dynasty_id = did and c.date = snapshot
    );

/* FOR TESTING FUNCTIONS ABOVE
select count_dynasty_titles(25061, '0770-01-01');
select c.character_id, c.name, count_char_titles(c.character_id, '0770-01-01')
    from Character_Status c
    where c.dynasty_id = 25061 and c.date = '0770-01-01'
    ;
*/

    /*
select distinct d.name, count_dynasty_titles(d.id, s.date) over (partition by d.id)
    from Snapshots s, Dynasties d
    order by title_count desc
    limit 20
    ;
*/
