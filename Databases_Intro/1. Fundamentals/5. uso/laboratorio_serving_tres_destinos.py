#!/usr/bin/env python3
"""
=============================================================================
LABORATORIO PRÁCTICO: SERVING Y USO DE DATOS (OPERACIONAL, BI Y MACHINE LEARNING)
=============================================================================

📘 GUÍA DIDÁCTICA Y DE ARQUITECTURA:

1. ¿QUÉ ES SQLITE Y POR QUÉ ES TAN ÚTIL?
   -------------------------------------
   • ¿Qué es?: SQLite es un motor de base de datos relacional SQL completo,
     autocontenido, "serverless" (sin servidor central) y de configuración cero.
   • ¿Por qué vive en un único fichero?: Toda la base de datos (tablas, índices,
     vistas, datos) se guarda en un único archivo en disco (ej. 'tienda_techstore.db').
     Esto permite clonarla, compartirla con alumnos o borrarla simplemente
     manejando un archivo ordinario del sistema operativo.
   • ¿Por qué no requiere instalar PostgreSQL/MySQL?: Porque el motor SQLite viene
     integrado de fábrica directamente dentro del intérprete de Python a través
     del módulo estándar `sqlite3`. ¡No necesitas instalar servidores, configurar
     puertos (5432, 3306), ni gestionar usuarios o contraseñas!
   • ¿Es un juguete?: ¡En absoluto! Es el motor de base de datos más desplegado
     del planeta (cada iPhone, Android, navegador web Chrome/Firefox y televisor
     inteligente tiene decenas de bases de datos SQLite operativas). Soporta
     transacciones ACID completas y millones de registros.
   • ¿Cuándo usar SQLite vs PostgreSQL?:
     - Usa SQLite: Prototipos, desarrollo local, docencia, apps móviles, testing.
     - Usa PostgreSQL: Aplicaciones multi-usuario en red con alta concurrencia
       de escrituras simultáneas, analítica masiva y arquitecturas cliente-servidor.

2. LIBRERÍAS NATIVAS VS. LIBRERÍAS DE TERCEROS (PIP)
   -------------------------------------------------
   • Librerías Nativas (Vienen instaladas por defecto con Python):
     - `sqlite3`: Motor de base de datos relacional (rápido y nativo).
     - `os`, `sys`: Interacción con el sistema operativo y argumentos de terminal.
     - `time`, `random`: Medición precisa de latencias y generación de datos.
     - `typing`: Anotaciones de tipos para código robusto y legible.
   
   • Librerías Externas de Machine Learning (NO vienen por defecto):
     - `numpy`: Cálculo matricial y vectores numéricos multidimensionales.
     - `scikit-learn`: Algoritmos de Machine Learning (regresión, árboles, métricas).
     
   ⚠️ ATENCIÓN ALUMNOS - SI TE DA ERROR "ModuleNotFoundError":
      Debes instalar estas librerías en tu terminal ejecutando:
      
         pip install numpy scikit-learn
         
      O si en tu ordenador usas 'python3' y 'pip3':
      
         pip3 install numpy scikit-learn

=============================================================================
MODOS DE EJECUCIÓN DISPONIBLES:
  python3 laboratorio_serving_tres_destinos.py --run-all      (Demostración fluida)
  python3 laboratorio_serving_tres_destinos.py --paso-a-paso  (Con pausas ENTER para leer)
  python3 laboratorio_serving_tres_destinos.py --db           (Ver solo tablas SQLite)
  python3 laboratorio_serving_tres_destinos.py --operacional  (Ver solo API y transacciones)
  python3 laboratorio_serving_tres_destinos.py --bi           (Ver solo Cuadro de Mando BI)
  python3 laboratorio_serving_tres_destinos.py --ml           (Ver solo Machine Learning)
  python3 laboratorio_serving_tres_destinos.py --quiz         (Quiz interactivo)
  python3 laboratorio_serving_tres_destinos.py                (Menú interactivo guiado)
=============================================================================
"""

import sys
import os
import time
import random
import sqlite3
from typing import Dict, Any, List, Tuple

# Ubicación absoluta de la base de datos SQLite (se guarda junto a este script)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_NAME = os.path.join(SCRIPT_DIR, "tienda_techstore.db")


# =============================================================================
# UTILIDAD DIDÁCTICA: CONTROL DE TIEMPO Y PAUSAS PARA LECTURA
# =============================================================================

def pausar_para_lectura(mensaje: str = "Presiona [ENTER] para continuar...", interactivo: bool = False, segundos_espera: float = 1.5):
    """
    Permite a los alumnos leer la información con tranquilidad:
    - Si 'interactivo' es True (o modo --paso-a-paso): pide pulsar ENTER.
    - Si 'interactivo' es False (modo --run-all): hace una pausa breve con puntos suspensivos.
    """
    if interactivo:
        try:
            print(f"\n📖 \033[1;36m{mensaje}\033[0m", end="", flush=True)
            input()
            print()
        except (KeyboardInterrupt, EOFError):
            print()
            sys.exit(0)
    else:
        print(f"\n⏳ Esperando {segundos_espera}s para dar tiempo de lectura...", end="", flush=True)
        time.sleep(segundos_espera)
        print(" [Continuando] 🚀\n")


