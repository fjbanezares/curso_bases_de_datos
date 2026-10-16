// ==============================================================================
// 🏁 8.2 POSTGRES READ: RETO DE BANDERAS (FLAGS QUIZ) - CÓDIGO BASE DEL ALUMNO
// ==============================================================================
// Este archivo es la plantilla inicial para el ejercicio del quiz de banderas.
// En este ejercicio aprenderás a aplicar lo aprendido en el quiz de capitales, pero
// ahora conectándote a la tabla 'flags' de PostgreSQL.
// ==============================================================================

// ------------------------------------------------------------------------------
// 1. IMPORTACIÓN DE LIBRERÍAS
// ------------------------------------------------------------------------------
// ¿Qué es una librería o módulo?
// Es código ya escrito por la comunidad que importamos para no crear herramientas desde cero.
// La palabra clave 'import' nos permite traer paquetes instalados previamente mediante 'npm'.

// 'express': Framework que gestiona el servidor web, rutas y respuestas HTTP.
import express from "express";

// 'body-parser': Middleware para interceptar y procesar los formularios que envía el usuario.
import bodyParser from "body-parser";

// 💡 PISTA DIDÁCTICA PARA TU PRÁCTICA:
// Aquí deberás importar la librería de PostgreSQL para poder conectar con la base de datos:
// import pg from "pg";

// ------------------------------------------------------------------------------
// 2. CONFIGURACIÓN DEL SERVIDOR WEB
// ------------------------------------------------------------------------------
// 'const' declara identificadores constantes (que no cambian de valor ni se pueden reasignar).
// 'express()' ejecuta la función constructora que inicializa nuestro servidor web.
const app = express();

// 'port' define el puerto de red en tu máquina local ('localhost') por donde escuchará el servidor.
const port = 3000;

// Variable de tipo número entero para contabilizar las respuestas correctas acumuladas.
let totalCorrect = 0;

// ------------------------------------------------------------------------------
// 3. MIDDLEWARES (PROCESAMIENTO PREVIO DE PETICIONES)
// ------------------------------------------------------------------------------
// ¿Qué es un Middleware?
// Una función intermedia que se ejecuta antes de que la petición llegue a la ruta final.
// Se registran mediante el método 'app.use()'.

// 'bodyParser.urlencoded': Lee los campos del formulario HTML y los guarda en 'req.body'.
app.use(bodyParser.urlencoded({ extended: true }));

// 'express.static': Permite al navegador descargar directamente archivos estáticos (CSS, imágenes)
// desde la carpeta 'public'.
app.use(express.static("public"));

// ¿Qué es un Objeto en JavaScript '{}'?
// Es una colección de propiedades organizadas en pares de "clave: valor".
// 'currentQuestion' almacenará los datos de la pregunta actual (país y bandera).
let currentQuestion = {};

// 💡 PISTA DIDÁCTICA PARA TU PRÁCTICA:
// Aquí deberás:
// 1. Configurar el cliente de PostgreSQL con 'new pg.Client({ ... })'.
// 2. Conectarte con 'db.connect()'.
// 3. Declarar 'let quiz = [];' y ejecutar 'db.query("SELECT * FROM flags", ...)' para cargar las banderas.

// ------------------------------------------------------------------------------
// 4. RUTAS DEL SERVIDOR
// ------------------------------------------------------------------------------

// RUTA GET "/" (Página principal del juego)
// Se activa cuando el usuario entra en 'http://localhost:3000/' con su navegador.
//   - 'req' (Request): Contiene los datos recibidos de la petición del cliente.
//   - 'res' (Response): Ofrece métodos para responder al cliente.
app.get("/", (req, res) => {
  // Reiniciamos la puntuación a 0 al comenzar la partida.
  totalCorrect = 0;

  // Llamamos a la función auxiliar para escoger una pregunta al azar.
  nextQuestion();

  // 'console.log' imprime la pregunta en el terminal para que podamos verla mientras programamos.
  console.log(currentQuestion);

  // 'res.render()' combina la plantilla 'views/index.ejs' con los datos del objeto '{ question: currentQuestion }'
  // y le devuelve la página web resultante al navegador del usuario.
  res.render("index.ejs", { question: currentQuestion });
});

