{{- define "serviceAccountTemplate" }}
{{- if .Values.serviceAccount.create }}
apiVersion: v1
{{- if .Values.image.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.image.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
kind: ServiceAccount
metadata:
  labels:
    {{- include "splunk-otel-collector.commonLabels" . | nindent 4 }}
    app: {{ template "splunk-otel-collector.name" . }}
    chart: {{ template "splunk-otel-collector.chart" . }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
  {{- if .Values.serviceAccount.annotations }}
  annotations:
    {{- toYaml .Values.serviceAccount.annotations | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}
