// ==============================================================================
// PLANTILLA INICIAL: TRAVEL TRACKER (index.js)
// Este archivo sirve como esqueleto base para que el estudiante implemente
// la lógica de conexión a PostgreSQL y el renderizado del mapa.
// ==============================================================================

// 1. Importación de módulos esenciales
import express from "express";        // Framework web para Node.js
import bodyParser from "body-parser";  // Middleware para procesar datos de formularios HTML

// 2. Inicialización de la aplicación Express y puerto de escucha
const app = express();
const port = 3000;

// 3. Configuración de Middlewares
// - urlencoded: permite leer los datos enviados desde formularios HTML (req.body)
app.use(bodyParser.urlencoded({ extended: true }));
// - static: sirve archivos públicos (hojas de estilo CSS, imágenes, etc.) desde la carpeta "public"
app.use(express.static("public"));

// 4. Ruta principal (GET /)
// Aquí se debe consultar la base de datos PostgreSQL para obtener los países visitados
// y renderizar la plantilla "index.ejs" enviando los datos obtenidos.
app.get("/", async (req, res) => {
  // Write your code here.
});

// 5. Arranque del servidor HTTP
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

