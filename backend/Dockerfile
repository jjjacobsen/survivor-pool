FROM astral/uv:python3.13-trixie-slim

# Set working directory
WORKDIR /app

# Force backend to boot in production mode
ENV APP_ENV=prod

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies
RUN uv sync --locked

# Copy project files
COPY src/ src/
COPY env/ env/

# Expose port
EXPOSE 8001

# Run the application
CMD ["uv", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8001"]
