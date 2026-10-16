// ==============================================================================
// 🟢 NODE.JS + POSTGRESQL EN LA NUBE (SUPABASE) VIA EL DRIVER NATIVO 'pg'
// ==============================================================================
// En este archivo nos conectamos a la base de datos PostgreSQL alojada en Supabase
// exactamente igual que lo hacíamos en local, pero usando conexión cifrada SSL
// y variables de entorno para proteger nuestras contraseñas.
// ==============================================================================

// ------------------------------------------------------------------------------
// 1. IMPORTACIÓN DE LIBRERÍAS
// ------------------------------------------------------------------------------
// 'dotenv': Lee las variables secretas escritas en el archivo '.env' y las carga
// automáticamente en el objeto global 'process.env' de Node.js.
import dotenv from "dotenv";
dotenv.config();

// 'pg': El conector estándar entre Node.js y PostgreSQL que ya conocemos.
import pg from "pg";

// ------------------------------------------------------------------------------
// 2. CONFIGURACIÓN DEL CLIENTE CON CIFRADO SSL OBLIGATORIO
// ------------------------------------------------------------------------------
// ¿Por qué necesitamos 'ssl'?
// Cuando nos conectábamos a 'localhost', el tráfico viajaba solo dentro de tu ordenador.
// Pero Supabase está en la NUBE (un servidor en Frankfurt, Virginia, etc.).
// Para que nadie pueda interceptar tus datos ni tu contraseña mientras viajan por
// los cables de Internet, PostgreSQL exige que la conexión esté cifrada con SSL/TLS.
//
// 💡 PRIORIDAD DE CONEXIÓN:
// 1. Si existe 'DATABASE_SES_URL' (modo Session Pooler de Supabase) o 'DATABASE_URL', la usamos directamente.
// 2. Si no, usamos las variables individuales (DB_HOST, DB_USER, etc.).
const connectionUrl = process.env.DATABASE_SES_URL || process.env.DATABASE_URL;

let clientConfig;

if (connectionUrl) {
  console.log("📡 Usando URL de conexión configurada en .env");
  clientConfig = {
    connectionString: connectionUrl,
    ssl: { rejectUnauthorized: false },
  };
} else if (process.env.DB_HOST && process.env.DB_PASSWORD) {
  console.log("📡 Usando variables desglosadas (DB_HOST, DB_USER...)");
  clientConfig = {
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || "5432"),
    user: process.env.DB_USER || "postgres",
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || "postgres",
    ssl: { rejectUnauthorized: false },
  };
} else {
  console.error("❌ No se encontró ninguna configuración de conexión en .env");
  process.exit(1);
}

const client = new pg.Client(clientConfig);

// ------------------------------------------------------------------------------
// 3. FUNCIÓN PRINCIPAL ASÍNCRONA (EJECUCIÓN DE CONSULTAS)
// ------------------------------------------------------------------------------
// ¿Qué es 'async / await'?
// Conectarse a un servidor remoto en la nube y pedirle datos toma tiempo (unos cuantos milisegundos).
// En lugar de bloquear todo el programa, declaramos una función 'async' que usa 'await'
// para pausar ordenadamente el flujo hasta que el servidor remoto responda.
async function main() {
  try {
    console.log("⏳ Conectando con PostgreSQL en Supabase...");
    // Abrimos el canal de comunicación seguro
    await client.connect();
    console.log("✅ ¡Conexión establecida con éxito en la nube!\n");

    // --------------------------------------------------------------------------
    // CONSULTA 1: Listar todos los autores
    // --------------------------------------------------------------------------
    console.log("📋 CONSULTA 1: Lista de Autores:");
    const resAutores = await client.query(
      "SELECT id, nombre, pais FROM autores ORDER BY id ASC;"
    );

    // 'console.table()' imprime arrays de objetos en una tabla visual limpia en el terminal:
    console.table(resAutores.rows);

    // --------------------------------------------------------------------------
    // CONSULTA 2: Libros con su autor usando un JOIN
    // --------------------------------------------------------------------------
    console.log("\n📖 CONSULTA 2: Libros con información de su autor (JOIN):");
    const consultaSQL = `
      SELECT 
        l.id,
        l.titulo,
        l.genero,
        l.precio,
        a.nombre AS autor
      FROM libros l
      JOIN autores a ON l.autor_id = a.id
      ORDER BY l.precio DESC;
    `;

    const resLibros = await client.query(consultaSQL);
    console.table(resLibros.rows);

    // --------------------------------------------------------------------------
    // CONSULTA 3: Inserción de un nuevo libro (Parámetros seguros)
    // --------------------------------------------------------------------------
    console.log("\n✍️ CONSULTA 3: Insertando un nuevo libro con parámetros seguros ($1, $2...):");
    const nuevoLibro = {
      autor_id: 1, // Gabriel García Márquez
      titulo: "Relato de un náufrago",
      genero: "Reportaje novelado",
      precio: 11.5,
      paginas: 176,
    };

    const insertSQL = `
      INSERT INTO libros (autor_id, titulo, genero, precio, paginas)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, titulo, precio;
    `;

    // Pasamos los valores en un array para evitar ataques de Inyección SQL:
    const resInsert = await client.query(insertSQL, [
      nuevoLibro.autor_id,
      nuevoLibro.titulo,
      nuevoLibro.genero,
      nuevoLibro.precio,
      nuevoLibro.paginas,
    ]);

    console.log("🎉 ¡Libro insertado correctamente en Supabase!");
    console.log("Datos creados:", resInsert.rows[0]);
  } catch (error) {
    // ¿Qué es 'try / catch'?
    // Si la contraseña es incorrecta, no hay conexión a internet o la tabla no existe,
    // el código entra aquí sin colgar abruptamente el programa:
    console.error("❌ Ocurrió un error al consultar Supabase:", error.message);
    if (error.code === "ENOTFOUND" || error.message.includes("ENOTFOUND")) {
      console.error("\n💡 CAUSA DEL ERROR 'ENOTFOUND':");
      console.error(
        "1. El host directo 'db.[ref].supabase.co' utiliza únicamente IPv6. Si tu conexión a Internet o router utiliza IPv4, tu ordenador no podrá resolverlo."
      );
      console.error(
        "2. SOLUCIÓN: En Supabase ve a 'Project Settings' -> 'Database' -> 'Connection string' y cambia el modo a 'Transaction' o 'Session' (Connection Pooler)."
      );
      console.error(
        "   El host del Pooler (ej: aws-0-eu-central-1.pooler.supabase.com en el puerto 6543) tiene soporte completo IPv4."
      );
    }
  } finally {
    // El bloque 'finally' se ejecuta SIEMPRE al final, haya ido bien o mal.
    // Es una buena práctica cerrar la conexión para no dejar recursos abiertos en el servidor:
    await client.end();
    console.log("\n🔒 Conexión cerrada de forma limpia.");
  }
}

// Ejecutamos la función principal
main();
