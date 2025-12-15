# Scenario 2: The Right Way (Proper Probe Separation)

## The Solution

Separate liveness and readiness probes with distinct responsibilities.

## What's Right
```python
@app.route('/health/liveness')
def liveness():
    """Only checks internal application state"""
    if internal_deadlock:
        return 500
    return 200

@app.route('/health/readiness')
def readiness():
    """Checks if app can handle traffic"""
    if not db_connected or not startup_complete:
        return 503
    return 200
```

## Run the Scenario
```bash
./run.sh
```

## Test It
```bash
POD_NAME=$(kubectl get pod -l app=good-health-app -o jsonpath='{.items[0].metadata.name}')

# Test 1: DB failure (should become Not Ready, not restart)
kubectl exec $POD_NAME -- python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/simulate/db-down').read().decode())"
kubectl get pods -l app=good-health-app  # Shows 0/1 READY

# Restore
kubectl exec $POD_NAME -- python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/simulate/db-up').read().decode())"

# Test 2: Internal deadlock (should restart)
kubectl exec $POD_NAME -- python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/simulate/deadlock').read().decode())"
kubectl get pods -l app=good-health-app -w  # Watch it restart
```

## Expected Behavior (Correct!)

1. **During startup**: `0/1 READY` for ~10 seconds ✅
2. **DB failure**: `Running 0/1` - removed from service, not restarted ✅
3. **Internal deadlock**: Pod restarts ✅
4. **Traffic**: Only to `1/1 READY` pods ✅

## Key Differences

| Aspect | Liveness | Readiness |
|--------|----------|-----------|
| Purpose | Detect unrecoverable state | Detect inability to serve |
| Checks | Internal state only | Dependencies + internal |
| Failure Action | Restart pod | Remove from service |
| Interval | 20-30s | 5-10s |
| Timeout | 10s+ | 3-5s |
| Threshold | 3-5 failures | 2-3 failures |

## Cleanup
```bash
kubectl delete -f deployment.yaml
```
