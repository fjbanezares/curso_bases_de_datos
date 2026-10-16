// ==============================================================================
// 🏁 8.2 POSTGRES READ: RETO DE BANDERAS (FLAGS QUIZ) - SOLUCIÓN COMPLETA
// ==============================================================================
// En este ejercicio conectamos la aplicación web con la tabla 'flags' en PostgreSQL.
// A diferencia del quiz de capitales, aquí la base de datos almacena banderas y nombres de países.
// ==============================================================================

// ------------------------------------------------------------------------------
// 1. IMPORTACIÓN DE MÓDULOS Y LIBRERÍAS
// ------------------------------------------------------------------------------
// ¿Qué es una librería o módulo?
// Es código empaquetado y listo para usar que otros programadores han creado para facilitarnos la vida.
// En JavaScript moderno usamos 'import ... from "..."' para traer esas herramientas a nuestro archivo.

// 'express': Framework para Node.js que nos ayuda a crear el servidor web y responder a peticiones HTTP.
import express from "express";

// 'body-parser': Librería auxiliar (middleware) para leer y procesar la información enviada
// por formularios HTML a través de peticiones HTTP con método POST.
import bodyParser from "body-parser";

// 'pg' (node-postgres): Conector oficial entre Node.js y el motor de base de datos PostgreSQL.
// Nos proporciona las herramientas necesarias para enviar sentencias SQL como 'SELECT * FROM flags'.
import pg from "pg";

// ------------------------------------------------------------------------------
// 2. CONFIGURACIÓN DEL CLIENTE DE BASE DE DATOS (POSTGRESQL)
// ------------------------------------------------------------------------------
// ¿Qué es 'const'?
// Una palabra reservada para declarar variables constantes (cuyo identificador no se puede reasignar).
//
// ¿Qué es un Objeto '{}'?
// Una estructura que guarda datos mediante pares de "clave: valor" (llamados propiedades).
//
// ¿Qué es 'new'?
// Es el operador que crea una nueva instancia (un nuevo objeto) a partir de una clase o constructor.
// Aquí creamos una conexión con los parámetros de nuestro servidor local de PostgreSQL:
const db = new pg.Client({
  user: "postgres",       // Nombre de usuario de la base de datos
  host: "localhost",      // Dirección donde corre la base de datos ('localhost' es tu propia máquina)
  database: "world",      // Nombre de la base de datos relacional
  password: "XXXX",  // Contraseña de acceso a PostgreSQL
  port: 5432,             // Puerto de red por defecto en el que escucha PostgreSQL
});

// Inicializamos el servidor web llamando a la función constructora 'express()'.
const app = express();

// Puerto en el que el servidor web escuchará las visitas de los usuarios en su navegador web.
const port = 3000;

// ¿Qué es un Método?
// Una función que está asociada a un objeto. Se invoca como: objeto.metodo().
// '.connect()' abre la conexión física de red con el motor de PostgreSQL.
db.connect();

// ------------------------------------------------------------------------------
// 3. CONSULTA SQL PARA CARGAR LAS BANDERAS EN MEMORIA
// ------------------------------------------------------------------------------
// ¿Qué es un Array '[]'?
// Una lista o colección ordenada de elementos. Cada elemento tiene una posición numérica (índice),
// empezando por el índice 0. Aquí creamos un array vacío donde guardaremos todas las banderas.
let quiz = [];

// ¿Qué hace 'db.query()'?
// Envía una sentencia SQL directamente a la base de datos PostgreSQL.
//   1. Consulta SQL: "SELECT * FROM flags" (obtiene todas las columnas y filas de la tabla 'flags').
//   2. Función Callback '(err, res) => { ... }': Función que se ejecutará en cuanto PostgreSQL responda.
//
// ¿Qué es un Callback?
// Una función que pasamos como argumento para que se ejecute de forma diferida en el futuro
// cuando una tarea asíncrona (como consultar un disco o una red) haya terminado.
//
// Parámetros de la función callback:
//   - 'err' (error): Si la consulta falla, contendrá los detalles del error. Si fue un éxito, es nulo.
//   - 'res' (resultado): Objeto que contiene los datos devueltos por PostgreSQL.
db.query("SELECT * FROM flags", (err, res) => {
  if (err) {
    // Si hubo un fallo, lo imprimimos con 'console.error' y mostramos el historial de la traza ('err.stack').
    console.error("Error executing query", err.stack);
  } else {
    // ¿Qué es 'res.rows'?
    // Es un Array de JavaScript que contiene cada fila devuelta por la tabla 'flags'.
    // Cada fila es un Objeto con las columnas de la tabla (ej: { id: 1, name: "Spain", flag: "ES" }).
    // Guardamos todas las filas en nuestra variable 'quiz':
    quiz = res.rows;
  }
  // '.end()' cierra la conexión con la base de datos para no dejar procesos abiertos innecesariamente.
  db.end();
});

// Variable numérica entera para llevar el recuento de aciertos consecutivos del jugador.
let totalCorrect = 0;

// ------------------------------------------------------------------------------
// 4. MIDDLEWARES (FUNCIONES DE PASO PREVIO)
// ------------------------------------------------------------------------------
// ¿Qué es un Middleware?
// Una función intermedia por la que viaja cualquier petición antes de ser atendida por una ruta.

// Middleware 1: Habilita la lectura de formularios HTML enviados mediante POST.
// Almacena los datos introducidos por el usuario dentro del objeto 'req.body'.
app.use(bodyParser.urlencoded({ extended: true }));

