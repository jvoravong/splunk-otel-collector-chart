# Example of chart configuration

## How to deploy the OpenTelemetry Operator and .Net auto-instrumentation

In the following example we will show how to instrument a project using
[otel-demo](https://raw.githubusercontent.com/signalfx/splunk-otel-collector-chart/main/examples/enable-operator-and-auto-instrumentation/otel-demo/otel-demo.yaml).

### 1. Setup the OpenTelemetry demo to instrument

The .Net otel-demo demo will create a otel-demo namespace and deploys the related .Net applications to it.
If you have your own .Net application you want to instrument, you can still use the steps below as an example for how
to instrument your application.

#### TODO: Choose one of these examples to use
#### Example 1) Local OpenTelemetry demo for this chart
```bash
kubectl create namespace otel-demo
```

```bash
curl https://raw.githubusercontent.com/signalfx/splunk-otel-collector-chart/main/examples/enable-operator-and-auto-instrumentation/otel-demo/otel-demo.yaml | kubectl apply -n otel-demo -f -
```

#### Example 2) Local test .Net app for this chart that is a webserver and generates traffic

```bash
kubectl delete -f ../../functional_tests/testdata/dotnet/deployment.yaml -n default
sleep 2
kubectl apply -f ../../functional_tests/testdata/dotnet/deployment.yaml -n default
```

#### Example 3) Upstream Operator demo, likely doesn't generate traffic

```bash
curl https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/tests/e2e-instrumentation/instrumentation-dotnet-musl/01-install-app.yaml | kubectl apply -n default -f -
```

### 2. Complete the steps outlined in [Getting started with auto-instrumentation](../../docs/auto-instrumentation-install.md#steps-for-setting-up-auto-instrumentation)

#### 2.1 Deploy the Helm Chart with the Operator enabled

To install the chart with operator in an existing cluster, make sure you have cert-manager installed and available.
Both the cert-manager and operator are subcharts of this chart and can be enabled with `--set certmanager.enabled=true,operator.enabled=true`.
These helm install commands will deploy the chart to the current namespace for this example.

```bash
# Check if a cert-manager is already installed by looking for cert-manager pods.
kubectl get pods -l app=cert-manager --all-namespaces

# If cert-manager is deployed, make sure to remove certmanager.enabled=true to the list of values to set
helm install splunk-otel-collector -f ./my_values.yaml --set operator.enabled=true,certmanager.enabled=true,environment=dev splunk-otel-collector-chart/splunk-otel-collector
```

#### 2.2 Verify all the OpenTelemetry resources (collector, operator, webhook, instrumentation) are deployed successfully

<details>
<summary>Expand for kubectl commands to run and output</summary>

```bash
kubectl get pods
# NAME                                                            READY   STATUS             RESTARTS        AGE
# splunk-otel-collector-agent-2mtfn                               2/2     Running            0                5m
# splunk-otel-collector-agent-k4gc8                               2/2     Running            0                5m
# splunk-otel-collector-agent-wjt98                               2/2     Running            0                5m
# splunk-otel-collector-certmanager-69b98cc84d-2vzl7              1/1     Running            0                5m
# splunk-otel-collector-certmanager-cainjector-76db6dcbbf-4625c   1/1     Running            0                5m
# splunk-otel-collector-certmanager-webhook-bc68cd487-dctrf       1/1     Running            0                5m
# splunk-otel-collector-k8s-cluster-receiver-8449bfdc8-hhbvz      1/1     Running            0                5m
# splunk-otel-collector-operator-754c9d78f8-9ztwg                 2/2     Running            0                5m

kubectl get mutatingwebhookconfiguration.admissionregistration.k8s.io
# NAME                                      WEBHOOKS   AGE
# splunk-otel-collector-certmanager-webhooh 1          8m
# splunk-otel-collector-operator-mutation   3          2m

kubectl get otelinst
# NAME                    AGE   ENDPOINT
# splunk-otel-collector   5m    http://$(SPLUNK_OTEL_AGENT):4317

# TODO: Update this section according to what example/demo is used
kubectl get pods -n otel-demo
# NAME                                                        READY   STATUS    RESTARTS   AGE
# opentelemetry-demo-frontend-67f5685979-b4ngb                1/1     Running   0          2m11s
```

</details>

#### 2.3 Instrument Application by Setting an Annotation

Apply the instrumentation annotation to instrument the .Net deployment `opentelemetry-demo-frontend`:

#### TODO: Choose one of these examples to use
#### Example 1) Local OpenTelemetry demo for this chart

TODO: Choose one of these. Depending on if you are using linux-64 or linux-muscl-64 you will use one of these annotation apply (patch commands).
The linux-x64 annotation value is used if no instrumentation.opentelemetry.io/otel-dotnet-auto-runtime is supplied.

```bash
kubectl patch deployment opentelemetry-demo-cartservice -n otel-demo -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/otel-dotnet-auto-runtime":"linux-x64"}}}} }'
```

```bash
kubectl patch deployment opentelemetry-demo-cartservice -n otel-demo -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/otel-dotnet-auto-runtime":"linux-musl-x64"}}}} }'
```

Then apply the auto-instrumentation annotation for the instrumentation to happen.

```bash
kubectl patch deployment opentelemetry-demo-cartservice -n otel-demo -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/inject-dotnet":"default/splunk-otel-collector"}}}} }'
```

#### Example 2) Local test .Net app for this chart that is a webserver and generates traffic
TODO: Choose one of these. Depending on if you are using linux-64 or linux-muscl-64 you will use one of these annotation apply (patch commands).
The linux-x64 annotation value is used if no instrumentation.opentelemetry.io/otel-dotnet-auto-runtime is supplied.

```bash
kubectl patch deployment dotnet-test -n default -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/otel-dotnet-auto-runtime":"linux-x64"}}}} }'
```

```bash
kubectl patch deployment dotnet-test -n default -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/otel-dotnet-auto-runtime":"linux-musl-x64"}}}} }'
```

Then apply the auto-instrumentation annotation for the instrumentation to happen.

```bash
kubectl patch deployment dotnet-test -n default -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/inject-dotnet":"default/splunk-otel-collector"}}}} }'
```

#### Example 3) Upstream Operator demo, likely doesn't generate traffic
TODO: Choose one of these. Depending on if you are using linux-64 or linux-muscl-64 you will use one of these annotation apply (patch commands).
The linux-x64 annotation value is used if no instrumentation.opentelemetry.io/otel-dotnet-auto-runtime is supplied.

```bash
kubectl patch deployment my-deployment-with-sidecar -n default -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/otel-dotnet-auto-runtime":"linux-x64"}}}} }'
```

```bash
kubectl patch deployment my-deployment-with-sidecar -n default -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/otel-dotnet-auto-runtime":"linux-musl-x64"}}}} }'
```

Then apply the auto-instrumentation annotation for the instrumentation to happen.

```bash
kubectl patch deployment my-deployment-with-sidecar -n default -p '{"spec": {"template":{"metadata":{"annotations":{"instrumentation.opentelemetry.io/inject-dotnet":"default/splunk-otel-collector"}}}} }'
```

#### General Examples Notes
**Note:**
- This will cause the opentelemetry-demo-frontend pod to restart.
- The annotation value "default/splunk-otel-collector" refers to the Instrumentation configuration named `splunk-otel-collector` in the `default` namespace.
- If the chart is not installed in the "default" namespace, modify the annotation value to be "{chart_namespace}/splunk-otel-collector".

Remove the annotation to disable instrumentation:

TODO: Update this for the proper example/demo used
```bash
kubectl patch deployment {deployment_name} -n {deployment_namespace} --type=json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/instrumentation.opentelemetry.io~1inject-dotnet"}]'
```

You can verify instrumentation was successful on an individual pod with. Check that these bullet points are
true for the instrumented pod using the command below.
- Your instrumented pods should contain an initContainer named `opentelemetry-auto-instrumentation`
- The target application container should have several OTEL_* env variables set that are similar to the output below.

<details>
<summary>Expand for commands to run to verify instrumentation</summary>

TODO: Update this for the proper example/demo used
```bash
kubectl describe pod -n default -l app=dotnet-test
# Name:             dotnet-test-8499bc67dc-wn2fm
# Namespace:        default
# Labels:           app=dotnet-test
#                   pod-template-hash=8499bc67dc
# Annotations:      cni.projectcalico.org/containerID: 1f036e2d27391289aadabe5e9b55746e9d336a6eb120c84c96954d6125a864d5
#                   cni.projectcalico.org/podIP: 100.101.34.226/32
#                   cni.projectcalico.org/podIPs: 100.101.34.226/32
#                   instrumentation.opentelemetry.io/inject-dotnet: true
#                   instrumentation.opentelemetry.io/otel-dotnet-auto-runtime: linux-x64
#                   kubernetes.io/limit-ranger: LimitRanger plugin set: cpu request for container dotnet-test
# Status:           Running
# Init Containers:
#   opentelemetry-auto-instrumentation-dotnet:
#     Container ID:  containerd://062483a82fe212bb54d9ab59ae3259ae1fbaf78cca3adbd9fdd554cc02fed6a1
#     Image:         ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-dotnet:1.0.0
#     Image ID:      ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-dotnet@sha256:97f4ceb4294133f4c9a6837b0bdda6929a654cddc71c9cc03016c1ef76d1d53d
#     Port:          <none>
#     Host Port:     <none>
#     Command:
#       cp
#       -a
#       /autoinstrumentation/.
#       /otel-auto-instrumentation-dotnet
#     State:          Terminated
#       Reason:       Completed
#     Ready:          True
#     Restart Count:  0
#     Limits:
#       cpu:     500m
#       memory:  128Mi
#     Requests:
#       cpu:        50m
#       memory:     128Mi
#     Environment:  <none>
#     Mounts:
#       /otel-auto-instrumentation-dotnet from opentelemetry-auto-instrumentation-dotnet (rw)
#       /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-j5wm6 (ro)
# Containers:
#   dotnet-test:
#     Container ID:   containerd://dfcc9e74a37c2fe3c254e2ccfee506febfc9ab8efcc70f05c64f2dbab4eafa22
#     Image:          jvsplk/dotnet_test:latest
#     Image ID:       docker.io/jvsplk/dotnet_test@sha256:a73272be81969dfbf76f2a39f3f2201d4bcfa83a728c125d8912c10392f558d3
#     State:          Running
#     Ready:          True
#     Restart Count:  0
#     Requests:
#       cpu:  100m
#     Environment:
#       OTEL_EXPORTER_OTLP_ENDPOINT:         http://$(SPLUNK_OTEL_AGENT):4318
#       CORECLR_ENABLE_PROFILING:            1
#       CORECLR_PROFILER:                    {918728DD-259F-4A6A-AC2B-B85E1B658318}
#       CORECLR_PROFILER_PATH:               /otel-auto-instrumentation-dotnet/linux-x64/OpenTelemetry.AutoInstrumentation.Native.so
#       DOTNET_STARTUP_HOOKS:                /otel-auto-instrumentation-dotnet/net/OpenTelemetry.AutoInstrumentation.StartupHook.dll
#       DOTNET_ADDITIONAL_DEPS:              /otel-auto-instrumentation-dotnet/AdditionalDeps
#       OTEL_DOTNET_AUTO_HOME:               /otel-auto-instrumentation-dotnet
#       DOTNET_SHARED_STORE:                 /otel-auto-instrumentation-dotnet/store
#       SPLUNK_OTEL_AGENT:                    (v1:status.hostIP)
#       OTEL_SERVICE_NAME:                   dotnet-test
#       OTEL_RESOURCE_ATTRIBUTES_POD_NAME:   dotnet-test-8499bc67dc-wn2fm (v1:metadata.name)
#       OTEL_RESOURCE_ATTRIBUTES_NODE_NAME:   (v1:spec.nodeName)
#       OTEL_PROPAGATORS:                    tracecontext,baggage,b3
#       OTEL_RESOURCE_ATTRIBUTES:            splunk.zc.method=autoinstrumentation-dotnet:1.0.0,k8s.container.name=dotnet-test,k8s.deployment.name=dotnet-test,k8s.namespace.name=default,k8s.node.name=$(OTEL_RESOURCE_ATTRIBUTES_NODE_NAME),k8s.pod.name=$(OTEL_RESOURCE_ATTRIBUTES_POD_NAME),k8s.replicaset.name=dotnet-test-8499bc67dc,service.version=latest
#     Mounts:
#       /otel-auto-instrumentation-dotnet from opentelemetry-auto-instrumentation-dotnet (rw)
#       /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-j5wm6 (ro)
# Conditions:
#   Type              Status
#   Initialized       True
#   Ready             True
#   ContainersReady   True
#   PodScheduled      True
# Volumes:
#   opentelemetry-auto-instrumentation-dotnet:
#     Type:        EmptyDir (a temporary directory that shares a pod's lifetime)
#     Medium:
#     SizeLimit:   200Mi
```

</details>

#### 2.4 Check out the results at [Splunk Observability APM](https://app.us1.signalfx.com/#/apm)

![APM](auto-instrumentation-dotnet-apm-result.png)


TODO:
Add note about different logs existing in cat /var/log/opentelemetry/dotnet/
kubectl exec -it dotnet-test-8499bc67dc-97s5t -- /bin/sh
ls /var/log/opentelemetry/dotnet/
otel-dotnet-auto-DotNetTestApp-1-20240122.log  otel-dotnet-auto-DotNetTestApp-1-Loader-20240117.log  otel-dotnet-auto-DotNetTestApp-1-StartupHook-20240117.log  otel-dotnet-auto-native-dotnet-1.log
cat  /var/log/opentelemetry/dotnet/otel-dotnet-auto-DotNetTestApp-1-20240122.log
