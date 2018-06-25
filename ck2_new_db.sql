/* Frederick Hornsey
 * CS 434 Summer 2018
 * Create CK2 database on MariaDB
 */

/* Create or Override Database */
drop database if exists ck2;
create database if not exists ck2;
use ck2;

/* User =================================================================== */
create or replace user 'ck2' identified by 'ck2password';
grant all privileges on `ck2`.* to 'ck2'@localhost;


/* Basic Infomation ======================================================= */

/* Snapshots */
create table Snapshots (date char(10) key);

/* Character Information ================================================== */

/* Dynasties */
create table Dynasties (
    id int unsigned key,
    name varchar(100) not null
);

/* Characters */

create table Characters (
    id int unsigned key,
    birth char(10) not null,
    death char(10),
    is_female boolean not null,

    mother_id int unsigned check (mother_id != id),
    foreign key (mother_id)
        references Characters(id)
        on delete cascade,

    real_father_id int unsigned check(real_father_id != id),
    foreign key (real_father_id)
        references Characters(id)
        on delete cascade
);

/* Enforce the fact a mothers is female if a character has one */
create function is_female(id int unsigned) returns boolean return id is null or (
    (select count(c.id) from Characters as c where c.id = id and c.is_female = true) = 1);
delimiter $$
create trigger mother_is_female after insert on Characters for each row begin
    if not is_female(new.mother_id) then
        signal sqlstate '45000' set message_text = 'Mother is not female';
    end if;
    end; $$
delimiter ;

/* Enforce the fact a fathers is male if a character has one */
create function is_male(id int unsigned) returns boolean return id is null or (
    (select count(c.id) from Characters as c where c.id = id and c.is_female = false) = 1);
delimiter $$
create trigger father_is_male after insert on Characters for each row begin
    if not is_male(new.real_father_id) then
        signal sqlstate '45000' set message_text = 'Father is not male';
    end if;
    end; $$
delimiter ;

/* Character_Status */
create table Character_Status (
    character_id int unsigned,
    foreign key (character_id)
        references Characters (id)
        on delete cascade,
    date char(10),
    foreign key (date)
        references Snapshots(date)
        on delete cascade,
    key (character_id, date),

    name varchar(100) not null,
    health float not null,
    wealth float not null,
    piety float not null,
    prestige float not null,
    diplomacy tinyint unsigned not null,
    martial tinyint unsigned not null,
    stewardship tinyint unsigned not null,
    intrigue tinyint unsigned not null,
    learning tinyint unsigned not null,

    dynasty_id int unsigned,
    foreign key (dynasty_id)
        references Dynasties(id)
        on delete cascade,

    perceived_father_id int unsigned check (character_id != perceived_father_id),
    foreign key (perceived_father_id)
        references Characters(id)
        on delete cascade
);

/* Enforce the fact a perceived fathers is male if a character has one */
delimiter $$
create trigger perceived_father_is_male before insert on Character_Status for each row begin
    if not is_male(new.perceived_father_id) then
        signal sqlstate '45000' set message_text = 'Perceived father is not male';
    end if;
    end; $$
delimiter ;

create table Marriages (
    husband_id int unsigned,
    foreign key (husband_id, date)
        references Character_Status (character_id, date)
        on delete cascade,
    wife_id int unsigned,
    date char(10),
    foreign key (wife_id, date)
        references Character_Status (character_id, date)
        on delete cascade,
    key(husband_id, wife_id, date)
);

/* Enforce the fact a spouse is of the opposite sex if a character has one */
create function is_opposite_sex(husband_id int unsigned, wife_id int unsigned)
    returns boolean
    return
        ((select count(c.id) from Characters as c
            where c.id = husband_id and c.is_female = false) = 1)
        and
        ((select count(c.id) from Characters as c
            where c.id = wife_id and c.is_female = true) = 1)
        ;

delimiter $$
create trigger spouse_is_opposite_sex before insert on Marriages for each row begin
    if not is_opposite_sex(new.husband_id, new.wife_id) then
        signal sqlstate '45000' set message_text = 'Marriage is Same Sex! O:';
    end if;
    end; $$
