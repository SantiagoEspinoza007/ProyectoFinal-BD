#----------------------------------------CREACIÓN DE LA BASE DE DATOS--------------------------------------------------
CREATE DATABASE proyectobdd01 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;;
USE proyectobdd01;
#----------------------------------------CREACIÓN TABLAS TEMPORALES--------------------------------------------------
DROP PROCEDURE IF EXISTS creacion_tablas ;
DELIMITER $$
CREATE PROCEDURE creacion_tablas ()
BEGIN
    DROP TABLE IF EXISTS Production_Countries_temp;
    SET @sql_text = 'CREATE TABLE Production_Countries_temp (
        iso_3166_1 varchar(10) NOT NULL,
        Name varchar(155) NOT NULL
    );';
    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DROP TABLE IF EXISTS production_Companies_temp;
    SET @sql_text = 'CREATE TABLE Production_Companies_temp (
        id_pc int NOT NULL,
        Name varchar(155) NOT NULL
    );';
    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DROP TABLE IF EXISTS spoken_languages_temp;
    SET @sql_text = 'CREATE TABLE spoken_languages_temp (
        iso_639_1 varchar(10) NOT NULL,
        Name varchar(155) DEFAULT NULL
    );';
    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DROP TABLE IF EXISTS People_temp;
    SET @sql_text = 'CREATE TABLE `People_temp` (
        `id` int NOT NULL,
        `name_` varchar(155) DEFAULT NULL,
        `gender` int NOT NULL
    );';
    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END$$
DELIMITER ;
CALL creacion_tablas();
#----------------------------------------------PROCEDURES PEOPLE-----------------------------------------------
DROP PROCEDURE IF EXISTS cursor_People ;
DELIMITER $$
CREATE PROCEDURE cursor_People ()
BEGIN
     DECLARE done INT DEFAULT FALSE ;
     DECLARE jsonData json ;
     DECLARE jsonIdPeople int;
     DECLARE jsonGender int;
     DECLARE jsonName_ varchar(155);
     DECLARE i INT;
 -- Declarar el cursor
 DECLARE myCursor
  CURSOR FOR
   SELECT JSON_EXTRACT(CONVERT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(crew, '"', '\''), '{\'', '{"'),
    '\': \'', '": "'),'\', \'', '", "'),'\': ', '": '),', \'', ', "')
    USING UTF8mb4 ), '$[*]') FROM movie_dataset;
 -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
 DECLARE CONTINUE HANDLER
  FOR NOT FOUND SET done = TRUE ;
 -- Abrir el cursor
 OPEN myCursor  ;
 cursorLoop: LOOP
  FETCH myCursor INTO jsonData;
  -- Controlador para buscar cada uno de lso arrays
    SET i = 0;
  -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
  IF done THEN
   LEAVE  cursorLoop ;
  END IF ;
  WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO
  SET jsonName_ = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].name')), '') ;
  SET jsonGender = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].gender')), '') ;
  SET jsonIdPeople = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].id')), '') ;
  SET i = i + 1;
  SET @sql_text = CONCAT(' INSERT People_temp VALUES (', jsonIdPeople, ', ', jsonName_, ',',jsonGender,'); ');
PREPARE stmt FROM @sql_text;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
  END WHILE;
 END LOOP ;
    DROP TABLE IF EXISTS People;
    SET @sql_text = 'CREATE TABLE `People` (
        `id` int NOT NULL,
        `name_` varchar(155) DEFAULT NULL,
        `gender` int NOT NULL,
        PRIMARY KEY (id,gender)
    );';
    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

     INSERT INTO People (id,gender,name_)
    SELECT DISTINCT id,gender,name_
    FROM People_temp;
    DROP TABLE People_temp;
 CLOSE myCursor ;
