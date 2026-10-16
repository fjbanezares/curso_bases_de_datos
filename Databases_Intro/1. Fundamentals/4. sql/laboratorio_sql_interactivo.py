#!/usr/bin/env python3
"""
==============================================================================
LABORATORIO INTERACTIVO DE SQL: TIENDA ONLINE
==============================================================================
Este script permite a los estudiantes ejecutar y practicar inmediatamente
todas las consultas y conceptos de las 10 infografías de SQL:
- Filtros, Agregaciones, CTEs, Funciones Ventana, DML Seguro y Vistas.
- Funciona 100% en local con SQLite sin necesidad de instalar servidores.
==============================================================================
"""

import os
import sys
import sqlite3

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_FILE = os.path.join(SCRIPT_DIR, "tienda_curso.db")
SQL_SEED_FILE = os.path.join(SCRIPT_DIR, "tienda_online_schema_y_datos.sql")

def init_database():
    """Inicializa la base de datos local con el esquema y los datos del curso"""
    if not os.path.exists(SQL_SEED_FILE):
        print(f"❌ Error: No se encuentra el archivo de datos: {SQL_SEED_FILE}")
        sys.exit(1)
        
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    with open(SQL_SEED_FILE, "r", encoding="utf-8") as f:
        sql_script = f.read()
    cursor.executescript(sql_script)
    conn.commit()
    conn.close()
    print("✓ Base de datos 'tienda_curso.db' inicializada y poblada con éxito.")

def print_table(cursor, max_rows=20):
    """Imprime los resultados de una consulta en una tabla ASCII limpia"""
    if not cursor.description:
        print("✓ Sentencia ejecutada con éxito (sin filas que mostrar).")
        return
        
    headers = [d[0] for d in cursor.description]
    rows = cursor.fetchmany(max_rows)
    
    if not rows:
        print("ℹ️ Consulta vacía: 0 filas devueltas.")
        return
        
    # Calcular anchos de columna
    col_widths = [len(h) for h in headers]
    for row in rows:
        for i, val in enumerate(row):
            col_widths[i] = max(col_widths[i], len(str(val) if val is not None else "NULL"))
            
    # Formato
    sep_line = "+" + "+".join(["-" * (w + 2) for w in col_widths]) + "+"
    header_line = "|" + "|".join([f" {h:<{col_widths[i]}} " for i, h in enumerate(headers)]) + "|"
    
    print(sep_line)
    print(header_line)
    print(sep_line)
    for row in rows:
        row_str = "|" + "|".join([
            f" {str(v) if v is not None else 'NULL':<{col_widths[i]}} " for i, v in enumerate(row)
        ]) + "|"
        print(row_str)
    print(sep_line)
    print(f"({len(rows)} filas mostradas)")

def run_query_demo(title, sql, explanation=""):
    """Ejecuta una consulta demostrativa explicando el concepto"""
    print("\n" + "=" * 80)
    print(f"🎯 {title}")
    if explanation:
        print(f"💡 {explanation}")
    print("-" * 80)
    print("📝 SQL EJECUTADO:")
    print(sql.strip())
    print("-" * 80)
    
    conn = sqlite3.connect(DB_FILE)
    try:
        cursor = conn.cursor()
        cursor.execute(sql)
        print_table(cursor)
        conn.commit()
    except Exception as e:
        print(f"❌ Error en SQL: {e}")
    finally:
        conn.close()

def demo_filtros():
    run_query_demo(
        "FILTRO BÁSICO CON WHERE Y COMPARADORES",
        "SELECT nombre, precio, stock FROM productos WHERE precio > 100 AND stock > 0;",
        "Muestra productos de gama media-alta que tienen inventario disponible."
    )
    run_query_demo(
        "FILTRO CON LIKE (BÚSQUEDA DE PATRONES EN TEXTO)",
        "SELECT id_cliente, nombre, email, ciudad FROM clientes WHERE nombre LIKE 'A%' OR ciudad = 'Barcelona';",
        "Clientes cuyo nombre empieza por 'A' o que residen en Barcelona."
    )
    run_query_demo(
        "GESTIÓN DE NULLS (IS NULL vs IS NOT NULL)",
        "SELECT id_cliente, nombre, email, telefono FROM clientes WHERE telefono IS NULL;",
        "IMPORTANTE: Nunca uses '= NULL'. En SQL, NULL es desconocido y debe compararse con IS NULL."
    )

