import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firestore
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Reference to the 'Course' collection
course_ref = db.collection('Course')

# Get all documents in the Course collection
docs = course_ref.stream()

for doc in docs:
    data = doc.to_dict()
    class_room_and_time = data.get('class_room_and_time', '')
    words = class_room_and_time.split()
    
    if len(words) ==0:
        print(f"Deleting document: {doc.id} - class_room_and_time: {class_room_and_time}")
        doc.reference.delete()