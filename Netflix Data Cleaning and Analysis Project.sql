-- language: sql

use netflix;

drop database netflix;

-- 1. Vérification initiale de nos jeux de données

select * from netflix_raw;

-- 2. Vérification de la qualité des données

select * from netflix_raw order by title desc;

select * from netflix_raw where show_id = 's5023';

-- 3. Vérification des doublons et suppression si nécessaire

-- I. Vérification des doublons sur la colonne show_id

select show_id , count(*) as dups_count from netflix_raw 
group by show_id having count(*) > 1 ;

-- Changement de show_id en clé primaire (valeurs null interdites)

alter table netflix_raw
modify column show_id varchar(12) primary key;

-- II. Vérification des doublons sur la colonne title

-- Doublons dans la colonne title

select title, count(*) as dups_count from netflix_raw
group by title having count(*) > 1;

-- Enquête sur les doublons en comparant avec d'autres colonnes

with netflix_raw as (
    select show_id, upper(title) as title, director, type, cast, country, release_year 
    from netflix_raw
),
dups_title as (
    select upper(title) as title from netflix_raw
    group by upper(title) having count(*) > 1
) 
select show_id, nr.title, type, director, release_year, cast, country 
from netflix_raw as nr
join dups_title dt on nr.title = dt.title
order by title;

-- Suppression de 3 doublons

DELETE FROM netflix_raw
WHERE show_id IN (
    SELECT show_id
    FROM (
        SELECT show_id, 
               ROW_NUMBER() OVER (PARTITION BY lower(title), type, country ORDER BY show_id) AS rn
        FROM netflix_raw
    ) AS temp
    WHERE rn > 1
);

-- 4. Vérification des valeurs manquantes dans chaque colonne (en pourcentage)

SELECT
    round(SUM(CASE WHEN show_id IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS show_id_null_count,
    round(SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS type_null_count,
    round(SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS title_null_count,
    round(SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS director_null_count,
    round(SUM(CASE WHEN cast IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS cast_null_count,
    round(SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS country_null_count,
    round(SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS date_added_null_count,
    round(SUM(CASE WHEN release_year IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS release_year_null_count,
    round(SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS rating_null_count,
    round(SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS duration_null_count,
    round(SUM(CASE WHEN listed_in IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS listed_in_null_count,
    round(SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) / count(*) * 100, 2) AS description_null_count
FROM netflix_raw;

-- Valeurs distinctes de la colonne type

select distinct type from netflix_raw;

-- Traitement des valeurs NULL :

-- I. Pour la colonne director

update netflix_raw set director = 'Unknown' where director is null;

-- Vérification

select count(*) from netflix_raw where director is null;

select director from netflix_raw where director regexp '[0-9]';

-- II. Pour la colonne cast

select count(*) from netflix_raw where cast is null;

update netflix_raw set cast = 'Unknown' where cast is null;

-- III. Pour la colonne country

select count(*) from netflix_raw where country is null;

update netflix_raw set country = 'Unknown' where country is null;

-- Vérification de la colonne date_added

select count(*) from netflix_raw where date_added is null;

-- Remplacement des valeurs nulles dans date_added

-- (Suites des UPDATE pour chaque show_id…)

-- Pour la colonne rating

select count(*) from netflix_raw where rating is null;

-- Remplissage manuel des valeurs manquantes

-- Pour la colonne duration

select * from netflix_raw where duration is null;

-- Remplissage manuel de duration et correction de rating

-- Création de tables séparées pour les colonnes à valeurs multiples

-- Exemples : Director, Country, Genre (listed_in), Cast

-- Table Netflix_Director + INSERT avec CTE récursif

-- Même logique pour Country, Genre, Cast (voir script complet)

-- Suppression des colonnes désormais réparties dans des tables séparées

alter table netflix_raw
drop column director,
drop column cast,
drop column country,
drop column duration,
drop column listed_in;

-- 5. Conversion des types de données

-- Conversion de date_added en DATE et release_year en entier

UPDATE netflix_raw
SET 
    date_added = STR_TO_DATE(date_added, '%M %d, %Y'),
    release_year = CAST(release_year AS UNSIGNED);

-- 6. Extraction de nouvelles colonnes à partir de duration

-- Ajout des colonnes duration_in_minutes et total_number_of_seasons

alter table netflix_raw
add column duration_in_minutes VARCHAR(255),
add column total_number_of_seasons VARCHAR(255);

update netflix_raw
set duration_in_minutes = case when type = 'Movie' then substring_index(duration, ' ', 1) else 'Unknown' end,
    total_number_of_seasons = case when type = 'TV Show' then substring_index(duration, ' ', 1) else 'Unknown' end;

-- Analyse exploratoire sur les données nettoyées

/* 1. Combien de films et séries TV sont disponibles sur Netflix ? */

select type , count(*) as count from netflix_raw group by type;

/* 2. Quel pays a le plus de titres disponibles sur Netflix ? */

select nc.country_name as country_name, count(*) as count from netflix_raw nr
join netflix_country nc on nc.show_id = nr.show_id 
group by country_name order by count desc limit 1;

/* 3. Quels sont les réalisateurs les plus prolifiques ? */

select nd.director_name, count(nr.show_id) as number_of_show from netflix_director nd 
join netflix_raw nr on nr.show_id = nd.show_id 
where nd.director_name <> 'Unknown' 
group by nd.director_name order by number_of_show desc limit 15;

/* 4. Quels sont les genres les plus populaires ? */

select ng.genre_type  as genre, count(*) as count  from netflix_genre ng 
join netflix_raw nr on nr.show_id = ng.show_id
group by genre order by count desc limit 10;
