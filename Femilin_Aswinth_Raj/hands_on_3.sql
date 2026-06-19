
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    COUNT(e.enrollment_id) AS course_count
FROM students s
JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name
HAVING COUNT(e.enrollment_id) > (
    -- non-correlated subquery: average enrollments per student
    SELECT AVG(enroll_count)
    FROM (
        SELECT COUNT(*) AS enroll_count
        FROM enrollments
        GROUP BY student_id
    ) AS per_student_counts
);
-- Expected Outcome: returns students enrolled in 3+ courses on sample data

-- Step 36: Courses in which ALL enrolled students received grade 'A'
-- (correlated subquery using NOT EXISTS — "no student without an A")
SELECT c.course_id, c.course_name
FROM courses c
WHERE EXISTS (
        SELECT 1 FROM enrollments e WHERE e.course_id = c.course_id
    )
  AND NOT EXISTS (
        SELECT 1
        FROM enrollments e
        WHERE e.course_id = c.course_id
          AND (e.grade IS DISTINCT FROM 'A')
    );

-- Step 37: Professor with the highest salary in EACH department
-- (correlated subquery comparing to the MAX salary within the same department)
SELECT p.professor_id, p.prof_name, p.department_id, p.salary
FROM professors p
WHERE p.salary = (
    SELECT MAX(p2.salary)
    FROM professors p2
    WHERE p2.department_id = p.department_id
);

-- Step 38: Derived table (subquery in FROM) — per-department avg salary,
-- filtered to departments where that average exceeds 85,000
SELECT dept_avg.department_id, dept_avg.avg_salary
FROM (
    SELECT department_id, AVG(salary) AS avg_salary
    FROM professors
    GROUP BY department_id
) AS dept_avg
WHERE dept_avg.avg_salary > 85000;


-- ================================================================
-- TASK 2: Creating and Using Views
-- ================================================================

-- Step 39: vw_student_enrollment_summary
-- full name, department, number of courses enrolled, GPA (A=4,B=3,C=2,D=1,F=0)
CREATE VIEW vw_student_enrollment_summary AS
SELECT
    s.student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    d.dept_name,
    COUNT(e.enrollment_id) AS courses_enrolled,
    ROUND(AVG(
        CASE e.grade
            WHEN 'A' THEN 4
            WHEN 'B' THEN 3
            WHEN 'C' THEN 2
            WHEN 'D' THEN 1
            WHEN 'F' THEN 0
        END
    ), 2) AS gpa
FROM students s
JOIN departments d ON s.department_id = d.department_id
LEFT JOIN enrollments e ON s.student_id = e.student_id
GROUP BY s.student_id, s.first_name, s.last_name, d.dept_name;

-- Step 40: vw_course_stats
-- course_name, course_code, total_enrollments, avg_gpa for each course
CREATE VIEW vw_course_stats AS
SELECT
    c.course_name,
    c.course_code,
    COUNT(e.enrollment_id) AS total_enrollments,
    ROUND(AVG(
        CASE e.grade
            WHEN 'A' THEN 4
            WHEN 'B' THEN 3
            WHEN 'C' THEN 2
            WHEN 'D' THEN 1
            WHEN 'F' THEN 0
        END
    ), 2) AS avg_gpa
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name, c.course_code;
-- Expected Outcome: SELECT * FROM vw_course_stats returns 5 rows (one per course)

-- Step 41: Students with GPA above 3.0
SELECT *
FROM vw_student_enrollment_summary
WHERE gpa > 3.0;

-- Step 42: Attempt to UPDATE through vw_student_enrollment_summary
-- UPDATE vw_student_enrollment_summary SET gpa = 4.0 WHERE student_id = 1;
--
-- Result: PostgreSQL raises an error such as:
--   "ERROR: cannot update view "vw_student_enrollment_summary""
--   "DETAIL: Views that return aggregate functions are not automatically updatable."
--
-- Why multi-table / aggregated views are generally NOT updatable:
-- 1. The view joins students, departments, and enrollments — Postgres
--    cannot unambiguously determine which underlying base table row(s)
--    a column like "gpa" or "courses_enrolled" should map back to,
--    since these are computed via GROUP BY and aggregate functions
--    (COUNT, AVG) rather than being a direct column of one base table.
-- 2. An updatable view in PostgreSQL must (per the SQL standard) be a
--    simple view: one base relation in the FROM clause, no GROUP BY,
--    no aggregate functions, no DISTINCT, no set operations (UNION
--    etc.), and no subqueries in the SELECT list that reference other
--    tables. vw_student_enrollment_summary violates several of these.
-- 3. Even disregarding the aggregates, it's a 3-way JOIN, so a single
--    UPDATE wouldn't know whether to apply the change to students,
--    departments, or some derived value — the mapping is not 1:1.

-- Step 43: Drop both views and recreate vw_student_enrollment_summary
-- as a single-table subset view WITH CHECK OPTION
DROP VIEW IF EXISTS vw_student_enrollment_summary;
DROP VIEW IF EXISTS vw_course_stats;

