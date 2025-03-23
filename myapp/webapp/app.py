from flask import Flask, render_template, jsonify
import mysql.connector
import os
from dotenv import load_dotenv
from orbwatch import search_prices, init_database

load_dotenv()

app = Flask(__name__)

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
    #get last 2 days of data
    query = """
    SELECT * FROM orbwatcher 
    WHERE date >= DATE_SUB(NOW(), INTERVAL 2 DAY)
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