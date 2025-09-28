from fastapi import FastAPI
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
import time
import random
import uvicorn

app = FastAPI(title="DevOps Stack API", version="1.0.0")

# Métriques Prometheus
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
BUSINESS_METRIC = Counter('business_operations_total', 'Business operations counter', ['operation'])

@app.middleware("http")
async def prometheus_middleware(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    REQUEST_DURATION.observe(duration)
    
    return response

@app.get("/")
def read_root():
    return {"message": "Stack DevOps API is running!", "version": "1.0.0"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": time.time()}

@app.get("/simulate-load")
def simulate_load():
    processing_time = random.uniform(0.1, 2.0)
    time.sleep(processing_time)
    
    BUSINESS_METRIC.labels(operation="data_processing").inc()
    
    return {
        "message": "Load simulation completed",
        "processing_time": processing_time,
        "load_level": "high" if processing_time > 1.0 else "normal"
    }

@app.get("/api/users")
def get_users():
    BUSINESS_METRIC.labels(operation="user_fetch").inc()
    return {"users": [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]}

@app.get("/metrics")
def get_metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
