import pyodbc

def conectar():
    try:
        conexion = pyodbc.connect(
            'DRIVER={ODBC Driver 18 for SQL Server};'
            'SERVER=localhost;'
            'DATABASE=ReservasCanchas;'
            'UID=admin;'
            'PWD=admin123;'
            'Encrypt=yes;'
            'TrustServerCertificate=yes;'
        )
        print("✅ Conexión exitosa")
        return conexion
    except Exception as e:
        print("❌ Error de conexión a SQL Server:", e)
        return None


