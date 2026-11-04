from collections import defaultdict, deque
from threading import Lock
from time import monotonic

from flask import current_app, jsonify, request

_buckets = defaultdict(deque)
_lock = Lock()


def consume(key: str, limit: int, window_seconds: int) -> int:
    if limit <= 0 or window_seconds <= 0:
        return 0
    now = monotonic()
    with _lock:
        bucket = _buckets[key]
        cutoff = now - window_seconds
        while bucket and bucket[0] <= cutoff:
            bucket.popleft()
        if len(bucket) >= limit:
            return max(1, int(window_seconds - (now - bucket[0])) + 1)
        bucket.append(now)
        return 0


def enforce(key: str, limit_config: str, window_config: str) -> int:
    limit = int(current_app.config.get(limit_config, 0))
    window = int(current_app.config.get(window_config, 0))
    return consume(key, limit, window)


def client_ip() -> str:
    return request.remote_addr or "desconocido"


def too_many_requests(retry_after: int):
    response = jsonify({"error": "Demasiadas solicitudes. Intenta de nuevo más tarde."})
    response.status_code = 429
    response.headers["Retry-After"] = str(max(1, retry_after))
    return response


def reset_rate_limits():
    with _lock:
        _buckets.clear()
