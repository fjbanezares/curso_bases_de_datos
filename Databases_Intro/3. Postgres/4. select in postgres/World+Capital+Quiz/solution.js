// ==============================================================================
// 🌍 WORLD CAPITAL QUIZ - SOLUCIÓN COMPLETA CON POSTGRESQL (READ / SELECT)
// ==============================================================================
// Este archivo representa el servidor backend de nuestra aplicación web.
// Aquí conectamos JavaScript (Node.js + Express) con una base de datos real (PostgreSQL).
// ==============================================================================

// ------------------------------------------------------------------------------
// 1. IMPORTACIÓN DE MÓDULOS Y LIBRERÍAS
// ------------------------------------------------------------------------------
// ¿Qué es una librería/módulo? Es un conjunto de código ya programado por otros
// desarrolladores que podemos reutilizar en nuestro proyecto para no tener que
// programar todo desde cero (por ejemplo, cómo gestionar peticiones HTTP o cómo
// comunicarse a bajo nivel con una base de datos).
//
// Usamos la palabra reservada 'import' (sintaxis de módulos ES6 de JavaScript)
// para cargar estas librerías desde la carpeta 'node_modules':

// 'express': Framework que simplifica la creación de un servidor web, gestión de rutas y peticiones.
import express from "express";

// 'body-parser': Herramienta que procesa y extrae los datos que un usuario envía a través
// de un formulario HTML (por ejemplo, cuando escribe texto en un <input> y pulsa un botón).
import bodyParser from "body-parser";

// 'pg' (node-postgres): Es el "driver" o conector oficial entre Node.js y PostgreSQL.
// Nos permite enviar sentencias SQL (como SELECT, INSERT, etc.) a la base de datos y recibir sus datos.
import pg from "pg";

// ------------------------------------------------------------------------------
// 2. CONFIGURACIÓN Y CONEXIÓN CON POSTGRESQL
// ------------------------------------------------------------------------------
// ¿Qué es una constante ('const')? Es una variable cuyo valor no puede ser reasignado
// después de su creación. Se usa para datos o referencias que deben mantenerse estables.
//
// ¿Qué es un Objeto en JavaScript? Es una estructura de datos delimitada por llaves '{}'
// que almacena información en parejas de "clave: valor" (propiedades). Por ejemplo:
// { user: "postgres", host: "localhost" }.
//
// ¿Qué es 'new'? Es una palabra reservada que invoca una función constructora o Clase.
// En este caso, 'new pg.Client({...})' crea un nuevo objeto cliente para gestionar
// la conexión específica con nuestro motor de base de datos.
const db = new pg.Client({
  user: "postgres",       // Usuario con permisos en PostgreSQL (por defecto suele ser 'postgres')
  host: "localhost",      // Dirección IP o nombre de host donde corre PostgreSQL ('localhost' = tu propio ordenador)
  database: "world",      // Nombre de la base de datos a la que queremos acceder
  password: "XXXX",    // Contraseña personal de acceso a PostgreSQL
  port: 5432,             // Puerto de red TCP por el que PostgreSQL escucha conexiones (5432 es el predeterminado)
});

// ¿Qué es una variable ('let')? A diferencia de 'const', 'let' declara variables cuyo
// contenido puede cambiar o reasignarse en cualquier momento durante la ejecución del programa.
//
// ¿Qué es una función ('express()')? Un bloque de código ejecutable. Al llamarla con paréntesis '()',
// Express crea e inicializa nuestra aplicación web (el servidor).
const app = express();

// Definimos el puerto de red en el que escuchará nuestro servidor web local.
// Un puerto es como un "número de puerta o timbre" en tu ordenador para que el navegador
// sepa a qué programa dirigir sus peticiones de páginas web.
const port = 3000;

// ¿Qué es un método? Un método es simplemente una función que pertenece a un objeto.
// Se invoca con la sintaxis: objeto.metodo().
// Aquí invocamos el método '.connect()' del objeto 'db' para abrir el canal de comunicación
// físico (conexión de red) entre Node.js y la base de datos PostgreSQL.
db.connect();

// ------------------------------------------------------------------------------
// 3. CONSULTA INICIAL A LA BASE DE DATOS (CARGAR PREGUNTAS EN MEMORIA)
// ------------------------------------------------------------------------------
// ¿Qué es un Array (arreglo o lista) '[]'? Es una colección ordenada de elementos.
// En JavaScript se define entre corchetes '[]'. Los elementos dentro de un array
// están indexados numéricamente comenzando desde la posición 0 (índice 0).
// Aquí creamos un array vacío donde guardaremos todas las filas de países y capitales.
let quiz = [];

