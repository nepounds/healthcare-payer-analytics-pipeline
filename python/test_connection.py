import os

import pyodbc
from dotenv import load_dotenv


load_dotenv()

server = os.getenv("SQL_SERVER")
database = os.getenv("SQL_DATABASE")
driver = os.getenv("SQL_DRIVER")

connection_string = (
    f"DRIVER={{{driver}}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    "Trusted_Connection=yes;"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

try:
    with pyodbc.connect(connection_string) as conn:
        cursor = conn.cursor()

        cursor.execute("""
            IF OBJECT_ID('dbo.connection_test', 'U') IS NOT NULL
                DROP TABLE dbo.connection_test;

            CREATE TABLE dbo.connection_test (
                test_id INT PRIMARY KEY,
                message VARCHAR(100) NOT NULL
            );

            INSERT INTO dbo.connection_test (test_id, message)
            VALUES (1, 'Python successfully connected to SQL Server');
        """)

        conn.commit()

        cursor.execute("""
            SELECT test_id, message
            FROM dbo.connection_test;
        """)

        row = cursor.fetchone()

        print("Connection successful.")
        print(f"Database: {database}")
        print(f"Test row: {row.test_id} - {row.message}")

except pyodbc.Error as error:
    print("Connection failed.")
    print(error)