from flask import Flask, render_template, jsonify
import mysql.connector
import os
import sys
from dotenv import load_dotenv
from datetime import datetime, timedelta

# Add parent directory to Python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from orbwatch import search_prices

load_dotenv()

app = Flask(__name__)

def get_db_connection():
  try:
    connection = mysql.connector.connect(
      host=os.getenv('DB_HOST'),
      user=os.getenv('DB_USER'),
      password=os.getenv('DB_PASSWORD'),
      database=os.getenv('DB_NAME')
    )
    return connection
  except mysql.connector.Error as err:
    print(f"Error connecting to MySQL: {err}")
    return None

@app.route('/')
def index():
  return render_template('index.html')

@app.route('/api/data')
def get_data():
  connection = get_db_connection()
  if not connection:
    return jsonify({'error': 'Database connection failed'}), 500

  try:
    cursor = connection.cursor(dictionary=True)
    # Get last 24 hours of data
    query = """
    SELECT * FROM orbwatcher 
    WHERE date >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
    ORDER BY date ASC
    """
    cursor.execute(query)
    data = cursor.fetchall()
    
    # Format data for Chart.js
    formatted_data = {
      'labels': [row['date'].strftime('%Y-%m-%d %H:%M') for row in data],
      'prices': [float(row['price_value'].replace(',', '')) for row in data]
    }
    
    return jsonify(formatted_data)
  except Exception as e:
    return jsonify({'error': str(e)}), 500
  finally:
    if connection.is_connected():
      connection.close()

@app.route('/api/update')
def update_data():
  try:
    search_prices('currency')
    return jsonify({'status': 'success'})
  except Exception as e:
    return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
  app.run(debug=True) 