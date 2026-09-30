FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY V40_requirements.txt .
RUN pip install --no-cache-dir -r V40_requirements.txt

COPY V40_app.py .
COPY static ./static

# Run as a non-root user.
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# gunicorn instead of Flask's development server. The Container Apps ingress
# terminates HTTPS and forwards traffic here on port 8000.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "60", "V40_app:app"]
