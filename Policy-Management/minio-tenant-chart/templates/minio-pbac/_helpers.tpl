{{/*
Expand the name of the chart.
*/}}
{{- define "tenant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "tenant.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "tenant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tenant.labels" -}}
helm.sh/chart: {{ include "tenant.chart" . }}
{{ include "tenant.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tenant.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tenant.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Policy labels
*/}}
{{- define "tenant.policyLabels" -}}
{{ include "tenant.labels" . }}
app.kubernetes.io/component: policy-management
{{- end }}

{{/*
Service Account labels for a specific role
*/}}
{{- define "tenant.serviceAccountLabels" -}}
{{ include "tenant.labels" . }}
app.kubernetes.io/component: service-account
{{- end }}

{{/*
PolicyBinding labels for a specific role  
*/}}
{{- define "tenant.policyBindingLabels" -}}
{{ include "tenant.labels" . }}
app.kubernetes.io/component: policy-binding
{{- end }}

{{/*
Check if STS is available (operator has STS enabled)
*/}}
{{- define "tenant.stsEnabled" -}}
{{- if .Values.sts.enabled -}}
{{- $capabilities := .Capabilities.APIVersions -}}
{{- if $capabilities.Has "sts.min.io/v1alpha1" -}}
true
{{- else -}}
false
{{- end -}}
{{- else -}}
false
{{- end -}}
{{- end }}

{{/*
Generate policy JSON for a given role
*/}}
{{- define "tenant.policyJson" -}}
{{- $policy := . -}}
{
  "Version": "{{ $policy.policy.Version }}",
  "Statement": [
    {{- range $i, $stmt := $policy.policy.Statement }}
    {{- if $i }},{{ end }}
    {
      "Effect": "{{ $stmt.Effect }}",
      "Action": {{ $stmt.Action | toJson }},
      "Resource": {{ $stmt.Resource | toJson }}
      {{- if $stmt.Condition }},
      "Condition": {{ $stmt.Condition | toJson }}
      {{- end }}
    }
    {{- end }}
  ]
}
{{- end }}

{{/*
Generate service account name for a role
*/}}
{{- define "tenant.serviceAccountName" -}}
{{- if .serviceAccount.name -}}
{{- .serviceAccount.name }}
{{- else -}}
{{- printf "%s-%s-sa" (include "tenant.fullname" $.root) $.roleName }}
{{- end -}}
{{- end }}

{{/*
Generate policy binding name for a role
*/}}
{{- define "tenant.policyBindingName" -}}
{{- if .policyBinding.name -}}
{{- .policyBinding.name }}
{{- else -}}
{{- printf "%s-%s-binding" (include "tenant.fullname" $.root) $.roleName }}
{{- end -}}
{{- end }}

{{/*
Validate policy configuration
*/}}
{{- define "tenant.validatePolicy" -}}
{{- $policy := . -}}
{{- if not $policy.name -}}
{{- fail "Policy name is required" -}}
{{- end -}}
{{- if not $policy.policy -}}
{{- fail "Policy definition is required" -}}
{{- end -}}
{{- if not $policy.policy.Statement -}}
{{- fail "Policy must have at least one statement" -}}
{{- end -}}
{{- end }}

