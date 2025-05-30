use  netflix;

drop database netflix;

-- 1. Let's do the initial Check on Our Datasets

select * from netflix_raw;

-- 2. Checking the Data Quality 

select * from netflix_raw order by title desc;

select * from netflix_raw where show_id = 's5023';

-- 3. Checking the duplicates and removing duplicates, if any

-- I. Checking the Dups in the Show ID Attributes

select show_id , count(*) as dups_count from netflix_raw 
group by show_id having count(*) > 1 ;

-- Changing its default value from NULL to Primary Key

alter table netflix_raw
modify column show_id varchar(12) primary key;

-- II. Checking the Dups in the title Attributes

-- Dups in the title

select title, count(*) as dups_count from netflix_raw
group by title having count(*) > 1;

-- Dups Investigation by comparing it with other attributes

with netflix_raw as (
select show_id, upper(title) as title, director, type,cast, country ,release_year from netflix_raw )
,
dups_title as (
select upper(title) as title from netflix_raw
group by upper(title) having count(*) > 1) 

select show_id, nr.title as title,type , director,release_year ,cast,country from netflix_raw as nr
join dups_title dt on nr.title = dt.title
order by title;

-- Deleting 3 dups title

DELETE FROM netflix_raw
WHERE show_id IN (
    SELECT show_id
    FROM (
        SELECT Show_id, 
               ROW_NUMBER() OVER (PARTITION BY lower(title),type, country  ORDER BY show_id) AS rn
        FROM netflix_raw
    ) AS temp
    WHERE rn > 1
);

-- 4. Checking for the missing values in each column in term of percentage

