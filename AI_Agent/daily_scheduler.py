import os
import sys
import pandas as pd
from datetime import datetime, timedelta, timezone, time

# Add the parent directory to the path to import modules of backend and model
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
from models import CompostPile, HealthRecord, Task
from AI_Agent.decision_tree import predict_next_task

def run_daily_predictions():
    """
    Script that runs daily (e.g., via cron at 00:00).
    Queries the previous day's records for all piles of every user
    and uses the Decision Tree to schedule the recommended task for the day.
    """
    db = SessionLocal()
    
    # 1. Define the "Yesterday" window
    yesterday = datetime.now(timezone.utc) - timedelta(days=1)
    start_of_yesterday = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
    end_of_yesterday = start_of_yesterday + timedelta(days=1)
    target_schedule_date = datetime.now(timezone.utc).date() # The task is for "Today"

    try:
        # Get all piles from all users
        all_piles = db.query(CompostPile).all()
        print(f"[{datetime.now()}] Starting scheduler for {len(all_piles)} piles...")

        for pile in all_piles:
            # 2. Query the database directly (emulating API input)
            records = db.query(HealthRecord).filter(
                HealthRecord.pile_id == pile.pile_id,
                HealthRecord.timestamp >= start_of_yesterday,
                HealthRecord.timestamp < end_of_yesterday
            ).all()

            if not records:
                print(f"  - Pile ID {pile.pile_id}: No records for yesterday. Skipping.")
                continue

            # Convert the data to the pandas format expected by the model
            records_data = []
            for r in records:
                records_data.append({
                    'timestamp': r.timestamp,
                    'temperature': float(r.temperature) if r.temperature else None,
                    'moisture': float(r.moisture) if r.moisture else None
                })
            
            df = pd.DataFrame(records_data).dropna()

            if df.empty:
                print(f"  - Pile ID {pile.pile_id}: Records without valid data. Skipping.")
                continue

            # 3. Call the predict_next_task() function
            prediction_label = predict_next_task(df, model_path='AI_Agent/decision_tree_model.joblib')

            # 4. Formulate a friendly title according to the predicted label for the current pile
            action_map = {
                'TURN_PILE': f"Turn {pile.name}",
                'WATER_PILE': f"Water {pile.name}",
                'ADD_BROWNS': f"Add Browns to {pile.name}",
                'HARVEST': f"Harvest {pile.name}",
                'MONITOR': f"Monitor {pile.name} (Curing/Active)"
            }
            task_title = action_map.get(prediction_label, f"Review {pile.name}")

            print(f"  - Pile ID {pile.pile_id} ({pile.name}): Prediction = {prediction_label}. Creating task...")

            # 5. Save the new task
            new_task = Task(
                pile_id=pile.pile_id,
                title=task_title,
                action_type=prediction_label,
                date_scheduled=target_schedule_date,
                status="Active"
            )
            db.add(new_task)

        db.commit()
        print(f"[{datetime.now()}] Daily process finished successfully.")

    except Exception as e:
        print(f"Error processing daily predictions: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    run_daily_predictions()
