"""
==============================================================================
🐍 PYTHON + POSTGRESQL EN LA NUBE (SUPABASE) CON PSYCOPG2
==============================================================================
En este script conectamos Python directamente con la base de datos PostgreSQL
en Supabase utilizando 'psycopg2', el adaptador estándar de la industria.
==============================================================================
"""

import os
import psycopg2
from dotenv import load_dotenv

# 1. Cargar las variables del archivo .env
load_dotenv()

# 2. Obtener la cadena de conexión o parámetros
# 'os.getenv()' busca el valor de una variable en el entorno
db_url = os.getenv("DATABASE_SES_URL") or os.getenv("DATABASE_URL")

def main():
    conn = None
    cur = None
    try:
        print("⏳ Conectando con PostgreSQL en Supabase desde Python...")
        
        # ¿Qué es 'psycopg2.connect()'?
        # Abre el socket de red seguro con el servidor de Supabase.
        # 'sslmode=require' le exige a PostgreSQL que todo el tráfico viaje cifrado con SSL.
        if db_url:
            # Si pasamos la URL completa, nos aseguramos de que incluya sslmode
            conn = psycopg2.connect(db_url, sslmode="require")
        else:
            conn = psycopg2.connect(
                host=os.getenv("DB_HOST"),
                port=os.getenv("DB_PORT", "5432"),
                user=os.getenv("DB_USER", "postgres"),
                password=os.getenv("DB_PASSWORD"),
                dbname=os.getenv("DB_NAME", "postgres"),
                sslmode="require"
            )
            
        print("✅ ¡Conexión establecida con éxito en la nube!\n")

        # ¿Qué es un Cursor ('conn.cursor()')?
        # En Python, el cursor es el "puntero de trabajo" o agente que envía las sentencias SQL
        # al motor y recupera las filas del resultado una a una o en bloque.
        cur = conn.cursor()

        # ----------------------------------------------------------------------
        # CONSULTA 1: Listar los autores
        # ----------------------------------------------------------------------
        print("📋 CONSULTA 1: Autores registrados:")
        cur.execute("SELECT id, nombre, pais FROM autores ORDER BY id ASC;")
        
        # 'cur.fetchall()' descarga todas las filas devueltas como una lista de tuplas en Python:
        autores = cur.fetchall()
        for autor in autores:
            # autor[0] = id, autor[1] = nombre, autor[2] = pais
            print(f"  • [ID {autor[0]}] {autor[1]} (País: {autor[2]})")

        # ----------------------------------------------------------------------
        # CONSULTA 2: Libros con su autor (JOIN)
        # ----------------------------------------------------------------------
        print("\n📖 CONSULTA 2: Libros con autor (JOIN):")
        query_join = """
            SELECT l.titulo, l.genero, l.precio, a.nombre
            FROM libros l
            JOIN autores a ON l.autor_id = a.id
            ORDER BY l.precio ASC;
        """
        cur.execute(query_join)
        libros = cur.fetchall()
        for libro in libros:
            print(f"  • '{libro[0]}' | Género: {libro[1]} | Precio: {libro[2]}€ | Autor: {libro[3]}")

        # ----------------------------------------------------------------------
        # CONSULTA 3: Inserción segura con parámetros (%s)
        # ----------------------------------------------------------------------
        print("\n✍️ CONSULTA 3: Insertando un nuevo libro desde Python...")
        insert_query = """
            INSERT INTO libros (autor_id, titulo, genero, precio, paginas)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id, titulo;
        """
        # ⚠️ REGLA DE ORO DE SEGURIDAD:
        # En psycopg2 los parámetros se representan con '%s' y se pasan como una tupla separada.
        # Nunca concatenes strings para evitar inyecciones SQL.
        nuevo_libro = (2, "Emma", "Comedia romántica", 16.90, 480)
        cur.execute(insert_query, nuevo_libro)

        # ¿Qué es 'conn.commit()'?
        # A diferencia de SELECT (que solo lee), cuando hacemos INSERT/UPDATE/DELETE en Python,
        # los cambios se mantienen en una transacción provisional hasta que llamamos a 'commit()'
        # para confirmar y guardar los cambios de forma permanente en la base de datos.
        conn.commit()

        fila_creada = cur.fetchone()
        print(f"🎉 ¡Libro insertado con éxito! ID generado: {fila_creada[0]} | Título: {fila_creada[1]}")

    except Exception as e:
        print(f"❌ Error al conectar o consultar Supabase: {e}")
        if conn:
            # Si algo falla, revertimos cualquier cambio pendiente
            conn.rollback()

    finally:
        # Cerramos cursor y conexión para liberar recursos
        if cur:
            cur.close()
        if conn:
            conn.close()
            print("\n🔒 Conexión con Supabase cerrada correctamente.")

if __name__ == "__main__":
    main()
