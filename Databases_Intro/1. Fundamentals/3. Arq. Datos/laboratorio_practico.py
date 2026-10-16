#!/usr/bin/env python3
"""
==============================================================================
LABORATORIO PRÁCTICO: FUNDAMENTOS DE ARQUITECTURA DE DATOS
==============================================================================
Este script implementa un laboratorio didáctico que reproduce los pilares
de la Arquitectura de Datos moderna utilizando únicamente Python estándar
y SQLite (sin requerir infraestructura pesada ni servicios cloud):

1. FLUJO DE INGESTA Y DATA LAKE (Schema-on-Read en crudo)
2. DATA WAREHOUSE DIMENSIONAL (Esquema en Estrella: Hechos y Dimensiones)
3. COMPARATIVA EN VIVO: PIPELINE ETL vs PIPELINE ELT
4. DATAMARTS DEPARTAMENTALES (Ventas vs Finanzas mediante Vistas SQL)
5. MINIATURA DE ARQUITECTURA LAMBDA (Capa Batch + Capa Speed en Tiempo Real)
==============================================================================
"""

import os
import json
import sqlite3
import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(SCRIPT_DIR, "data_warehouse_lab.db")
RAW_LAKE_DIR = os.path.join(SCRIPT_DIR, "datalake_raw")

def banner(title):
    print("\n" + "=" * 75)
    print(f"  🏢 {title}")
    print("=" * 75)

# ==============================================================================
# 1. DATA LAKE: ALMACENAMIENTO EN CRUDO (Schema-on-Read)
# ==============================================================================
def lab_step_1_data_lake():
    banner("PASO 1: DATA LAKE — Almacenamiento en Crudo (Schema-on-Read)")
    print("Simulando llegada de eventos heterogéneos desde diferentes fuentes...")
    os.makedirs(RAW_LAKE_DIR, exist_ok=True)
    
    # Eventos con formatos variables (típico de un Data Lake: logs, carritos, pagos)
    raw_events = [
        {"event_id": 101, "timestamp": "2026-09-25T10:00:00", "source": "web_store", "customer": "Alice", "product": "Portátil Pro", "category": "Electrónica", "price": 1200.0, "qty": 1},
        {"event_id": 102, "timestamp": "2026-09-25T10:05:00", "source": "mobile_app", "customer": "Bob", "product": "Ratón Inalámbrico", "category": "Accesorios", "price": 25.5, "qty": 2, "discount_code": "PROMO10"},
        {"event_id": 103, "timestamp": "2026-09-25T10:15:00", "source": "web_store", "customer": "Charlie", "product": "Teclado Mecánico", "category": "Accesorios", "price": 85.0, "qty": 1},
        {"event_id": 104, "timestamp": "2026-09-25T10:20:00", "source": "pos_terminal", "customer": "Alice", "product": "Monitor 4K", "category": "Electrónica", "price": 450.0, "qty": 1, "store_id": "Madrid_01"}
    ]
    
    lake_file = os.path.join(RAW_LAKE_DIR, "events_partition_20260925.json")
    with open(lake_file, "w", encoding="utf-8") as f:
        json.dump(raw_events, f, indent=2)
        
    print(f"✓ Guardados {len(raw_events)} eventos crudos en el Data Lake: '{lake_file}'")
    print("  -> Observa que cada evento tiene campos distintos (discount_code, store_id).")
    print("  -> En el Data Lake NO exigimos esquema previo al escribir (Schema-on-Read).")
    return raw_events

# ==============================================================================
# 2. DATA WAREHOUSE: ESQUEMA EN ESTRELLA (Star Schema - Modelo Kimball)
# ==============================================================================
def lab_step_2_star_schema(conn):
    banner("PASO 2: DATA WAREHOUSE — Esquema en Estrella (Star Schema)")
    print("Creando la arquitectura dimensional con Tablas de Hechos y Dimensiones...")
    cursor = conn.cursor()
    
    # 2.1 Tablas de Dimensiones (Contexto del Negocio)
    cursor.executescript("""
    DROP TABLE IF EXISTS fact_sales;
    DROP TABLE IF EXISTS dim_customer;
    DROP TABLE IF EXISTS dim_product;
    DROP TABLE IF EXISTS dim_date;
    DROP TABLE IF EXISTS staging_raw_events;

    CREATE TABLE dim_customer (
        customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT UNIQUE NOT NULL,
        segment TEXT DEFAULT 'Estándar'
    );

    CREATE TABLE dim_product (
        product_id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_name TEXT UNIQUE NOT NULL,
        category TEXT NOT NULL,
        unit_price REAL NOT NULL
    );

    CREATE TABLE dim_date (
        date_id INTEGER PRIMARY KEY, -- Formato YYYYMMDD
        full_date TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        day INTEGER NOT NULL,
        day_of_week TEXT NOT NULL
    );

    -- 2.2 Tabla Central de Hechos (Métricas Cuantitativas)
    CREATE TABLE fact_sales (
        sale_id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER REFERENCES dim_customer(customer_id),
        product_id INTEGER REFERENCES dim_product(product_id),
        date_id INTEGER REFERENCES dim_date(date_id),
        quantity INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        source_system TEXT NOT NULL
    );
    """)
    conn.commit()
    print("✓ Tablas creadas con éxito:")
    print("  ⭐ dim_customer (Dimensión Cliente)")
    print("  ⭐ dim_product  (Dimensión Producto)")
    print("  ⭐ dim_date     (Dimensión Tiempo)")
    print("  📊 fact_sales   (Tabla Central de Hechos: métricas numéricas agregables)")

