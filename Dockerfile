FROM python:3.10-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt || echo "No requirements"
EXPOSE 8000
CMD ["python", "main.py"]
