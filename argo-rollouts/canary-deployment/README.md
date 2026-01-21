# Argo Rollouts Demo on Minikube (WSL Ubuntu)

This repository contains a complete setup and demo for **Argo Rollouts** using **Canary deployment with analysis** and **Experiment strategy**, integrated with **Prometheus** for metric-based rollout decisions. The environment is built on **Minikube running inside WSL Ubuntu**.

## 🎯 Objectives

- Understand what Argo Rollouts is and why it's useful.
- Learn progressive delivery strategies: Canary, Blue-Green, and Experiment.
- Set up Argo Rollouts and Prometheus on Minikube.
- Deploy applications using Canary with metric analysis.
- Run experiments comparing multiple versions.
- Visualize rollout progress using the Argo Rollouts dashboard.

---

## 🛠️ Prerequisites

- Windows with WSL2 and Ubuntu installed
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) with Docker driver
- `kubectl` installed and configured
- `helm` installed
- Internet access for downloading charts and images

---

## ⚙️ Setup Instructions

### 1. Start Minikube

```bash
minikube start --driver=docker
```
### 2. Install Argo Rollouts
```
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```
### 3. Install Argo Rollouts CLI Plugin
```
wget https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x ./kubectl-argo-rollouts-linux-amd64
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```
### 4. Install Prometheus (Monitoring)
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install prometheus prometheus-community/prometheus --namespace monitoring
```
## Create AnalysisTemplate
```
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  metrics:
  - name: success-rate
    interval: 30s
    count: 3
    successCondition: result[0] >= 0.95
    failureCondition: result[0] < 0.90
    provider:
      prometheus:
        address: http://prometheus-server.monitoring.svc.cluster.local:80
        query: |
          sum(rate(http_requests_total{status=~"2.."}[1m]))
          /
          sum(rate(http_requests_total[1m]))
```
Apply it:

```
kubectl apply -f analysis-template.yaml
```
## Canary Deployment with Analysis
```
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: demo-canary
spec:
  replicas: 3
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 30}
      - analysis:
          templates:
          - templateName: success-rate
      - setWeight: 50
      - pause: {}
  selector:
    matchLabels:
      app: demo-canary
  template:
    metadata:
      labels:
        app: demo-canary
    spec:
      containers:
      - name: demo
        image: nginx:1.19
        ports:
        - containerPort: 80
```
Apply it:
```
kubectl apply -f canary-rollout.yaml
```
## Experiment Strategy
```
apiVersion: argoproj.io/v1alpha1
kind: Experiment
metadata:
  name: demo-experiment
spec:
  duration: 60s
  templates:
  - name: version-a
    replicas: 2
    selector:
      matchLabels:
        app: demo-experiment
        version: a
    template:
      metadata:
        labels:
          app: demo-experiment
          version: a
      spec:
        containers:
        - name: demo
          image: nginx:1.19
          ports:
          - containerPort: 80
  - name: version-b
    replicas: 2
    selector:
      matchLabels:
        app: demo-experiment
        version: b
    template:
      metadata:
        labels:
          app: demo-experiment
          version: b
      spec:
        containers:
        - name: demo
          image: nginx:1.20
          ports:
          - containerPort: 80
  analyses:
  - name: compare-success-rate
    templateName: success-rate
```
Apply it:
```
kubectl apply -f experiment.yaml
```
## Access Argo Rollouts Dashboard
```
kubectl-argo-rollouts dashboard
```
Open your browser at:
```
http://localhost:3100
```
