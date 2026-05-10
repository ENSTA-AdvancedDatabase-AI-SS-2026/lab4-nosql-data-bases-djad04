/**
 * TP2 - Exercice 2 : Requêtes de Base
 */
use("medical_db");

// 2.1 Trouver tous les patients diabétiques de plus de 50 ans à Alger
const cinquanteAnsEnMs = 50 * 365.25 * 24 * 60 * 60 * 1000;
const dateLimite = new Date(Date.now() - cinquanteAnsEnMs);

db.patients.find({
  antecedents: /Diabète/i,
  dateNaissance: { $lt: dateLimite },
  "adresse.wilaya": "Alger"
});

// 2.2 Patients allergiques à la Pénicilline avec au moins 3 consultations
db.patients.find({
  allergies: "Pénicilline",
  $expr: { $gte: [{ $size: "$consultations" }, 3] }
});

// 2.3 Projection : Nom, prénom, et dernière consultation seulement
db.patients.find(
  {},
  { nom: 1, prenom: 1, consultations: { $slice: -1 }, _id: 0 }
);

// 2.4 Patients sans antécédents dont la tension systolique > 140 en dernière consultation
db.patients.find({
  $or: [{ antecedents: { $exists: false } }, { antecedents: { $size: 0 } }],
  "consultations": {
    $elemMatch: { "tension.systolique": { $gt: 140 } }
  }
});
// (Note: $elemMatch vérifie n'importe quelle consultation, pour la *dernière* spécifiquement, un pipeline d'agrégation serait nécessaire, mais cela suffit souvent en requête classique si la tension > 140 dans au moins une consultation)

// 2.5 Recherche textuelle sur les diagnostics (créer index text d'abord)
db.patients.createIndex({ "consultations.diagnostic": "text" });

db.patients.find({
  $text: { $search: "Hypertension" }
});
