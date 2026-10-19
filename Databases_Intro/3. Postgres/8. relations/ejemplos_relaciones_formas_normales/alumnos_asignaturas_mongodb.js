// RELACIONES N:M EN MONGODB
// Ejemplo: alumnos, asignaturas y matrículas.
// Ejecutar en mongosh, NO en un editor SQL.
//
// Sintaxis revisada; no ejecutado contra MongoDB en este entorno.

const lab = db.getSiblingDB("nm_practica_mongo");

if (lab.getCollectionNames().length !== 0) {
    throw new Error(
        "La base de práctica ya contiene colecciones. Usa otro nombre de base."
    );
}

// ============================================================
// MODELO A: TRES COLECCIONES
// alumnos + asignaturas + matriculas
// ============================================================

// 1. CREAR LOS ALUMNOS
// _id identifica de forma única cada documento.

lab.alumnos.insertMany([
    { _id: 1, nombre: "Ana" },
    { _id: 2, nombre: "Bruno" },
    { _id: 3, nombre: "Carla" },
    { _id: 4, nombre: "Diego" }
]);

// 2. CREAR LAS ASIGNATURAS

lab.asignaturas.insertMany([
    { _id: 101, titulo: "SQL" },
    { _id: 102, titulo: "Modelado" },
    { _id: 103, titulo: "Redes" }
]);

// 3. PREPARAR LA COLECCIÓN INTERMEDIA
//
// Cada documento representa UNA matrícula.
// La pareja alumno_id + asignatura_id no puede repetirse.
//
// Esto NO comprueba que existan el alumno y la asignatura:
// MongoDB no impone aquí claves foráneas como una base relacional.

lab.matriculas.createIndex(
    { alumno_id: 1, asignatura_id: 1 },
    { unique: true }
);

// Índice adicional para buscar matrículas por asignatura.
// Los índices pueden acelerar consultas, pero ocupan espacio
// y requieren mantenimiento cuando escribimos datos.

lab.matriculas.createIndex({ asignatura_id: 1 });

// 4. INSERTAR CUATRO MATRÍCULAS
//
// Ana cursa SQL y Modelado.
// Bruno cursa SQL.
// Carla cursa Modelado, pero todavía no tiene nota.
// Diego no está matriculado.
// Redes no tiene alumnos.

lab.matriculas.insertMany([
    { alumno_id: 1, asignatura_id: 101, nota: 8 },
    { alumno_id: 1, asignatura_id: 102, nota: 9 },
    { alumno_id: 2, asignatura_id: 101, nota: 7 },
    { alumno_id: 3, asignatura_id: 102, nota: null }
]);

// ============================================================
// CONSULTA 1: MATRÍCULAS DE ANA
// ============================================================

// find filtra documentos.
// toArray reúne los resultados para mostrarlos con printjson.

printjson(
    lab.matriculas.find({ alumno_id: 1 }).toArray()
);

// Resultado: dos documentos, asignaturas 101 y 102.

// ============================================================
// CONSULTA 2: MOSTRAR NOMBRES, ASIGNATURAS Y NOTAS
// Equivalente al informe SQL con dos INNER JOIN.
// ============================================================

// aggregate ejecuta una secuencia de transformaciones.
//
// $lookup:
// Busca documentos relacionados y los añade dentro de un ARRAY.
//
// $unwind:
// Despliega ese array: un documento de salida por elemento.
//
// $project:
// Elige las columnas/campos que queremos mostrar.
//
// Los nombres con "$", como "$alumno.nombre", indican que
// queremos leer el valor de ese campo.

printjson(
    lab.matriculas.aggregate([
        {
            $lookup: {
                from: "alumnos",
                localField: "alumno_id",
                foreignField: "_id",
                as: "alumno"
            }
        },
        {
            $unwind: "$alumno"
        },
        {
            $lookup: {
                from: "asignaturas",
                localField: "asignatura_id",
                foreignField: "_id",
                as: "asignatura"
            }
        },
        {
            $unwind: "$asignatura"
        },
        {
            $sort: {
                alumno_id: 1,
                asignatura_id: 1
            }
        },
        {
            $project: {
                _id: 0,
                nombre: "$alumno.nombre",
                titulo: "$asignatura.titulo",
                nota: 1
            }
        }
    ]).toArray()
);

// Resultado esperado:
//
// Ana   | SQL      | 8
// Ana   | Modelado | 9
// Bruno | SQL      | 7
// Carla | Modelado | null
//
// IMPORTANTE:
// $lookup conserva el documento original aunque no encuentre
// coincidencias: añade un array vacío.
//
// Pero $unwind, utilizado así, elimina los arrays vacíos.
// Por eso esta combinación se comporta como INNER JOIN.

// ============================================================
// CONSULTA 3: INCLUIR TAMBIÉN A LOS ALUMNOS SIN MATRÍCULA
// Equivalente al ejemplo con LEFT JOIN.
// ============================================================

// Ahora empezamos desde alumnos.
//
// preserveNullAndEmptyArrays: true
// conserva al alumno aunque no haya coincidencias.
//
// $ifNull permite mostrar null cuando el campo no existe
// o ya tiene valor null.

