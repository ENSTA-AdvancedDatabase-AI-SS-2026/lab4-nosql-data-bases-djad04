// TP4 - Exercice 4 : Requêtes Avancées

// 4.1 Trouver un tuteur (Étudiant en année > 3 qui maîtrise Python)
MATCH (tuteur:Etudiant)-[:MAITRISE]->(c:Competence {nom: "Python"})
WHERE tuteur.annee > 3
RETURN tuteur.prenom, tuteur.nom, tuteur.annee, tuteur.universite
LIMIT 5;

// 4.2 Réseau alumni (Exemple: Qui de mon réseau jusqu'à 3 sauts travaille chez Sonatrach)
// MATCH (moi:Etudiant {prenom: "Ahmed"})-[:CONNAIT*1..3]-(contact)-[:A_STAGE_CHEZ]->(e:Entreprise {nom: "Sonatrach"})
// RETURN DISTINCT contact.prenom, contact.nom;
// (Requête simulée car Entreprises non insérées massivement dans Ex1)

// 4.3 Détection de ponts (Étudiants qui connectent des universités)
MATCH (e1:Etudiant)-[:CONNAIT]-(pont:Etudiant)-[:CONNAIT]-(e2:Etudiant)
WHERE e1.universite <> pont.universite AND pont.universite <> e2.universite AND e1.universite <> e2.universite
RETURN DISTINCT pont.prenom, pont.nom, pont.universite
LIMIT 10;

// 4.5 Score de similarité (Coefficient de Jaccard) basé sur les cours suivis
MATCH (e1:Etudiant {prenom: "Ahmed"})-[:SUIT]->(c:Cours)<-[:SUIT]-(e2:Etudiant)
WHERE e1 <> e2
WITH e1, e2, count(c) AS intersection
MATCH (e1)-[:SUIT]->(c1:Cours)
WITH e1, e2, intersection, collect(DISTINCT c1) AS s1
MATCH (e2)-[:SUIT]->(c2:Cours)
WITH e1, e2, intersection, s1, collect(DISTINCT c2) AS s2
WITH e1, e2, intersection, size(s1) + size(s2) - intersection AS union
RETURN e2.prenom, e2.nom, (toFloat(intersection) / union) AS jaccard_index
ORDER BY jaccard_index DESC
LIMIT 5;