# =============================================================================
# 0. POBLACIÓN DE LA BASE DE DATOS UNIFICADA (Single Source of Truth)
# =============================================================================

def inicializar_base_de_datos(db_path: str = DB_NAME) -> sqlite3.Connection:
    """
    Crea y puebla la base de datos relacional SQLite que sirve como ÚNICA FUENTE
    DE LA VERDAD para los tres destinos (Operacional, BI y Machine Learning).
    """
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Habilitamos validación estricta de Foreign Keys en SQLite
    cursor.execute("PRAGMA foreign_keys = ON;")

    # 1. Tabla Clientes
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        ciudad TEXT NOT NULL,
        nivel_fidelidad INTEGER NOT NULL DEFAULT 1 CHECK (nivel_fidelidad IN (1, 2, 3)),
        fecha_registro DATE NOT NULL
    );
    """)

    # 2. Tabla Productos (con restricción CHECK de stock no negativo)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE NOT NULL,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL,
        precio REAL NOT NULL CHECK (precio > 0),
        stock INTEGER NOT NULL CHECK (stock >= 0)
    );
    """)

    # 3. Tabla Pedidos (Transaccional)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS pedidos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        cantidad INTEGER NOT NULL CHECK (cantidad > 0),
        precio_unitario REAL NOT NULL,
        total REAL NOT NULL,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        estado TEXT NOT NULL DEFAULT 'COMPLETADO',
        FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE RESTRICT,
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE RESTRICT
    );
    """)

    # 4. Tabla Visitas Web (Comportamiento para BI y ML)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS visitas_web (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        minutos_sesion REAL NOT NULL,
        paginas_vistas INTEGER NOT NULL,
        agrego_al_carrito INTEGER NOT NULL CHECK (agrego_al_carrito IN (0, 1)),
        descargas_folleto INTEGER NOT NULL CHECK (descargas_folleto IN (0, 1)),
        abandono_carrito INTEGER NOT NULL CHECK (abandono_carrito IN (0, 1)),
        FOREIGN KEY (cliente_id) REFERENCES clientes (id)
    );
    """)

    # Si ya existen registros, devolvemos la conexión sin duplicar
    cursor.execute("SELECT COUNT(*) FROM productos;")
    if cursor.fetchone()[0] > 0:
        conn.commit()
        return conn

    # Inserción de catálogo y clientes semilla
    ciudades = ["Madrid", "Barcelona", "Valencia", "Sevilla", "Bilbao"]
    nombres = [
        "Lucía Gómez", "Carlos Ruiz", "Sofía Martín", "David Sanz", "Elena Cano",
        "Javier Pérez", "Marta Gil", "Pablo Ramos", "Laura Vega", "Andrés Castro"
    ]

    for i, nombre in enumerate(nombres, 1):
        email = f"user{i}@techstore.com"
        ciudad = ciudades[i % len(ciudades)]
        fidelidad = (i % 3) + 1
        cursor.execute("""
            INSERT INTO clientes (id, nombre, email, ciudad, nivel_fidelidad, fecha_registro)
            VALUES (?, ?, ?, ?, ?, '2026-01-15')
        """, (i, nombre, email, ciudad, fidelidad))

    productos = [
        ("ZAP-RUN-42", "Zapatillas Running Pro", "Calzado", 89.99, 15),
        ("AUR-WIR-01", "Auriculares Bluetooth Noise-Cancelling", "Electrónica", 129.50, 8),
        ("MOC-TEC-15", "Mochila Ergonomica Portátil", "Accesorios", 45.00, 25),
        ("MON-GAM-27", "Monitor Gaming 27 pulgadas 144Hz", "Electrónica", 210.00, 4),
        ("RAT-ERG-09", "Ratón Inalámbrico Ergonómico", "Accesorios", 29.90, 50)
    ]
    cursor.executemany("""
        INSERT INTO productos (sku, nombre, categoria, precio, stock)
        VALUES (?, ?, ?, ?, ?)
    """, productos)

    # 80 pedidos históricos para BI
    random.seed(42)
    for _ in range(80):
        c_id = random.randint(1, len(nombres))
        p_id = random.randint(1, len(productos))
        qty = random.randint(1, 3)
        precio_u = productos[p_id - 1][3]
        total = round(qty * precio_u, 2)
        estado = random.choice(["COMPLETADO", "COMPLETADO", "COMPLETADO", "EN_CAMINO"])
        cursor.execute("""
            INSERT INTO pedidos (cliente_id, producto_id, cantidad, precio_unitario, total, estado)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (c_id, p_id, qty, precio_u, total, estado))

    # 250 sesiones de navegación web para Machine Learning
    for _ in range(250):
        c_id = random.randint(1, len(nombres))
        minutos = round(random.uniform(0.5, 25.0), 1)
        paginas = max(1, int(minutos * random.uniform(0.5, 1.8)))
        agrego = 1 if minutos > 3.0 and random.random() > 0.3 else 0
        descargas = 1 if random.random() > 0.75 else 0

        score_abandono = (minutos * 0.15) - (agrego * 2.5) - (descargas * 0.8) + random.gauss(0, 0.8)
        abandono = 1 if score_abandono > 0.2 else 0

        cursor.execute("""
            INSERT INTO visitas_web (cliente_id, minutos_sesion, paginas_vistas, agrego_al_carrito, descargas_folleto, abandono_carrito)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (c_id, minutos, paginas, agrego, descargas, abandono))

    conn.commit()
    return conn