END$$
DELIMITER ;
CALL cursor_People();
#----------------------------------------------PROCEDURES Movie PRIMER PASO-----------------------------------------------
DROP PROCEDURE IF EXISTS Procedure_Movie ;
DELIMITER $$
CREATE PROCEDURE Procedure_Movie()
BEGIN
      DROP TABLE IF EXISTS Movies;
        CREATE TABLE `Movies` (
      `budget` bigint DEFAULT NULL,
      `homepage` varchar(255) DEFAULT NULL,
      `id` int NOT NULL,
      `keywords_` text DEFAULT NULL,
      `original_language` varchar(5) NOT NULL,
      `original_title` varchar(255) DEFAULT NULL,
      `overview` text,
      `popularity` double DEFAULT NULL,
      `release_date` varchar(25) DEFAULT NULL,
      `revenue` bigint DEFAULT NULL,
      `runtime` varchar(255) DEFAULT NULL,
      `tagline` varchar(255) DEFAULT NULL,
      `title` varchar(255) DEFAULT NULL,
      `vote_average` float DEFAULT NULL,
      `vote_count` int DEFAULT NULL,
      PRIMARY KEY (`id`)
    );
      INSERT INTO Movies (budget, homepage,id,keywords_,original_language,original_title,
                          overview,popularity,release_date, revenue,runtime,
                          tagline,title,vote_average,vote_count)
        SELECT budget, homepage,id,keywords,original_language,original_title,
               overview,popularity,release_date,revenue,runtime,tagline,title,
               vote_average,vote_count
        FROM movie_dataset;
END $$
DELIMITER ;
CALL Procedure_Movie();
#----------------------------------------------PROCEDURES SpokenLanguages Primera Parte ------------------------------------
DROP PROCEDURE IF EXISTS Procedurejson_spokenLenguages ;
DELIMITER $$
CREATE PROCEDURE Procedurejson_spokenLenguages ()
BEGIN
 DECLARE done INT DEFAULT FALSE ;
 DECLARE jsonData json ;
 DECLARE jsonId varchar(250) ;
 DECLARE jsonLabel varchar(250) ;
 DECLARE i INT;

 -- Declarar el cursor
 DECLARE myCursor
  CURSOR FOR
   SELECT JSON_EXTRACT(CONVERT(spoken_languages USING UTF8MB4), '$[*]') FROM movie_dataset;

 -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
 DECLARE CONTINUE HANDLER
  FOR NOT FOUND SET done = TRUE ;
 -- Abrir el cursor
 OPEN myCursor  ;
 cursorLoop: LOOP
  FETCH myCursor INTO jsonData;
  -- Controlador para buscar cada uno de lso arrays
    SET i = 0;
  -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
  IF done THEN
   LEAVE  cursorLoop ;
  END IF ;

  WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO

  SET jsonId = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].iso_639_1')), '') ;
  SET jsonLabel = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].name')), '') ;
  SET i = i + 1;
  SET @sql_text = CONCAT('INSERT INTO spoken_languages_temp VALUES (', REPLACE(jsonId,'\'',''), ', ', jsonLabel, '); ');
PREPARE stmt FROM @sql_text;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
  END WHILE;

 END LOOP ;
    DROP TABLE IF EXISTS spoken_languages;
    CREATE TABLE spoken_languages AS
    SELECT Distinct iso_639_1,name
    FROM spoken_languages_temp ;

    ALTER TABLE spoken_languages
    ADD PRIMARY KEY (iso_639_1);
    DROP TABLE spoken_languages_temp;
 CLOSE myCursor ;
END$$
DELIMITER ;

CALL Procedurejson_spokenLenguages ();
#----------------------------------------------PROCEDURES SpokenLanguages Segunda Parte ------------------------------------
DROP TABLE IF EXISTS Movies_spokenLanguages;
CREATE TABLE Movies_spokenLanguages (
      `ISO_639_1` varchar(255) NOT NULL,
      `Id_mv` int NOT NULL,
      PRIMARY KEY (`ISO_639_1`,`Id_mv`),
      FOREIGN KEY (`Id_mv`) REFERENCES `Movies` (`id`),
      FOREIGN KEY (`ISO_639_1`) REFERENCES `spoken_Languages` (`ISO_639_1`)
    );
