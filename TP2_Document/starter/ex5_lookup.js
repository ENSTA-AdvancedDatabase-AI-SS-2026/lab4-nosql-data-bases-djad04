/**
 * TP2 - Exercice 5 : $lookup et Données Référencées
 */
use("medical_db");

// 5.1 Joindre patients et analyses pour récupérer le dossier complet d'un patient
const dossierComplet = db.patients.aggregate([
  {
    $lookup: {
      from: "analyses",
      localField: "_id",
      foreignField: "patient_id",
      as: "dossier_analyses"
    }
  },
  { $limit: 1 }
]).toArray();

print("Dossier complet (1 patient):");
printjson(dossierComplet);

// 5.2 Trouver les patients dont la glycémie dépasse 1.26 g/L
const patientsHyperglycemie = db.analyses.aggregate([
  {
    $match: {
      type: "Glycémie",
      "resultats.valeur": { $gt: 1.26 }
    }
  },
  {
    $lookup: {
      from: "patients",
      localField: "patient_id",
      foreignField: "_id",
      as: "info_patient"
    }
  },
  { $unwind: "$info_patient" },
  {
    $project: {
      _id: 0,
      nom: "$info_patient.nom",
      prenom: "$info_patient.prenom",
      valeur_glycemie: "$resultats.valeur"
    }
  }
]).toArray();

print("Patients avec glycémie > 1.26 g/L:");
printjson(patientsHyperglycemie);

// 5.3 Statistiques croisées : taux d'analyses anormales par wilaya
const anomaliesParWilaya = db.analyses.aggregate([
  {
    $match: {
      "resultats.valeur": { $gt: 1.26 } // Considéré anormal pour ce test
    }
  },
  {
    $lookup: {
      from: "patients",
      localField: "patient_id",
      foreignField: "_id",
      as: "patient"
    }
  },
  { $unwind: "$patient" },
  {
    $group: {
      _id: "$patient.adresse.wilaya",
      nombre_anomalies: { $sum: 1 }
    }
  },
  { $sort: { nombre_anomalies: -1 } }
]).toArray();

print("Anomalies par wilaya:");
printjson(anomaliesParWilaya);
