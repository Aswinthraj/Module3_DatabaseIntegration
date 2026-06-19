-- ================================================================
-- Digital Nurture 5.0 | Module 3: Database Integration
-- HANDS-ON 1 — Schema Design & Core SQL
-- Student Course Registration System | PostgreSQL
-- ================================================================

-- ================================================================
-- TASK 1: Create the Database and Tables
-- ================================================================

CREATE DATABASE college_db;

-- Connect to college_db before running the rest of this script
-- (in psql: \c college_db)

-- 1. departments (no dependencies so  create first)
CREATE TABLE departments (
    department_id   SERIAL PRIMARY KEY,
    dept_name        VARCHAR(100) NOT NULL,
    hod_name         VARCHAR(100),
    budget           DECIMAL(12,2)
);

-- 2. students (depends on departments)
CREATE TABLE students (
    student_id       SERIAL PRIMARY KEY,
    first_name       VARCHAR(50) NOT NULL,
    last_name        VARCHAR(50) NOT NULL,
    email            VARCHAR(100) UNIQUE NOT NULL,
    date_of_birth    DATE,
    department_id    INT REFERENCES departments(department_id),
    enrollment_year  INT
);

-- 3. courses (depends on departments)
CREATE TABLE courses (
    course_id        SERIAL PRIMARY KEY,
    course_name      VARCHAR(150) NOT NULL,
    course_code      VARCHAR(20) UNIQUE,
    credits          INT,
    department_id    INT REFERENCES departments(department_id)
);

-- 4. enrollments (depends on students AND courses)
CREATE TABLE enrollments (
    enrollment_id    SERIAL PRIMARY KEY,
    student_id       INT REFERENCES students(student_id),
    course_id        INT REFERENCES courses(course_id),
    enrollment_date  DATE,
    grade            CHAR(2)
);

-- 5. professors (depends on departments)
CREATE TABLE professors (
    professor_id     SERIAL PRIMARY KEY,
    prof_name        VARCHAR(100) NOT NULL,
    email            VARCHAR(100) UNIQUE,
    department_id    INT REFERENCES departments(department_id),
    salary           DECIMAL(10,2)
);

-- Verification commands:
-- \d students
-- \d enrollments
-- \dt   (lists all 5 tables)


-- ================================================================
-- SAMPLE DATA
-- ================================================================

-- departments
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


-- ================================================================
-- TASK 2: Verify Normalisation
-- ================================================================

-- 1NF (Atomicity):
-- All columns hold single, atomic values (e.g. email is one string,
-- not a list). If we had instead stored multiple phone numbers in
-- one field like '9876543210, 9123456789', that would violate 1NF
-- because the column wouldn't hold a single atomic value — it
-- would need a separate student_phones table instead.

-- 2NF (Full functional dependency on the WHOLE primary key):
-- enrollments has a single-column surrogate key (enrollment_id),
-- but its real candidate key is the composite (student_id, course_id).
-- Every other column in enrollments (enrollment_date, grade) depends
-- on the FULL pair (student_id, course_id) — not on student_id alone
-- or course_id alone — so there's no partial dependency. 2NF holds.

-- 3NF (No transitive dependencies):
-- In students, department_id determines which department a student
-- belongs to, and dept_name is a fact about the DEPARTMENT, not
-- about the student directly. If we stored dept_name inside the
-- students table, it would create a transitive dependency:
--   student_id -> department_id -> dept_name
-- This violates 3NF (and risks update anomalies — change the dept
-- name once, and you'd have to update it in every student row).
-- Keeping dept_name only in departments, and referencing it via
-- department_id, keeps the schema in 3NF.


-- ================================================================
-- TASK 3: Alter and Extend the Schema
-- ================================================================

-- Step 1: Add phone_number to students
ALTER TABLE students ADD COLUMN phone_number VARCHAR(15);

-- Step 2: Add max_seats to courses with a default
ALTER TABLE courses ADD COLUMN max_seats INT DEFAULT 60;

-- Step 3: CHECK constraint on enrollments.grade
ALTER TABLE enrollments
    ADD CONSTRAINT chk_grade CHECK (grade IN ('A','B','C','D','F') OR grade IS NULL);

-- Step 4: Rename hod_name -> head_of_dept
-- (PostgreSQL syntax: RENAME COLUMN ... TO ...;
--  MySQL would instead use: ALTER TABLE ... CHANGE hod_name head_of_dept VARCHAR(100);)
ALTER TABLE departments RENAME COLUMN hod_name TO head_of_dept;

-- Step 5: Drop phone_number (simulate rollback)
ALTER TABLE students DROP COLUMN phone_number;

-- Verification:
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'courses';
--
-- SELECT column_name FROM information_schema.columns
-- WHERE table_name = 'departments';
-- (should show head_of_dept, not hod_name)
--
-- SELECT column_name FROM information_schema.columns
-- WHERE table_name = 'students';
-- (phone_number should no longer appear)
