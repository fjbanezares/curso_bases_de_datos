/*
NORMALIZACIÓN DE 0 A 100 · PostgreSQL 14 o posterior
=================================================
OBJETIVO: ver los mismos hechos antes y después de 1NF, 2NF y 3NF.
VALIDACIÓN: sintaxis de 102 sentencias SQL y 3 bloques PL/pgSQL comprobada
con el parser de PostgreSQL (pglast). No ejecutado en un servidor PostgreSQL
en este entorno. El recorrido incluye comprobaciones de equivalencia que
se ejecutarán al correrlo; los resultados comentados son los esperados.
Ejecuta por secciones o todo seguido en una base de PRUEBAS.
En psql: psql -v ON_ERROR_STOP=1 -d tu_base -f tutorial_normalizacion_0_a_100.sql
En un editor, selecciona cada consulta para ver su resultado individual.

SEGURIDAD Y USO
- Crea únicamente el esquema nuevo nf_laboratorio y sus objetos.
- No contiene DROP ni modifica tablas ajenas.
- Si el esquema ya existe, CREATE SCHEMA falla. No sigas ejecutando:
  termina la transacción con ROLLBACK; usa una base nueva o cambia el nombre
  del esquema en CREATE SCHEMA y SET LOCAL search_path.
- BEGIN/COMMIT hacen que el recorrido completo sea una transacción.
- Las demostraciones peligrosas se revierten con SAVEPOINT.
- Si aparece un error inesperado, ejecuta ROLLBACK.
- Los cuatro modelos coexisten SOLO para comparar. Una aplicación real
  no debe mantener estas cuatro copias como fuentes independientes.

REGLAS DEL NEGOCIO (de aquí salen las dependencias)
1. Una inscripción = un alumno en una asignatura. No hay años ni reintentos.
2. Una sola calificación final por pareja alumno/asignatura, de 0 a 10.
3. Cada alumno tiene un nombre actual y pertenece a un departamento.
4. Un departamento tiene un nombre actual; muchos alumnos pueden compartirlo.
5. Una asignatura tiene un título actual; muchos alumnos pueden cursarla.
6. Los nombres NO son únicos: dos personas pueden llamarse igual.
7. Las inscripciones de este ejemplo ya tienen nota. No modelamos pendientes.

VOCABULARIO
PK: identifica una fila, sin repeticiones ni NULL.
FK: referencia una clave de otra tabla; comprueba que el destino exista.
Clave candidata: conjunto MÍNIMO que identifica una fila.
Dependencia X -> Y: si dos filas tienen el mismo X, deben tener el mismo Y.
No implica que Y no cambie con el tiempo: hablamos del mismo estado actual.

DIAGRAMAS
Los bloques erDiagram de los comentarios son Mermaid: puedes copiarlos
en un visor Mermaid. Son diagramas conceptuales, NO instrucciones SQL.
Los sufijos s0, s1, s2, s3 identifican la etapa del modelo.
La optionalidad representada es la de las FK: un padre puede no tener hijos.
*/

BEGIN;
CREATE SCHEMA nf_laboratorio;
SET LOCAL search_path TO nf_laboratorio, pg_catalog;

-- 00 · UNA FILA POR ALUMNO, CON SUS INSCRIPCIONES DENTRO
-- ---------------------------------------------------
/*
Modelo inicial:
erDiagram
  ALUMNOS_S0 {
    integer alumno_id PK
    text alumno_nombre
    integer departamento_id
    text departamento_nombre
    jsonb inscripciones
  }

La columna JSON contiene un grupo repetido de inscripciones.
Según la interpretación clásica de 1NF para estos hechos, necesitamos
un valor por atributo y una fila por inscripción, no una lista dentro.
PostgreSQL admite JSON y arrays como tipos: esto NO es un error de SQL.
La atomicidad depende del dominio; aquí queremos consultar y restringir
cada inscripción de forma independiente, y por eso la extraemos.
*/
CREATE TABLE alumnos_s0 (
  alumno_id integer PRIMARY KEY,
  alumno_nombre text NOT NULL,
  departamento_id integer NOT NULL,
  departamento_nombre text NOT NULL,
  inscripciones jsonb NOT NULL CHECK (jsonb_typeof(inscripciones) = 'array')
);

