FROM astral/uv:python3.13-trixie-slim

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --locked

# Copy project files
COPY src/ src/

# Expose port
EXPOSE 8000

# Run the application
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
