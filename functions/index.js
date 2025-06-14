// const functions = require("firebase-functions");
// const admin = require("firebase-admin");
// admin.initializeApp();
// const db = admin.firestore();

// const { VertexAI } = require("@google-cloud/vertexai");

// const vertex_ai = new VertexAI({
//   project: "finalproject-a3615",
//   location: "asia-east1",
// });

// const model = vertex_ai.getGenerativeModel({
//   model: "gemini-1.5-pro-preview", 
//   safetySettings: [],
// });

// exports.recommendCourses = functions.https.onRequest(async (req, res) => {
//   const studentId = req.body.studentId;

//   if (!studentId) {
//     return res.status(400).send("studentId is required");
//   }

//   try {
//     const takenCoursesSnap = await db
//       .collection("Student")
//       .doc(studentId)
//       .collection("COURSE")
//       .get();

//     const takenCourses = [];
//     for (const doc of takenCoursesSnap.docs) {
//       const courseId = doc.id;
//       const courseResult = doc.data();

//       const allCoursesSnap = await db
//         .collection("Course")
//         .where(admin.firestore.FieldPath.documentId(), "==", courseId)
//         .get();

//       if (!allCoursesSnap.empty) {
//         const courseDetails = allCoursesSnap.docs[0].data();
//         takenCourses.push({
//           id: courseId,
//           name: courseDetails.english_title,
//           credit: courseDetails.credit,
//           score: courseResult["T-SCORE"],
//           grade: courseResult["GRADE"],
//         });
//       }
//     }

//     const prompt = `
// This student has taken the following courses:
// ${takenCourses
//   .map(
//     (c) =>
//       `- ${c.name} (Credit: ${c.credit}, Grade: ${c.grade}, Score: ${c.score})`
//   )
//   .join("\n")}

// Please recommend courses for the next semester.
// `;

//     const result = await model.generateContent({
//       contents: [{ role: "user", parts: [{ text: prompt }] }],
//     });

//     const response = result.response;

//     return res.json({
//       recommendation:
//         response.candidates?.[0]?.content?.parts?.[0]?.text || "No response.",
//     });
//   } catch (err) {
//     console.error(err);
//     return res.status(500).send("Server error");
//   }
// });

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp({
  projectId: "finalproject-a3615" // Replace with your Firebase project ID
});

exports.sendNewsNotification = onDocumentCreated("News/{newsId}", async (event) => {
  try {
    const snapshot = event.data;
    const newsData = snapshot.data();

    console.log("News created:", newsData);

    const tokensSnapshot = await admin.firestore().collection("fcm_tokens").get();
    const tokens = tokensSnapshot.docs.map((doc) => doc.id).filter(t => t.length > 100);

    console.log("Tokens found:", tokens);

    if (tokens.length === 0) {
      console.log("No valid tokens to notify.");
      return null;
    }

    const result = await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: "NEW NEWS POSTED!",
        body: newsData.english_title || "Check out the latest updates",
      },
      data: {
        type: "news",
        id: event.params.newsId,
      }
    });
    console.log("✅ Notification sent:", result);

    return result;
  } catch (err) {
    console.error("❌ Notification error:", err);
    throw err;
  }
});


exports.sendTaAppNotification = onDocumentCreated("TA Application/{appId}", async (event) => {
  try {
    const snapshot = event.data;
    const TAdata = snapshot.data();

    console.log("Application created:", TAdata);

    const tokensSnapshot = await admin.firestore().collection("fcm_tokens").get();
    const tokens = tokensSnapshot.docs.map((doc) => doc.id).filter(t => t.length > 100);

    console.log("Tokens found:", tokens);

    if (tokens.length === 0) {
      console.log("No valid tokens to notify.");
      return null;
    }

    const title = `${TAdata.english_title} TA`;
    const professorName = TAdata.professor?.EN || "";
    let body = "Check out the latest updates";
    if (TAdata.english_title && professorName) {
      body = `${title}, ${professorName}`;
    }

    const result = await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: "NEW TA APPLICATION!",
        body: body,
      },
      data: {
        type: "ta_applciation",
        id: event.params.appId,
      }
  });
    console.log("✅ Notification sent:", result);

    return result;
  } catch (err) {
    console.error("❌ Notification error:", err);
    throw err;
  }
});
 