printjson(
    lab.alumnos.aggregate([
        {
            $lookup: {
                from: "matriculas",
                localField: "_id",
                foreignField: "alumno_id",
                as: "matricula"
            }
        },
        {
            $unwind: {
                path: "$matricula",
                preserveNullAndEmptyArrays: true
            }
        },
        {
            $lookup: {
                from: "asignaturas",
                localField: "matricula.asignatura_id",
                foreignField: "_id",
                as: "asignatura"
            }
        },
        {
            $unwind: {
                path: "$asignatura",
                preserveNullAndEmptyArrays: true
            }
        },
        {
            $sort: {
                _id: 1,
                "asignatura._id": 1
            }
        },
        {
            $project: {
                _id: 0,
                nombre: 1,
                titulo: {
                    $ifNull: ["$asignatura.titulo", null]
                },
                nota: {
                    $ifNull: ["$matricula.nota", null]
                }
            }
        }
    ]).toArray()
);

// Resultado esperado:
//
// Ana   | SQL      | 8
// Ana   | Modelado | 9
// Bruno | SQL      | 7
// Carla | Modelado | null
// Diego | null     | null
//
// Carla tiene matrícula, pero no nota.
// Diego no tiene matrícula. Son situaciones diferentes.

// ============================================================
// INTEGRIDAD: DIFERENCIA IMPORTANTE RESPECTO A SQL
// ============================================================

// El índice único evita repetir la pareja.
//
// Pero MongoDB NO comprueba automáticamente que alumno_id
// exista en alumnos ni que asignatura_id exista en asignaturas.
//
// La aplicación debe gestionar:
// - Referencias válidas.
// - Qué ocurre al borrar un alumno o una asignatura.
// - Cambios concurrentes.
//
// Validar los tipos de los campos no valida la existencia
// del documento referenciado en otra colección.
//
// Una transacción tampoco crea automáticamente una regla de FK.

// ============================================================
// MODELO B: ARRAY DE IDs DENTRO DE CADA ALUMNO
// ============================================================

// Creamos otra colección SOLO para comparar diseños.
//
// En producción no mantendríamos ambos modelos como fuentes
// independientes sin definir cómo sincronizarlos.
//
// Aquí el vínculo está dentro del alumno.
// Los títulos siguen guardados en asignaturas.

lab.alumnos_array.insertMany([
    {
        _id: 1,
        nombre: "Ana",
        asignatura_ids: [101, 102]
    },
    {
        _id: 2,
        nombre: "Bruno",
        asignatura_ids: [101]
    },
    {
        _id: 3,
        nombre: "Carla",
        asignatura_ids: [102]
    },
    {
        _id: 4,
        nombre: "Diego",
        asignatura_ids: []
    }
]);

// Indexar un campo que contiene arrays produce un índice multikey:
// permite indexar sus elementos.

lab.alumnos_array.createIndex({ asignatura_ids: 1 });

// ============================================================
// CONSULTA 4: ALUMNOS QUE CURSAN SQL
// ============================================================

// Busca documentos cuyo array contiene el valor 101.

printjson(
    lab.alumnos_array.find(
        { asignatura_ids: 101 },
        { nombre: 1 }
    ).toArray()
);

// Resultado: Ana y Bruno, con sus _id.

// ============================================================
// CONSULTA 5: ANA CON LOS DATOS DE SUS ASIGNATURAS
// ============================================================

// $match filtra documentos dentro de aggregate.
//
// $lookup puede comparar un array de IDs con el _id
// de los documentos de la otra colección.
// No necesitamos desplegar primero asignatura_ids.

printjson(
    lab.alumnos_array.aggregate([
        {
            $match: { _id: 1 }
        },
        {
            $lookup: {
                from: "asignaturas",
                localField: "asignatura_ids",
                foreignField: "_id",
                as: "materias"
            }
        }
    ]).toArray()
);

// Obtendremos a Ana con un array "materias" que contiene
// los documentos de SQL y Modelado.
//
// No supongas que "materias" conserva el orden de asignatura_ids.

// ============================================================
// AÑADIR UN ID SIN REPETIRLO
// ============================================================

// $addToSet añade el elemento solo si no está presente.
// Como Ana ya tiene 101, esta instrucción no cambia su array.

lab.alumnos_array.updateOne(
    { _id: 1 },
    { $addToSet: { asignatura_ids: 101 } }
);

// LIMITACIONES:
// - No comprueba que exista la asignatura 101.
// - No elimina duplicados que ya hubiera antes.
// - Si guardamos objetos {asignatura_id, nota}, compara el objeto
//   completo. No garantiza una única entrada por asignatura_id.

// ============================================================
// ¿QUÉ MODELO ELEGIR?
// ============================================================

// TRES COLECCIONES:
// - Una matrícula por documento.
// - Cómodo para consultar desde ambos extremos.
// - Fácil añadir nota, fecha y estado a cada matrícula.
// - Índice único sobre la pareja.
// - Necesita $lookup o consultas adicionales para reunir nombres.
//
// ARRAY DENTRO DEL ALUMNO:
// - Cómodo para leer al alumno con su lista de asignaturas.
// - Adecuado cuando la lista está acotada.
// - La consulta inversa puede buscar dentro del array.
// - Hay que controlar crecimiento y duplicados.
// - Si necesitamos nota por matrícula, el array de IDs ya no basta:
//   necesitaríamos objetos u otro modelo.
//
// Guardar IDs NO duplica el título de las asignaturas.
// Copiar el título dentro de cada alumno SÍ lo duplica.
//
// Evita mantener dos listas espejo —materias en cada alumno
// y alumnos en cada materia— sin una estrategia de consistencia.
//
// NoSQL no elimina las relaciones:
// cambia cómo las representamos, consultamos y verificamos.