INSERT INTO alumnos_s0 VALUES
 (1, 'Ana', 10, 'Ingeniería',
  '[{"asignatura_id":101,"titulo":"SQL","nota":8},
    {"asignatura_id":102,"titulo":"Modelado","nota":9}]'),
 (2, 'Bruno', 10, 'Ingeniería',
  '[{"asignatura_id":101,"titulo":"SQL","nota":7},
    {"asignatura_id":103,"titulo":"Redes","nota":6}]'),
 (3, 'Carla', 20, 'Humanidades',
  '[{"asignatura_id":102,"titulo":"Modelado","nota":10}]');

SELECT '00 · Datos anidados' AS etapa;
SELECT * FROM alumnos_s0 ORDER BY alumno_id;

-- Informe: una fila por inscripción. JSON no obliga a salir de SQL.
-- LATERAL permite que la función utilice el alumno de la fila actual.
-- CROSS JOIN no conserva un alumno cuyo array esté vacío.
SELECT a.alumno_id, a.alumno_nombre,
       (j.item ->> 'asignatura_id')::integer AS asignatura_id,
       j.item ->> 'titulo' AS asignatura_titulo,
       (j.item ->> 'nota')::numeric AS nota,
       a.departamento_nombre
FROM alumnos_s0 a
CROSS JOIN LATERAL jsonb_array_elements(a.inscripciones) AS j(item)
ORDER BY a.alumno_id, asignatura_id;
-- 5 filas: Ana/SQL/8, Ana/Modelado/9, Bruno/SQL/7,
-- Bruno/Redes/6, Carla/Modelado/10.

-- Para buscar aprobados, extraemos y convertimos cada nota.
SELECT a.alumno_nombre, j.item ->> 'titulo' AS asignatura
FROM alumnos_s0 a
CROSS JOIN LATERAL jsonb_array_elements(a.inscripciones) AS j(item)
WHERE (j.item ->> 'nota')::numeric >= 9
ORDER BY a.alumno_id;
-- Ana/Modelado y Carla/Modelado.

-- RIESGO: el CHECK solo verifica que sea un array. No obliga a que cada
-- elemento tenga nota válida, asignatura existente ni pareja única.
-- Se podrían añadir validaciones JSON, pero aquí son más laboriosas
-- que PK/FK/CHECK sobre filas y columnas ordinarias.

-- 10 · PRIMERA FORMA NORMAL: UNA FILA POR INSCRIPCIÓN
-- -------------------------------------------------
/*
erDiagram
  INSCRIPCIONES_S1 {
    integer alumno_id PK
    integer asignatura_id PK
    text alumno_nombre
    text asignatura_titulo
    integer departamento_id
    text departamento_nombre
    numeric nota
  }

PK compuesta: (alumno_id, asignatura_id).
Cada alumno puede aparecer varias veces: ahora la fila es una inscripción.
*/
CREATE TABLE inscripciones_s1 (
  alumno_id integer,
  asignatura_id integer,
  alumno_nombre text NOT NULL,
  asignatura_titulo text NOT NULL,
  departamento_id integer NOT NULL,
  departamento_nombre text NOT NULL,
  nota numeric(4,2) NOT NULL CHECK (nota BETWEEN 0 AND 10),
  PRIMARY KEY (alumno_id, asignatura_id)
);

INSERT INTO inscripciones_s1
SELECT a.alumno_id, (j.item ->> 'asignatura_id')::integer,
       a.alumno_nombre, j.item ->> 'titulo',
       a.departamento_id, a.departamento_nombre,
       (j.item ->> 'nota')::numeric
FROM alumnos_s0 a
CROSS JOIN LATERAL jsonb_array_elements(a.inscripciones) AS j(item);

SELECT '10 · 1NF, pero todavía no 2NF' AS etapa;
SELECT * FROM inscripciones_s1 ORDER BY alumno_id, asignatura_id;

-- La misma pregunta ahora es más sencilla: columnas tipadas y WHERE.
SELECT alumno_nombre, asignatura_titulo
FROM inscripciones_s1
WHERE nota >= 9
ORDER BY alumno_id;

/*
GANANCIA DE 1NF EN ESTE DISEÑO
+ PK evita dos inscripciones para la misma pareja.
+ CHECK comprueba cada nota; no hacen falta extracciones JSON ni casts.
+ Cada inscripción se puede modificar directamente por su clave.
- Repetimos alumno, asignatura y departamento en muchas filas.
  Expandir a 1NF NO garantiza ahorrar espacio; aquí introduce repetición.

POR QUÉ FALLA 2NF
(alumno_id, asignatura_id) -> nota             depende de toda la clave.
alumno_id -> alumno_nombre, departamento_id    depende solo de una parte.
asignatura_id -> asignatura_titulo            depende solo de otra parte.
El nombre del departamento también queda determinado por alumno_id.
*/

