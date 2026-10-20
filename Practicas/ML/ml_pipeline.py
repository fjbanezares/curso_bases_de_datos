#!/usr/bin/env python3
"""
==============================================================================
PIPELINE DE MACHINE LEARNING DESDE POSTGRESQL (Viviendas y Precios)
==============================================================================
Flujo completo:
1. Conexión segura a PostgreSQL (lectura de .env)
2. Extracción relacional mediante multi-tabla SQL JOIN
3. Carga en Pandas DataFrame
4. Preprocesamiento: Variables Dummies (One-Hot), Escalado (StandardScaler), División Train/Test
5. Entrenamiento y Evaluación de 11 Algoritmos de Machine Learning
   - 10 Algoritmos de Regresión (Predicción Continua de Precios)
   - 1 Algoritmo de Clasificación (Regresión Logística para Viviendas Premium)
==============================================================================
"""

import os
import sys
import psycopg2
import pandas as pd
import numpy as np
from dotenv import load_dotenv

# Algoritmos de Regresión
from sklearn.linear_model import LinearRegression, Ridge, Lasso, ElasticNet
from sklearn.neighbors import KNeighborsRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor, AdaBoostRegressor
from sklearn.svm import SVR

# Algoritmo de Clasificación
from sklearn.linear_model import LogisticRegression

# Preprocesamiento y Métricas
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.impute import SimpleImputer  # 👈 Imputador para gestionar NULLs si se usa LEFT JOIN
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, confusion_matrix

# Cargar variables de entorno desde .env
load_dotenv()

def get_db_connection():
    """Establece conexión con PostgreSQL leyendo las credenciales de .env"""
    try:
        conn = psycopg2.connect(
            user=os.getenv("DB_USER", "postgres"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "5432"),
            database=os.getenv("DB_DATABASE", "world")
        )
        return conn
    except Exception as e:
        print(f"❌ Error al conectar a PostgreSQL: {e}")
        print("Verifica que PostgreSQL esté arrancado y que tu archivo .env tenga la contraseña correcta.")
        sys.exit(1)

def load_data_from_postgres():
    """Ejecuta el SQL JOIN para unir las 3 tablas relacionales en una sola fila por vivienda"""
    conn = get_db_connection()
    
    query = """
    SELECT 
        p.property_id,
        p.square_meters,
        p.bedrooms,
        p.bathrooms,
        p.floor,
        p.construction_year,
        p.energy_rating,
        p.has_elevator,
        p.has_terrace,
        p.has_parking,
        p.has_pool,
        p.condition,
        n.name AS neighborhood_name,
        n.avg_income_eur,
        n.safety_score,
        n.distance_center_km,
        n.schools_count,
        m.sale_price_eur,
        m.days_on_market
    FROM properties p
    JOIN neighborhoods n ON p.neighborhood_id = n.neighborhood_id
    JOIN market_valuations m ON p.property_id = m.property_id;
    """
    
    print("📡 1. Extrayendo datos de PostgreSQL mediante SQL JOIN...")
    df = pd.read_sql_query(query, conn)
    conn.close()
    print(f"   ✓ Filas extraídas: {len(df)} | Columnas: {len(df.columns)}")
    return df

