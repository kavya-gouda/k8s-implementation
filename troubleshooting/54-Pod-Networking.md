# Issue: Pod Networking (Pods cannot reach each other or external services)
Symptoms:

Pods that are supposed to communicate over the network are unable to do so. This could be within the cluster (pod A can’t talk to pod B on its pod IP or service IP) or going outside the cluster (pod can’t reach external internet or an API).

It include timeouts or connection errors in application logs, failing health checks (if one service depends on another), or components like service mesh sidecars reporting connectivity issues. In Kubernetes, every pod is given an IP and the CNI (Container Network Interface) is responsible for routing packets between pods across nodes and to external networks.

How to Identify:

Check if the pods got an IP: kubectl get pods -o wide to see their IPs. If any pod has as IP or is stuck in ContainerCreating, that’s a clue of CNI problems.

If IPs are assigned, try pinging or curling between pods manually (if allowed and if minimal network policy). You can use kubectl exec into one pod and ping the IP of another pod.

Check the CNI plugin pods: kubectl get daemonset -n kube-system (Flannel, Calico, Weave, AWS Node). Are they Running? If CrashLoopBackOff, describe those pods and get logs. For example, AWS CNI might log “ENI attach timeout” or “no available IP addresses”.

Check node routes: On a node, ip route should show routes to pod CIDRs of other nodes (for overlay networks) or not (for AWS CNI which uses VPC routing). If overlay like Flannel, ensure the flanneld process has established subnet lease (logs will show). For Calico, check calicoctl node status if possible, to see BGP peers

If suspect network policy, do a quick test by allowing all traffic (for debugging, you could create a NetworkPolicy that allows all ingress/egress in that namespace to see if issue resolves).

If only external traffic fails: try a curl ifconfig.me or ping 8.8.8.8 from a pod. If ping by IP fails, it’s egress network. If ping by IP works but DNS name doesn’t, then it’s DNS. Also check the node’s ability: if node can’t reach out either, likely a network config issue (on EKS, maybe no NAT gateway)

Common Causes:

CNI Plugin Malfunction: If the cluster’s CNI (like Flannel, Calico, Weave, or AWS VPC CNI) is not installed correctly or crashed, pods might not be assigned IPs or routes properly. E.g., if AWS VPC CNI aws-node pods are CrashLooping, new pods might be stuck in ContainerCreating because no IP can be allocated.

IP Exhaustion: On EKS (AWS VPC CNI), each node has a limited number of IP addresses from the VPC to assign to pods. If that limit is hit, new pods can’t get IPs, leading to network issues for those pods (and they might stay in ContainerCreating). This is often accompanied by events like “Failed to create pod sandbox: unable to assign an IP address”

Network Policy Blocking Traffic: Kubernetes NetworkPolicy (if using Calico or other implementing plugin) could be denying traffic. If a policy is too restrictive, pods may not reach each other. Symptoms would be specific: e.g., only certain namespaces or apps can’t talk, whereas base connectivity (ping between nodes, etc.) is fine.

Node Networking Issues: If a node’s own networking is broken (routing table issues, incorrect IPTables rules outside of kube-proxy, etc.), pods on that node might not reach others.

kube-proxy Issues: If kube-proxy is not running or functioning on a node, service IPs on that node won’t work for pods on that node. But pod-to-pod via direct IP might still work unless overlay is broken.

External Access Issues: If pods can’t reach the internet, it could be due to lack of egress configuration (in cloud, missing NAT gateway or internet gateway), or corporate firewall/proxy needed. On EKS, a common scenario: private cluster with no NAT, pods have no route to external internet – DNS queries to 8.8.8.8 or external APIs will fail. Security groups could also block egress if mis-set (though by default AWS allows all egress).

DNS vs. Network: Sometimes people misinterpret DNS issues as network issues. If pods can ping each other by IP but not by name, that’s a DNS problem (covered next). Pure network issues mean even IP connectivity fails.

Fixes / Mitigation:

1. Fix or Restart the CNI Plugin:

Restart CNI Daemonset: Sometimes simply restarting the CNI pods on the node can reinitialize networking. kubectl rollout restart ds/aws-node -n kube-system (for AWS) or similar for others. This can disrupt networking briefly, but might resolve a hung state.

Upgrade CNI: Ensure you’re using a compatible and up-to-date CNI version for your Kubernetes. EKS provides CNI plugins – check if an update is available via EKS console or eksctl to a newer version that might fix known bugs (for example, IP leak issues).

Configure CNI Correctly: If the issue was misconfiguration (like flannel using wrong interface), edit the CNI config. For Flannel, you’d update the daemonset arguments to specify the correct --iface and then restart it. For Calico, ensure the IP pool CIDR matches your cluster CIDR and doesn’t conflict with other network. For AWS CNI, you can tweak settings via ConfigMap (e.g., increase WARM_IP_TARGET to pre-allocate more IPs or enable ENABLE_PREFIX_DELEGATION to get more IPs per ENI).

2. Network Policy / Firewall Adjustments:

Allow Necessary Traffic: If using NetworkPolicies, ensure that core DNS, ingress-controller, etc., are allowed to communicate as needed. For example, if pods can’t reach the DNS server, maybe a policy is blocking port 53; update the policy to allow DNS from pods or run DNS in hostNetwork so not subject to policies (some setups do that).

If an external firewall (like cloud security groups, on-prem firewalls) is blocking traffic between nodes or to outside, update those rules. EKS by default sets security group rules to allow node-tonode on required ports (if all nodes share a SG). If custom SGs were used, verify that all nodes can talk to each other on the pod CIDR ranges or relevant ports (VXLAN, BGP for Calico, etc., depending on CNI).

Test without Policy: As a debugging measure, create a liberal NetworkPolicy (or remove custom ones) to see if connectivity restores, then refine the rules properly. It’s possible a policy was too broad in denying traffic

3. Service and Kube-proxy Considerations: (Though service issues are addressed more in the next issue)

If pods can reach each other by IP but not via Service IP, check kube-proxy. Ensure kube-proxy pods (or processes) are running. If iptables mode, check iptables -L -t nat on a node to see if service rules exist. If blank, kube-proxy might be down. Restart kube-proxy (usually a daemonset named kube-proxy).

4. External Connectivity:

For pods needing internet, ensure a NAT gateway or HTTP proxy is configured. If corporate environment, might need to set proxy env vars for outgoing traffic.

On EKS private clusters, consider adding VPC Endpoints for services your pods use (like S3, DynamoDB) so they don’t need internet. If that’s not possible short-term, allow temporary internet access.

Security group egress: AWS SG by default allows all egress, but if someone locked it down, open at least what’s necessary (or allow all egress if policy permits).
