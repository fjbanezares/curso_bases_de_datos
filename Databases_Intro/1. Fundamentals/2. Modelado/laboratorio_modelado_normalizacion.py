#!/usr/bin/env python3
"""
==============================================================================
LABORATORIO PRÁCTICO: MODELADO DE DATOS Y NORMALIZACIÓN (1NF, 2NF, 3NF)
==============================================================================
Este script implementa un laboratorio interactivo y didáctico que reproduce:
1. TABLA DESNORMALIZADA CAÓTICA: Demostración de las 3 anomalías mortales
   (Inserción, Actualización y Borrado).
2. PASO A 1NF: Atomicidad de atributos y eliminación de listas anidadas.
3. PASO A 2NF: Eliminación de dependencias funcionales parciales.
4. PASO A 3NF: Eliminación de dependencias funcionales transitivas.
5. SPOTIFY EN 3 PARADIGMAS:
   - Relacional Transaccional 3FN (OLTP)
   - Dimensional Kimball / Esquema en Estrella (OLAP / BI)
   - Tabla Ancha (Wide Table / OBT)
==============================================================================
"""

import os
import sys
import sqlite3

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(SCRIPT_DIR, "spotify_modelado_lab.db")

def banner(title):
    print("\n" + "=" * 80)
    print(f"  🎵 {title}")
    print("=" * 80)

def print_table(cursor, max_rows=15):
    """Muestra los resultados de una consulta SQL en una tabla ASCII limpia"""
    if not cursor.description:
        print("✓ Sentencia ejecutada con éxito.")
        return
    headers = [d[0] for d in cursor.description]
    rows = cursor.fetchmany(max_rows)
    if not rows:
        print("ℹ️ Consulta vacía: 0 filas devueltas.")
        return
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(val) if val is not None else "NULL"))
    sep_line = "+" + "+".join(["-" * (w + 2) for w in col_widths]) + "+"
    header_line = "|" + "|".join([f" {h:<{col_widths[i]}} " for i, h in enumerate(headers)]) + "|"
    print(sep_line)
    print(header_line)
    print(sep_line)
    for row in rows:
        print("|" + "|".join([f" {str(v) if v is not None else 'NULL':<{col_widths[i]}} " for i, v in enumerate(row)]) + "|")
    print(sep_line)
    print(f"({len(rows)} filas mostradas)")

# ==============================================================================
# 1. LA TABLA CAÓTICA Y SUS 3 ANOMALÍAS
# ==============================================================================
def lab_step_1_tabla_caotica(conn):
    banner("PASO 1: LA TABLA DESNORMALIZADA CAÓTICA Y SUS 3 ANOMALÍAS")
    cursor = conn.cursor()
    
    cursor.executescript("""
    DROP TABLE IF EXISTS escuchas_caoticas;
    CREATE TABLE escuchas_caoticas (
        id_usuario INT,
        usuario_nombre TEXT,
        canciones TEXT,        -- ❌ VIOLA 1NF: Contiene listas ("Song1, Song2")
        album TEXT,
        artista TEXT,
        pais_artista TEXT,     -- ❌ VIOLA 3NF: Depende del artista, no de la escucha
        fecha TEXT
    );

    INSERT INTO escuchas_caoticas VALUES
    (1, 'Ana', 'Blinding Lights, Save Your Tears', 'After Hours', 'The Weeknd', 'Canadá', '2026-01-10'),
    (2, 'Luis', 'Believer', 'Evolve', 'Imagine Dragons', 'EE. UU.', '2026-01-12'),
    (1, 'Ana', 'In Your Eyes', 'After Hours', 'The Weeknd', 'Canadá', '2026-01-15'),
    (3, 'Marta', 'Starboy', 'Starboy', 'The Weeknd', 'Canadá', '2026-01-16');
    """)
    conn.commit()
    
    print("Contenido de la tabla 'escuchas_caoticas':")
    cursor.execute("SELECT * FROM escuchas_caoticas;")
    print_table(cursor)
    
    print("\n🚨 DEMOSTRACIÓN DE LAS 3 ANOMALÍAS MORTALES:")
    print("----------------------------------------------------------------------")
    print("1. ANOMALÍA DE INSERCIÓN:")
    print("   ¿Podemos registrar a una nueva artista emergente ('Rosalía', España) si aún")
    print("   ningún usuario ha escuchado sus canciones? NO, tendríamos que inventar un")
    print("   usuario fantasma o meter valores NULL artificiales.")
    
    print("\n2. ANOMALÍA DE ACTUALIZACIÓN:")
    print("   El artista 'The Weeknd' aparece repetido en 3 filas. Si su país estuviera mal")
    print("   o se nacionalizara y solo actualizamos una fila, creamos inconsistencia:")
    cursor.execute("UPDATE escuchas_caoticas SET pais_artista = 'Estados Unidos' WHERE rowid = 1;")
    conn.commit()
    print("   -> Consulta tras actualizar erróneamente solo una fila:")
    cursor.execute("SELECT usuario_nombre, artista, pais_artista FROM escuchas_caoticas WHERE artista = 'The Weeknd';")
    print_table(cursor)
    print("   ⚠️ ¡Inconsistencia! 'The Weeknd' ahora tiene dos países distintos a la vez en la BD.")

    print("\n3. ANOMALÍA DE BORRADO:")
    print("   Si Luis (id_usuario = 2) borra su cuenta y eliminamos su fila de escucha:")
    cursor.execute("DELETE FROM escuchas_caoticas WHERE id_usuario = 2;")
    conn.commit()
    cursor.execute("SELECT * FROM escuchas_caoticas WHERE artista = 'Imagine Dragons';")
    print_table(cursor)
    print("   💥 ¡Desastre! Al borrar la escucha de Luis, hemos borrado del sistema")
    print("   la existencia del grupo 'Imagine Dragons' y su álbum 'Evolve'.")

