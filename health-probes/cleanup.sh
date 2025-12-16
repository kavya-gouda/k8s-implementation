#!/bin/bash

echo "🧹 Cleaning up all lab resources..."

kubectl delete deployment bad-health-app good-health-app cascade-app cascade-app-fixed --ignore-not-found=true
kubectl delete service bad-health-app good-health-app cascade-app cascade-app-fixed --ignore-not-found=true

echo "✅ Cleanup complete!"