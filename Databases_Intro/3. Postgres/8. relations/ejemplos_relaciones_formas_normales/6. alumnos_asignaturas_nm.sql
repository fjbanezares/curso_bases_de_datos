/* N:M DESDE CERO · PostgreSQL · Ejecutar por secciones en una base de pruebas.
   No requiere los ejercicios anteriores. No usa DO ni PL/pgSQL.
   Sintaxis comprobada; no ejecutado en un servidor en este entorno.
   Los resultados comentados son los esperados.

   Regla: una matrícula por pareja alumno/asignatura. Sin años ni reintentos.
   Cada alumno puede tener cero o más asignaturas y viceversa.
   La nota puede ser NULL: matriculado, pero sin nota todavía.

   Una fila de alumnos = una persona.
   Una fila de asignaturas = una materia.
   Una fila de matriculas = el hecho de que una persona cursa una materia.

   El modelo conceptual N:M se implementa mediante dos relaciones 1:N.
   Mermaid (texto para un visor de diagramas, no SQL):
   erDiagram
     ALUMNOS ||--o{ MATRICULAS : tiene
     ASIGNATURAS ||--o{ MATRICULAS : recibe
     MATRICULAS {
       integer alumno_id PK,FK
       integer asignatura_id PK,FK
       numeric nota
     }

   Si el esquema nm_practica ya existe, el script se detiene por error.
   Ejecuta ROLLBACK y usa otra base o cambia el nombre del esquema.
*/
BEGIN;
CREATE SCHEMA nm_practica;
SET LOCAL search_path TO nm_practica, pg_catalog;

-- 00 · LAS DOS ENTIDADES
CREATE TABLE alumnos (
  id integer PRIMARY KEY,
  nombre text NOT NULL
);
CREATE TABLE asignaturas (
  id integer PRIMARY KEY,
  titulo text NOT NULL
);
INSERT INTO alumnos VALUES (1,'Ana'),(2,'Bruno'),(3,'Carla'),(4,'Diego');
INSERT INTO asignaturas VALUES (101,'SQL'),(102,'Modelado'),(103,'Redes');

-- 10 · LO QUE FALTA: SABER QUIÉN CURSA QUÉ
-- Poner asignatura_id en alumnos permitiría solo una asignatura por alumno.
-- Poner alumno_id en asignaturas permitiría solo un alumno por asignatura.
-- Crear asignatura_1, asignatura_2... impone un límite artificial.
-- Guardar '101,102' como texto hace más difícil validar y consultar cada vínculo.
-- En un modelo relacional normalizado, usamos una fila por vínculo.
-- No es que SQL prohíba listas; PostgreSQL admite arrays/JSON, pero aquí
-- queremos claves y referencias verificables para cada matrícula.

CREATE TABLE matriculas (
  alumno_id integer REFERENCES alumnos(id),
  asignatura_id integer REFERENCES asignaturas(id),
  nota numeric(4,2) CHECK (nota BETWEEN 0 AND 10),
  PRIMARY KEY (alumno_id, asignatura_id)
);
-- PK compuesta: la PAREJA no puede repetirse; sus dos columnas no admiten NULL.
-- alumno_id sí puede repetirse. asignatura_id también. La pareja completa no.
-- Dos FK impiden matrículas que apunten a alumnos o asignaturas inexistentes.
-- El CHECK acepta NULL: aquí significa nota aún no registrada, no cero.
-- La nota pertenece a la matrícula: Ana puede tener distinta nota en cada materia.

INSERT INTO matriculas VALUES
 (1,101,8), (1,102,9), (2,101,7), (3,102,NULL);
SELECT * FROM matriculas ORDER BY alumno_id, asignatura_id;
-- 4 vínculos, no las 4 x 3 = 12 combinaciones posibles.

-- 20 · EXPLORAR UN EXTREMO SIN JOIN: SOLO IDENTIFICADORES
SELECT asignatura_id FROM matriculas WHERE alumno_id = 1
ORDER BY asignatura_id; -- Ana: 101 y 102.
SELECT alumno_id FROM matriculas WHERE asignatura_id = 101
ORDER BY alumno_id; -- SQL: Ana (1) y Bruno (2).

-- 30 · UN JOIN: AÑADIR EL NOMBRE DEL OTRO EXTREMO
SELECT s.id, s.titulo
FROM matriculas m
JOIN asignaturas s ON s.id = m.asignatura_id
WHERE m.alumno_id = 1 ORDER BY s.id;
-- 101/SQL y 102/Modelado. Ya conocemos al alumno: no necesitamos alumnos.

