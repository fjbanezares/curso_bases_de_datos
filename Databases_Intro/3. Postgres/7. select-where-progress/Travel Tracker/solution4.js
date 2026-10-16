// ==============================================================================
// 🔍 SOLUCIÓN 4: BÚSQUEDA FLEXIBLE (FUZZY SEARCH) CON LIKE Y LOWER (NIVEL 4 DE 5)
// ==============================================================================
// 📌 ¿QUÉ MEJORA RESPECTO A solution3.js?
// 1. Búsqueda Insensible a Mayúsculas: Convierte ambos lados a minúsculas usando
//    LOWER(country_name) en SQL e input.toLowerCase() en JS.
// 2. Coincidencias Parciales: Usa el operador LIKE con comodines '%' a ambos lados.
//    Permite encontrar países con nombres oficiales largos (ej. teclear 'Tanzania'
//    encuentra con éxito 'United Republic of Tanzania').
// 3. Concatenación Nativa SQL: Usa el operador '||' de PostgreSQL ('%' || $1 || '%')
//    respetando las consultas parametrizadas contra SQL Injection.
//
// ⚠️ LIMITACIONES DE ESTA SOLUCIÓN (MOTIVACIÓN PARA SOLUTION 5):
// - Solo permite AÑADIR (Create): Si el usuario marca un país por error o desea
//   desmarcarlo de su historial, la aplicación no tiene ninguna opción de BORRADO (Delete).
// ==============================================================================

import express from "express";
import bodyParser from "body-parser";
import pg from "pg";
import "dotenv/config"; // Carga las variables de entorno desde el archivo local .env

const app = express();
const port = process.env.PORT || 3000;

// Conexión a la base de datos PostgreSQL protegida con variables de entorno
const db = new pg.Client({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_DATABASE || "world",
  password: process.env.DB_PASSWORD, // Se lee desde .env (nunca hardcodeada en el código)
  port: process.env.DB_PORT || 5432,
});
db.connect();

// Middlewares
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"));

// Función auxiliar para obtener la lista de países visitados
async function checkVisisted() {
  const result = await db.query("SELECT country_code FROM visited_countries");
  let countries = [];
  result.rows.forEach((country) => {
    countries.push(country.country_code);
  });
  return countries;
}

// GET /: Carga de la página inicial
app.get("/", async (req, res) => {
  const countries = await checkVisisted();
  res.render("index.ejs", { countries: countries, total: countries.length });
});

// POST /add: Búsqueda difusa e inserción
app.post("/add", async (req, res) => {
  const input = req.body["country"];

  try {
    // CLAVE DE LA MEJORA EN SQL:
    // 1. LOWER(country_name): Convierte a minúsculas el nombre guardado en la BD para comparar sin distinción de mayúsculas.
    // 2. input.toLowerCase(): Convierte la entrada del usuario a minúsculas en JavaScript.
    // 3. '%' || $1 || '%': Concatena los comodines de SQL (%) con el parámetro $1 usando el operador de unión de cadenas de PostgreSQL (||).
    // Esto equivale a buscar cualquier país cuyo nombre contenga el texto ingresado.
    const result = await db.query(
      "SELECT country_code FROM countries WHERE LOWER(country_name) LIKE '%' || $1 || '%';",
      [input.toLowerCase()]
    );

    const data = result.rows[0];
    const countryCode = data.country_code;

    try {
      await db.query(
        "INSERT INTO visited_countries (country_code) VALUES ($1)",
        [countryCode]
      );
      res.redirect("/");
    } catch (err) {
      console.log(err);
      const countries = await checkVisisted();
      res.render("index.ejs", {
        countries: countries,
        total: countries.length,
        error: "Country has already been added, try again.",
      });
    }
  } catch (err) {
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

