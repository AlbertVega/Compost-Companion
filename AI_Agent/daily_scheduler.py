import os
import sys
import pandas as pd
from datetime import datetime, timedelta, timezone

# Agregamos la ruta principal para importar los módulos de backend y del modelo 
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models import CompostPile, HealthRecord, Task
from AI_Agent.decision_tree import predict_next_task

def run_daily_predictions():
    """
    Script que se ejecuta diariamente (ej. vía cron a las 00:00).
    Consulta los registros del día anterior para todos los piles de cada usuario
    y utiliza el Decision Tree para programar la tarea recomendada del día.
    """
    db = SessionLocal()
    
    # 1. Definir la ventana de "Ayer"
    yesterday = datetime.now(timezone.utc) - timedelta(days=1)
    start_of_yesterday = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_yesterday = start_of_yesterday + timedelta(days=1)
    target_schedule_date = datetime.now(timezone.utc).date() # La tarea es para "Hoy"

    try:
        # Obtenemos todos los piles de todos los usuarios
        all_piles = db.query(CompostPile).all()
        print(f"[{datetime.now()}] Iniciando scheduler para {len(all_piles)} piles...")

        for pile in all_piles:
            # 2. Consultamos directamente la base de datos (emulando la entrada del API)
            records = db.query(HealthRecord).filter(
                HealthRecord.pile_id == pile.pile_id,
                HealthRecord.timestamp >= start_of_yesterday,
                HealthRecord.timestamp < end_of_yesterday
            ).all()

            if not records:
                print(f"  - Pile ID {pile.pile_id}: Sin registros el día de ayer. Se omite.")
                continue

            # Convertimos la data al formato de pandas que espera el modelo
            records_data = []
            for r in records:
                records_data.append({
                    'timestamp': r.timestamp,
                    'temperature': float(r.temperature) if r.temperature else None,
                    'moisture': float(r.moisture) if r.moisture else None
                })
            
            df = pd.DataFrame(records_data).dropna()

            if df.empty:
                print(f"  - Pile ID {pile.pile_id}: Registros sin data válida. Se omite.")
                continue

            # 3. Convocamos a la función predict_next_task()
            prediction_label = predict_next_task(df, model_path='AI_Agent/decision_tree_model.joblib')

            # 4. Formulamos un título amigable según la etiqueta predicha para la pila actual
            action_map = {
                'TURN_PILE': f"Turn {pile.name}",
                'WATER_PILE': f"Water {pile.name}",
                'ADD_BROWNS': f"Add Browns to {pile.name}",
                'HARVEST': f"Harvest {pile.name}",
                'MONITOR': f"Monitor {pile.name} (Curing/Active)"
            }
            task_title = action_map.get(prediction_label, f"Review {pile.name}")

            print(f"  - Pile ID {pile.pile_id} ({pile.name}): Predicción = {prediction_label}. Creando task...")

            # 5. Guardamos la nueva tarea
            new_task = Task(
                pile_id=pile.pile_id,
                title=task_title,
                action_type=prediction_label,
                date_scheduled=target_schedule_date,
                status="Active"
            )
            db.add(new_task)

        db.commit()
        print(f"[{datetime.now()}] Proceso diario finalizado con éxito.")

    except Exception as e:
        print(f"Error procesando las predicciones diarias: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    run_daily_predictions()
