const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.onExpenseRecalculate = onDocumentWritten(
  "{collection}/{docId}",
  async (event) => {
    const collection = event.params.collection;

    // 🔥 Only react to relevant collections
    if (
      collection !== "labour_entries" &&
      collection !== "materials_received"
    ) {
      return;
    }

    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    const projectId = after?.projectId || before?.projectId;
    const date = after?.date || before?.date;

    if (!projectId || !date) return;

    const db = admin.firestore();

    try {
      // 🔥 1. Recalculate LABOUR COST
      const labourSnapshot = await db
        .collection("labour_entries")
        .where("projectId", "==", projectId)
        .where("date", "==", date)
        .get();

      let totalLabourCost = 0;

      labourSnapshot.forEach((doc) => {
        totalLabourCost += doc.data().totalAmount || 0;
      });

      // 🔥 2. Recalculate MATERIAL COST
      const materialSnapshot = await db
        .collection("materials_received")
        .where("projectId", "==", projectId)
        .where("date", "==", date)
        .get();

      let totalMaterialCost = 0;

      materialSnapshot.forEach((doc) => {
        totalMaterialCost += doc.data().totalAmount || 0;
      });

      // 🔥 FINAL TOTAL
      const totalCost = totalLabourCost + totalMaterialCost;

      // 🔥 UNIQUE DOC ID
      const expenseId = `${projectId}_${date}`;

      const ref = db.collection("expenses").doc(expenseId);

      await ref.set(
        {
          projectId: projectId,
          date: date,

          labourCost: totalLabourCost,
          materialCost: totalMaterialCost,
          totalCost: totalCost,

          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

    } catch (error) {
      console.error("Expense recalculation failed:", error);
    }
  }
);