# ==============================================================================
# 2. EL PROCESO DE NORMALIZACIÓN PASO A PASO (1NF -> 2NF -> 3NF)
# ==============================================================================
def lab_step_2_normalizacion(conn):
    banner("PASO 2: EL PROCESO DE NORMALIZACIÓN PASO A PASO (1NF -> 2NF -> 3NF)")
    cursor = conn.cursor()

    # --------------------------------------------------------------------------
    # 2.1 PRIMERA FORMA NORMAL (1NF)
    # Regla: Cada celda debe ser atómica (un solo valor). Sin listas ni arrays.
    # --------------------------------------------------------------------------
    print("\n[2.1] APLICANDO LA 1ª FORMA NORMAL (1NF):")
    print("  -> Desdoblamos la celda 'Blinding Lights, Save Your Tears' en 2 filas individuales atómicas.")
    print("  -> Definimos una clave primaria (id_escucha).")
    
    cursor.executescript("""
    DROP TABLE IF EXISTS escuchas_1nf;
    CREATE TABLE escuchas_1nf (
        id_escucha INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INT NOT NULL,
        usuario_nombre TEXT NOT NULL,
        cancion_titulo TEXT NOT NULL,
        album_titulo TEXT NOT NULL,
        artista_nombre TEXT NOT NULL,
        pais_artista TEXT NOT NULL,
        fecha TEXT NOT NULL
    );

    INSERT INTO escuchas_1nf (id_usuario, usuario_nombre, cancion_titulo, album_titulo, artista_nombre, pais_artista, fecha) VALUES
    (1, 'Ana', 'Blinding Lights', 'After Hours', 'The Weeknd', 'Canadá', '2026-01-10'),
    (1, 'Ana', 'Save Your Tears', 'After Hours', 'The Weeknd', 'Canadá', '2026-01-10'),
    (2, 'Luis', 'Believer', 'Evolve', 'Imagine Dragons', 'EE. UU.', '2026-01-12'),
    (1, 'Ana', 'In Your Eyes', 'After Hours', 'The Weeknd', 'Canadá', '2026-01-15'),
    (3, 'Marta', 'Starboy', 'Starboy', 'The Weeknd', 'Canadá', '2026-01-16');
    """)
    conn.commit()
    cursor.execute("SELECT id_escucha, id_usuario, cancion_titulo, album_titulo, artista_nombre FROM escuchas_1nf;")
    print_table(cursor)
    print("  ✓ 1NF Cumplida: Todos los datos son atómicos y existe clave primaria.")

    # --------------------------------------------------------------------------
    # 2.2 SEGUNDA FORMA NORMAL (2NF)
    # Regla: Cumple 1NF + Ningún atributo no clave depende parcialmente de la PK.
    # --------------------------------------------------------------------------
    print("\n[2.2] APLICANDO LA 2ª FORMA NORMAL (2NF):")
    print("  -> 'usuario_nombre' solo depende de 'id_usuario', no de la escucha ni de la canción.")
    print("  -> Separamos la entidad USUARIOS.")
    
    cursor.executescript("""
    DROP TABLE IF EXISTS usuarios_2nf;
    DROP TABLE IF EXISTS escuchas_2nf;

    CREATE TABLE usuarios_2nf (
        id_usuario INTEGER PRIMARY KEY,
        usuario_nombre TEXT NOT NULL
    );

    CREATE TABLE escuchas_2nf (
        id_escucha INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER REFERENCES usuarios_2nf(id_usuario),
        cancion_titulo TEXT NOT NULL,
        album_titulo TEXT NOT NULL,
        artista_nombre TEXT NOT NULL,
        pais_artista TEXT NOT NULL,
        fecha TEXT NOT NULL
    );

    INSERT INTO usuarios_2nf VALUES (1, 'Ana'), (2, 'Luis'), (3, 'Marta');

    INSERT INTO escuchas_2nf (id_usuario, cancion_titulo, album_titulo, artista_nombre, pais_artista, fecha)
    SELECT id_usuario, cancion_titulo, album_titulo, artista_nombre, pais_artista, fecha FROM escuchas_1nf;
    """)
    conn.commit()
    print("  ✓ 2NF Cumplida: Atributos del usuario aislados en su propia tabla.")

    # --------------------------------------------------------------------------
    # 2.3 TERCERA FORMA NORMAL (3NF)
    # Regla: Cumple 2NF + Sin dependencias transitivas (A -> B -> C).
    # 'pais_artista' depende de 'artista_nombre', no de la escucha.
    # 'album_titulo' pertenece al artista y la canción pertenece al álbum.
    # --------------------------------------------------------------------------
    print("\n[2.3] APLICANDO LA 3ª FORMA NORMAL (3NF):")
    print("  -> Eliminamos la dependencia transitiva: Artista -> País del Artista.")
    print("  -> Creamos tablas normalizadas: ARTISTAS, ALBUMES, CANCIONES, USUARIOS y ESCUCHAS.")

    cursor.executescript("""
    DROP TABLE IF EXISTS escuchas_3nf;
    DROP TABLE IF EXISTS canciones_3nf;
    DROP TABLE IF EXISTS albumes_3nf;
    DROP TABLE IF EXISTS artistas_3nf;
    DROP TABLE IF EXISTS usuarios_3nf;

    CREATE TABLE usuarios_3nf (
        id_usuario INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL
    );

    CREATE TABLE artistas_3nf (
        id_artista INTEGER PRIMARY KEY,
        nombre TEXT NOT NULL,
        pais TEXT NOT NULL
    );

    CREATE TABLE albumes_3nf (
        id_album INTEGER PRIMARY KEY,
        id_artista INTEGER NOT NULL REFERENCES artistas_3nf(id_artista),
        titulo TEXT NOT NULL,
        anio INTEGER NOT NULL
    );

    CREATE TABLE canciones_3nf (
        id_cancion INTEGER PRIMARY KEY,
        id_album INTEGER NOT NULL REFERENCES albumes_3nf(id_album),
        titulo TEXT NOT NULL,
        duracion_seg INTEGER NOT NULL
    );

    CREATE TABLE escuchas_3nf (
        id_escucha INTEGER PRIMARY KEY AUTOINCREMENT,
        id_usuario INTEGER NOT NULL REFERENCES usuarios_3nf(id_usuario),
        id_cancion INTEGER NOT NULL REFERENCES canciones_3nf(id_cancion),
        fecha TEXT NOT NULL
    );

    -- Población en 3NF
    INSERT INTO usuarios_3nf VALUES (1, 'Ana'), (2, 'Luis'), (3, 'Marta');
    INSERT INTO artistas_3nf VALUES (10, 'The Weeknd', 'Canadá'), (20, 'Imagine Dragons', 'EE. UU.');
    INSERT INTO albumes_3nf VALUES (100, 10, 'After Hours', 2020), (101, 10, 'Starboy', 2016), (200, 20, 'Evolve', 2017);
    INSERT INTO canciones_3nf VALUES 
    (1001, 100, 'Blinding Lights', 200),
    (1002, 100, 'Save Your Tears', 215),
    (1003, 100, 'In Your Eyes', 237),
    (1004, 101, 'Starboy', 230),
    (2001, 200, 'Believer', 204);

    INSERT INTO escuchas_3nf (id_usuario, id_cancion, fecha) VALUES
    (1, 1001, '2026-01-10'),
    (1, 1002, '2026-01-10'),
    (2, 2001, '2026-01-12'),
    (1, 1003, '2026-01-15'),
    (3, 1004, '2026-01-16');
    """)
    conn.commit()

    print("  ✓ 3NF Cumplida con éxito. Consulta con JOINs de la verdad única:")
    cursor.execute("""
    SELECT 
        e.id_escucha,
        u.nombre AS usuario,
        c.titulo AS cancion,
        al.titulo AS album,
        ar.nombre AS artista,
        ar.pais AS pais_artista
    FROM escuchas_3nf e
    JOIN usuarios_3nf u ON e.id_usuario = u.id_usuario
    JOIN canciones_3nf c ON e.id_cancion = c.id_cancion
    JOIN albumes_3nf al ON c.id_album = al.id_album
    JOIN artistas_3nf ar ON al.id_artista = ar.id_artista;
    """)
    print_table(cursor)
    print("  -> Ventaja de 3NF: Si 'The Weeknd' cambia de país, solo se edita 1 sola fila en 'artistas_3nf'.")
    print("  -> Desventaja de 3NF: Requiere encadenar 4 JOINs para obtener el informe completo.")

