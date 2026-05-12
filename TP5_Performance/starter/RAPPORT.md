# Rapport TP5 - Performance & Optimisation NoSQL

## Tableau de Recommandation

| Critère | Redis | MongoDB | Cassandra | Neo4j |
|---------|-------|---------|-----------|-------|
| **Débit écriture** | Extrêmement Élevé (>100k/s en pipeline) | Élevé (~10k-50k/s avec `insertMany`) | Très Élevé (optimisé pour `APPEND`, sans locks) | Modéré (les relations nécessitent des `MERGE` coûteux) |
| **Débit lecture** | Extrêmement Élevé (In-Memory, <1ms latence) | Élevé (B-Trees indexes, très performant) | Élevé (Par clé de partition `Point Lookup` O(1)) | Lent / Modéré (Traversal de graphe complexe) |
| **Requêtes complexes** | Faible (limité aux structures basiques, pas de jointures) | Très Fort (Aggregation Pipeline puissant, `$lookup`) | Très Faible (Pas de jointures, pas d'agrégation native, pas de `ALLOW FILTERING`) | Excellent (Jointures N-niveaux instantanées via `MATCH`) |
| **Scalabilité** | Limitée par la RAM (Bien que Redis Cluster aide) | Horizontale (Sharding natif) | Horizontale Massive (Masterless, Peer-to-Peer, tolérance pannes) | Horizontale limitée (Scale out read-replicas, write scale difficile) |
| **Use case idéal** | **Cache**, Leaderboard, Sessions | **Documents**, CMS, E-commerce, Profils | **IoT**, Time-Series, Logs massifs | **Graphe**, Réseaux sociaux, Recommandations, Fraude |

## Analyse et Recommandations
Chaque base répond à un paradigme spécifique selon le **théorème CAP** et l'**architecture système** :
- **Redis** est à choisir pour des **opérations temps réel** où la persistance est optionnelle et la latence doit être inférieure à la milliseconde. Idéal pour éponger des pics de trafic (Burst).
- **MongoDB** offre un compromis parfait pour les applications orientées objet grâce à sa flexibilité de schéma et son moteur d'agrégation. C'est la base de données **General Purpose** par excellence dans l'écosystème NoSQL.
- **Cassandra** est imbattable dès qu'il s'agit d'ingérer d'immenses volumes de données sans jamais bloquer (`write-heavy`). Elle brille particulièrement pour les métriques de **capteurs IoT** ou de transactions bancaires distribuées globalement (Active-Active).
- **Neo4j** ne se choisit pas pour son débit brut, mais pour son **modèle de relations**. Là où PostgreSQL fait s'écrouler le serveur à la 3ème jointure, Neo4j traverse 10 sauts de profondeur en une fraction de seconde. Il est irremplaçable pour la modélisation de **réseaux complexes**.

> **Recommandation finale** : Le choix d'une base de données NoSQL (ou SQL) ne se fait jamais par "quelle est la plus rapide" de manière absolue, mais "quelle structure de données correspond à mon type de requête le plus fréquent". C'est le principe de la Polyglot Persistence.
