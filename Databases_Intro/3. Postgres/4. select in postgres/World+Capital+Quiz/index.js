// ==============================================================================
// 🌍 WORLD CAPITAL QUIZ - CÓDIGO BASE DEL ALUMNO (ANTES DE CONECTAR POSTGRESQL)
// ==============================================================================
// Este archivo es el punto de partida de la práctica.
// Actualmente, las preguntas están "hardcodeadas" (escritas a mano de forma fija)
// en un array de JavaScript. Tu objetivo en la práctica será sustituir ese array fijo
// conectando este servidor con la base de datos PostgreSQL mediante una consulta 'SELECT'.
// ==============================================================================

// ------------------------------------------------------------------------------
// 1. IMPORTACIÓN DE MÓDULOS (LIBRERÍAS EXTERNAS)
// ------------------------------------------------------------------------------
// ¿Qué es una librería o paquete?
// Es código escrito por otros programadores y compartido a través de 'npm' (Node Package Manager)
// para que no tengamos que reinventar la rueda (por ejemplo, construir un servidor web desde cero).
//
// ¿Qué hace 'import ... from ...'?
// Es la instrucción oficial de JavaScript moderno (ES Modules) para cargar una librería instalada
// en la carpeta 'node_modules' y ponerla a nuestra disposición en este archivo:

// 'express': El framework web más utilizado en Node.js. Facilita escuchar peticiones HTTP de usuarios,
// definir URLs (rutas como "/" o "/submit") y responder con páginas web.
import express from "express";

// 'body-parser': Un procesador (middleware) que intercepta los datos enviados por el usuario
// a través de un formulario HTML (mediante el método POST) y los convierte en un objeto fácil de leer.
import bodyParser from "body-parser";

// 💡 PISTA DIDÁCTICA PARA TU PRÁCTICA:
// Para conectar PostgreSQL, aquí deberás importar el conector oficial de Postgres:
// import pg from "pg";

// ------------------------------------------------------------------------------
// 2. CREACIÓN DEL SERVIDOR WEB
// ------------------------------------------------------------------------------
// ¿Qué es una constante ('const')?
// Es una palabra reservada para declarar variables cuyo identificador no cambiará ni será reasignado.
//
// ¿Qué hace 'express()'?
// Es una función que, al ser invocada con paréntesis '()', inicializa y nos devuelve una nueva
// instancia de una aplicación Express (nuestro servidor web), que guardamos en la constante 'app'.
const app = express();

// ¿Qué es un puerto ('port')?
// Es un número que identifica un canal de comunicación específico en tu ordenador.
// Tu ordenador tiene una dirección local llamada 'localhost' (o 127.0.0.1). El puerto 3000
// actúa como una "puerta de entrada" para que el navegador web sepa exactamente a qué programa
// entregarle los mensajes cuando visites 'http://localhost:3000'.
const port = 3000;

// ------------------------------------------------------------------------------
// 3. DATOS DE LAS PREGUNTAS (ESTADO INICIAL ESTÁTICO)
// ------------------------------------------------------------------------------
// ¿Qué es una variable ('let')?
// Es una variable cuyo valor SÍ puede cambiar o ser modificado a lo largo de la ejecución del programa.
//
// ¿Qué es un Array (arreglo / lista) '[]'?
// Es una colección ordenada de elementos encerrada entre corchetes '[]'.
// Cada posición de la lista tiene un número llamado "índice", comenzando siempre desde 0:
// - Posición 0: { country: "France", capital: "Paris" }
// - Posición 1: { country: "United Kingdom", capital: "London" }
// - Posición 2: { country: "United States of America", capital: "New York" }
//
// ¿Qué es un Objeto '{}'?
// Es una estructura que agrupa datos relacionados mediante parejas de "clave: valor" separadas por comas.
// Aquí, cada país es un objeto con dos claves (propiedades):
//   - 'country' (clave) : "France" (valor, de tipo String o texto)
//   - 'capital' (clave) : "Paris"  (valor, de tipo String o texto)
//
// ⚠️ PROBLEMA ACTUAL: Solo tenemos 3 países escritos a mano.
// 🎯 EN LA PRÁCTICA: Conectarás con PostgreSQL y harás un 'SELECT * FROM capitals'
// para rellenar este array 'quiz' con los 249 países reales de la base de datos.
let quiz = [
  { country: "France", capital: "Paris" },
  { country: "United Kingdom", capital: "London" },
  { country: "United States of America", capital: "New York" },
];

