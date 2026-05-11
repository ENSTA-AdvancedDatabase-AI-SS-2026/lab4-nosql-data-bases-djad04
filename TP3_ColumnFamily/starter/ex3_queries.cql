-- TP3 - Exercice 3 : Requêtes CQL

-- 3.1 Mesures d'un capteur spécifique sur les dernières 6 heures
SELECT * FROM mesures_par_capteur
WHERE capteur_id = 123e4567-e89b-12d3-a456-426614174000 
  AND date_jour = '2024-05-15' 
  AND timestamp >= '2024-05-15 08:00:00';

-- 3.2 Dernière mesure de chaque capteur d'une wilaya
-- (En théorie avec une table partitionnée par wilaya)
-- SELECT * FROM mesures_par_wilaya WHERE wilaya = 'Alger' LIMIT 1;

-- 3.3 Capteurs en alerte dans la wilaya "Alger" aujourd'hui
SELECT count(*) FROM alertes_par_wilaya WHERE wilaya = 'Alger' AND date_jour = '2024-05-15';
SELECT * FROM alertes_par_wilaya WHERE wilaya = 'Alger' AND date_jour = '2024-05-15';

-- 3.4 Consommation totale par heure sur une journée (dashboard)
SELECT * FROM agregats_horaires WHERE wilaya = 'Alger' AND date_heure >= '2024-05-15 00:00:00' AND date_heure <= '2024-05-15 23:59:59';

-- 3.5 Détection d'anomalie : capteurs avec tension < 200V ou > 240V
-- Cassandra ne gère pas les OR. On doit gérer cette logique applicativement ou avec plusieurs requêtes.

-- 3.7 Requête ALLOW FILTERING : Pourquoi éviter ?
-- SELECT * FROM mesures_par_capteur WHERE tension_v > 240 ALLOW FILTERING;
-- Solution propre: Créer une table `alertes_tension_haute` où la tension est la clustering key ou utiliser une vue matérialisée.
