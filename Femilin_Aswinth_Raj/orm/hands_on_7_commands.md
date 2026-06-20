

# Step 92: initialise Alembic (run once, from inside orm/)
alembic init migrations

# This creates:
#   alembic.ini
#   migrations/
#     env.py
#     script.py.mako
#     versions/   (empty for now)


# Find the line:
#   sqlalchemy.url = driver://user:pass@localhost/dbname
# Replace it with your actual connection string:
#   sqlalchemy.url = postgresql+psycopg2://postgres:your_password@localhost:5432/college_db_orm


# Near the top of env.py, add:
#   import sys, os
#   sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
#   from models import Base
#
# Then find the line:
#   target_metadata = None
# and change it to:
#   target_metadata = Base.metadata


# (at this point models.py should have all 5 original tables ONLY —
# do NOT add is_active or CourseSchedule until after this step)
alembic revision --autogenerate -m "initial schema"


# Open migrations/versions/<hash>_initial_schema.py and confirm it
# contains both:
#   def upgrade(): ... (creates departments, students, courses,
#                        enrollments, professors with op.create_table)
#   def downgrade(): ... (drops the same 5 tables, in reverse order)

# apply the migration
alembic upgrade head

# Verify:
#   psql -d college_db_orm -c "\dt"
# Expected: alembic_version table + all 5 original tables present.
alembic current
# Expected output: shows the revision hash you just generated, marked (head)


# add is_active column to Student in models.py
# --> THIS HAS ALREADY BEEN DONE in the models.py provided alongside
#     this file. The relevant addition was:
#         is_active = Column(Boolean, default=True)
#     inside the Student class.

# generate the migration for this single change
alembic revision --autogenerate -m "add is_active to students"

# inspect the new file in migrations/versions/
# Confirm:
#   upgrade()   contains: op.add_column('students', sa.Column('is_active', sa.Boolean(), ...))
#   downgrade() contains: op.drop_column('students', 'is_active')

#  apply it
alembic upgrade head

# Verify the column exists:
#   psql -d college_db_orm -c "\d students"
# is_active should now appear in the column list.

# ----------------------------------------------------------------
# add the CourseSchedule table to models.py
# --> THIS HAS ALSO ALREADY BEEN DONE in the provided models.py:
#         class CourseSchedule(Base):
#             __tablename__ = "course_schedules"
#             schedule_id, course_id (FK), day_of_week,
#             start_time, end_time
# ----------------------------------------------------------------

# Generate + apply the migration for the new table
alembic revision --autogenerate -m "add course_schedules table"
alembic upgrade head

# Verify:
#   psql -d college_db_orm -c "\dt"
# course_schedules should now be listed.

# Step 103: view the full migration chain
alembic history --verbose
# Expected Outcome: 3 revisions total, oldest -> newest:
#   1. initial schema
#   2. add is_active to students
#   3. add course_schedules table



#  note the current head revision hash
alembic current
# Write down the hash shown — you'll compare against it in Step 107.

# roll back ONE step
alembic downgrade -1
# Verify: psql -d college_db_orm -c "\d students"
# is_active column should now be GONE.

#  roll back ALL THE WAY to the very first revision
alembic downgrade base
# This undoes every migration, including the original 5-table schema.
# Verify: psql -d college_db_orm -c "\dt"
# Expected: only the alembic_version table remains (or even that may
# reset depending on your Alembic version's handling of "base").

# re-apply everything
alembic upgrade head
alembic current
# Confirm the hash shown now matches the head hash you noted in Step 104.

# (Bonus — Django only, skip if using SQLAlchemy/Alembic):
#   python manage.py makemigrations
#   python manage.py migrate
#   python manage.py migrate <app_name> <previous_migration_number>


