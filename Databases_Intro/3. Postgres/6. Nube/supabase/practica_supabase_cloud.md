# ☁️ Práctica Guiada: PostgreSQL en la Nube con Supabase
### *Puesta en marcha, diseño de tablas relacionales y consumo desde Node.js y Python*

> *"Supabase pone en tus manos el poder colosal de un servidor PostgreSQL profesional en la nube en menos de 2 minutos, con copias de seguridad, panel visual y APIs listas para conectar con cualquier lenguaje de programación."*

¡Bienvenido/a a la práctica de bases de datos en la **Nube**! Hasta ahora hemos trabajado con PostgreSQL instalado localmente en tu ordenador (`localhost`). Hoy daremos el salto que da todo equipo de desarrollo profesional: desplegar una base de datos PostgreSQL real en la nube, diseñar un par de tablas relacionadas, alimentarlas con datos y aprender a conectarnos a ellas tanto desde **Node.js** como desde **Python**.

![Infografía de Supabase](./supabase.png)

---

## 📌 Índice de Contenidos

1. [¿Qué es la Nube y qué es Supabase? (Sin dar nada por sabido)](#1-qué-es-la-nube-y-qué-es-supabase)
   - [¿Por qué llevar la base de datos a la Nube?](#por-qué-llevar-la-base-de-datos-a-la-nube)
   - [¿Qué es Supabase y por qué no es un PostgreSQL cualquiera?](#qué-es-supabase)
2. [Paso 1: Puesta en Marcha / "Instalar" Supabase](#2-paso-1-puesta-en-marcha--instalar-supabase)
   - [Opción Cloud (Recomendada y Gratuita)](#opción-a-supabase-cloud-la-opción-oficial-y-gratuita)
   - [Opción Local (Supabase CLI con Docker)](#opción-b-supabase-cli-local-para-desarrollo-offline-con-docker)
3. [Paso 2: Dónde encontrar y entender tus Credenciales](#3-paso-2-dónde-encontrar-y-entender-tus-credenciales)
   - [Las 2 formas de comunicarse con Supabase](#las-2-formas-de-comunicarse-con-supabase)
   - [Connection String URI para SQL directo (`pg` y `psycopg2`)](#1-connection-string-uri-conexión-sql-directa)
   - [Project URL y Claves de API (`anon key`) para los SDKs](#2-project-url-y-api-keys-conexión-por-sdk)
   - [Gestión de secretos con archivos `.env`](#buenas-prácticas-el-archivo-env)
   - [⚡ El Gran Obstáculo de Conexión: IPv4 vs IPv6 y Caracteres Especiales (@) desmitificados](#33--el-gran-obstáculo-de-conexión-ipv4-vs-ipv6-y-caracteres-especiales--desmitificados)
4. [Paso 3: Crear Tablas Relacionales y Cargar Datos (`autores` y `libros`)](#4-paso-3-crear-tablas-relacionales-y-cargar-datos)
   - [El Modelo de Datos Relacional](#el-modelo-de-datos)
   - [Método Visual: Usando el *Table Editor* de Supabase](#método-1-usar-el-table-editor-interfaz-visual)
   - [Método SQL: Usando el *SQL Editor* (Rápido y Profesional)](#método-2-usar-el-sql-editor-recomendado)
5. [Paso 4: Conectar y Consultar desde Node.js](#5-paso-4-conectar-y-consultar-desde-nodejs)
   - [Vía 1: Conductor SQL nativo con `pg`](#vía-1-conexión-sql-con-el-driver-pg-app_pgjs)
   - [Vía 2: Cliente moderno con `@supabase/supabase-js`](#vía-2-conexión-moderna-con-el-sdk-app_supabasejs)
6. [Paso 5: Conectar y Consultar desde Python](#6-paso-5-conectar-y-consultar-desde-python)
   - [6.1 La trampa de instalación: psycopg2 vs psycopg2-binary (C Extensions vs Wheels)](#61-la-trampa-de-instalación-psycopg2-vs-psycopg2-binary)
   - [6.2 El estándar RFC 3986 y el colapso del parser con arrobas (@) en Python](#62-el-estándar-rfc-3986-y-el-colapso-del-parser-con-arrobas--en-python)
   - [6.3 La regla de oro relacional: Violación de clave foránea (Foreign Key Violation)](#63-la-regla-de-oro-relacional-violación-de-clave-foránea-foreign-key-violation)
   - [Vía 1: Conductor SQL nativo con `psycopg2`](#vía-1-conexión-sql-con-psycopg2-app_psycopg2py)
   - [Vía 2: Cliente oficial con `supabase-py`](#vía-2-conexión-con-el-sdk-de-python-app_supabasepy)
7. [Seguridad en la Nube: ¿Qué es RLS (*Row Level Security*)?](#7-seguridad-en-la-nube-qué-es-rls-row-level-security)
8. [💡 Lo que se extrae de esta práctica (Puntos Clave)](#8-lo-que-se-extrae-de-esta-práctica-puntos-clave)

---

## 1. ¿Qué es la Nube y qué es Supabase?

### ¿Por qué llevar la base de datos a la Nube?
Cuando tienes PostgreSQL en tu ordenador (`localhost`):
- Si apagas tu portátil, la base de datos se apaga.
- Ningún usuario externo en Internet puede acceder a tus datos.
- Si se rompe tu disco duro, pierdes todo a menos que hagas copias manuales.

En la **Nube** (*Cloud*), tu base de datos corre en un servidor dedicado dentro de un centro de datos seguro (de alta velocidad, encendido 24/7, con copias de seguridad automáticas y protegido contra cortes de luz).

### ¿Qué es Supabase?
**Supabase** se autodefine como la *"Alternativa de código abierto a Firebase"*. Pero a diferencia de Google Firebase (que te obliga a usar bases de datos NoSQL propietarias), Supabase te entrega un **PostgreSQL 100% puro y estándar**, con añadidos automáticos extraordinarios:

```mermaid
graph TD
    subgraph "El Ecosistema Supabase"
        PG[("🐘 Motor PostgreSQL Puro<br>(Tablas, Tipos, SQL, Extensiones)")]
        POSTGREST["⚡ PostgREST<br>(Genera APIs REST instantáneas de tus tablas)"]
        AUTH["🔐 Sistema de Autenticación<br>(Login con Google, GitHub, Magic Links)"]
        STORAGE["📁 Storage<br>(Para subir imágenes, PDFs, ficheros)"]
        STUDIO["🖥️ Supabase Studio<br>(Panel de control web visual moderno)"]
    end

    STUDIO --> PG
    POSTGREST --> PG
    AUTH --> PG
    STORAGE --> PG
```

> [!NOTE]
> **Lo mejor de Supabase:** No hay *"Vendor Lock-in"* (atadura de proveedor). Como por debajo es un PostgreSQL estándar, tu código SQL y tus librerías (`pg` en Node.js, `psycopg2` en Python) funcionarán exactamente igual que en tu máquina local.

---

## 2. Paso 1: Puesta en Marcha / "Instalar" Supabase

Para usar Supabase tenemos dos caminos: usar su servicio en la nube (lo más habitual y cómodo) o instalarlo en local mediante contenedores.

### Opción A: Supabase Cloud (La opción oficial y gratuita)

No necesitas instalar ningún software pesado en tu ordenador; el servidor lo pone Supabase gratis.

1. **Crear cuenta:**
   - Entra en [https://supabase.com](https://supabase.com).
   - Haz clic en el botón verde **"Start your project"** o **"Sign in"**.
   - Puedes iniciar sesión directamente con tu cuenta de **GitHub** (muy recomendado) o registrarte con tu correo electrónico.

2. **Crear una Organización y Proyecto:**
   - En tu panel principal (*Dashboard*), pulsa en **"New Project"**.
   - Elige un nombre para tu organización (por ejemplo: `Curso-Databases`).
   - Rellena la ficha del proyecto:
     - **Name:** `laboratorio-nube` (o el nombre que prefieras).
     - **Database Password:** ⚠️ **¡FUNDAMENTAL!** Escribe una contraseña fuerte que recuerdes o guárdala en un gestor de notas. *Por motivos de seguridad, Supabase nunca te volverá a mostrar esta contraseña; si la pierdes, tendrás que restablecerla*.
     - **Region:** Elige la región geográfica más cercana a ti para que las consultas vuelen rápido. Si estás en España/Europa, elige `Central EU (Frankfurt)` o `West EU (Ireland)`.
     - **Pricing Plan:** Selecciona **Free Plan** (es 100% gratuito y suficiente para decenas de proyectos de aprendizaje).
   - Haz clic en **"Create new project"**.

3. **Esperar el aprovisionamiento:**  
   Verás un mensaje que dice *"Setting up project"*. En unos 60-90 segundos, Supabase configurará una máquina virtual con PostgreSQL, redes y certificados SSL listos para ti.

---

### Opción B: Supabase CLI Local (Para desarrollo offline con Docker)

Si quieres desarrollar sin conexión a Internet, hacer pruebas destructivas sin riesgo o trabajar en equipo con migraciones versionadas en Git, puedes ejecutar Supabase directamente en tu propio ordenador mediante su herramienta de línea de comandos (**Supabase CLI**).

#### ¿Cómo se relaciona Supabase CLI con Docker? (Bajo el capó)
Sabemos que **Docker** permite empaquetar y ejecutar aplicaciones dentro de "contenedores" aislados y reproducibles. Pues bien: **Supabase no es un único programa, sino una constelación de servicios interconectados**. 

Cuando en tu terminal ejecutas el comando:
```bash
supabase start
```
Supabase CLI se conecta automáticamente a tu motor de Docker (debe estar abierto **Docker Desktop** en tu Mac) y descarga y orquesta **una flota completa de contenedores Docker** trabajando en armonía:

```mermaid
graph TD
    CLI["💻 Comando: supabase start"] --> DOCKER["🐳 Motor Docker (Docker Compose interno)"]
    
    subgraph "Flota de Contenedores Locales de Supabase"
        C_DB["🐘 supabase_db<br>PostgreSQL 15+ con extensiones (pgvector, etc.)"]
        C_KONG["🚪 supabase_kong<br>API Gateway que centraliza todas las peticiones"]
        C_AUTH["🔐 supabase_auth (GoTrue)<br>Gestión de usuarios y tokens JWT"]
        C_REST["⚡ supabase_rest (PostgREST)<br>Transforma tablas en APIs REST en tiempo real"]
        C_REAL["📡 supabase_realtime<br>WebSockets para cambios en vivo"]
        C_STOR["📁 supabase_storage<br>Servicio para guardar imágenes y archivos"]
        C_STUD["🖥️ supabase_studio<br>El panel web visual en http://localhost:54323"]
        C_MAIL["📬 supabase_inbucket<br>Servidor de correo falso para capturar emails de prueba"]
    end

    DOCKER --> C_DB
    DOCKER --> C_KONG
    DOCKER --> C_AUTH
    DOCKER --> C_REST
    DOCKER --> C_REAL
    DOCKER --> C_STOR
    DOCKER --> C_STUD
    DOCKER --> C_MAIL
```

#### Paso a paso para arrancar Supabase en local:

1. **Requisito indispensable:**  
   Tener **Docker Desktop** instalado y abierto en tu Mac (debes ver el icono de la ballenita activo en la barra superior).

2. **Instalar Supabase CLI en Mac:**
   ```bash
   brew install supabase/tap/supabase
   ```

3. **Inicializar tu proyecto:**  
   Crea una carpeta e inicializa la configuración:
   ```bash
   mkdir mi-proyecto-local && cd mi-proyecto-local
   supabase init
   ```
   *(Esto creará una carpeta oculta `supabase/` con archivos de configuración y la carpeta de migraciones SQL).*

4. **Arrancar los contenedores:**
   ```bash
   supabase start
   ```
   *La primera vez tardará un par de minutos porque Docker descargará las imágenes oficiales. Al finalizar, la terminal te imprimirá un resumen con todas las URLs y claves de acceso locales:*
   - **Studio URL:** `http://localhost:54323` (El panel visual equivalente a la web de Supabase).
   - **API URL:** `http://localhost:54321` (La puerta de enlace para tu código).
   - **DB URL:** `postgresql://postgres:postgres@localhost:54322/postgres` (Conexión directa a Postgres).
   - **Inbucket URL:** `http://localhost:54324` (Bandeja de entrada para ver emails de confirmación sin enviarlos realmente a Internet).

5. **Comprobar qué contenedores están corriendo:**  
   Puedes usar el comando estándar de Docker en cualquier momento:
   ```bash
   docker ps
   ```
   Verás la lista de todos los contenedores con prefijo `supabase_...`.

6. **Detener los servicios cuando termines:**  
   Para no consumir memoria RAM innecesaria cuando no estés programando:
   ```bash
   supabase stop
   ```
   *(Tus datos quedarán guardados en los volúmenes de Docker para la próxima vez que hagas `supabase start`).*

---

## 3. Paso 2: Dónde encontrar y entender tus Credenciales

Una vez que tu proyecto en Supabase Cloud está listo (`Active`), necesitas las llaves de acceso para que tus programas de Python y Node.js puedan entrar.

En el menú lateral izquierdo de tu proyecto en Supabase, verás un icono de engranaje llamado **Project Settings**. Aquí residen tus secretos:

```mermaid
graph LR
    SETTINGS["⚙️ Project Settings"] --> DB_TAB["🗄️ Database"]
    SETTINGS --> API_TAB["🔌 API"]

    DB_TAB --> URI["Cadena de conexión URI<br>postgresql://postgres:[PASS]@db...:5432/postgres"]
    API_TAB --> URL["Project URL<br>https://xxxx.supabase.co"]
    API_TAB --> ANON["anon public key<br>eyJhbGciOi..."]
```

### Las 2 formas de comunicarse con Supabase

| Método de Conexión | Protocolo | ¿Para qué librerías se usa? | Dónde se copia en Supabase |
| :--- | :--- | :--- | :--- |
| **1. Conexión SQL Directa (TCP)** | Conexión PostgreSQL estándar cifrada por puerto `5432` | `pg` (Node.js), `psycopg2` (Python), `psql`, `pgAdmin` | **Project Settings** ➔ **Database** ➔ Sección **Connection string** ➔ Pestaña **URI** |
| **2. Conexión por API REST (HTTPS)** | Peticiones web JSON por puerto `443` | `@supabase/supabase-js`, librería `supabase` (Python) | **Project Settings** ➔ **API** ➔ **Project URL** y **anon public key** |

---

### 1. Connection String URI (Conexión SQL directa)
1. Ve a **Project Settings** ➔ **Database**.
2. Baja hasta la sección **Connection string**.
3. Selecciona la pestaña **URI** (o modo *Session* / *Direct*).
4. Verás algo como esto:
   ```text
   postgresql://postgres.[TU-ID]:[YOUR-PASSWORD]@aws-0-eu-central-1.pooler.supabase.com:6543/postgres
   ```
   o bien:
   ```text
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxxxx.supabase.co:5432/postgres
   ```
5. Sustituye el texto `[YOUR-PASSWORD]` por la contraseña que escribiste en el Paso 1.

### 2. Project URL y API Keys (Conexión por SDK)
1. Ve a **Project Settings** ➔ **API**.
2. **Project URL:** Es la dirección web de tu servidor (ej: `https://xyzcompany.supabase.co`).
3. **Project API Keys:** Verás dos claves:
   - **`anon` (public):** Es segura para usar en el frontend o aplicaciones de usuario; solo tiene acceso a lo que tú permitas con las políticas de seguridad (RLS).
   - **`service_role` (secret):** ⚠️ ¡CUIDADO! Es la llave maestra con permisos totales que se salta todas las restricciones de seguridad. Nunca la compartas ni la subas a GitHub.

---

### Buenas Prácticas: El archivo `.env`
Tanto en la carpeta [`nodejs/`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/nodejs/) como en [`python/`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/python/) te he preparado una plantilla llamada `.env.example`.

Para usarla, simplemente haz una copia y llámala `.env`:
```bash
# En nodejs o python:
cp .env.example .env
```
Abre ese `.env` y pega tus valores reales.

---

### 3.3 ⚡ El Gran Obstáculo de Conexión: IPv4 vs IPv6 y Caracteres Especiales (@) desmitificados

*(Esta es la causa del 90% de los dolores de cabeza al conectar por primera vez con bases de datos en la nube. Vamos a entender qué ocurre desde los cimientos).*

#### 1. ¿Qué es una dirección IP?
Para que dos ordenadores se envíen cartas a través de Internet, cada uno necesita una dirección única en el mundo: su **Dirección IP** (*Internet Protocol*). Es el equivalente digital al número de teléfono o a tu dirección postal física.

```mermaid
graph LR
    TU_MAC["💻 Tu Ordenador<br>(Pide datos)"] -->|Pregunta por la IP| DNS["🌍 Servidor DNS<br>(La 'guía telefónica')"]
    DNS -->|Devuelve la IP| TU_MAC
    TU_MAC -->|Envía la consulta SQL a esa IP| SUPA["🐘 Servidor Supabase<br>(Responde)"]
```

---

#### 2. IPv4 vs IPv6: El choque generacional

| Protocolo | Formato y Ejemplo | Número de Direcciones en el Mundo | Situación Real |
| :--- | :--- | :--- | :--- |
| **IPv4** *(Antiguo, año 1981)* | 4 números de 0 a 255 separados por puntos:<br>`54.229.189.117` | Unos **4.300 millones** de IPs en total. | ❌ **¡Agotadas!** En los años 80 parecía infinito, pero hoy entre móviles, ordenadores y bombillas inteligentes no quedan direcciones libres. Amazon (AWS) cobra dinero extra por cada IPv4 pública. |
| **IPv6** *(Moderno, año 1998)* | 8 grupos hexadecimales separados por dos puntos:<br>`2a05:d018:f3f:3101:d842:878e:67c2:97be` | $3.4 \times 10^{38}$ (prácticamente infinito). | ✅ Hay suficientes direcciones para asignarle trillones a cada grano de arena del planeta. |

#### ¿Cuál es el problema en el mundo real?
Aunque IPv6 lleva años inventado, **la transición mundial es muy lenta**. Millones de routers domésticos, redes Wi-Fi de operadoras de fibra y conexiones corporativas **todavía funcionan exclusivamente con IPv4**.

---

#### 3. La "Trampa" de Supabase y el error `getaddrinfo ENOTFOUND`

Cuando creas un proyecto gratuito en Supabase, para ahorrar costes de direcciones IPv4, Supabase configura su dirección directa (`db.[ID_PROYECTO].supabase.co`) con **únicamente direcciones IPv6**.

Cuando tu código en Node.js o Python intenta conectarse a `db.xxxx.supabase.co`:
1. Tu ordenador pregunta a tu router/DNS: *"¿Cuál es la IP de este servidor?"*.
2. El DNS responde: *"Solo tengo una dirección IPv6 (registro AAAA)"*.
3. Tu conexión a Internet responde: *"Yo solo sé hablar IPv4, no tengo ruta para viajar por IPv6"*.
4. **Resultado inmediato:** Node.js se rinde y lanza el error:
   ```text
   ❌ Error: getaddrinfo ENOTFOUND db.nlkfysmrygdqdjaluzch.supabase.co
   ```
   *(Literalmente: "No he podido encontrar ninguna dirección reconocible para este nombre de host").*

---

#### 4. Cómo salvar el obstáculo: El Connection Pooler (Supavisor) con IPv4

Supabase sabe que este problema afecta a miles de desarrolladores en todo el mundo. Por eso incluye una puerta de entrada alternativa con soporte nativo para **IPv4**: el **Connection Pooler**.

Un **Pooler** es un intermediario inteligente (un "conserje") que recibe cientos de conexiones de clientes y las administra eficientemente hacia PostgreSQL. Y lo más importante: **el Pooler sí tiene direcciones IPv4 públicas**.

```mermaid
graph TD
    CLIENTE["💻 Tu Script (Node.js / Python)"]
    
    subgraph "Conexión Directa (Falla en redes domésticas)"
        DIRECTA["db.xxxx.supabase.co (Puerto 5432)"]
        FALLO["❌ getaddrinfo ENOTFOUND<br>(Solo disponible en IPv6)"]
    end

    subgraph "Conexión por Pooler (Funciona SIEMPRE)"
        POOLER["aws-0-[region].pooler.supabase.com<br>o aws-1-[region].pooler.supabase.com"]
        IPV4["✅ Compatible 100% con IPv4"]
        PUERTO_SES["Puerto 5432 (Session Mode)"]
        PUERTO_TX["Puerto 6543 (Transaction Mode)"]
    end

    CLIENTE -.->|Falla si tu router no tiene IPv6| DIRECTA --> FALLO
    CLIENTE ==>|Recomendado para desarrollo local| POOLER --> IPV4
    IPV4 --> PUERTO_SES
    IPV4 --> PUERTO_TX
```

#### Los 3 cambios clave al usar el Pooler:
1. **El Host:** Pasa de ser `db.xxxx...` a ser `aws-0-[region].pooler.supabase.com` (o `aws-1-...`).
2. **El Usuario:** Ya no es solo `postgres`, sino `postgres.[ID_PROYECTO]` (por ejemplo: `postgres.nlkfysmrygdqdjaluzch`).
3. **El Puerto:** 
   - **`5432` (*Session Mode*):** Se comporta exactamente como una conexión directa estándar. Es la opción ideal para desarrollo local. En Supabase la variable suele llamarse `DATABASE_SES_URL`.
   - **`6543` (*Transaction Mode*):** Ideal para arquitecturas Serverless (como funciones AWS Lambda o Vercel) donde miles de peticiones entran y salen en microsegundos.

---

#### 5. El Conflicto de la Arroba (`@`) en las Contraseñas

En el estándar oficial de Internet (RFC 3986), una cadena de conexión tiene la siguiente estructura obligatoria:
```text
postgresql:// [usuario] : [contraseña] @ [servidor] : [puerto] / [base_de_datos]
```
La arroba **`@`** es el **delimitador reservado** que separa las credenciales del usuario de la dirección del servidor.

#### El dilema:
Si tu contraseña contiene arrobas (por ejemplo: `Pepito@123@@`):
```text
postgresql://postgres.id:Pepito@123@@@aws-1-eu-west-1.pooler.supabase.com:5432/postgres
                         ^           ^
                         |           |-- ¿Dónde empieza el host?
                         |-- ¿Es parte de la contraseña o del host?
```
El analizador de URLs se confunde con los tres `@` consecutivos.

#### Cómo salvarlo:
* **Solución 1: Codificación URL (Percent-Encoding):**  
  En las URLs, el carácter especial `@` se sustituye por su código hexadecimal: **`%40`**.  
  Por tanto, `Pepito@123@@` se escribe de forma 100% segura como:
  ```text
  Pepito%40123%40%40
  ```
* **Solución 2: Usar configuración por Objeto (Recomendado en Node.js):**  
  En lugar de meter toda la URL larga en un string, pasas cada parámetro por separado a `new pg.Client(...)`:
  ```javascript
  const client = new pg.Client({
    host: "aws-1-eu-west-1.pooler.supabase.com",
    port: 5432,
    user: "postgres.nlkfysmrygdqdjaluzch",
    password: "Pepito@123@@", // ¡Aquí la arroba no causa ningún conflicto!
    database: "postgres",
    ssl: { rejectUnauthorized: false }
  });
  ```

---

## 4. Paso 3: Crear Tablas Relacionales y Cargar Datos

Vamos a crear un modelo relacional sencillo y elegante compuesto por dos tablas: **`autores`** y **`libros`**, unidas por una relación de uno a muchos ($1:N$).

### El Modelo de Datos

```mermaid
erDiagram
    AUTORES ||--o{ LIBROS : escribe
    AUTORES {
        bigint id PK
        varchar nombre
        varchar pais
        boolean activo
        timestamp creado_en
    }
    LIBROS {
        bigint id PK
        bigint autor_id FK
        varchar titulo
        varchar genero
        numeric precio
        int paginas
        timestamp creado_en
    }
```

---

### Método 1: Usar el *Table Editor* (Interfaz visual)
Si prefieres crear las tablas con ratón y ventanas (ideal para familiarizarse):
1. En el menú lateral de Supabase, pulsa en el icono de tabla llamado **Table Editor**.
2. Haz clic en **"New table"**.
3. Nombra la tabla como `autores`.
4. Añade las columnas con sus tipos (`nombre` tipo `varchar`, `pais` tipo `varchar`).
5. Pulsa **Save**.
6. Para meter datos, pulsa en **"Insert" ➔ "Insert row"** y escribe los datos como si fuera una hoja de cálculo Excel.

---

### Método 2: Usar el *SQL Editor* (Recomendado y Profesional)
La forma más rápida, reproducible e industrial de trabajar es ejecutar sentencias SQL.

1. En el menú lateral de Supabase, pulsa en el icono **SQL Editor** (o el icono con símbolo `>_`).
2. Pulsa en **"New query"**.
3. Abre el archivo [`tablas.sql`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/tablas.sql) que hemos creado en esta misma carpeta, copia todo su contenido y pégalo en el editor:

```sql
-- 1. Crear tabla autores
CREATE TABLE autores (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    pais VARCHAR(50) NOT NULL,
    activo BOOLEAN DEFAULT true,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Crear tabla libros con clave foránea hacia autores
CREATE TABLE libros (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    autor_id BIGINT REFERENCES autores(id) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    genero VARCHAR(50) NOT NULL,
    precio NUMERIC(6, 2) NOT NULL,
    paginas INT,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Insertar autores de prueba
INSERT INTO autores (nombre, pais, activo) VALUES
('Gabriel García Márquez', 'Colombia', true),
('Jane Austen', 'Reino Unido', true),
('Haruki Murakami', 'Japón', true);

-- 4. Insertar libros asociados
INSERT INTO libros (autor_id, titulo, genero, precio, paginas) VALUES
(1, 'Cien años de soledad', 'Realismo mágico', 19.99, 471),
(1, 'El amor en los tiempos del cólera', 'Novela romántica', 15.50, 368),
(1, 'Crónica de una muerte anunciada', 'Ficción', 12.00, 144),
(2, 'Orgullo y prejuicio', 'Romance de época', 14.25, 432),
(2, 'Sentido y sensibilidad', 'Drama clásico', 13.80, 380),
(3, 'Tokio Blues (Norwegian Wood)', 'Ficción contemporánea', 18.00, 384),
(3, 'Kafka en la orilla', 'Fantasía / Misterio', 21.50, 504);
```

4. Pulsa el botón verde **"Run"** (o presiona `Cmd + Enter` en Mac).
5. En la parte inferior verás: `Success. No rows returned`.
6. ¡Listo! Si vuelves a la sección **Table Editor**, verás tus dos tablas creadas y rellenas con los 7 libros y 3 autores.

---

## 5. Paso 4: Conectar y Consultar desde Node.js

En la carpeta [`nodejs/`](databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/nodejs/) tienes un proyecto completo preparado.

### Instalación de dependencias
Abre tu terminal, sitúate en la carpeta `nodejs` e instala los paquetes necesarios:
```bash
cd "databases_flash_course/Databases_Intro/3. Postgres/6. Nube/supabase/nodejs"
npm install
```

Crea tu archivo `.env`:
```bash
cp .env.example .env
```
*(Edita el archivo `.env` con tus credenciales reales de Supabase).*

---

### Vía 1: Conexión SQL con el driver `pg` ([`app_pg.js`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/nodejs/app_pg.js))

Esta vía demuestra que **todo lo aprendido en el curso sirve exactamente igual en la nube**. Solo añadimos la directiva de cifrado `ssl`:

```javascript
import dotenv from "dotenv";
import pg from "pg";
dotenv.config();

// Creamos el cliente con la URI de Supabase y cifrado SSL obligatorio:
const client = new pg.Client({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

await client.connect();

// Hacemos una consulta con JOIN exactamente igual que en local:
const res = await client.query(`
  SELECT l.titulo, l.precio, a.nombre AS autor
  FROM libros l
  JOIN autores a ON l.autor_id = a.id
  ORDER BY l.precio DESC;
`);

console.table(res.rows);
await client.end();
```

Ejecútalo con:
```bash
npm run start:pg
```

---

### Vía 2: Conexión moderna con el SDK ([`app_supabase.js`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/nodejs/app_supabase.js))

Si estás construyendo una aplicación moderna (Next.js, Vue, React, Express API):

```javascript
import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";
dotenv.config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Consultar libros baratos sin escribir SQL en texto:
const { data, error } = await supabase
  .from("libros")
  .select("id, titulo, precio, genero")
  .lt("precio", 20);

console.table(data);
```

Ejecútalo con:
```bash
npm run start:sdk
```

---

## 6. Paso 5: Conectar y Consultar desde Python

En la carpeta [`python/`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/python/) tienes la versión para Python.

---

### 6.1 La trampa de instalación: `psycopg2` vs `psycopg2-binary`
*(Fundamento teórico: Extensiones nativas en C vs Paquetes precompilados Wheels)*

Al instalar librerías en Python mediante `pip`, uno de los errores más desconcertantes para los alumnos ocurre al ejecutar:
```bash
pip install psycopg2   # ❌ ¡Suele fallar en Mac y Linux!
```
El terminal arroja un error kilométrico que termina con:
```text
Error: pg_config executable not found.
pg_config is required to build psycopg2 from source.
```

#### ¿Por qué ocurre esto? El Fundamento Teórico:
1. **Python es interpretado, pero la red es en C:**  
   Python es un lenguaje de alto nivel muy amigable, pero comunicarse con PostgreSQL por sockets de red a velocidad extrema requiere código de muy bajo nivel. Por eso, el conector `psycopg2` no está escrito en Python puro, sino que es una **extensión nativa escrita en lenguaje C** que interactúa directamente con la librería oficial del motor de base de datos llamada `libpq`.
2. **Código Fuente (*Source Distribution / sdist*) vs Binario (*Wheel*):**  
   - El paquete llamado simplemente **`psycopg2`** se distribuye como código fuente sin compilar (archivos `.c` y `.h`).
   - Para instalarlo, tu ordenador tiene que **compilar ese código en C en ese mismo instante**.
   - Para compilar en C se necesita un compilador (`clang` en Mac o `gcc` en Linux) y los archivos de cabecera de desarrollo de PostgreSQL.
   - El programa **`pg_config`** es el configurador de PostgreSQL que le indica al compilador dónde están las librerías del sistema. Si no tienes instaladas las herramientas de desarrollo de C de Postgres en tu Mac, la compilación se detiene.
3. **La solución de ingeniería: `psycopg2-binary`:**  
   Para evitar obligar a millones de desarrolladores y científicos de datos a instalar compiladores de C y gigabytes de herramientas de desarrollo, la comunidad creó **`psycopg2-binary`**.
   - Se distribuye en formato **Wheel (`.whl`)**: paquetes **ya precompilados de fábrica** para tu procesador específico (Apple Silicon M1/M2/M3 o procesadores Intel x86_64).
   - Trae consigo una copia estática ya compilada de `libpq`.
   - Por eso en [`requirements.txt`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/python/requirements.txt) usamos siempre:
     ```text
     psycopg2-binary>=2.9.9
     ```

---

### 6.2 El estándar RFC 3986 y el colapso del parser con arrobas (`@`) en Python
*(Fundamento teórico: Caracteres reservados y codificación por porcentaje / Percent-Encoding)*

Cuando configuraste tu contraseña de base de datos con arrobas (por ejemplo: `Pepito@123@@`), al ejecutar el script de Python obtuviste este curioso error:
```text
❌ could not translate host name "123@@@aws-1-eu-west-1.pooler.supabase.com" to address: nodename nor servname provided
```

#### ¿Por qué ocurrió? El Fundamento Teórico:
1. **La gramática formal de una URI (RFC 3986):**  
   En la arquitectura de Internet, las cadenas de conexión siguen la especificación formal del IETF (RFC 3986):
   $$\text{URI} = \text{scheme} \, \text{"://"} \, [\,\text{userinfo} \, \mathbf{"@"} \,] \, \text{host} \, [\, \text{":"} \, \text{port} \,] \, \text{"/"} \, \text{database}$$
   En esta gramática, la arroba (**`@`**) es un **carácter reservado con función delimitadora sintáctica**: su misión exclusiva es marcar la frontera entre el `userinfo` (usuario y contraseña) y el `host` (la máquina remota).
2. **El analizador sintáctico de `psycopg2`:**  
   `psycopg2` se apoya en la función C de bajo nivel `PQconnectdb` de PostgreSQL. Al analizar tu cadena de texto:
   `postgresql://postgres.id:Pepito@123@@@aws-1-eu-west-1.pooler.supabase.com...`
   el algoritmo de parsing lee de izquierda a derecha y se encuentra la primera `@` inmediatamente después de `Pepito`.
   Asume automáticamente:
   - **Contraseña:** `Pepito`
   - **Host:** `123@@@aws-1-eu-west-1.pooler.supabase.com`
   Al intentar buscar un servidor llamado `123@@@...`, el sistema de resolución de nombres colapsa.
3. **La necesidad matemática del *Percent-Encoding*:**  
   El estándar RFC 3986 establece que cuando un carácter reservado deba formar parte del *dato en sí* y no de la *sintaxis*, debe reemplazarse por el símbolo `%` seguido de su código numérico ASCII en base hexadecimal.
   - En la tabla ASCII, la arroba `@` tiene el código decimal 64.
   - 64 en base hexadecimal es **`40`** ($4 \times 16^1 + 0 \times 16^0 = 64$).
   - Por tanto, `@` se traduce en **`%40`**.
   Al escribir `Pepito%40123%40%40`:
   - El parser de la URI ve una única arroba sintáctica: la que separa el host.
   - El motor de PostgreSQL decodifica `%40` internamente y recupera la contraseña original `Pepito@123@@` de forma transparente y sin ambigüedades.

---

### 6.3 La regla de oro relacional: Violación de clave foránea (Foreign Key Violation)
*(Fundamento teórico: Integridad referencial del modelo relacional de Edgar F. Codd)*

Cuando ejecutamos por primera vez la consulta de inserción de un libro:
```javascript
// En app_pg.js:
const nuevoLibro = {
  autor_id: 1, // Gabriel García Márquez
  titulo: "Relato de un náufrago",
  ...
};
```
PostgreSQL detuvo la operación en seco con el error:
```text
❌ insert or update on table "libros" violates foreign key constraint "libros_autor_id_fkey"
DETAIL: Key (autor_id)=(1) is not present in table "autores".
```

#### ¿Por qué ocurrió? El Fundamento Teórico:
1. **Bases de datos relacionales vs Archivos sueltos:**  
   En un archivo Excel o JSON, puedes escribir un libro y decir que su autor es el "ID 1", aunque el autor 1 no exista en ninguna parte.
   En una **Base de Datos Relacional (RDBMS)**, rige el principio de **Integridad Referencial**:
   Al definir en SQL:
   ```sql
   CREATE TABLE libros (
       ...
       autor_id BIGINT REFERENCES autores(id) ON DELETE CASCADE
   );
   ```
   le ordenamos al motor de PostgreSQL que actúe como un guardián matemático estricto: **está terminantemente prohibido que exista un registro "hijo" (un libro) apuntando a un registro "padre" inexistente (un autor inexistente)**. Evita los llamados "registros huérfanos".
2. **El orden de las operaciones en bases de datos:**  
   Como la tabla `autores` estaba recién creada y vacía en Supabase, PostgreSQL protegió la coherencia de los datos rechazando el libro.
3. **La solución:**  
   En bases de datos relacionales, el orden de inserción es siempre jerárquico:
   $$\text{1. Insertar siempre primero en las Tablas Padre (Autores)} \longrightarrow \text{2. Insertar después en las Tablas Hijas (Libros)}$$

---

### Instalación de dependencias y ejecución de Python

Abre la terminal y sitúate en la carpeta `python`:
```bash
cd "/Users/fjbanezares/databases_flash_course/Databases_Intro/3. Postgres/6. Nube/supabase/python"
```

Crea tu entorno virtual e instala las dependencias:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Copia y configura tu archivo `.env`:
```bash
cp .env.example .env
```
*(Asegúrate de que en `.env` la variable `DATABASE_SES_URL` tenga tu contraseña con `%40`).*

---

### Vía 1: Conexión SQL con `psycopg2` ([`app_psycopg2.py`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/python/app_psycopg2.py))

`psycopg2` es el estándar en Python para ciencia de datos, análisis con Pandas y frameworks backend (Django, FastAPI, Flask):

```python
import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# Lee DATABASE_SES_URL o DATABASE_URL
db_url = os.getenv("DATABASE_SES_URL") or os.getenv("DATABASE_URL")

# Conexión con sslmode obligatorio para la nube
conn = psycopg2.connect(db_url, sslmode="require")
cur = conn.cursor()

# Ejecutar consulta con JOIN
cur.execute("""
    SELECT l.titulo, l.precio, a.nombre 
    FROM libros l 
    JOIN autores a ON l.autor_id = a.id
    ORDER BY l.precio ASC;
""")

for fila in cur.fetchall():
    print(f"📖 {fila[0]} ({fila[1]}€) - Autor: {fila[2]}")

cur.close()
conn.close()
```

Ejecútalo con:
```bash
python3 app_psycopg2.py
```

---

### Vía 2: Conexión con el SDK de Python ([`app_supabase.py`](file:///Users/fjbanezares/databases_flash_course/Databases_Intro/3.%20Postgres/6.%20Nube/supabase/python/app_supabase.py))

```python
import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()
supabase = create_client(os.getenv("SUPABASE_URL"), os.getenv("SUPABASE_ANON_KEY"))

# Consulta con la API de Supabase
respuesta = supabase.table("libros").select("titulo, precio, genero").execute()

for libro in respuesta.data:
    print(f"• {libro['titulo']} - {libro['precio']}€")
```

Ejecútalo con:
```bash
python3 app_supabase.py
```

---

## 7. Seguridad en la Nube: ¿Qué es RLS (*Row Level Security*)?

Cuando trabajas en local, cualquier cliente con la contraseña accede a todo. En la nube, sin embargo, existe un concepto vital llamado **RLS (Seguridad a Nivel de Fila)**.

> [!WARNING]
> **¿Por qué el SDK devuelve un array vacío `[]` aunque haya datos en la tabla?**  
> Si consultas mediante `@supabase/supabase-js` o `supabase-py` usando la clave pública `anon` y no recibes datos, es porque Supabase tiene activado **RLS** por defecto para proteger la tabla contra accesos no autorizados.

### ¿Cómo habilitar lectura pública para nuestras prácticas de aprendizaje?
En el **SQL Editor** de Supabase, ejecuta estas dos líneas para permitir que cualquiera pueda leer las tablas de muestra:

```sql
-- Permitir lectura pública de autores
ALTER TABLE autores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura publica de autores" ON autores FOR SELECT USING (true);

-- Permitir lectura pública de libros
ALTER TABLE libros ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lectura publica de libros" ON libros FOR SELECT USING (true);
```

*(Nota: Si usas la conexión SQL directa con `pg` o `psycopg2` identificándote como usuario `postgres`, RLS no te bloquea porque eres el superadministrador de la base de datos).*

---

## 8. 💡 Lo que se extrae de esta práctica (Puntos Clave)

<div style="background-color: #f0fdf4; border: 2px solid #22c55e; padding: 22px; border-radius: 8px; margin: 24px 0;">

### 🟢 Conclusiones y Aprendizajes Extraídos

1. **La Nube no cambia las reglas de SQL:**  
   PostgreSQL en Supabase sigue siendo PostgreSQL. Las consultas `SELECT`, las claves foráneas (`FOREIGN KEY`), los `JOIN` y los índices funcionan exactamente igual que en local. Lo único que cambia es el **Host** (remoto en lugar de `localhost`) y la necesidad obligatoria de cifrado **SSL**.

2. **Doble modalidad de consumo:**  
   - Si vienes del mundo relacional puro o necesitas análisis pesado: usa conexiones SQL estándar con **`pg`** (Node.js) o **`psycopg2`** (Python).
   - Si estás creando interfaces web modernas o móviles: usa el **SDK de Supabase**, que simplifica el desarrollo y transforma consultas en objetos JSON limpios.

3. **Seguridad profesional con `.env`:**  
   Jamás se deben escribir contraseñas ni URLs de conexión directamente dentro de los archivos `.js` o `.py`. El uso de variables de entorno y archivos `.env` (añadidos a `.gitignore`) es la regla número 1 en el desarrollo de software seguro.

4. **El valor del aprovisionamiento instantáneo:**  
   Crear un servidor en la nube hace pocos años requería horas de configuración de terminal en Linux, cortafuegos e instalación manual de paquetes. Herramientas modernas como Supabase o Neon permiten tener una base de datos de producción lista para usar en menos de 2 minutos.

</div>
