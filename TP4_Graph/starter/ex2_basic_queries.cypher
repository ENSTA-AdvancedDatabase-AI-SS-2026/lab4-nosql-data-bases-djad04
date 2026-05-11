// TP4 - Exercice 2 : Requêtes de Base

// 2.1 Trouver tous les amis d'Ahmed (1 saut)
MATCH (ahmed:Etudiant {prenom: "Ahmed"})-[:CONNAIT]-(ami:Etudiant)
RETURN ami.prenom, ami.nom, ami.universite;

// 2.2 Trouver les amis d'amis d'Ahmed qui ne sont pas déjà ses amis
MATCH (ahmed:Etudiant {prenom: "Ahmed"})-[:CONNAIT*2]-(fof:Etudiant)
WHERE NOT (ahmed)-[:CONNAIT]-(fof) AND ahmed <> fof
RETURN DISTINCT fof.prenom, fof.nom, fof.universite;

// 2.3 Étudiants qui suivent le même cours que Fatima mais ne la connaissent pas
MATCH (fatima:Etudiant {prenom: "Fatima"})-[:SUIT]->(c:Cours)<-[:SUIT]-(autre:Etudiant)
WHERE NOT (fatima)-[:CONNAIT]-(autre) AND fatima <> autre
RETURN DISTINCT autre.prenom, autre.nom, c.intitule AS cours_commun;

// 2.4 Clubs les plus populaires (s'ils existent, sinon requêtes similaires sur les Cours)
// Si on avait ajouté des clubs, on ferait:
// MATCH (e:Etudiant)-[:MEMBRE_DE]->(c:Club) RETURN c.nom, count(e) AS membres ORDER BY membres DESC LIMIT 5;
// Pour les cours les plus populaires :
MATCH (e:Etudiant)-[:SUIT]->(c:Cours)
RETURN c.intitule, count(e) AS nb_etudiants
ORDER BY nb_etudiants DESC LIMIT 5;

// 2.5 Profil complet d'un étudiant : amis, cours, compétences
MATCH (e:Etudiant {prenom: "Ahmed"})
OPTIONAL MATCH (e)-[:CONNAIT]-(ami:Etudiant)
OPTIONAL MATCH (e)-[:SUIT]->(c:Cours)
OPTIONAL MATCH (e)-[:MAITRISE]->(comp:Competence)
RETURN e.prenom, e.nom,
       collect(DISTINCT ami.prenom) AS amis,
       collect(DISTINCT c.code) AS cours,
       collect(DISTINCT comp.nom) AS competences;
