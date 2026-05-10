/**
 * TP2 - Exercice 3 : Pipelines d'Agrégation
 * Use Case : Statistiques médicales HealthCare DZ
 */

use("medical_db");

// ─── 3.1 : Distribution des diagnostics par wilaya ────────────────────────────
print("=== 3.1 : Top diagnostics par wilaya ===");

const diagParWilaya = db.patients.aggregate([
  { $unwind: "$consultations" },
  { $group: {
      _id: { wilaya: "$adresse.wilaya", diagnostic: "$consultations.diagnostic" },
      count: { $sum: 1 }
  }},
  { $sort: { count: -1 } },
  { $limit: 20 },
  { $project: { _id: 0, wilaya: "$_id.wilaya", diagnostic: "$_id.diagnostic", count: 1 } }
]).toArray();

// printjson(diagParWilaya);

// ─── 3.2 : Médicament le plus prescrit par spécialité ─────────────────────────
print("\n=== 3.2 : Top médicaments par spécialité ===");

const medsParSpecialite = db.patients.aggregate([
  { $unwind: "$consultations" },
  { $unwind: "$consultations.medicaments" },
  { $group: {
      _id: { specialite: "$consultations.medecin.specialite", medicament: "$consultations.medicaments.nom" },
      count: { $sum: 1 }
  }},
  { $sort: { count: -1 } },
  { $group: {
      _id: "$_id.specialite",
      medicament_top: { $first: "$_id.medicament" },
      prescriptions: { $first: "$count" }
  }}
]).toArray();

// ─── 3.3 : Évolution mensuelle des consultations ──────────────────────────────
print("\n=== 3.3 : Consultations par mois (12 derniers mois) ===");

const evolutionMensuelle = db.patients.aggregate([
  { $unwind: "$consultations" },
  { $match: {
    "consultations.date": {
      $gte: new Date(new Date().setFullYear(new Date().getFullYear() - 1))
    }
  }},
  { $group: {
      _id: { annee: { $year: "$consultations.date" }, mois: { $month: "$consultations.date" } },
      count: { $sum: 1 }
  }},
  { $sort: { "_id.annee": 1, "_id.mois": 1 } },
  { $project: {
      _id: 0,
      mois: { $concat: [ { $toString: "$_id.annee" }, "-", { $cond: [ { $lt: ["$_id.mois", 10] }, { $concat: ["0", { $toString: "$_id.mois" }] }, { $toString: "$_id.mois" } ] } ] },
      count: 1
  }}
]).toArray();

// ─── 3.4 : Patients à risque multiple ────────────────────────────────────────
print("\n=== 3.4 : Profil patients à risque élevé ===");

const patientsRisque = db.patients.aggregate([
  {
    $match: {
      antecedents: { $all: ["Diabète type 2", "HTA"] },
      $expr: {
        $gt: [
          { $divide: [ { $subtract: [ new Date(), "$dateNaissance" ] }, 31557600000 ] },
          60
        ]
      }
    }
  },
  { $addFields: {
      age: { $floor: { $divide: [ { $subtract: [ new Date(), "$dateNaissance" ] }, 31557600000 ] } },
      nb_consultations: { $size: "$consultations" }
  }},
  { $group: {
      _id: null,
      total_patients: { $sum: 1 },
      avg_consultations: { $avg: "$nb_consultations" }
  }}
]).toArray();

// ─── 3.5 : Rapport médecins ───────────────────────────────────────────────────
print("\n=== 3.5 : Top 5 médecins & taux de ré-consultation ===");

const rapportMedecins = db.patients.aggregate([
  { $unwind: "$consultations" },
  { $group: {
      _id: "$consultations.medecin.nom",
      patients_uniques_set: { $addToSet: "$_id" },
      total_consultations: { $sum: 1 }
  }},
  { $addFields: {
      patients_uniques: { $size: "$patients_uniques_set" }
  }},
  { $addFields: {
      taux_reconsultation: {
        $multiply: [
          { $divide: [
              { $subtract: [ "$total_consultations", "$patients_uniques" ] },
              "$patients_uniques"
          ]},
          100
        ]
      }
  }},
  { $sort: { total_consultations: -1 } },
  { $limit: 5 },
  { $project: { patients_uniques_set: 0 } }
]).toArray();

printjson(rapportMedecins);
