from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
import mysql.connector
from datetime import datetime
import pytz
from decimal import Decimal, InvalidOperation
import os
from dotenv import load_dotenv


load_dotenv()

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
      
      #create table if doesn't exist
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
      
      print("Connected to MySQL")
      return connection
  except mysql.connector.Error as err:
    print(f"Error connecting to MySQL: {err}")
    return None




def insert_into_mysql(connection, currency_id, currency_name, price_value, exchange_price_value, date):
  try:
    cursor = connection.cursor()
    insert_query = """
    INSERT INTO orbwatcher (currency_id, currency_name, price_value, exchange_price_value, date)
    VALUES (%s, %s, %s, %s, %s)
    """
    cursor.execute(insert_query, (currency_id, currency_name, price_value, exchange_price_value, date))
    connection.commit()
    return True
  except mysql.connector.Error as err:
    print(f"Error inserting data: {err}")
    return False


def init_driver():
  options = Options()
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--log-level=3")
  options.add_argument("--remote-debugging-port=9222")
  options.add_argument("--enable-unsafe-swiftshader")
  options.add_argument("--disable-software-rasterizer")
  options.add_argument("--disable-extensions")
  options.add_argument("--disable-setuid-sandbox")
  options.add_argument("--no-first-run")
  options.add_argument("--no-default-browser-check")
  options.add_argument("--disable-popup-blocking")
  options.add_argument("--disable-notifications")
  options.add_argument("--user-data-dir=/tmp/chromium-data")
  options.add_experimental_option("excludeSwitches", ["enable-logging"])
  options.binary_location = "/usr/bin/chromium-browser"
  driver = webdriver.Chrome(service=Service(ChromeDriverManager(driver_version="134.0.6998.117").install()), options=options)
  return driver

def search_prices(type):
  #initialize connection
  connection = init_database()
  if not connection:
    print("Failed to connect to database")
    return []

  driver = init_driver()
  url = f"https://orbwatch.trade/#{type}"
  driver.get(url)
  
  WebDriverWait(driver, 10).until(
    EC.presence_of_element_located((By.CSS_SELECTOR, 'span[data-tooltip-id]'))
  )
  
  soup = BeautifulSoup(driver.page_source, 'html.parser')
  
  data = []
  
  #find the specific row with data-tooltip-id="divine"
  divine_span = soup.find('span', {'data-tooltip-id': 'divine'})
  if divine_span:
    row = divine_span.find_parent('tr')
    if row:
      currency_name = divine_span.text
      currency_id = divine_span['data-tooltip-id']
      price_value_span = row.find('span', {'class': 'price-value'})
      if price_value_span:
        price_value = price_value_span.text
        price_arrow_span = price_value_span.find_next('span', {'class': 'price-arrow'})
        if price_arrow_span:
          exchange_price_value_span = price_arrow_span.find_next('span', {'class': 'price-value'})
          if exchange_price_value_span:
            exchange_price_value = exchange_price_value_span.text
            formatted_currency_name = currency_name.replace(" ", "").replace("'", "").replace("(", "").replace(")", "")
            
            data.append({
              'currency_id': currency_id,
              'currency_name': currency_name,
              'price_value': price_value,
              'exchange_price_value': exchange_price_value,
              'formatted_currency_name': formatted_currency_name
            })
            
            date = datetime.now(pytz.timezone('America/Los_Angeles')).strftime("%Y-%m-%d %H:%M")
            #insert data into MySQL
            insert_into_mysql(connection, currency_id, currency_name, price_value, exchange_price_value, date)
            
  last_update = soup.find('div', {'class': 'timestamp'}).text
  if last_update:
    print(f"{last_update}")
  
  driver.quit()
  
  #close connection
  if connection.is_connected():
    connection.close()
  
  return data