DROP PROCEDURE IF EXISTS ProcedureRelacion_spokenLenguages ;
DELIMITER $$
CREATE PROCEDURE ProcedureRelacion_spokenLenguages ()
BEGIN
 DECLARE done INT DEFAULT FALSE ;
 DECLARE jsonData json ;
 DECLARE jsonId varchar(250) ;
 DECLARE jsonLabel varchar(250) ;
 DECLARE resultSTR LONGTEXT DEFAULT '';
 DECLARE i INT;
 DECLARE idmv INT;

 -- Declarar el cursor
 DECLARE myCursor
  CURSOR FOR
   SELECT id,JSON_EXTRACT(CONVERT(spoken_languages USING UTF8MB4), '$[*]') FROM movie_dataset;

 -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
 DECLARE CONTINUE HANDLER
  FOR NOT FOUND SET done = TRUE ;
 -- Abrir el cursor
 OPEN myCursor  ;
 cursorLoop: LOOP
  FETCH myCursor INTO idmv ,jsonData;
  -- Controlador para buscar cada uno de lso arrays
    SET i = 0;
  -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
  IF done THEN
   LEAVE  cursorLoop ;
  END IF ;
  WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO

  SET jsonId = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].iso_639_1')), '') ;
  SET i = i + 1;
  SET @sql_text = CONCAT('INSERT INTO Movies_spokenLanguages VALUES (', REPLACE(jsonId,'\'',''), ', ', idmv, '); ');
    PREPARE stmt FROM @sql_text;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END WHILE;
 END LOOP ;
 CLOSE myCursor ;
END$$
DELIMITER ;
CALL ProcedureRelacion_spokenLenguages ();
#----------------------------------------------PROCEDURES Production Companies Primera Parte ------------------------------------
DROP PROCEDURE IF EXISTS Procedure_ProductionCompanies;
DELIMITER $$
CREATE PROCEDURE Procedure_ProductionCompanies ()
BEGIN
    DECLARE done INT DEFAULT FALSE ;
    DECLARE jsonData json ;
    DECLARE jsonId varchar(250) ;
    DECLARE jsonLabel varchar(250) ;
    DECLARE i INT;

    -- Declarar el cursor
    DECLARE myCursor
        CURSOR FOR
        SELECT JSON_EXTRACT(CONVERT(production_companies USING UTF8MB4), '$[*]') FROM movie_dataset ;

    -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
    DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET done = TRUE ;
    -- Abrir el cursor
    OPEN myCursor  ;
    cursorLoop: LOOP
        FETCH myCursor INTO jsonData;
        -- Controlador para buscar cada uno de lso arrays
        SET i = 0;
        -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
        IF done THEN
            LEAVE  cursorLoop ;
        END IF ;

        WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO

                SET jsonId = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].id')), '') ;
                SET jsonLabel = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].name')), '') ;
                SET i = i + 1;
                SET @sql_text = CONCAT('INSERT INTO Production_Companies_temp VALUES (', REPLACE(jsonId,'\'',''), ', ', jsonLabel, '); ');
                PREPARE stmt FROM @sql_text;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END WHILE;

    END LOOP ;
    CREATE TABLE Production_Companies AS
    SELECT Distinct id_pc,name
    FROM Production_Companies_temp ;

    ALTER TABLE Production_Companies
        ADD PRIMARY KEY (id_pc);

    DROP TABLE production_Companies_temp;
    CLOSE myCursor ;
END$$
DELIMITER ;

CALL Procedure_ProductionCompanies ();
#----------------------------------------------PROCEDURES Production Companies Segunda Parte ------------------------------------
DROP TABLE IF EXISTS Movies_ProductionCompanies;
CREATE TABLE `Movies_ProductionCompanies` (
  `id_pc` int NOT NULL,
  `id_mv` int NOT NULL,
  PRIMARY KEY (`id_mv`,`id_pc`),
  FOREIGN KEY (`id_mv`) REFERENCES `Movies` (`id`),
  FOREIGN KEY (`id_pc`) REFERENCES `Production_Companies` (`id_pc`)
);

