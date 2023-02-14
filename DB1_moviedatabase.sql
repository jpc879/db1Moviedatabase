----
-- Create tables for database
----

-- Drop tables and constraints
----
ALTER TABLE movies DROP CONSTRAINT mov_fk1;
ALTER TABLE movies DROP CONSTRAINT mov_fk2;
ALTER TABLE movie_characters DROP CONSTRAINT char_fk1;
ALTER TABLE movie_characters DROP CONSTRAINT char_fk2;
ALTER TABLE movie_role DROP CONSTRAINT role_fk1;
ALTER TABLE movie_role DROP CONSTRAINT role_fk2;
ALTER TABLE movie_cast DROP CONSTRAINT cast_fk1;
ALTER TABLE movie_cast DROP CONSTRAINT cast_fk2;
ALTER TABLE movie_director DROP CONSTRAINT dir_fk1;
ALTER TABLE movie_director DROP CONSTRAINT dir_fk2;

ALTER TABLE movies DROP CONSTRAINT movies_pk;
ALTER TABLE characters DROP CONSTRAINT characters_pk;
ALTER TABLE movie_characters DROP CONSTRAINT movie_char_pk;
ALTER TABLE actors DROP CONSTRAINT actors_pk;
ALTER TABLE movie_role DROP CONSTRAINT movie_role_pk;
ALTER TABLE movie_cast DROP CONSTRAINT movie_cast_pk;
ALTER TABLE directors DROP CONSTRAINT directors_pk;
ALTER TABLE movie_director DROP CONSTRAINT movie_director_pk;
ALTER TABLE finances DROP CONSTRAINT finances_pk;
ALTER TABLE movie_reviews DROP CONSTRAINT movie_reviews_pk;

DROP TABLE movie_reviews;
DROP TABLE finances;
DROP TABLE movie_director;
DROP TABLE directors;
DROP TABLE movie_cast;
DROP TABLE movie_role;
DROP TABLE actors;
DROP TABLE movie_characters;
DROP TABLE characters;
DROP TABLE movies;


-- Create tables
----
-- Movies
----
CREATE TABLE movies (
        movie_id                INTEGER         
    ,   title                   VARCHAR(30)     NOT NULL
    ,   yearreleased            INTEGER         NOT NULL 
    ,   duration_in_mins        INTEGER         NOT NULL
    ,   FSK_rating              INTEGER         NOT NULL        
    ,   m_finances_id           INTEGER         NOT NULL         -- (foreign key)
    ,   m_reviews_id            INTEGER         NOT NULL         -- (foreign key)
    ,   brief_description       VARCHAR(150) 
);


-- Characters
----
CREATE TABLE characters (
        character_id            INTEGER         
    ,   character_name          VARCHAR(30)     NOT NULL
    ,   alias_nickname          VARCHAR(30)                   
    ,   occupation              VARCHAR(30)                     -- e.g. detective
);


-- Movie characters - which movie does the character appear in
----
CREATE TABLE movie_characters (                       
        movie_char_id           INTEGER         
    ,   character_id            INTEGER         NOT NULL        -- (foreign key)
    ,   movie_id                INTEGER         NOT NULL        -- (foreign key)
    ,   age                     INTEGER                         -- current age in main story of this movie
);


-- Actors
----
CREATE TABLE actors (
        actor_id                INTEGER         
    ,   initials                CHAR(2)         NOT NULL        -- e.g. JT for John Travolta
    ,   actor_name              VARCHAR(30)     NOT NULL
    ,   birthdate               DATE        
    ,   place_of_birth          VARCHAR (100)    
    ,   nr_of_oscars            INTEGER        
 
);


-- Movie role - which actor portrays the character
----
CREATE TABLE movie_role (
        movie_role_id           INTEGER         
    ,   actor_id                INTEGER         NOT NULL        -- (foreign key)
    ,   character_id            INTEGER         NOT NULL        -- (foreign key)
    ,   character_portrayal     VARCHAR(30)                     -- e.g. actor, voice actor, stunt double               
);
    

