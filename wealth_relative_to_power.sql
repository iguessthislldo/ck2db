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

select cs.name, cs.date, avg(cs.wealth) / avg(char_titles_score(c.id, cs.date)) as avg_relative_wealth
    from Characters c inner join Character_Status cs on c.id = cs.character_id
    group by c.id, cs.date
    order by avg_relative_wealth desc
    limit 10
    ;
