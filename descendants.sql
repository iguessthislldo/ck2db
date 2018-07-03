/*
List the Characters with the most descendants
Does not work
*/
use ck2;

/*
select c.id as cid, (
    with recursive Descendants as (
        select x.* from Characters as x where x.id = cid
        union
        select y.* from Characters as y, Descendants as d
            where d.id = y.mother_id or d.id = y.real_father_id
    ) select count(distinct(id)) from Descendants) as descendant_count
    from Characters as c
    order by descendant_count desc limit 10;
*/

/*
select c.id,
    (with recursive Descendants as (
        select x.id, x.mother_id, x.real_father_id
            from `Characters` as `x` where `x`.`id` = c.id
        union
        select y.id, y.mother_id, y.real_father_id from Characters as y, Descendants as d
            where d.id = y.mother_id or d.id = y.real_father_id
    ) select count(distinct(e.id)) from Descendants as e) as descendant_count
    from Characters as c
    order by descendant_count desc limit 10;
;
    */