// Variable numérica entera que almacena el número de aciertos consecutivos del jugador.
let totalCorrect = 0;

// ------------------------------------------------------------------------------
// 4. MIDDLEWARES (FUNCIONES INTERMEDIARIAS)
// ------------------------------------------------------------------------------
// ¿Qué es un Método?
// Una función que pertenece a un objeto. Se ejecuta usando la sintaxis de punto: objeto.metodo().
//
// ¿Qué es un Middleware en Express?
// Es una función intermedia por la que pasa cualquier petición HTTP antes de llegar a su ruta final.
// El método 'app.use()' registra un middleware en nuestra aplicación.

// Middleware 1: Lectura de formularios HTML
// Cuando un usuario pulsa "Comprobar" en un formulario HTML, los datos viajan codificados en el cuerpo
// de la petición HTTP. Esta línea le enseña a Express a interpretar ese formato y guardarlo de forma limpia
// en el objeto 'req.body'.
app.use(bodyParser.urlencoded({ extended: true }));

// Middleware 2: Servir archivos estáticos
// Le dice a Express que todos los archivos dentro de la carpeta 'public' (como hojas de estilos 'main.css',
// imágenes, fuentes) deben ser accesibles públicamente para el navegador de forma directa.
app.use(express.static("public"));

// Variable global donde guardaremos el objeto del país que se está preguntando actualmente en pantalla.
// Comienza siendo un objeto vacío '{}'.
let currentQuestion = {};

// ------------------------------------------------------------------------------
// 5. RUTAS Y CONTROLADORES (CÓMO RESPONDE EL SERVIDOR)
// ------------------------------------------------------------------------------

// RUTA GET "/" (Página principal)
// ¿Qué es una petición GET?
// Es el tipo de petición que hace un navegador cuando un usuario teclea 'http://localhost:3000'
// en la barra de direcciones para solicitar y visualizar una página web.
//
// Parámetros '(req, res)':
//   - 'req' (Request / Petición): Objeto que contiene toda la información que llega desde el navegador.
//   - 'res' (Response / Respuesta): Objeto con métodos y utilidades para responder al navegador.
//
// ¿Qué significa 'async'?
// Indica que la función es asíncrona, permitiendo pausar su flujo con 'await' si hay tareas
// que requieren esperar (como consultas a bases de datos o funciones externas).
app.get("/", async (req, res) => {
  // Ponemos el contador a 0 para empezar una partida desde el principio.
  totalCorrect = 0;

  // Ejecutamos la función auxiliar que elige un país aleatorio de nuestra lista.
  await nextQuestion();

  // Imprimimos la pregunta seleccionada en la consola del terminal para poder verificarla.
  console.log(currentQuestion);

  // ¿Qué es el método 'res.render()'?
  // Toma la plantilla 'views/index.ejs', fusiona las variables que le pasamos en el objeto
  // '{ question: currentQuestion }' dentro de la plantilla HTML dinámica, y le envía al navegador
  // el código HTML final ya generado.
  res.render("index.ejs", { question: currentQuestion });
});

