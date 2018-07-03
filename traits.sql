use ck2;

create or replace function most_common_trait(test_trait_id int unsigned)
    returns varchar(100)
    return (
    select trait_name from (
    select t.name as trait_name, count(ct1.trait_id) as trait_count
        from Traits t, Character_Traits ct1, Character_Traits ct2
        where
            ct1.character_id = ct2.character_id
            and
            ct1.date = ct1.date
            and
            ct2.trait_id = test_trait_id
            and
            ct1.trait_id != test_trait_id
            and
            t.id = ct1.trait_id
        group by ct1.trait_id
        order by trait_count desc
        limit 1
    ) as Common_Traits
    );

select name, common_trait from (
    select name, most_common_trait(id) as common_trait
        from Traits) as Common_Traits where common_trait is not null;

