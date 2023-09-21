# Splunk OpenTelemetry Collector Documentation

## Splunk OpenTelemetry Collector Helm Chart Components



### Agent Component:

1. daemonset.yaml:
  - Defines a DaemonSet to ensure that all (or some) nodes in the cluster run a copy of the agent pod.
  - Collects data from each node in the Kubernetes cluster.

2. configmap-agent.yaml:
  - Provides configuration data to the agent component.
  - Contains details about how the agent should collect and forward data.

3. service-agent.yaml (Optional):
  - Defines a Kubernetes Service for the agent.
  - Used for internal communication within the cluster or for exposing specific metrics or health endpoints.

### Cluster Receiver Component:

1. deployment-cluster-receiver.yaml:
  - Defines a Deployment to manage the replicated application for the Cluster Receiver.
  - Receives and processes data at the cluster level.

2. configmap-cluster-receiver.yaml:
  - Provides configuration data to the Cluster Receiver.
  - Contains details about how the receiver should process and forward the data it collects.

3. service-cluster-receiver-stateful-set.yaml (Optional):
  - Defines a Kubernetes Service for the Cluster Receiver.
  - Associated with a StatefulSet and used for load balancing, internal communication, or exposing specific endpoints.

4. pdb-cluster-receiver.yaml:
  - Defines a Pod Disruption Budget (PDB) for the Cluster Receiver.
  - Ensures that a certain number or percentage of replicas remain available during operations like node maintenance.

### Gateway Component (Optional):

1. deployment-gateway.yaml:
  - Defines a Deployment for the Gateway.
  - Processes and forwards data between the agents/receivers and external destinations.

2. configmap-gateway.yaml:
  - Provides configuration data to the Gateway.
  - Contains details about how the gateway should process, transform, and forward the data it receives.

3. service.yaml:
  - Defines a Kubernetes Service for the gateway.
  - Used for internal communication within the cluster for accepting data from the agent or cluster receiver and forwarding it to the Splunk backend endpoint.

4. pdb-gateway.yaml:
  - Defines a Pod Disruption Budget (PDB) for the Gateway.
  - Ensures that a certain number or percentage of replicas of the Gateway remain available during voluntary disruptions.



### Use Cases

#### Collector All Modes Enabled


# Use Case: All Collector Modes Enabled

### Agent:
**Exporters**:
- [otlp](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/otlpexporter)
- [signalfx](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/signalfxexporter)

**Extensions**:
- [health_check](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/healthcheckextension)
- [k8s_observer](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/observer/k8sobserver)
- [memory_ballast](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/memoryballastextension)
- [zpages](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/zpagesextension)

**Processors**:
- [batch](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/batchprocessor)
- [groupbyattrs/logs](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/groupbyattrsprocessor)
- [k8sattributes](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/k8sattributesprocessor)
- [memory_limiter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/memorylimiterprocessor)
- [resource](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourceprocessor)
- [resourcedetection](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourcedetectionprocessor)

**Receivers**:
- [hostmetrics](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/hostmetricsreceiver)
- [jaeger](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/jaegerreceiver)
- [kubeletstats](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/kubeletstatsreceiver)
- [otlp](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/otlpreceiver)
- [receiver_creator](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/receivercreator)
- [signalfx](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/signalfxreceiver)
- [zipkin](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/zipkinreceiver)

### Cluster Receiver:
**Extensions**:
- [health_check](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/healthcheckextension)
- [memory_ballast](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/memoryballastextension)

**Processors**:
- [batch](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/batchprocessor)
- [memory_limiter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/memorylimiterprocessor)
- [resource](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourceprocessor)
- [resourcedetection](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourcedetectionprocessor)

**Receivers**:
- [k8s_cluster](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/k8sclusterreceiver)

### Gateway:
**Exporters**:
- [sapm](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/sapmexporter)
- [signalfx](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/signalfxexporter)

**Extensions**:
- [health_check](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/healthcheckextension)
- [http_forwarder](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/httpforwarderextension)
- [memory_ballast](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/memoryballastextension)
- [zpages](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/zpagesextension)

**Processors**:
- [batch](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/batchprocessor)
- [filter/logs](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/attributesprocessor) (Assuming this is a type of attributes processor)
- [k8sattributes](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/k8sattributesprocessor)
- [memory_limiter](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/memorylimiterprocessor)
- [resource](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourceprocessor)
- [resourcedetection](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/resourcedetectionprocessor)

