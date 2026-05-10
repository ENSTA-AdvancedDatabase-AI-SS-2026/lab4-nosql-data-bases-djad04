/**
 * TP2 - Exercice 1 : Modélisation MongoDB
 * Use Case : HealthCare DZ - Dossiers Médicaux
 */

use("medical_db");
db.dropDatabase();

db.createCollection("patients", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["cin", "nom", "prenom", "dateNaissance", "sexe"],
      properties: {
        cin: { bsonType: "string", description: "CIN obligatoire" },
        nom: { bsonType: "string" },
        prenom: { bsonType: "string" },
        dateNaissance: { bsonType: "date" },
        sexe: { enum: ["M", "F"] },
        adresse: { bsonType: "object", required: ["wilaya"] }
      }
    }
  }
});

const wilayas = ["Alger", "Oran", "Constantine", "Annaba", "Blida"];
const noms = ["Bensalem", "Mansouri", "Boumediene", "Haddad", "Saadi", "Benali", "Khelil"];
const prenoms = ["Ahmed", "Fatima", "Karim", "Yasmine", "Omar", "Amina", "Riad", "Zahra", "Nassim", "Lina"];

const patients = [];
for (let i = 0; i < 20; i++) {
  patients.push({
    cin: "19800" + (1000 + i),
    nom: noms[i % noms.length],
    prenom: prenoms[i % prenoms.length],
    dateNaissance: new Date(`19${70 + (i % 20)}-01-01`),
    sexe: i % 2 === 0 ? "M" : "F",
    adresse: { wilaya: wilayas[i % wilayas.length], commune: "Centre" },
    groupeSanguin: i % 3 === 0 ? "O+" : "A+",
    antecedents: i % 2 === 0 ? ["Diabète type 2", "HTA"] : (i % 3 === 0 ? ["Asthme"] : []),
    allergies: i % 5 === 0 ? ["Pénicilline"] : [],
    consultations: [
      {
        id: UUID(),
        date: new Date(`2024-0${1 + (i % 9)}-15`),
        medecin: { nom: "Dr. Touati", specialite: "Généraliste" },
        diagnostic: i % 2 === 0 ? "Hypertension artérielle" : "Grippe",
        tension: { systolique: 120 + i, diastolique: 80 + (i % 10) },
        medicaments: [
          { nom: "Paracétamol", dosage: "1g", duree: "5 jours" }
        ],
        notes: "Rien à signaler"
      },
      {
        id: UUID(),
        date: new Date(`2023-0${1 + (i % 9)}-10`),
        medecin: { nom: "Dr. Mansouri", specialite: "Cardiologie" },
        diagnostic: "Visite de contrôle",
        tension: { systolique: 130, diastolique: 85 },
        medicaments: [],
        notes: "Bon état général"
      }
    ]
  });
}

db.patients.insertMany(patients);

const analyses = [];
let dbPatients = db.patients.find().toArray();
for (let i = 0; i < dbPatients.length; i++) {
  analyses.push({
    patient_id: dbPatients[i]._id,
    date: new Date("2024-05-01"),
    type: "Glycémie",
    resultats: { valeur: 1.1 + (i % 5) * 0.1, unite: "g/L" },
    laboratoire: "Labo Central Alger",
    valide: true
  });
}

db.analyses.insertMany(analyses);

print("✅ Modélisation terminée. Patients insérés:", db.patients.countDocuments());
print("✅ Analyses insérées:", db.analyses.countDocuments());
