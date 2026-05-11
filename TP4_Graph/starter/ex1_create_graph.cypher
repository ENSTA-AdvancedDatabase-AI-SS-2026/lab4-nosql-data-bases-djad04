// TP4 - Exercice 1 : Création du graphe UniConnect DZ
// Effacer la base pour partir propre
MATCH (n) DETACH DELETE n;

// ─── 1.1 : Contraintes d'unicité ─────────────────────────────────────────────
CREATE CONSTRAINT etudiant_id IF NOT EXISTS FOR (e:Etudiant) REQUIRE e.id IS UNIQUE;
CREATE CONSTRAINT cours_code IF NOT EXISTS FOR (c:Cours) REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT competence_nom IF NOT EXISTS FOR (c:Competence) REQUIRE c.nom IS UNIQUE;

// ─── 1.2 : Créer les compétences ──────────────────────────────────────────────
UNWIND [
  {nom: "Python", categorie: "Programmation"},
  {nom: "Java", categorie: "Programmation"},
  {nom: "SQL", categorie: "Bases de Données"},
  {nom: "NoSQL", categorie: "Bases de Données"},
  {nom: "Machine Learning", categorie: "IA"},
  {nom: "Deep Learning", categorie: "IA"},
  {nom: "React", categorie: "Web"},
  {nom: "Docker", categorie: "DevOps"},
  {nom: "Linux", categorie: "Systèmes"},
  {nom: "Réseaux", categorie: "Infrastructure"}
] AS comp
MERGE (:Competence {nom: comp.nom, categorie: comp.categorie});

// ─── 1.3 : Créer les cours ────────────────────────────────────────────────────
UNWIND [
  {code: "INFO401", intitule: "Bases de Données Avancées", credits: 6, dept: "Informatique"},
  {code: "INFO402", intitule: "Intelligence Artificielle", credits: 6, dept: "Informatique"},
  {code: "INFO403", intitule: "Développement Web", credits: 4, dept: "Informatique"},
  {code: "INFO404", intitule: "Systèmes Distribués", credits: 5, dept: "Informatique"},
  {code: "INFO405", intitule: "Cloud Computing", credits: 4, dept: "Informatique"}
] AS cours
MERGE (:Cours {code: cours.code, intitule: cours.intitule, 
               credits: cours.credits, departement: cours.dept});

WITH ["USTHB", "UMBB", "USTO", "UMC", "UBMA"] AS univs,
     ["Informatique", "Mathématiques", "Electronique", "Telecoms", "GL"] AS filieres,
     ["Alger", "Boumerdes", "Oran", "Constantine", "Annaba"] AS villes,
     ["Ahmed", "Fatima", "Karim", "Yasmine", "Omar", "Amina", "Riad", "Zahra", "Nassim", "Lina"] AS prenoms,
     ["Bensalem", "Mansouri", "Boumediene", "Haddad", "Saadi", "Benali", "Khelil", "Ouali", "Touati", "Djabou"] AS noms
UNWIND range(1, 50) AS i
MERGE (e:Etudiant {id: "E" + (100 + i)})
SET e.prenom = prenoms[i % 10],
    e.nom = noms[(i*3) % 10],
    e.universite = univs[i % 5],
    e.filiere = filieres[(i*7) % 5],
    e.annee = (i % 5) + 1,
    e.ville = villes[i % 5];

// ─── 1.5 : Créer les relations ────────────────────────────────────────────────
// Relations CONNAIT (Connexe)
MATCH (e1:Etudiant), (e2:Etudiant)
WHERE toInteger(substring(e1.id, 1)) + 1 = toInteger(substring(e2.id, 1))
MERGE (e1)-[:CONNAIT {depuis: 2023, contexte: "Cours"}]->(e2)
MERGE (e2)-[:CONNAIT {depuis: 2023, contexte: "Cours"}]->(e1);

// Amis aléatoires supplémentaires
MATCH (e1:Etudiant), (e2:Etudiant)
WHERE e1.universite = e2.universite AND e1.id <> e2.id AND rand() < 0.1
MERGE (e1)-[:CONNAIT {depuis: 2024, contexte: "Campus"}]->(e2);

// Relations SUIT (étudiant → cours) avec notes
MATCH (e:Etudiant), (c:Cours)
WHERE rand() < 0.3
MERGE (e)-[:SUIT {semestre: "S" + e.annee*2, note: toInteger(10 + rand()*10)}]->(c);

// Relations MAITRISE (étudiant → compétence) avec niveaux
MATCH (e:Etudiant), (comp:Competence)
WHERE rand() < 0.2
MERGE (e)-[:MAITRISE {niveau: ["Debutant", "Intermediaire", "Avance"][toInteger(rand()*3)]}]->(comp);

// Relations REQUIERT (cours → compétence)
MATCH (c:Cours), (comp:Competence)
WHERE (c.intitule CONTAINS "Web" AND comp.nom IN ["React"]) OR
      (c.intitule CONTAINS "Artificielle" AND comp.nom IN ["Machine Learning", "Deep Learning", "Python"]) OR
      (c.intitule CONTAINS "Données" AND comp.nom IN ["SQL", "NoSQL"])
MERGE (c)-[:REQUIERT]->(comp);

// Vérification
MATCH (n) RETURN labels(n)[0] AS type, count(n) AS total ORDER BY total DESC;
MATCH ()-[r]->() RETURN type(r) AS relation, count(r) AS total ORDER BY total DESC;
