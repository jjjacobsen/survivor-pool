FROM astral/uv:python3.13-trixie-slim

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --locked --no-dev

# Copy project files
COPY src/ src/

# Expose port
EXPOSE 8001

# Create non-root user with a real home for uv cache
RUN adduser --system --group --home /home/appuser appuser \
    && chown -R appuser:appuser /app /home/appuser

ENV HOME=/home/appuser

# Run the application
USER appuser
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8001"]
