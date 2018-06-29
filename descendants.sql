/*
List the Characters with the most descendants
*/
use ck2;

/*
create or replace function count_descendants(cid int unsigned) returns int unsigned return (
    with recursive Descendants as (
        select * from Characters where id = cid
        union
        select c.* from Characters as c, Descendants as d
            where d.id = c.mother_id or d.id = c.real_father_id
    ) select count(distinct(id)) from Descendants
    );
drop function count_descendants;


select c.id as cid, (
    with recursive Descendants as (
        select x.* from Characters as x where x.id = cid
        union
        select y.* from Characters as y, Descendants as d
            where d.id = y.mother_id or d.id = y.real_father_id
    ) select count(distinct(id)) from Descendants) as descendant_count
    from Character as c
    order by descendant_count desc limit 10;
    

with Descendant_Counts as (
    select id, count_descendants(id) as descendants from Characters
)
select * from Descendant_Counts
*/

/*
create or replace function count_descendants(cid int unsigned) returns int unsigned return (
    with recursive Descendants as (
        select * from ck2.Characters where id = cid
        union
        select c.* from ck2.Characters as c, Descendants as d
            where d.id = c.mother_id or d.id = c.real_father_id
    ) select count(distinct(id)) from Descendants
);

select count_descendants(91402);
*/

delimiter $$
create or replace procedure count_descendants_proc(in cid int unsigned, out result int unsigned)
begin
    with recursive Descendants as (
        select x.* from Characters as x where x.id = cid
        union
        select y.* from Characters as y, Descendants as d
            where d.id = y.mother_id or d.id = y.real_father_id
    ) select count(distinct(id)) from Descendants into result;
end; $$

/*
create or replace function count_descendants(cid int unsigned) returns int unsigned
begin
    call count_descendants_proc(cid, @result);
    return @result;
end; $$
*/

delimiter ;

select c.id as cid, count_descendants(cid) as descendant_count 
    from Characters as c
    order by descendant_count desc limit 10;

