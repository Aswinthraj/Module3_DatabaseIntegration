

-- ================================================================
-- TASK 1: Baseline Performance — No Indexes
-- ================================================================

-- Step 48: Run EXPLAIN on the target query (no indexes yet beyond
-- the primary keys / foreign keys created in Hands-On 1)
EXPLAIN
SELECT s.first_name, s.last_name, c.course_name
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
WHERE s.enrollment_year = 2022;


--
-- Step 49: Table scan check —
--   On a table this small (a handful of rows), PostgreSQL chooses
--   Seq Scan on ALL THREE tables (enrollments, students, courses).
--   This is the planner correctly deciding that scanning a tiny
--   table is cheaper than the overhead of using an index.
--
-- Step 50: Estimated cost noted —
--   The "students" Seq Scan shows the highest relative cost among
--   the leaf scans here (cost=0.00..1.06) due to the Filter on
--   enrollment_year = 2022, since there is no index to support that
--   filter yet — PostgreSQL must read every row and check the
--   condition row-by-row.
-- ---------------------------------------------------------------


-- ================================================================
-- TASK 2: Add Indexes and Compare Plans
-- ================================================================

-- Step 51: B-Tree index on students.enrollment_year
CREATE INDEX idx_students_enrollment_year ON students(enrollment_year);

-- Step 52: Composite UNIQUE index on enrollments(student_id, course_id)
-- — also prevents duplicate enrollments going forward
CREATE UNIQUE INDEX idx_enrollments_student_course
    ON enrollments(student_id, course_id);

-- Step 53: Index on courses.course_code
CREATE INDEX idx_courses_course_code ON courses(course_code);

-- Step 54: Re-run the same EXPLAIN and compare to baseline
EXPLAIN
SELECT s.first_name, s.last_name, c.course_name
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
WHERE s.enrollment_year = 2022;


-- Step 55: Partial index on enrollments(student_id) WHERE grade IS NULL
-- (optimises lookups for unevaluated enrollments specifically)
CREATE INDEX idx_enrollments_ungraded
    ON enrollments(student_id)
    WHERE grade IS NULL;