def preprocess_features(df):
    """Realiza la preparación de datos: Dummies, limpieza y separación Train/Test"""
    print("\n🧹 2. Tratamiento de Datos (Feature Engineering):")
    
    # 2.1 Inspección y tipos
    # Convertir booleanos a enteros (0 y 1)
    bool_cols = ['has_elevator', 'has_terrace', 'has_parking', 'has_pool']
    for col in bool_cols:
        df[col] = df[col].astype(int)
    print("   ✓ Booleanos convertidos a binarios (0 y 1).")
    
    # 2.2 Variables Categóricas a Dummies (One-Hot Encoding)
    # energy_rating, condition, neighborhood_name
    cat_cols = ['energy_rating', 'condition', 'neighborhood_name']
    df_encoded = pd.get_dummies(df, columns=cat_cols, drop_first=True, dtype=int)
    print(f"   ✓ Variables categóricas codificadas con get_dummies(). Total columnas ahora: {df_encoded.shape[1]}")
    
    # 2.3 Separar Features (X) y Target (y)
    # Excluimos identificadores y días en mercado para predecir el precio
    drop_cols = ['property_id', 'sale_price_eur', 'days_on_market']
    X = df_encoded.drop(columns=drop_cols)
    y = df_encoded['sale_price_eur']
    
    # 2.4 Comprobación y Gestión de NULLs (Vital si se usara LEFT JOIN)
    null_counts = X.isnull().sum().sum()
    if null_counts > 0:
        print(f"   ⚠️ Se detectaron {null_counts} valores NULL en las variables. Aplicando SimpleImputer(median)...")
        imputer = SimpleImputer(strategy='median')
        X = pd.DataFrame(imputer.fit_transform(X), columns=X.columns)
    else:
        print("   ✓ Comprobación de NULLs: 0 valores ausentes (dataset íntegro gracias a integridad relacional).")
    
    print(f"   ✓ Matriz de características X: {X.shape[0]} muestras x {X.shape[1]} variables.")
    print(f"   ✓ Variable objetivo continua y (Precio €): Media = {y.mean():,.0f}€ | Mediana = {y.median():,.0f}€")
    
    # 2.5 Train / Test Split (80% entrenamiento, 20% prueba)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    print(f"   ✓ División Train/Test: {len(X_train)} filas de entrenamiento | {len(X_test)} de test.")
    
    # 2.6 Escalado / Normalización con StandardScaler
    # Ajustamos el escalador SOLO con X_train para evitar Data Leakage
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    print("   ✓ Normalización StandardScaler aplicada a X (Media=0, Desv.Tipica=1).")
    
    return X, y, X_train, X_test, y_train, y_test, X_train_scaled, X_test_scaled

def evaluate_regression_models(X_train, X_test, y_train, y_test, X_train_scaled, X_test_scaled):
    """Entrena y evalúa los 10 algoritmos de regresión"""
    print("\n🤖 3. Entrenando y Evaluando los 10 Algoritmos de Regresión:")
    print("=" * 80)
    
    models = {
        "1. Linear Regression (OLS)": (LinearRegression(), False),
        "2. Ridge Regression (L2)": (Ridge(alpha=10.0), True),
        "3. Lasso Regression (L1)": (Lasso(alpha=100.0, max_iter=5000), True),
        "4. ElasticNet (L1 + L2)": (ElasticNet(alpha=1.0, l1_ratio=0.5, max_iter=5000), True),
        "5. K-Nearest Neighbors (KNN)": (KNeighborsRegressor(n_neighbors=5), True),
        "6. Decision Tree Regressor": (DecisionTreeRegressor(max_depth=6, random_state=42), False),
        "7. Random Forest Regressor": (RandomForestRegressor(n_estimators=150, max_depth=10, random_state=42), False),
        "8. Gradient Boosting (GBM)": (GradientBoostingRegressor(n_estimators=150, learning_rate=0.1, max_depth=4, random_state=42), False),
        "9. AdaBoost Regressor": (AdaBoostRegressor(n_estimators=80, random_state=42), False),
        "10. Support Vector Regressor (SVR)": (SVR(kernel='rbf', C=100000, epsilon=5000), True)
    }
    
    results = []
    
    for name, (model, requires_scale) in models.items():
        # Selección de datos escalados o crudos según la naturaleza del algoritmo
        X_tr = X_train_scaled if requires_scale else X_train
        X_te = X_test_scaled if requires_scale else X_test
        
        # Entrenamiento
        model.fit(X_tr, y_train)
        
        # Predicción sobre el conjunto de test
        y_pred = model.predict(X_te)
        
        # Cálculo de Métricas
        r2 = r2_score(y_test, y_pred)
        rmse = np.sqrt(mean_squared_error(y_test, y_pred))
        mae = mean_absolute_error(y_test, y_pred)
        mape = np.mean(np.abs((y_test - y_pred) / y_test)) * 100
        
        results.append({
            "Algoritmo": name,
            "R² Score": r2,
            "RMSE (€)": rmse,
            "MAE (€)": mae,
            "Error % (MAPE)": mape
        })
        
        print(f"   ✓ {name:<35} | R² = {r2:.3f} | RMSE = {rmse:,.0f}€ | MAE = {mae:,.0f}€")
    
    df_results = pd.DataFrame(results).sort_values(by="R² Score", ascending=False).reset_index(drop=True)
    return df_results

