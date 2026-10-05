FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY V41_requirements.txt .
RUN pip install --no-cache-dir -r V41_requirements.txt

COPY V41_common.py V41_app.py V41_worker.py ./
COPY static ./static

# Run as a non-root user.
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# gunicorn instead of Flask's development server. The Container Apps ingress
# terminates HTTPS and forwards traffic here on port 8000.
# gthread: several uploads (2-5 MB photos) can be in flight per worker.
# The notification job reuses this image and overrides the command with
# "python V41_worker.py" (see V41_resources.bicep).
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "4", "--worker-class", "gthread", "--timeout", "60", "V41_app:app"]