-- 20 · VER EL PROBLEMA, NO SOLO LEER SU DEFINICIÓN
-- ----------------------------------------------
SAVEPOINT antes_del_error_de_nombre;
UPDATE inscripciones_s1 SET alumno_nombre = 'Ana María'
WHERE alumno_id = 1 AND asignatura_id = 101;

SELECT alumno_id, asignatura_id, alumno_nombre
FROM inscripciones_s1 WHERE alumno_id = 1 ORDER BY asignatura_id;
-- 101 dice Ana María; 102 sigue diciendo Ana. La PK no lo impide.
SELECT alumno_id, COUNT(DISTINCT alumno_nombre) AS nombres_distintos
FROM inscripciones_s1 GROUP BY alumno_id
HAVING COUNT(DISTINCT alumno_nombre) > 1;
-- Detecta al alumno 1. Es la anomalía de actualización.
ROLLBACK TO SAVEPOINT antes_del_error_de_nombre;
RELEASE SAVEPOINT antes_del_error_de_nombre;

SAVEPOINT antes_de_borrar;
DELETE FROM inscripciones_s1 WHERE alumno_id = 3;
SELECT * FROM inscripciones_s1 WHERE alumno_id = 3;
-- 0 filas: al borrar su última inscripción perdimos también el nombre
-- de Carla EN ESTE MODELO. Las otras etapas son copias de laboratorio.
ROLLBACK TO SAVEPOINT antes_de_borrar;
RELEASE SAVEPOINT antes_de_borrar;

-- Anomalía de inserción: ¿cómo guardar a Diego sin asignatura?
-- No se puede representar correctamente en esta tabla: la PK exige pareja.
-- No inventes una asignatura 0 para rellenar el hueco.

-- 30 · SEGUNDA FORMA NORMAL: CADA PARTE TIENE SU ENTIDAD
-- ----------------------------------------------------
/*
erDiagram
  ALUMNOS_S2 ||--o{ INSCRIPCIONES_S2 : tiene
  ASIGNATURAS_S2 ||--o{ INSCRIPCIONES_S2 : recibe
  ALUMNOS_S2 {
    integer alumno_id PK
    text alumno_nombre
    integer departamento_id
    text departamento_nombre
  }
  ASIGNATURAS_S2 {
    integer asignatura_id PK
    text asignatura_titulo
  }
  INSCRIPCIONES_S2 {
    integer alumno_id PK,FK
    integer asignatura_id PK,FK
    numeric nota
  }
*/
CREATE TABLE alumnos_s2 (
  alumno_id integer PRIMARY KEY,
  alumno_nombre text NOT NULL,
  departamento_id integer NOT NULL,
  departamento_nombre text NOT NULL
);
CREATE TABLE asignaturas_s2 (
  asignatura_id integer PRIMARY KEY,
  asignatura_titulo text NOT NULL
);
CREATE TABLE inscripciones_s2 (
  alumno_id integer REFERENCES alumnos_s2(alumno_id),
  asignatura_id integer REFERENCES asignaturas_s2(asignatura_id),
  nota numeric(4,2) NOT NULL CHECK (nota BETWEEN 0 AND 10),
  PRIMARY KEY (alumno_id, asignatura_id)
);

-- Primero comprobamos que no intentamos migrar hechos contradictorios.
-- DISTINCT no resuelve conflictos: solo elimina filas idénticas.
DO $$
BEGIN
  IF EXISTS (
    SELECT alumno_id FROM inscripciones_s1 GROUP BY alumno_id
    HAVING COUNT(DISTINCT (alumno_nombre, departamento_id,
                          departamento_nombre)) > 1
  ) OR EXISTS (
    SELECT asignatura_id FROM inscripciones_s1 GROUP BY asignatura_id
    HAVING COUNT(DISTINCT asignatura_titulo) > 1
  ) THEN
    RAISE EXCEPTION 'Hay contradicciones: corregirlas antes de migrar a 2NF';
  END IF;
END $$;

INSERT INTO alumnos_s2
SELECT DISTINCT alumno_id, alumno_nombre, departamento_id,
                departamento_nombre FROM inscripciones_s1;
