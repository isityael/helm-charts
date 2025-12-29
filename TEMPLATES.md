# Helm Chart Templates Guide

This guide provides examples and best practices for creating Helm chart templates.

## Table of Contents

- [Basic Structure](#basic-structure)
- [Common Patterns](#common-patterns)
- [Template Functions](#template-functions)
- [Best Practices](#best-practices)

## Basic Structure

A typical Helm chart template uses the following structure:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "chart.selectorLabels" . | nindent 8 }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
```

## Common Patterns

### 1. Helper Templates (_helpers.tpl)

Define reusable templates in `templates/_helpers.tpl`:

```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### 2. Conditional Resources

Use `if` statements to conditionally include resources:

```yaml
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  # ... ingress spec ...
{{- end }}
```

### 3. Iterating Over Lists

Loop through lists with `range`:

```yaml
{{- range .Values.ingress.hosts }}
- host: {{ .host | quote }}
  http:
    paths:
    {{- range .paths }}
    - path: {{ .path }}
      pathType: {{ .pathType }}
      backend:
        service:
          name: {{ include "chart.fullname" $ }}
          port:
            number: {{ $.Values.service.port }}
    {{- end }}
{{- end }}
```

### 4. Environment Variables from ConfigMap/Secret

```yaml
envFrom:
{{- if .Values.configMap.enabled }}
- configMapRef:
    name: {{ include "chart.fullname" . }}-config
{{- end }}
{{- if .Values.secret.enabled }}
- secretRef:
    name: {{ include "chart.fullname" . }}-secret
{{- end }}
```

### 5. Resource Limits and Requests

```yaml
resources:
  {{- toYaml .Values.resources | nindent 10 }}
```

With values:
```yaml
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### 6. Probes

```yaml
livenessProbe:
  httpGet:
    path: {{ .Values.livenessProbe.path | default "/" }}
    port: http
  initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds | default 30 }}
  periodSeconds: {{ .Values.livenessProbe.periodSeconds | default 10 }}
readinessProbe:
  httpGet:
    path: {{ .Values.readinessProbe.path | default "/" }}
    port: http
  initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds | default 5 }}
  periodSeconds: {{ .Values.readinessProbe.periodSeconds | default 10 }}
```

### 7. Volumes and Volume Mounts

```yaml
volumes:
{{- if .Values.persistence.enabled }}
- name: data
  persistentVolumeClaim:
    claimName: {{ include "chart.fullname" . }}
{{- end }}
{{- if .Values.configMap.enabled }}
- name: config
  configMap:
    name: {{ include "chart.fullname" . }}-config
{{- end }}

volumeMounts:
{{- if .Values.persistence.enabled }}
- name: data
  mountPath: {{ .Values.persistence.mountPath }}
{{- end }}
{{- if .Values.configMap.enabled }}
- name: config
  mountPath: /etc/config
  readOnly: true
{{- end }}
```

## Template Functions

### String Functions

```yaml
# Convert to upper/lower case
{{ .Values.name | upper }}
{{ .Values.name | lower }}

# Trim whitespace
{{ .Values.name | trim }}

# Quote strings
{{ .Values.name | quote }}

# Truncate and trim suffix
{{ .Values.name | trunc 63 | trimSuffix "-" }}

# Default value
{{ .Values.name | default "default-name" }}
```

### Encoding Functions

```yaml
# Base64 encode
{{ .Values.password | b64enc }}

# Base64 decode
{{ .Values.encodedPassword | b64dec }}
```

### Type Conversion

```yaml
# Convert to integer
{{ .Values.port | int }}

# Convert to string
{{ .Values.replicas | toString }}
```

### Date Functions

```yaml
# Current date
{{ now | date "2006-01-02" }}

# Unix timestamp
{{ now | unixEpoch }}
```

### Cryptographic Functions

```yaml
# Generate random string
{{ randAlphaNum 10 }}

# SHA256 hash
{{ .Values.data | sha256sum }}
```

## Best Practices

### 1. Use Proper Indentation

```yaml
# Correct
labels:
  {{- include "chart.labels" . | nindent 4 }}

# Correct - with proper spacing
{{- with .Values.annotations }}
annotations:
  {{- toYaml . | nindent 4 }}
{{- end }}
```

### 2. Validate Required Values

```yaml
{{- if not .Values.required.value }}
{{- fail "required.value is required!" }}
{{- end }}
```

### 3. Use Range for Multiple Items

```yaml
{{- range $key, $value := .Values.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
```

### 4. Handle Empty Values

```yaml
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 8 }}
{{- end }}
```

### 5. Escape Special Characters

```yaml
# Use quote for strings with special characters
annotation: {{ .Values.text | quote }}
```

### 6. Template Comments

```yaml
{{/*
This is a comment that won't appear in the output.
Use this for documentation.
*/}}
```

### 7. Debug Output

```yaml
# Show values during dry-run
{{- toYaml .Values | nindent 0 }}
```

## Testing Templates

### 1. Dry Run

```bash
helm install test ./chart --dry-run --debug
```

### 2. Template Command

```bash
helm template test ./chart
```

### 3. Lint

```bash
helm lint ./chart
```

### 4. Test with Custom Values

```bash
helm template test ./chart -f custom-values.yaml
```

### 5. Test Specific Templates

```bash
helm template test ./chart -s templates/deployment.yaml
```

## Common Mistakes to Avoid

1. **Incorrect Indentation**: Use `nindent` instead of `indent` for YAML
2. **Missing Quotes**: Always quote strings in annotations and labels
3. **Not Handling Empty Values**: Use `with` or `if` for optional values
4. **Hardcoded Values**: Use `.Values` for all configurable options
5. **Missing Required Values**: Add validation for required fields
6. **Long Resource Names**: Use `trunc 63` to limit name length
7. **Not Using Helpers**: Create reusable helper templates

## Resources

- [Helm Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Go Template Documentation](https://pkg.go.dev/text/template)
- [Sprig Function Documentation](http://masterminds.github.io/sprig/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

## Example: Complete Deployment Template

See the [example-app chart](charts/example-app/templates/deployment.yaml) for a complete, production-ready example.