// RUTA POST "/submit" (Procesar la respuesta del usuario)
// ¿Qué es una petición POST?
// Es el tipo de petición HTTP que se utiliza para enviar datos importantes desde el navegador
// hacia el servidor (en este caso, la respuesta que el alumno escribió en el formulario).
app.post("/submit", (req, res) => {
  // ¿Qué es 'req.body.answer'?
  // 'req.body' es el objeto creado por 'body-parser'.
  // '.answer' extrae el texto del campo cuyo nombre en el HTML es <input name="answer">.
  //
  // ¿Qué es el método '.trim()'?
  // Es un método nativo de las cadenas de texto (Strings) en JavaScript.
  // Su labor es "podar" o eliminar los espacios en blanco que pueda haber por descuido
  // al principio o al final del texto escrito.
  // Ejemplo: si el usuario escribe "  Londres  ", '.trim()' lo limpia a "Londres".
  let answer = req.body.answer.trim();

  // ¿Qué es un Booleano (Boolean)?
  // Es un tipo de dato que solo puede tener dos valores: 'true' (verdadero) o 'false' (falso).
  // Inicializamos la variable en 'false' asumiendo que aún no sabemos si acertó.
  let isCorrect = false;

  // ¿Qué es el método '.toLowerCase()'?
  // Es un método nativo de Strings que transforma todas las letras de un texto en minúsculas.
  // ¿Por qué lo usamos aquí?
  // Para que la comparación sea justa y flexible:
  // Si la capital guardada es "Paris" y el usuario escribe "PARIS" o "paris",
  // al aplicar '.toLowerCase()' a ambos lados comparamos "paris" === "paris", ¡ambos coinciden!
  //
  // ¿Qué es el operador '===' (Igualdad estricta)?
  // Compara dos valores y verifica que tanto su contenido como su tipo de dato sean exactamente idénticos.
  if (currentQuestion.capital.toLowerCase() === answer.toLowerCase()) {
    // ¿Qué hace '++'? Es el operador de incremento: le suma 1 al número guardado en 'totalCorrect'.
    totalCorrect++;
    console.log(totalCorrect);
    // Marcamos la respuesta como correcta.
    isCorrect = true;
  }

  // Elegimos un nuevo país al azar para la siguiente ronda.
  nextQuestion();

  // Renderizamos de nuevo la plantilla 'index.ejs', pero ahora enviamos 3 datos:
  //   1. 'question': el siguiente país a adivinar.
  //   2. 'wasCorrect': booleano (true/false) para mostrar si acertó o falló la anterior.
  //   3. 'totalScore': el marcador actual con el total de aciertos.
  res.render("index.ejs", {
    question: currentQuestion,
    wasCorrect: isCorrect,
    totalScore: totalCorrect,
  });
});

// ------------------------------------------------------------------------------
// 6. FUNCIÓN AUXILIAR: SELECCIÓN DE PREGUNTA ALEATORIA
// ------------------------------------------------------------------------------
// ¿Qué es una Función?
// Un bloque de instrucciones con nombre que se puede llamar o reutilizar siempre que sea necesario.
async function nextQuestion() {
  // Explicación detallada de la fórmula matemática para elegir un elemento aleatorio de una lista:
  // 1. 'quiz.length': Propiedad que devuelve el número total de elementos en el array (por ejemplo, 3).
  // 2. 'Math.random()': Función nativa que genera un número decimal aleatorio entre 0 (incluido) y 1 (excluido), ej: 0.72.
  // 3. 'Math.random() * quiz.length': Multiplica ese decimal por la longitud del array (ej: 0.72 * 3 = 2.16).
  // 4. 'Math.floor(...)': Redondea hacia abajo descartando los decimales (ej: 2.16 se convierte en 2).
  //    Así obtenemos un número entero válido dentro del rango de índices del array (0, 1 o 2).
  // 5. 'quiz[...]': Accedemos al elemento que está en ese índice del array.
  const randomCountry = quiz[Math.floor(Math.random() * quiz.length)];

  // Guardamos ese país seleccionado en nuestra variable de pregunta activa.
  currentQuestion = randomCountry;
}

// ------------------------------------------------------------------------------
// 7. PUESTA EN MARCHA DEL SERVIDOR
// ------------------------------------------------------------------------------
// El método '.listen()' le dice a nuestra aplicación Express que empiece a escuchar
// conexiones en el puerto 3000. El servidor se queda funcionando de fondo esperando que
// los usuarios abran la página web.
//
// El segundo argumento es una función callback que se ejecuta inmediatamente cuando
// el servidor se ha levantado con éxito para avisarnos en la consola.
app.listen(port, () => {
  // Las comillas invertidas (``) permiten crear "Template Strings", donde podemos
  // incrustar variables usando la sintaxis '${variable}'.
  console.log(`Server is running at http://localhost:${port}`);
});
