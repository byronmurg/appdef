{{/*
 * Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
*/}}

{{- define "container_resources" }}
{{/*
A generic resource definition for containers
*/}}
resources {
  limits = { cpu = "1", memory = "1Gi" }
  requests = {
    cpu    = var.DEV_MODE ? "50m" : "200m",
    memory = var.DEV_MODE ? "128Mi" : "256Mi"
  }
}
{{- end }}

terraform {
  required_version = "> 1.1.0"

  backend "gcs" {
    //@NOTE partial configuration
    prefix = "deployment-{{ $.Spec.Name }}"
  }

  required_providers {
    {{- if eq $.Spec.SecretSource "doppler" }}
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.1.1"
    }
    {{- end }}

    google = {
      source  = "hashicorp/google"
      version = ">= 4.21.0"
    }
  }
}

provider "google" {
  project = var.PROJECT_ID
}

locals {
  deployment_name = "{{ $.Spec.Name }}-${terraform.workspace}"
}

variable "PROJECT_ID" {
  type        = string
  description = "gcp project to deploy to"
}

variable "BASE_DOMAIN" {
  type        = string
  description = "domain suffix to attach to fqdn"
}

variable "DNS_ZONE" {
  type        = string
  description = "dns zone to use for A records"
}

variable "REGION" {
  type        = string
  description = "gcp region to deploy application"
}

variable "LIVE_TAG" {
  type        = string
  description = "tag to default to if the spec .tag is not present. Normally used by ci."
}

variable "INTERNAL_IMAGE_REPO" {
  type        = string
  description = "docker repo where app/cron/startup images are stored"
}

variable "DEV_MODE" {
  type        = bool
  default     = false
  description = "enables developer tools at the expense of security"
}

variable "HA" {
  type        = bool
  default     = true
  description = "enables ha mode on all components at the expense of cost"
}

variable "ALLOWED_GROUPS" {
  type = set(string)
}

variable "IAP_CLIENT_ID" {
  type = string
}

variable "IAP_CLIENT_SECRET" {
  type      = string
  sensitive = true
}

{{- if eq $.Spec.SecretSource "doppler" }}

variable "DOPPLER_TOKEN" {
  type = string
}

provider "doppler" {
  doppler_token = var.DOPPLER_TOKEN
}

data "doppler_secrets" "this" {}

locals {
  secrets = data.doppler_secrets.this.map
}

{{- else if eq $.Spec.SecretSource "gcp" }}

variable "GCP_SECRET_PREFIX" {
  type = string
  default = ""
}

{{- else }}{{/* else default secret-source */}}

variable "SECRETS" {
  type    = map(string)
  default = {}
}

locals {
  secrets = var.SECRETS
}

{{- end }}{{/* end secret-source */}}


locals {
  external_route_map = {
    {{- range $appName, $app := $.Spec.ExposedApps }}

    {{- if eq $app.Subdomain "" }}
    {{ $appName | quote }} = "https://${var.BASE_DOMAIN}{{ $app.Path }}"
    {{- else }}
    {{ $appName | quote }} = "https://${var.BASE_DOMAIN}{{ $app.Path }}"

    {{- end }}

    {{- end }}{{/* end range apps */}}
  }
}

{{ range $appName, $app := $.Spec.Apps }}

//
// Application {{ $appName }}
//

resource "google_service_account" "app-{{$appName}}" {
  account_id   = "app-{{$appName}}-service-account"
  display_name = "Service account for app-{{$appName}}"
}

{{- if eq $.Spec.SecretSource "gcp" }}
{{- range $secret := $app.Secrets }}
resource "google_secret_manager_secret_iam_member" "{{$appName}}-{{$secret.Var}}-secret-access" {
  secret_id = "{{$secret.Var}}"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.app-{{$appName}}.email}"
}
{{- end }}
{{- end }}


