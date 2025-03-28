FROM python:3.12-slim

# Set working directory
WORKDIR /app

RUN apt-get update && apt-get install -y chromium chromium-driver && rm -rf /var/lib/apt/lists/*

# Install gunicorn
RUN pip install gunicorn

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy the orbwatch.py to the correct location
COPY myapp/webapp/orbwatch.py /app/orbwatch.py

# Copy the rest of the webapp
COPY myapp/webapp /app/myapp/webapp

# Set Python path to include both the app root and webapp directory
ENV PYTHONPATH=/app:/app/myapp/webapp

# Expose the port Gunicorn will listen on
EXPOSE 80

# Run Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:80", "--workers", "3", "--log-level", "debug", "myapp.webapp.app:app"]