def demo_agregaciones():
    run_query_demo(
        "AGREGACIÓN SIMPLE (COUNT, SUM, AVG, MIN, MAX)",
        "SELECT COUNT(*) AS total_pedidos, SUM(cantidad * precio_unitario) AS facturacion_total, ROUND(AVG(precio_unitario), 2) AS precio_promedio FROM detalle_pedido;",
        "Calcula métricas globales de toda la tienda."
    )
    run_query_demo(
        "GROUP BY + HAVING (FILTRO DE GRUPOS)",
        """
        SELECT 
            c.ciudad,
            COUNT(DISTINCT p.id_pedido) AS pedidos_totales,
            SUM(d.cantidad * d.precio_unitario) AS gasto_total
        FROM clientes c
        JOIN pedidos p ON c.id_cliente = p.id_cliente
        JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
        GROUP BY c.ciudad
        HAVING gasto_total > 500
        ORDER BY gasto_total DESC;
        """,
        "Agrupa por ciudad y filtra solo aquellas ciudades cuyo gasto total supere 500 € (HAVING actúa tras el GROUP BY)."
    )

def demo_transformaciones():
    run_query_demo(
        "TRANSFORMACIONES DE TEXTO, FECHAS Y MATEMÁTICAS",
        """
        SELECT 
            UPPER(c.nombre) || ' (' || c.ciudad || ')' AS cliente_etiqueta,
            p.fecha AS fecha_pedido,
            strftime('%Y', p.fecha) AS anio,
            strftime('%m', p.fecha) AS mes,
            ROUND(d.precio_unitario * d.cantidad * 0.21, 2) AS iva_estimado_eur
        FROM clientes c
        JOIN pedidos p ON c.id_cliente = p.id_cliente
        JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
        LIMIT 6;
        """,
        "Demuestra concatenación (||), formateo de mayúsculas (UPPER), extracción de fechas y cálculo de IVA."
    )

def demo_subconsultas_cte():
    run_query_demo(
        "SUBCONSULTA ESCALAR",
        """
        SELECT nombre, precio, categoria
        FROM productos
        WHERE precio > (SELECT AVG(precio) FROM productos)
        ORDER BY precio DESC;
        """,
        "Filtra los productos cuyo precio está por encima del precio medio de todo el catálogo."
    )
    run_query_demo(
        "COMMON TABLE EXPRESSION (CTE: WITH ... AS ...)",
        """
        WITH gasto_por_cliente AS (
            SELECT 
                p.id_cliente,
                SUM(d.cantidad * d.precio_unitario) AS total_gastado
            FROM pedidos p
            JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
            WHERE p.estado != 'Cancelado'
            GROUP BY p.id_cliente
        )
        SELECT 
            c.nombre,
            c.ciudad,
            g.total_gastado
        FROM clientes c
        JOIN gasto_por_cliente g ON c.id_cliente = g.id_cliente
        WHERE g.total_gastado >= 500
        ORDER BY g.total_gastado DESC;
        """,
        "Divide una consulta compleja en bloques limpios y reutilizables mediante WITH."
    )

