# 🌍 Guía Maestra: Proyecto Fullstack Travel Tracker

> **Bienvenido a la Práctica de Travel Tracker.**  
> Esta guía conecta todo el contenido de la práctica dividido en sus 3 etapas formativas. Aquí encontrarás la visión general del proyecto, la arquitectura completa, cómo preparar y poblar la base de datos con los archivos CSV y los enlaces directos a las guías detalladas de cada parte.

---

## 🗺️ Mapa de la Práctica (Índice de Módulos)

Haz clic en cualquiera de las secciones para acceder a su guía didáctica detallada:

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                                TRAVEL TRACKER ROADMAP                                 │
├──────────────────────────────────────┬────────────────────────────────────────────────┤
│ 📖 [PARTE 1: Lectura y Renderizado]  │ Conexión PostgreSQL, SELECT, EJS y DOM del SVG │
│    👉 ./parte1_lectura_mapa.md       │ (Basado en solution1.js e infografías 1, 2 y 3)│
├──────────────────────────────────────┼────────────────────────────────────────────────┤
│ 📦 [PARTE 2: Tablas, CSV e INSERT]   │ DDL, restricciones, importación de CSV, PRG   │
│    👉 ./parte2-Insert/...            │ (Basado en solution2.js e infografías 1 a 5)  │
├──────────────────────────────────────┼────────────────────────────────────────────────┤
│ 🛡️ [PARTE 3: Errores y Búsqueda]     │ try/catch anidado, LIKE, LOWER() y comodines   │
│    👉 ./parte3-error-handling/...    │ (Basado en solution3.js, 4 y páginas 1, 2 y 3) │
└──────────────────────────────────────┴────────────────────────────────────────────────┘
```

* **[Parte 1: Lectura Básica y Renderizado en el Mapa SVG](./parte1_lectura_mapa.md)**  
  Aprende cómo Express consulta `visited_countries`, transforma las filas en un array de códigos y utiliza EJS y JavaScript en el navegador para pintar de turquesa los `<path>` del mapa mundial.
* **[Parte 2: Creación de Tablas, Importación de CSV e Inserción de Países](./parte2-Insert/parte2_tablas_csv_insert.md)**  
  Aprende a diseñar esquemas con `SERIAL`, `CHAR(2)`, `NOT NULL` y `UNIQUE`, cómo importar datos masivos desde `countries.csv` con pgAdmin o terminal, y cómo implementar el patrón **PRG (Post-Redirect-Get)** para añadir nuevos países.
* **[Parte 3: Manejo de Errores y Búsqueda Flexible (*Fuzzy Search*)](./parte3-error-handling/parte3_errores_y_busqueda_flexible.md)**  
  Descubre cómo blindar tu servidor con `try...catch` anidados frente a países inventados o duplicados, y cómo implementar búsquedas flexibles e insensibles a mayúsculas con `LIKE`, `LOWER()` y el operador de unión de cadenas `||`.

---

## 🏗️ 1. Arquitectura General del Sistema

Travel Tracker es una aplicación web clásica de **3 capas**:

```
[ CAPA 1: CLIENTE (Navegador) ]
  • Formulario HTML: <input name="country">
  • Mapa vectorial SVG: Más de 170 etiquetas <path id="XX">
  • Script de cliente: Convierte "<%= countries %>".split(",") y colorea con .style.fill
       │ ▲
  HTTP │ │ HTML renderizado
  POST │ │ (Server-Side Rendering)
       ▼ │
[ CAPA 2: SERVIDOR (Node.js + Express) ]
  • Middlewares: body-parser.urlencoded y express.static
  • Rutas: GET / y POST /add
  • Lógica asíncrona: async/await y control de errores try/catch
  • Driver: pg (Client / Pool)
       │ ▲
   TCP │ │ Filas de resultados
  SQL  │ │ (result.rows)
       ▼ │
[ CAPA 3: BASE DE DATOS (PostgreSQL: world) ]
  • Tabla 'countries': Catálogo maestro de referencia (id, country_code, country_name)
  • Tabla 'visited_countries': Estado del usuario (id, country_code UNIQUE)
