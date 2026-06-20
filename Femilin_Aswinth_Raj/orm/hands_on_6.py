
from datetime import date

from sqlalchemy.orm import sessionmaker, joinedload

from models import engine, Department, Student, Course, Enrollment, Professor

Session = sessionmaker(bind=engine)


def task2_insert_departments_and_students(session):
   
    departments = [
        Department(dept_name="Computer Science", hod_name="Dr. Ramesh Kumar", budget=850000.00),
        Department(dept_name="Electronics", hod_name="Dr. Priya Nair", budget=620000.00),
        Department(dept_name="Mechanical", hod_name="Dr. Suresh Iyer", budget=540000.00),
    ]
    session.add_all(departments)
    session.commit()  # commit now so department_id values are assigned

    students = [
        Student(first_name="Arjun", last_name="Mehta", email="arjun.mehta@college.edu",
                date_of_birth=date(2003, 4, 12), department_id=departments[0].department_id,
                enrollment_year=2022),
        Student(first_name="Priya", last_name="Suresh", email="priya.suresh@college.edu",
                date_of_birth=date(2003, 7, 25), department_id=departments[0].department_id,
                enrollment_year=2022),
        Student(first_name="Rohan", last_name="Verma", email="rohan.verma@college.edu",
                date_of_birth=date(2002, 11, 8), department_id=departments[1].department_id,
                enrollment_year=2021),
        Student(first_name="Sneha", last_name="Patel", email="sneha.patel@college.edu",
                date_of_birth=date(2004, 1, 30), department_id=departments[2].department_id,
                enrollment_year=2023),
        Student(first_name="Vikram", last_name="Das", email="vikram.das@college.edu",
                date_of_birth=date(2003, 9, 14), department_id=departments[0].department_id,
                enrollment_year=2022),
    ]
    session.add_all(students)
    session.commit()
    print("Inserted 3 departments and 5 students.")
    return departments, students


def task2_insert_courses_and_enrollments(session, departments, students):
    """Step 82: Add 3 Course objects and 4 Enrollment objects."""
    courses = [
        Course(course_name="Data Structures & Algorithms", course_code="CS101",
               credits=4, department_id=departments[0].department_id),
        Course(course_name="Database Management Systems", course_code="CS102",
               credits=3, department_id=departments[0].department_id),
        Course(course_name="Circuit Theory", course_code="EC101",
               credits=3, department_id=departments[1].department_id),
    ]
    session.add_all(courses)
    session.commit()

    enrollments = [
        Enrollment(student_id=students[0].student_id, course_id=courses[0].course_id,
                   enrollment_date=date(2022, 7, 1), grade="A"),
        Enrollment(student_id=students[1].student_id, course_id=courses[0].course_id,
                   enrollment_date=date(2022, 7, 1), grade="B"),
        Enrollment(student_id=students[1].student_id, course_id=courses[1].course_id,
                   enrollment_date=date(2022, 7, 1), grade="A"),
        Enrollment(student_id=students[2].student_id, course_id=courses[2].course_id,
                   enrollment_date=date(2021, 7, 1), grade="A"),
    ]
    session.add_all(enrollments)
    session.commit()
    print("Inserted 3 courses and 4 enrollments.")
    return courses, enrollments


def task2_read_cs_students(session):
    """Step 83: Query all students in department 'Computer Science'."""
    cs_students = (
        session.query(Student)
        .join(Department)
        .filter(Department.dept_name == "Computer Science")
        .all()
    )
    print(f"\nStudents in Computer Science ({len(cs_students)}):")
    for s in cs_students:
        print(f"  {s.first_name} {s.last_name}")
    return cs_students


def task2_read_enrollments_lazy(session):
    """
    Step 84: Query all enrollments and print each student's name
    alongside course name, using default LAZY loading. With
    echo=True on the engine, watch the SQL log -- this triggers
    the N+1 pattern described in the module docstring above.
    """
    print("\n--- Lazy-loaded enrollment read (watch SQL log for N+1) ---")
    enrollments = session.query(Enrollment).all()  # query #1
    for e in enrollments:
        
        print(f"  {e.student.first_name} {e.student.last_name} -> {e.course.course_name}")


def task2_update_student(session, email, new_year):
    """Step 85: Find a student by email and update their enrollment_year."""
    student = session.query(Student).filter(Student.email == email).first()
    if student:
        student.enrollment_year = new_year
        session.commit()
        print(f"\nUpdated {student.first_name} {student.last_name} -> enrollment_year={new_year}")
    else:
        print(f"\nNo student found with email {email}")
    return student


def task2_delete_enrollment(session, enrollment_id):
    """Step 86: Remove an enrollment record using session.delete()."""
    enrollment = session.get(Enrollment, enrollment_id)
    if enrollment:
        session.delete(enrollment)
        session.commit()
        print(f"\nDeleted enrollment_id={enrollment_id}")
    else:
        print(f"\nNo enrollment found with id={enrollment_id}")


def task3_read_enrollments_joinedload(session):
   
    print("\n--- joinedload enrollment read (should be 1 query only) ---")
    enrollments = (
        session.query(Enrollment)
        .options(joinedload(Enrollment.student), joinedload(Enrollment.course))
        .all()
    )
    for e in enrollments:
       
        print(f"  {e.student.first_name} {e.student.last_name} -> {e.course.course_name}")


def main():
    session = Session()
    try:
        departments, students = task2_insert_departments_and_students(session)
        courses, enrollments = task2_insert_courses_and_enrollments(session, departments, students)

        task2_read_cs_students(session)

        
        task2_read_enrollments_lazy(session)

      
        task2_update_student(session, "rohan.verma@college.edu", 2022)

      
        task2_delete_enrollment(session, enrollments[-1].enrollment_id)

        
        task3_read_enrollments_joinedload(session)

    finally:
        session.close()


if __name__ == "__main__":
    main()