-- Movie cast - which movies does the actor play in
----
CREATE TABLE movie_cast (
        movie_cast_id           INTEGER        
    ,   actor_id                INTEGER         NOT NULL        -- (foreign key)
    ,   movie_id                INTEGER         NOT NULL        -- (foreign key)
    ,   movie_role              VARCHAR(30)     NOT NULL        -- e.g. leading role, supporting role
);

    
-- Directors
----
CREATE TABLE directors (
        dir_id                  INTEGER         
   ,    dir_name                VARCHAR(30)     NOT NULL
   ,    birthdate               DATE            
   ,    nr_of_oscars            INTEGER                         -- number of Oscars as best director
   ,    nr_of_movies_dir        INTEGER                         -- number of movies directed  
);


-- Movie director - who directed the movie
----
CREATE TABLE movie_director (
        movie_dir_id            INTEGER         
    ,   dir_id                  INTEGER         NOT NULL        -- (foreign key)
    ,   movie_id                INTEGER         NOT NULL        -- (foreign key)
);


-- Estimated movie budget and gross in USA
----
CREATE TABLE finances (
        finances_id             INTEGER
     ,  estimated_budget        INTEGER         NOT NULL         -- in million dollars
     ,  US_gross                NUMBER(7,3)     NOT NULL         -- in million dollars
)


-- Movie reviews
----
CREATE TABLE movie_reviews (
        review_id               INTEGER
     ,  IMDb                    NUMBER(4,1)     NOT NULL         -- 1,0 - 10,0
     ,  Rotten_Tomatoes         INTEGER         NOT NULL         -- 0% - 100%
)
        



-- Set primary keys
----
ALTER TABLE movies ADD CONSTRAINT movies_pk PRIMARY KEY (movie_id);
ALTER TABLE characters ADD CONSTRAINT characters_pk PRIMARY KEY (character_id);
ALTER TABLE movie_characters ADD CONSTRAINT movie_char_pk PRIMARY KEY (movie_char_id);
ALTER TABLE actors ADD CONSTRAINT actors_pk PRIMARY KEY (actor_id);
ALTER TABLE movie_role ADD CONSTRAINT movie_role_pk PRIMARY KEY (movie_role_id);
ALTER TABLE movie_cast ADD CONSTRAINT movie_cast_pk PRIMARY KEY (movie_cast_id);
ALTER TABLE directors ADD CONSTRAINT directors_pk PRIMARY KEY (dir_id);
ALTER TABLE movie_director ADD CONSTRAINT movie_director_pk PRIMARY KEY (movie_dir_id);
ALTER TABLE finances ADD CONSTRAINT finances_pk PRIMARY KEY (finances_id);
ALTER TABLE movie_reviews ADD CONSTRAINT movie_reviews_pk PRIMARY KEY (review_id);


-- Set foreign keys
----

-- Link movie with finances
ALTER TABLE movies ADD CONSTRAINT
    mov_fk1 FOREIGN KEY (m_finances_id) REFERENCES finances (finances_id);

-- Link movie with reviews
ALTER TABLE movies ADD CONSTRAINT
    mov_fk2 FOREIGN KEY (m_reviews_id) REFERENCES movie_reviews (review_id);
    
-- Link movie with character
ALTER TABLE movie_characters ADD CONSTRAINT             
    char_fk1 FOREIGN KEY (character_id) REFERENCES characters;
ALTER TABLE movie_characters ADD CONSTRAINT
    char_fk2 FOREIGN KEY (movie_id) REFERENCES movies;
    
-- Link actor with character
ALTER TABLE movie_role ADD CONSTRAINT
    role_fk1 FOREIGN KEY (actor_id) REFERENCES actors;
ALTER TABLE movie_role ADD CONSTRAINT
    role_fk2 FOREIGN KEY (character_id) REFERENCES characters;
  
-- Link actor with movie  
ALTER TABLE movie_cast ADD CONSTRAINT
    cast_fk1 FOREIGN KEY (actor_id) REFERENCES actors;