DROP PROCEDURE IF EXISTS ProcedureRelacion_ProductionCompanies ;
DELIMITER $$
CREATE PROCEDURE ProcedureRelacion_ProductionCompanies ()
BEGIN
    DECLARE done INT DEFAULT FALSE ;
    DECLARE jsonData json ;
    DECLARE jsonId varchar(250) ;
    DECLARE i INT;
    DECLARE idmv INT;

    -- Declarar el cursor
    DECLARE myCursor
        CURSOR FOR
        SELECT id,JSON_EXTRACT(CONVERT(production_companies USING UTF8MB4), '$[*]') FROM movie_dataset;

    -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
    DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET done = TRUE ;
    -- Abrir el cursor
    OPEN myCursor  ;
    cursorLoop: LOOP
        FETCH myCursor INTO idmv ,jsonData;
        -- Controlador para buscar cada uno de lso arrays
        SET i = 0;
        -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
        IF done THEN
            LEAVE  cursorLoop ;
        END IF ;

        WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO

                SET jsonId = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].id')), '') ;
                SET i = i + 1;
                SET @sql_text = CONCAT('INSERT INTO Movies_ProductionCompanies VALUES (', REPLACE(jsonId,'\'',''), ', ', idmv, '); ');
                PREPARE stmt FROM @sql_text;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END WHILE;

    END LOOP ;

    CLOSE myCursor ;
END$$
DELIMITER ;

CALL ProcedureRelacion_ProductionCompanies ();
#----------------------------------------------PROCEDURES Production Countries Primera Parte ------------------------------------
DROP PROCEDURE IF EXISTS Procedure_ProductionCountries;
DELIMITER $$
CREATE PROCEDURE Procedure_ProductionCountries ()
BEGIN
    DECLARE done INT DEFAULT FALSE ;
    DECLARE jsonData json ;
    DECLARE jsonId varchar(250) ;
    DECLARE jsonLabel varchar(250) ;
    DECLARE i INT;

    -- Declarar el cursor
    DECLARE myCursor
        CURSOR FOR
        SELECT JSON_EXTRACT(CONVERT(production_Countries USING UTF8MB4), '$[*]') FROM movie_dataset;

    -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
    DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET done = TRUE ;
    -- Abrir el cursor
    OPEN myCursor  ;
    cursorLoop: LOOP
        FETCH myCursor INTO jsonData;
        -- Controlador para buscar cada uno de lso arrays
        SET i = 0;
        -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
        IF done THEN
            LEAVE  cursorLoop ;
        END IF ;

        WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO

                SET jsonId = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].iso_3166_1')), '') ;
                SET jsonLabel = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].name')), '') ;
                SET i = i + 1;
                SET @sql_text = CONCAT('INSERT INTO Production_Countries_temp VALUES (', REPLACE(jsonId,'\'',''), ', ', jsonLabel, '); ');
                PREPARE stmt FROM @sql_text;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END WHILE;

    END LOOP ;

    CREATE TABLE Production_Countries AS
    SELECT Distinct iso_3166_1,name
    FROM Production_Countries_temp ;

    ALTER TABLE Production_Countries
        ADD PRIMARY KEY (iso_3166_1);

    DROP TABLE Production_Countries_temp;
    CLOSE myCursor ;
END$$
DELIMITER ;

CALL Procedure_ProductionCountries ();
#----------------------------------------------PROCEDURES Production Countries Segunda Parte ------------------------------------
CREATE TABLE `Movies_Countries` (
  `Id_mv` int NOT NULL,
  `ISO_3166_1` varchar(255) NOT NULL,
  PRIMARY KEY (`Id_mv`,`ISO_3166_1`),
  FOREIGN KEY (`Id_mv`) REFERENCES `Movies` (`id`),
  FOREIGN KEY (`ISO_3166_1`) REFERENCES `Production_Countries` (`ISO_3166_1`)
);

