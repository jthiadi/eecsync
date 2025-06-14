final Map<String, List<List<String>>> groupedRequirements = {
  "Department Required Courses": [
    ["12"],
    ["MATH1030"],
    ["PHYS1133"],
    ["EE 2310", "CS 1355"],
    ["EE 3900", "CS 3901", "EECS3900"],
    ["EE 3910", "CS 3902", "EECS3910"],
  ],
  "Basic Core Courses": [
    ["12"],
    ["MATH1040"],
    ["PHYS1134"],
    ["EECS1010"],
    ["EE 2060", "CS 2336", "EECS2060"],
    ["EECS2030"],
    ["CS 2334", "EE 2030"],
    ["CS 3332", "EE 3060"],
    ["EECS2020"],
  ],
  "Core Courses": [
    ["12"],
    ["EE 2255", "EE 2250"],
    ["EE 2210"],
    ["EE 2140"],
    ["EE 2410", "CS 2351"],
    ["EECS4030", "CS 4100", "EE 3450"],
    ["EECS3020"],
    ["CS 3423"],
    ["EECS4020", "CS 4311", "EE 3980"],
  ],
  "Professional Courses": [
    ["34"],
  ]
};

Map<String, Map<String, dynamic>> allRequiredCourses = {
    'MATH1030': {'name': 'Calculus I', 'category': 'Department Required Courses'},
    'PHYS1133': {'name': 'General Physics (I)', 'category': 'Department Required Courses'},
    'EE 2310': {'name': 'Introduction to Programming', 'category': 'Department Required Courses'},
    'CS 1355': {'name': 'Introduction to Programming', 'category': 'Department Required Courses'},

    'MATH1040': {'name': 'Calculus (II)', 'category': 'Basic Core Courses'},
    'PHYS1134': {'name': 'General Physics(II)', 'category': 'Basic Core Courses'},
    'EECS1010': {'name': 'Logic Design', 'category': 'Basic Core Courses'},
    'EE 2060': {'name': 'Discrete Mathematics', 'category': 'Basic Core Courses'},
    'CS 2336': {'name': 'Discrete Mathematics', 'category': 'Basic Core Courses'},
    'EECS2060': {'name': 'Discrete Mathematics', 'category': 'Basic Core Courses'},
    'EECS2030': {'name': 'Ordinary Differential Equations', 'category': 'Basic Core Courses'},
    'CS 2334': {'name': 'Linear Algebra', 'category': 'Basic Core Courses'},
    'EE 2030': {'name': 'Linear Algebra', 'category': 'Basic Core Courses'},
    'CS 3332': {'name': 'Probability', 'category': 'Basic Core Courses'},
    'EE 3060': {'name': 'Probability', 'category': 'Basic Core Courses'},
    'EECS2020': {'name': 'Signals and Systems', 'category': 'Basic Core Courses'},
    
    'EE 2255': {'name': 'Electronics', 'category': 'Core Courses'},
    'EE 2250': {'name': 'Electronics', 'category': 'Core Courses'},
    'EE 2210': {'name': 'Electric Circuits', 'category': 'Core Courses'},
    'EE 2140': {'name': 'Electromagnetism', 'category': 'Core Courses'},
    'EE 2410': {'name': 'Data Structures', 'category': 'Core Courses'},
    'CS 2351': {'name': 'Data Structures', 'category': 'Core Courses'},
    'EECS4030': {'name': 'Computer Architecture', 'category': 'Core Courses'},
    'CS 4100': {'name': 'Computer Architecture', 'category': 'Core Courses'},
    'EE 3450': {'name': 'Computer Architecture', 'category': 'Core Courses'},
    'EECS3020': {'name': 'Introduction to Computer Networks', 'category': 'Core Courses'},
    'CS 3423': {'name': 'Operating Systems', 'category': 'Core Courses'},
    'EECS4020': {'name': 'Algorithms', 'category': 'Core Courses'},
    'CS 4311': {'name': 'Algorithms', 'category': 'Core Courses'},
    'EE 3980': {'name': 'Algorithms', 'category': 'Core Courses'},
  };
