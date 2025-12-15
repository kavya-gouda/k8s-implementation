# Scenario 1: The Wrong Way (Heartbeat Only)

## The Problem

This scenario demonstrates a common anti-pattern: health checks that only verify the server process is alive, not whether it can actually serve traffic.

## What's Wrong
```python
@app.route('/health')
def health():
    # BAD: Only checks if server responds
    return jsonify({"status": "ok"}), 200
```

The health endpoint returns 200 as long as the Flask server is running, even when:
- Database connection is lost
- External dependencies are down
- Application is in an error state

## Run the Scenario
```bash
./run.sh
```

## Test It
```bash
# Get a pod name
POD_NAME=$(kubectl get pod -l app=bad-health-app -o jsonpath='{.items[0].metadata.name}')

# Break the database connection
kubectl exec $POD_NAME -- python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/break-db').read().decode())"

# Check pod status - it will still show READY! ❌
kubectl get pods -l app=bad-health-app

# Try to access the API - returns 500 errors
kubectl run curl-test --image=curlimages/curl -i --rm --restart=Never -- \
  curl -s http://bad-health-app/api/data
```

## Expected Behavior (Wrong!)

- Pod shows `1/1 READY`
- API calls return 500 errors
- Kubernetes keeps routing traffic to the broken pod
- Users experience failures

## Why This Is Bad

- No automatic remediation
- Users get errors while K8s thinks everything is fine
- No visibility into actual application health
- Incidents go undetected

## Cleanup
```bash
kubectl delete -f deployment.yaml
```