DROP PROCEDURE IF EXISTS ProcedureRelacion_ProductionCountries ;
DELIMITER $$
CREATE PROCEDURE ProcedureRelacion_ProductionCountries ()
BEGIN
    DECLARE done INT DEFAULT FALSE ;
    DECLARE jsonData json ;
    DECLARE jsonId varchar(250) ;
    DECLARE i INT;
    DECLARE idmv INT;
    -- Declarar el cursor
    DECLARE myCursor
        CURSOR FOR
        SELECT id,JSON_EXTRACT(CONVERT(production_countries USING UTF8MB4), '$[*]') FROM movie_dataset;
    -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
    DECLARE CONTINUE HANDLER
        FOR NOT FOUND SET done = TRUE ;
    -- Abrir el cursor
    OPEN myCursor  ;
    cursorLoop: LOOP
        FETCH myCursor INTO idmv ,jsonData;
        -- Controlador para buscar cada uno de lso arrays
        SET i = 0;
        -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
        IF done THEN
            LEAVE  cursorLoop ;
        END IF ;
        WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO

                SET jsonId = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].iso_3166_1')), '') ;
                SET i = i + 1;
                SET @sql_text = CONCAT('INSERT INTO Movies_Countries (ISO_3166_1,Id_mv) VALUES (', REPLACE(jsonId,'\'',''), ', ', idmv, '); ');
                PREPARE stmt FROM @sql_text;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END WHILE;
    END LOOP ;
    CLOSE myCursor ;
END$$
DELIMITER ;

CALL ProcedureRelacion_ProductionCountries ();
#----------------------------------------------PROCEDURES crew ------------------------------------
CREATE TABLE `Crew` (
  `id_People` int NOT NULL,
  `id_mv` int NOT NULL,
  `name_Job` varchar(255) NOT NULL,
  `credit_id` varchar(105) NOT NULL,
  `department` varchar(25) NOT NULL,
  PRIMARY KEY (`id_People`,`name_Job`,`id_mv`),
  FOREIGN KEY (`id_People`) REFERENCES `People` (`id`),
  FOREIGN KEY (`id_mv`) REFERENCES `Movies` (`id`)
);

DROP PROCEDURE IF EXISTS Procedure_Crew ;
DELIMITER $$
CREATE PROCEDURE Procedure_Crew ()
BEGIN
     DECLARE done INT DEFAULT FALSE ;
     DECLARE jsonData json ;
     DECLARE jsonIdPeople int;
     DECLARE jsonNameJob VARCHAR(255);
     DECLARE jsonCreditId VARCHAR(105);
     DECLARE jsonDepartment VARCHAR(25);
     DECLARE idmv INT;
     DECLARE i INT;
 -- Declarar el cursor
 DECLARE myCursor
  CURSOR FOR
   SELECT id,JSON_EXTRACT(CONVERT(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(crew, '"', '\''), '{\'', '{"'),
    '\': \'', '": "'),'\', \'', '", "'),'\': ', '": '),', \'', ', "')
    USING UTF8mb4 ), '$[*]') FROM movie_dataset;
 -- Declarar el handler para NOT FOUND (esto es marcar cuando el cursor ha llegado a su fin)
 DECLARE CONTINUE HANDLER
  FOR NOT FOUND SET done = TRUE ;
 -- Abrir el cursor
 OPEN myCursor  ;
 cursorLoop: LOOP
  FETCH myCursor INTO idmv,jsonData;
  -- Controlador para buscar cada uno de lso arrays
    SET i = 0;
  -- Si alcanzo el final del cursor entonces salir del ciclo repetitivo
  IF done THEN
   LEAVE  cursorLoop ;
  END IF ;
  WHILE(JSON_EXTRACT(jsonData, CONCAT('$[', i, ']')) IS NOT NULL) DO
  SET jsonIdPeople = IFNULL(JSON_EXTRACT(jsonData,  CONCAT('$[', i, '].id')), '') ;
  SET jsonNameJob = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].job')), '') ;
  SET jsonCreditId = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].credit_id')), '') ;
  SET jsonDepartment = IFNULL(JSON_EXTRACT(jsonData, CONCAT('$[', i,'].department')), '') ;
  SET i = i + 1;
  SET @sql_text = CONCAT('INSERT INTO Crew VALUES (',jsonIdPeople,',',idmv,',',jsonNameJob,',',jsonCreditId,',',jsonDepartment,');');
