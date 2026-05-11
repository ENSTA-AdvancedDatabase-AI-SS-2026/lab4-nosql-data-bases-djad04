# Rapport TP4 - Neo4j

## 1. Schéma du Graphe
Le graphe `UniConnect DZ` comprend les éléments suivants :
- **Nœuds** : `:Etudiant`, `:Cours`, `:Competence` (les labels Entreprise et Club peuvent être ajoutés pour étendre le graphe).
- **Relations** : 
  - `(:Etudiant)-[:CONNAIT]->(:Etudiant)` (Relations sociales, amis).
  - `(:Etudiant)-[:SUIT]->(:Cours)` (Inscriptions).
  - `(:Etudiant)-[:MAITRISE]->(:Competence)` (Aptitudes).
  - `(:Cours)-[:REQUIERT]->(:Competence)` (Prérequis).

## 2. Algorithme de Communautés (Louvain)
L'algorithme de Louvain (`gds.louvain.stream`) a permis de détecter les "cercles sociaux" (communautés) au sein du réseau d'étudiants. 
Les communautés détectées se forment principalement autour de deux axes :
1. **L'université d'appartenance** : Les probabilités de connexions entre étudiants de la même université (ex: USTHB) étant plus fortes, Louvain groupe naturellement ces étudiants.
2. **Le parcours séquentiel** : Comme la construction initiale reliait chaque étudiant à son voisin ID, des chaînes locales se forment.
Le résultat de l'algorithme attribue un `communityId` à chaque étudiant, ce qui permet à UniConnect DZ de recommander des groupes de travail ou de suggérer des clubs locaux en fonction de la communauté dominante.

## 3. Comparaison SQL vs Cypher : Amis d'amis
**Cas pratique : Trouver les amis de mes amis qui ne sont pas déjà mes amis.**

**En SQL (Modèle relationnel) :**
```sql
SELECT DISTINCT fof.prenom, fof.nom
FROM etudiants moi
JOIN connait c1 ON moi.id = c1.etudiant_id1
JOIN etudiants ami ON c1.etudiant_id2 = ami.id
JOIN connait c2 ON ami.id = c2.etudiant_id1
JOIN etudiants fof ON c2.etudiant_id2 = fof.id
WHERE moi.prenom = 'Ahmed'
  AND fof.id != moi.id
  AND fof.id NOT IN (
      SELECT etudiant_id2 FROM connait WHERE etudiant_id1 = moi.id
  );
```
*Complexité et lisibilité* : Le SQL est très verbeux. Il nécessite de multiples JOINs sur la table de liaison `connait`, rendant la requête difficile à lire. Côté performance, c'est très lourd sur de gros volumes car le moteur doit calculer les produits cartésiens des JOINs.

**En Cypher (Graphe) :**
```cypher
MATCH (moi:Etudiant {prenom: "Ahmed"})-[:CONNAIT*2]-(fof:Etudiant)
WHERE NOT (moi)-[:CONNAIT]-(fof) AND moi <> fof
RETURN DISTINCT fof.prenom, fof.nom;
```
*Complexité et lisibilité* : Cypher est extrêmement expressif grâce à son pattern matching de type ASCII-art (`-[:CONNAIT*2]-` pour exactement 2 sauts). La lisibilité est immédiate. Côté performance, Neo4j n'utilise pas d'index globaux pour les jointures mais suit les pointeurs directs en mémoire (Index-free adjacency), ce qui maintient des temps de réponse ultra-rapides indépendamment du volume total de la base.
