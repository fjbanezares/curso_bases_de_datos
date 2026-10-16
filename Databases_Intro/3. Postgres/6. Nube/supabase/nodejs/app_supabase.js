// ==============================================================================
// ⚡ NODE.JS + SUPABASE VIA EL SDK OFICIAL (@supabase/supabase-js)
// ==============================================================================
// Además del driver SQL tradicional 'pg', Supabase ofrece una librería moderna (SDK)
// que te permite consultar tus tablas mediante métodos de JavaScript y objetos JSON,
// sin necesidad de escribir sentencias SQL en texto plano.
// ==============================================================================

// 1. Cargar variables de entorno del archivo .env
import dotenv from "dotenv";
dotenv.config();

// 2. Importar WebSocket y el creador de cliente oficial de Supabase
import WebSocket from "ws";
globalThis.WebSocket = WebSocket; // Polyfill para Node.js < 22
import { createClient } from "@supabase/supabase-js";

// 3. Obtener la URL del proyecto y la clave pública (Anon Key)
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error("⚠️ Error: Faltan las variables SUPABASE_URL o SUPABASE_ANON_KEY en el archivo .env");
  process.exit(1);
}

// 4. Inicializar el cliente de Supabase
// ¿Qué es el SDK? Es un intermediario que transforma tus llamadas de JavaScript
// en peticiones web seguras (API REST / PostgREST) hacia Supabase.
const supabase = createClient(supabaseUrl, supabaseKey);

async function demoSDK() {
  console.log("🚀 Iniciando consultas mediante el SDK de Supabase...\n");

  // ----------------------------------------------------------------------------
  // CONSULTA 1: Obtener todos los libros con precio menor a 20 euros
  // ----------------------------------------------------------------------------
  // En lugar de "SELECT * FROM libros WHERE precio < 20", usamos métodos encadenados:
  //   .from('libros') -> tabla
  //   .select('*')    -> columnas que queremos
  //   .lt('precio', 20) -> 'lt' significa 'Less Than' (menor que)
  console.log("📚 Libros con precio menor a 20€:");
  const { data: librosBaratos, error: errLibros } = await supabase
    .from("libros")
    .select("id, titulo, precio, genero")
    .lt("precio", 20)
    .order("precio", { ascending: false });

  if (errLibros) {
    console.error("❌ Error al consultar libros:", errLibros.message);
  } else {
    console.table(librosBaratos);
  }

  // ----------------------------------------------------------------------------
  // CONSULTA 2: Consultar libros trayendo datos de la tabla relacionada 'autores'
  // ----------------------------------------------------------------------------
  // Supabase detecta automáticamente las claves foráneas (Foreign Keys) en PostgreSQL.
  // Con la sintaxis 'autores ( nombre, pais )', ¡hace el JOIN por ti bajo el capó!
  console.log("\n🔗 Libros con datos del autor asociado (JOIN automático via SDK):");
  const { data: librosConAutor, error: errJoin } = await supabase
    .from("libros")
    .select(`
      titulo,
      genero,
      precio,
      autores (
        nombre,
        pais
      )
    `)
    .limit(3);

  if (errJoin) {
    console.error("❌ Error en la consulta con relación:", errJoin.message);
  } else {
    console.log(JSON.stringify(librosConAutor, null, 2));
  }
}

demoSDK();
