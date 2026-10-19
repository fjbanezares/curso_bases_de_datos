-- PostgreSQL. Ejecutar una vez en una base de pruebas.
-- No contiene DROP. Detener ante errores (psql: -v ON_ERROR_STOP=1).

-- Lámina 2
CREATE SCHEMA tutorial_relaciones;
SET search_path TO tutorial_relaciones;

CREATE TABLE estudiantes (
  id integer PRIMARY KEY,
  nombre text NOT NULL
);
CREATE TABLE contacto_unico (
  estudiante_id integer PRIMARY KEY
    REFERENCES estudiantes(id),
  email text NOT NULL
);
INSERT INTO estudiantes VALUES (1,'Ana'),(2,'Bruno'),(3,'Carla');
INSERT INTO contacto_unico VALUES
  (1,'ana@uni.test'),(2,'bruno@uni.test');

-- Lámina 3
SELECT e.id, e.nombre, u.email
FROM estudiantes AS e
JOIN contacto_unico AS u ON u.estudiante_id = e.id
ORDER BY e.id;

-- Lámina 3
SELECT e.id, e.nombre, u.email
FROM estudiantes AS e
LEFT JOIN contacto_unico AS u ON u.estudiante_id = e.id
ORDER BY e.id;

-- Lámina 4
CREATE TABLE contactos (
  id integer PRIMARY KEY,
  estudiante_id integer NOT NULL REFERENCES estudiantes(id),
  email text NOT NULL,
  prioridad integer NOT NULL CHECK (prioridad > 0),
  principal boolean NOT NULL DEFAULT false,
  UNIQUE (estudiante_id, email)
);
CREATE UNIQUE INDEX un_principal_por_estudiante
  ON contactos(estudiante_id) WHERE principal;

INSERT INTO contactos VALUES
 (11,1,'ana@uni.test',1,true),
 (12,1,'ana@casa.test',2,false),
 (13,1,'ana@trabajo.test',3,false),
 (21,2,'bruno@uni.test',1,true);

-- Lámina 4
SELECT e.id, e.nombre, c.email
FROM estudiantes e
JOIN contactos c ON c.estudiante_id = e.id
WHERE e.id = 1
ORDER BY c.prioridad, c.id;

-- Lámina 5
SELECT e.id, e.nombre, c.email
FROM estudiantes e
LEFT JOIN contactos c
  ON c.estudiante_id = e.id AND c.principal
ORDER BY e.id;

-- Lámina 5
SELECT e.id, e.nombre, elegido.email
FROM estudiantes e
LEFT JOIN LATERAL (
  SELECT c.email
  FROM contactos c
  WHERE c.estudiante_id = e.id
  ORDER BY c.prioridad, c.id
  LIMIT 1
) AS elegido ON true
ORDER BY e.id;

-- Lámina 5
SELECT e.id, e.nombre, c.email
FROM estudiantes e JOIN contactos c ON c.estudiante_id = e.id
ORDER BY e.id, c.prioridad, c.id
LIMIT 1;

-- Lámina 6
WITH ordenados AS (
  SELECT c.*, ROW_NUMBER() OVER (
    PARTITION BY estudiante_id ORDER BY prioridad, id
  ) AS rn
  FROM contactos c
)
SELECT e.id, e.nombre, o.email
FROM estudiantes e
LEFT JOIN ordenados o ON o.estudiante_id = e.id AND o.rn = 1
ORDER BY e.id;

-- Lámina 6
SELECT e.id, e.nombre,
       COUNT(c.id) AS total,
       COALESCE(ARRAY_AGG(c.email ORDER BY c.prioridad, c.id)
         FILTER (WHERE c.id IS NOT NULL), ARRAY[]::text[]) AS emails
FROM estudiantes e
LEFT JOIN contactos c ON c.estudiante_id = e.id
GROUP BY e.id, e.nombre
ORDER BY e.id;

-- Lámina 6
SELECT e.id, e.nombre
FROM estudiantes e
WHERE EXISTS (
  SELECT 1 FROM contactos c WHERE c.estudiante_id = e.id
)
ORDER BY e.id;