resource "google_cloud_run_service" "app-{{ $appName }}" {
  name     = "app-{{ $appName }}"
  location = var.REGION
  project  = var.PROJECT_ID

  template {

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = "8"
        "autoscaling.knative.dev/minScale"  = "1"
        "run.googleapis.com/client-name"    = "terraform"
        #"run.googleapis.com/cpu-throttling" = "false" # always on https://cloud.google.com/run/docs/configuring/cpu-allocation
      }
    }

    spec {
      service_account_name = google_service_account.app-{{$appName}}.email

      containers {
        image = "${var.INTERNAL_IMAGE_REPO}/{{ $app.Image }}:${var.LIVE_TAG}"

        {{- if eq $.Spec.SecretSource "gcp" }}
        {{- range $secret := $app.Secrets }}
        env {
          name = {{ quote $secret.Var}}
          # {{ $secret.Description }}
          value_from {
            secret_key_ref {
              name = "${var.GCP_SECRET_PREFIX}{{ $secret.Var }}"
              key = "latest"
            }
          }
        }
        {{- end }}
        {{- end }}

        {{- with $app.Port }}
        ports {
          container_port = {{.}}
        }
        {{- else }}
        ports {
          container_port = 8080
        }
        {{- end }}

        {{ include "container_resources" $app | nindent 8 }}

        env {
          name  = "NODE_ENV"
          value = var.DEV_MODE ? "development" : "production"
        }

        env {
          name = "EXT_ROUTE_MAP"
          value = jsonencode(local.external_route_map)
        }

        {{- with $app.Path }}
        env {
          name  = "MOUNT_PATH"
          value = "{{.}}"
        }

        env {
          name  = "APP_URL"
          {{- if $app.Subdomain }}
          value = "https://{{ $app.Subdomain }}.${var.BASE_DOMAIN}{{.}}"
          {{- else }}
          value = "https://${var.BASE_DOMAIN}{{.}}"
          {{- end }}
        }
        {{- end }}
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "app-{{$appName}}-neg" {
  provider              = google
  name                  = "{{$appName}}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.REGION

  cloud_run {
    service = google_cloud_run_service.app-{{$appName}}.name
  }
}

{{- end }} {{/* end range Apps */}}

resource "google_compute_url_map" "urlmap" {
  name = local.deployment_name

  description = "main {{ $.Spec.Name }} url map"

  {{- range $appName, $app := $.Spec.ExposedApps }}
  {{- if and (eq $app.Subdomain "") (eq $app.Path "/") }}
  default_service = module.lb-http-app.backend_services["{{$appName}}"].self_link
  {{- end }}
  {{- end }}

  {{- range $subdomain := $.Subdomains }}
  host_rule {
    {{ if eq $subdomain "" }}
    hosts        = [var.BASE_DOMAIN]
    path_matcher = "default" {{/* @TODO what if it's actually "default" */}}
    {{- else }}
    hosts        = ["{{$subdomain }}.${var.BASE_DOMAIN}"]
    path_matcher = {{ quote $subdomain }}
    {{- end }}
  }
  {{- end }}

  {{- range $subdomain := $.Subdomains }}
  path_matcher {
    {{ if eq $subdomain "" }}
    name = "default" {{/* @TODO what if it's actually "default" */}}
    {{- else }}
    name = {{ quote $subdomain }}
    {{- end }}

    {{- range $appName, $app := $.Spec.ExposedApps }}
    {{- if eq $app.Subdomain $subdomain }}

    {{- if eq $app.Path "/" }}
    default_service = module.lb-http-app.backend_services["{{$appName}}"].self_link
    {{- else }}
    path_rule {
      paths = ["{{$app.Path }}/*"]
      service = module.lb-http-app.backend_services["{{$appName}}"].self_link
    }
    {{- end }}{{/* end neq .Path "" */}}

    {{- end }}{{/* end eq $subdomain $app.Subdomain */}}
    {{- end }}{{/* end range $.Spec.Apps */}}
  }
  {{- end }}{{/* end range $.Subdomains */}}
}

module "lb-http-app" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "6.2.0"

  project = var.PROJECT_ID
  name    = local.deployment_name

  ssl = true

  managed_ssl_certificate_domains = [
    {{- range $subdomain := $.Subdomains }}
    {{- if eq $subdomain "" }}
    var.BASE_DOMAIN,
    {{- else }}
    "{{$subdomain}}.${var.BASE_DOMAIN}",
    {{- end }}{{/* end eq "" */}}
    {{- end }}{{/* end range $.Subdomains */}}
  ]

  https_redirect = true

  create_url_map = false

  url_map = google_compute_url_map.urlmap.id

  backends = {
    {{- range $appName, $app := $.Spec.ExposedApps }}
    {{$appName}} = {
      description = null
      {{- with $app.Port }}
      port        = {{ $app.Port }}
      {{- else }}
      port        = 8080
      {{- end }}
      groups = [
        {
          group = google_compute_region_network_endpoint_group.app-{{$appName}}-neg.id
        },
      ]
      enable_cdn              = false
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      iap_config = {
        enable               = true
        oauth2_client_id     = var.IAP_CLIENT_ID
        oauth2_client_secret = var.IAP_CLIENT_SECRET
      }
      log_config = {
        enable      = false
        sample_rate = null
      }
    }
    {{- end }}
  }
}


{{ range $subdomain := $.Subdomains }}

resource "google_dns_record_set" "app-{{$subdomain}}" {
  // @TODO ipv6
  managed_zone = var.DNS_ZONE

  {{ if eq $subdomain "" }}
  name    = "${var.BASE_DOMAIN}."
  {{- else }}
  name    = "{{$subdomain}}.${var.BASE_DOMAIN}."
  {{- end }}
  type    = "A"
  ttl     = 300
  rrdatas = [module.lb-http-app.external_ip]
}

{{- end }}

data "google_iam_policy" "iap" {
  binding {
    role    = "roles/iap.httpsResourceAccessor"
    members = var.ALLOWED_GROUPS
  }
}

{{- range $appName, $app := $.Spec.Apps }}
resource "google_iap_web_backend_service_iam_policy" "policy-{{$appName}}" {
  project             = var.PROJECT_ID
  web_backend_service = "${local.deployment_name}-backend-{{$appName}}"
  policy_data         = data.google_iam_policy.iap.policy_data
  depends_on = [
    module.lb-http-app
  ]
}
{{- end }}