# =============================================================================
# INSPECCIÓN DE LA BASE DE DATOS SQLITE (VER EL CONTENIDO DE LAS TABLAS)
# =============================================================================

def mostrar_contenido_base_datos(conn: sqlite3.Connection):
    """Muestra el contenido real de la base de datos SQLite antes de servirla."""
    cursor = conn.cursor()
    print("\n" + "=" * 80)
    print(" 🔍 INSPECTOR DE BASE DE DATOS: CONTENIDO REAL EN SQLITE ('tienda_techstore.db')")
    print("=" * 80)
    print("Explicación: Aquí vemos las tablas relacionales tal y como están almacenadas.")
    print("Cada tabla tiene tipos estrictos, claves primarias (PK) y claves foráneas (FK).\n")

    # 1. Resumen de tablas
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    tablas = [fila[0] for fila in cursor.fetchall()]

    print("📋 TABLAS DETECTADAS Y VOLUMEN DE REGISTROS:")
    for t in tablas:
        cursor.execute(f"SELECT COUNT(*) FROM {t};")
        conteo = cursor.fetchone()[0]
        print(f"   • Tabla '{t:<12}': {conteo:>4} registros")
    print("-" * 80)

    # 2. Clientes
    print("\n👤 TABLA 'clientes' (Muestra de las primeras 5 filas):")
    print(f"  {'ID':<4} | {'Nombre':<15} | {'Email':<22} | {'Ciudad':<10} | {'Fidelidad':<10} | {'Fecha Reg.'}")
    print("  " + "-" * 75)
    cursor.execute("SELECT id, nombre, email, ciudad, nivel_fidelidad, fecha_registro FROM clientes LIMIT 5;")
    for r in cursor.fetchall():
        fidelidad_str = {1: "1-Bronce", 2: "2-Plata", 3: "3-Oro"}.get(r[4], str(r[4]))
        print(f"  {r[0]:<4} | {r[1]:<15} | {r[2]:<22} | {r[3]:<10} | {fidelidad_str:<10} | {r[5]}")

    # 3. Productos
    print("\n📦 TABLA 'productos' (Catálogo completo y existencias de stock en vivo):")
    print(f"  {'ID':<4} | {'SKU':<12} | {'Nombre':<35} | {'Categoría':<12} | {'Precio':<10} | {'Stock Actual'}")
    print("  " + "-" * 88)
    cursor.execute("SELECT id, sku, nombre, categoria, precio, stock FROM productos;")
    for r in cursor.fetchall():
        print(f"  {r[0]:<4} | {r[1]:<12} | {r[2]:<35} | {r[3]:<12} | {r[4]:>7.2f} € | {r[5]:>4} uds")

    # 4. Pedidos
    print("\n🛒 TABLA 'pedidos' (Últimos 5 pedidos registrados en el sistema):")
    print(f"  {'ID':<4} | {'Cliente ID':<10} | {'Prod. ID':<8} | {'Cantidad':<8} | {'Total':<10} | {'Estado':<12} | {'Fecha'}")
    print("  " + "-" * 80)
    cursor.execute("SELECT id, cliente_id, producto_id, cantidad, total, estado, fecha FROM pedidos ORDER BY id DESC LIMIT 5;")
    for r in cursor.fetchall():
        print(f"  {r[0]:<4} | {r[1]:<10} | {r[2]:<8} | {r[3]:<8} | {r[4]:>8.2f} € | {r[5]:<12} | {r[6]}")

    # 5. Visitas Web
    print("\n🌐 TABLA 'visitas_web' (Eventos de navegación para BI y Machine Learning):")
    print(f"  {'ID':<4} | {'Cliente ID':<10} | {'Minutos':<8} | {'Páginas':<8} | {'¿Añadió Cesta?':<15} | {'¿Descargó Folleto?':<18} | {'Abandono (TARGET)'}")
    print("  " + "-" * 95)
    cursor.execute("SELECT id, cliente_id, minutos_sesion, paginas_vistas, agrego_al_carrito, descargas_folleto, abandono_carrito FROM visitas_web LIMIT 5;")
    for r in cursor.fetchall():
        cesta_str = "SÍ (1)" if r[4] == 1 else "NO (0)"
        folleto_str = "SÍ (1)" if r[5] == 1 else "NO (0)"
        abandono_str = "🔴 ABANDONÓ (1)" if r[6] == 1 else "🟢 COMPRÓ (0)"
        print(f"  {r[0]:<4} | {r[1]:<10} | {r[2]:>7.1f} | {r[3]:>7} | {cesta_str:<15} | {folleto_str:<18} | {abandono_str}")

    print("\n" + ">" * 3 + " 💡 Conclusión SQLite: Todos estos datos residen en un único archivo '.db', listos para ser servidos.")