INSERT INTO asignaturas_s2
SELECT DISTINCT asignatura_id, asignatura_titulo FROM inscripciones_s1;
INSERT INTO inscripciones_s2
SELECT alumno_id, asignatura_id, nota FROM inscripciones_s1;

SELECT '30 · 2NF: alumno y asignatura separados de la inscripción' AS etapa;
SELECT * FROM alumnos_s2 ORDER BY alumno_id;
SELECT * FROM asignaturas_s2 ORDER BY asignatura_id;
SELECT * FROM inscripciones_s2 ORDER BY alumno_id, asignatura_id;

-- Mismo informe de cinco filas, ahora con dos JOIN.
SELECT a.alumno_id, a.alumno_nombre, s.asignatura_id,
       s.asignatura_titulo, i.nota, a.departamento_nombre
FROM inscripciones_s2 i
JOIN alumnos_s2 a ON a.alumno_id = i.alumno_id
JOIN asignaturas_s2 s ON s.asignatura_id = i.asignatura_id
ORDER BY a.alumno_id, s.asignatura_id;

SAVEPOINT cambio_normalizado;
UPDATE alumnos_s2 SET alumno_nombre = 'Ana María' WHERE alumno_id = 1;
SELECT a.alumno_nombre, i.asignatura_id, i.nota
FROM alumnos_s2 a JOIN inscripciones_s2 i USING (alumno_id)
WHERE a.alumno_id = 1 ORDER BY i.asignatura_id;
-- Ambas filas muestran Ana María, aunque solo actualizamos UNA fila.
INSERT INTO alumnos_s2 VALUES (4, 'Diego', 10, 'Ingeniería');
SELECT a.alumno_nombre, i.asignatura_id
FROM alumnos_s2 a LEFT JOIN inscripciones_s2 i USING (alumno_id)
WHERE a.alumno_id = 4;
-- Diego / NULL: ya puede existir sin inscripción.
ROLLBACK TO SAVEPOINT cambio_normalizado;
RELEASE SAVEPOINT cambio_normalizado;

/*
GANANCIA DE 2NF
+ Nombre del alumno una vez por alumno; título una vez por asignatura.
+ Alta y baja de alumnos/asignaturas independientes de las inscripciones.
+ Menos copias que mantener. Repetir IDs en las FK es necesario y correcto.
- El informe completo requiere dos JOIN; consultas y migraciones más largas.
- Las tablas e índices adicionales también tienen costes de almacenamiento.

¿CUMPLE 3NF? ALUMNOS_S2 TODAVÍA NO:
alumno_id -> departamento_id -> departamento_nombre.
La PK tiene una columna (y no suponemos otras claves candidatas compuestas):
cumple 2NF, pero departamento_nombre describe al departamento, no al alumno.
*/

-- 40 · DEPENDENCIA TRANSITIVA: EL PROBLEMA QUE QUEDABA
-- -------------------------------------------------
SAVEPOINT antes_del_error_departamento;
UPDATE alumnos_s2 SET departamento_nombre = 'Ingeniería y Tecnología'
WHERE alumno_id = 1;
SELECT alumno_id, departamento_id, departamento_nombre
FROM alumnos_s2 WHERE departamento_id = 10 ORDER BY alumno_id;
-- D10 tiene dos nombres actuales incompatibles: la 2NF no lo ha resuelto.
ROLLBACK TO SAVEPOINT antes_del_error_departamento;
RELEASE SAVEPOINT antes_del_error_departamento;

-- 50 · TERCERA FORMA NORMAL: EL DEPARTAMENTO TIENE SU TABLA
-- -------------------------------------------------------
/*
erDiagram
  DEPARTAMENTOS_S3 ||--o{ ALUMNOS_S3 : agrupa
  ALUMNOS_S3 ||--o{ INSCRIPCIONES_S3 : tiene
  ASIGNATURAS_S3 ||--o{ INSCRIPCIONES_S3 : recibe
  DEPARTAMENTOS_S3 {
    integer departamento_id PK
    text departamento_nombre
  }
  ALUMNOS_S3 {
    integer alumno_id PK
    text alumno_nombre
    integer departamento_id FK
  }
  ASIGNATURAS_S3 {
    integer asignatura_id PK
    text asignatura_titulo
  }
  INSCRIPCIONES_S3 {
    integer alumno_id PK,FK
    integer asignatura_id PK,FK
    numeric nota
  }
*/
CREATE TABLE departamentos_s3 (
  departamento_id integer PRIMARY KEY,
  departamento_nombre text NOT NULL
);
CREATE TABLE alumnos_s3 (
  alumno_id integer PRIMARY KEY,
  alumno_nombre text NOT NULL,
  departamento_id integer NOT NULL
    REFERENCES departamentos_s3(departamento_id)
);
CREATE TABLE asignaturas_s3 (
  asignatura_id integer PRIMARY KEY,
  asignatura_titulo text NOT NULL
);
CREATE TABLE inscripciones_s3 (
  alumno_id integer REFERENCES alumnos_s3(alumno_id),
  asignatura_id integer REFERENCES asignaturas_s3(asignatura_id),
  nota numeric(4,2) NOT NULL CHECK (nota BETWEEN 0 AND 10),
  PRIMARY KEY (alumno_id, asignatura_id)
);

