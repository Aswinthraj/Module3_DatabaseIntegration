
import time
import psycopg2

# Update these to match your local PostgreSQL setup
DB_CONFIG = {
    "host": "localhost",
    "dbname": "college_db",
    "user": "postgres",
    "password": "your_password",
    "port": 5432,
}


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


# ----------------------------------------------------------------
# Step 56: Simulate the N+1 problem
# ----------------------------------------------------------------
def fetch_enrollments_n_plus_1(conn):
    """
    1 query to get all enrollments, then 1 additional query PER ROW
    to fetch that enrollment's student name -> N+1 total queries.
    """
    query_count = 0
    results = []

    cur = conn.cursor()

    # Query #1: fetch all enrollments
    cur.execute("SELECT enrollment_id, student_id, course_id FROM enrollments;")
    query_count += 1
    enrollments = cur.fetchall()

    # Queries #2 through #(N+1): one SELECT per enrollment row
    for enrollment_id, student_id, course_id in enrollments:
        cur.execute(
            "SELECT first_name, last_name FROM students WHERE student_id = %s;",
            (student_id,),
        )
        query_count += 1
        first_name, last_name = cur.fetchone()
        results.append((enrollment_id, f"{first_name} {last_name}", course_id))

    cur.close()
    print(f"[N+1 version]   {query_count} queries executed")
    return results, query_count


# ----------------------------------------------------------------
# Step 57: Fix using a single JOIN query
# ----------------------------------------------------------------
def fetch_enrollments_with_join(conn):
  
    query_count = 0
    cur = conn.cursor()

    cur.execute(
        
    )
    query_count += 1
    rows = cur.fetchall()
    results = [
        (enrollment_id, f"{first_name} {last_name}", course_id)
        for enrollment_id, first_name, last_name, course_id in rows
    ]

    cur.close()
    print(f"[JOIN version]  {query_count} query executed")
    return results, query_count


def main():
    conn = get_connection()
    try:
        start_n1 = time.perf_counter()
        results_n1, count_n1 = fetch_enrollments_n_plus_1(conn)
        elapsed_n1 = time.perf_counter() - start_n1

        start_join = time.perf_counter()
        results_join, count_join = fetch_enrollments_with_join(conn)
        elapsed_join = time.perf_counter() - start_join

        print()
        print("=== Comparison ===")
        print(f"N+1 approach : {count_n1} queries, {elapsed_n1:.4f}s")
        print(f"JOIN approach: {count_join} query,  {elapsed_join:.4f}s")
        print(f"Extra queries avoided: {count_n1 - count_join}")
        print(f"Identical row counts: {len(results_n1) == len(results_join)}")

      

    finally:
        conn.close()


if __name__ == "__main__":
    main()
