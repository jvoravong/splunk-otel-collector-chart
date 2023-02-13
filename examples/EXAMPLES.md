
<details close>
<summary>Example: route-data-through-gateway-deployed-separately-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      otlp:
        endpoint: <custom-gateway-url>:4317
        tls:
          insecure: true
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: http://<custom-gateway-url>:6060
        correlation: null
        ingest_url: http://<custom-gateway-url>:9943
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        logs:
          exporters:
          - otlp
        metrics:
          exporters:
          - otlp
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - otlp
          - signalfx
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resourcedetection
          - resource
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: http://<custom-gateway-url>:6060
        ingest_url: http://<custom-gateway-url>:9943
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: bc1bf4fa0fa13665c3106a5521c612939752c8ad3428faf5c93de02967ffcc7e
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 189de116b86b7c5d9f55fa4647c8627b9aa6946291023e229498778b74404a17
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: filter-container-metrics-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/exclude_containers:
        metrics:
          exclude:
            match_type: regexp
            resource_attributes:
            - Key: k8s.container.name
              Value: ^(containerX|containerY)$
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          - filter/exclude_containers
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      filter/exclude_containers:
        metrics:
          exclude:
            match_type: regexp
            resource_attributes:
            - Key: k8s.container.name
              Value: ^(containerX|containerY)$
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          - filter/exclude_containers
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: 57ada3cba700545e990efc1d8c7edd2a249116a93973ebbef4c74faef73c09e6
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 137d211d21eccc48e4268e12c29c811e0546677ab867f2cd2898978b836ad496
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: add-receiver-creator-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          postgresql:
            config:
              endpoint: localhost:5433
              password: password
              username: postgres
            rule: type == "port" && port == 5433
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
          smartagent/postgresql:
            config:
              connectionString: sslmode=disable user={{.username}} password={{.password}}
              params:
                password: password
                username: postgres
              port: 5432
              type: postgresql
            rule: type == "port" && port == 5432
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          - signalfx
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resourcedetection
          - resource
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: 38479c03e5add2b8a5fec907700bf8dd3649d9aa584dd86280ff9d6f34812316
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 94371fe9c8062ad6c2eb9da843086ee092b3d1ddc2753b9f8198e6a422c5a20c
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: splunk-enterprise-index-routing-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_platform_hec_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      splunk_hec/platform_logs:
        disable_compression: true
        endpoint: http://localhost:8088/services/collector
        index: main
        max_connections: 200
        profiling_data_enabled: false
        retry_on_failure:
          enabled: true
          initial_interval: 5s
          max_elapsed_time: 300s
          max_interval: 30s
        sending_queue:
          enabled: true
          num_consumers: 10
          queue_size: 5000
        source: kubernetes
        splunk_app_name: splunk-otel-collector
        splunk_app_version: 0.70.0
        timeout: 10s
        tls:
          insecure_skip_verify: false
        token: ${SPLUNK_PLATFORM_HEC_TOKEN}
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      fluentforward:
        endpoint: 0.0.0.0:8006
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        logs:
          exporters:
          - splunk_hec/platform_logs
          processors:
          - memory_limiter
          - groupbyattrs/logs
          - k8sattributes
          - filter/logs
          - batch
          - resource/logs
          - resourcedetection
          - resource
          receivers:
          - fluentforward
          - otlp
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-fluentd-json.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-fluentd-json
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  source.containers.parse.conf: |-
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%NZ

  output.filter.conf: ""

  output.transform.conf: ""
