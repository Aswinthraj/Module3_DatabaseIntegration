
INSERT INTO departments (dept_name, hod_name, budget) VALUES
  ('Computer Science', 'Dr. Ramesh Kumar', 850000.00),
  ('Electronics', 'Dr. Priya Nair', 620000.00),
  ('Mechanical', 'Dr. Suresh Iyer', 540000.00),
  ('Civil', 'Dr. Ananya Sharma', 430000.00);

-- students
INSERT INTO students (first_name, last_name, email, date_of_birth, department_id, enrollment_year) VALUES
  ('Arjun',  'Mehta',    'arjun.mehta@college.edu',    '2003-04-12', 1, 2022),
  ('Priya',  'Suresh',   'priya.suresh@college.edu',   '2003-07-25', 1, 2022),
  ('Rohan',  'Verma',    'rohan.verma@college.edu',    '2002-11-08', 2, 2021),
  ('Sneha',  'Patel',    'sneha.patel@college.edu',    '2004-01-30', 3, 2023),
  ('Vikram', 'Das',      'vikram.das@college.edu',     '2003-09-14', 1, 2022),
  ('Kavya',  'Menon',    'kavya.menon@college.edu',    '2002-05-17', 2, 2021),
  ('Aditya', 'Singh',    'aditya.singh@college.edu',   '2004-03-22', 4, 2023),
  ('Deepika','Rao',      'deepika.rao@college.edu',    '2003-08-09', 1, 2022);

-- courses
INSERT INTO courses (course_name, course_code, credits, department_id) VALUES
  ('Data Structures & Algorithms', 'CS101', 4, 1),
  ('Database Management Systems',  'CS102', 3, 1),
  ('Object Oriented Programming',  'CS103', 4, 1),
  ('Circuit Theory',               'EC101', 3, 2),
  ('Thermodynamics',               'ME101', 3, 3);

-- enrollments
INSERT INTO enrollments (student_id, course_id, enrollment_date, grade) VALUES
  (1, 1, '2022-07-01', 'A'), (1, 2, '2022-07-01', 'B'),
  (2, 1, '2022-07-01', 'B'), (2, 3, '2022-07-01', 'A'),
  (3, 4, '2021-07-01', 'A'), (4, 5, '2023-07-01', NULL),
  (5, 1, '2022-07-01', 'C'), (5, 2, '2022-07-01', 'A'),
  (6, 4, '2021-07-01', 'B'), (7, 5, '2023-07-01', NULL),
  (8, 1, '2022-07-01', 'A'), (8, 3, '2022-07-01', 'B');

-- professors
INSERT INTO professors (prof_name, email, department_id, salary) VALUES
  ('Dr. Anand Krishnan',  'anand.k@college.edu',   1, 95000.00),
  ('Dr. Meena Pillai',    'meena.p@college.edu',   1, 88000.00),
  ('Dr. Sunil Rajan',     'sunil.r@college.edu',   2, 82000.00),
  ('Dr. Latha Gopal',     'latha.g@college.edu',   3, 79000.00),
  ('Dr. Kartik Bose',     'kartik.b@college.edu',  4, 76000.00);

-- Step 16: Insert two additional students of your own choosing
INSERT INTO students (first_name, last_name, email, date_of_birth, department_id, enrollment_year) VALUES
  ('Naveen', 'Raj',  'naveen.raj@college.edu',  '2003-02-18', 2, 2022),
  ('Ishita', 'Bose', 'ishita.bose@college.edu', '2004-06-05', 4, 2023);
-- students table now has 10 rows total

-- Step 17: Update the grade of student_id = 5 for course_id = 1 from 'C' to 'B'
UPDATE enrollments
SET grade = 'B'
WHERE student_id = 5 AND course_id = 1 AND grade = 'C';

-- Step 18: Delete enrollments where grade IS NULL
-- Preview first (per hint) before deleting:
SELECT * FROM enrollments WHERE grade IS NULL;

DELETE FROM enrollments
WHERE grade IS NULL;

-- Step 19: Verify row counts after each operation
SELECT COUNT(*) AS total_students FROM students;        -- expect 10
SELECT COUNT(*) AS total_enrollments FROM enrollments;   -- only non-NULL grades remain


-- ================================================================
-- TASK 2: Single-Table Queries and Filtering
-- ================================================================

