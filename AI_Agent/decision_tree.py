import pandas as pd
from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import joblib
import os

def prepare_data_for_training(df):
    """
    Prepare the raw sensor data for training.
    Extracts 'day', 'temperature', 'moisture', and 'label', ignoring timestamp.
    """
    #if 'timestamp' in df.columns:
        #df['timestamp'] = pd.to_datetime(df['timestamp'])
        # Extract the day of the year as the 'day' feature if it's not present
        #df['day'] = df['timestamp'].dt.dayofyear
        
    required_cols = ['day', 'temperature', 'moisture', 'label']
    return df[required_cols].dropna()

def train_model(csv_path, model_path='decision_tree_model.joblib'):
    """
    Train the Decision Tree model using individual data points.
    """
    print(f"Loading data from {csv_path}...")
    df = pd.read_csv(csv_path)
    
    print("Preparing features...")
    processed_df = prepare_data_for_training(df)
    
    X = processed_df[['day', 'temperature', 'moisture']]
    y = processed_df['label']
    
    # Train test split on individual rows
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Train using Gini index
    clf_gini = DecisionTreeClassifier(criterion="gini", random_state=100, max_depth=3, min_samples_leaf=5)
    clf_gini.fit(X_train, y_train)
    y_pred_gini = clf_gini.predict(X_test)
    accuracy_gini = accuracy_score(y_test, y_pred_gini) * 100
    
    # Train using Entropy
    clf_entropy = DecisionTreeClassifier(criterion="entropy", random_state=100, max_depth=3, min_samples_leaf=5)
    clf_entropy.fit(X_train, y_train)
    y_pred_entropy = clf_entropy.predict(X_test)
    accuracy_entropy = accuracy_score(y_test, y_pred_entropy) * 100
    
    print(f"Accuracy with Gini:    {accuracy_gini:.2f}%")
    print(f"Accuracy with Entropy: {accuracy_entropy:.2f}%")
    
    # Select the best model
    if accuracy_gini >= accuracy_entropy:
        best_clf = clf_gini
        print("Selecting Gini model as the best performer.")
    else:
        best_clf = clf_entropy
        print("Selecting Entropy model as the best performer.")
    
    # Save the model
    joblib.dump(best_clf, model_path)
    print(f"Model saved to {model_path}")
    
    return best_clf

def predict_next_task(sensor_data_df, model_path='decision_tree_model.joblib'):
    """
    Predict the recommended task based on a single day of sensor readings.
    
    Args:
        sensor_data_df: A pandas DataFrame containing today's readings.
        model_path: Path to the saved joblib model.
        
    Returns:
        String representing the recommended task label.
    """
    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model not found at {model_path}. Please train the model first.")
        
    clf = joblib.load(model_path)
    
    # Determine the 'day' value
    if 'timestamp' in sensor_data_df.columns:
        sensor_data_df['timestamp'] = pd.to_datetime(sensor_data_df['timestamp'])
        current_day = sensor_data_df['timestamp'].dt.dayofyear.iloc[-1]
    else:
        current_day = pd.Timestamp.now().dayofyear
        
    # Average today's readings
    avg_temp = sensor_data_df['temperature'].mean()
    avg_moist = sensor_data_df['moisture'].mean()
    
    features_df = pd.DataFrame([{
        'day': current_day,
        'temperature': avg_temp,
        'moisture': avg_moist
    }])
    
    # Predict the recommended task
    prediction = clf.predict(features_df)
    
    return prediction[0]

if __name__ == '__main__':
    # Script entry point to train and save the model
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    CSV_FILE = os.path.join(BASE_DIR, 'compost_data.csv')
    MODEL_FILE = os.path.join(BASE_DIR, 'decision_tree_model.joblib')
    
    if os.path.exists(CSV_FILE):
        train_model(CSV_FILE, MODEL_FILE)
    else:
        print(f"Data file not found: {CSV_FILE}")