# ==============================================================================
# 3. SPOTIFY MODELADO DE OTRAS FORMAS: KIMBALL (DIMENSIONAL) Y TABLA ANCHA
# ==============================================================================
def lab_step_3_paradigmas_alternativos(conn):
    banner("PASO 3: PARADIGMAS ALTERNATIVOS: DIMENSIONAL (KIMBALL) Y TABLA ANCHA")
    cursor = conn.cursor()

    # --- 3.1 MODELO DIMENSIONAL KIMBALL (ESQUEMA EN ESTRELLA PARA BI) ---
    print("\n[A] MODELO KIMBALL (Esquema en Estrella optimizado para reportes y cubos analíticos):")
    cursor.executescript("""
    DROP TABLE IF EXISTS fact_escuchas;
    DROP TABLE IF EXISTS dim_usuario;
    DROP TABLE IF EXISTS dim_cancion;
    DROP TABLE IF EXISTS dim_tiempo;

    CREATE TABLE dim_usuario (
        user_key INTEGER PRIMARY KEY,
        nombre TEXT,
        tipo_plan TEXT
    );

    CREATE TABLE dim_cancion (
        song_key INTEGER PRIMARY KEY,
        titulo TEXT,
        artista TEXT,
        album TEXT,
        genero TEXT
    );

    CREATE TABLE dim_tiempo (
        date_key INTEGER PRIMARY KEY,
        fecha TEXT,
        anio INTEGER,
        mes INTEGER
    );

    CREATE TABLE fact_escuchas (
        fact_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_key INTEGER REFERENCES dim_usuario(user_key),
        song_key INTEGER REFERENCES dim_cancion(song_key),
        date_key INTEGER REFERENCES dim_tiempo(date_key),
        segundos_escuchados INTEGER NOT NULL,
        cancion_completada BOOLEAN NOT NULL
    );

    INSERT INTO dim_usuario VALUES (1, 'Ana', 'Premium'), (2, 'Luis', 'Free');
    INSERT INTO dim_cancion VALUES (101, 'Blinding Lights', 'The Weeknd', 'After Hours', 'Pop');
    INSERT INTO dim_tiempo VALUES (20260110, '2026-01-10', 2026, 1);
    INSERT INTO fact_escuchas (user_key, song_key, date_key, segundos_escuchados, cancion_completada)
    VALUES (1, 101, 20260110, 200, 1);
    """)
    conn.commit()
    print("  ✓ Tabla de hechos 'fact_escuchas' creada rodeada de dimensiones descriptivas.")

    # --- 3.2 TABLA ANCHA (WIDE TABLE / ONE BIG TABLE - OBT) ---
    print("\n[B] TABLA ANCHA (One Big Table - OBT):")
    print("  -> Cero JOINs en tiempo de consulta. Almacenamiento plano ideal para ClickHouse/BigQuery.")
    cursor.executescript("""
    DROP TABLE IF EXISTS spotify_wide_table;
    CREATE TABLE spotify_wide_table (
        id_escucha INTEGER PRIMARY KEY,
        fecha TEXT,
        usuario_nombre TEXT,
        tipo_plan TEXT,
        cancion_titulo TEXT,
        duracion_seg INTEGER,
        album_titulo TEXT,
        artista_nombre TEXT,
        artista_pais TEXT,
        segundos_reproducidos INTEGER
    );

    INSERT INTO spotify_wide_table VALUES
    (1, '2026-01-10', 'Ana', 'Premium', 'Blinding Lights', 200, 'After Hours', 'The Weeknd', 'Canadá', 200),
    (2, '2026-01-12', 'Luis', 'Free', 'Believer', 204, 'Evolve', 'Imagine Dragons', 'EE. UU.', 180);
    """)
    conn.commit()
    cursor.execute("SELECT fecha, usuario_nombre, cancion_titulo, artista_nombre, artista_pais FROM spotify_wide_table;")
    print_table(cursor)
    print("  ✓ Consulta instantánea directa sin ningún tipo de JOIN relacional.")

def main():
    print("=" * 80)
    print("🚀 INICIANDO LABORATORIO PRÁCTICO DE MODELADO DE DATOS (1NF, 2NF, 3NF)")
    print("=" * 80)
    conn = sqlite3.connect(DB_FILE)
    try:
        lab_step_1_tabla_caotica(conn)
        lab_step_2_normalizacion(conn)
        lab_step_3_paradigmas_alternativos(conn)
        banner("¡LABORATORIO DE MODELADO FINALIZADO!")
        print(f"Base de datos generada para experimentación: '{DB_FILE}'")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