DO $$
BEGIN
  IF EXISTS (
    SELECT departamento_id FROM alumnos_s2 GROUP BY departamento_id
    HAVING COUNT(DISTINCT departamento_nombre) > 1
  ) THEN
    RAISE EXCEPTION 'Hay departamentos con nombres contradictorios';
  END IF;
END $$;
INSERT INTO departamentos_s3
SELECT DISTINCT departamento_id, departamento_nombre FROM alumnos_s2;
INSERT INTO alumnos_s3
SELECT alumno_id, alumno_nombre, departamento_id FROM alumnos_s2;
INSERT INTO asignaturas_s3 SELECT * FROM asignaturas_s2;
INSERT INTO inscripciones_s3 SELECT * FROM inscripciones_s2;

SELECT '50 · 3NF: cada hecho en su entidad' AS etapa;
SELECT * FROM departamentos_s3 ORDER BY departamento_id;

-- Informe completo: ahora tres JOIN, cada uno expresa una relación.
-- Partimos de inscripciones: cada fila del resultado seguirá siendo una
-- inscripción, porque todos los JOIN van hacia una PK única.
SELECT a.alumno_id, a.alumno_nombre, s.asignatura_id,
       s.asignatura_titulo, i.nota, d.departamento_nombre
FROM inscripciones_s3 i
JOIN alumnos_s3 a ON a.alumno_id = i.alumno_id
JOIN asignaturas_s3 s ON s.asignatura_id = i.asignatura_id
JOIN departamentos_s3 d ON d.departamento_id = a.departamento_id
ORDER BY a.alumno_id, s.asignatura_id;

SAVEPOINT renombrar_departamento;
UPDATE departamentos_s3
SET departamento_nombre = 'Ingeniería y Tecnología'
WHERE departamento_id = 10;
SELECT a.alumno_nombre, d.departamento_nombre
FROM alumnos_s3 a JOIN departamentos_s3 d USING (departamento_id)
WHERE d.departamento_id = 10 ORDER BY a.alumno_id;
-- Ana y Bruno ven el nuevo nombre. Solo actualizamos una fila.
INSERT INTO departamentos_s3 VALUES (30, 'Física');
-- El departamento puede existir antes de tener alumnos.
ROLLBACK TO SAVEPOINT renombrar_departamento;
RELEASE SAVEPOINT renombrar_departamento;

-- 60 · ¿HEMOS PERDIDO DATOS AL SEPARAR LAS TABLAS?
-- ----------------------------------------------
CREATE VIEW informe_s3 AS
SELECT a.alumno_id, a.alumno_nombre, s.asignatura_id,
       s.asignatura_titulo, i.nota, d.departamento_nombre
FROM inscripciones_s3 i
JOIN alumnos_s3 a ON a.alumno_id = i.alumno_id
JOIN asignaturas_s3 s ON s.asignatura_id = i.asignatura_id
JOIN departamentos_s3 d ON d.departamento_id = a.departamento_id;