ALTER TABLE movie_cast ADD CONSTRAINT
    cast_fk2 FOREIGN KEY (movie_id) REFERENCES movies;
    
-- Link director with movie
ALTER TABLE movie_director ADD CONSTRAINT
    dir_fk1 FOREIGN KEY (dir_id) REFERENCES directors;
ALTER TABLE movie_director ADD CONSTRAINT
    dir_fk2 FOREIGN KEY (movie_id) REFERENCES movies;

COMMIT;

-- Create an index on movies
CREATE INDEX i_movie_titles ON movies (title);
CREATE INDEX i_movie_year ON movies (yearreleased);


----
-- Trigger
----

-- 1a) Update-Trigger
CREATE OR REPLACE TRIGGER dir_trigger
BEFORE UPDATE OF nr_of_oscars ON directors
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
    --
BEGIN
    IF :NEW.nr_of_oscars < :OLD.nr_of_oscars THEN
        :NEW.nr_of_oscars := :OLD.nr_of_oscars;
    END IF;
END;


-- 2a) Insert-Trigger
CREATE OR REPLACE TRIGGER fsk_trigger
BEFORE INSERT ON movies
REFERENCING OLD AS OLD NEW AS NEW
FOR EACH ROW
DECLARE
    INVALID_FSK EXCEPTION;
    PRAGMA EXCEPTION_INIT(INVALID_FSK, -20222);
BEGIN
    IF :NEW.FSK_rating <> 0 AND :NEW.FSK_rating <> 6 AND :NEW.FSK_rating <> 12 
    AND :NEW.FSK_rating <> 16 AND :NEW.FSK_rating <> 18 THEN
        RAISE_APPLICATION_ERROR(-20222, 'Invalid FSK rating! Must be either 0, 6, 12, 16 or 18.');
    END IF;
END;

   
    
----
-- Insert data into tables 
----