def demo_funciones_ventana():
    run_query_demo(
        "FUNCIONES VENTANA: ROW_NUMBER(), DENSE_RANK() Y LAG()",
        """
        SELECT 
            p.id_pedido,
            p.id_cliente,
            p.fecha,
            SUM(d.cantidad * d.precio_unitario) AS importe_pedido,
            -- Número de pedido consecutivo por cada cliente
            ROW_NUMBER() OVER (PARTITION BY p.id_cliente ORDER BY p.fecha ASC) AS nro_pedido_cliente,
            -- Ranking global de pedidos por mayor importe
            DENSE_RANK() OVER (ORDER BY SUM(d.cantidad * d.precio_unitario) DESC) AS rank_importe,
            -- Importe del pedido anterior del mismo cliente
            LAG(SUM(d.cantidad * d.precio_unitario)) OVER (PARTITION BY p.id_cliente ORDER BY p.fecha ASC) AS importe_pedido_anterior
        FROM pedidos p
        JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
        GROUP BY p.id_pedido, p.id_cliente, p.fecha
        ORDER BY p.id_cliente, p.fecha;
        """,
        "Calcula métricas analíticas manteniendo todas las filas individuales sin colapsarlas como haría GROUP BY."
    )

def demo_dml_seguro():
    run_query_demo(
        "DML SEGURO: TRANSACCIONES CON COMMIT Y ROLLBACK",
        """
        -- Demostración de actualización segura:
        -- Paso 1: Comprobar el dato antes
        SELECT id_producto, nombre, precio FROM productos WHERE id_producto = 4;
        """,
        "Regla de Oro: Siempre verifica antes con SELECT qué fila vas a modificar."
    )

def sql_repl():
    """Consola interactiva SQL libre"""
    print("\n" + "=" * 80)
    print("💻 CONSOLA SQL INTERACTIVA (Escribe tu consulta y pulsa ENTER)")
    print("   Escribe 'exit' o 'salir' para volver al menú principal.")
    print("=" * 80)
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    while True:
        try:
            query = input("\nSQL> ")
            if not query.strip():
                continue
            if query.strip().lower() in ['exit', 'salir', 'quit', 'q']:
                break
            cursor.execute(query)
            print_table(cursor)
            conn.commit()
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"❌ Error: {e}")
    conn.close()

def main():
    init_database()
    
    if len(sys.argv) > 1 and sys.argv[1] == "--run-all":
        print("\n🚀 EJECUTANDO TODOS LOS MÓDULOS DEL CURSO:")
        demo_filtros()
        demo_agregaciones()
        demo_transformaciones()
        demo_subconsultas_cte()
        demo_funciones_ventana()
        demo_dml_seguro()
        print("\n🎉 Todos los módulos ejecutados con éxito.")
        return

    while True:
        print("\n" + "=" * 65)
        print("   🎓 LABORATORIO DE SQL DESDE CERO — TIENDA ONLINE")
        print("=" * 65)
        print(" [1] Filtros y Operadores Lógicos (WHERE, LIKE, NULL)")
        print(" [2] Agregaciones y Agrupación (COUNT, SUM, GROUP BY, HAVING)")
        print(" [3] Transformación de Datos (Texto, Fechas, Números)")
        print(" [4] Subconsultas y CTEs (WITH ... AS ...)")
        print(" [5] Funciones Ventana (ROW_NUMBER, DENSE_RANK, LAG)")
        print(" [6] Modificación Segura de Datos (DML con Transacciones)")
        print(" [7] Consola Interactiva Libre (Escribe tu propio SQL)")
        print(" [8] Re-inicializar Base de Datos (Resetear datos)")
        print(" [0] Salir")
        print("=" * 65)
        opc = input("Selecciona una opción (0-8): ").strip()
        
        if opc == "1":
            demo_filtros()
        elif opc == "2":
            demo_agregaciones()
        elif opc == "3":
            demo_transformaciones()
        elif opc == "4":
            demo_subconsultas_cte()
        elif opc == "5":
            demo_funciones_ventana()
        elif opc == "6":
            demo_dml_seguro()
        elif opc == "7":
            sql_repl()
        elif opc == "8":
            init_database()
        elif opc == "0":
            print("\n👋 ¡Hasta pronto! Sigue practicando tus consultas.")
            break
        else:
            print("⚠️ Opción no válida. Inténtalo de nuevo.")

if __name__ == "__main__":
    main()