# ==============================================================================
# 3. PIPELINE DE TRANSFORMACIÓN: ETL vs ELT
# ==============================================================================
def lab_step_3_etl_vs_elt(conn, raw_events):
    banner("PASO 3: ETL vs ELT — Dos Enfoques para Transformar Datos")
    cursor = conn.cursor()
    
    # --- ENFOQUE A: PIPELINE ETL CLÁSICO (Transformar en Python antes de cargar) ---
    print("\n[A] Demostración de ETL (Extract -> Transform en memoria -> Load al DW):")
    print("  1. Extract: Leemos los eventos del Data Lake.")
    print("  2. Transform: Limpiamos, normalizamos y calculamos importes en Python.")
    
    # Poblamos dimensiones previas
    dim_date_data = (20260925, "2026-09-25", 2026, 9, 25, "Viernes")
    cursor.execute("INSERT OR IGNORE INTO dim_date VALUES (?, ?, ?, ?, ?, ?)", dim_date_data)
    
    for ev in raw_events:
        # Transformación en memoria
        c_name = ev["customer"]
        p_name = ev["product"]
        cat = ev["category"]
        price = ev["price"]
        qty = ev["qty"]
        total = price * qty # Métrica calculada en el pipeline ETL
        
        # Inserción controlada en dimensiones
        cursor.execute("INSERT OR IGNORE INTO dim_customer (customer_name) VALUES (?)", (c_name,))
        cursor.execute("INSERT OR IGNORE INTO dim_product (product_name, category, unit_price) VALUES (?, ?, ?)", (p_name, cat, price))
        
        # Recuperamos claves subrogadas (Foreign Keys)
        cursor.execute("SELECT customer_id FROM dim_customer WHERE customer_name = ?", (c_name,))
        cust_id = cursor.fetchone()[0]
        cursor.execute("SELECT product_id FROM dim_product WHERE product_name = ?", (p_name,))
        prod_id = cursor.fetchone()[0]
        
        # Load: Cargar en la tabla de hechos
        cursor.execute("""
            INSERT INTO fact_sales (customer_id, product_id, date_id, quantity, total_amount, source_system)
            VALUES (?, ?, 20260925, ?, ?, ?)
        """, (cust_id, prod_id, qty, total, ev["source"]))
        
    conn.commit()
    print("  3. Load: Hechos insertados limpiamente en 'fact_sales' mediante ETL.")

    # --- ENFOQUE B: PIPELINE ELT MODERNO (Extract -> Load en Staging -> Transform con SQL) ---
    print("\n[B] Demostración de ELT (Extract -> Load a Staging crudo -> Transform con SQL):")
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS staging_raw_events (
        event_payload TEXT,
        ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)
    # 1. Carga directa sin procesar (Load inmediato a staging)
    for ev in raw_events:
        cursor.execute("INSERT INTO staging_raw_events (event_payload) VALUES (?)", (json.dumps(ev),))
    conn.commit()
    print("  1. Load Crudo: Eventos cargados directamente en la tabla 'staging_raw_events'.")
    
    # 2. Transformación SQL in-database (Aprovecha el motor de la base de datos)
    print("  2. Transformación SQL dentro de la base de datos (filosofía dbt / Cloud Warehouse):")
    cursor.execute("""
    SELECT 
        json_extract(event_payload, '$.customer') AS cliente,
        json_extract(event_payload, '$.category') AS categoria,
        SUM(json_extract(event_payload, '$.price') * json_extract(event_payload, '$.qty')) AS total_transformado_en_bd
    FROM staging_raw_events
    GROUP BY cliente, categoria;
    """)
    for row in cursor.fetchall():
        print(f"     -> Cliente: {row[0]:<8} | Categoría: {row[1]:<12} | Total Calculado por SQL: {row[2]:,.2f} €")