// Invocamos el método '.query()' del objeto 'db' para enviar una consulta SQL a PostgreSQL.
// Recibe dos argumentos:
//   1. La sentencia SQL en texto: "SELECT * FROM capitals" (pide todas las columnas y filas de la tabla 'capitals').
//   2. Una función 'callback' (de devolución de llamada): '(err, res) => { ... }'.
//
// ¿Qué es un Callback? Es una función que le pasamos a otra para que la ejecute más adelante,
// en cuanto termine una tarea que tarda tiempo (en este caso, esperar a que la base de datos responda).
// ¿Qué es una 'arrow function' (función flecha)? '() => {}' es una forma moderna y concisa
// de escribir funciones anónimas en JavaScript.
//
// Parámetros del callback:
//   - 'err' (error): Si la consulta falla (ej: tabla inexistente, contraseña errónea), contendrá un objeto con el error. Si todo sale bien, vale 'null' o 'undefined'.
//   - 'res' (resultado / result): Objeto devuelto por PostgreSQL con la información de la respuesta.
db.query("SELECT * FROM capitals", (err, res) => {
  if (err) {
    // 'console.error' imprime mensajes destacados de error en la consola del terminal.
    // 'err.stack' muestra el historial técnico detallado de dónde ocurrió el fallo.
    console.error("Error executing query", err.stack);
  } else {
    // ¿Qué es 'res.rows'? La librería 'pg' convierte automáticamente cada fila de la tabla SQL
    // en un objeto de JavaScript con propiedades según las columnas (ej: { id: 1, country: "Spain", capital: "Madrid" }).
    // Todas esas filas se agrupan en un Array dentro de 'res.rows'.
    // Asignamos ese array de filas a nuestra variable 'quiz':
    quiz = res.rows;
  }
  // '.end()' cierra ordenadamente la conexión con PostgreSQL una vez que hemos terminado
  // de consultar los datos que necesitábamos para arrancar el juego. Esto libera memoria y recursos.
  db.end();
});

// Variable numérica para contar cuántas respuestas correctas seguidas lleva el usuario.
let totalCorrect = 0;

// ------------------------------------------------------------------------------
// 4. MIDDLEWARES (INTERMEDIARIOS DE EXPRESIONES)
// ------------------------------------------------------------------------------
// ¿Qué es un Middleware? Es una función intermediaria o "aduana" por la que pasan
// todas las peticiones HTTP que llegan al servidor antes de alcanzar la ruta final.
// El método 'app.use()' se utiliza para registrar y activar estos intermediarios en Express.

// Middleware 1: 'bodyParser.urlencoded({ extended: true })'
// Permite que Express pueda leer los datos que un usuario envía desde un formulario HTML
// con el método POST. Traduce esos datos del cuerpo de la petición y los deja empaquetados
// y listos para usar dentro del objeto 'req.body'.
app.use(bodyParser.urlencoded({ extended: true }));

// Middleware 2: 'express.static("public")'
// Configura la carpeta 'public' como carpeta de archivos estáticos.
// Cualquier archivo que esté dentro (como imágenes, hojas de estilo CSS o iconos)
// podrá ser descargado directamente por el navegador web del usuario sin tener
// que programar una ruta específica para cada archivo.
app.use(express.static("public"));

// Variable que almacenará un único objeto correspondiente a la pregunta activa en pantalla.
// Se inicializa como un objeto vacío '{}'.
let currentQuestion = {};

// ------------------------------------------------------------------------------
// 5. RUTAS DEL SERVIDOR (CONTROLADORES DE PETICIONES HTTP)
// ------------------------------------------------------------------------------

// RUTA 1: Petición GET a la raíz ("/")
// ¿Qué es una petición GET? Es el tipo de petición que hace el navegador cuando el usuario
// escribe una URL en la barra de direcciones o recarga la página para "obtener" o "ver" contenido.
//
// ¿Qué son 'req' y 'res'?
//   - 'req' (Request / Petición): Objeto que contiene toda la información que llega del cliente (navegador).
//   - 'res' (Response / Respuesta): Objeto que contiene métodos para enviar una respuesta de vuelta al cliente.
//
// ¿Qué significa 'async'? Indica que esta función es asíncrona, lo que permite usar 'await' dentro de ella.
app.get("/", async (req, res) => {
  // Reiniciamos el contador de respuestas correctas a 0 al comenzar una nueva partida.
  totalCorrect = 0;

  // Llamamos a la función para elegir una pregunta aleatoria de la lista 'quiz'.
  // 'await' indica al código que espere a que termine la función antes de continuar.
  await nextQuestion();

  // 'console.log()' es una función básica de JavaScript para imprimir información en el terminal (útil para depurar).
  console.log(currentQuestion);

  // ¿Qué es el método 'res.render()'?
  // Es un método de Express que toma un archivo de plantilla (en este caso 'views/index.ejs'),
  // le inyecta las variables que le pasamos en el segundo parámetro (un objeto '{ question: currentQuestion }'),
  // combina el código HTML con los datos de JavaScript y envía la página web final renderizada al navegador.
  res.render("index.ejs", { question: currentQuestion });
});

