import mysql.connector
from datetime import datetime, timedelta
import random
from dotenv import load_dotenv
import os

load_dotenv()

def insert_sample_data():
    try:
        # Connect to database
        connection = mysql.connector.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database='mydb'
        )
        
        if connection.is_connected():
            cursor = connection.cursor()
            
            # Generate 24 hours of sample data with 2-hour intervals
            base_price = 180  # Starting price
            current_time = datetime.now()
            
            # Insert data for the last 7 days
            for i in range(7 * 12):  # 7 days * 12 two-hour intervals
                # Generate a random price variation between -5 and +5
                price_variation = random.uniform(-5, 5)
                price = base_price + price_variation
                
                # Calculate timestamp for this data point
                timestamp = current_time - timedelta(hours=i*2)
                
                # Insert the data
                insert_query = """
                INSERT INTO orbwatcher 
                (currency_id, currency_name, price_value, exchange_price_value, date)
                VALUES (%s, %s, %s, %s, %s)
                """
                data = (
                    'divine',
                    'Divine Orb',
                    f"{price:.1f}",
                    "0",  # We're not using exchange price
                    timestamp.strftime('%Y-%m-%d %H:%M:%S')
                )
                
                cursor.execute(insert_query, data)
                
                # Update base price for next iteration (slight trend)
                base_price += random.uniform(-1, 1)
            
            connection.commit()
            print("Sample data inserted successfully!")
            
    except mysql.connector.Error as err:
        print(f"Error: {err}")
    finally:
        if 'connection' in locals() and connection.is_connected():
            cursor.close()
            connection.close()
            print("MySQL connection closed.")

if __name__ == "__main__":
    insert_sample_data() 