delimiter ;

/* Traits */
create table Traits (
    id int unsigned key,
    name varchar(100) not null
);
create table Character_Traits (
    character_id int unsigned,
    date char(10),
    foreign key (character_id, date)
        references Character_Status (character_id, date)
        on delete cascade,
    trait_id int unsigned not null,
    foreign key (trait_id)
        references Traits(id)
        on delete cascade,
    key(character_id, date, trait_id)
);

/* Title Information =================================================================== */

create table Titles (
    id varchar(100) key
);

create table Title_Status (
    title_id varchar(100),
    holder_id int unsigned,
    date char(10),
    foreign key (holder_id, date)
        references Character_Status (character_id, date)
        on delete cascade,
    key(title_id, date),
    name varchar(100)
);

create table Empires (
    title_id varchar(100)
        check (title_id regexp 'e_.+'),
    foreign key (title_id)
        references Titles(id)
        on delete cascade
);

create table Empire_Status (
    title_id varchar(100),
    date char(10),
    foreign key (title_id, date)
        references Title_Status (title_id, date)
        on delete cascade,
    foreign key (title_id)
        references Empires (title_id)
        on delete cascade
);

create table Kingdoms (
    title_id varchar(100)
        check (title_id regexp 'k_.+'),
    foreign key (title_id)
        references Titles(id)
        on delete cascade
);

create table Kingdom_Status (
    title_id varchar(100),
    date char(10),
    foreign key (title_id, date)
        references Title_Status (title_id, date)
        on delete cascade,
    foreign key (title_id)
        references Kingdoms (title_id)
        on delete cascade,
    de_jure_empire_id varchar(100),
    foreign key (de_jure_empire_id)
        references Empires (title_id)
        on delete cascade,
    de_facto_liege_id varchar(100),
    foreign key (de_facto_liege_id, date)
        references Title_Status(title_id, date)
        on delete cascade
);

create table Duchies (
    title_id varchar(100)
        check (title_id regexp 'd_.+'),
    foreign key (title_id)
        references Titles(id)
        on delete cascade
);

create table Duchy_Status (
    title_id varchar(100),
    date char(10),
    foreign key (title_id, date)
        references Title_Status (title_id, date)
        on delete cascade,
    foreign key (title_id)
        references Duchies (title_id)
        on delete cascade,
    de_jure_kingdom_id varchar(100),
    foreign key (de_jure_kingdom_id)
        references Kingdoms (title_id)
        on delete cascade,
    de_facto_liege_id varchar(100),
    foreign key (de_facto_liege_id, date)
        references Title_Status(title_id, date)
        on delete cascade
);

create table Counties (
    title_id varchar(100)
        check (title_id regexp 'c_.+'),
    foreign key (title_id)
        references Titles(id)
        on delete cascade,
    duchy_id varchar(100),
    foreign key (duchy_id)
        references Duchies(title_id)
        on delete cascade
);

create table County_Status (
    title_id varchar(100),
    date char(10),
    foreign key (title_id, date)
        references Title_Status (title_id, date)
        on delete cascade,
    foreign key (title_id)
        references Counties (title_id)
        on delete cascade,

    de_facto_liege_id varchar(100),
    foreign key (de_facto_liege_id, date)
        references Title_Status(title_id, date)
        on delete cascade
);

create table Baronies (
    title_id varchar(100)
        check (title_id regexp 'b_.+'),
    foreign key (title_id)
        references Titles(id)
        on delete cascade,
    county_id varchar(100),
    foreign key (county_id)
        references Counties(title_id)
        on delete cascade
);

create table Barony_Status (
    title_id varchar(100),
    date char(10),
    foreign key (title_id, date)
        references Title_Status (title_id, date)
        on delete cascade,
    foreign key (title_id)
        references Baronies (title_id)
        on delete cascade,

    de_facto_liege_id varchar(100),
    foreign key (de_facto_liege_id, date)
        references Title_Status(title_id, date)
        on delete cascade
);

