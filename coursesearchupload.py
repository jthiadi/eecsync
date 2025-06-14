from google.cloud import firestore

# Initialize Firestore client
db = firestore.Client()

# List of allowed substrings in course document ID
allowed_codes = ['CS', 'EE', 'EECS', 'MATH', 'PHYS', 'COM', 'ENE', 'IPT', 'ISA', 'IIS']

# Reference to the 'Course' collection
course_ref = db.collection('Course')
courses = course_ref.stream()

# Reference to 'SEARCH' collection
search_ref = db.collection('Search')

for course in courses:
    course_id = course.id
    data = course.to_dict()
    english_title = data.get('english_title')

    # Check if any allowed code is in the course ID
    if english_title and any(code in course_id for code in allowed_codes):
        search_ref.add({
            'text': f"C {english_title}"
        })

print("Filtered SEARCH documents created.")