-- Debe dar cero diferencias en ambas direcciones (incluida multiplicidad).
WITH original AS (
  SELECT alumno_id, alumno_nombre, asignatura_id, asignatura_titulo,
         nota, departamento_nombre FROM inscripciones_s1
), diferencias AS (
  (SELECT * FROM original EXCEPT ALL SELECT * FROM informe_s3)
  UNION ALL
  (SELECT * FROM informe_s3 EXCEPT ALL SELECT * FROM original)
)
SELECT COUNT(*) AS diferencias_esperadas_cero FROM diferencias;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM informe_s3) <> 5 THEN
    RAISE EXCEPTION 'El informe no tiene las cinco inscripciones esperadas';
  END IF;
  IF EXISTS (
    (SELECT alumno_id, alumno_nombre, asignatura_id, asignatura_titulo,
            nota, departamento_nombre FROM inscripciones_s1
     EXCEPT ALL SELECT * FROM informe_s3)
    UNION ALL
    (SELECT * FROM informe_s3 EXCEPT ALL
     SELECT alumno_id, alumno_nombre, asignatura_id, asignatura_titulo,
            nota, departamento_nombre FROM inscripciones_s1)
  ) THEN
    RAISE EXCEPTION 'La descomposición ha cambiado los hechos del informe';
  END IF;
END $$;

-- La vista oculta los JOIN al consumidor; no almacena una copia del informe.
SELECT alumno_nombre, asignatura_titulo, nota
FROM informe_s3 WHERE nota >= 9
ORDER BY alumno_id;
-- Igual resultado que antes: Ana/Modelado/9 y Carla/Modelado/10.

-- 70 · CONSULTAS MÁS LARGAS, PERO TAMBIÉN MÁS EXPRESIVAS
-- ---------------------------------------------------
-- Media POR INSCRIPCIÓN en cada departamento. No es la media de medias
-- de alumnos: un alumno con más inscripciones aporta más notas.
SELECT d.departamento_nombre, COUNT(*) AS inscripciones,
       ROUND(AVG(i.nota), 2) AS media_por_inscripcion
FROM departamentos_s3 d
JOIN alumnos_s3 a ON a.departamento_id = d.departamento_id
JOIN inscripciones_s3 i ON i.alumno_id = a.alumno_id
GROUP BY d.departamento_id, d.departamento_nombre
ORDER BY d.departamento_id;
-- Ingeniería: 4 y 7.50. Humanidades: 1 y 10.00.

SAVEPOINT casos_sin_hijos;
INSERT INTO departamentos_s3 VALUES (30, 'Física');
INSERT INTO alumnos_s3 VALUES (4, 'Diego', 10);
-- Todos los alumnos, incluso sin inscripción. Los LEFT JOIN deben continuar
-- en la rama opcional: un INNER JOIN a asignaturas eliminaría a Diego.
SELECT a.alumno_nombre, d.departamento_nombre,
       s.asignatura_titulo, i.nota
FROM alumnos_s3 a
JOIN departamentos_s3 d ON d.departamento_id = a.departamento_id
LEFT JOIN inscripciones_s3 i ON i.alumno_id = a.alumno_id
LEFT JOIN asignaturas_s3 s ON s.asignatura_id = i.asignatura_id
ORDER BY a.alumno_id, s.asignatura_id;
-- 6 filas: las cinco originales y Diego/Ingeniería/NULL/NULL.

-- Alarma: alumnos sin inscripciones, sin multiplicar filas.
SELECT a.alumno_id, a.alumno_nombre
FROM alumnos_s3 a
WHERE NOT EXISTS (
  SELECT 1 FROM inscripciones_s3 i WHERE i.alumno_id = a.alumno_id
);
-- Diego. No equivale a “no ha hecho exámenes” fuera de nuestras reglas.

-- Todos los departamentos, incluso vacíos. COUNT(*) contaría una fila
-- de extensión NULL para Física: contamos el ID no nulo del hijo.
SELECT d.departamento_nombre, COUNT(a.alumno_id) AS alumnos
FROM departamentos_s3 d
LEFT JOIN alumnos_s3 a ON a.departamento_id = d.departamento_id
GROUP BY d.departamento_id, d.departamento_nombre
ORDER BY d.departamento_id;
-- Ingeniería 3, Humanidades 1, Física 0.
ROLLBACK TO SAVEPOINT casos_sin_hijos;
RELEASE SAVEPOINT casos_sin_hijos;

-- 80 · ESPACIO: MEDIR QUÉ AHORRAMOS, SIN PROMETER MILAGROS
-- -----------------------------------------------------
-- Primero contamos copias de NOMBRES, no IDs ni filas totales.
SELECT '1NF' AS etapa,
       (SELECT COUNT(*) FROM inscripciones_s1) AS copias_nombre_alumno,
       (SELECT COUNT(*) FROM inscripciones_s1) AS copias_titulo_asignatura,
       (SELECT COUNT(*) FROM inscripciones_s1) AS copias_nombre_departamento
