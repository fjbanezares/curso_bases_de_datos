# Práctica Guiada: SQL vs NoSQL con Docker 🐳

¡Bienvenido/a a esta práctica guiada! En este laboratorio vas a aprender, desde cero y de forma 100% práctica, cómo funcionan y en qué se diferencian una **Base de Datos Relacional (SQL)** y una **Base de Datos No Relacional (NoSQL)**.

Para ello, utilizaremos **Docker**, una tecnología que nos permite ejecutar cualquier base de datos en cuestión de segundos dentro de nuestro ordenador sin instalar nada raro ni ensuciar el sistema operativo.

---

## 📌 Índice
1. [Requisitos Previos: Instalación y Verificación de Docker](#-paso-0-instalación-y-verificación-de-docker)
2. [Paso 1: Despliegue de los Contenedores (SQL y NoSQL)](#-paso-1-despliegue-de-los-contenedores)
3. [Paso 2: Práctica en SQL (PostgreSQL)](#-paso-2-práctica-en-sql-postgresql)
4. [Paso 3: Práctica en NoSQL (MongoDB)](#-paso-3-práctica-en-nosql-mongodb)
5. [Paso 4: Resumen Comparativo (SQL vs NoSQL)](#-paso-4-resumen-comparativo)
6. [Paso 5: Limpieza del Entorno](#-paso-5-limpieza-del-entorno)

---

## 🛠️ Paso 0: Instalación y Verificación de Docker

Antes de empezar, necesitamos tener **Docker** listo en nuestro equipo.

### ¿Qué es Docker?
Imagínate que Docker es una fábrica de "cajas aisladas" llamadas **contenedores**. Cada contenedor tiene su propio programa (como PostgreSQL o MongoDB) funcionando independientemente con todo lo necesario para ejecutarse, sin importar si estás en Windows, Mac o Linux.

### Instalación según tu sistema operativo:

- **Windows / macOS**:
  1. Descarga **Docker Desktop** desde el sitio web oficial: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
  2. Ejecuta el instalador y sigue los pasos por defecto (en Windows, mantén marcada la opción WSL 2).
  3. Abre la aplicación **Docker Desktop** y espera a que el icono se ponga en verde/activo.

- **Linux (Ubuntu/Debian)**:
  Ejecuta los siguientes comandos en tu terminal:
  ```bash
  sudo apt update
  sudo apt install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  ```

### Verificación del entorno
Abre tu terminal (PowerShell/CMD en Windows, Terminal en macOS/Linux) y escribe:

```bash
docker --version
```

🔍 **En qué fijarse:**
- Si el comando devuelve algo como `Docker version 27.x.x, build ...`, ¡estás listo!
- Si da error de "comando no encontrado" o "daemon not running", asegúrate de haber abierto la aplicación **Docker Desktop**.

---

## 🚀 Paso 1: Despliegue de los Contenedores

Vamos a arrancar un motor **PostgreSQL** (SQL) y un motor **MongoDB** (NoSQL).

### 1. Levantar el servidor SQL (PostgreSQL)

Ejecuta en tu terminal el siguiente comando:

```bash
docker run -d --name postgres_lab -e POSTGRES_PASSWORD=mi_secreto -p 5432:5432 postgres:16-alpine
```

💬 **Explicación didáctica línea por línea:**
- `docker run`: Le dice a Docker que cree y arranque un nuevo contenedor.
- `-d`: (Detached mode) Ejecuta el contenedor en segundo plano para no bloquear tu consola.
- `--name postgres_lab`: Asigna un nombre amigable al contenedor (`postgres_lab`) para referirnos a él fácilmente.
- `-e POSTGRES_PASSWORD=mi_secreto`: Define una variable de entorno (`-e`) con la contraseña de administración del superusuario `postgres`.
- `-p 5432:5432`: Mapea los puertos. El primer `5432` es el puerto de tu ordenador local y el segundo `5432` es el puerto dentro del contenedor.
- `postgres:16-alpine`: Es la **imagen oficial** que Docker descargará. Usamos la versión `16-alpine` por ser ultraligera.

---

### 2. Levantar el servidor NoSQL (MongoDB)

Ejecuta en tu terminal el siguiente comando:

```bash
docker run -d --name mongodb_lab -p 27017:27017 mongo:latest
```

💬 **Explicación didáctica línea por línea:**
- `docker run -d`: Crea y ejecuta en segundo plano.
- `--name mongodb_lab`: Le da el nombre `mongodb_lab` a este contenedor.
- `-p 27017:27017`: Redirige el puerto estándar de MongoDB (`27017`) de tu máquina al contenedor.
- `mongo:latest`: Descarga e inicia la versión más reciente de la imagen oficial de MongoDB.

---

### 3. Comprobar que ambos contenedores están corriendo

Ejecuta:

```bash
docker ps
```

🔍 **En qué fijarse:**
- Verás una tabla en la consola. Debes confirmar que en la columna `STATUS` de `postgres_lab` y `mongodb_lab` aparece `Up ... seconds/minutes`.

---

## 📊 Paso 2: Práctica en SQL (PostgreSQL)

En las bases de datos relacionales (SQL), **el esquema se define por adelantado**. Las tablas tienen columnas estrictas y las relaciones entre datos se gestionan mediante **Claves Primarias (Primary Keys)** y **Claves Foráneas (Foreign Keys)**.

### Escenario de ejemplo: Autores y Libros (Relación 1 a N)
Un **Autor** puede escribir **muchos Libros**, pero cada **Libro** pertenece a un **único Autor**.

---

### 1. Entrar en la consola interactiva de PostgreSQL (`psql`)

Ejecuta el siguiente comando para abrir el terminal propio de PostgreSQL dentro del contenedor:

```bash
docker exec -it postgres_lab psql -U postgres
```

💬 **Explicación:**
- `docker exec`: Ejecuta un comando dentro de un contenedor en ejecución.
- `-it`: Combina `-i` (interactivo) y `-t` (asigna una terminal TTY). Nos permite escribir comandos e interactuar como si tuviéramos un terminal dentro del contenedor.
- `postgres_lab`: El nombre del contenedor objetivo.
- `psql -U postgres`: Abre el cliente oficial de PostgreSQL con el usuario por defecto `postgres`.

Deberías ver un prompt similar a: `postgres=#`

---

### 2. Crear las tablas con restricciones de relación

Copia y pega este bloque de código SQL:

```sql
-- 1. Crear la tabla de Autores
CREATE TABLE autores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    pais VARCHAR(50)
);

-- 2. Crear la tabla de Libros relacionada con Autores
CREATE TABLE libros (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    precio NUMERIC(6, 2),
    autor_id INT REFERENCES autores(id) ON DELETE CASCADE
);
```

💬 **Explicación didáctica línea por línea:**
- `CREATE TABLE autores`: Define una nueva estructura de tabla nombrada `autores`.
- `id SERIAL PRIMARY KEY`: 
  - `SERIAL`: Genera un entero numérico que se autoincrementa automáticamente (1, 2, 3...).
  - `PRIMARY KEY`: Identificador único e irrepetible para cada autor.
- `nombre VARCHAR(100) NOT NULL`: Cadena de texto de hasta 100 caracteres. `NOT NULL` exige que no se pueda guardar un autor sin nombre.
- `autor_id INT REFERENCES autores(id)`: **¡La Clave Foránea (Foreign Key)!** Indica que el valor de la columna `autor_id` debe existir previamente en la columna `id` de la tabla `autores`.
- `ON DELETE CASCADE`: Si borramos un autor, PostgreSQL eliminará automáticamente todos sus libros asociados para evitar mantener datos huérfanos.

---

### 3. Insertar datos en la base de datos SQL

```sql
-- Insertar 2 autores
INSERT INTO autores (nombre, pais) VALUES 
('Gabriel García Márquez', 'Colombia'),
('George Orwell', 'Reino Unido');

-- Consultar los IDs asignados a los autores
SELECT * FROM autores;
```

📌 Deberías ver que Gabriel tiene `id = 1` y George tiene `id = 2`.

Ahora insertamos los libros asociados a sus respectivos `autor_id`:

```sql
INSERT INTO libros (titulo, precio, autor_id) VALUES 
('Cien años de soledad', 19.99, 1),
('El amor en los tiempos del cólera', 15.50, 1),
('1984', 12.00, 2);
```

---

### 4. Intentar romper la regla de integridad referencial (Prueba de error)

¿Qué pasa si intentamos guardar un libro de un autor con `autor_id = 99` que NO existe?

```sql
INSERT INTO libros (titulo, precio, autor_id) VALUES ('Libro Fantasma', 10.00, 99);
```

🛑 **Resultado esperado:**
PostgreSQL lanzará un error explícito:
`ERROR: insert or update on table "libros" violates foreign key constraint...`

🔍 **En qué fijarse:**
- El motor SQL protege la **Integridad Referencial**. Es imposible guardar datos cruzados inconsistentes o huérfanos.

---

### 5. Consultar los datos uniendo las tablas (`JOIN`)

Para obtener el título del libro junto con el nombre del autor, debemos usar una operación `JOIN`:

```sql
SELECT 
    libros.id AS libro_id,
    libros.titulo,
    libros.precio,
    autores.nombre AS autor,
    autores.pais
FROM libros
JOIN autores ON libros.autor_id = autores.id;
```

💬 **Explicación:**
`JOIN autores ON libros.autor_id = autores.id`: Cruza en tiempo de ejecución cada fila de la tabla `libros` con la fila correspondiente en `autores` donde coincida la clave.

---

### 6. Salir de PostgreSQL
Escribe el comando:
```sql
\q
```

---

## 🍃 Paso 3: Práctica en NoSQL (MongoDB)

En las bases de datos NoSQL basadas en documentos (como MongoDB), **no existen tablas fijas ni consultas `CREATE TABLE` previamente definidas**. Las estructuras son dinámicas y se almacenan en formato JSON/BSON.

Existen dos estrategias principales para manejar relaciones en NoSQL:
1. **Documentos Anidados (Embedding)**.
2. **Referencias de ID (Referencing)**.

---

### 1. Entrar en la consola interactiva de MongoDB (`mongosh`)

Ejecuta en tu terminal:

```bash
docker exec -it mongodb_lab mongosh
```

Deberías ver una consola con el prompt `test>`.

Crea/Cambia a una base de datos llamada `libreria_nosql`:

```javascript
use libreria_nosql
```

---

### Estrategia A: Documentos Anidados (Embedding / Denormalización)

En NoSQL, si los libros siempre se consultan junto con el autor, **podemos guardar los libros dentro del mismo documento del autor** como una lista/array.

```javascript
db.autores_anidados.insertOne({
    nombre: "Gabriel García Márquez",
    pais: "Colombia",
    libros: [
        { titulo: "Cien años de soledad", precio: 19.99 },
        { titulo: "El amor en los tiempos del cólera", precio: 15.50 }
    ]
});
```

💬 **Explicación didáctica línea por línea:**
- `db.autores_anidados`: MongoDB crea automáticamente la colección `autores_anidados` si no existe al hacer la primera inserción. ¡Sin `CREATE TABLE`!
- `insertOne({...})`: Inserta un objeto JSON/BSON.
- `libros: [...]`: Los datos de la relación (Libros) están incrustados directamente dentro del documento principal.

#### Consulta en Documentos Anidados:
```javascript
db.autores_anidados.find({ nombre: "Gabriel García Márquez" }).pretty();
```

🔍 **En qué fijarse en la Estrategia A:**
- **Súper rápido para lecturas:** Obtienes el autor y todos sus libros con **1 sola petición** y sin necesidad de operaciones `JOIN`.
- **Desventaja:** Si la lista de libros creciera a miles de elementos, el documento se volvería gigante.

---

### Estrategia B: Referencias (Referencing / Normalización)

Si queremos tener colecciones independientes (una de autores y otra de libros), guardamos el ID del autor como referencia.

```javascript
// 1. Insertar autor y guardar su ID automático
var idAutor = db.autores.insertOne({
    nombre: "George Orwell",
    pais: "Reino Unido"
}).insertedId;

// 2. Insertar libro usando el ID del autor como referencia
db.libros.insertOne({
    titulo: "1984",
    precio: 12.00,
    autor_id: idAutor
});
```

💬 **Explicación:**
- MongoDB asigna automáticamente un `_id` de tipo `ObjectId("...")` a cada documento.
- Guardamos manualmente la referencia `autor_id: idAutor` en el libro.

#### Consulta cruzada con Aggregation (`$lookup`)
Como en NoSQL no hay un `JOIN` tradicional, usamos una **tubería de agregación (aggregation pipeline)** con `$lookup`:

```javascript
db.libros.aggregate([
    {
        $lookup: {
            from: "autores",          // Colección a unir
            localField: "autor_id",   // Campo de esta colección (libros)
            foreignField: "_id",     // Campo de la otra colección (autores)
            as: "datos_autor"         // Nombre del campo resultado
        }
    }
]);
```

🔍 **En qué fijarse en la Estrategia B:**
- MongoDB permite guardar cualquier documento sin validar si `autor_id` existe o no en la colección `autores`. **No existe restricción física de clave foránea** en el motor a nivel de esquema por defecto.

---

### 2. Salir de MongoDB
Escribe:
```javascript
exit
```

---

## ⚖️ Paso 4: Resumen Comparativo

Al finalizar las dos prácticas, podemos resumir las diferencias fundamentales en esta tabla:

| Criterio | SQL (PostgreSQL) 🐘 | NoSQL (MongoDB) 🍃 |
| :--- | :--- | :--- |
| **Definición de Esquema** | Rígido. Obligatorio definir `CREATE TABLE` previo. | Flexible / Dinámico. Se crea al insertar datos. |
| **Estructura de Datos** | Tablas con Filas y Columnas. | Documentos JSON / BSON. |
| **Relaciones entre Datos** | Claves Primarias y Foráneas (`FOREIGN KEY`). | Documentos Anidados (Embedding) o Referencias por ID. |
| **Integridad Referencial** | Garantizada por la Base de Datos (Strict). | Gestionada por la aplicación (Software). |
| **Consultas Complejas** | Nativa y potente con `JOIN`. | Mediante `$lookup` o consultas separadas. |
| **Caso de Uso Ideal** | Sistemas transaccionales, bancarios, ERPs (donde la inconsistencia no es tolerable). | Catálogos, IoT, Big Data, prototipado rápido o estructuras cambiantes. |

---

## 🧹 Paso 5: Limpieza del Entorno

Cuando hayas terminado la práctica, es una buena costumbre detener y eliminar los contenedores creados para liberar recursos en memoria RAM y CPU de tu equipo.

Ejecuta en tu terminal:

```bash
# 1. Detener los contenedores en ejecución
docker stop postgres_lab mongodb_lab

# 2. Eliminar los contenedores
docker rm postgres_lab mongodb_lab
```

¡Felicidades! 🎉 Has completado con éxito la práctica y ahora entiendes cómo funcionan las relaciones de datos en entornos SQL y NoSQL con Docker.
