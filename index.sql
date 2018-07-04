use ck2;

create or replace index Character_Status_Index on Character_Status(character_id, date);
create or replace index Character_Traits_Index on Character_Traits(character_id, date, trait_id);
create or replace index Dynasties_Index on Dynasties(id);
create or replace index Titles_Index on Titles(id);
create or replace index Titles_Status_Index on Title_Status(title_id, date);

