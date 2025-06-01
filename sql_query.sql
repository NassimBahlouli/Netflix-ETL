-- Ce fichier comporte toutes les commandes SQL utilisées --


-- 1) Création de la base de données NETFLIX
CREATE DATABASE NETFLIX;

--2) Executer une requete pour voir l’ensemble de données et comprendre sa structure et son contenu. ( j'ai affiché une seule ligne )
SELECT * 
FROM netflix_rawn 
LIMIT 1;



SELECT * 
FROM netflix_raw 
ORDER BY title DESC;

SELECT * FROM NETFLIX_Raw WHERE show_id = 's5023';


--I. Vérification des doublons dans les attributs Show_ID 
SELECT SHOW_ID, COUNT(*) AS DUPS_COUNT
FROM NETFLIX_Raw
GROUP BY SHOW_ID
HAVING COUNT(*) > 1;


ALTER TABLE NETFLIX_RAW
MODIFY COLUMN SHOW_ID VARCHAR(12) PRIMARY KEY;


-- II. Vérification des doublons dans l'attribut titre¶
SELECT title, COUNT(*) AS dups_count FROM netflix_raw
GROUP BY title HAVING COUNT(*) > 1;
