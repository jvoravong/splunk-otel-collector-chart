This compact document outlines many of the available configuration values for
this chart. For full in depths details, you can view the Chart
[values.yaml](./values.yaml) file.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `""` | Kubernetes object names. |
| fullnameOverride | string | `""` | fullnameOverride completely replaces the generated name. |
| clusterName | string | `""` | .cluster.name" attribute. |
| splunkPlatform.endpoint | string | `""` | enables Splunk Platform as a destination. |
| splunkPlatform.token | string | `""` | HTTP Event Collector token. |
| splunkPlatform.index | string | `"main"` | Name of the Splunk event type index targeted. Required when ingesting logs to Splunk Platform. |
| splunkPlatform.metricsIndex | string | `""` | Name of the Splunk metric type index targeted. Required when ingesting metrics to Splunk Platform. |
| splunkPlatform.tracesIndex | string | `""` | Name of the Splunk event type index targeted. Required when ingesting traces to Splunk Platform. |
| splunkPlatform.source | string | `"kubernetes"` | Optional. Default value for `source` field. |
| splunkPlatform.sourcetype | string | `""` | be container name. |
| splunkPlatform.maxConnections | int | `200` | Maximum HTTP connections to use simultaneously when sending data. |
| splunkPlatform.disableCompression | bool | `true` | Whether to disable gzip compression over HTTP. Defaults to true. |
| splunkPlatform.timeout | string | `"10s"` | HTTP timeout when sending data. Defaults to 10s. |
| splunkPlatform.insecureSkipVerify | bool | `false` | data over HTTPS. |
| splunkPlatform.clientCert | string | `""` | file path. The certificate will be stored as a secret in kubernetes. |
| splunkPlatform.clientKey | string | `""` | The key will be stored as a secret in kubernetes. |
| splunkPlatform.caFile | string | `""` | The file will be stored as a secret in kubernetes. |
| splunkPlatform.logsEnabled | bool | `true` | Splunk Platform. Only logs collection is enabled by default. |
| splunkPlatform.metricsEnabled | bool | `false` | If you enable metrics collection, make sure that `metricsIndex` is provided as well. |
| splunkPlatform.tracesEnabled | bool | `false` | If you enable traces collection, make sure that `tracesIndex` is provided as well. |
| splunkPlatform.fieldNameConvention | object | `{"keepOtelConvention":true,"renameFieldsSck":false}` | Field name conventions to use. (Only for those who are migrating from Splunk Connect for Kubernetes helm chart) |
| splunkPlatform.fieldNameConvention.renameFieldsSck | bool | `false` | Boolean for renaming pod metadata fields to match to Splunk Connect for Kubernetes helm chart. |
| splunkPlatform.fieldNameConvention.keepOtelConvention | bool | `true` | Boolean for keeping Otel convention fields after renaming it |
| splunkPlatform.retryOnFailure.enabled | bool | `true` | for detailed examples |
| splunkPlatform.retryOnFailure.initialInterval | string | `"5s"` | Time to wait after the first failure before retrying; ignored if enabled is false |
| splunkPlatform.retryOnFailure.maxInterval | string | `"30s"` | The upper bound on backoff; ignored if enabled is false |
| splunkPlatform.retryOnFailure.maxElapsedTime | string | `"300s"` | The maximum amount of time spent trying to send a batch; ignored if enabled is false |
| splunkPlatform.sendingQueue.enabled | bool | `true` |  |
| splunkPlatform.sendingQueue.numConsumers | int | `10` | Number of consumers that dequeue batches; ignored if enabled is false |
| splunkPlatform.sendingQueue.queueSize | int | `5000` | requests_per_second is the average number of requests per seconds. |
| splunkObservability.realm | string | `""` | destination. |
| splunkObservability.accessToken | string | `""` | Observability org access token. |
| splunkObservability.ingestUrl | string | `""` | "https://ingest.<realm>.signalfx.com". |
| splunkObservability.apiUrl | string | `""` | "https://api.<realm>.signalfx.com". |
| splunkObservability.metricsEnabled | bool | `true` | Options to disable or enable metric telemetry data types. |
| splunkObservability.tracesEnabled | bool | `true` | Options to disable or enable trace telemetry data types. |
| splunkObservability.logsEnabled | bool | `false` | Options to disable or enable log telemetry data types. |
| splunkObservability.infrastructureMonitoringEventsEnabled | bool | `false` | and set splunkObservability.logsEnabled to true. |
| splunkObservability.profilingEnabled | bool | `false` | If you don't use AlwaysOn Profiling for Splunk APM, you can disable it. |
| logsEngine | string | `"fluentd"` | an extra container for fluentd. |
| cloudProvider | string | `""` | - Leave empty for none/other. |
| distribution | string | `""` | - Leave empty for none/other. |
| environment | string | `nil` | users to investigate data coming from different source separately. |
| autodetect | object | `{"istio":false,"prometheus":false}` | Optional Automatic detection of additional metric sources. |
| autodetect.prometheus | bool | `false` | "prometheus.io/scrape". |
| autodetect.istio | bool | `false` | Set autodetect.istio=true in istio environment. |
| extraAttributes | object | `{"custom":[],"fromAnnotations":[],"fromLabels":[{"key":"app"}]}` | always sent to Splunk Observability (if enabled) as metric properties. |
| clusterReceiver.enabled | bool | `true` | It has to be running on one pod, so it uses its own dedicated deployment with 1 replica. |
| clusterReceiver.resources | object | `{"limits":{"cpu":"200m","memory":"500Mi"}}` | Need to be adjusted based on size of the monitored cluster |
| clusterReceiver.nodeSelector | object | `{}` | Scheduling configurations |
| clusterReceiver.tolerations | list | `[]` |  |
| clusterReceiver.affinity | object | `{}` |  |
| clusterReceiver.securityContext | object | `{}` | Pod configurations |
| clusterReceiver.terminationGracePeriodSeconds | int | `600` |  |
| clusterReceiver.priorityClassName | string | `""` |  |
| clusterReceiver.annotations | object | `{}` | k8s cluster receiver collector annotations |
| clusterReceiver.podAnnotations | object | `{}` |  |
| clusterReceiver.eventsEnabled | bool | `false` | Once the receiver is stabilized, it'll be enabled by default in this helm chart |
| clusterReceiver.k8sObjects | list | `[]` | https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/k8sobjectsreceiver |
| clusterReceiver.podLabels | object | `{}` | k8s cluster receiver extra pod labels |
| clusterReceiver.extraEnvs | list | `[]` | Extra enviroment variables to be set in the OTel Cluster Receiver container |
| clusterReceiver.extraVolumes | list | `[]` | Extra volumes to be mounted to the k8s cluster receiver container. |
| clusterReceiver.extraVolumeMounts | list | `[]` |  |
| clusterReceiver.featureGates | string | `""` | Enable or disable features of the cluster receiver. |
| clusterReceiver.config | object | `{}` | existing fields can be disabled by setting them to null value. |
| podDisruptionBudget | object | `{}` |  |
| serviceAccount.create | bool | `true` | Specifies whether a ServiceAccount should be created |
| serviceAccount.name | string | `""` | If not set and create is true, a name is generated using the fullname template |
| serviceAccount.annotations | object | `{}` | Service account annotations |
| rbac.create | bool | `true` | Create or use existing RBAC resources |
| rbac.customRules | list | `[]` | Specifies additional rules that will be added to the clusterRole. |
| secret | object | `{"create":true,"name":"","validateSecret":true}` | Create or use existing secret if name is empty default name is used |
| secret.validateSecret | bool | `true` | Specifies whether secret provided by user should be validated. |
| tolerations | list | `[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master"}]` | so that we can also collect logs and metrics from those nodes. |
| nodeSelector | object | `{}` | Defines which nodes should be selected to deploy the o11y collector daemonset. |
| terminationGracePeriodSeconds | int | `600` |  |
| affinity | object | `{}` | Defines node affinity to restrict deployment of the o11y collector daemonset. |
| priorityClassName | string | `""` | Defines priorityClassName to assign a priority class to pods. |
| readinessProbe | object | `{"initialDelaySeconds":0}` | It is recommended to keep it a 60-second window but it depends on cluster specification. |
| livenessProbe.initialDelaySeconds | int | `0` |  |
| isWindows | bool | `false` | Specifies whether to apply for k8s cluster with windows worker node. |
| securityContextConstraintsOverwrite | object | `{}` | NOTE: This config will only be used when distribution=openshift |
| service | object | `{"annotations":{},"type":"ClusterIP"}` | opentelemetry collector service created only if collector.enabled = true |
| service.type | string | `"ClusterIP"` | Service type |
| service.annotations | object | `{}` | Service annotations |
| operator | object | `{"enabled":false}` | https://github.com/open-telemetry/opentelemetry-helm-charts/blob/main/charts/opentelemetry-operator/values.yaml ############################################################################### |
| operator.enabled | bool | `false` | Currently, this feature cannot be enabled. Coming soon. |