---
# Source: splunk-otel-collector/templates/configmap-fluentd.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-fluentd
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  fluent.conf: |-
    @include system.conf
    @include source.containers.conf
    @include source.files.conf
    @include source.journald.conf
    @include output.conf
    @include prometheus.conf

  system.conf: |-
    # system wide configurations
    <system>
      log_level info
      root_dir /tmp/fluentd
    </system>

  prometheus.conf: |-
    # input plugin that exports metrics
    <source>
      @type prometheus
    </source>

    # input plugin that collects metrics from MonitorAgent
    <source>
      @type prometheus_monitor
    </source>

    # input plugin that collects metrics for output plugin
    <source>
      @type prometheus_output_monitor
    </source>

  source.containers.conf: |-
    # This configuration file for Fluentd / td-agent is used
    # to watch changes to Docker log files. The kubelet creates symlinks that
    # capture the pod name, namespace, container name & Docker container ID
    # to the docker logs for pods in the /var/log/containers directory on the host.
    # If running this fluentd configuration in a Docker container, the /var/log
    # directory should be mounted in the container.
    # reading kubelet logs from journal
    #
    # Reference:
    # https://github.com/kubernetes/community/blob/20d2f6f5498a5668bae2aea9dcaf4875b9c06ccb/contributors/design-proposals/node/kubelet-cri-logging.md
    #
    # Json Log Example:
    # {"log":"[info:2016-02-16T16:04:05.930-08:00] Some log text here\n","stream":"stdout","time":"2016-02-17T00:04:05.931087621Z"}
    # CRI Log Example (not supported):
    # 2016-02-17T00:04:05.931087621Z stdout P { 'long': { 'json', 'object output' },
    # 2016-02-17T00:04:05.931087621Z stdout F 'splitted': 'partial-lines' }
    # 2016-02-17T00:04:05.931087621Z stdout F [info:2016-02-16T16:04:05.930-08:00] Some log text here
    <source>
      @id containers.log
      @type tail
      @label @CONCAT
      tag tail.containers.*
      path /var/log/containers/*.log
      pos_file /var/log/splunk-fluentd-containers.log.pos
      path_key source
      read_from_head true
      <parse>
        @include source.containers.parse.conf
        time_key time
        time_type string
        localtime false
      </parse>
    </source>

  source.files.conf: |-
    # This fluentd conf file contains sources for log files other than container logs.
    <source>
      @id tail.file.kube-audit
      @type tail
      @label @CONCAT
      tag tail.file.kube:apiserver-audit
      path /var/log/kube-apiserver-audit.log
      pos_file /var/log/splunk-fluentd-kube-audit.pos
      read_from_head true
      path_key source
      <parse>
        @type regexp
        expression /^(?<log>.*)$/
        time_key time
        time_type string
        time_format %Y-%m-%dT%H:%M:%SZ
      </parse>
    </source>

  source.journald.conf: |-
    # This fluentd conf file contains configurations for reading logs from systemd journal.
    <source>
      @id journald-docker
      @type systemd
      @label @CONCAT
      tag journald.kube:docker
      path "/run/log/journal"
      matches [{ "_SYSTEMD_UNIT": "docker.service" }]
      read_from_head true
      <storage>
        @type local
        persistent true
        path /var/log/splunkd-fluentd-journald-docker.pos.json
      </storage>
      <entry>
        field_map {"MESSAGE": "log", "_SYSTEMD_UNIT": "source"}
        field_map_strict true
      </entry>
    </source>
    <source>
      @id journald-kubelet
      @type systemd
      @label @CONCAT
      tag journald.kube:kubelet
      path "/run/log/journal"
      matches [{ "_SYSTEMD_UNIT": "kubelet.service" }]
      read_from_head true
      <storage>
        @type local
        persistent true
        path /var/log/splunkd-fluentd-journald-kubelet.pos.json
      </storage>
      <entry>
        field_map {"MESSAGE": "log", "_SYSTEMD_UNIT": "source"}
        field_map_strict true
      </entry>
    </source>

  output.conf: |-
    #Events are emitted to the CONCAT label from the container, file and journald sources for multiline processing.
    <label @CONCAT>
      @include output.filter.conf
      # = handle custom multiline logs =
      <filter tail.containers.var.log.containers.dns-controller*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-dns*sidecar*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-dns*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-apiserver*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-controller-manager*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-dns-autoscaler*autoscaler*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-proxy*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-scheduler*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      <filter tail.containers.var.log.containers.kube-dns*.log>
        @type concat
        key log
        timeout_label @SPLUNK
        stream_identity_key stream
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
        separator ""
        use_first_timestamp true
      </filter>
      # = filters for journald logs =
      <filter journald.kube:kubelet>
        @type concat
        key log
        timeout_label @SPLUNK
        multiline_start_regexp /^\w[0-1]\d[0-3]\d/
        flush_interval 5s
      </filter>
      # Events are relabeled then emitted to the SPLUNK label
      <match **>
        @type relabel
        @label @SPLUNK
      </match>
    </label>
    <label @SPLUNK>
      # Extract k8s metadata from container logs source paths. Use original logs source
      # "/var/log/containers/<k8s.pod.k8s>_<k8s.namespace.name>_<k8s.container.name>-<container.id>.log"
      # first then check symlinks to the new k8s logs format
      # "/var/log/pods/<k8s.namespace.name>_<k8s.pod.name>_<k8s.pod.uid>/<k8s.container.name>/<k8s.container.restart_count>.log"
      # to fetch "k8s.pod.uid" that will be used to get other k8s metadata by otel-collector from k8s API.
      <filter tail.containers.**>
        @type record_modifier
        <record>
          pods_source ${File.readlink(record['source'])}
        </record>
      </filter>
      <filter tail.containers.**>
        @type jq_transformer
        jq '.record | . + (.source | capture("^/var/log/containers/(?<k8s.pod.name>[^_]+)_(?<k8s.namespace.name>[^_]+)_(?<k8s.container.name>[-0-9a-z]+)-(?<container.id>[^.]+).log$")) | . + (.pods_source | capture("^/var/log/pods/[^_]+_[^_]+_(?<k8s.pod.uid>[^/]+)/[^._]+/[0-9]+.log$") // {}) | .sourcetype = ("kube:container:" + .["k8s.container.name"])'
      </filter>

      @include output.transform.conf

      # create source and sourcetype
      <filter journald.**>
        @type jq_transformer
        jq '.record.source = "/run/log/journal/" + .record.source | .record.sourcetype = (.tag | ltrimstr("journald.")) |.record'
      </filter>

      # = filters for non-container log files =
      # extract sourcetype
      <filter tail.file.**>
        @type jq_transformer
        jq '.record.sourcetype = (.tag | ltrimstr("tail.file.")) | .record'
      </filter>

      # = custom filters specified by users =

      <filter **>
        @type record_transformer
        enable_ruby
        <record>
          com.splunk.sourcetype ${record.dig("sourcetype") ? record.dig("sourcetype") : ""}
          com.splunk.source ${record.dig("source") ? record.dig("source") : ""}
        </record>
        remove_keys pods_source,source,sourcetype
      </filter>

      # = output =
      <match **>
        @type forward
        heartbeat_type udp
        <server>
          host 127.0.0.1
          port 8006
        </server>
        <buffer>
          @type memory
          chunk_limit_records 100000
          chunk_limit_size 1m
          flush_interval 5s
          flush_thread_count 1
          overflow_action block
          retry_max_times 3
          total_limit_size 600m
        </buffer>
        <format>
          # we just want to keep the raw logs, not the structure created by docker or journald
          @type single_value
          message_key log
          add_newline false
        </format>
      </match>
    </label>
  source.containers.parse.conf: |-
    @type regexp
    expression /^(?<time>.+) (?<stream>stdout|stderr)( (?<partial_flag>[FP]))? (?<log>.*)$/
    time_format %Y-%m-%dT%H:%M:%S.%N%:z
  output.filter.conf: |-
    # = handle cri/containerd multiline format =
    <filter tail.containers.var.log.containers.**>
      @type concat
      key log
      partial_key partial_flag
      partial_value P
      separator ''
      timeout_label @SPLUNK
    </filter>
  output.transform.conf: |-
    # extract pod_uid and container_name for CRIO runtime
    # currently CRI does not produce log paths with all the necessary
    # metadata to parse out pod, namespace, container_name, container_id.
    # this may be resolved in the future by this issue: https://github.com/kubernetes/kubernetes/issues/58638#issuecomment-385126031
    <filter tail.containers.var.log.pods.**>
      @type jq_transformer
      jq '.record | . + (.source | capture("/var/log/pods/(?<pod_uid>[^/]+)/(?<container_name>[^/]+)/(?<container_retry>[0-9]+).log")) | .sourcetype = ("kube:container:" + .container_name)'
    </filter>
    # rename pod_uid and container_name to otel semantics.
    <filter tail.containers.var.log.pods.**>
      @type record_transformer
      <record>
        k8s.pod.uid ${record["pod_uid"]}
        k8s.container.name ${record["container_name"]}
      </record>
    </filter>
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    engine: fluentd
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: 06c3daf120705029797394a1b5faee57ac67280eb59715fc8719517e72b9079b
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      initContainers:
        - name: prepare-fluentd-config
          image: splunk/fluentd-hec:1.2.8
          imagePullPolicy: IfNotPresent
          command: [ "sh", "-c"]
          securityContext:
            runAsUser: 0
          args:
            - cp /fluentd/etc/common/* /fluentd/etc/;
              if [ "${LOG_FORMAT_TYPE}" == "json" ] || [ "$(ls /var/lib/docker/containers/*/*json.log 2>/dev/null | wc -l)" != "0" ]; then
                  cp /fluentd/etc/json/* /fluentd/etc/;
              fi;
          env:
            - name: LOG_FORMAT_TYPE
              value: ""
          volumeMounts:
            - name: varlogdest
              mountPath: /var/lib/docker/containers
              readOnly: true
            - name: fluentd-config
              mountPath: /fluentd/etc
            - name: fluentd-config-common
              mountPath: /fluentd/etc/common
            - name: fluentd-config-json
              mountPath: /fluentd/etc/json
      containers:
      - name: fluentd
        image: splunk/fluentd-hec:1.2.8
        imagePullPolicy: IfNotPresent
        securityContext:
          
          runAsUser: 0
        env:
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: MY_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
        resources:
          limits:
            cpu: 500m
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 200Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlogdest
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: journallogpath
          mountPath: "/run/log/journal"
          readOnly: true
        - name: fluentd-config
          mountPath: /fluentd/etc
        - name: tmp
          mountPath: /tmp
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: fluentforward
          containerPort: 8006
          hostPort: 8006
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_PLATFORM_HEC_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_platform_hec_token

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlogdest
        hostPath:
          path: /var/lib/docker/containers
      - name: journallogpath
        hostPath:
          path: "/run/log/journal"
      - name: fluentd-config
        emptyDir: {}
      - name: fluentd-config-common
        configMap:
          name: default-splunk-otel-collector-fluentd
      - name: fluentd-config-cri
        configMap:
          name: default-splunk-otel-collector-fluentd-cri
      - name: fluentd-config-json
        configMap:
          name: default-splunk-otel-collector-fluentd-json
      - name: tmp
        emptyDir: {}
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: fluentd-multiline-logs-java-stack-traces-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          - signalfx
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resourcedetection
          - resource
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: f24285909af0884c7557482977a7a54aa1294e3a121a5cf78d7572a19fc5bafd
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 94371fe9c8062ad6c2eb9da843086ee092b3d1ddc2753b9f8198e6a422c5a20c
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: collector-gateway-only-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-gateway.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
        sending_queue:
          num_consumers: 32
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sending_queue:
          num_consumers: 32
    extensions:
      health_check: null
      http_forwarder:
        egress:
          endpoint: https://api.CHANGEME.signalfx.com
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource/add_cluster_name:
        attributes:
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/collector:
        config:
          scrape_configs:
          - job_name: otel-collector
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      signalfx:
        access_token_passthrough: true
        endpoint: 0.0.0.0:9943
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - memory_ballast
      - zpages
      - http_forwarder
      pipelines:
        logs/signalfx-events:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          receivers:
          - signalfx
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_cluster_name
          receivers:
          - otlp
          - signalfx
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource/add_cluster_name
          receivers:
          - prometheus/collector
        traces:
          exporters:
          - sapm
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resource/add_cluster_name
          receivers:
          - otlp
          - jaeger
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-collector
spec:
  type: ClusterIP
  ports:
  - name: http-forwarder
    port: 6060
    targetPort: http-forwarder
    protocol: TCP
  - name: jaeger-grpc
    port: 14250
    targetPort: jaeger-grpc
    protocol: TCP
  - name: jaeger-thrift
    port: 14268
    targetPort: jaeger-thrift
    protocol: TCP
  - name: otlp
    port: 4317
    targetPort: otlp
    protocol: TCP
  - name: otlp-http
    port: 4318
    targetPort: otlp-http
    protocol: TCP
  - name: otlp-http-old
    port: 55681
    targetPort: otlp-http-old
    protocol: TCP
  - name: signalfx
    port: 9943
    targetPort: signalfx
    protocol: TCP
  - name: zipkin
    port: 9411
    targetPort: zipkin
    protocol: TCP
  selector:
    app: splunk-otel-collector
    component: otel-collector
    release: default
---
# Source: splunk-otel-collector/templates/deployment-gateway.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-collector
spec:
  replicas: 3
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-collector
        release: default
      annotations:
        checksum/config: 0a71c96ab49070efbab9792ac6bd2a7fd6c79456ffbd8742ee2dda17103c2ae6
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "8192"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        ports:
        - name: http-forwarder
          containerPort: 6060
          protocol: TCP
        - name: jaeger-grpc
          containerPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          protocol: TCP
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 4
            memory: 8Gi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-collector
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: collector-cluster-receiver-only-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
      splunk_hec/o11y:
        disable_compression: true
        endpoint: https://ingest.CHANGEME.signalfx.com/v1/log
        log_data_enabled: true
        profiling_data_enabled: false
        token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
      transform/add_sourcetype:
        log_statements:
        - context: log
          statements:
          - set(resource.attributes["com.splunk.sourcetype"], Concat(["kube:object:",
            attributes["k8s.resource.name"]], ""))
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      k8sobjects:
        auth_type: serviceAccount
        objects:
        - field_selector: status.phase=Running
          interval: 15m
          label_selector: environment in (production),tier in (frontend)
          mode: pull
          name: pods
        - group: events.k8s.io
          mode: watch
          name: events
          namespaces:
          - default
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        logs/objects:
          exporters:
          - splunk_hec/o11y
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          - transform/add_sourcetype
          receivers:
          - k8sobjects
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: c4743fac640a0ee010545732c3252ea72f78ec092f66f614314e541eb8687a3d
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: add-sampler-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      probabilistic_sampler:
        hash_seed: 22
        sampling_percentage: 15.3
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          - signalfx
          processors:
          - memory_limiter
          - probabilistic_sampler
          - k8sattributes
          - batch
          - resource
          - resourcedetection
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: fb7b212cc914fce0178fb811a13ec32be64b73489d87cef5249462f9b9d29e2b
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 94371fe9c8062ad6c2eb9da843086ee092b3d1ddc2753b9f8198e6a422c5a20c
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: enable-trace-sampling-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      probabilistic_sampler:
        hash_seed: 22
        sampling_percentage: 15.3
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          processors:
          - memory_limiter
          - probabilistic_sampler
          - k8sattributes
          - batch
          - resource
          - resourcedetection
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: ab13703d5dd5ac2341d3f122a1b80e2775536c7f7abb85f2b05e7de113881c1e
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: collector-agent-only-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          - signalfx
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resourcedetection
          - resource
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: f24285909af0884c7557482977a7a54aa1294e3a121a5cf78d7572a19fc5bafd
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: crio-logging-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          - signalfx
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resourcedetection
          - resource
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: f24285909af0884c7557482977a7a54aa1294e3a121a5cf78d7572a19fc5bafd
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 94371fe9c8062ad6c2eb9da843086ee092b3d1ddc2753b9f8198e6a422c5a20c
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: use-proxy-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          - signalfx
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resourcedetection
          - resource
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: f24285909af0884c7557482977a7a54aa1294e3a121a5cf78d7572a19fc5bafd
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo
          - name: HTTPS_PROXY
            value: 192.168.0.10

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 94371fe9c8062ad6c2eb9da843086ee092b3d1ddc2753b9f8198e6a422c5a20c
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          - name: HTTPS_PROXY
            value: 192.168.0.10
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  
<details close>
<summary>Example: enabled-pprof-extension-values.yaml</summary>
<pre><code>
---
# Source: splunk-otel-collector/templates/serviceAccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
---
# Source: splunk-otel-collector/templates/secret-splunk.yaml
apiVersion: v1
kind: Secret
metadata:
  name: splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
type: Opaque
data:
  splunk_observability_access_token: Q0hBTkdFTUU=
---
# Source: splunk-otel-collector/templates/configmap-agent.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      sapm:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        endpoint: https://ingest.CHANGEME.signalfx.com/v2/trace
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        correlation: null
        ingest_url: https://ingest.CHANGEME.signalfx.com
        sync_host_metadata: true
    extensions:
      health_check: null
      k8s_observer:
        auth_type: serviceAccount
        node: ${K8S_NODE_NAME}
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
      pprof: null
      zpages: null
    processors:
      batch: null
      filter/logs:
        logs:
          exclude:
            match_type: strict
            resource_attributes:
            - key: splunk.com/exclude
              value: "true"
      groupbyattrs/logs:
        keys:
        - com.splunk.source
        - com.splunk.sourcetype
        - container.id
        - fluent.tag
        - istio_service_name
        - k8s.container.name
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
      k8sattributes:
        extract:
          annotations:
          - from: pod
            key: splunk.com/sourcetype
          - from: namespace
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: pod
            key: splunk.com/exclude
            tag_name: splunk.com/exclude
          - from: namespace
            key: splunk.com/index
            tag_name: com.splunk.index
          - from: pod
            key: splunk.com/index
            tag_name: com.splunk.index
          labels:
          - key: app
          metadata:
          - k8s.namespace.name
          - k8s.node.name
          - k8s.pod.name
          - k8s.pod.uid
          - container.id
          - container.image.name
          - container.image.tag
        filter:
          node_from_env_var: K8S_NODE_NAME
        pod_association:
        - sources:
          - from: resource_attribute
            name: k8s.pod.uid
        - sources:
          - from: resource_attribute
            name: k8s.pod.ip
        - sources:
          - from: resource_attribute
            name: ip
        - sources:
          - from: connection
        - sources:
          - from: resource_attribute
            name: host.name
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_agent_k8s:
        attributes:
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/logs:
        attributes:
        - action: upsert
          from_attribute: k8s.pod.annotations.splunk.com/sourcetype
          key: com.splunk.sourcetype
        - action: delete
          key: k8s.pod.annotations.splunk.com/sourcetype
        - action: delete
          key: splunk.com/exclude
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      hostmetrics:
        collection_interval: 10s
        scrapers:
          cpu: null
          disk: null
          filesystem: null
          load: null
          memory: null
          network: null
          paging: null
          processes: null
      jaeger:
        protocols:
          grpc:
            endpoint: 0.0.0.0:14250
          thrift_http:
            endpoint: 0.0.0.0:14268
      kubeletstats:
        auth_type: serviceAccount
        collection_interval: 10s
        endpoint: ${K8S_NODE_IP}:10250
        extra_metadata_labels:
        - container.id
        metric_groups:
        - container
        - pod
        - node
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      prometheus/agent:
        config:
          scrape_configs:
          - job_name: otel-agent
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
      receiver_creator:
        receivers:
          smartagent/coredns:
            config:
              extraDimensions:
                metric_source: k8s-coredns
              port: 9153
              type: coredns
            rule: type == "pod" && labels["k8s-app"] == "kube-dns"
          smartagent/kube-controller-manager:
            config:
              extraDimensions:
                metric_source: kubernetes-controller-manager
              port: 10257
              skipVerify: true
              type: kube-controller-manager
              useHTTPS: true
              useServiceAccount: true
            rule: type == "pod" && labels["k8s-app"] == "kube-controller-manager"
          smartagent/kubernetes-apiserver:
            config:
              extraDimensions:
                metric_source: kubernetes-apiserver
              skipVerify: true
              type: kubernetes-apiserver
              useHTTPS: true
              useServiceAccount: true
            rule: type == "port" && port == 443 && pod.labels["k8s-app"] == "kube-apiserver"
          smartagent/kubernetes-proxy:
            config:
              extraDimensions:
                metric_source: kubernetes-proxy
              port: 10249
              type: kubernetes-proxy
            rule: type == "pod" && labels["k8s-app"] == "kube-proxy"
          smartagent/kubernetes-scheduler:
            config:
              extraDimensions:
                metric_source: kubernetes-scheduler
              port: 10251
              type: kubernetes-scheduler
            rule: type == "pod" && labels["k8s-app"] == "kube-scheduler"
        watch_observers:
        - k8s_observer
      signalfx:
        endpoint: 0.0.0.0:9943
      smartagent/signalfx-forwarder:
        listenAddress: 0.0.0.0:9080
        type: signalfx-forwarder
      zipkin:
        endpoint: 0.0.0.0:9411
    service:
      extensions:
      - health_check
      - k8s_observer
      - memory_ballast
      - zpages
      - pprof
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resourcedetection
          - resource
          receivers:
          - hostmetrics
          - kubeletstats
          - otlp
          - receiver_creator
          - signalfx
        metrics/agent:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_agent_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/agent
        traces:
          exporters:
          - sapm
          - signalfx
          processors:
          - memory_limiter
          - k8sattributes
          - batch
          - resourcedetection
          - resource
          receivers:
          - otlp
          - jaeger
          - smartagent/signalfx-forwarder
          - zipkin
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/configmap-cluster-receiver.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: default-splunk-otel-collector-otel-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
data:
  relay: |
    exporters:
      signalfx:
        access_token: ${SPLUNK_OBSERVABILITY_ACCESS_TOKEN}
        api_url: https://api.CHANGEME.signalfx.com
        ingest_url: https://ingest.CHANGEME.signalfx.com
        timeout: 10s
    extensions:
      health_check: null
      memory_ballast:
        size_mib: ${SPLUNK_BALLAST_SIZE_MIB}
    processors:
      batch: null
      memory_limiter:
        check_interval: 2s
        limit_mib: ${SPLUNK_MEMORY_LIMIT_MIB}
      resource:
        attributes:
        - action: insert
          key: metric_source
          value: kubernetes
        - action: upsert
          key: k8s.cluster.name
          value: CHANGEME
      resource/add_collector_k8s:
        attributes:
        - action: insert
          key: k8s.node.name
          value: ${K8S_NODE_NAME}
        - action: insert
          key: k8s.pod.name
          value: ${K8S_POD_NAME}
        - action: insert
          key: k8s.pod.uid
          value: ${K8S_POD_UID}
        - action: insert
          key: k8s.namespace.name
          value: ${K8S_NAMESPACE}
      resource/k8s_cluster:
        attributes:
        - action: insert
          key: receiver
          value: k8scluster
      resourcedetection:
        detectors:
        - env
        - system
        override: true
        timeout: 10s
    receivers:
      k8s_cluster:
        auth_type: serviceAccount
        metadata_exporters:
        - signalfx
      prometheus/k8s_cluster_receiver:
        config:
          scrape_configs:
          - job_name: otel-k8s-cluster-receiver
            scrape_interval: 10s
            static_configs:
            - targets:
              - ${K8S_POD_IP}:8889
    service:
      extensions:
      - health_check
      - memory_ballast
      pipelines:
        metrics:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource
          - resource/k8s_cluster
          receivers:
          - k8s_cluster
        metrics/collector:
          exporters:
          - signalfx
          processors:
          - memory_limiter
          - batch
          - resource/add_collector_k8s
          - resourcedetection
          - resource
          receivers:
          - prometheus/k8s_cluster_receiver
      telemetry:
        metrics:
          address: 0.0.0.0:8889
---
# Source: splunk-otel-collector/templates/clusterRole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
rules:
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - nodes/stats
  - nodes/proxy
  - pods
  - pods/status
  - persistentvolumeclaims
  - persistentvolumes
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
  - list
  - watch
---
# Source: splunk-otel-collector/templates/clusterRoleBinding.yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-splunk-otel-collector
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: default-splunk-otel-collector
subjects:
- kind: ServiceAccount
  name: default-splunk-otel-collector
  namespace: default
---
# Source: splunk-otel-collector/templates/daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: default-splunk-otel-collector-agent
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        release: default
      annotations:
        checksum/config: 02cc42a814faa44ce25d6ede2fb23032bda87d1146e74979751c29788e270110
        kubectl.kubernetes.io/default-container: otel-collector
    spec:
      hostNetwork: true
      dnsPolicy: ClusterFirstWithHostNet
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
        
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        ports:
        - name: jaeger-grpc
          containerPort: 14250
          hostPort: 14250
          protocol: TCP
        - name: jaeger-thrift
          containerPort: 14268
          hostPort: 14268
          protocol: TCP
        - name: otlp
          containerPort: 4317
          hostPort: 4317
          protocol: TCP
        - name: otlp-http
          containerPort: 4318
          protocol: TCP
        - name: otlp-http-old
          containerPort: 55681
          protocol: TCP
        - name: sfx-forwarder
          containerPort: 9080
          hostPort: 9080
          protocol: TCP
        - name: signalfx
          containerPort: 9943
          hostPort: 9943
          protocol: TCP
        - name: zipkin
          containerPort: 9411
          hostPort: 9411
          protocol: TCP
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_NODE_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.hostIP
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
          # Env variables for host metrics receiver
          - name: HOST_PROC
            value: /hostfs/proc
          - name: HOST_SYS
            value: /hostfs/sys
          - name: HOST_ETC
            value: /hostfs/etc
          - name: HOST_VAR
            value: /hostfs/var
          - name: HOST_RUN
            value: /hostfs/run
          - name: HOST_DEV
            value: /hostfs/dev
          # until https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/5879
          # is resolved fall back to previous gopsutil mountinfo path:
          # https://github.com/shirou/gopsutil/issues/1271
          - name: HOST_PROC_MOUNTINFO
            value: /proc/self/mountinfo

        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: otel-configmap
        - mountPath: /hostfs/dev
          name: host-dev
          readOnly: true
        - mountPath: /hostfs/etc
          name: host-etc
          readOnly: true
        - mountPath: /hostfs/proc
          name: host-proc
          readOnly: true
        - mountPath: /hostfs/run/udev/data
          name: host-run-udev-data
          readOnly: true
        - mountPath: /hostfs/sys
          name: host-sys
          readOnly: true
        - mountPath: /hostfs/var/run/utmp
          name: host-var-run-utmp
          readOnly: true
      terminationGracePeriodSeconds: 600
      volumes:
      - name: host-dev
        hostPath:
          path: /dev
      - name: host-etc
        hostPath:
          path: /etc
      - name: host-proc
        hostPath:
          path: /proc
      - name: host-run-udev-data
        hostPath:
          path: /run/udev/data
      - name: host-sys
        hostPath:
          path: /sys
      - name: host-var-run-utmp
        hostPath:
          path: /var/run/utmp
      - name: otel-configmap
        configMap:
          name: default-splunk-otel-collector-otel-agent
          items:
            - key: relay
              path: relay.yaml
---
# Source: splunk-otel-collector/templates/deployment-cluster-receiver.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: default-splunk-otel-collector-k8s-cluster-receiver
  labels:
    app.kubernetes.io/name: splunk-otel-collector
    helm.sh/chart: splunk-otel-collector-0.70.0
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/instance: default
    app.kubernetes.io/version: "0.70.0"
    app: splunk-otel-collector
    component: otel-k8s-cluster-receiver
    chart: splunk-otel-collector-0.70.0
    release: default
    heritage: Helm
    app.kubernetes.io/component: otel-k8s-cluster-receiver
spec:
  replicas: 1
  selector:
    matchLabels:
      app: splunk-otel-collector
      component: otel-k8s-cluster-receiver
      release: default
  template:
    metadata:
      labels:
        app: splunk-otel-collector
        component: otel-k8s-cluster-receiver
        release: default
      annotations:
        checksum/config: 94371fe9c8062ad6c2eb9da843086ee092b3d1ddc2753b9f8198e6a422c5a20c
    spec:
      serviceAccountName: default-splunk-otel-collector
      nodeSelector:
          kubernetes.io/os: linux
      containers:
      - name: otel-collector
        command:
        - /otelcol
        - --config=/conf/relay.yaml
        image: quay.io/signalfx/splunk-otel-collector:0.70.0
        imagePullPolicy: IfNotPresent
        env:
          - name: SPLUNK_MEMORY_TOTAL_MIB
            value: "500"
          - name: K8S_NODE_NAME
            valueFrom:
              fieldRef:
                fieldPath: spec.nodeName
          - name: K8S_POD_IP
            valueFrom:
              fieldRef:
                apiVersion: v1
                fieldPath: status.podIP
          - name: K8S_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: K8S_POD_UID
            valueFrom:
              fieldRef:
                fieldPath: metadata.uid
          - name: K8S_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: SPLUNK_OBSERVABILITY_ACCESS_TOKEN
            valueFrom:
              secretKeyRef:
                name: splunk-otel-collector
                key: splunk_observability_access_token
        readinessProbe:
          httpGet:
            path: /
            port: 13133
        livenessProbe:
          httpGet:
            path: /
            port: 13133
        resources:
          limits:
            cpu: 200m
            memory: 500Mi
        volumeMounts:
        - mountPath: /conf
          name: collector-configmap
      terminationGracePeriodSeconds: 600
      volumes:
      - name: collector-configmap
        configMap:
          name: default-splunk-otel-collector-otel-k8s-cluster-receiver
          items:
            - key: relay
              path: relay.yaml

</code></pre>
</details>
  