**Receivers**:
- [jaeger](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/jaegerreceiver)
- [otlp](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/otlpreceiver)
- [prometheus/collector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/prometheusreceiver)
- [signalfx](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/signalfxreceiver)
- [zipkin](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/zipkinreceiver)


### Kubernetes Objects Explained

### Deployment

**What is it?**
A Deployment is a higher-level resource meant to manage the deployment of pods. It describes the desired state for your application deployments.

**Key Features:**
- Allows for rolling updates to your application.
- Supports rollbacks to previous versions.
- Can ensure a certain number of pods are running at all times.

**Usage:**
Used when you want to ensure your application is highly available. For instance, if you have a web application backend, you might use a Deployment to manage its pods.

---

### DaemonSet

**What is it?**
A DaemonSet ensures that all (or some) nodes run a copy of a specific pod. As nodes are added to or removed from the cluster, the DaemonSet automatically adjusts the number of pods.

**Key Features:**
- Ensures a pod runs on all nodes or specific nodes.
- Useful for node-level tasks like monitoring, logging, or node-specific services.

**Usage:**
Used for deploying system daemons such as log collectors, monitoring agents, or other node-level services.

---

### ConfigMap

**What is it?**
A ConfigMap is an object used to store non-confidential configuration data in key-value pairs. It allows you to decouple environment-specific configuration from your application's image.

**Key Features:**
- Can be mounted as environment variables or files in a pod.
- Allows for centralized management of configuration data.

**Usage:**
Used when you want to keep your configuration separate from your application, allowing your application to be environment agnostic.

---

### Pod Disruption Budget (PDB)

**What is it?**
A PDB limits the number of concurrently disrupted pods during voluntary disruptions. It ensures high availability of applications during operations like node maintenance.

**Key Features:**
- Defines the allowed disruption based on label selectors.
- Ensures application availability during maintenance.

**Usage:**
Used when you want to ensure a certain percentage or number of your application replicas are available at all times, especially during node or cluster maintenance.

---

### Service

**What is it?**
A Service in Kubernetes is a way to expose an application running on a set of pods as a network service.

**Key Features:**
- Provides a single point of entry for accessing pods.
- Distributes network traffic across a group of interconnected pods.
- Can automatically load balance traffic.

**Usage:**
Used when you want to expose your application to other applications in the same cluster or to external consumers. For instance, a frontend application might access a backend through a Service.


### Kubernetes vs. Linux/Windows Deployment



#### Deployment in a Linux Environment:

Agent:
1. Installation: Download and install the Splunk OpenTelemetry Connector package relevant to your Linux distribution.
2. Configuration: Configuration files in /etc/otel/collector/. Manually edit for custom configurations.
3. Service Management: Runs as a system service, managed by systemd or init.d.

Collector (or Receiver):
1. Installation: Download and install the package relevant to your Linux distribution.
2. Configuration: Configuration files in the same directory as the agent.
3. Service Management: Runs as a system service, similar to the agent.

#### Differences Compared to Kubernetes (K8s) Setup:

1. Deployment Mechanism:
  - Linux: Traditional package managers.
  - K8s: Deployed using Helm charts or Kubernetes manifests.

2. Configuration Management:
  - Linux: Directly edit configuration files.
  - K8s: Use ConfigMaps and Secrets.

3. Service Discovery:
  - Linux: Typically static.
  - K8s: Dynamic using Kubernetes service discovery.

4. Scaling and Resilience:
  - Linux: Manual scaling.
  - K8s: Automatic scaling with ReplicaSets, Deployments, and StatefulSets.

5. Logging and Monitoring:
  - Linux: Use traditional tools.
  - K8s: Logs captured from container stdout/stderr.

6. Network:
  - Linux: Managed by the host OS.
  - K8s: Uses its own overlay network.

7. Service Lifecycle:
  - Linux: Managed by system init systems.
  - K8s: Managed by Kubernetes.

8. Isolation:
  - Linux: Processes share the same OS.
  - K8s: Services run in their own container.

9. Updates and Rollbacks:
  - Linux: Manual updates using package managers.
  - K8s: Managed by Kubernetes controllers.

10. Resource Limits:
- Linux: Set using system tools.
- K8s: Set at the container level.
