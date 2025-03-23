FROM python:3.12-slim
WORKDIR /app

#install chormium
RUN apt-get update && apt-get install -y chromium chromium-driver && rm -rf /var/lib/apt/lists/*

#install requirements
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY myapp/webapp .

EXPOSE 5000

CMD ["python", "app.py"]