# =============================================================================
# DESTINO 1: SISTEMAS OPERACIONALES (APIs, Transacciones ACID, Baja Latencia)
# =============================================================================

def destino_operacional(conn: sqlite3.Connection):
    """Demuestra cómo los datos sirven a aplicaciones en tiempo real con transacciones ACID."""
    print("\n" + "=" * 80)
    print(" 🛠️  DESTINO 1: SISTEMA OPERACIONAL (APIs en Tiempo Real y Transacciones ACID)")
    print("=" * 80)
    print("Objetivo: Respuestas ultrarrápidas (< 50 ms) para sostener la operativa diaria.")
    print("Requisitos técnicos: Baja latencia, consistencia ACID, transacciones atómicas.\n")

    cursor = conn.cursor()

    # 1. Petición API puntual
    sku_a_buscar = "AUR-WIR-01"

    # Reposición didáctica automática si el stock cayó por compras repetidas en ejecuciones anteriores
    cursor.execute("SELECT stock FROM productos WHERE sku = ?", (sku_a_buscar,))
    stk_row = cursor.fetchone()
    if stk_row and stk_row[0] < 4:
        cursor.execute("UPDATE productos SET stock = 8 WHERE sku = ?", (sku_a_buscar,))
        conn.commit()

    print(f"⏳ [Paso 1/2] Simulando petición API [GET /api/v1/productos?sku={sku_a_buscar}]...", end="", flush=True)
    t_inicio = time.perf_counter()
    cursor.execute("SELECT id, nombre, categoria, precio, stock FROM productos WHERE sku = ?", (sku_a_buscar,))
    prod = cursor.fetchone()
    latencia_ms = round((time.perf_counter() - t_inicio) * 1000, 2)
    print(f" [Respondido en {latencia_ms} ms] ✅")

    if prod:
        print(f"   📦 Producto encontrado: {prod[1]}")
        print(f"   💰 Precio oficial: {prod[3]:.2f} €  |  📦 Stock actual disponible: {prod[4]} unidades")
    print("-" * 80)

    # 2. Transacción de compra con Rollback
    print("⏳ [Paso 2/2] Probando compras transaccionales concurrentes...")

    def ejecutar_compra(cliente_id: int, sku: str, cantidad_deseada: int):
        print(f"\n🛒 Intento de compra: Cliente #{cliente_id} solicita {cantidad_deseada} uds de '{sku}'")
        try:
            cursor.execute("BEGIN TRANSACTION;")
            cursor.execute("SELECT id, nombre, precio, stock FROM productos WHERE sku = ?", (sku,))
            fila = cursor.fetchone()
            if not fila:
                print("   ❌ Error 404: Producto inexistente.")
                cursor.execute("ROLLBACK;")
                return

            p_id, p_nom, p_precio, p_stock = fila
            print(f"   🔍 Comprobando inventario físico en vivo... (Stock en almacén: {p_stock} unidades)")

            if p_stock < cantidad_deseada:
                print(f"   ⚠️ CONFLICTO OPERACIONAL (HTTP 409 Conflict): Stock insuficiente.")
                print(f"   ❌ Solicitados: {cantidad_deseada} | Disponibles en almacén: {p_stock}")
                print(f"   🔄 Ejecutando ROLLBACK. La transacción se cancela; no se cobra ni se modifica nada.")
                cursor.execute("ROLLBACK;")
                return

            nuevo_stock = p_stock - cantidad_deseada
            cursor.execute("UPDATE productos SET stock = ? WHERE id = ?", (nuevo_stock, p_id))

            total_pagar = round(cantidad_deseada * p_precio, 2)
            cursor.execute("""
                INSERT INTO pedidos (cliente_id, producto_id, cantidad, precio_unitario, total, estado)
                VALUES (?, ?, ?, ?, ?, 'COMPLETADO')
            """, (cliente_id, p_id, cantidad_deseada, p_precio, total_pagar))
            pedido_creado_id = cursor.lastrowid

            cursor.execute("COMMIT;")
            print(f"   ✅ ¡TRANSACCIÓN EXITOSA (HTTP 201 Created)!")
            print(f"   📝 Pedido #{pedido_creado_id} registrado por un importe total de {total_pagar:.2f} €.")
            print(f"   📉 Stock actualizado de '{p_nom}': de {p_stock} pasa a {nuevo_stock} unidades.")

        except Exception as e:
            cursor.execute("ROLLBACK;")
            print(f"   💥 Excepción de sistema: {e}. Se ejecutó ROLLBACK por seguridad de datos.")

    # Demostración A: Con stock suficiente
    ejecutar_compra(cliente_id=1, sku="AUR-WIR-01", cantidad_deseada=2)

    # Demostración B: Con stock insuficiente (dispara Rollback)
    ejecutar_compra(cliente_id=2, sku="AUR-WIR-01", cantidad_deseada=50)

    print("\n" + ">" * 3 + " 👁️  Lección Operacional: En este destino manda la inmediatez y la consistencia ACID.")


