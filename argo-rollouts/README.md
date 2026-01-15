# Argo Rollouts

Argo Rollouts is a solution for performing progressive delivery of deployments to Kubernetes clusters. It helps you improve deployment reliability and performance using blue-green and canary rollouts.

## What is Argo Rollouts?
Argo Rollouts is a Kubernetes tool that implements advanced rollout strategies for deployments in your cluster. This means using techniques such as blue-green deployments and canary deployments to gradually move traffic to a new app release instead of having all requests immediately switch over. It enables you to limit the damage caused by broken deployments because they’ll initially serve only a subset of users.

The tool is implemented as a Kubernetes controller and a collection of Custom Resource Definitions (CRDs). The main CRD is Rollout — it acts as a replacement for the Kubernetes Deployment object and allows you to define deployments that use the advanced update strategies that Argo provides. Without creating a Rollout, you can only use the rolling update and complete recreation deployment strategies that are included with Kubernetes.

When you add a Rollout object to your cluster, the Argo controller detects its presence and then creates, replaces, and removes Pods as required. You can then manage the rollout using Argo’s Kubectl plugin, such as exposing the new deployment to more users or initiating a rollback. These actions can also be automated based on data supplied by external sources — for example, HTTP request metrics collated by an Ingress controller or analysis of network activity exposed by your service mesh.

Although the Kubernetes Deployment object provides useful controls for simple scenarios, it’s not robust enough to support real-world rollouts at scale. Argo Rollouts adds the missing features that let you precisely manage rollout progression and automate more parts of your deployment workflow.

## Understanding app rollout strategies

How does Argo Rollouts work?

There are four main strategies used to roll out application changes. The one you select defines what happens when you launch a new version of an app into your Kubernetes cluster:

Blue-Green — Blue-green deployments, available in Argo Rollouts, start the new version’s Pods but don’t direct any traffic to them. The old version (blue) remains live and continues to serve your production users. Developers can manually test against the new release (green) to verify it’s functioning correctly.
Canary — Canary deployments start the new version and use it to handle a portion of live traffic. You can gradually increase the amount of traffic that’s served by the new release, allowing any problems to be detected and resolved before too many users experience them.
Rolling Update — A rolling update starts the new deployment’s Pods, then gradually scales down the old deployment until only the new one is left running. (Note: This is the default behavior of regular Kubernetes Deployments.)
Recreate — This strategy removes the old deployment from your cluster, then launches the new release and immediately exposes it to traffic. This can be advantageous when you’re introducing backward-incompatible changes that require a clean break to function correctly, but the gap between the old deployment stopping and the new one starting means some downtime will occur. (Note: Recreate is supported by regular Kubernetes Deployments.)

## Argo Rollouts deployment workflow
The core Argo Rollouts workflow is as follows:

1.  Deploy your new app release.
2.  Test the new release.
For blue-green deployments, this will be done by developers, whereas canary deployments will be tested by a small percentage of real users. As you gain confidence in the canary, you can increase the proportion of traffic that’s directed to it.
3.  Once you’re sure the deployment has been successful, promote it to a full rollout.
Argo will then remove the old deployment and ensure all traffic is directed to the new one. At this point, you can begin iterating on your next change, ready to repeat the cycle.

<img width="1090" height="318" alt="image" src="https://github.com/user-attachments/assets/11209b69-981b-4c9f-9f6c-7d1689693030" />
One of the key benefits of Argo Rollouts is that these steps can be automated, so you don’t have to keep checking your deployments before they proceed. For example, you could configure Argo to automatically increase the percentage of traffic that targets your canary deployment every 10 minutes, or specify that a rollout should be aborted if there’s a spike in HTTP error codes. This facilitates greater DevOps efficiency without compromising deployment reliability.


## Argo Rollouts use cases
As we’ve outlined above, Argo Rollouts enables more advanced Kubernetes deployment techniques. Here are some key use cases:

1.  Expose new app releases to a limited group of users via blue-green or canary deployments.
2.  Take control over rollout speed and progression for example, by expanding access to an additional 20% of traffic each hour, but only if no errors have occurred.
3.  Automate rollbacks in the event of failures using metrics generated by external systems (such as request latency or failure data sourced from a Prometheus instance).
4.  Use GitOps and declarative configuration to define your deployment rollouts and easily apply changes using IaC methods.
These benefits illustrate how Argo Rollouts fills in the blanks left by the built-in Kubernetes Deployment object.
