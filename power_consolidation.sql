use ck2;

create or replace function title_score(title_id varchar(100))
    returns int unsigned
    return (
        select case substring(title_id, 1, 2)
            when 'e_' then 10000
            when 'k_' then 1000
            when 'd_' then 100
            when 'c_' then 10
            when 'b_' then 1
            else 0 end
    );

select 

/*
create or replace function snapshot_titles_score(date char(10))
    returns int unsigned
    return (
        select sum(title_score(title_id))
            from Title_Status
            where holder_id is not null
    );

select date, snapshot_titles_score(date) from Snapshots order by date;
*/