# =============================================================================
# DESTINO 2: BUSINESS INTELLIGENCE Y ANALÍTICA (Métricas, Agregaciones y KPIs)
# =============================================================================

def destino_bi_analitica(conn: sqlite3.Connection):
    """Demuestra cómo los datos sirven para la toma de decisiones humanas."""
    print("\n" + "=" * 80)
    print(" 📊  DESTINO 2: BUSINESS INTELLIGENCE Y ANALÍTICA (Cuadro de Mando Ejecutivo)")
    print("=" * 80)
    print("Objetivo: Transformar datos históricos y agrupados en conocimiento para tomar decisiones.")
    print("Requisitos clave: Métricas semánticas consistentes, datos limpios, vistas analíticas.\n")

    cursor = conn.cursor()

    print("⏳ [Paso 1/3] Calculando métricas globales de facturación (SUM, AVG, COUNT)...", end="", flush=True)
    t0 = time.perf_counter()
    cursor.execute("""
    SELECT 
        COUNT(id) AS total_pedidos,
        SUM(total) AS facturacion_total,
        AVG(total) AS ticket_medio,
        SUM(cantidad) AS unidades_vendidas
    FROM pedidos
    WHERE estado != 'CANCELADO';
    """)
    total_pedidos, facturacion, ticket_medio, unidades = cursor.fetchone()
    print(f" [Completado en {(time.perf_counter() - t0)*1000:.2f} ms] ✅")

    print("⏳ [Paso 2/3] Calculando tasa de conversión web sobre sesiones históricas...", end="", flush=True)
    cursor.execute("""
    SELECT 
        COUNT(*) AS total_sesiones,
        SUM(CASE WHEN abandono_carrito = 0 THEN 1 ELSE 0 END) AS sesiones_convertidas
    FROM visitas_web;
    """)
    total_sesiones, convertidas = cursor.fetchone()
    tasa_conversion = (convertidas / total_sesiones * 100) if total_sesiones else 0
    print(" [Completado] ✅")

    print("⏳ [Paso 3/3] Renderizando Cuadro de Mando Ejecutivo...\n")

    print("┌────────────────────────────────────────────────────────────────────────┐")
    print("│                     TECHSTORE - DASHBOARD EJECUTIVO                    │")
    print("├──────────────────┬──────────────────┬──────────────────┬───────────────┤")
    print(f"│ Facturación Total│ Ticket Medio     │ Pedidos Totales  │ Tasa Convers. │")
    print(f"│  {facturacion:>10.2f} € │   {ticket_medio:>10.2f} € │     {total_pedidos:>8} uds │    {tasa_conversion:>8.1f} % │")
    print("└──────────────────┴──────────────────┴──────────────────┴───────────────┘\n")

    # Ranking con barras ASCII
    print("🏆 PRODUCTOS MÁS VENDIDOS (Ranking por Unidades Vendidas):")
    cursor.execute("""
    SELECT 
        pr.nombre,
        SUM(pe.cantidad) AS uds_vendidas,
        SUM(pe.total) AS total_euros
    FROM pedidos pe
    JOIN productos pr ON pe.producto_id = pr.id
    GROUP BY pr.id, pr.nombre
    ORDER BY uds_vendidas DESC
    LIMIT 3;
    """)
    top_prods = cursor.fetchall()
    max_uds = top_prods[0][1] if top_prods else 1

    for prod_nom, uds, euros in top_prods:
        bar_len = int((uds / max_uds) * 20)
        barra = "█" * bar_len + "░" * (20 - bar_len)
        print(f"  • {prod_nom[:32]:<32} | {barra} | {uds:>3} uds | {euros:>8.2f} €")

    # Facturación por ciudad
    print("\n🌍 FACTURACIÓN POR CIUDAD:")
    cursor.execute("""
    SELECT 
        cl.ciudad,
        COUNT(DISTINCT pe.id) AS num_pedidos,
        SUM(pe.total) AS facturado,
        ROUND(SUM(pe.total) * 100.0 / (SELECT SUM(total) FROM pedidos), 1) AS pct_share
    FROM pedidos pe
    JOIN clientes cl ON pe.cliente_id = cl.id
    GROUP BY cl.ciudad
    ORDER BY facturado DESC;
    """)
    for ciudad, pedidos_c, fact_c, pct in cursor.fetchall():
        print(f"  📍 {ciudad:<12} -> {pedidos_c:>2} compras | {fact_c:>8.2f} € ({pct:>4.1f}% del total)")

    print("\n" + ">" * 3 + " 👁️  Lección BI: Los directores no leen filas individuales; leen patrones, rankings y métricas agregadas.")


