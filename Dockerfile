FROM python:3-alpine

WORKDIR /app

RUN apk add --no-cache \
    gcc \
    musl-dev 

# Copy all files to workdir
COPY stale-tickets-notifier.py .
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

CMD ./stale-tickets-notifier.py
