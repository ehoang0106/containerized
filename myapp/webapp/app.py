from flask import Flask, render_template, jsonify
from dotenv import load_dotenv
from orbwatch import search_prices, init_database
import schedule
import time

load_dotenv()

app = Flask(__name__)

def update_prices():
    try:
        search_prices('currency')
        print("Price update completed successfully")
    except Exception as e:
        print(f"Error updating prices: {e}")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/data')
def get_data():
    connection = init_database()
    if not connection:
        print("Database connection failed")
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
            print("No data available")
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
        print(f"Error updating data: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    #schedule the job to run every hour
    schedule.every(1).hour.do(update_prices)
    
    #run the first update
    update_prices()
    while True:
        schedule.run_pending()
        app.run(host='0.0.0.0', port=80, debug=True)
        time.sleep(1)
   