# =============================================================================
# DESTINO 3: MACHINE LEARNING (Features, Entrenamiento, Evaluación e Inferencia)
# =============================================================================

def destino_machine_learning(conn: sqlite3.Connection):
    """
    Demuestra cómo los datos sirven a modelos matemáticos:
    - Carga controlada en tiempo real de Scikit-Learn y NumPy con feedback visual.
    - Preparación de vector de características (Feature Engineering).
    - Separación Train/Test para validación honesta.
    - Entrenamiento de un modelo clasificador de abandono de carrito (LogisticRegression).
    - Inferencia viva: evaluar dos perfiles de usuario en tiempo real y disparar acciones automáticas.
    """
    print("\n" + "=" * 80)
    print(" 🤖  DESTINO 3: MACHINE LEARNING (Predicción de Abandono de Carrito)")
    print("=" * 80)
    print("Objetivo: Encontrar patrones matemáticos en datos históricos para predecir el futuro.")
    print("Requisitos clave: Features consistentes, ausencia de Data Leakage, reproducibilidad.\n")

    # 👁️ PASO 1: CARGA DINÁMICA DE LIBRERÍAS CIENTÍFICAS CON FEEDBACK INMEDIATO
    print("⏳ [Paso 1/5] Cargando librerías científicas ('numpy' y 'scikit-learn')... ", end="", flush=True)
    t_load = time.perf_counter()
    try:
        import numpy as np
        from sklearn.linear_model import LogisticRegression
        from sklearn.model_selection import train_test_split
        from sklearn.metrics import accuracy_score
        duracion_carga = time.perf_counter() - t_load
        print(f"✅ ¡Listas en {duracion_carga:.2f} segundos!\n")
    except ImportError as err:
        print("❌ ERROR")
        print("\n" + "!" * 75)
        print("❌ AVISO: Las librerías de Machine Learning 'numpy' o 'scikit-learn' no están instaladas.")
        print(f"   Detalle del error de importación: {err}")
        print("\n💡 CÓMO SOLUCIONARLO EN TU TERMINAL:")
        print("   Ejecuta el siguiente comando para instalarlas con pip:")
        print("   -----------------------------------------------------")
        print("   pip install numpy scikit-learn")
        print("   (o bien: pip3 install numpy scikit-learn)")
        print("   -----------------------------------------------------")
        print("   Una vez instaladas, vuelve a ejecutar esta opción.")
        print("!" * 75 + "\n")
        return

    cursor = conn.cursor()

    # 👁️ PASO 2: EXTRACCIÓN DE CARACTERÍSTICAS
    print("⏳ [Paso 2/5] Extrayendo 250 registros de comportamiento web desde SQLite para el Feature Store...", end="", flush=True)
    cursor.execute("""
    SELECT 
        v.minutos_sesion,
        v.paginas_vistas,
        v.agrego_al_carrito,
        v.descargas_folleto,
        c.nivel_fidelidad,
        v.abandono_carrito
    FROM visitas_web v
    JOIN clientes c ON v.cliente_id = c.id;
    """)
    filas = cursor.fetchall()

    X = np.array([f[:5] for f in filas])
    y = np.array([f[5] for f in filas])
    feature_names = ["minutos_sesion", "paginas_vistas", "agrego_al_carrito", "descargas_folleto", "fidelidad"]
    print(" ✅ Completado.")
    print(f"   • Total de sesiones históricas analizadas: {len(X)}")
    print(f"   • Características de entrada (Features X): {feature_names}")
    print(f"   • Variable objetivo (Target y): abandono_carrito (1=Abandona, 0=Compra)")

    # 👁️ PASO 3: TRAIN / TEST SPLIT
    print("\n⏳ [Paso 3/5] Dividiendo dataset en entrenamiento (80%) y prueba (20%)...", end="", flush=True)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.20, random_state=42)
    print(" ✅ Listo.")
    print(f"   • Muestras para entrenamiento (Training Set): {len(X_train)}")
    print(f"   • Muestras para validación (Test Set no visto): {len(X_test)}")

    # 👁️ PASO 4: AJUSTE Y ENTRENAMIENTO DEL MODELO
    print("\n⏳ [Paso 4/5] Entrenando LogisticRegression (ajuste matemático de pesos)...", end="", flush=True)
    t_train = time.perf_counter()
    modelo = LogisticRegression(max_iter=500)
    modelo.fit(X_train, y_train)
    tiempo_entrenamiento = (time.perf_counter() - t_train) * 1000
    print(f" ✅ ¡Modelo ajustado en {tiempo_entrenamiento:.2f} ms!")

    y_pred = modelo.predict(X_test)
    exactitud = accuracy_score(y_test, y_pred) * 100

    print(f"\n🧠 RESULTADOS DEL APRENDIZAJE:")
    print(f"   🎯 Precisión global (Accuracy en test no visto): {exactitud:.1f}%")
    print("   ⚖️  Pesos aprendidos por el modelo (Importancia de cada feature):")
    for nombre_feat, coef in zip(feature_names, modelo.coef_[0]):
        impacto = "Aumenta riesgo abandono ↗️" if coef > 0 else "Reduce riesgo (propensión compra) ↘️"
        print(f"      - {nombre_feat:<18}: {coef:>+6.3f} ({impacto})")

    # 👁️ PASO 5: INFERENCIA EN VIVO
    print("\n⚡ [Paso 5/5] INFERENCIA EN TIEMPO REAL (Scoring de visitantes activos en la web):")
    
    visitantes_a_evaluar = [
        {
            "perfil": "Visitante A (Dudoso / Alto Riesgo)",
            "datos": [22.0, 14, 0, 0, 1],
            "desc": "Sesión larga (22 min), 14 páginas vistas, carrito vacío, cliente nuevo"
        },
        {
            "perfil": "Visitante B (Decidido / Bajo Riesgo)",
            "datos": [4.5, 3, 1, 1, 3],
            "desc": "Sesión directa (4.5 min), agregó producto a cesta, descargó folleto, cliente Oro"
        }
    ]

    for v in visitantes_a_evaluar:
        vector = np.array([v["datos"]])
        prob_abandono = modelo.predict_proba(vector)[0][1] * 100
        
        print(f"\n   👤 {v['perfil']}:")
        print(f"      Características: {v['desc']}")
        print(f"      🔮 Predicción del Modelo: {prob_abandono:.1f}% probabilidad de abandono")
        
        if prob_abandono >= 65.0:
            print(f"      🚨 ACCIÓN EN TIEMPO REAL DISPARADA (Alerta Abandono >= 65%):")
            print(f"         🏷️ Mostrar pop-up emergente con cupón 'DESCUENTO15' (Válido 10 minutos).")
        else:
            print(f"      ✅ ACCIÓN EN TIEMPO REAL:")
            print(f"         🛒 Experiencia fluida: alta probabilidad de compra orgánica sin intervención.")

    print("\n" + ">" * 3 + " 👁️  Lección ML: El modelo no sirve de nada en un notebook si no se conecta a un sistema que actúe en producción.")