// RUTA POST "/submit" (Recepción de la respuesta escrita por el usuario)
// Se activa cuando el usuario pulsa el botón para enviar el formulario con su respuesta.
app.post("/submit", (req, res) => {
  // ¿Qué hace 'req.body.answer'?
  // Extrae el valor que el usuario escribió en el campo con <input name="answer">.
  //
  // ¿Qué es el método '.trim()'?
  // Es un método propio de las cadenas de texto (Strings) en JavaScript.
  // Quita los espacios en blanco sobrantes al inicio y al final del texto para evitar errores
  // si el usuario pulsó la barra espaciadora antes o después de escribir.
  let answer = req.body.answer.trim();

  // Variable de tipo booleano (Boolean: solo 'true' o 'false') para indicar si la respuesta fue acertada.
  let isCorrect = false;

  // ¿Qué es el método '.toLowerCase()'?
  // Convierte todo el texto a letras minúsculas.
  // Al aplicar '.toLowerCase()' en ambos lados de la comparación, nos aseguramos de que
  // "España", "españa" y "ESPAÑA" sean reconocidos exactamente igual.
  //
  // ¿Qué es el operador '==='?
  // Comprueba si dos valores son estrictamente iguales en contenido y tipo de dato.
  //
  // 💡 NOTA: En la tabla 'flags', el país se guarda en la columna 'name' (a diferencia de 'capitals' donde era 'capital').
  // Por eso aquí compararemos con 'currentQuestion.name'.
  if (currentQuestion.name && currentQuestion.name.toLowerCase() === answer.toLowerCase()) {
    // '++': Operador de incremento que suma 1 a 'totalCorrect'.
    totalCorrect++;
    console.log(totalCorrect);
    isCorrect = true;
  }

  // Elegimos una nueva pregunta para el siguiente turno.
  nextQuestion();

  // Renderizamos de nuevo la plantilla 'index.ejs' enviando la nueva pregunta,
  // el indicador de acierto ('wasCorrect') y la puntuación actual ('totalScore').
  res.render("index.ejs", {
    question: currentQuestion,
    wasCorrect: isCorrect,
    totalScore: totalCorrect,
  });
});

// ------------------------------------------------------------------------------
// 5. FUNCIÓN AUXILIAR: SELECCIÓN ALEATORIA DE PREGUNTAS
// ------------------------------------------------------------------------------
// ¿Qué es una Función?
// Un bloque organizado de código que realiza una acción concreta y que podemos invocar con 'nextQuestion()'.
function nextQuestion() {
  // Fórmula para elegir un elemento al azar de un array 'quiz':
  // 1. 'quiz.length': Tamaño total del array.
  // 2. 'Math.random()': Devuelve un número decimal aleatorio entre 0 y casi 1 (ej: 0.45).
  // 3. 'Math.random() * quiz.length': Escala el número aleatorio a la longitud del array.
  // 4. 'Math.floor(...)': Redondea hacia abajo al entero más cercano, dando un índice válido (0, 1, 2...).
  // 5. 'quiz[...]': Obtiene el elemento ubicado en esa posición del array.
  if (typeof quiz !== "undefined" && quiz.length > 0) {
    const randomCountry = quiz[Math.floor(Math.random() * quiz.length)];
    currentQuestion = randomCountry;
  }
}

// ------------------------------------------------------------------------------
// 6. ENCENDIDO DEL SERVIDOR WEB
// ------------------------------------------------------------------------------
// El método '.listen()' arranca el servidor para que empiece a escuchar peticiones
// en el puerto 3000 de forma continua.
app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});
