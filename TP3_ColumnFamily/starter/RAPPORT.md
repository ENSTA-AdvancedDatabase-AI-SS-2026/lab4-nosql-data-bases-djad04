# Rapport TP3 - Cassandra

## 1. Justification des clés de partition et du modèle (Hot Partitions)
Dans Cassandra, le choix de la clé de partition (Partition Key) est critique car il détermine sur quel nœud physique la donnée sera stockée.
- **`mesures_par_capteur`** : La Primary Key est `((capteur_id, date_jour), timestamp)`. La clé de partition composée de `capteur_id` et `date_jour` (Bucketisation) garantit que les données d'un capteur pour une journée donnée restent sur le même nœud. Sans la `date_jour`, une partition grandirait indéfiniment (unbounded partition), créant une "hot partition" et s'étouffant au fil des années.
- **`alertes_par_wilaya`** : La PK est `((wilaya, date_jour), timestamp, capteur_id)`. Le même principe s'applique : on groupe par wilaya et par jour pour que le dashboard puisse charger très vite toutes les alertes récentes d'une région sans scanner toute la base.

## 2. Pourquoi `ALLOW FILTERING` est dangereux en production
La commande `ALLOW FILTERING` permet à Cassandra d'exécuter une requête en filtrant des colonnes qui ne font pas partie de la clé primaire. Pour cela, Cassandra doit souvent lire les données sur de multiples nœuds, ramener des mégaoctets voire gigaoctets de données en mémoire sur le nœud coordinateur, puis filtrer les lignes correspondantes.
- En production, sous forte charge (ex: 10 000 capteurs), cela provoque des temps de réponse imprévisibles, une saturation du CPU et de la mémoire, et souvent un Timeout (Crash).
- **Règle d'or** : Si on a besoin de filtrer sur un attribut, il faut créer une nouvelle table où cet attribut fait partie de la Primary Key, ou utiliser un index secondaire (avec précaution).

## 3. Comparaison TWCS vs STCS vs LCS
- **TWCS (TimeWindowCompactionStrategy)** : Idéal pour nos capteurs IoT. Les données arrivent dans l'ordre chronologique et expirent. TWCS regroupe les SSTables par fenêtres de temps (ex: 1 jour). À la fin du TTL (90 jours), Cassandra supprime simplement le fichier complet sans consommer de CPU ni d'E/S (I/O).
- **STCS (SizeTieredCompactionStrategy)** : C'est la méthode par défaut. Elle fusionne des SSTables de tailles similaires. C'est idéal pour des écritures intensives (append-heavy) avec des données qui n'expirent pas forcément (ex: logs bruts sans TTL ou données modifiées).
- **LCS (LeveledCompactionStrategy)** : Idéal pour des lectures intensives (read-heavy) et des mises à jour fréquentes de la même donnée. LCS maintient des SSTables de taille fixe (généralement 160MB) réparties en niveaux. Elle garantit que 99% des lectures nécessitent l'accès à une seule SSTable, mais elle est très coûteuse en écritures. Pour l'IoT (très write-heavy), LCS est à proscrire.