-- Lámina 7
CREATE TABLE contactos_array (
  estudiante_id integer PRIMARY KEY REFERENCES estudiantes(id),
  emails text[] NOT NULL DEFAULT ARRAY[]::text[]
);
INSERT INTO contactos_array VALUES
 (1,ARRAY['ana@uni.test','ana@casa.test','ana@trabajo.test']),
 (2,ARRAY['bruno@uni.test']), (3,ARRAY[]::text[]);

-- Primer elemento: convención de prioridad por posición.
SELECT estudiante_id, emails[1] AS preferido
FROM contactos_array ORDER BY estudiante_id;

-- Buscar dentro del array, sin salir de SQL.
SELECT estudiante_id FROM contactos_array
WHERE 'ana@casa.test' = ANY(emails);

-- Convertir la lista en filas y conservar el orden.
SELECT a.estudiante_id, u.email, u.posicion
FROM contactos_array a
CROSS JOIN LATERAL unnest(a.emails) WITH ORDINALITY
  AS u(email, posicion)
ORDER BY a.estudiante_id, u.posicion;

-- Lámina 8
CREATE TABLE examenes (
  id integer PRIMARY KEY,
  titulo text NOT NULL
);
CREATE TABLE calificaciones (
  estudiante_id integer REFERENCES estudiantes(id),
  examen_id integer REFERENCES examenes(id),
  nota numeric(4,2) NOT NULL CHECK (nota BETWEEN 0 AND 10),
  PRIMARY KEY (estudiante_id, examen_id)
);
INSERT INTO examenes VALUES (101,'SQL'),(102,'Modelado');
INSERT INTO calificaciones VALUES (1,101,8),(1,102,9),(2,101,7);

SELECT e.nombre, x.titulo, g.nota
FROM calificaciones g
JOIN estudiantes e ON e.id = g.estudiante_id
JOIN examenes x ON x.id = g.examen_id
ORDER BY e.id, x.id;

-- Lámina 9
SELECT e.id, e.nombre, g.examen_id, g.nota
FROM estudiantes e
LEFT JOIN calificaciones g ON g.estudiante_id = e.id
ORDER BY e.id, g.examen_id;

-- Misma conservación, con las tablas invertidas:
SELECT e.id, e.nombre, g.examen_id, g.nota
FROM calificaciones g
RIGHT JOIN estudiantes e ON e.id = g.estudiante_id
ORDER BY e.id, g.examen_id;

-- Lámina 9
SELECT e.id, e.nombre,
  NOT EXISTS (SELECT 1 FROM contactos c
              WHERE c.estudiante_id = e.id) AS falta_contacto,
  NOT EXISTS (SELECT 1 FROM calificaciones g
              WHERE g.estudiante_id = e.id) AS sin_nota
FROM estudiantes e ORDER BY e.id;

-- Lámina 9
SELECT e.id, e.nombre
FROM estudiantes e
LEFT JOIN calificaciones g
  ON g.estudiante_id = e.id AND g.examen_id = 102
WHERE g.estudiante_id IS NULL
ORDER BY e.id;

-- Lámina 10
SELECT e.nombre, c.email, g.examen_id, g.nota
FROM estudiantes e
JOIN contactos c ON c.estudiante_id = e.id
JOIN calificaciones g ON g.estudiante_id = e.id
WHERE e.id = 1
ORDER BY c.id, g.examen_id;

-- Lámina 10
WITH resumen_contactos AS (
  SELECT estudiante_id, COUNT(*) AS n_contactos
  FROM contactos GROUP BY estudiante_id
), resumen_notas AS (
  SELECT estudiante_id, COUNT(*) AS n_notas, AVG(nota) AS media
  FROM calificaciones GROUP BY estudiante_id
)
SELECT e.id, e.nombre,
       COALESCE(c.n_contactos, 0) AS n_contactos,
       COALESCE(g.n_notas, 0) AS n_notas, g.media
FROM estudiantes e
LEFT JOIN resumen_contactos c ON c.estudiante_id = e.id
LEFT JOIN resumen_notas g ON g.estudiante_id = e.id
ORDER BY e.id;

-- Lámina 12
SELECT e.id AS estudiante_id, e.nombre, g.nota
FROM estudiantes AS e
LEFT JOIN calificaciones AS g ON g.estudiante_id = e.id
WHERE e.nombre = 'Ana'
ORDER BY g.examen_id;
