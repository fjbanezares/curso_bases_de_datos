// ==============================================================================
// ➕ SOLUCIÓN 2: INSERCIÓN DE PAÍSES Y PATRÓN PRG (NIVEL 2 DE 5)
// ==============================================================================
// 📌 ¿QUÉ MEJORA RESPECTO A solution1.js?
// 1. Conexión Persistente: Elimina 'db.end()' para no cerrar la conexión tras la primera visita.
// 2. Modularización: Crea la función auxiliar 'checkVisisted()' para no duplicar código SQL.
// 3. Ruta POST /add: Permite recibir el formulario web del usuario mediante req.body.
// 4. Búsqueda en Catálogo: Traduce el nombre del país a su código ISO ('Spain' -> 'ES').
// 5. Inserción SQL: Guarda el código obtenido en la tabla 'visited_countries'.
// 6. Patrón PRG (Post-Redirect-Get): Redirige a GET / tras insertar, evitando reenvíos
//    accidentales si el usuario pulsa F5 (Refrescar).
//
// ⚠️ LIMITACIONES Y BUGS DE ESTA SOLUCIÓN (MOTIVACIÓN PARA SOLUTION 3):
// - BUG DE CARGA INFINITA: Si el usuario escribe un país que no existe (o escribe 'ES'
//   en vez de 'Spain'), la consulta devuelve 0 filas. Como no hay bloque 'else' ni
//   respuesta HTTP, ¡el navegador se queda colgado indefinidamente con la ruedita girando!
// - CAÍDA DEL SERVIDOR: Si se añade un país ya visitado, PostgreSQL lanza un error
//   de clave UNIQUE no capturado y la aplicación se rompe.
// ==============================================================================

import express from "express";
import bodyParser from "body-parser";
import pg from "pg";
import "dotenv/config"; // Carga las variables de entorno desde el archivo local .env

const app = express();
const port = process.env.PORT || 3000;

// Configuración de la conexión a la base de datos PostgreSQL "world"
// Credenciales protegidas mediante variables de entorno
const db = new pg.Client({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_DATABASE || "world",
  password: process.env.DB_PASSWORD, // Se lee desde .env
  port: process.env.DB_PORT || 5432,
});
db.connect();

// Middlewares
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"));

// FUNCIÓN AUXILIAR REUTILIZABLE:
// Centraliza la lógica de consultar la base de datos para obtener los países visitados.
// Evita repetir código tanto en GET / como en futuras rutas.
async function checkVisisted() {
  const result = await db.query("SELECT country_code FROM visited_countries");

  let countries = [];
  result.rows.forEach((country) => {
    countries.push(country.country_code);
  });
  return countries;
}

// GET /: Página principal
app.get("/", async (req, res) => {
  const countries = await checkVisisted();
  res.render("index.ejs", { countries: countries, total: countries.length });
});

// POST /add: Procesa el envío del formulario HTML para añadir un nuevo país
app.post("/add", async (req, res) => {
  // 1. Extraemos el texto escrito por el usuario en el <input name="country">
  const input = req.body["country"];

  // 2. Consulta parametrizada ($1): Buscamos el código ISO en la tabla maestra "countries".
  // Usar $1 previene ataques de Inyección SQL (SQL Injection).
  const result = await db.query(
    "SELECT country_code FROM countries WHERE country_name = $1",
    [input]
  );

  // 3. Verificamos si la consulta devolvió algún resultado
  if (result.rows.length !== 0) {
    const data = result.rows[0];
    const countryCode = data.country_code;

    // 4. Insertamos el código obtenido en la tabla de visitas
    await db.query("INSERT INTO visited_countries (country_code) VALUES ($1)", [
      countryCode,
    ]);

    // 5. Patrón PRG (Post-Redirect-Get):
    // Redirigimos al navegador a GET / para que recargue la lista actualizada.
    // Esto evita que si el usuario pulsa F5 se vuelva a enviar el formulario.
    res.redirect("/");
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

