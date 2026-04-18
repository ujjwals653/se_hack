const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccount.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initCollections() {
  
  // 1. timetable_entries
  await db.collection("timetable_entries").doc("init").set({
    id: "init",
    subjectName: "init",
    weekday: 1,
    startTime: "00:00",
    endTime: "00:00",
    room: "init",
    professorName: "init",
    userId: "init"
  });

  // 2. attendance_records
  await db.collection("attendance_records").doc("init").set({
    id: "init",
    timetableEntryId: "init",
    date: new Date(),
    attended: false,
    userId: "init"
  });

  // 3. expenses
  await db.collection("expenses").doc("init").set({
    id: "init",
    label: "init",
    amount: 0,
    category: "other",
    date: new Date(),
    note: "init",
    userId: "init"
  });

  // 4. kanban_tasks
  await db.collection("kanban_tasks").doc("init").set({
    id: "init",
    roomId: "init",
    title: "init",
    description: "init",
    status: "doing",
    assignedTo: "init",
    position: 0,
    createdAt: new Date(),
    updatedAt: new Date()
  });

  // 5. heatmap_entries
  await db.collection("heatmap_entries").doc("init").set({
    id: "init",
    date: new Date(),
    stressLevel: 0,
    source: "init",
    label: "init",
    userId: "init"
  });

  console.log("✅ All collections created successfully!");
}

initCollections().catch(console.error);