-- Step 20: Students enrolled in 2022, ordered by last_name alphabetically
SELECT student_id, first_name, last_name, enrollment_year
FROM students
WHERE enrollment_year = 2022
ORDER BY last_name ASC;

-- Step 21: Courses with more than 3 credits, sorted by credits descending
SELECT course_id, course_name, course_code, credits
FROM courses
WHERE credits > 3
ORDER BY credits DESC;

-- Step 22: Professors whose salary is between 80,000 and 95,000 (inclusive)
SELECT professor_id, prof_name, salary
FROM professors
WHERE salary BETWEEN 80000 AND 95000;

-- Step 23: Students whose email ends with '@college.edu'
SELECT student_id, first_name, last_name, email
FROM students
WHERE email LIKE '%@college.edu';

-- Step 24: Count of students per enrollment_year
-- Expected Outcome: returns 3 rows — one per distinct enrollment_year (2021, 2022, 2023)
SELECT enrollment_year, COUNT(*) AS student_count
FROM students
GROUP BY enrollment_year
ORDER BY enrollment_year;


-- ================================================================
-- TASK 3: Multi-Table Joins
-- ================================================================

-- Step 25: Each student's full name alongside their department name
SELECT
    s.first_name || ' ' || s.last_name AS full_name,
    d.dept_name
FROM students s
JOIN departments d ON s.department_id = d.department_id
ORDER BY full_name;

-- Step 26: Each enrollment with student name and course name (3-table JOIN)
SELECT
    e.enrollment_id,
    s.first_name || ' ' || s.last_name AS student_name,
    c.course_name,
    e.grade
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c ON e.course_id = c.course_id
ORDER BY e.enrollment_id;

-- Step 27: Students NOT enrolled in any course (LEFT JOIN + IS NULL pattern)
SELECT s.student_id, s.first_name, s.last_name
FROM students s
LEFT JOIN enrollments e ON s.student_id = e.student_id
WHERE e.enrollment_id IS NULL;

-- Step 28: Every course with its enrollment count (courses with 0 enrolments must still appear)
SELECT
    c.course_id,
    c.course_name,
    COUNT(e.enrollment_id) AS enrollment_count
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name
ORDER BY c.course_id;
-- Expected Outcome: all 5 courses appear, including any with 0 students

-- Step 29: Each department with its professors and salaries
-- (include departments that have no professors yet)
SELECT
    d.dept_name,
    p.prof_name,
    p.salary
FROM departments d
LEFT JOIN professors p ON d.department_id = p.department_id
ORDER BY d.dept_name;


-- ================================================================
-- TASK 4: Aggregations and Grouping
-- ================================================================

-- Step 30: Total enrollments per course — course_name and enrollment_count
SELECT
    c.course_name,
    COUNT(e.enrollment_id) AS enrollment_count
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_name
ORDER BY enrollment_count DESC;

-- Step 31: Average salary of professors per department, rounded to 2 decimal places
-- Expected Outcome: returns 4 rows — one per department
SELECT
    d.dept_name,
    ROUND(AVG(p.salary), 2) AS avg_salary
FROM departments d
JOIN professors p ON d.department_id = p.department_id
GROUP BY d.dept_name
ORDER BY d.dept_name;

-- Step 32: Departments where total budget exceeds 600,000
SELECT dept_name, budget
FROM departments
WHERE budget > 600000;

-- Step 33: Grade distribution for course CS101 — count of each grade
SELECT
    e.grade,
    COUNT(*) AS grade_count
FROM enrollments e
JOIN courses c ON e.course_id = c.course_id
WHERE c.course_code = 'CS101'
GROUP BY e.grade
ORDER BY e.grade;

-- Step 34: Departments where more than 2 students are enrolled
-- across all courses in that department (uses HAVING on aggregated result)
SELECT
    d.dept_name,
    COUNT(e.enrollment_id) AS total_enrollments
FROM departments d
JOIN courses c ON c.department_id = d.department_id
JOIN enrollments e ON e.course_id = c.course_id
GROUP BY d.dept_name
HAVING COUNT(e.enrollment_id) > 2;
-- Note: WHERE filters rows BEFORE grouping; HAVING filters groups AFTER
-- aggregation — that's why the row-count condition belongs in HAVING here.
