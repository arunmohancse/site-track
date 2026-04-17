const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onLabourCreated = onDocumentCreated(
  "labour_entries/{docId}",
  async (event) => {
    const data = event.data.data();

    const projectId = data.projectId;
    const date = data.date;
    const amount = data.totalAmount || 0;

    const db = admin.firestore();

    // 🔥 UNIQUE DOC ID
    const expenseId = `${projectId}_${date}`;

    const ref = db.collection("expenses").doc(expenseId);

    await ref.set(
      {
        projectId: projectId,
        date: date,

        labourCost: admin.firestore.FieldValue.increment(amount),
        totalCost: admin.firestore.FieldValue.increment(amount),

        materialCost: 0,
        otherCost: 0,

        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true } // 🔥 IMPORTANT
    );
  }
);