INSERT INTO movies VALUES (1, 'Pulp Fiction', 1994, 154, 16, 1, 1, 'Pulp Fiction follows three different interrelated stories that 
                            are told out of chronological order.');
INSERT INTO movies VALUES (2, 'Taxi Driver', 1976, 114, 18, 2, 2, 'Taxi Driver tells the story of the lonely New Yorker taxi driver 
                            Travis Bickle.');
INSERT INTO movies VALUES (3, 'Shutter Island', 2010, 138, 16, 3, 3, 'After one of its patients has gone missing, 
                            a psychiatric facility on Shutter Island is being investigated by U.S. Marshal Edward Daniels.');
INSERT INTO movies VALUES (4, 'Roma', 2018, 135, 12, 4, 4, 'Roma follows the story of the indigenous live-in maid Cleodegaria 
                            Gutiérrez in the Colonia Roma neighborhood of Mexico City.');
commit;

INSERT INTO characters (character_id, character_name, occupation) VALUES (1, 'Vincent Vega', 'hitman');
INSERT INTO characters (character_id, character_name, occupation) VALUES (2, 'Travis Bickle', 'taxi driver');
INSERT INTO characters VALUES (3, 'Edward Daniels', 'Teddy', 'U.S. Marshal');
INSERT INTO characters VALUES (4, 'Cleodegaria Gutiérrez', 'Cleo', 'live-in maid');
commit;

INSERT INTO movie_characters VALUES (1, 1, 1, 45);                    -- 1, Vincent Vega, Pulp Fiction, 45
INSERT INTO movie_characters VALUES (2, 2, 2, 50);                    -- 2, Travis Bickle, Taxi Driver, 50
INSERT INTO movie_characters VALUES (3, 3, 3, 40);
INSERT INTO movie_characters VALUES (4, 4, 4, 25);
commit;

INSERT INTO actors VALUES (1, 'JT', 'John Travolta', to_date('18.02.1954', 'DD.MM.YYYY'), 'Englewood, New Jersey, USA', 0);
INSERT INTO actors VALUES (2, 'RN', 'Robert De Niro', to_date('17.07.1943', 'DD.MM.YYYY'), 'New York City, New York, USA', 2);
INSERT INTO actors VALUES (3, 'LC', 'Leonardo DiCaprio', to_date('11.11.1974', 'DD.MM.YYYY'), 'Los Angeles, California, USA', 1);
INSERT INTO actors VALUES (4, 'YA', 'Yalitza Aparicio', to_date('11.12.1993', 'DD.MM.YYYY'), 'Tlaxiaco, Oaxaca, Mexico', 0);
commit;

INSERT INTO movie_role VALUES (1, 1, 1, 'actor');                   -- 1, John Travolta, Vincent Vega, actor
INSERT INTO movie_role VALUES (2, 2, 2, 'actor');                   -- 2, Robert De Niro, Travis Bickle, actor
INSERT INTO movie_role VALUES (3, 3, 3, 'actor');
INSERT INTO movie_role VALUES (4, 4, 4, 'actor');
commit;

INSERT INTO movie_cast VALUES (1, 1, 1, 'leading role');             -- 1, John Travolta, Pulp Fiction
INSERT INTO movie_cast VALUES (2, 2, 2, 'leading role');             
INSERT INTO movie_cast VALUES (3, 3, 3, 'leading role');
INSERT INTO movie_cast VALUES (4, 4, 4, 'leading role');
commit;

INSERT INTO directors VALUES (1, 'Quentin Tarantino', to_date('27.03.1963', 'DD.MM.YYYY'), 2, 9);
INSERT INTO directors VALUES (2, 'Martin Scorsese', to_date('17.11.1942', 'DD.MM.YYYY'), 1, 27);
INSERT INTO directors VALUES (3, 'Alfonso Cuarón', to_date('28.11.1961', 'DD.MM.YYYY'), 2, 12);
commit;

INSERT INTO movie_director VALUES (1, 1, 1);                         -- 1, Quentin Tarantino, Pulp Fiction
INSERT INTO movie_director VALUES (2, 2, 2);                           
INSERT INTO movie_director VALUES (3, 2, 3);                           
INSERT INTO movie_director VALUES (4, 3, 4);                          
commit;

INSERT INTO budget_revenue VALUES (1, 8, 107.955);                     
INSERT INTO budget_revenue VALUES (2, 1, 28.267);
INSERT INTO budget_revenue VALUES (3, 80, 128.098);
INSERT INTO budget_revenue VALUES (4, 15, 3.043);
commit;

INSERT INTO movie_reviews VALUES (1, 8.9, 92);
INSERT INTO movie_reviews VALUES (2, 8.3, 98);
INSERT INTO movie_reviews VALUES (3, 8.1, 68);
INSERT INTO movie_reviews VALUES (4, 7.8, 96);
commit;

----
-- Test Triggers
----
-- a) Test Update-Trigger
UPDATE directors SET nr_of_oscars = 1 WHERE dir_id = 1;

SELECT * FROM directors WHERE dir_id = 1; 		-- check correct number

-- b) Test Insert-Trigger
INSERT INTO movies (movie_id, title, yearreleased, duration_in_mins, FSK_rating)
        VALUES (5, 'Matrix', 1999, 136, 15);

----
-- Update and Select
----

-- 1) Movie rating was changed
----

UPDATE movies SET FSK_rating = 16 WHERE title = 'Taxi Driver';

COMMIT;


-- 2) List all movies directed by Martin Scorsese
----
SELECT * FROM movies
WHERE movie_id IN(
    SELECT movie_id FROM movie_director
    WHERE dir_id IN(
        SELECT dir_id FROM directors
        WHERE dir_name = 'Martin Scorsese'
    )
);

-- 3) Delete all entries of movies made before 1990
----

DELETE FROM movies WHERE yearreleased <= 1989;

COMMIT;


-- 4) Add column for number of sequels
ALTER TABLE movies ADD (nr_of_sequels INTEGER);

UPDATE movies SET nr_of_sequels = 0;                -- set column to default 0 for all entries
ALTER TABLE movies MODIFY (nr_of_sequels NOT NULL); -- then set to NOT NULL

COMMIT;




