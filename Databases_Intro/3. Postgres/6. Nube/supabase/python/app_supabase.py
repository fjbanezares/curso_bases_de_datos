"""
==============================================================================
⚡ PYTHON + SUPABASE VIA CLIENTE OFICIAL (SDK)
==============================================================================
En este script utilizamos la librería oficial 'supabase' de Python para
consultar datos como objetos y diccionarios nativos.
==============================================================================
"""

import os
from dotenv import load_dotenv
from supabase import create_client, Client

# 1. Cargar variables del entorno
load_dotenv()

supabase_url = os.getenv("SUPABASE_URL")
supabase_key = os.getenv("SUPABASE_ANON_KEY")

if not supabase_url or not supabase_key:
    print("⚠️ Error: Faltan las credenciales SUPABASE_URL o SUPABASE_ANON_KEY en el archivo .env")
    exit(1)

# 2. Inicializar el cliente
supabase: Client = create_client(supabase_url, supabase_key)

def demo_supabase_python():
    print("🚀 Consultando Supabase desde Python con el SDK oficial...\n")

    # --------------------------------------------------------------------------
    # CONSULTA 1: Libros ordenados por precio descendente
    # --------------------------------------------------------------------------
    print("📚 Libros obtenidos mediante la API de Supabase:")
    response = (
        supabase.table("libros")
        .select("id, titulo, precio, genero")
        .order("precio", desc=True)
        .execute()
    )

    # 'response.data' contiene una lista de diccionarios en Python:
    libros = response.data
    for l in libros:
        print(f"  • {l['titulo']} - {l['genero']} ({l['precio']}€)")

    # --------------------------------------------------------------------------
    # CONSULTA 2: Filtrar autores activos
    # --------------------------------------------------------------------------
    print("\n👥 Autores activos:")
    autores_response = (
        supabase.table("autores")
        .select("nombre, pais")
        .eq("activo", True)
        .execute()
    )

    for a in autores_response.data:
        print(f"  • {a['nombre']} [{a['pais']}]")

if __name__ == "__main__":
    demo_supabase_python()