SELECT
	round( SUM(CASE WHEN show_id IS NULL THEN 1 ELSE 0 END) / count(*) * 100 ,2 ) AS show_id_null_count,
	round(SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS type_null_count,
    round(SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS title_null_count,
    round(SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2)  AS director_null_count,
    round(SUM(CASE WHEN cast IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS cast_null_count,
    round(SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS country_null_count,
    round(SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS date_added_null_count,
    round(SUM(CASE WHEN release_year IS NULL THEN 1 ELSE 0 END) /count(*) * 100,2) AS release_year_null_count,
    round(SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS rating_null_count,
    round(SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2)  AS duration_null_count,
    round(SUM(CASE WHEN listed_in IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS listed_in_null_count,
    round(SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) / count(*) * 100,2) AS description_null_count
    
FROM netflix_raw;

-- Moview Type distinct values

select distinct type from netflix_raw;

-- Treatment of NULL Values:

-- I. For Director Column,

update netflix_raw set director = 'Unknown' where director is null;

-- Let's verify the null count in director column

select count(*) from netflix_raw where director is null ;

select director from netflix_raw where director regexp'[0-9]';

-- II. For Cast Column,

-- Let's check for null values in the cast 

select count(*) from netflix_raw where cast is null;

-- Let’s handle these blanks by replacing them with ‘Unknown’:

update netflix_raw set cast= 'Unknown' where cast is null;

-- III. For Country Column

-- Check for null values

select count(*) from netflix_raw where country is null;

-- Replacing null values

 Update netflix_raw set country = 'Unknown' where country is null;
 
 
 -- Check for date_added column
 
 select count(*) from netflix_raw where date_added is null;
 
 select * from netflix_raw where date_added is null;
 
 UPDATE netflix_raw
SET date_added = '2016-12-09'
WHERE title = 'A Young Doctor''s Notebook and Other Stories';

UPDATE netflix_raw
SET date_added = '2014-12-01'
WHERE title = 'Anthony Bourdain: Parts Unknown';

UPDATE netflix_raw
SET date_added = '2020-12-30'
WHERE title = 'Frasier';

UPDATE netflix_raw
SET date_added = '2015-01-01'
WHERE title = 'Friends';

UPDATE netflix_raw
SET date_added = '2013-03-08'
WHERE title = 'Gunslinger Girl';

UPDATE netflix_raw
SET date_added = '2016-07-19'
WHERE title = 'La Familia P. Luche';

UPDATE netflix_raw
SET date_added = '2015-11-01'
WHERE title = 'Kikoriki';

UPDATE netflix_raw
SET date_added = '2013-08-14'
WHERE title = 'Maron';

UPDATE netflix_raw
SET date_added = '2014-04-01'
WHERE title = 'Red vs. Blue';

UPDATE netflix_raw
SET date_added = '2015-02-15'
WHERE title = 'The Adventures of Figaro Pho';

-- for rating column

select count(*) from netflix_raw where rating is null;

select * from netflix_raw where rating is null;

-- replacing null values for rating column

UPDATE netflix_raw
SET rating = 'TV-PG'
Where show_id = 's5990';

UPDATE netflix_raw
SET rating = 'TV-MA'
Where show_id = 's7538';

UPDATE netflix_raw
SET rating = 'TV-14'
Where show_id = 's6828';

UPDATE netflix_raw
SET rating = 'TV-G'
Where show_id = 's7313';

-- Checking unusual values in rating column

select distinct rating from netflix_raw ;


select * from netflix_raw where duration is null;

-- Replacing duration from the rating column for 3 shows

-- For Show ID S5542:

Update netflix_raw
set duration = '74 min'
where show_id ='s5542';

Update netflix_raw
set rating = 'TV-MA'
where show_id ='s5542';

-- For Show ID S5814:

Update netflix_raw
set duration = '66 min'
where show_id ='s5814';

Update netflix_raw
set rating = 'TV-MA'
where show_id ='s5814'; 


SELECT distinct (rating)
from netflix_raw;

-- For Show ID s5795:

Update netflix_raw
set duration = '84 min'
where show_id ='s5795';

Update netflix_raw
set rating = 'TV-MA'
where show_id ='s5795';


-- Creating Separate Tables for Multi-Value Columns

-- For Director 

CREATE TABLE IF NOT EXISTS Netflix_Director (
    show_id VARCHAR(50),
    director_name VARCHAR(255)
);


INSERT INTO Netflix_Director (show_id, director_name)
SELECT show_id, director_name
FROM (
    WITH RECURSIVE director_split AS (
        -- Anchor member: start with the original rows
        SELECT 
            show_id,
            TRIM(SUBSTRING_INDEX(director, ',', 1)) AS director_name,
            TRIM(SUBSTRING(director, LENGTH(SUBSTRING_INDEX(director, ',', 1)) + 2)) AS remaining_director
        FROM netflix_raw
        WHERE director IS NOT NULL AND director <> ''  -- Ensures only non-null directors are processed

        UNION ALL

        -- Recursive member: process the remaining part
        SELECT
            show_id,
            TRIM(SUBSTRING_INDEX(remaining_director, ',', 1)) AS director_name,
            CASE 
                -- Only continue splitting if there are more commas
                WHEN remaining_director LIKE '%,%' 
                THEN TRIM(SUBSTRING(remaining_director, LENGTH(SUBSTRING_INDEX(remaining_director, ',', 1)) + 2))
                ELSE NULL  -- Stop the recursion if there are no more commas
            END AS remaining_director
        FROM director_split
        WHERE remaining_director IS NOT NULL AND remaining_director <> ''  -- Ensure non-empty remaining parts
    )
    SELECT show_id, director_name
    FROM director_split
    WHERE director_name IS NOT NULL AND director_name <> ''  -- Filter out any blank director names
) AS directors
ORDER BY show_id;


select * from director;


-- Let's apply same concept to other columns as well

select * from netflix_raw;

create table if not exists Netflix_Country (show_id varchar(10), country_name varchar(20) );

-- for country column

INSERT INTO Netflix_Country (show_id, country_name)
SELECT show_id, country
FROM (
    WITH RECURSIVE country_recursion AS (
        -- Anchor member: start with the original rows
        SELECT 
            show_id,
            TRIM(SUBSTRING_INDEX(country, ',', 1)) AS first_country,
            TRIM(SUBSTRING(country, LENGTH(SUBSTRING_INDEX(country, ',', 1)) + 2)) AS next_country
        FROM netflix_raw
        WHERE country IS NOT NULL AND country <> ''  -- Ensures only non-empty `country` values are processed

        UNION ALL

        -- Recursive member: process the remaining countries
        SELECT 
            show_id,
            TRIM(SUBSTRING_INDEX(next_country, ',', 1)) AS first_country,
            CASE 
                WHEN next_country LIKE '%,%' THEN
                    TRIM(SUBSTRING(next_country, LENGTH(SUBSTRING_INDEX(next_country, ',', 1)) + 2))
                ELSE NULL  -- Stop recursion if no more commas
            END AS next_country
        FROM country_recursion
        WHERE next_country IS NOT NULL AND next_country <> ''  -- Ensure non-empty remaining parts
    )

    -- Final selection of valid countries
    SELECT 
        show_id, 
        first_country AS country
    FROM country_recursion
    WHERE first_country IS NOT NULL AND first_country <> ''  -- Filter out any blank or NULL countries
) AS valid_countries
ORDER BY show_id;




-- --    for listed_in column


create table Netflix_Genre (show_id varchar(10), genre_type nvarchar(50));

INSERT INTO Netflix_Genre (show_id, genre_type)
SELECT show_id, genre
FROM (
    WITH RECURSIVE genre AS (
        -- Anchor member: start with the original rows
        SELECT 
            show_id,
            TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS first_genre,
            TRIM(SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2)) AS next_genre
        FROM netflix_raw
        WHERE listed_in IS NOT NULL AND listed_in <> '' -- Ensures only non-empty `listed_in` values

        UNION ALL

        -- Recursive member: process the remaining genres
        SELECT 
            show_id,
            TRIM(SUBSTRING_INDEX(next_genre, ',', 1)) AS first_genre,
            CASE 
                WHEN next_genre LIKE '%,%' THEN
                    TRIM(SUBSTRING(next_genre, LENGTH(SUBSTRING_INDEX(next_genre, ',', 1)) + 2))
                ELSE NULL
            END AS next_genre
        FROM genre
        WHERE next_genre IS NOT NULL AND next_genre <> '' -- Ensure non-empty remaining genres
    )

    -- Final selection of valid genres
    SELECT 
        show_id, 
        first_genre AS genre
    FROM genre
    WHERE first_genre IS NOT NULL AND first_genre <> '' -- Filter out any blank or NULL genres
) AS valid_genres
ORDER BY show_id;



-- Let's apply this to cast attributes as well.

create table Netflix_Actors (show_id varchar(9), actor_name nvarchar(50));

INSERT INTO Netflix_Actors (show_id, actor_name)
SELECT show_id, actors 
FROM (
    WITH RECURSIVE cast_recursive AS (
        -- Anchor member: start with the original rows
        SELECT 
            show_id, 
            TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS first_actor,
            TRIM(SUBSTRING(cast, LENGTH(TRIM(SUBSTRING_INDEX(cast, ',', 1))) + 2)) AS next_actor
        FROM netflix_raw
        WHERE cast IS NOT NULL AND cast <> ''  -- Ensures only non-empty `cast` values are processed

        UNION ALL

        -- Recursive member: process the remaining actors
        SELECT 
            show_id, 
            TRIM(SUBSTRING_INDEX(next_actor, ',', 1)) AS first_actor,
            CASE 
                WHEN next_actor LIKE '%,%' THEN
                    TRIM(SUBSTRING(next_actor, LENGTH(TRIM(SUBSTRING_INDEX(next_actor, ',', 1))) + 2))
                ELSE NULL  -- Stop recursion if no more commas
            END AS next_actor
        FROM cast_recursive
        WHERE next_actor IS NOT NULL AND next_actor <> ''  -- Ensure non-empty remaining parts
    )

    -- Final selection of valid actors
    SELECT 
        show_id, 
        first_actor AS actors
    FROM cast_recursive
    WHERE first_actor IS NOT NULL AND first_actor <> ''  -- Filter out any blank or NULL actor names
) AS valid_actors
ORDER BY show_id;


-- we will drop the column that we have moved to director, genre, actors and country tables later 

-- 5. Data type conversion of the appropriate column

select * from netflix_raw;

-- Let's convert data and year column from text to date and number respectively

UPDATE netflix_raw
SET 
    date_added = STR_TO_DATE(date_added, '%M %d, %Y'), -- Convert date_added to DATE
    release_year = CAST(release_year AS UNSIGNED);     -- Convert release_year to an integer


-- 6. Feature extraction

select * from netflix_raw;

select case when type ='Movie' then substring_index(duration,' ',1) else 'Unknown' end as  duration_in_minutes,
case when type='TV Show' then substring_index(duration,' ',1) else 'Unknown' end as total_number_of_seasons
from netflix_raw;

-- Creating two new column

alter table netflix_raw
add column duration_in_minutes VARCHAR(255),
add column total_number_of_seasons VARCHAR(255);

-- Setting the values into this two new columns

update  netflix_raw
set duration_in_minutes = case when type ='Movie' then substring_index(duration,' ',1) else 'Unknown' end ,
 total_number_of_seasons = case when type='TV Show' then substring_index(duration,' ',1) else 'Unknown' end   ;
select * from netflix_raw;

-- Now Lets' drop all the unnecessary columns from the netflix raw

select * from netflix_raw;

alter table netflix_raw
drop column director,
drop column cast,
drop column country,
drop column duration,
drop column listed_in;

select * from netflix_raw;

-- This is my clean data and now let's do some Data Analysis using netflix_raw , director , genre, actor and country table

-- Netflix Data Analysis 

/* 1. How many Mobies and TV Shows are avaialble in Netflix */

select type , count(*) as count from netflix_raw group by type;

/* 2. Which country has the most titles available on Netflix? */

select nc.country_name as country_name, count(*) as count from netflix_raw nr
join netflix_country nc on nc.show_id = nr.show_id 
group by country_name order by count desc limit 1;

/* 3. Who are Netflix's most prolific directors?*/

select nd.director_name, count(nr.show_id) as number_of_show from netflix_director nd join netflix_raw nr on nr.show_id = nd.show_id 
where nd.director_name <> 'Unknown' group by nd.director_name order by number_of_show desc limit 15;

/* 4. What are the most popular genres on Netflix? */

select ng.genre_type  as genre, count(*) as count  from netflix_genre ng join netflix_raw nr on nr.show_id = ng.show_id
group by genre order by count desc limit 10 ;

/* 5. Which year had the most releases on Netflix? */

select year(date_added) as year_ , count(*) from netflix_raw group by year_ order by 2 desc;

/* 6. What’s the average duration of a movie on Netflix? */

select round(avg(duration_in_minutes)) as duration from netflix_raw where duration_in_minutes <>'Unknown' and type='Movie';


/* 7. Please recommend documentaries to the user on Netflix? */

select title from netflix_raw  nr join netflix_genre ng where ng.genre_type like '%Documentaries%';


/* 8. Are there any noticeable trends in the types of content being added to Netflix over the years? */


select year(date_added) as year_ , type , count(*)  from netflix_raw 
group by year_;

/* 9. Count number of shows created by each director and it should be more than 1 */

select director_name , count(distinct type) as number_of_shows
from netflix_raw nr join netflix_director d on d.show_id = nr.show_id
 where trim((director_name is not null) ) 
group by 1 having count(distinct type)>1 order by 2 desc;

/* 10. Write an SQL query to find the total count of shows (Moview, TV Shows and Both) So total number of shows created for  movies only, tv shows only 
and both movies and both together by the director*
Movies only: Total number of shows where the director created only movies.
TV Shows only: Total number of shows where the director created only TV shows.
Both: Total number of shows where the director created both movies and TV shows.*/

with shows_count as (
    -- Step 1: Calculate the number of TV shows and movies per director
    select 
        d.director_name,
        sum(case when nr.type = 'TV Show' then 1 else 0 end) as tv_show_count,  -- Count of TV Shows
        sum(case when nr.type = 'Movie' then 1 else 0 end) as movies_count      -- Count of Movies
    from 
        netflix_raw nr
    join 
        netflix_director d 
        on nr.show_id = d.show_id 
    where 
        d.director_name is not null
    group by 
        d.director_name
)

-- Step 2: Aggregate counts for different types of shows

-- Query 1: Total number of movies
select 
    'Movies' as Shows, 
    sum(movies_count) as total_count 
from 
    shows_count 
where 
    movies_count > 0  -- Filter to include only directors with movies

union all 

-- Query 2: Total number of TV shows
select 
    'TV Shows' as Shows, 
    sum(tv_show_count) as total_count 
from 
    shows_count 
where 
    tv_show_count > 0  -- Filter to include only directors with TV shows

union all 

-- Query 3: Total number of directors who directed both movies and TV shows
select 
    'Both' as Shows, 
    sum(movies_count + tv_show_count) as total_count 
from 
    shows_count
where 
    tv_show_count > 0 and movies_count > 0;  -- Filter to include only directors with both TV shows and movies

 
 /* 11. Which country has highest number of comedy movies ? */
 
 select country_name, count(distinct g.show_id) as count from country c join genre g on c.show_id = g.show_id
 join netflix_raw nr on nr.show_id = g.show_id
 where genre_type= 'Comedies'  and nr.type='Movie' and country_name is not null and  country_name <> '' group by country_name order by 2 desc limit 1 ;
 
 /* 12. for each year, which director has the maximum movies released in the theatre consider release_year as the actual release year */
 
 with cte as (
    select nr.release_year,
           d.director_name,
           count(distinct d.show_id) as movie_released_count,
           row_number() over (partition by nr.release_year order by count(distinct d.show_id) desc) as rn
    from netflix_raw nr
    join netflix_director d on nr.show_id = d.show_id
    where nr.type = 'Movie'
      and d.director_name is not null
      and d.director_name <> ''
    group by nr.release_year, d.director_name
)

select release_year, director_name, movie_released_count
from cte 
where rn = 1 and  director_name <>'Unknown'
order by movie_released_count desc, release_year desc ;


 /* 13. for each year, which director has the maximum movies released in the netflix as per date_added attributes */
 
 with cte as (select year(nr.date_added) as date_added, d.director_name, count(distinct d.show_id) as movie_released_count
 , row_number()over(partition by year(nr.date_added) order by count(distinct d.show_id) desc)  rn 
 from netflix_raw nr join director d on nr.show_id = d.show_id
 where nr.type = 'Movie' and  d.director_name is not null and d.director_name <> ''
 group by nr.date_added, d.director_name
 )
 
 select date_added, director_name,  movie_released_count from cte 
 where rn =1 and director_name <> 'Unknown' order by movie_released_count desc, 
         date_added desc;
 
/* 14. What is the Average season for tv shows in each genre */
 
select genre_type,round( avg(total_number_of_seasons),2) from netflix_raw nr
 join netflix_genre g on g.show_id = nr.show_id where nr.type='TV Show' 
 group by genre_type;
 
/* 15. Find the List of director who has created horror as well as comedy movie both 
 Display director name along with number of comedy and horror movies directed by them  */
 
select director_name, g.genre_type , 
count(distinct d.show_id) as show_count from netflix_director d 
join netflix_genre g on d.show_id = g.show_id
join netflix_raw nr on nr.show_id = g.show_id
where g.genre_type in ('Comedies' , 'Horror Movies') and  nr.type ='Movie'
and d.director_name is not null and d.director_name <> '' group by 1,2
order by director_name desc , show_count desc;

select distinct genre_type from netflix_genre;
 
 /* 16. For each director count the no of movies and tv shows created by them.
      */
select 
    d.director_name,                                    -- Director's name
    sum(case when nr.type = 'Movie' then 1 else 0 end) as movies_count,  -- Count of movies
    sum(case when nr.type = 'TV Show' then 1 else 0 end) as tv_show_count  -- Count of TV shows
from 
    netflix_raw nr
join 
    netflix_director d 
    on nr.show_id = d.show_id
where 
    d.director_name is not null  and director_name <>'Unknown'                       -- Exclude rows where director_name is null
group by 
    d.director_name                                     -- Group by director to get counts for each
order by 
    movies_count desc,                                  -- Optionally order by number of movies
    tv_show_count desc;                                 -- and then by number of TV shows

 
 
 