SELECT a.id, a.nombre
FROM matriculas m
JOIN alumnos a ON a.id = m.alumno_id
WHERE m.asignatura_id = 101 ORDER BY a.id;
-- 1/Ana y 2/Bruno. Mismo puente recorrido en sentido contrario.

-- 40 · DOS JOIN: EL INFORME CON AMBOS NOMBRES
SELECT a.nombre, s.titulo, m.nota
FROM matriculas m
JOIN alumnos a ON a.id = m.alumno_id
JOIN asignaturas s ON s.id = m.asignatura_id
ORDER BY a.id, s.id;
-- Ana/SQL/8, Ana/Modelado/9, Bruno/SQL/7, Carla/Modelado/NULL.
-- Cada matrícula encuentra UNA PK de alumno y UNA PK de asignatura.
-- Por eso obtenemos cuatro filas, una por vínculo: no un producto cartesiano.

-- Mostrar que JOIN añade columnas paso a paso:
SELECT m.alumno_id, m.asignatura_id, a.nombre
FROM matriculas m JOIN alumnos a ON a.id = m.alumno_id
ORDER BY m.alumno_id, m.asignatura_id;
-- Aún tenemos cuatro filas; ahora cada una incluye el nombre del alumno.

-- ERROR CONCEPTUAL: relacionar a.id = s.id no representa una matrícula.
-- Los identificadores de entidades distintas no expresan por sí solos vínculo.
SELECT a.nombre, s.titulo
FROM alumnos a CROSS JOIN asignaturas s ORDER BY a.id, s.id;
-- CROSS JOIN produce 12 combinaciones. No afirma que estén matriculados.

-- 50 · LEFT JOIN: CONSERVAR A QUIEN NO TIENE VÍNCULOS
SELECT a.nombre, s.titulo, m.nota
FROM alumnos a
LEFT JOIN matriculas m ON m.alumno_id = a.id
LEFT JOIN asignaturas s ON s.id = m.asignatura_id
ORDER BY a.id, s.id;
-- 5 filas: las cuatro matrículas + Diego/NULL/NULL.
-- Los DOS LEFT JOIN conservan la rama opcional. Un INNER JOIN al final
-- quitaría a Diego, porque no hay asignatura coincidente.

SELECT a.id, a.nombre
FROM alumnos a
LEFT JOIN matriculas m ON m.alumno_id = a.id
WHERE m.alumno_id IS NULL ORDER BY a.id;
-- Diego: no tiene matrícula. Comprobamos una clave, no la nota.
-- Carla tiene matrícula aunque su nota sea NULL.

SELECT s.id, s.titulo
FROM asignaturas s
LEFT JOIN matriculas m ON m.asignatura_id = s.id
WHERE m.asignatura_id IS NULL ORDER BY s.id;
-- Redes: ningún alumno matriculado.

-- ¿Quién no está matriculado en SQL, incluyendo quienes no cursan nada?
SELECT a.id, a.nombre
FROM alumnos a
LEFT JOIN matriculas m ON m.alumno_id = a.id AND m.asignatura_id = 101
WHERE m.alumno_id IS NULL ORDER BY a.id;
-- Carla y Diego. El filtro de la asignatura va dentro del ON.

-- 60 · UNA FILA POR ALUMNO: AGRUPAR, NO PONER LIMIT 1
SELECT a.id, a.nombre, COUNT(m.asignatura_id) AS asignaturas
FROM alumnos a LEFT JOIN matriculas m ON m.alumno_id = a.id
GROUP BY a.id, a.nombre ORDER BY a.id;
-- Ana 2; Bruno 1; Carla 1; Diego 0.
-- COUNT(*) daría 1 para Diego por la fila de extensión NULL del LEFT JOIN.
-- LIMIT 1 devolvería una fila total, no una fila por alumno.

SELECT s.id, s.titulo, COUNT(m.alumno_id) AS alumnos,
       COUNT(m.nota) AS notas_registradas, AVG(m.nota) AS media
FROM asignaturas s LEFT JOIN matriculas m ON m.asignatura_id = s.id
GROUP BY s.id, s.titulo ORDER BY s.id;
-- SQL: 2 alumnos, 2 notas, media 7.5.
-- Modelado: 2 alumnos, 1 nota, media 9 (NULL no participa).
-- Redes: 0 alumnos, 0 notas, media NULL.

