import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Initialize Firebase Admin SDK
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

# List of questions
questions = [
    # Probability-related
    "probability of passing [course]",
    "probability of getting an A in [course]",
    "probability of getting a B+ in [course]",
    "probability of failing [course]",
    "probability of improving in [course] this semester",
    "probability of graduating in 4 years",
    "probability of entering top CS graduate program",
    "probability of becoming a TA for [course]",
    "probability of doing well in [course] after poor midterm",
    "probability of qualifying for honors program",
    "probability of internship acceptance with current GPA",
    "probability of GPA rising if I ace [course]",
    "probability of being accepted into the AI track",
    "probability of passing final exam in [course]",
    "probability of being recommended for research based on [course] score",
    "probability of finishing senior project on time",

    # Recommend-related
    "recommend similar courses to [course]",
    "recommend replacements for [course]",
    "recommend easier version of [course]",
    "recommend elective courses for EECS majors",
    "recommend project topics based on [course]",
    "recommend study partners for [course]",
    "recommend tutorials for [course]",
    "recommend summer courses to boost GPA",
    "recommend courses for Machine Learning track",
    "recommend professors with good reviews for [course]",
    "recommend lab courses with low workload",
    "recommend job roles related to [course]",
    "recommend research topics in [course]",
    "recommend online resources for [course]",
    "recommend which of my courses to drop",
    "recommend combinations of [course1] and [course2]",

    # How to…
    "how to catch up in [course]",
    "how to prepare for midterm in [course]",
    "how to pass [course] with minimal stress",
    "how to build portfolio with [course] skills",
    "how to get professor’s attention in [course]",
    "how to study for [course] final exam",
    "how to revise material in [course] quickly",
    "how to recover from a failing midterm in [course]",
    "how to apply what I learned in [course] to real projects",
    "how to balance [course] and other heavy courses",
    "how to self-study [course] ahead of time",
    "how to explain concepts from [course] in an interview",
    "how to find a mentor for [course]",
    "how to get recommendation letter from [course] professor",
    "how to do better in [course] next semester",
    "how to catch up in [course] after skipping classes",

    # What is / Am I / Can I…
    "what is my grade trend in [course]",
    "what is the average score in [course]",
    "what is required to pass [course]",
    "what is the best strategy to ace [course]",
    "am I doing well enough in [course]",
    "am I eligible to take advanced [course] next semester",
    "am I at risk of failing [course]",
    "can I still pass [course] if I get X on final",
    "can I drop [course] without affecting graduation",
    "can I retake [course] to improve GPA",
    "will my score in [course] affect internship chances",
    "can I transfer credits for [course] from another university",
    "what if I fail [course] this semester",
    "what’s the GPA impact if I fail [course]",
    "what’s the benefit of getting A+ in [course]",
]

# Upload to Firestore
for question in questions:
    doc_ref = db.collection("Questions").add({
        "text": question,
    })
    print(f"Uploaded: {question}")

print("✅ All questions uploaded.")
