// ==============================================================================
// 🗑️ SOLUCIÓN 5: OPERACIÓN CRUD COMPLETA — BORRADO CON 'DELETE' (NIVEL 5 DE 5)
// ==============================================================================
// 📌 ¿QUÉ MEJORA RESPECTO A solution4.js?
// 1. Operación DELETE en SQL: Añade la capacidad de eliminar países individuales de
//    la tabla 'visited_countries' usando:
//    DELETE FROM visited_countries WHERE country_code = $1;
// 2. Ruta POST /delete: Procesa la petición de borrado enviada desde el formulario.
// 3. Búsqueda Flexible para Borrar: Permite al usuario indicar el país a borrar tanto
//    por su nombre (ej: "Spain", "spain", "United Kingdom") como por su código ISO (ej: "ES", "GB").
// 4. Verificación de Filas Afectadas (result.rowCount):
//    - Si rowCount > 0: El país estaba visitado y se ha borrado con éxito -> res.redirect("/").
//    - Si rowCount === 0: El país no figuraba en la lista de visitas -> se informa al usuario.
// 5. Soporte en la Vista: Envía 'allowDelete: true' a index.ejs para habilitar el
//    formulario de borrado visual en color rojo.
// ==============================================================================

import express from "express";
import bodyParser from "body-parser";
import pg from "pg";
import "dotenv/config"; // Carga las credenciales seguras desde .env

const app = express();
const port = process.env.PORT || 3000;

// Conexión a la base de datos PostgreSQL protegida con variables de entorno
const db = new pg.Client({
  user: process.env.DB_USER || "postgres",
  host: process.env.DB_HOST || "localhost",
  database: process.env.DB_DATABASE || "world",
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT || 5432,
});
db.connect();

// Middlewares
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static("public"));

// Función auxiliar: Consulta los países visitados en PostgreSQL
async function checkVisited() {
  const result = await db.query("SELECT country_code FROM visited_countries");
  let countries = [];
  result.rows.forEach((country) => {
    countries.push(country.country_code);
  });
  return countries;
}

// -----------------------------------------------------------------------------
// 1. GET /: Página de Inicio
// -----------------------------------------------------------------------------
app.get("/", async (req, res) => {
  const countries = await checkVisited();
  res.render("index.ejs", {
    countries: countries,
    total: countries.length,
    allowDelete: true, // Habilita el formulario de borrado en la vista
  });
});

// -----------------------------------------------------------------------------
// 2. POST /add: Añadir un Nuevo País Visitado (Operación INSERT)
// -----------------------------------------------------------------------------
app.post("/add", async (req, res) => {
  const input = req.body["country"];

  if (!input || input.trim() === "") {
    const countries = await checkVisited();
    return res.render("index.ejs", {
      countries: countries,
      total: countries.length,
      allowDelete: true,
      error: "Please enter a country name.",
    });
  }

  try {
    // Búsqueda flexible: Busca por nombre parcial o código ISO exacto
    const result = await db.query(
      "SELECT country_code FROM countries WHERE LOWER(country_name) LIKE '%' || $1 || '%' OR UPPER(country_code) = $2;",
      [input.toLowerCase().trim(), input.toUpperCase().trim()]
    );

    const data = result.rows[0];
    const countryCode = data.country_code;

    try {
      // Inserción en la tabla de visitas
      await db.query(
        "INSERT INTO visited_countries (country_code) VALUES ($1);",
        [countryCode]
      );
      res.redirect("/");
    } catch (err) {
      // Error: Clave duplicada (restricción UNIQUE)
      const countries = await checkVisited();
      res.render("index.ejs", {
        countries: countries,
        total: countries.length,
        allowDelete: true,
        error: "Country has already been added, try again.",
      });
    }
  } catch (err) {
    // Error: País no encontrado en el catálogo
    const countries = await checkVisited();
    res.render("index.ejs", {
      countries: countries,
      total: countries.length,
      allowDelete: true,
      error: "Country name does not exist, try again.",
    });
  }
});

// -----------------------------------------------------------------------------
// 3. POST /delete: Eliminar un País Visitado (Operación DELETE)
// -----------------------------------------------------------------------------
app.post("/delete", async (req, res) => {
  const input = req.body["country"];

  if (!input || input.trim() === "") {
    const countries = await checkVisited();
    return res.render("index.ejs", {
      countries: countries,
      total: countries.length,
      allowDelete: true,
      error: "Please enter a country to delete.",
    });
  }

  try {
    // Paso A: Buscamos qué código ISO le corresponde al texto que escribió el usuario
    const searchResult = await db.query(
      "SELECT country_code FROM countries WHERE LOWER(country_name) LIKE '%' || $1 || '%' OR UPPER(country_code) = $2;",
      [input.toLowerCase().trim(), input.toUpperCase().trim()]
    );

    if (searchResult.rows.length === 0) {
      // El país ni siquiera existe en el catálogo mundial
      const countries = await checkVisited();
      return res.render("index.ejs", {
        countries: countries,
        total: countries.length,
        allowDelete: true,
        error: "Country name does not exist, cannot delete.",
      });
    }

    const countryCode = searchResult.rows[0].country_code;

    // Paso B: Ejecutamos la sentencia SQL DELETE en visited_countries
    const deleteResult = await db.query(
      "DELETE FROM visited_countries WHERE country_code = $1;",
      [countryCode]
    );

    // Paso C: Verificamos cuántas filas se eliminaron con deleteResult.rowCount
    if (deleteResult.rowCount === 0) {
      // El país existe en el mundo, pero no estaba en la lista de visitados
      const countries = await checkVisited();
      return res.render("index.ejs", {
        countries: countries,
        total: countries.length,
        allowDelete: true,
        error: "Country is not in your visited list, cannot delete.",
      });
    }

    // Éxito: Se eliminó el país de la base de datos
    console.log(`🗑️ País eliminado con éxito: ${countryCode}`);
    res.redirect("/");

  } catch (err) {
    console.error("Error al eliminar país:", err);
    const countries = await checkVisited();
    res.render("index.ejs", {
      countries: countries,
      total: countries.length,
      allowDelete: true,
      error: "An error occurred while deleting the country.",
    });
  }
});

// Arrancar el servidor
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port} (Solution 5 con DELETE habilitado)`);
});