PREPARE stmt FROM @sql_text;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
  END WHILE;
 END LOOP ;
 CLOSE myCursor ;
END$$
DELIMITER ;
CALL Procedure_Crew();
#----------------------------------------------PROCEDURES Status ------------------------------------
DROP PROCEDURE IF EXISTS Procedure_Status ;
DELIMITER $$
    CREATE PROCEDURE Procedure_Status()
    BEGIN
        DROP TABLE IF EXISTS Status;
    CREATE TABLE Status (status VARCHAR(25)) AS SELECT DISTINCT status
    FROM movie_dataset;

    ALTER TABLE Status
    ADD PRIMARY KEY (status);
        DROP TABLE IF EXISTS Status_movie;
    #Creación e INSERTS movie-status
    CREATE TABLE Status_movie (id INT NOT NULL,
                                status VARCHAR(25))AS SELECT id, st.status AS status
    FROM movie_dataset movie_status, Status st
    WHERE movie_status.status = st.status;

    ALTER TABLE status_movie
    ADD FOREIGN KEY (id) REFERENCES Movies(id),
        ADD FOREIGN KEY (status) REFERENCES Status(status);

END $$
DELIMITER ;
CALL Procedure_Status();
#----------------------------------------------PROCEDURES Directors ------------------------------------
DROP PROCEDURE IF EXISTS Procedure_Directors ;
DELIMITER $$
    CREATE PROCEDURE Procedure_Directors()
    BEGIN
        DROP TABLE IF EXISTS Directors;
    CREATE TABLE `Directors` (
      `id_People` int NOT NULL,
      `id_mv` int NOT NULL,
      PRIMARY KEY (`id_People`,`id_mv`),
      FOREIGN KEY (`id_People`) REFERENCES `Crew` (`id_People`),
      FOREIGN KEY (`id_mv`) REFERENCES `Movies` (`id`)
    );
        INSERT IGNORE INTO Directors(id_People, id_mv)
            SELECT  c.id_People, c.id_mv FROM Crew c,People p,movie_dataset m
            WHERE  c.name_Job = 'Director' AND p.id = c.id_People AND m.id = c.id_mv;

END $$
DELIMITER ;
CALL Procedure_Directors();

#----------------------------------------------PROCEDURES Cast ------------------------------------
DROP TABLE IF EXISTS cast_;
CREATE TABLE `cast_` (
  `id_mv` int NOT NULL,
  `id_People` int NOT NULL,
  PRIMARY KEY (`id_mv`,`id_People`),
  FOREIGN KEY (`id_mv`) REFERENCES `Movies` (`id`),
  FOREIGN KEY (`id_People`) REFERENCES `People` (`id`)
);
#----------------------------------------------PROCEDURES Genres ------------------------------------
DROP PROCEDURE IF EXISTS Procedure_Genres ;
DELIMITER $$
    CREATE PROCEDURE Procedure_Genres()
    BEGIN
        DROP TABLE IF EXISTS genres;
    CREATE TABLE genres(genres VARCHAR(100)) AS
    SELECT DISTINCT (
    SUBSTRING_INDEX(SUBSTRING_INDEX(genres,' ', 5), ' ', -1)) AS genres
    FROM movie_dataset;
    DELETE
    FROM genres
    WHERE genres IS NULL;

    ALTER TABLE genres
        ADD PRIMARY KEY (genres);
    DROP TABLE IF EXISTS Movies_genres;
    CREATE TABLE Movies_genres AS
        SELECT tg.genres, id
        FROM genres tg, movie_dataset mv
        WHERE INSTR(mv.genres, tg.genres )>0;

    ALTER TABLE Movies_genres
    ADD FOREIGN KEY (id)
        REFERENCES Movies(id),
        ADD FOREIGN KEY (genres)
            REFERENCES genres(genres);
END $$
DELIMITER ;
CALL Procedure_Genres();
