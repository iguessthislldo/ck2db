use ck2;

create or replace view Complete_Character as select
    c.id, birth, death, is_female, mother_id, real_father_id,
    s.name as personal_name, d.name as dynasty_name, perceived_father_id
    from Characters c, Character_Status s, Dynasties d
    where c.id = character_id and dynasty_id = d.id
    ;

