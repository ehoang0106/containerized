from flask import Flask, render_template, jsonify
import mysql.connector
import os
import sys
from dotenv import load_dotenv
from datetime import datetime, timedelta

#add parent directory to python path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from orbwatch import search_prices

load_dotenv()

app = Flask(__name__)

def init_database():
  try:
    #connect to database
    connection = mysql.connector.connect(
      host=os.getenv('DB_HOST'),
      user=os.getenv('DB_USER'),
      password=os.getenv('DB_PASSWORD')
    )
    
    if connection.is_connected():
      cursor = connection.cursor()
      print("Connected to database")
      
      #create database if it doesn't exist
      cursor.execute("CREATE DATABASE IF NOT EXISTS mydb")
      cursor.execute("USE mydb")
      
      #create table if it doesn't exist
      create_table_query = """
      CREATE TABLE IF NOT EXISTS orbwatcher (
        id INT AUTO_INCREMENT PRIMARY KEY,
        currency_id VARCHAR(255),
        currency_name VARCHAR(255),
        price_value VARCHAR(255),
        exchange_price_value VARCHAR(255),
        date DATETIME,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
      """
      cursor.execute(create_table_query)
      connection.commit()
      
      return connection
    else:
      print("Failed to connect to database")
      return None
    
    
  except mysql.connector.Error as err:
    print(f"Error connecting to MySQL: {err}")
    return None

@app.route('/')
def index():
  return render_template('index.html')

@app.route('/api/data')
def get_data():
  connection = init_database()
  if not connection:
    return jsonify({'error': 'Database connection failed'}), 500

  try:
    cursor = connection.cursor(dictionary=True)
    
    #get the latest data point
    query = """
    SELECT * FROM orbwatcher 
    ORDER BY date DESC 
    LIMIT 1
    """
    cursor.execute(query)
    data = cursor.fetchall()
    
    if not data:
      return jsonify({'error': 'No data available'}), 404
    
    #format data for Chart.js
    formatted_data = {
      'labels': [data[0]['date'].strftime('%Y-%m-%d %H:%M')],
      'prices': [float(data[0]['price_value'].replace(',', ''))]
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