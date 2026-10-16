// ==============================================================================
// 🗺️ SOLUCIÓN 1: LECTURA BÁSICA Y RENDERIZADO INICIAL (NIVEL 1 DE 5)
// ==============================================================================
// 📌 ¿QUÉ AÑADE RESPECTO A index.js?
// 1. Conexión a PostgreSQL: Importa 'pg' e inicializa 'new pg.Client()' usando .env.
// 2. Consulta de Lectura: Ejecuta 'SELECT country_code FROM visited_countries'.
// 3. Transformación de Datos: Convierte el array de objetos de Postgres
//    [ { country_code: 'FR' }, ... ] en un array simple de texto ['FR', 'GB', 'US'].
// 4. Renderizado EJS: Envía los códigos y el contador total a la plantilla.
//
// ⚠️ LIMITACIONES DE ESTA SOLUCIÓN (MOTIVACIÓN PARA SOLUTION 2):
// - Es de SOLO LECTURA: No existe ninguna ruta POST para que el usuario añada países.
// - Cierre prematuro de conexión: La línea 'db.end()' cierra el socket TCP tras la
//   primera visita. Si el usuario recarga la página, el servidor falla.
// ==============================================================================

import express from "express";
import bodyParser from "body-parser";
import pg from "pg"; // Driver oficial de PostgreSQL para Node.js
import "dotenv/config"; // Carga las variables de entorno desde el archivo local .env

const app = express();
const port = process.env.PORT || 3000;

// Configuración de la conexión a PostgreSQL usando variables de entorno
// ¡Buena práctica de seguridad! La contraseña nunca se escribe en el código fuente.
const db = new pg.Client({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_DATABASE || "world",
  password: process.env.DB_PASSWORD, // Se lee de forma segura desde el archivo .env
  port: process.env.DB_PORT || 5432,
});
db.connect(); // Abre el socket de conexión TCP con PostgreSQL

// Middlewares
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"));

// GET home page: Obtiene los países visitados y renderiza el mapa
app.get("/", async (req, res) => {
  // 1. Ejecutamos la consulta SQL para leer los códigos de 2 letras guardados
  const result = await db.query("SELECT country_code FROM visited_countries");

  // 2. Transformamos el resultado:
  // result.rows devuelve un array de objetos: [ { country_code: 'FR' }, { country_code: 'GB' }, ... ]
  // Pero el frontend necesita un array plano de strings: ['FR', 'GB', 'US']
  let countries = [];
  result.rows.forEach((country) => {
    countries.push(country.country_code);
  });
  console.log(result.rows);

  // 3. Renderizamos index.ejs pasando la lista de códigos y el contador total
  res.render("index.ejs", { countries: countries, total: countries.length });

  // Nota didáctica: db.end() cierra la conexión con la base de datos.
  // En una app real no se cierra dentro de una ruta porque la siguiente petición fallaría;
  // por eso en solution2, 3 y 4 verás que se elimina esta línea.
  db.end();
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