UNION ALL
SELECT '2NF', (SELECT COUNT(*) FROM alumnos_s2),
       (SELECT COUNT(*) FROM asignaturas_s2), (SELECT COUNT(*) FROM alumnos_s2)
UNION ALL
SELECT '3NF', (SELECT COUNT(*) FROM alumnos_s3),
       (SELECT COUNT(*) FROM asignaturas_s3),
       (SELECT COUNT(*) FROM departamentos_s3)
ORDER BY etapa;
-- 1NF: 5/5/5. 2NF: 3/3/3. 3NF: 3/3/2.

-- Bytes lógicos SOLO de esos textos; no es tamaño físico de las tablas.
SELECT '1NF' AS etapa,
       SUM(octet_length(alumno_nombre) + octet_length(asignatura_titulo)
           + octet_length(departamento_nombre)) AS bytes_textos
FROM inscripciones_s1
UNION ALL
SELECT '3NF',
       (SELECT SUM(octet_length(alumno_nombre)) FROM alumnos_s3)
     + (SELECT SUM(octet_length(asignatura_titulo)) FROM asignaturas_s3)
     + (SELECT SUM(octet_length(departamento_nombre)) FROM departamentos_s3);

-- Tamaño físico aproximado actual: tablas + índices + almacenamiento TOAST.
-- La suma solo incluye tablas de cada etapa, no vistas ni las otras etapas.
WITH tamanos AS (
 SELECT CASE
   WHEN c.relname LIKE '%_s0' THEN '0 · anidado'
   WHEN c.relname LIKE '%_s1' THEN '1 · 1NF'
   WHEN c.relname LIKE '%_s2' THEN '2 · 2NF'
   WHEN c.relname LIKE '%_s3' THEN '3 · 3NF'
 END AS etapa, pg_total_relation_size(c.oid) AS bytes
 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
 WHERE n.nspname = 'nf_laboratorio' AND c.relkind = 'r'
)
SELECT etapa, SUM(bytes) AS bytes_fisicos,
       pg_size_pretty(SUM(bytes)::bigint) AS tamano_legible
FROM tamanos GROUP BY etapa ORDER BY etapa;

/*
En cinco inscripciones, 3NF puede ocupar MÁS: hay más tablas, páginas,
cabeceras e índices. Además, las demostraciones revertidas pueden dejar
versiones de filas físicamente presentes hasta el mantenimiento posterior.
Esta medición no es un experimento de rendimiento controlado.
Con muchísimas inscripciones y textos largos, eliminar copias puede ahorrar
mucho; aun así, importan los índices, IDs, compresión y patrones reales.
El ahorro de espacio es posible. La claridad y el control de actualizaciones
son beneficios estructurales, no una promesa de que todo SELECT será más rápido.
*/

-- 90 · COSTE DE LOS JOIN: VER EL PLAN Y AYUDAR AL ACCESO
-- ---------------------------------------------------
-- La PK compuesta ya indexa (alumno_id, asignatura_id).
-- PostgreSQL no crea automáticamente un índice por cada FK hija.
CREATE INDEX alumnos_s3_por_departamento ON alumnos_s3(departamento_id);
CREATE INDEX inscripciones_s3_por_asignatura ON inscripciones_s3(asignatura_id);
ANALYZE alumnos_s3;
ANALYZE asignaturas_s3;
ANALYZE departamentos_s3;
ANALYZE inscripciones_s3;
ANALYZE inscripciones_s1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT alumno_nombre, asignatura_titulo, nota, departamento_nombre
FROM inscripciones_s1 WHERE alumno_id = 1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT alumno_nombre, asignatura_titulo, nota, departamento_nombre
FROM informe_s3 WHERE alumno_id = 1;
-- EXPLAIN ANALYZE ejecuta estas consultas de lectura y muestra su plan.
-- En tablas diminutas, un Seq Scan es normal, aunque haya índices.
-- No compares microsegundos de cinco filas para concluir qué diseño escala.
-- Con datos representativos, revisa filas estimadas/reales, lecturas,
-- índices usados, memoria y latencias de las consultas que sí importan.

-- 100 · DESNORMALIZAR DE FORMA CONTROLADA PARA LEER
-- -----------------------------------------------
CREATE MATERIALIZED VIEW informe_cache AS SELECT * FROM informe_s3;
-- Esta SÍ guarda resultados. Es una copia derivada, no la fuente de verdad.
SAVEPOINT demostrar_cache;
UPDATE departamentos_s3 SET departamento_nombre = 'Ingeniería y Tecnología'
WHERE departamento_id = 10;

