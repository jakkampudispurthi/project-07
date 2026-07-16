import os
import httpx
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

app = FastAPI()

# The Ollama backend URL comes from an environment variable, not hardcoded.
# Inside Docker Compose, "ollama" is the service name, not localhost.
OLLAMA_URL = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/v1/chat/completions")
async def chat(request: Request):
    body = await request.json()

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{OLLAMA_URL}/v1/chat/completions",
            json=body,
        )

    data = response.json()
    data["verified"] = False  # Reminder: this box delivers the model's words faithfully;
                               # it does not verify their truth. A human must check.
    return JSONResponse(content=data)