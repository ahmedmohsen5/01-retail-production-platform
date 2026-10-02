{{- define "retail.labels" -}}
app.kubernetes.io/name: {{ .serviceName | quote }}
app.kubernetes.io/part-of: retail-store
app.kubernetes.io/managed-by: {{ .root.Release.Service | quote }}
helm.sh/chart: {{ printf "%s-%s" .root.Chart.Name .root.Chart.Version | quote }}
{{- end -}}
