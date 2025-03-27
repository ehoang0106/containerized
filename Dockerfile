FROM python:3.12-slim
WORKDIR /app


RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver && \
    chmod +x /usr/bin/chromedriver && \
    rm -rf /var/lib/apt/lists/*


COPY requirements.txt .
RUN pip install -r requirements.txt

COPY myapp/webapp .

EXPOSE 80

CMD ["python", "app.py"]
