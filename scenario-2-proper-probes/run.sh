#!/bin/bash
set -e

echo "🚀 Building good-health-app..."
docker build -t good-health-app:v1 .

echo "📦 Loading image into cluster..."
if command -v minikube &> /dev/null; then
    minikube image load good-health-app:v1
else
    docker save good-health-app:v1 | sudo k3s ctr images import -
fi

echo "🎯 Deploying application..."
kubectl apply -f deployment.yaml

echo "⏳ Watching startup (notice 0/1 during initialization)..."
sleep 2
kubectl get pods -l app=good-health-app

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📝 Test proper behavior:"
echo "   POD_NAME=\$(kubectl get pod -l app=good-health-app -o jsonpath='{.items[0].metadata.name}')"
echo "   # Simulate DB failure"
echo "   kubectl exec \$POD_NAME -- python -c \"import urllib.request; print(urllib.request.urlopen('http://localhost:8080/simulate/db-down').read().decode())\""
echo "   kubectl get pods -l app=good-health-app  # Shows 0/1 but still Running"
echo "   # Restore DB"
echo "   kubectl exec \$POD_NAME -- python -c \"import urllib.request; print(urllib.request.urlopen('http://localhost:8080/simulate/db-up').read().decode())\""
