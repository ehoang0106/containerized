FROM python:3.12-slim

# Set working directory
WORKDIR /app

RUN apt-get update && apt-get install -y chromium chromium-driver && rm -rf /var/lib/apt/lists/*

RUN pip install gunicorn

COPY requirements.txt .
RUN pip install -r requirements.txt
COPY myapp/webapp/orbwatch.py /app/orbwatch.py

COPY myapp/webapp /app/myapp/webapp

ENV PYTHONPATH=/app:/app/myapp/webapp

EXPOSE 80

CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "3", "--log-level", "debug", "myapp.webapp.app:app"]