SELECT 'vista actual' AS origen, departamento_nombre
FROM informe_s3 WHERE alumno_id = 1 AND asignatura_id = 101
UNION ALL
SELECT 'cache pendiente de refresco', departamento_nombre
FROM informe_cache WHERE alumno_id = 1 AND asignatura_id = 101;
-- La vista normal muestra el nombre nuevo; la materializada, el anterior.
REFRESH MATERIALIZED VIEW informe_cache;
SELECT departamento_nombre FROM informe_cache
WHERE alumno_id = 1 AND asignatura_id = 101;
-- Ahora también muestra el nombre nuevo.
ROLLBACK TO SAVEPOINT demostrar_cache;
RELEASE SAVEPOINT demostrar_cache;
-- Se revierten tanto el cambio como su refresco: todo vuelve a ser coherente.

/*
QUÉ DEBERÍAS HABER OBSERVADO
0 -> 1NF: extraemos la lista; columnas tipadas y una fila por inscripción.
1 -> 2NF: extraemos hechos que dependen de parte de la clave compuesta.
2 -> 3NF: extraemos hechos del departamento que dependían transitivamente.
Las FK reconstruyen los vínculos. Los JOIN reconstruyen los informes.
Una vista puede ocultar la complejidad de consulta sin duplicar los datos.
Una vista materializada cambia cálculo al leer por coste de refresco y espacio.

LÍMITES Y MATICES IMPORTANTES
- Estudiamos todas las claves candidatas, no solo la PK seleccionada.
  Añadir un id artificial no elimina una dependencia parcial existente.
- 2NF exige primero 1NF. Con todas las claves candidatas simples, no hay
  partes propias de claves y 2NF se cumple; todavía puede fallar 3NF.
- Formalmente 3NF: para toda dependencia no trivial X -> A, X es superclave
  o A es primo (pertenece a alguna clave candidata). Nuestros ejemplos
  sencillos se explican mediante dependencias transitivas problemáticas.
- Un resultado de JOIN puede repetir nombres sin desnormalizar el origen.
- No toda consulta necesita todas las tablas: una media de notas por alumno
  puede calcularse solo con inscripciones_s3 si no se necesitan nombres.
- Más JOIN no implica automáticamente multiplicación: de inscripción hacia
  PK únicas seguimos teniendo cinco filas. Unir dos ramas 1:N independientes
  sí puede multiplicar combinaciones; resúmelas por separado cuando corresponda.
- Nombre actual y nombre impreso en un diploma histórico son hechos distintos.
  Conservar una instantánea histórica puede ser correcto, no un error de 3NF.
- MongoDB también permite referencias y documentos embebidos. Flexibilidad
  de esquema, anidación y duplicación de hechos son decisiones diferentes.
- Este script usa las FK sin ON DELETE CASCADE: borrar un padre con hijos
  se rechaza. Elegir CASCADE o no es una regla de negocio, no una forma normal.

PRÁCTICA PROPUESTA (después de ejecutar COMMIT)
1. Añade un departamento sin alumnos. Comprueba que un LEFT JOIN lo conserva.
2. Añade a Diego sin inscripciones. Lista quién aún no está inscrito.
3. Matricula a Diego en SQL; intenta repetir la pareja y observa la PK.
4. Intenta una nota 11 y observa el CHECK. Si trabajas en transacción,
   usa SAVEPOINT y revierte el error antes de seguir.
5. Añade curso_academico al negocio: ¿debe formar parte de la clave?
6. Define cómo representar dos intentos del mismo examen sin pisar el anterior.

Referencias técnicas oficiales:
https://www.postgresql.org/docs/current/ddl-constraints.html
https://www.postgresql.org/docs/current/queries-table-expressions.html
https://www.postgresql.org/docs/current/rules-materializedviews.html
https://support.microsoft.com/en-us/access/database-design-basics
*/

SELECT 'Recorrido completado: las cuatro etapas quedan disponibles.' AS resultado;
COMMIT;
-- SET LOCAL termina con COMMIT. Para explorar después, usa:
-- SET search_path TO nf_laboratorio, pg_catalog;
-- SELECT * FROM informe_s3 ORDER BY alumno_id, asignatura_id;
