// ==============================================================================
// 🛡️ SOLUCIÓN 3: MANEJO DE ERRORES CON TRY...CATCH ANIDADOS (NIVEL 3 DE 5)
// ==============================================================================
// 📌 ¿QUÉ MEJORA RESPECTO A solution2.js?
// 1. Fin a los Bloqueos y Caídas: Protege el servidor con dos niveles de 'try...catch'.
// 2. Control de País Inexistente (Try Externo): Si el usuario busca 'Wakanda', result.rows
//    está vacío y data.country_code lanzaría TypeError. El catch lo atrapa y responde:
//    "Country name does not exist, try again."
// 3. Control de País Duplicado (Try Interno): Si el usuario repite un país, PostgreSQL
//    lanza la excepción de restricción UNIQUE (código 23505). El catch lo atrapa y responde:
//    "Country has already been added, try again."
// 4. Feedback en la Web: Envía la variable 'error' a index.ejs para mostrarla en el input.
//
// ⚠️ LIMITACIONES DE ESTA SOLUCIÓN (MOTIVACIÓN PARA SOLUTION 4):
// - Búsqueda Rígida e Inflexible: Usa 'WHERE country_name = $1'. Si el usuario escribe
//   en minúsculas ("spain") o el país tiene nombre oficial largo ("Tanzania" vs
//   "United Republic of Tanzania"), la búsqueda falla como inexistente.
// ==============================================================================

import express from "express";
import bodyParser from "body-parser";
import pg from "pg";
import "dotenv/config"; // Carga las variables de entorno desde el archivo local .env

const app = express();
const port = process.env.PORT || 3000;

// Conexión a la base de datos PostgreSQL mediante variables de entorno
const db = new pg.Client({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_DATABASE || "world",
  password: process.env.DB_PASSWORD, // Se lee desde .env sin exponer claves en el código
  port: process.env.DB_PORT || 5432,
});
db.connect();

// Middlewares
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"));

// Función auxiliar para leer la lista actual de países visitados
async function checkVisisted() {
  const result = await db.query("SELECT country_code FROM visited_countries");

  let countries = [];
  result.rows.forEach((country) => {
    countries.push(country.country_code);
  });
  return countries;
}

// GET /: Carga inicial de la página
app.get("/", async (req, res) => {
  const countries = await checkVisisted();
  res.render("index.ejs", { countries: countries, total: countries.length });
});

// POST /add: Inserción con gestión de errores
app.post("/add", async (req, res) => {
  const input = req.body["country"];

  // TRY EXTERNO: Gestiona la búsqueda del país en el diccionario "countries"
  try {
    const result = await db.query(
      "SELECT country_code FROM countries WHERE country_name = $1",
      [input]
    );

    // Si el país no existe, result.rows estará vacío y result.rows[0] será undefined.
    // Al intentar leer data.country_code se lanzará un TypeError: Cannot read properties of undefined,
    // saltando inmediatamente al CATCH EXTERNO.
    const data = result.rows[0];
    const countryCode = data.country_code;

    // TRY INTERNO: Gestiona la inserción en la tabla "visited_countries"
    try {
      await db.query(
        "INSERT INTO visited_countries (country_code) VALUES ($1)",
        [countryCode]
      );
      // Si la inserción tiene éxito, redirigimos limpiamente
      res.redirect("/");
    } catch (err) {
      // CATCH INTERNO: Ocurre si la clave UNIQUE de visited_countries se viola (error code 23505 en Postgres)
      // Significa que el país ya estaba registrado en la lista de visitas
      console.log(err);
      const countries = await checkVisisted();
      res.render("index.ejs", {
        countries: countries,
        total: countries.length,
        error: "Country has already been added, try again.",
      });
    }
  } catch (err) {
    // CATCH EXTERNO: Ocurre si el país ingresado no se encontró en la tabla "countries"
    console.log(err);
    const countries = await checkVisisted();
    res.render("index.ejs", {
      countries: countries,
      total: countries.length,
      error: "Country name does not exist, try again.",
    });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