-- 70 · ÍNDICES Y REGLAS DIFERENTES
-- La PK ya crea un índice único sobre (alumno_id, asignatura_id).
-- Su orden ayuda especialmente a búsquedas que empiezan por alumno_id.
CREATE INDEX idx_matriculas_asignatura ON matriculas(asignatura_id);
-- Añadimos un acceso para buscar alumnos de una asignatura.
-- El motor decide si lo usa; con cuatro filas probablemente recorrerá la tabla.
-- Un índice ocupa espacio y añade mantenimiento al escribir.
-- La FK define integridad; el índice facilita acceso. No son lo mismo.

-- Estas instrucciones fallarían. Están comentadas para no parar el recorrido:
-- INSERT INTO matriculas VALUES (1,101,10); -- pareja duplicada (PK).
-- INSERT INTO matriculas VALUES (99,101,8); -- alumno inexistente (FK).
-- INSERT INTO matriculas VALUES (4,103,11); -- nota fuera de rango (CHECK).

-- 80 · MODIFICAR EL VÍNCULO, NO LAS ENTIDADES
SAVEPOINT antes_de_practicar;
INSERT INTO matriculas VALUES (4,103,NULL); -- Diego empieza Redes.
UPDATE matriculas SET nota = 6
WHERE alumno_id = 4 AND asignatura_id = 103;
DELETE FROM matriculas WHERE alumno_id = 1 AND asignatura_id = 102;
-- Ana deja Modelado. No borramos ni a Ana ni la asignatura Modelado.
SELECT * FROM matriculas ORDER BY alumno_id, asignatura_id;
ROLLBACK TO SAVEPOINT antes_de_practicar;
RELEASE SAVEPOINT antes_de_practicar;
-- Volvemos a los cuatro vínculos originales.
-- Borrar un alumno con matrículas se rechaza con estas FK: no definimos CASCADE.

-- 90 · OCULTAR LOS JOIN CON UNA VISTA (NO COPIA LOS DATOS)
CREATE VIEW informe_matriculas AS
SELECT a.id AS alumno_id, a.nombre, s.id AS asignatura_id, s.titulo, m.nota
FROM matriculas m
JOIN alumnos a ON a.id = m.alumno_id
JOIN asignaturas s ON s.id = m.asignatura_id;
SELECT nombre, titulo FROM informe_matriculas WHERE alumno_id = 1
ORDER BY asignatura_id;

-- 100 · QUÉ CAMBIARÍA CON OTRAS REGLAS
-- Si un alumno repite materia en otro año, la pareja ya no identifica el hecho:
-- podríamos usar PK(alumno_id, asignatura_id, curso_academico).
-- Si existen varios intentos por curso, también hay que modelar el intento.
-- Una PK artificial matricula_id es válida, pero hay que conservar un UNIQUE
-- sobre la combinación que el negocio considere irrepetible.

COMMIT;
-- Para consultar después: SELECT * FROM nm_practica.informe_matriculas;

/* PORTABILIDAD
No utilizamos PL/pgSQL: CREATE TABLE, INSERT, JOIN, GROUP BY, CASE y las FK
son conceptos compartidos por PostgreSQL, MySQL y Oracle.
Este archivo está preparado específicamente para PostgreSQL:
- SET LOCAL search_path y este manejo de esquemas no se trasladan sin cambios.
- MySQL suele usar una base seleccionada con USE; para FK, tablas InnoDB.
  Su DDL puede provocar commits implícitos: no copies el envoltorio transaccional.
- Oracle usa esquemas asociados a usuarios y suele declarar NUMBER/VARCHAR2;
  su DDL también realiza commits implícitos. Adapta tipos y carga de datos
  a la versión; varios INSERT individuales son una opción portable.
- Si necesitáramos IF procedural: PostgreSQL usa PL/pgSQL (DO $$ ... $$);
  Oracle tiene bloques PL/SQL DECLARE/BEGIN/END; MySQL usa IF en programas
  almacenados, no ese DO de PostgreSQL. CASE dentro de SELECT es otra cosa.

MONGODB
Consulta el archivo alumnos_asignaturas_mongodb.js adjunto: es JavaScript
para mongosh, NO SQL. Reproduce los mismos datos y explica $lookup.

Fuentes:
https://www.postgresql.org/docs/current/ddl-constraints.html
https://www.postgresql.org/docs/current/queries-table-expressions.html
https://www.mongodb.com/docs/manual/data-modeling/
*/
