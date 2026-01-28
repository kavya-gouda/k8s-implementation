# API server and etcd
The backbone of kubernetes control plane
## Overview

API Server: The front door of the kubernetes control plane; handles all REST requests
etcd: A distributed Key-value store that persists cluster state
Together, they ensure reliable communication and state consistency

<img width="831" height="402" alt="image" src="https://github.com/user-attachments/assets/98f2e88e-83ec-44dd-95fc-add3ff65d24a" />

## API Server Fundamentals

1.  Exposes Kubernetes API (HTTP/JSON)
2.  Validates and processes requests from kubectl, controllers and components
3.  Performs authentication, authorization, and admission control
4.  Updates cluster state in etcd

<img width="467" height="575" alt="image" src="https://github.com/user-attachments/assets/ce0aceae-40b6-435c-bc95-61214b838ce2" />

## etcd Fundamentals
-  Distributed, consistent key-value store using Raft consensus.
-  Store all cluster data: pods, configmaps, Secrets, etc.
-  Supports watch mechanism for real-time updates.
-  Highly available and fault-tolerant when deployed as a cluster

## How they work together
-  API Server receives request → validates → writes to etcd
-  Controllers and scheduler watch API server for changes
-  etcd ensures consistenccy across control-plane nodes

  
