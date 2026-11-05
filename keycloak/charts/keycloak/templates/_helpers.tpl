{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "keycloak.fullname" -}}
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
Chart and version labels.
*/}}
{{- define "keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "keycloak.labels" -}}
helm.sh/chart: {{ include "keycloak.chart" . }}
{{ include "keycloak.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ include "keycloak.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "keycloak.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "keycloak.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Secret name for admin and database credentials
*/}}
{{- define "keycloak.secretName" -}}
{{- if .Values.auth.existingSecret }}
{{- .Values.auth.existingSecret }}
{{- else }}
{{- include "keycloak.fullname" . }}
{{- end }}
{{- end }}

{{/*
Database password secret name
*/}}
{{- define "keycloak.dbSecretName" -}}
{{- if .Values.database.existingSecret }}
{{- .Values.database.existingSecret }}
{{- else }}
{{- include "keycloak.secretName" . }}
{{- end }}
{{- end }}

{{/*
Database password secret key
*/}}
{{- define "keycloak.dbPasswordKey" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecretKey -}}
{{- else -}}
KC_DB_PASSWORD
{{- end -}}
{{- end }}

{{/*
ConfigMap name created for realmImport.files
*/}}
{{- define "keycloak.realmImportConfigMapName" -}}
{{- printf "%s-realm-import" (include "keycloak.fullname" .) }}
{{- end }}

{{/*
Name of the ConfigMap or Secret mounted for realm import
*/}}
{{- define "keycloak.realmImportSourceName" -}}
{{- if .Values.realmImport.existingSecret -}}
{{- .Values.realmImport.existingSecret -}}
{{- else if .Values.realmImport.existingConfigMap -}}
{{- .Values.realmImport.existingConfigMap -}}
{{- else -}}
{{- include "keycloak.realmImportConfigMapName" . -}}
{{- end -}}
{{- end }}