// RUTA 2: Petición POST a "/submit"
// ¿Qué es una petición POST? Es el tipo de petición HTTP que se utiliza para "enviar" o
// "publicar" datos al servidor (por ejemplo, el texto que el usuario escribió en un formulario).
app.post("/submit", (req, res) => {
  // ¿Qué hace 'req.body.answer'?
  // 'req.body' es el objeto que creó 'body-parser' con los campos del formulario.
  // '.answer' obtiene el valor exacto del campo de texto cuyo atributo en el HTML era: <input name="answer">.
  //
  // ¿Qué es el método '.trim()'?
  // Es un método nativo de los textos (Strings) en JavaScript. Su función es eliminar cualquier espacio
  // en blanco sobrante al principio o al final de la cadena de texto.
  // Por ejemplo: si el usuario escribe accidentalmente "  Madrid  ", '.trim()' lo convierte limpiamente en "Madrid".
  let answer = req.body.answer.trim();

  // Variable de tipo booleano (Boolean: solo puede ser 'true' o 'false') para saber si el usuario acertó.
  let isCorrect = false;

  // ¿Qué es el método '.toLowerCase()'?
  // Es un método de texto (String) que transforma todos los caracteres a letras minúsculas.
  // Al aplicarlo a ambos lados:
  //   - 'currentQuestion.capital.toLowerCase()' (ej: "Paris" -> "paris")
  //   - 'answer.toLowerCase()' (ej: "PARIS" -> "paris")
  // conseguimos que la comprobación sea insensible a mayúsculas/minúsculas. Así, si el usuario escribe
  // "paris", "Paris" o "PARIS", el programa lo dará por válido igualmente.
  //
  // ¿Qué es el operador '==='?
  // Es el operador de igualdad estricta en JavaScript. Compara tanto el valor como el tipo de dato.
  // A diferencia de '==', '===' no hace conversiones automáticas extrañas de tipos.
  if (currentQuestion.capital.toLowerCase() === answer.toLowerCase()) {
    // ¿Qué hace '++'? Es el operador de incremento. Suma 1 a la variable numérica 'totalCorrect'.
    totalCorrect++;
    console.log(totalCorrect);
    // Cambiamos el valor de la bandera booleana a verdadero porque la respuesta coincidió.
    isCorrect = true;
  }

  // Elegimos una nueva pregunta para el siguiente turno.
  nextQuestion();

  // Renderizamos de nuevo la plantilla 'index.ejs', pasándole:
  //   - 'question': la nueva pregunta seleccionada.
  //   - 'wasCorrect': si la respuesta anterior fue correcta o fallida (para mostrar un mensaje verde o rojo).
  //   - 'totalScore': la puntuación acumulada hasta este momento.
  res.render("index.ejs", {
    question: currentQuestion,
    wasCorrect: isCorrect,
    totalScore: totalCorrect,
  });
});

// ------------------------------------------------------------------------------
// 6. FUNCIÓN AUXILIAR: SELECCIÓN ALEATORIA DE PREGUNTAS
// ------------------------------------------------------------------------------
// Una función ('function') es un bloque de instrucciones reutilizable identificado por un nombre.
// Esta función elige al azar uno de los países que tenemos almacenados en el array 'quiz'.
async function nextQuestion() {
  // Desglose didáctico de cómo seleccionar un elemento al azar de un Array:
  // 1. 'quiz.length': Propiedad de los arrays que nos dice cuántos elementos contiene (ej: 249).
  // 2. 'Math.random()': Función nativa matemática que genera un número decimal aleatorio entre 0 (incluido) y 1 (excluido), ej: 0.634.
  // 3. 'Math.random() * quiz.length': Multiplica ese decimal por la cantidad de países (ej: 0.634 * 249 = 157.866).
  // 4. 'Math.floor(...)': Función nativa matemática que redondea cualquier número hacia abajo al entero más cercano (ej: 157.866 -> 157).
  // 5. 'quiz[...]': Accede al elemento del array en esa posición de índice entera. Como los índices van de 0 a 248, cubre todos los países.
  const randomCountry = quiz[Math.floor(Math.random() * quiz.length)];

  // Asignamos el objeto del país seleccionado aleatoriamente a la variable global 'currentQuestion'.
  currentQuestion = randomCountry;
}

// ------------------------------------------------------------------------------
// 7. INICIO Y ESCUCHA DEL SERVIDOR
// ------------------------------------------------------------------------------
// Invocamos el método '.listen()' del objeto 'app' de Express.
// Este método "enciende" el servidor y lo deja activo en un bucle continuo de escucha,
// esperando a que lleguen peticiones HTTP de usuarios a través del puerto 3000.
//
// El segundo argumento es una función callback que se ejecuta una única vez en cuanto el servidor
// ha arrancado con éxito, imprimiendo un enlace en la consola para acceder a la web.
app.listen(port, () => {
  // Usamos 'template literals' (comillas invertidas `` y ${variable}) para insertar variables dentro del texto.
  console.log(`Server is running at http://localhost:${port}`);
});
