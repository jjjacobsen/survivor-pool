# survivor-pool

Survivor Pool App for the TV Show Survivor

## Development Commands

- run webserver

    ```bash
    cd frontend/survivor_pool
    flutter run -d web-server
    ```

- run api

    ```bash
    cd backend
    uv run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
    ```
