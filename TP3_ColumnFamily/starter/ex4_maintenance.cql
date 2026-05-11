-- TP3 - Exercice 4 : Compaction et Maintenance

-- 4.1 Choisir la stratégie de compaction pour chaque table
-- Pour les mesures brutes : TimeWindowCompactionStrategy (TWCS).
-- TWCS est conçu pour les séries temporelles. Il groupe les données dans des fenêtres de temps (ex: 1 jour).
-- Quand le TTL est atteint, la SSTable entière est supprimée d'un coup, sans surcoût d'E/S (I/O).

-- 4.2 Configurer TWCS pour les mesures
ALTER TABLE mesures_par_capteur
WITH compaction = {
  'class': 'TimeWindowCompactionStrategy',
  'compaction_window_unit': 'DAYS',
  'compaction_window_size': 1
};

-- 4.3 Vérifier l'utilisation des TTL
-- Affiche le temps restant (en secondes) avant suppression pour les colonnes.
SELECT TTL(tension_v), TTL(courant_a) FROM mesures_par_capteur LIMIT 10;

-- 4.4 Analyser une partition "hot"
-- Pour détecter une hot partition, on peut utiliser nodetool (ex: nodetool tablestats, nodetool toppartitions).
-- Pour la corriger, on modifie le modèle de données, par exemple en ajoutant une composante "date" à la clé de partition (bucketisation) pour répartir la charge temporelle sur plusieurs nœuds.
