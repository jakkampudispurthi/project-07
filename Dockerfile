# Pin the base image to a specific version — never :latest
FROM python:3.12.6-slim

# Create a non-root user to run the app (security requirement)
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /code

# Copy ONLY requirements first, install them, THEN copy source code.
# This ordering matters for Docker's layer cache: if you only change
# app.py later, Docker won't have to reinstall all dependencies again.
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the actual source code
COPY app/app.py .

# Switch to the non-root user before running anything
USER appuser

EXPOSE 8000

# HEALTHCHECK hits a real endpoint, not just "is the process alive"
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import httpx; httpx.get('http://localhost:8000/health').raise_for_status()"

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]