/* Frederick Hornsey
 * CS 434 Summer 2018
 * Create CK2 database on MariaDB
 */

/* Create or Override Database */
DROP DATABASE IF EXISTS ck2;
CREATE DATABASE IF NOT EXISTS ck2;
USE ck2;

/* Basic Infomation ======================================================= */

/* Snapshots */
CREATE TABLE Snapshots (date CHAR(10) KEY);

/* Cultures */
CREATE TABLE Cultures (
    id VARCHAR(100) KEY,
    name VARCHAR(100) NOT NULL
);

/* Religion */
CREATE TABLE Religions (
    id VARCHAR(100) KEY,
    name VARCHAR(100) NOT NULL
);

/* Character Information ================================================== */

/* Dynasties */
CREATE TABLE Dynasties (
    id INT UNSIGNED KEY,
    name VARCHAR(100) NOT NULL
);

/* Characters */
CREATE TABLE Characters (
    id INT UNSIGNED KEY,
    birth CHAR(10) NOT NULL,
    death CHAR(10),
    is_female BOOLEAN NOT NULL,

    mother_id INT UNSIGNED
        CHECK(mother_id != character_id),
    FOREIGN KEY (mother_id)
        REFERENCES Characters(id)
        ON DELETE CASCADE,

    real_father_id INT UNSIGNED,
        CHECK(real_father_id != character_id),
    FOREIGN KEY (real_father_id)
        REFERENCES Characters(id)
        ON DELETE CASCADE
);

/* Character_Status */
CREATE TABLE Character_Status (
    character_id INT UNSIGNED,
    FOREIGN KEY (character_id)
        REFERENCES Characters (id)
        ON DELETE CASCADE,
    date CHAR(10),
    FOREIGN KEY (date)
        REFERENCES Snapshots(date)
        ON DELETE CASCADE,
    KEY (character_id, date),

    name VARCHAR(100) NOT NULL,
    health FLOAT NOT NULL,
    wealth FLOAT NOT NULL,
    piety FLOAT NOT NULL,
    prestige FLOAT NOT NULL,
    diplomacy TINYINT UNSIGNED NOT NULL,
    martial TINYINT UNSIGNED NOT NULL,
    stewardship TINYINT UNSIGNED NOT NULL,
    intrigue TINYINT UNSIGNED NOT NULL,
    learning TINYINT UNSIGNED NOT NULL,

    dynasty_id INT UNSIGNED NOT NULL,
    FOREIGN KEY (dynasty_id)
        REFERENCES Dynasties(id)
        ON DELETE CASCADE,

    culture_id VARCHAR(100) NOT NULL,
    FOREIGN KEY (culture_id)
        REFERENCES Cultures(id)
        ON DELETE CASCADE,

    religion_id VARCHAR(100) NOT NULL,
    FOREIGN KEY (religion_id)
        REFERENCES Religions(id)
        ON DELETE CASCADE,

    perceived_father_id INT UNSIGNED,
    FOREIGN KEY (perceived_father_id)
        REFERENCES Characters(id)
        ON DELETE CASCADE,

    spouse_id INT UNSIGNED,
    FOREIGN KEY (spouse_id)
        REFERENCES Characters(id)
        ON DELETE CASCADE
);

/* Traits */
CREATE TABLE Traits (
    id INT UNSIGNED KEY,
    name VARCHAR(100) NOT NULL
);
CREATE TABLE Character_Traits (
    character_id INT UNSIGNED,
    date CHAR(10),
    FOREIGN KEY (character_id, date)
        REFERENCES Character_Status (character_id, date)
        ON DELETE CASCADE,
    trait_id INT UNSIGNED,
    FOREIGN KEY (trait_id)
        REFERENCES Traits(id)
        ON DELETE CASCADE,
    KEY(character_id, date, trait_id)
);

/* User =================================================================== */
drop user if exists 'ck2';
create user 'ck2' identified by 'ck2password';
grant all privileges on `ck2`.* to 'ck2'@localhost;

