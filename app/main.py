import json, logging, random, time, uuid

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger("app")

ENDPOINTS = ["/api/orders", "/api/users", "/api/products", "/api/health", "/api/search"]
METHODS = ["GET", "POST", "PUT", "DELETE"]
STATUS_WEIGHTS = [(200, 60), (201, 10), (400, 8), (401, 5), (403, 3), (404, 8), (500, 4), (503, 2)]
STATUSES, WEIGHTS = zip(*STATUS_WEIGHTS)

def emit():
    status = random.choices(STATUSES, WEIGHTS)[0]
    level = "ERROR" if status >= 500 else "WARN" if status >= 400 else "INFO"
    duration = random.randint(5, 2000) if status < 500 else random.randint(1000, 8000)
    log = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "level": level,
        "request_id": str(uuid.uuid4()),
        "method": random.choice(METHODS),
        "endpoint": random.choice(ENDPOINTS),
        "status": status,
        "duration_ms": duration,
        "message": f"{level}: {status} response",
    }
    logger.info(json.dumps(log))

if __name__ == "__main__":
    while True:
        emit()
        time.sleep(random.uniform(0.5, 3.0))
