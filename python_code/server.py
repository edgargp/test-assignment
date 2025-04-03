import requests
import uvicorn  
from fastapi import FastAPI, Response, status
from fastapi.responses import PlainTextResponse 


METADATA_URL = "http://169.254.169.254/latest/meta-data/hostname"
HOSTNAME = "unknown" 
try:
    response = requests.get(METADATA_URL, timeout=5)
    response.raise_for_status() 
    HOSTNAME = response.text
except requests.exceptions.RequestException as e:
    print(f"Warning: Could not fetch hostname. Error: {e}")
    print(f"Running with default hostname: {HOSTNAME}")

app = FastAPI(
    title="Simple App"
)
# --- Healthcheck ---
healthcheck_status_code: int = status.HTTP_200_OK
healthcheck_message: str = f"OK {status.HTTP_200_OK}"

# --- API Endpoints ---
@app.get("/healthcheck", response_class=PlainTextResponse)
async def healthcheck():
    """
    Returns the current health status message and sets the corresponding HTTP status code.
    """
    return PlainTextResponse(content=healthcheck_message, status_code=healthcheck_status_code)

@app.get("/", response_class=PlainTextResponse)
async def home():
    """
    Returns the public hostname of the instance fetched from metadata.
    """
    return PlainTextResponse(content=HOSTNAME, status_code=status.HTTP_200_OK)

@app.get("/terminate-instance", response_class=PlainTextResponse)
async def terminate_instance():
    global healthcheck_status_code, healthcheck_message
    healthcheck_status_code = status.HTTP_404_NOT_FOUND
    healthcheck_message = f"Healthcheck Fails {status.HTTP_404_NOT_FOUND}"

    return PlainTextResponse(content=f"Healthcheck status set to {status.HTTP_404_NOT_FOUND}", status_code=status.HTTP_200_OK)


if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=5000, reload=True)