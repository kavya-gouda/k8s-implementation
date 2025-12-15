#!/bin/bash
set -e

echo "🚀 Building bad-health-app..."
docker build -t bad-health-app:v1 .

echo "📦 Loading image into cluster..."
minikube image load bad-health-app:v1


echo "🎯 Deploying application..."
kubectl apply -f deployment.yaml

echo "⏳ Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=bad-health-app --timeout=60s

echo "✅ Deployment complete!"
echo ""
echo "📝 Test the broken behavior:"
echo "   POD_NAME=\$(kubectl get pod -l app=bad-health-app -o jsonpath='{.items[0].metadata.name}')"
echo "   kubectl exec \$POD_NAME -- python -c \"import urllib.request; print(urllib.request.urlopen('http://localhost:8080/break-db').read().decode())\""
echo "   kubectl get pods -l app=bad-health-app"
echo ""
echo "💡 Notice: Pod stays 1/1 READY even though it can't serve traffic!"