```

---

## 🗄️ 2. El Modelo de Datos y Cómo Poblar la Base de Datos

En este proyecto intervienen dos tablas dentro de la base de datos `world`:

### 2.1. Tabla `countries` (Diccionario de Referencia)
Almacena los países reconocidos y sus códigos oficiales de 2 letras (ISO 3166-1 alfa-2).
* Archivo de datos fuente: [`countries.csv`](./countries.csv).
* Estructura DDL:
  ```sql
  CREATE TABLE countries (
      id SERIAL PRIMARY KEY,
      country_code CHAR(2) NOT NULL UNIQUE,
      country_name VARCHAR(100) NOT NULL
  );
  ```

### 2.2. Tabla `visited_countries` (Registro de Visitas)
Almacena los países que el usuario ha marcado como visitados.
* Estructura DDL:
  ```sql
  CREATE TABLE visited_countries (
      id SERIAL PRIMARY KEY,
      country_code CHAR(2) NOT NULL UNIQUE
  );
  ```

---

### 2.3. ¿Cómo poblar la base de datos en 1 minuto?

Dispones de dos métodos sencillos:

#### Método 1: Ejecutar el Script SQL Automatizado (Recomendado)
Hemos creado el script [`setup_travel_tracker.sql`](./setup_travel_tracker.sql) que crea ambas tablas e inserta todos los países del mapa SVG junto a los datos iniciales de prueba:
```bash
PGPASSWORD=tu_contraseña /Library/PostgreSQL/15/bin/psql -U postgres -d world -f setup_travel_tracker.sql
```

#### Método 2: Importar mediante pgAdmin 4 y los archivos CSV
1. Abre pgAdmin 4 y conéctate a la base de datos `world`.
2. Ejecuta el DDL de `countries` y `visited_countries`.
3. Haz clic derecho sobre `countries` ➔ **Import/Export Data...**
4. Selecciona [`countries.csv`](./countries.csv), marca la casilla **Header** e importa las columnas `id`, `country_code`, `country_name`.
5. Inserta los datos iniciales en `visited_countries`:
   ```sql
   INSERT INTO visited_countries (country_code) VALUES ('FR'), ('GB'), ('US');
   ```

---

## 💡 3. Conceptos Clave Extrapolables (Glosario Didáctico)

### En JavaScript / Node.js:
* **`async / await`:** Mecanismo para manejar operaciones asíncronas (como consultas a base de datos) sin bloquear el hilo principal de ejecución.
* **`try ... catch`:** Bloque de captura y tratamiento de excepciones. Permite que el servidor se recupere de fallos y responda con mensajes útiles en lugar de colgarse.
* **`body-parser.urlencoded`:** Middleware que lee el cuerpo de las peticiones `POST` enviadas desde formularios HTML estándar y las traduce a un objeto legible en `req.body`.
* **Patrón PRG (Post-Redirect-Get):** Técnica que redirige (`res.redirect("/")`) tras procesar un formulario `POST`, impidiendo que el usuario reenvíe datos duplicados al refrescar la pantalla con F5.

### En SQL / PostgreSQL:
* **`CHAR(2)`:** Cadena de longitud fija. Reserva exactamente 2 bytes, ideal para códigos ISO de dos letras (`ES`, `FR`, `US`).
* **`UNIQUE`:** Restricción de integridad que garantiza a nivel de motor que no existan valores duplicados en esa columna.
* **Consultas Parametrizadas (`$1, $2`):** Separan la estructura de la consulta de los datos introducidos por el usuario, eliminando por completo el riesgo de **Inyección SQL**.
* **`LIKE` y `%`:** Operador de búsqueda por patrones. El comodín `%` representa cualquier secuencia de caracteres (`'%spain%'`).
* **Operador de concatenación `||`:** Permite unir cadenas en SQL (`'%' || $1 || '%'`), equivalente al `+` en JavaScript.
* **`LOWER()`:** Función de PostgreSQL para convertir texto a minúsculas y permitir búsquedas insensibles a mayúsculas.

---

## 🚀 4. Puesta en Marcha Rápida

1. **Instalar dependencias:**
   ```bash
   cd "/Users/fjbanezares/databases_flash_course/Databases_Intro/3. Postgres/7. select-where-progress/Travel Tracker"
   npm install
   ```

2. **Arrancar la solución completa:**
   ```bash
   node solution4.js
   ```

3. **Abrir en el navegador:**
   Entra en [http://localhost:3000](http://localhost:3000)

4. **Probar la interactividad:**
   * Escribe `"spain"` (en minúsculas): España se coloreará de turquesa y el contador subirá a 4.
   * Escribe `"tanzania"`: El sistema encontrará *"United Republic of Tanzania"* gracias a la búsqueda flexible con `LIKE` y `LOWER()`.
   * Escribe `"spain"` otra vez: Verás el mensaje *"Country has already been added, try again."*.
   * Escribe `"Wakanda"`: Verás el mensaje *"Country name does not exist, try again."*.

---

## 📁 5. Inventario de Archivos del Proyecto

* 📄 **Guías Didácticas:**
  * [`practica_travel_tracker.md`](./practica_travel_tracker.md) — Guía Maestra Central (este documento).
  * [`parte1_lectura_mapa.md`](./parte1_lectura_mapa.md) — Guía de la Parte 1.
  * [`parte2-Insert/parte2_tablas_csv_insert.md`](./parte2-Insert/parte2_tablas_csv_insert.md) — Guía de la Parte 2.
  * [`parte3-error-handling/parte3_errores_y_busqueda_flexible.md`](./parte3-error-handling/parte3_errores_y_busqueda_flexible.md) — Guía de la Parte 3.
* 💾 **Datos y Scripts SQL:**
  * [`setup_travel_tracker.sql`](./setup_travel_tracker.sql) — Script SQL autoejecutable de inicialización completa.
  * [`countries.csv`](./countries.csv) — CSV con los 249 países del mundo.
  * [`world-food.csv`](./world-food.csv) — CSV de apoyo para ejercicios de producción agrícola.
* 💻 **Código Fuente:**
  * [`index.js`](./index.js) — Plantilla esqueleto para el alumno.
  * [`solution1.js`](./solution1.js) — Solución 1: Lectura básica de visitas y renderizado SVG.
  * [`solution2.js`](./solution2.js) — Solución 2: Inserción de países y patrón PRG.
  * [`solution3.js`](./solution3.js) — Solución 3: Manejo de errores con `try...catch` anidados.
  * [`solution4.js`](./solution4.js) — Solución 4: Búsqueda flexible con `LIKE`, `LOWER()` y concatenación `||`.
  * [`solution5.js`](./solution5.js) — Solución 5: Operación CRUD completa con borrado de países (`DELETE`).
  * [`views/index.ejs`](./views/index.ejs) — Vista del frontend con formulario de añadir y formulario condicional de borrado.

---

## 🔬 6. Desmitificando `visited_countries`: ¿En qué momento se crea y cómo se inyecta el array `['FR', 'GB', 'US']`?

Una de las mayores fuentes de confusión al comenzar la práctica es preguntarse:  
*¿En qué punto del código de Node.js se crea la tabla `visited_countries`? ¿Quién inyecta mágicamente el array `['FR', 'GB', 'US']` en la aplicación?*

### La Realidad: Node.js NO la crea ni la inyecta automáticamente
En el código de `solution1.js` vemos esto:
```javascript
app.get("/", async (req, res) => {
  const result = await db.query("SELECT country_code FROM visited_countries");
  let countries = [];
  result.rows.forEach((country) => {
    countries.push(country.country_code);
  });
  res.render("index.ejs", { countries: countries, total: countries.length });
});
```

* **Node.js actúa como un simple consumidor pasivo:** Asume que la tabla `visited_countries` **ya existe en PostgreSQL** antes de que tú ejecutes `node solution1.js`.
* Si intentas arrancar `node solution1.js` con una base de datos vacía, **el servidor fallará de inmediato** con el error:
  ```text
  error: relation "visited_countries" does not exist
  ```
* **¿Quién crea la tabla y quién inyecta los datos?:**  
  **Tú, como administrador de la base de datos (DBA).** En el diseño original del curso, el alumno debe abrir pgAdmin o la terminal antes de programar nada y ejecutar manualmente dos órdenes SQL:

#### Paso 1: Crear la tabla físicamente en PostgreSQL
```sql
CREATE TABLE visited_countries (
    id SERIAL PRIMARY KEY,
    country_code CHAR(2) NOT NULL UNIQUE
);
```

#### Paso 2: Inyectar manualmente la semilla inicial de datos
```sql
INSERT INTO visited_countries (country_code) 
VALUES ('FR'), ('GB'), ('US');
```

#### Paso 3: El viaje hacia el array de JavaScript
Una vez que esas 3 filas residen en el disco de PostgreSQL:
1. Node.js ejecuta `SELECT country_code FROM visited_countries;`.
2. PostgreSQL le devuelve un array de 3 objetos: `[ { country_code: 'FR' }, { country_code: 'GB' }, { country_code: 'US' } ]`.
3. El bucle `.forEach()` de Node.js extrae los valores y construye el array en memoria: `['FR', 'GB', 'US']`.
4. EJS lo convierte en `"FR,GB,US"`, el navegador hace `.split(",")` y el script del cliente pinta Francia, Reino Unido y EE.UU.

> 💡 *Enfoque Profesional (Self-Seeding):*  
> Si quisieras que Node.js cree la tabla e inyecte los datos automáticamente al arrancar sin depender de pasos manuales en pgAdmin, podrías añadir al inicio de tu servidor:
> ```javascript
> await db.query(`
>   CREATE TABLE IF NOT EXISTS visited_countries (
>     id SERIAL PRIMARY KEY,
>     country_code CHAR(2) NOT NULL UNIQUE
>   );
>   INSERT INTO visited_countries (country_code) VALUES ('FR'), ('GB'), ('US')
>   ON CONFLICT (country_code) DO NOTHING;
> `);
> ```

---

## 🌐 7. Apéndice Técnico: La Conexión a Base de Datos bajo los Modelos OSI y TCP/IP

Para comprender a fondo qué ocurre cuando nos conectamos a una base de datos, debemos descender a las entrañas de las redes de comunicaciones y analizar cómo interactúan **pgAdmin** y **Node.js (`pg.Client`)** con el motor **PostgreSQL**.

### 7.1. Tabla Comparativa: Modelo OSI (7 Capas) vs TCP/IP (4 Capas)

```
       MODELO OSI (Teórico)                      MODELO TCP/IP (Práctico)
┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐
│  7. Aplicación                       │  │                                      │
├──────────────────────────────────────┤  │  4. Aplicación                       │
│  6. Presentación                     │  │     (PostgreSQL Wire Protocol v3.0,  │
├──────────────────────────────────────┤  │      HTTP / WebSockets en pgAdmin)   │
│  5. Sesión                           │  │                                      │
├──────────────────────────────────────┼──┼──────────────────────────────────────┤
│  4. Transporte (TCP)                 │  │  3. Transporte (TCP - Puerto 5432)   │
├──────────────────────────────────────┼──┼──────────────────────────────────────┤
│  3. Red (IP)                         │  │  2. Internet (IPv4 / IPv6 Loopback)  │
├──────────────────────────────────────┼──┼──────────────────────────────────────┤
│  2. Enlace de Datos                  │  │  1. Acceso a Red                     │
├──────────────────────────────────────┤  │     (Interfaz virtual 'lo0' local o  │
│  1. Física                           │  │      Tarjeta de Red / Wi-Fi remoto)  │
└──────────────────────────────────────┘  └──────────────────────────────────────┘
```

---

### 7.2. Desglose Capa por Capa: ¿Qué ocurre al hacer `db.connect()` o abrir pgAdmin?

#### 1. Capa de Aplicación (Capa 7 OSI / Capa 4 TCP/IP)
Ni pgAdmin ni Node.js usan HTTP para comunicarse con PostgreSQL. Utilizan el **PostgreSQL Frontend/Backend Protocol v3.0**, un protocolo binario orientado a mensajes sobre un flujo de bytes continuo:
* **En Node.js (`pg.Client`):**  
  La librería `pg` implementa este protocolo en JavaScript puro. Cuando invocas `await db.connect()`, Node crea un objeto `Socket` y envía un mensaje binario llamado `StartupMessage` con el usuario (`postgres`), la base de datos (`world`) y parámetros de entorno.
* **En pgAdmin:**  
  pgAdmin está construido con un servidor web en **Python (Flask)**. Cuando tú haces clic en el navegador para ver una tabla, tu navegador envía una petición `HTTP/JSON` al servidor local de pgAdmin (en el puerto 5050). A su vez, el motor de Python (usando la librería C/Python `psycopg`) abre una conexión mediante el protocolo nativo de PostgreSQL hacia el puerto 5432.
* **El Diálogo de Mensajes en el Protocolo PostgreSQL:**
  ```
  Cliente (Node/pgAdmin)                   Servidor (PostgreSQL: 5432)
         │                                            │
         │ ─── 1. StartupMessage (user, db) ────────> │
         │ <── 2. AuthenticationCleartext/SCRAM ───── │
         │ ─── 3. PasswordMessage ('XXXX') ──────────> │
         │ <── 4. AuthenticationOk ────────────────── │
         │ <── 5. BackendKeyData (PID, CancelKey) ─── │
         │ <── 6. ReadyForQuery ('Z') ─────────────── │
         │                                            │
         │ ─── 7. Query ('Q': "SELECT ...") ────────> │
         │ <── 8. RowDescription ('T': columnas) ─── │
         │ <── 9. DataRow ('D': 'FR') ─────────────── │
         │ <── 10. DataRow ('D': 'GB') ────────────── │
         │ <── 11. DataRow ('D': 'US') ────────────── │
         │ <── 12. CommandComplete ('C': SELECT 3) ── │
         │ <── 13. ReadyForQuery ('Z') ────────────── │
  ```

#### 2. Capa de Presentación (Capa 6 OSI)
* **Formato y Codificación:** Se negocia `client_encoding`. PostgreSQL y Node.js acuerdan comunicarse en `UTF-8` para que nombres con tildes o caracteres especiales (ej. *Côte d'Ivoire*) no se corrompan.
* **Cifrado (Seguridad):** Antes de autenticarse, el cliente puede enviar un paquete de 8 bytes llamado `SSLRequest`. Si el servidor lo admite, se negocia una capa **TLS 1.3** que cifra todos los paquetes subsiguientes. En conexiones locales (`localhost`) solemos operar sin TLS, pero al conectar con nubes como **Supabase** o **AWS RDS**, este paso es obligatorio para que la contraseña no viaje en texto plano por Internet.

#### 3. Capa de Sesión (Capa 5 OSI)
* En el momento en que PostgreSQL responde `AuthenticationOk`, el sistema operativo del servidor bifurca un proceso hijo dedicado:  
  `postgres: postgres world 127.0.0.1(54321) idle`.
* Esta sesión mantiene el estado: transacciones activas (`BEGIN ... COMMIT`), tablas temporales, variables de configuración (`SET timezone`) y el identificador de proceso (PID).
* **Diferencia entre `pg.Client` y `pg.Pool`:**  
  `pg.Client` mantiene **una única sesión viva**. Si se cae o se cierra (`db.end()`), la sesión muere.  
  `pg.Pool` gestiona una piscina de múltiples sesiones que se prestan a las peticiones entrantes y se devuelven sin tener que destruir y recrear la sesión continuamente.

#### 4. Capa de Transporte (Capa 4 OSI / Capa 3 TCP/IP)
* **Protocolo TCP (Transmission Control Protocol):**  
  Las bases de datos relacionales exigen fiabilidad absoluta; no se puede perder ni un solo byte de una transacción financiera o de un registro. Por eso se usa **TCP** y nunca UDP.
* **Handshake de 3 Vías (Three-Way Handshake):**  
  Antes de que pueda viajar la primera consulta SQL, se produce el saludo TCP:
  1. Cliente (puerto efímero, ej. `54321`) envía segmento `SYN` al servidor (puerto `5432`).
  2. PostgreSQL responde con `SYN-ACK`.
  3. Cliente responde con `ACK`. ¡El canal bidireccional queda abierto!
* **Garantías de TCP:** Control de flujo mediante ventana deslizante, reordenación de segmentos recibidos fuera de orden, cálculo de sumas de verificación (*checksum*) y retransmisión automática en caso de pérdida de paquetes.
* **⚡ El caso especial: Unix Domain Sockets (IPC):**  
  En sistemas macOS y Linux, si configuras la conexión sin especificar host TCP (`localhost`), PostgreSQL puede comunicarse a través de un archivo socket local del sistema de archivos (ej. `/tmp/.s.PGSQL.5432`). En este caso, **se salta la pila de red TCP/IP por completo**; la comunicación ocurre directamente en la memoria del kernel mediante Inter-Process Communication (IPC), siendo notablemente más rápida.

#### 5. Capa de Red / Internet (Capa 3 OSI / Capa 2 TCP/IP)
* **Protocolo IP (IPv4 / IPv6):**  
  Empaqueta los segmentos TCP dentro de paquetes IP con sus cabeceras:
  * IP Origen: `127.0.0.1` (o `::1` en IPv6).
  * IP Destino: `127.0.0.1` (Dirección de Loopback local).
  * Campo TTL (Time-To-Live): Evita que los paquetes circulen infinitamente si hubiera bucles de enrutamiento.

#### 6. Capa de Enlace de Datos y Capa Física (Capas 2 y 1 OSI / Capa 1 TCP/IP)
* **En entorno Local (`localhost`):**  
  No hay tarjetas de red Ethernet físicas ni cables involucrados. La comunicación pasa por el controlador de interfaz virtual **Loopback (`lo0`)**. El kernel de macOS/Linux simplemente copia los buffers de memoria del proceso Node.js a los buffers de memoria del proceso PostgreSQL. La MTU (Unidad Máxima de Transferencia) virtual suele ser enorme (16.384 o 65.536 bytes) frente a los 1.500 bytes de una red Ethernet estándar.
* **En entorno Cloud / Nube (Supabase, RDS):**  
  Los paquetes IP se encapsulan en tramas Ethernet (IEEE 802.3), viajan por la tarjeta de red física (NIC), se modulan en ondas de radio Wi-Fi o pulsos de luz en cables de fibra óptica submarinos, y atraviesan decenas de enrutadores en Internet hasta alcanzar el centro de datos de la nube.

---

### 7.3. Reflexión de Cierre: Por qué esto te convierte en un Desarrollador Superior
Cuando un programador junior ve `await db.query("SELECT * FROM visited_countries")`, imagina que la tabla está dentro de su script de JavaScript.  
Cuando un ingeniero senior escribe esa misma línea, ve:
1. Una llamada a la API asíncrona de Node.js delegada a libuv.
2. Un mensaje binario formateado según el protocolo PostgreSQL v3.0.
3. Un flujo de bytes segmentado por TCP sobre el puerto 5432.
4. Paquetes enrutados por IP hacia el loopback local o una IP pública en la nube.
5. Un proceso en PostgreSQL que analiza la consulta con su optimizador de costes, busca páginas de datos en el buffer pool del disco y devuelve los bytes ordenadamente.

Entender la pila completa desde el píxel turquesa del SVG en el navegador hasta el paquete TCP en el puerto 5432 es lo que te permite depurar fallos complejos de red (*timeouts*, problemas de IPv4/IPv6, saturación de pools de conexiones) con total soltura y autoridad técnica.

---

## 🔐 8. Apéndice 2: Seguridad Profesional — Gestión de Credenciales con Variables de Entorno (`.env`)

> **"Hardcodear contraseñas en el código fuente es el equivalente a dejar la llave de tu casa pegada a la cerradura con una nota que dice: 'Por favor, no entren'."**

Escribir contraseñas directamente en archivos como `solution1.js` (`password: "XXXX"`) es una pésima práctica de desarrollo y un grave riesgo de seguridad:
* **Riesgo en Docencia:** Si proyectas tu pantalla en clase, grabas un vídeo tutorial o compartes tu repositorio con los alumnos, **todos verán tu contraseña real**.
* **Riesgo en Producción (Vulnerabilidad CWE-798):** Si el código se sube a un repositorio público o privado en GitHub o GitLab, bots automáticos escanean los *commits* en cuestión de segundos y extraen las contraseñas para atacar los servidores.
* **Inflexibilidad:** Si tu contraseña local es `"XXXX"` y la de tu alumno es `"123456"`, cada vez que alguien descargue el código tendrá que modificar archivos `.js` manualmente, generando conflictos de Git innecesarios.

---

### 8.1. La Filosofía de *The Twelve-Factor App* (Factor III: Configuración)
El estándar internacional de la industria de software establece que:
> **El código fuente de una aplicación debe ser exactamente idéntico en todos los entornos.** Lo único que cambia de una máquina a otra es la **configuración**, y esta debe ser inyectada desde el exterior mediante **Variables de Entorno**.

---

### 8.2. La Tríada Indispensable: `.env`, `.env.example` y `.gitignore`

Para gestionar secretos de forma profesional en esta y en cualquier otra práctica, se utiliza siempre una estructura de 3 archivos:

```
Mi Proyecto/
│
├── 🔒 .env            <-- TUS SECRETOS REALES (Contraseña real, usuario, puerto).
│                          ¡ESTE ARCHIVO NUNCA SE SUBE A GIT NI SE COMPARTE!
│
├── 📋 .env.example    <-- PLANTILLA PÚBLICA (Nombres de variables sin contraseñas).
│                          Este archivo SÍ se sube a Git y se comparte con alumnos.
│
├── 🚫 .gitignore      <-- LA BARRERA DE SEGURIDAD.
│                          Contiene la línea ".env" para que Git jamás lo rastree.
│
└── 💻 solution4.js    <-- TU CÓDIGO (Lee process.env.DB_PASSWORD limpiamente).
```

---

### 8.3. Contenido de los Archivos de Configuración

#### 1. Archivo [`.env.example`](./.env.example) (Público y Seguro para Compartir)
Este archivo se entrega a los alumnos como molde para que sepan qué variables necesita la aplicación:
```env
# ==============================================================================
# PLANTILLA DE VARIABLES DE ENTORNO (.env.example)
# Copia este archivo como ".env" y escribe tus credenciales locales:
# cp .env.example .env
# ==============================================================================

