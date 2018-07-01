use ck2;

create or replace function title_score(title_id varchar(100))
    returns int unsigned
    return (
        select case substring(title_id, 1, 2)
            when 'e_' then 256
            when 'k_' then 64
            when 'd_' then 16
            when 'c_' then 4
            when 'b_' then 1
            else 0 end
    );

create or replace function char_titles_score(cid int unsigned, snapshot char(10))
    returns int unsigned
    return (
        select sum(title_score(title_id))
            from Title_Status
            where holder_id = cid and date = snapshot
    );

create or replace function dynasty_titles_score(did int unsigned, snapshot char(10))
    returns int unsigned
    return (
        select coalesce(sum(char_titles_score(c.character_id, snapshot)),0)
            from Character_Status c
            where c.dynasty_id = did and c.date = snapshot
    );

/*
TESTING FUNCTIONS ABOVE:
    Test Case:
    6392 (Charlemange) at 0770-01-01 has 8
    Dynasty is 25061 (Karling)
    Charlemange has 9 titles, Karlomam has 5 for a total of 14 of Karling Dynasty

select dynasty_titles_score(25061, '0770-01-01');
select c.character_id, c.name, char_titles_score(c.character_id, c.date)
    from Character_Status c
    where c.dynasty_id = 25061 and c.date = '0770-01-01'
    ;
*/

select name,
    dynasty_titles_score(id, first_year) as first_year_score,
    dynasty_titles_score(id, last_year) as last_year_score
    from
        Dynasties,
        (select min(date) as first_year from Snapshots) as first_year_q,
        (select max(date) as last_year from Snapshots) as last_year_q
    order by first_year_score desc limit 10
    ;

