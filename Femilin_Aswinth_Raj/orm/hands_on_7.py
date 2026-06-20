"""
Digital Nurture 5.0 | Module 3: Database Integration
HANDS-ON 6 [Advanced] - Task 1: SQLAlchemy - Define Models and Connect

Defines ORM model classes mirroring the college_db relational schema
(Department, Student, Course, Enrollment, Professor) and creates the
tables in a fresh database, college_db_orm.

Run: python models.py
Requires: pip install sqlalchemy psycopg2-binary
"""

from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    Date,
    Numeric,
    ForeignKey,
    CHAR,
    Boolean,
    Time,
)
from sqlalchemy.orm import relationship, declarative_base

# Step 76: engine connecting to college_db_orm (a FRESH database,
# separate from the hand-written college_db used in Hands-On 1-5)
DATABASE_URL = "postgresql+psycopg2://postgres:your_password@localhost:5432/college_db_orm"
engine = create_engine(DATABASE_URL, echo=True)

Base = declarative_base()


# Step 77 + 78: Define the five ORM model classes with relationships

class Department(Base):
    __tablename__ = "departments"

    department_id = Column(Integer, primary_key=True, autoincrement=True)
    dept_name = Column(String(100), nullable=False)
    hod_name = Column(String(100))
    budget = Column(Numeric(12, 2))

    students = relationship("Student", back_populates="department")
    courses = relationship("Course", back_populates="department")
    professors = relationship("Professor", back_populates="department")


class Student(Base):
    __tablename__ = "students"

    student_id = Column(Integer, primary_key=True, autoincrement=True)
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    date_of_birth = Column(Date)
    department_id = Column(Integer, ForeignKey("departments.department_id"))
    enrollment_year = Column(Integer)

    # Step 98 (Hands-On 7): new column added AFTER the baseline migration
    # was generated, so Alembic's autogenerate can detect this diff.
    is_active = Column(Boolean, default=True)

    # many-to-one: Student -> Department
    department = relationship("Department", back_populates="students")
    # one-to-many: Student -> Enrollment
    enrollments = relationship("Enrollment", back_populates="student")


class Course(Base):
    __tablename__ = "courses"

    course_id = Column(Integer, primary_key=True, autoincrement=True)
    course_name = Column(String(150), nullable=False)
    course_code = Column(String(20), unique=True)
    credits = Column(Integer)
    department_id = Column(Integer, ForeignKey("departments.department_id"))

    department = relationship("Department", back_populates="courses")
    enrollments = relationship("Enrollment", back_populates="course")


class Enrollment(Base):
    __tablename__ = "enrollments"

    enrollment_id = Column(Integer, primary_key=True, autoincrement=True)
    student_id = Column(Integer, ForeignKey("students.student_id"))
    course_id = Column(Integer, ForeignKey("courses.course_id"))
    enrollment_date = Column(Date)
    grade = Column(CHAR(2))

    # many-to-one relationships to BOTH Student and Course
    student = relationship("Student", back_populates="enrollments")
    course = relationship("Course", back_populates="enrollments")


class Professor(Base):
    __tablename__ = "professors"

    professor_id = Column(Integer, primary_key=True, autoincrement=True)
    prof_name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True)
    department_id = Column(Integer, ForeignKey("departments.department_id"))
    salary = Column(Numeric(10, 2))

    department = relationship("Department", back_populates="professors")


# Step 102 (Hands-On 7): new table added in a SECOND incremental
# migration, after is_active was already migrated separately.
class CourseSchedule(Base):
    __tablename__ = "course_schedules"

    schedule_id = Column(Integer, primary_key=True, autoincrement=True)
    course_id = Column(Integer, ForeignKey("courses.course_id"))
    day_of_week = Column(String(10))   # e.g. 'Monday', 'Tuesday'
    start_time = Column(Time)
    end_time = Column(Time)

    course = relationship("Course")


# Step 79: auto-create all tables in college_db_orm
if __name__ == "__main__":
    Base.metadata.create_all(engine)
    print("All 5 tables created successfully in college_db_orm.")
    print("Verify with: \\dt   (in psql, connected to college_db_orm)")
