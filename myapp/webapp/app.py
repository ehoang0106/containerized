from flask import Flask, render_template, jsonify
import mysql.connector
import os
from dotenv import load_dotenv
from orbwatch import search_prices

load_dotenv()

app = Flask(__name__)

def init_database():
  try:
    #connect db
    connection = mysql.connector.connect(
      host=os.getenv('DB_HOST'),
      user=os.getenv('DB_USER'),
      password=os.getenv('DB_PASSWORD')
    )
    
    if connection.is_connected():
      cursor = connection.cursor()
      
      #create db if doesn't exist 
      cursor.execute("CREATE DATABASE IF NOT EXISTS mydb")
      cursor.execute("USE mydb")
      
      
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
    #get last 7 days of data
    query = """
    SELECT * FROM orbwatcher 
    WHERE date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ORDER BY date ASC
    """
    cursor.execute(query)
    data = cursor.fetchall()
    
    if not data:
      return jsonify({'error': 'No data available'}), 404
    
    #format data for Chart.js
    labels = []
    prices = []
    
    for row in data:
      labels.append(row['date'].strftime('%Y-%m-%d %H:%M'))
      prices.append(float(row['price_value'].replace(',', '')))
  
    formatted_data = {
      'labels': labels,
      'prices': prices
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
  app.run(host='0.0.0.0', port=5000, debug=True) 