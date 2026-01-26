# Service Not Accessible 
Cause:
The service is not exposing the application correctly.
Solution:
1. Check the service 
details. Example:
kubectl get services
2. Verify the service 
configuration. Example:
kubectl describe service <service-name>
3. Ensure the target port matches the container's exposed port.
4. If using a NodePort or LoadBalancer service, ensure that the 
firewall allows traffic on the specified port.
5. Test the service using a temporary 
pod. Example:
kubectl run test-pod --image=busybox --rm -it -- /bin/sh 
Use curl to test the service from inside the cluster.

----
Issue: Service is Not Accessible (ClusterIP / NodePort / LoadBalancer issues)

Symptoms:

A Kubernetes Service is not functioning as expected. This could be an internal ClusterIP service (pods cannot access the service IP or name), a NodePort service not responding on the node’s IP:port, or a LoadBalancer service (on cloud) that isn’t reachable via the provisioned load balancer
<img width="823" height="690" alt="image" src="https://github.com/user-attachments/assets/d0a696d4-fe67-4ae0-b72d-83d659d84b00" />

How to Identify:

Check the Service and Endpoints: kubectl describe svc to see which pods (IPs) are supposed to be behind it (or use kubectl get endpoints). If endpoints list is empty or not matching expected pods, focus there.

Verify pods are labeled correctly to match service’s selector. Maybe a typo in labels (e.g., service selecting app=frontend but pods labeled app=fronted)

If endpoints exist, try accessing the pod directly (skip the service): from a client pod, do curl http://: for one of the endpoints. If that works, the pod and network are fine, problem is service routing.

If service is ClusterIP type, test it from within cluster (ClusterIP isn’t accessible outside by design). If NodePort/LoadBalancer, test accordingly: e.g., NodePort: curl http://:. LoadBalancer: try the LB’s DNS or IP from outside cluster (and ensure some pod is running).

Look at kubectl describe service events (maybe none, but if cloud LB failed, there might be events).

For cloud LB issues on AWS: go to AWS console, see if an ELB was created. Check its health checks – are target nodes marked healthy? If not, maybe the health check path/port is wrong or SG is blocking.

If no ELB at all, likely an IAM or config issue in the CCM (Cloud Controller Manager).

Logs: Check kube-proxy logs on a node that can’t reach the service. Or describe that node with kubectl get ep -o yaml to see if that node has endpoints. A trick: if using iptables, ssh into node and run iptables -t nat -L KUBE-SERVICES | grep . This can show if rules exist for that service. If not present at all, kube-proxy didn’t program it (maybe service definition not picked up or kube-proxy down). If present but perhaps pointing to wrong IP, maybe stale endpoints (rare since endpoints update should sync).

If ExternalTrafficPolicy=Local: Check on how many nodes pods exist. If LB sends traffic to a node with no pods, that traffic will fail. You can either tolerate that (some requests fail) or ensure at least one pod per node (DaemonSet or topology spread).

For NodePort: ensure node’s firewall (if any) allows the port. On cloud VMs, security groups might need to allow the NodePort range or specific port.

Common Causes:

No Endpoints / Pods not Ready: The service might have zero endpoints. If the pods that are supposed to back it are not labeled correctly or not in Ready state (readiness probe failing), the service has no endpoints. kubectl get endpoints would show none. In that case, any traffic to the service IP will not be directed to any pod (and likely gets dropped).

TargetPort/Port Mismatch: The Service’s configuration might be incorrect. For example, you expose port 80 but your pods listen on 8080, and you set targetPort to 8080 but your app actually listens on 80 (or vice versa). Mismatch can lead to connection refused because there’s no process listening on the targeted port

Network Policy blocking service traffic: If a policy doesn’t allow traffic from the client to the pod, that can affect service. Usually, service traffic is just IP traffic from the client (which could be another pod).

Fixes / Mitigation:

1. Ensure Service and Endpoint Alignment:

Correct Labels: If endpoints are missing due to selectors, fix either the pod labels or service selector so they match. This will immediately populate endpoints (check endpoints resource after fix).

Wait for Readiness: If pods aren’t ready, they won’t be in endpoints for service (if publishNotReadyAddresses is not set). If readiness probe is too strict or failing wrongly, consider adjusting it or temporarily remove it to quickly get endpoints (not ideal in prod, but as a debug).

TargetPort Fix: If you realize you exposed the wrong port, edit the Service (or the deployment) so that they agree. For example, if your container listens on 3000 but service targetPort was 80, change targetPort to 3000. Note: If using type: LoadBalancer, changing ports might recreate LB or need update. On internal clusterIP, it’s straightforward.

Multiple ports scenario: If a service has multiple ports, ensure you’re curling the correct one and the pod indeed listens on those.

Headless service debugging: If it’s headless (ClusterIP None), then no cluster IP – clients should use DNS to get pod IPs and connect directly. If that fails, treat it like DNS or direct pod connectivity issues.

2. Cloud Load Balancer Troubleshooting (EKS):

Check IAM for CCM: The AWS Cloud Controller Manager (for older clusters the in-tree cloud provider) needs permission to create load balancers, modify SGs, etc. In EKS, if using the AWS Load Balancer Controller (for ALB/NLB provisioning via Ingress or Service annotations), ensure that controller’s IAM role has the correct policy (AWSLoadBalancerController policy). If the service stuck in Pending, likely the controller isn’t running or authorized. Install the AWS Load Balancer Controller if not present (for ALB ingress). For Services type LoadBalancer that create Classic ELB/NLB (default for Service on EKS), ensure your cluster’s IAM (the role EKS cluster uses to interact with AWS) has permissions (EKS usually handles this).

Security Group rules: EKS usually attaches a SG to the ELB allowing the service’s port from 0.0.0.0/0. But if you have custom VPC SG rules, ensure the nodes accept traffic from the LB (the nodes’ SG should allow the LB SG on the NodePort range or specific node ports – EKS automatically adds an ingress on node SG for the LB, if using managed). If that was modified, fix it.

Health Check settings: AWS CLB health checks by default hit NodePort on the node. If your service port is 80, NodePort maybe 31223, it will check that. If your pods aren’t on every node and extTrafficPolicy=Local, some nodes will be always unhealthy. Option: switch extTrafficPolicy to Cluster so any node will forward to a healthy pod (but sacrifices client source IP unless using Proxy protocol on NLB). Or deploy at least one pod per node (not always feasible).

If LB exists but you can’t reach it at all, maybe it’s an internal LB in a private subnet and you’re trying from internet. Check if Service annotation service.beta.kubernetes.io/aws-load-balancerinternal is set accidentally making it internal.

Recreate Service: As a drastic measure, if a LoadBalancer Service is glitched, you can delete and recreate it. That will create a new ELB. This might be easier than debugging weird AWS state, but be mindful of DNS name changes, etc., if consumers rely on it.

4. Interim Workarounds:

If service is broken and fix is not immediate, use direct pod IP or a headless service with your own client-side load balancing as a stopgap.

For external clients (if LB is down), you could port-forward as a temporary access: kubectl portforward from your machine to target service/pod, if desperate to get connectivity for debugging.