def evaluate_classification_model(X_train_scaled, X_test_scaled, y_train, y_test):
    """Algoritmo 11: Regresión Logística para Clasificación de Vivienda Premium"""
    print("\n🎯 4. Algoritmo 11: Regresión Logística (Clasificación Binaria: ¿Es Vivienda Premium?)")
    print("=" * 80)
    
    # Definimos la clase "Premium" como viviendas cuyo precio supera la mediana
    threshold = y_train.median()
    y_train_class = (y_train > threshold).astype(int)
    y_test_class = (y_test > threshold).astype(int)
    
    clf = LogisticRegression(max_iter=1000, random_state=42)
    clf.fit(X_train_scaled, y_train_class)
    
    y_pred_class = clf.predict(X_test_scaled)
    y_pred_prob = clf.predict_proba(X_test_scaled)[:, 1]
    
    acc = accuracy_score(y_test_class, y_pred_class)
    prec = precision_score(y_test_class, y_pred_class)
    rec = recall_score(y_test_class, y_pred_class)
    f1 = f1_score(y_test_class, y_pred_class)
    auc = roc_auc_score(y_test_class, y_pred_prob)
    cm = confusion_matrix(y_test_class, y_pred_class)
    
    print(f"   • Umbral de precio para ser 'Premium': > {threshold:,.0f}€")
    print(f"   • Accuracy (Exactitud Global): {acc*100:.1f}%")
    print(f"   • Precision (Calidad de la predicción Premium): {prec*100:.1f}%")
    print(f"   • Recall (Capacidad de detectar Premium reales): {rec*100:.1f}%")
    print(f"   • F1-Score (Equilibrio Precision-Recall): {f1*100:.1f}%")
    print(f"   • ROC-AUC (Área bajo la curva ROC): {auc:.3f}")
    print("\n   • Matriz de Confusión:")
    print(f"     [Verdaderos Negativos: {cm[0][0]:2d} | Falsos Positivos:  {cm[0][1]:2d}]")
    print(f"     [Falsos Negativos:     {cm[1][0]:2d} | Verdaderos Positivos: {cm[1][1]:2d}]")
    
    return {
        "Accuracy": acc,
        "Precision": prec,
        "Recall": rec,
        "F1-Score": f1,
        "ROC-AUC": auc
    }

def main():
    print("=" * 80)
    print("🚀 INICIANDO PIPELINE DE MACHINE LEARNING: POSTGRESQL -> PYTHON PANDAS -> ML")
    print("=" * 80)
    
    # 1. Cargar datos desde PostgreSQL
    df = load_data_from_postgres()
    
    # 2. Preprocesamiento
    X, y, X_train, X_test, y_train, y_test, X_train_scaled, X_test_scaled = preprocess_features(df)
    
    # 3. Evaluar los 10 Modelos de Regresión
    df_reg_results = evaluate_regression_models(
        X_train, X_test, y_train, y_test, X_train_scaled, X_test_scaled
    )
    
    # 4. Evaluar el Modelo 11 de Clasificación (Regresión Logística)
    clf_results = evaluate_classification_model(
        X_train_scaled, X_test_scaled, y_train, y_test
    )
    
    # 5. Tabla Resumen Final de Regresión
    print("\n🏆 TABLA COMPARATIVA DE LOS MODELOS DE REGRESIÓN (Ordenados por R²):")
    print("=" * 80)
    print(df_reg_results.to_string(index=False))
    print("=" * 80)
    print("✨ ¡Pipeline completado con éxito!")

if __name__ == "__main__":
    main()