# ==============================================================================
# 4. DATAMARTS DEPARTAMENTALES (Vistas Orientadas a Dominio)
# ==============================================================================
def lab_step_4_datamarts(conn):
    banner("PASO 4: DATAMARTS — Subconjuntos de Negocio sin Duplicar Datos")
    print("Creando Datamarts virtuales como vistas especializadas sobre el Data Warehouse...")
    cursor = conn.cursor()
    
    # Datamart para Marketing (Comportamiento de clientes y canales de origen)
    cursor.execute("""
    CREATE VIEW IF NOT EXISTS datamart_marketing AS
    SELECT 
        c.customer_name,
        f.source_system AS canal_captacion,
        COUNT(f.sale_id) AS total_pedidos,
        SUM(f.total_amount) AS ltv_cliente
    FROM fact_sales f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    GROUP BY c.customer_name, f.source_system;
    """)
    
    # Datamart para Finanzas (Facturación y ticket promedio por categoría)
    cursor.execute("""
    CREATE VIEW IF NOT EXISTS datamart_finanzas AS
    SELECT 
        p.category,
        SUM(f.quantity) AS unidades_vendidas,
        SUM(f.total_amount) AS ingresos_totales,
        ROUND(AVG(f.total_amount), 2) AS ticket_medio
    FROM fact_sales f
    JOIN dim_product p ON f.product_id = p.product_id
    GROUP BY p.category;
    """)
    conn.commit()
    
    print("\n📊 Consulta al Datamart de Marketing:")
    cursor.execute("SELECT * FROM datamart_marketing;")
    print(f"   {'Cliente':<10} | {'Canal':<12} | {'Pedidos':<8} | {'Valor de Vida (LTV)':<20}")
    print("   " + "-" * 55)
    for r in cursor.fetchall():
        print(f"   {r[0]:<10} | {r[1]:<12} | {r[2]:<8} | {r[3]:>15,.2f} €")
        
    print("\n📈 Consulta al Datamart de Finanzas:")
    cursor.execute("SELECT * FROM datamart_finanzas;")
    print(f"   {'Categoría':<15} | {'Unidades':<10} | {'Ingresos Totales':<18} | {'Ticket Medio'}")
    print("   " + "-" * 60)
    for r in cursor.fetchall():
        print(f"   {r[0]:<15} | {r[1]:<10} | {r[2]:>15,.2f} € | {r[3]:>10,.2f} €")

# ==============================================================================
# 5. MINIATURA DE ARQUITECTURA LAMBDA (Batch + Streaming en Tiempo Real)
# ==============================================================================
def lab_step_5_lambda_miniature(conn):
    banner("PASO 5: ARQUITECTURA LAMBDA — Unión de Batch y Streaming")
    cursor = conn.cursor()
    
    # 1. Capa Batch: Histórico consolidado almacenado en la tabla de hechos
    cursor.execute("SELECT SUM(total_amount) FROM fact_sales;")
    batch_total = cursor.fetchone()[0] or 0.0
    print(f"📦 Capa Batch (Histórico Consolidado Diario): Facturación cerrada = {batch_total:,.2f} €")
    
    # 2. Capa Speed: Evento recién ocurrido en los últimos 2 segundos (en memoria/cola rápida)
    streaming_event = {
        "event_id": 999,
        "timestamp": datetime.datetime.now().isoformat(),
        "customer": "VIP_Daniel",
        "product": "Servidor Rack",
        "amount": 4999.00
    }
    speed_amount = streaming_event["amount"]
    print(f"⚡ Capa Speed (Streaming en Tiempo Real): Transacción en vivo recibida = +{speed_amount:,.2f} € (Cliente: {streaming_event['customer']})")
    
    # 3. Capa Serving: Combina Batch + Speed para responder la consulta global al instante
    serving_total = batch_total + speed_amount
    print(f"🌐 Capa Serving (Vista Unificada para el Dashboard Ejecutivo):")
    print(f"   >>> TOTAL EN TIEMPO REAL (Batch + Speed) = {serving_total:,.2f} € <<<")
    print("   (La Capa Batch ofrece precisión histórica inmutable, la Capa Speed baja latencia).")

def main():
    print("=" * 75)
    print("🚀 BIENVENIDO AL LABORATORIO DE ARQUITECTURA DE DATOS DESDE CERO")
    print("=" * 75)
    
    # Conexión local SQLite
    conn = sqlite3.connect(DB_FILE)
    
    try:
        events = lab_step_1_data_lake()
        lab_step_2_star_schema(conn)
        lab_step_3_etl_vs_elt(conn, events)
        lab_step_4_datamarts(conn)
        lab_step_5_lambda_miniature(conn)
        
        banner("¡LABORATORIO COMPLETADO CON ÉXITO!")
        print(f"Se ha generado el archivo SQLite local: '{DB_FILE}'")
        print(f"Se ha generado el directorio del Data Lake: '{RAW_LAKE_DIR}/'")
        print("Puedes explorar la base de datos con cualquier cliente SQLite o continuar con la guía .md")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