# =============================================================================
# 4. QUIZ DIDÁCTICO INTERACTIVO PARA ALUMNOS
# =============================================================================

def quiz_didactico():
    """Preguntas interactivas con explicación pedagógica inmediata."""
    preguntas = [
        {
            "escenario": "El Director Financiero necesita un reporte consolidado con las ventas totales de cada tienda del país durante el último trimestre para la junta de accionistas.",
            "opciones": ["1. Sistema Operacional", "2. Business Intelligence (BI)", "3. Machine Learning"],
            "correcta": 2,
            "explicacion": "Es un caso clásico de BI: requiere datos históricos, agregados (SUM, GROUP BY) y está pensado para que un humano tome decisiones estratégicas."
        },
        {
            "escenario": "Un usuario pulsa el botón 'Pagar con Visa' en una tienda online y el sistema debe verificar en 80 milisegundos si la tarjeta está activa y tiene saldo.",
            "opciones": ["1. Sistema Operacional", "2. Business Intelligence (BI)", "3. Machine Learning"],
            "correcta": 1,
            "explicacion": "Es un Sistema Operacional: requiere latencia ultra baja (< 100 ms), alta disponibilidad y una transacción individual por clave única."
        },
        {
            "escenario": "Spotify analiza tu historial de canciones de los últimos 6 meses para generar automáticamente tu lista semanal personalizada 'Descubrimiento Semanal'.",
            "opciones": ["1. Sistema Operacional", "2. Business Intelligence (BI)", "3. Machine Learning"],
            "correcta": 3,
            "explicacion": "Es Machine Learning: un algoritmo aprende patrones en el comportamiento histórico para hacer recomendaciones probabilísticas individualizadas."
        }
    ]

    print("\n" + "=" * 80)
    print(" 🎓  QUIZ INTERACTIVO: ¿QUÉ DESTINO DE SERVING CORRESPONDE A CADA CASO?")
    print("=" * 80)

    aciertos = 0
    for idx, p in enumerate(preguntas, 1):
        print(f"\nCaso {idx}: {p['escenario']}")
        for opc in p["opciones"]:
            print(f"  {opc}")
        
        eleccion = input("\n👉 Tu respuesta (1, 2 o 3, o Enter para ver solución): ").strip()
        if eleccion == str(p["correcta"]):
            print(f"  ✅ ¡CORRECTO! {p['explicacion']}")
            aciertos += 1
        else:
            print(f"  ❌ Respuesta esperada: Opción {p['correcta']}.")
            print(f"  💡 Explicación: {p['explicacion']}")

    print(f"\n🎉 Puntuación final: {aciertos}/{len(preguntas)} aciertos.")