// Middleware 2: Permite servir de forma directa archivos estáticos (imágenes, CSS, etc.)
// ubicados en la carpeta local 'public'.
app.use(express.static("public"));

// Objeto que almacenará la bandera y país que se están preguntando actualmente al usuario.
let currentQuestion = {};

// ------------------------------------------------------------------------------
// 5. RUTAS Y CONTROLADORES HTTP
// ------------------------------------------------------------------------------

// RUTA GET "/" (Carga inicial del juego en el navegador)
// ¿Qué es GET? Petición que hace el navegador cuando el usuario solicita una URL para verla.
//
// 'req' (Request / Petición): Datos que llegan del cliente hacia el servidor.
// 'res' (Response / Respuesta): Métodos para enviar la contestación del servidor al cliente.
//
// 'async': Indica que la función contiene operaciones asíncronas que usan 'await'.
app.get("/", async (req, res) => {
  // Reiniciamos los aciertos a 0 al comenzar.
  totalCorrect = 0;

  // Elegimos una bandera al azar de la lista cargada desde la base de datos.
  // 'await' espera a que la selección termine antes de continuar.
  await nextQuestion();

  // Imprimimos la pregunta en el terminal para facilitar la depuración y seguimiento.
  console.log(currentQuestion);

  // ¿Qué hace 'res.render()'?
  // Lee la plantilla 'views/index.ejs', sustituye las variables dinámicas por las del objeto
  // '{ question: currentQuestion }' y envía el documento HTML final al navegador web.
  res.render("index.ejs", { question: currentQuestion });
});

// RUTA POST "/submit" (Recepción y comprobación de la respuesta del usuario)
// ¿Qué es POST? Petición HTTP utilizada para enviar datos desde el navegador hacia el servidor.
app.post("/submit", (req, res) => {
  // ¿Qué es 'req.body.answer'?
  // Es el texto que el usuario escribió en el campo con <input name="answer"> en la página web.
  //
  // ¿Qué es el método '.trim()'?
  // Es una función nativa de las cadenas de texto (Strings).
  // Su propósito es eliminar espacios en blanco accidentales que puedan quedar al inicio o al final.
  // Ejemplo: si el usuario escribe "  España ", '.trim()' devuelve "España".
  let answer = req.body.answer.trim();

  // Variable de tipo booleano (Boolean: solo 'true' o 'false') para saber si acertó.
  let isCorrect = false;

  // ¿Qué es el método '.toLowerCase()'?
  // Convierte todas las letras del texto a minúsculas.
  // Al aplicar '.toLowerCase()' tanto al nombre oficial del país ('currentQuestion.name')
  // como a lo que escribió el usuario ('answer'), la comparación ignora si se escribieron mayúsculas
  // o minúsculas (ej: "Francia", "FRANCIA" y "francia" se consideran idénticos).
  //
  // 💡 NOTA DIDÁCTICA SOBRE LA TABLA 'flags':
  // En la tabla 'flags', la columna donde se guarda el país se llama 'name' (a diferencia de 'capitals' donde era 'capital').
  // Por eso aquí accedemos a 'currentQuestion.name'.
  //
  // ¿Qué es '==='?
  // Operador de igualdad estricta en JavaScript. Verifica que ambos lados tengan el mismo valor y tipo de dato.
  if (currentQuestion.name.toLowerCase() === answer.toLowerCase()) {
    // '++': Operador de incremento que suma 1 a 'totalCorrect'.
    totalCorrect++;
    console.log(totalCorrect);
    // Marcamos que la respuesta ha sido correcta.
    isCorrect = true;
  }

  // Elegimos la siguiente bandera aleatoria.
  nextQuestion();

  // Renderizamos de nuevo la vista con los resultados actualizados:
  //   - 'question': la nueva bandera que debe adivinar.
  //   - 'wasCorrect': si la respuesta previa fue correcta o no (para mostrar feedback visual).
  //   - 'totalScore': total de aciertos acumulados.
  res.render("index.ejs", {
    question: currentQuestion,
    wasCorrect: isCorrect,
    totalScore: totalCorrect,
  });
});

// ------------------------------------------------------------------------------
// 6. FUNCIÓN AUXILIAR DE SELECCIÓN ALEATORIA
// ------------------------------------------------------------------------------
// Función que selecciona un elemento aleatorio del array 'quiz':
async function nextQuestion() {
  // Explicación paso a paso de la fórmula aleatoria:
  // 1. 'quiz.length': Cantidad total de banderas en el array.
  // 2. 'Math.random()': Genera un número decimal pseudoaleatorio entre 0 y 0.999...
  // 3. 'Math.random() * quiz.length': Escala el número aleatorio al rango de tamaño de la lista.
  // 4. 'Math.floor(...)': Redondea hacia abajo al entero más cercano (obteniendo un índice válido entre 0 y quiz.length - 1).
  // 5. 'quiz[...]': Obtiene el elemento ubicado en ese índice del array.
  const randomCountry = quiz[Math.floor(Math.random() * quiz.length)];

  // Asignamos el país y bandera elegidos a la variable global 'currentQuestion'.
  currentQuestion = randomCountry;
}

// ------------------------------------------------------------------------------
// 7. ARRANQUE DEL SERVIDOR WEB
// ------------------------------------------------------------------------------
// El método '.listen()' pone al servidor a escuchar de forma permanente peticiones
// que lleguen al puerto especificado (3000).
app.listen(port, () => {
  console.log(`Server is running at http://localhost:${port}`);
});
