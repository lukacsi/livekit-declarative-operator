# Declarative LiveKit Operator

A Kubernetes Operator for managing the lifecycle of [LiveKit](https://livekit.io/) media servers.

Unlike standard operators built with Kubebuilder, this project utilizes the **\Delta-Controller framework**, allowing for a purely declarative, pipeline-based architecture. It solves the complex "Day-1" and "Day-2" operational challenges of WebRTC infrastructure—specifically Network Discovery (NAT/TURN), state management, and multi-tenancy—without imperative spaghetti code.

## Key Features

* **Zero-Touch Provisioning:** Automatically discovers public IPs from Cloud LoadBalancers and hydrates the LiveKit configuration. No manual `turn_servers` setup required.
* **Gateway API Integration:** Native support for [Stunner](https://github.com/l7mp/stunner) and Envoy Gateway to handle UDP/TCP traffic separation.
* **Polymorphic Persistence:** Seamlessly switch between embedded Redis (StatefulSet) and external Cloud Redis (Memorystore/Elasticache) with zero downtime.
* **Feature Toggling:** Enable/Disable components like **Ingress** via simple CRD flags; the operator handles the cleanup.
* **Secure by Default:** Automated TLS certificate generation via cert-manager and secure credential management.

## Installation

### Prerequisites

* Kubernetes cluster (GKE, EKS, or Kind)
* [Delta-Controller](https://github.com/l7mp/dcontroller) installed.
* [Stunner Gateway Operator](https://github.com/l7mp/stunner-gateway-operator) installed.
* [Envoy Gateway](https://gateway.envoyproxy.io/) installed.
* [Cert-Manager](https://cert-manager.io/) installed.
* Domain with access to DNS

## Architecture

This operator implements the **\Delta-Controller Pattern**, treating the Kubernetes reconciliation loop as a dataflow problem rather than a procedural one.

### The Pipeline

Instead of `if/else` logic, the state is derived through SQL-like transformations:

1. **Decomposition:** `LiveKitPool` \to `LiveKitServerView` + `LiveKitNetworkingView`
2. **Network Discovery:** `NetworkingView` + `Gateway (K8s)` \to `Resolved Public IP`
3. **Materialization:** `Views` \to `Deployments`, `Services`, `Secrets`

This architecture ensures that the "Inverse Operation" (Teardown/Garbage Collection) is handled automatically. If a resource disappears from the View, it is deleted from the cluster.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Background

This project was developed as part of a BSc Thesis at **Budapest University of Technology and Economics (BME)**, Department of Telecommunications and Media Informatics.

**Title:** Design and Implementation of a Declarative Kubernetes Operator for the LiveKit Media Server Framework.
**Author:** Sándor Lukácsi
