const {onDocumentCreated} = require("firebase-functions/v2/firestore");
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

      const query = await db
          .collection("expenses")
          .where("projectId", "==", projectId)
          .where("date", "==", date)
          .get();

      if (!query.empty) {
        const doc = query.docs[0];

        await doc.ref.update({
          labourCost: admin.firestore.FieldValue.increment(amount),
          totalCost: admin.firestore.FieldValue.increment(amount),
        });
      } else {
        await db.collection("expenses").add({
          projectId: projectId,
          date: date,
          labourCost: amount,
          materialCost: 0,
          otherCost: 0,
          totalCost: amount,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    },
);
