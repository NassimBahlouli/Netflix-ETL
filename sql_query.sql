-- Ce fichier comporte toutes les commandes SQL utilisées --


-- 1) Création de la base de données NETFLIX
CREATE DATABASE NETFLIX;

--2) Executer une requete pour voir l’ensemble de données et comprendre sa structure et son contenu. ( j'ai affiché une seule ligne )
SELECT * FROM netflix_rawn LIMIT 1;



SELECT * FROM netflix_raw ORDER BY title DESC;

SELECT * FROM netflix_raw WHERE show_id = 's5023';


--I. Vérification des doublons dans les attributs Show_ID 
SELECT SHOW_ID, COUNT(*) AS DUPS_COUNT
FROM NETFLIX_RAW
GROUP BY SHOW_ID
HAVING COUNT(*) > 1;