# =============================================================================
# MENÚ PRINCIPAL Y CONTROLADOR DE ARGUMENTOS
# =============================================================================

def menu_principal():
    conn = inicializar_base_de_datos()

    while True:
        print("\n" + "=" * 75)
        print("  🚀 CURSO PRÁCTICO: SERVING Y USO DE DATOS EN 3 DESTINOS")
        print("=" * 75)
        print("  0. Inspeccionar contenido de la base de datos SQLite (Tablas y Datos)")
        print("  1. Probar Destino 1: Sistema Operacional (API en ms, Stock, ACID)")
        print("  2. Probar Destino 2: Business Intelligence (Dashboard y KPIs)")
        print("  3. Probar Destino 3: Machine Learning (Entrenamiento e Inferencia)")
        print("  4. Ejecutar FLUJO PASO A PASO (Con pausas para leer con calma)")
        print("  5. Ejecutar DEMOSTRACIÓN COMPLETA RÁPIDA (Sin pausas)")
        print("  6. Realizar Quiz de Autoevaluación para alumnos")
        print("  9. Salir")
        print("=" * 75)

        opcion = input("Elige una opción (0-6, 9 para salir): ").strip()

        if opcion == "0":
            mostrar_contenido_base_datos(conn)
        elif opcion == "1":
            destino_operacional(conn)
        elif opcion == "2":
            destino_bi_analitica(conn)
        elif opcion == "3":
            destino_machine_learning(conn)
        elif opcion == "4":
            print("\n📖 INICIANDO RECORRIDO DIDÁCTICO PASO A PASO...")
            mostrar_contenido_base_datos(conn)
            pausar_para_lectura("Presiona [ENTER] para pasar al Destino 1 (Sistema Operacional)...", interactivo=True)
            destino_operacional(conn)
            pausar_para_lectura("Presiona [ENTER] para pasar al Destino 2 (Business Intelligence)...", interactivo=True)
            destino_bi_analitica(conn)
            pausar_para_lectura("Presiona [ENTER] para pasar al Destino 3 (Machine Learning)...", interactivo=True)
            destino_machine_learning(conn)
            print("\n🎉 ¡Has completado el recorrido por los tres destinos del serving!")
        elif opcion == "5":
            mostrar_contenido_base_datos(conn)
            pausar_para_lectura(interactivo=False, segundos_espera=1.5)
            destino_operacional(conn)
            pausar_para_lectura(interactivo=False, segundos_espera=1.5)
            destino_bi_analitica(conn)
            pausar_para_lectura(interactivo=False, segundos_espera=1.5)
            destino_machine_learning(conn)
        elif opcion == "6":
            quiz_didactico()
        elif opcion == "9":
            print("\n👋 ¡Hasta luego! Recuerda: el dato solo tiene valor cuando se sirve con impacto.")
            break
        else:
            print("⚠️ Opción no válida. Introduce un número del menú.")

    conn.close()


def main():
    conn = inicializar_base_de_datos()

    if "--paso-a-paso" in sys.argv:
        print("▶️ Ejecutando recorrido didáctico PASO A PASO con pausas de lectura...\n")
        mostrar_contenido_base_datos(conn)
        pausar_para_lectura("Presiona [ENTER] para pasar al Destino 1 (Operacional)...", interactivo=True)
        destino_operacional(conn)
        pausar_para_lectura("Presiona [ENTER] para pasar al Destino 2 (BI / Analítica)...", interactivo=True)
        destino_bi_analitica(conn)
        pausar_para_lectura("Presiona [ENTER] para pasar al Destino 3 (Machine Learning)...", interactivo=True)
        destino_machine_learning(conn)
        conn.close()
        sys.exit(0)
    elif "--run-all" in sys.argv:
        print("▶️ Ejecutando demostración fluida con pausas de lectura...\n")
        mostrar_contenido_base_datos(conn)
        pausar_para_lectura(interactivo=False, segundos_espera=1.2)
        destino_operacional(conn)
        pausar_para_lectura(interactivo=False, segundos_espera=1.2)
        destino_bi_analitica(conn)
        pausar_para_lectura(interactivo=False, segundos_espera=1.2)
        destino_machine_learning(conn)
        conn.close()
        sys.exit(0)
    elif "--db" in sys.argv or "--tablas" in sys.argv:
        mostrar_contenido_base_datos(conn)
        conn.close()
        sys.exit(0)
    elif "--operacional" in sys.argv or "--operativo" in sys.argv:
        destino_operacional(conn)
        conn.close()
        sys.exit(0)
    elif "--bi" in sys.argv or "--consulta" in sys.argv or "--analitica" in sys.argv:
        destino_bi_analitica(conn)
        conn.close()
        sys.exit(0)
    elif "--ml" in sys.argv or "--machine-learning" in sys.argv:
        destino_machine_learning(conn)
        conn.close()
        sys.exit(0)
    elif "--quiz" in sys.argv:
        conn.close()
        quiz_didactico()
        sys.exit(0)

    menu_principal()


if __name__ == "__main__":
    main()
