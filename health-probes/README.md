# Kubernetes Health Probes Lab

## Overview

This lab provides hands-on experience with Kubernetes health probes through practical scenarios that demonstrate both improper and proper probe configurations. It's designed to help DevOps engineers understand the critical role of health probes in maintaining application reliability and availability in production Kubernetes environments.

## What are Kubernetes Health Probes?

Health probes are diagnostic mechanisms that Kubernetes uses to determine the state of containers running in pods. They enable Kubernetes to automatically detect and respond to application failures, ensuring high availability and self-healing capabilities.

### Types of Health Probes

1. **Liveness Probe**
   - **Purpose**: Determines if a container is running properly
   - **Action on Failure**: Kubernetes kills and restarts the container
   - **Use Case**: Detect deadlocks, infinite loops, or any state where the app is running but not functioning
   - **Example**: An application is running but stuck in an infinite loop processing requests

2. **Readiness Probe**
   - **Purpose**: Determines if a container is ready to accept traffic
   - **Action on Failure**: Removes the pod from service endpoints (stops sending traffic)
   - **Use Case**: Handle startup delays, temporary unavailability, or dependencies loading
   - **Example**: Application is starting up and loading configuration from a database

3. **Startup Probe**
   - **Purpose**: Determines if the application within the container has started
   - **Action on Failure**: Kubernetes kills and restarts the container
   - **Use Case**: Protect slow-starting containers from premature liveness probe failures
   - **Example**: Legacy applications that take 60+ seconds to initialize

## How Health Probes Work

### Probe Mechanisms

Kubernetes offers three ways to check container health:

1. **HTTP GET**: Sends an HTTP GET request to a specified path and port
   - Success: HTTP status code between 200-399
   - Failure: Any other status code or connection failure

2. **TCP Socket**: Attempts to open a TCP connection to a specified port
   - Success: Connection establishes successfully
   - Failure: Connection cannot be established

3. **Exec Command**: Executes a command inside the container
   - Success: Command exits with status code 0
   - Failure: Command exits with non-zero status code

### Probe Configuration Parameters

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15    # Wait before first check
  periodSeconds: 10          # How often to check
  timeoutSeconds: 5          # Seconds before check times out
  successThreshold: 1        # Consecutive successes to mark healthy
  failureThreshold: 3        # Consecutive failures before action
```

### Execution Flow

1. **Container Starts**: Kubernetes waits for `initialDelaySeconds`
2. **First Check**: Probe executes using configured mechanism
3. **Periodic Checks**: Probe runs every `periodSeconds`
4. **Evaluation**: Based on `successThreshold` and `failureThreshold`
5. **Action**: Kubernetes takes appropriate action based on probe type and result

## What This Lab Achieves

### Learning Objectives

1. **Understand Probe Misconfiguration Impact**
   - Experience how improper probes cause unnecessary restarts
   - See the cascade effect of bad probe settings on application availability
   - Learn to identify common probe configuration mistakes

2. **Implement Best Practices**
   - Configure appropriate timing parameters for different scenarios
   - Design effective health check endpoints
   - Balance probe sensitivity with application needs

3. **Observe Real-World Behavior**
   - Monitor pod lifecycle events in real-time
   - Analyze Kubernetes responses to probe failures
   - Understand the relationship between probes and service availability

### Lab Scenarios

#### Scenario 1: Bad Probes Configuration
- **What's Wrong**: Aggressive probe settings that don't account for application startup time
- **Observable Issues**:
  - Pods continuously restart (CrashLoopBackOff)
  - Application never becomes fully available
  - Service disruption despite healthy application code
- **Learning**: Importance of proper timing and thresholds

#### Scenario 2: Proper Probes Configuration
- **What's Right**: Appropriate probe timing, dedicated health endpoints, realistic thresholds
- **Observable Benefits**:
  - Smooth application startup and operation
  - Graceful handling of temporary issues
  - Reliable traffic routing to healthy pods
- **Learning**: Best practices for production-ready configurations

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured to access your cluster
- Docker for building container images
- Basic understanding of Kubernetes concepts (pods, deployments, services)

## Getting Started

1. Clone this repository
2. Navigate to each scenario directory
3. Follow the README in each scenario to run the examples
4. Observe the differences in behavior between bad and proper configurations

## Key Takeaways for DevOps Engineers

- **Never skip health probes**: They're essential for production reliability
- **Tune for your application**: Every app has different startup and response times
- **Separate health from readiness**: Use different endpoints when appropriate
- **Monitor probe metrics**: Failed probes indicate real issues to investigate
- **Test thoroughly**: Validate probe configurations before production deployment

## Additional Resources

- [Kubernetes Official Documentation - Configure Liveness, Readiness and Startup Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Best Practices for Health Checks](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#container-probes)