DB_USER=postgres
DB_HOST=localhost
DB_DATABASE=world
DB_PASSWORD=tu_contraseña_local_aqui
DB_PORT=5432
PORT=3000
```

#### 2. Archivo [`.env`](./.env) (Privado, Local y Protegido en tu Máquina)
Aquí reside tu clave real. Solo existe en tu ordenador:
```env
DB_USER=postgres
DB_HOST=localhost
DB_DATABASE=world
DB_PASSWORD=XXXX
DB_PORT=5432
PORT=3000
```

#### 3. Archivo [`.gitignore`](./.gitignore) (El Escudo Protector)
Asegura que ni por descuido se envíe `.env` a GitHub:
```gitignore
node_modules/
.env
.env.local
.env.*.local
.DS_Store
```

---

### 8.4. Cómo Consumir las Variables de Entorno en el Código

#### A. En Node.js (JavaScript)
1. Se instala la librería estándar de la industria:
   ```bash
   npm install dotenv
   ```
2. Al inicio del archivo `.js`, se importa la librería:
   ```javascript
   import "dotenv/config"; // Lee automáticamente el archivo .env local
   ```
3. Se configuran las conexiones leyendo de `process.env`:
   ```javascript
   const db = new pg.Client({
     user: process.env.DB_USER || "postgres",
     host: process.env.DB_HOST || "localhost",
     database: process.env.DB_DATABASE || "world",
     password: process.env.DB_PASSWORD, // 👈 ¡Nadie ve tu contraseña!
     port: process.env.DB_PORT || 5432,
   });
   ```

*(Nota técnica: En versiones modernas de Node.js v20.6+ también puedes arrancar sin librerías externas ejecutando `node --env-file=.env solution4.js`)*.

---

#### B. En Python (para Prácticas de Ciencia de Datos o Supabase)
Si en el futuro haces prácticas con Python:
1. Instalas `python-dotenv`:
   ```bash
   pip install python-dotenv
   ```
2. En tu script Python:
   ```python
   import os
   from dotenv import load_dotenv

   load_dotenv() # Carga las variables del .env

   db_password = os.getenv("DB_PASSWORD")
   db_user = os.getenv("DB_USER", "postgres")
   ```

---

#### C. En Servicios Cloud (Supabase, AWS, Render)
Cuando conectas con la nube, en el archivo `.env` simplemente declaras la URL completa o las claves de API:
```env
DATABASE_URL=postgresql://postgres.xxx:TuClaveSecreta@aws-1-eu-west-1.pooler.supabase.com:5432/postgres
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsIn...
```
Y en tu código:
```javascript
const db = new pg.Client({
  connectionString: process.env.DATABASE_URL,
});
```

---

### 8.5. Flujo de Trabajo Docente: Cómo Entregar Prácticas a tus Alumnos

Para tus clases y cursos, el protocolo perfecto y profesional es:

```
         [ PROFESOR ]                                     [ ALUMNO ]
 1. Trabaja en local con su .env.                1. Clona el repositorio de Git.
 2. El archivo .gitignore bloquea .env.          2. No ve ninguna contraseña del profesor.
 3. Sube el código + .env.example.               3. Ve el archivo .env.example con instrucciones.
                                                 4. Ejecuta en terminal: cp .env.example .env
                                                 5. Abre su .env y pone su propia contraseña.
                                                 6. Ejecuta "node solution4.js" y ¡funciona a la primera!
```

Con este flujo:
* Tu contraseña personal queda **100% oculta y segura**.
* Tus alumnos aprenden desde el día 1 cómo se trabaja en empresas tecnológicas reales.
* El repositorio queda limpio, elegante y listo para compartir públicamente sin temor.