-- Single-table subset view (only students enrolled in 2022) so it is
-- genuinely updatable, then protected with WITH CHECK OPTION so that
-- INSERT/UPDATE through the view cannot create rows that fall outside
-- the view's own WHERE clause (e.g. you could not sneak in a row with
-- enrollment_year = 2023 through this view).
CREATE VIEW vw_student_enrollment_summary AS
SELECT student_id, first_name, last_name, email, department_id, enrollment_year
FROM students
WHERE enrollment_year = 2022
WITH CHECK OPTION;

-- Recreate vw_course_stats as before (not part of the CHECK OPTION requirement,
-- but kept since later exercises may still reference it)
CREATE VIEW vw_course_stats AS
SELECT
    c.course_name,
    c.course_code,
    COUNT(e.enrollment_id) AS total_enrollments,
    ROUND(AVG(
        CASE e.grade
            WHEN 'A' THEN 4
            WHEN 'B' THEN 3
            WHEN 'C' THEN 2
            WHEN 'D' THEN 1
            WHEN 'F' THEN 0
        END
    ), 2) AS avg_gpa
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name, c.course_code;


-- ================================================================
-- TASK 3: Stored Procedures / Functions and Transactions
-- ================================================================
-- PostgreSQL uses FUNCTIONS with LANGUAGE plpgsql (no separate
-- "stored procedure" syntax was available before PG11; CREATE
-- PROCEDURE exists in modern PostgreSQL too, but a function is used
-- here per the hint: "PostgreSQL: fn_enroll_student").

-- Step 44: fn_enroll_student — checks for duplicate enrollment, then inserts
CREATE OR REPLACE FUNCTION fn_enroll_student(
    p_student_id INT,
    p_course_id INT,
    p_enrollment_date DATE
)
RETURNS VOID AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM enrollments
        WHERE student_id = p_student_id AND course_id = p_course_id
    ) THEN
        RAISE EXCEPTION 'Student % is already enrolled in course %', p_student_id, p_course_id;
    END IF;

    INSERT INTO enrollments (student_id, course_id, enrollment_date, grade)
    VALUES (p_student_id, p_course_id, p_enrollment_date, NULL);
END;
$$ LANGUAGE plpgsql;

-- Test: this should succeed (new combination)
SELECT fn_enroll_student(3, 1, '2024-01-10');

-- Test: this should raise the duplicate-enrollment exception
-- SELECT fn_enroll_student(3, 1, '2024-01-10');

-- Step 45: department_transfer_log table + sp_transfer_student procedure
CREATE TABLE department_transfer_log (
    log_id           SERIAL PRIMARY KEY,
    student_id       INT REFERENCES students(student_id),
    old_department_id INT,
    new_department_id INT,
    transferred_at   TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE sp_transfer_student(
    p_student_id INT,
    p_new_department_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_department_id INT;
BEGIN
    SELECT department_id INTO v_old_department_id
    FROM students WHERE student_id = p_student_id;

    -- Both statements run in the same transaction as the caller.
    -- If either fails, PostgreSQL automatically rolls back the whole
    -- transaction (no explicit COMMIT/ROLLBACK needed inside a
    -- procedure invoked via CALL under default autocommit behaviour;
    -- wrap the CALL itself in BEGIN/COMMIT/ROLLBACK as shown below
    -- for explicit control).
    UPDATE students
    SET department_id = p_new_department_id
    WHERE student_id = p_student_id;

    INSERT INTO department_transfer_log (student_id, old_department_id, new_department_id)
    VALUES (p_student_id, v_old_department_id, p_new_department_id);
END;
$$;

-- Explicit transaction wrapper around the transfer (recommended usage):
BEGIN;
    CALL sp_transfer_student(1, 2);
COMMIT;

-- Step 46: Test the transaction with a deliberate error (invalid FK)
-- and verify the UPDATE is also rolled back
BEGIN;
    UPDATE students SET department_id = 2 WHERE student_id = 2;
    -- This INSERT references a department_id that does not exist (999),
    -- violating the FOREIGN KEY constraint and aborting the transaction:
    INSERT INTO department_transfer_log (student_id, old_department_id, new_department_id)
    VALUES (2, 1, 999999);
ROLLBACK;
-- Verify: student_id = 2's department_id is unchanged because the
-- UPDATE above was rolled back along with the failed INSERT.
SELECT student_id, department_id FROM students WHERE student_id = 2;

-- Step 47: SAVEPOINT mid-transaction checkpoint
BEGIN;
    -- First insert — should persist
    INSERT INTO enrollments (student_id, course_id, enrollment_date, grade)
    VALUES (6, 2, '2024-02-01', NULL);

    SAVEPOINT after_first_insert;

    -- Second insert — deliberately fails (course_id 999 does not exist,
    -- violates FOREIGN KEY)
    INSERT INTO enrollments (student_id, course_id, enrollment_date, grade)
    VALUES (6, 999, '2024-02-01', NULL);

    -- Roll back only to the savepoint, discarding the failed second
    -- insert but keeping the first
    ROLLBACK TO SAVEPOINT after_first_insert;
COMMIT;

-- Verify: only the first record (student 6, course 2) was saved
SELECT * FROM enrollments WHERE student_id = 6 AND course_id IN (2, 999);
