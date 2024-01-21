{{/*
 * Copyright (C) Byron Murgatroyd - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Byron Murgatroyd <byron.murgatroyd@appdef.io>, 2022
*/}}

{{- define "init_containers" }}
{{/*
This implements the generic init_containers to
wait for database services
*/}}
{{- if .Mongo.Use }}
init_container {
  name  = "init-mongodb"
  image = "${var.EXTERNAL_IMAGE_REPO}/busybox:${local.external_versions.busybox_image}"
  command = ["sh", "-c", <<-EOF
     %{if var.HA}
     mongo_host="${local.deployment_name}-db-mongo-{{.Mongo.Db}}-mongodb-headless"
     %{else}
     mongo_host="${local.deployment_name}-db-mongo-mongodb"
     %{endif}
     until nslookup $mongo_host; do
       echo waiting for mongo;
       sleep 2;
     done
     EOF
  ]
}
{{- end }}

{{- if .S3.Use }}
init_container {
  name  = "init-minio"
  image = "${var.EXTERNAL_IMAGE_REPO}/busybox:${local.external_versions.busybox_image}"
  command = ["sh", "-c", <<-EOF
     %{if var.HA}
     minio_host="${local.deployment_name}-db-minio-{{.S3.Db}}"
     %{else}
     minio_host="${local.deployment_name}-db-minio"
     %{endif}
     until nslookup $minio_host; do
       echo waiting for minio;
       sleep 2;
     done
     EOF
  ]
}
{{- end }}

{{- if .Postgresql.Use }}
init_container {
  name  = "init-pg"
  image = "${var.EXTERNAL_IMAGE_REPO}/busybox:${local.external_versions.busybox_image}"
  command = ["sh", "-c", <<-EOF
     %{if var.HA}
     pg_host="${local.deployment_name}-db-pg-{{.Postgresql.Db}}-pgpool"
     %{else}
     pg_host="${local.deployment_name}-db-pg-postgresql"
     %{endif}
     until nslookup $pg_host; do
       echo waiting for postgres;
       sleep 2;
     done
     EOF
  ]
}
{{- end }}


{{- end }}{{/* end define init_containers */}}

{{- define "image" }}
{{- if .Tag }}
image = "${var.INTERNAL_IMAGE_REPO}/{{ .Image }}:{{ .Tag }}"
{{- else }}
image = "${var.INTERNAL_IMAGE_REPO}/{{ .Image }}:${var.LIVE_TAG}"
{{- end }}
{{- end }} {{/* end define image */}}

{{- define "container_security_context" }}
{{/*
This is a re-usable security_context for our containers
*/}}
security_context {
  {{- if .User }}
  run_as_non_root            = true
  run_as_user                = {{ .User }}
  {{- end }}
  {{- if .ReadOnly}}
  read_only_root_filesystem  = true
  {{- end }}

  allow_privilege_escalation = false
  privileged                 = false
}
{{- end }}

{{- define "container_resources" }}
{{/*
A generic resource definition for containers
*/}}
resources {
  limits   = { cpu = "1", memory = "4Gi" }
  requests = {
    cpu    = var.DEV_MODE ? "50m"  : "200m",
    memory = var.DEV_MODE ? "128Mi" : "256Mi"
  }
}
{{- end }}

terraform {
  required_version = "> 1.1.0"

  backend "kubernetes" {
    secret_suffix = "{{ $.Spec.Name }}-state"
    namespace     = "kube-system"
  }

  required_providers {
    {{- if eq $.Spec.SecretSource "doppler" }}
    doppler = {
      source  = "DopplerHQ/doppler"
      version = "1.1.1"
    }
    {{- end }}
    {{- if eq $.Spec.SecretSource "gcp" }}
    google = {
      source = "hashicorp/google"
      version = ">= 4.21.0"
    }
    {{- end }}
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.2.0"
    }
  }
}

# Initialise helm provider using local configuration
provider "helm" {}

# Initialise kubernetes provider using local configuration
provider "kubernetes" {}

locals {
  # This is the unique name of our deployment
  deployment_name = "{{ $.Spec.Name }}-${terraform.workspace}"

  # These are the external component versions that need
  # to be updated periodically.

  external_versions = {
    # https://github.com/bitnami/charts/tree/master/bitnami/mongodb
    mongodb_chart = "11.1.7"

    # https://github.com/bitnami/charts/tree/master/bitnami/minio
    minio_chart = "11.3.1"

    # https://github.com/bitnami/charts/tree/master/bitnami/postgresql-ha
    postgresql_ha_chart = "9.0.5"

    # https://github.com/bitnami/charts/tree/master/bitnami/postgresql
    postgresql_chart = "11.1.27"

    # https://hub.docker.com/_/busybox
    busybox_image = "1.28"
  }
}

##########################################
# Global variables
#
# These are variables used globaly
# throughout deployment of the application
##########################################

variable "BASE_DOMAIN" {
  type        = string
  description = "domain suffix to attach to fqdn"
}

variable "LIVE_TAG" {
  type        = string
  description = "tag to default to if the spec .tag is not present. Normally used by ci."
}

variable "INTERNAL_IMAGE_REPO" {
  type        = string
  description = "docker repo where app/cron/startup images are stored"
}

variable "EXTERNAL_IMAGE_REPO" {
  type        = string
  default     = "docker.io"
  description = "docker repo where database images are stored"
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


##########################################
# External secrets
#
# We may need to load external secrets
# depending on the deployment scenario
##########################################

{{- if eq $.Spec.SecretSource "doppler" }}

# The doppler token needs to be provided
# in order to load the secrets

variable "DOPPLER_TOKEN" {
  type = string
  sensitive = true
}

provider "doppler" {
  doppler_token = var.DOPPLER_TOKEN
}

data "doppler_secrets" "this" {}

locals {
  secrets = data.doppler_secrets.this.map
}

{{- else if eq $.Spec.SecretSource "gcp" }}

variable "GCP_SECRET_MANAGER_PROJECT" {
  type = string
}

// We assume either local setup or partial-configuration for this provider
provider "google" {}

data "google_secret_manager_secret_version" "gcp_secrets" {
  for_each = toset({{ toTf $.SecretList }})
  secret = each.value
  project = var.GCP_SECRET_MANAGER_PROJECT
}

locals {
  secrets = {
    for key, res in data.google_secret_manager_secret_version.gcp_secrets:
      key => res.secret_data
  }
}

{{- else }}{{/* else default secret-source */}}

# Secrets need to be passed to terraform as
# a map

variable "SECRETS" {
  type = map(string)
  default = {}
  sensitive = true
}

locals {
  secrets = var.SECRETS
}

{{- end }}{{/* end secret-source */}}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = local.deployment_name
  }
}

locals {
  ns        = kubernetes_namespace.ns
  namespace = kubernetes_namespace.ns.metadata[0].name
}


{{- if $.Spec.Mongo.Enabled }}

##############################################################
# Mongo Standalone
#
# In non-HA deployments we enable a standalone mongo instance
# hosting all logical databases: ({{ $.Spec.Mongo.DbNames | join ", " }})
##############################################################

resource "random_password" "mongo_dev_password" {
  length  = 16
  special = false
}

resource "random_password" "mongo_root_password" {
  length  = 16
  special = false
}

resource "random_password" "mongo_rs_key" {
  length  = 16
  special = false
}

resource "helm_release" "mongo-dev" {
  count = (!var.HA) ? 1 : 0

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"

  name      = "${local.deployment_name}-db-mongo"
  namespace = local.namespace
  version   = local.external_versions.mongodb_chart

  set {
    name  = "architecture"
    value = "standalone"
  }

  values = [
    yamlencode({
      global = {
        imageRegistry = var.EXTERNAL_IMAGE_REPO
      }
      commonLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "mongo"
      })
      metrics = {
        enabled = true
      }
      persistence = {
        size = var.DEV_MODE ? "8Gi" : "64Gi"
      }
      auth = {
        enabled      = false
        databases    = {{ toTf $.Spec.Mongo.DbNames }}

        usernames    = ["db-user"]
        passwords    = [random_password.mongo_dev_password.result]
        rootPassword = random_password.mongo_root_password.result
      }
    })
  ]

}

##############################################################
# Mongo HA
#
# With HA switched on we create a mongo replicaset for each
# logical database.
##############################################################

resource "random_password" "mongo_prod_password" {
  for_each = toset({{ toTf $.Spec.Mongo.DbNames }})
  length   = 16
  special  = false
}

resource "kubernetes_network_policy_v1" "mongo-db-policy" {
  for_each = var.HA ? toset({{ toTf $.Spec.Mongo.DbNames }}) : []
  metadata {
    name      = "${local.deployment_name}-db-mongo-policy-${each.value}"
    namespace = local.namespace
    labels    = local.component_common_labels
  }

  spec {
    pod_selector {
      match_labels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "mongo-${each.value}"
      })
    }
    policy_types = ["Egress"]

    egress {
      to {
        # Allow mongos to connect to each other
        pod_selector {
          match_labels = merge(local.db_common_labels, {
            "appdef.io/component-name" = "mongo-${each.value}"
          })
        }
      }
    }
  }
}


resource "helm_release" "mongo-prod" {
  for_each = var.HA ? toset({{ toTf $.Spec.Mongo.DbNames }}) : []
  depends_on = [kubernetes_network_policy_v1.mongo-db-policy]

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"

  name      = "${local.deployment_name}-db-mongo-${each.value}"
  namespace = local.namespace
  version   = local.external_versions.mongodb_chart

  wait = false # This can take a long time to come up

  set {
    name  = "architecture"
    value = "replicaset"
  }

  values = [
    yamlencode({
      replicaCount = 3
      global = {
        imageRegistry = var.EXTERNAL_IMAGE_REPO
      }
      commonLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "mongo-${each.value}"
      })
      podLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "mongo-${each.value}"
      })
      arbiter = {
        podLabels = merge(local.db_common_labels, {
          "appdef.io/component-name" = "mongo-${each.value}"
        })
      }
      metrics = {
        enabled = true
      }
      persistence = {
        size = var.DEV_MODE ? "8Gi" : "64Gi"
      }
      auth = {
        enabled       = true
        databases     = [each.value]
        usernames     = ["db-user"]
        passwords     = [random_password.mongo_prod_password[each.value].result]
        rootPassword  = random_password.mongo_root_password.result
        replicaSetKey = random_password.mongo_rs_key.result
      }
    })
  ]
}


{{- end }}{{/* end mongo enabled */}}



{{- if $.Spec.Postgresql.Enabled }}


{{- range $entry := $.ContainerList }}
{{- if $entry.Container.Postgresql.Use }}
resource "random_password" "postgresql-secret-{{$entry.Fullname}}" {
  # This is the postgresql password for {{$entry.Fullname}}
  length   = 16
  special  = false
}
{{- end }}
{{- end }}

{{- range $db := $.Spec.Postgresql.DbNames }}

##############################################################
# Postgresql HA {{$db}} database
#
# In HA mode we create a postgresql pool and pgpool request
# balancer for this database.
##############################################################

resource "random_password" "postgresql-root-{{$db}}" {
  # This is the root postgresql password for {{$db}}
  length   = 16
  special  = false
}

resource "random_password" "postgresql-repmgr-{{$db}}" {
  # This is the postgresql repmgr password for {{$db}}
  length   = 16
  special  = false
}

resource "random_password" "postgresql-admin-{{$db}}" {
  # This is the postgresql pgpool admin password for {{$db}}
  length   = 16
  special  = false
}

resource "kubernetes_network_policy_v1" "pg-db-policy-{{$db}}" {
  count = var.HA ? 1 : 0
  metadata {
    name      = "${local.deployment_name}-db-pg-policy-{{$db}}"
    namespace = local.namespace
    labels = merge(local.db_common_labels, {
      "appdef.io/component-name" = "postgresql-{{$db}}"
    })
  }

  spec {
    pod_selector {
      match_labels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "postgresql-{{$db}}"
      })
    }
    policy_types = ["Egress"]

    egress {
      to {
        # Allow pods for this postgresql instance to connect to each other
        pod_selector {
          match_labels = merge(local.db_common_labels, {
            "appdef.io/component-name" = "postgresql-{{$db}}"
          })
        }
      }
    }
  }
}

resource "kubernetes_secret_v1" "postgresql-ha-{{$db}}-initdb" {
  count = var.HA ? 1 : 0
  metadata {
    name      = "${local.deployment_name}-db-pg-{{$db}}-initdb"
    namespace = local.namespace
    labels = merge(local.db_common_labels, {
      "appdef.io/component-name" = "postgresql-{{$db}}"
    })
  }

  data = {
    "10-create-db-{{$db}}.sh" = <<-EOF
    PGUSER=postgres PGPASSWORD=$POSTGRESQL_INITSCRIPTS_PASSWORD psql -c 'create database {{$db}}' || true
    EOF

    "20-init.sql" = <<-EOF
    REVOKE CONNECT ON DATABASE {{$db}} FROM PUBLIC;

    \c {{$db}}
    REVOKE ALL ON SCHEMA public FROM PUBLIC;
    REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC ;

    {{- range $entry := $.ContainerList }}
    {{- if eq $entry.Container.Postgresql.Db $db }}
    DO
    $$
    BEGIN
       IF EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = '{{$entry.Fullname}}') THEN

          RAISE NOTICE 'Role "{{$entry.Fullname}}" already exists. Skipping.';
       ELSE
          CREATE ROLE "{{$entry.Fullname}}" LOGIN PASSWORD '${random_password.postgresql-secret-{{$entry.Fullname}}.result}';
          GRANT  CONNECT ON DATABASE {{$db}} TO "{{$entry.Fullname}}";
          GRANT  USAGE   ON SCHEMA public TO "{{$entry.Fullname}}";
          {{- if $entry.Container.Postgresql.Priviledged }}
          GRANT ALL ON DATABASE "{{$db}}" TO "{{$entry.Fullname}}";
          {{- else }}
          ALTER DEFAULT PRIVILEGES GRANT SELECT, UPDATE, DELETE, INSERT ON TABLES TO "{{$entry.Fullname}}";
          {{- end }}

       END IF;
    END
    $$;
    {{- end }}{{/* end if Db eq */}}
    {{- end }}{{/* end range ContainerList */}}
    EOF
  }
}

resource "helm_release" "postgresql-ha-{{$db}}" {
  count = var.HA ? 1 : 0
  depends_on = [kubernetes_network_policy_v1.pg-db-policy-{{$db}}]

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql-ha"

  name      = "${local.deployment_name}-{{$db}}"
  namespace = local.namespace
  version   = local.external_versions.postgresql_ha_chart

  wait = false # This can take a long time to come up

  values = [
    yamlencode({
      // We override the name as it can get a bit long otherwise
      fullnameOverride = "${local.deployment_name}-db-pg-{{$db}}",
      global = {
        imageRegistry = var.EXTERNAL_IMAGE_REPO
        postgresql = {
          password = random_password.postgresql-root-{{$db}}.result
          repmgrPassword = random_password.postgresql-root-{{$db}}.result
        }
      }
      pgpool = {
        adminPassword = random_password.postgresql-admin-{{$db}}.result
      }
      commonLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "postgresql-{{$db}}"
      })
      metrics = {
        enabled = true
      }
      persistence = {
        size = var.DEV_MODE ? "8Gi" : "64Gi"
      }
      postgresql = {
        password = random_password.postgresql-root-{{$db}}.result
        repmgrPassword = random_password.postgresql-root-{{$db}}.result

        podLabels = merge(local.db_common_labels, {
          "appdef.io/component-name" = "postgresql-{{$db}}"
        })

        initdbScriptsSecret = kubernetes_secret_v1.postgresql-ha-{{$db}}-initdb[count.index].metadata[0].name
      }
    })
  ]
}

{{- end }}

##############################################################
# Standalone Postgresql DB
#
# In standalone (non-HA) mode we create one postgresql
# instance and create each logical database within it.
##############################################################

resource "random_password" "postgresql-standalone-root" {
  # This is the standalone root postgresql password
  length   = 16
  special  = false
}

resource "kubernetes_secret_v1" "postgresql-standalone-initdb" {
  count = var.HA ? 0 : 1
  metadata {
    name      = "${local.deployment_name}-db-pg-initdb"
    namespace = local.namespace
    labels = merge(local.db_common_labels, {
      "appdef.io/component-name" = "postgresql"
    })
  }

  data = {
    {{ range $db := $.Spec.Postgresql.DbNames }}
    "10-create-db-{{$db}}.sh" = <<-EOF
      PGUSER=postgres PGPASSWORD=$POSTGRESQL_INITSCRIPTS_PASSWORD psql -c 'create database {{$db}}' || true
      EOF
    {{- end }}

    "20-init.sql" = <<-EOF
      {{ range $db := $.Spec.Postgresql.DbNames }}

      \c {{$db}}
      REVOKE CONNECT ON DATABASE {{$db}} FROM PUBLIC;
      REVOKE ALL ON SCHEMA public FROM PUBLIC;
      REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC ;

      {{- range $entry := $.ContainerList }}
      {{- if eq $entry.Container.Postgresql.Db $db }}
      DO
      $$
      BEGIN
         IF EXISTS (
            SELECT FROM pg_catalog.pg_roles
            WHERE  rolname = '{{$entry.Fullname}}') THEN

            RAISE NOTICE 'Role "{{$entry.Fullname}}" already exists. Skipping.';
         ELSE
            CREATE ROLE "{{$entry.Fullname}}" LOGIN PASSWORD '${random_password.postgresql-secret-{{$entry.Fullname}}.result}';
            GRANT  CONNECT ON DATABASE {{$db}} TO "{{$entry.Fullname}}";
            GRANT  USAGE   ON SCHEMA public TO "{{$entry.Fullname}}";

            {{- if $entry.Container.Postgresql.Priviledged }}
            GRANT ALL ON DATABASE "{{$db}}" TO "{{$entry.Fullname}}";
            {{- else }}
            ALTER DEFAULT PRIVILEGES GRANT SELECT, UPDATE, DELETE, INSERT ON TABLES TO "{{$entry.Fullname}}";
            {{- end }}

         END IF;
      END
      $$;
      {{- end }}{{/* end id Db eq */}}
      {{- end }}{{/* end range ContainerList */}}
      {{- end }}
      EOF
  }
}

resource "helm_release" "postgresql-standalone" {
  count = var.HA ? 0 : 1

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  name      = "${local.deployment_name}-db-pg"
  namespace = local.namespace
  version   = local.external_versions.postgresql_chart

  wait = false # This can take a long time to come up

  values = [
    yamlencode({
      global = {
        imageRegistry = var.EXTERNAL_IMAGE_REPO
        postgresql = {
          auth = {
            postgresPassword = random_password.postgresql-standalone-root.result
          }
        }
      }
      commonLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "postgresql"
      })
      primary = {
        persistence = {
          size = var.DEV_MODE ? "8Gi" : "64Gi"
        }
        podLabels = merge(local.db_common_labels, {
          "appdef.io/component-name" = "postgresql"
        })
        initdb = {
          password = random_password.postgresql-standalone-root.result
          user = "postgres"
          scriptsSecret = kubernetes_secret_v1.postgresql-standalone-initdb[count.index].metadata[0].name
        }
      }
      readReplicas = {
        replicaCount = 0 # We don't need replicas for standalone mode
      }
    })
  ]
}
{{- end }}


{{- if $.Spec.S3.Enabled }}

resource "random_password" "minio_standalone_admin_password" {
  length  = 16
  special = false
}

resource "random_password" "minio_passwords" {
  # This creates a random password for each bucket
  for_each = toset({{ toTf $.Spec.S3.DbNames }})
  length   = 16
  special  = false
}

resource "helm_release" "minio_standalone" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "minio"

  count = var.HA ? 0 : 1

  name      = "${local.deployment_name}-db-minio"
  namespace = local.namespace
  version   = local.external_versions.minio_chart

  set {
    name  = "mode"
    value = "standalone"
  }

  set {
    name  = "auth.rootPassword"
    value = random_password.minio_standalone_admin_password.result
  }

  set {
    name  = "defaultBuckets"
    value = {{ $.Spec.S3.DbNames | join "," | quote }}
  }

  values = [
    yamlencode({
      global = {
        imageRegistry = var.EXTERNAL_IMAGE_REPO
      }
      commonLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "minio"
      })
      persistence = {
        size = var.DEV_MODE ? "8Gi" : "64Gi"
      }
      provisioning = {
        enabled = true
        users = [
          {{- range $entry := $.ContainerList }}
          {{- if $entry.Container.S3.Use }}
          {
            username    = {{ quote $entry.Fullname }}
            password    = random_password.minio_passwords[{{ quote $entry.Container.S3.Db }}].result
            setPolicies = true # overwrite any existing policies each time
            disabled    = false
            policies = [
              "readwrite",
              "diagnostics",
              {{- if $entry.Container.Mongo.Priviledged }}
              "userAdmin",
              "dbAdmin",
              {{- end }}
            ]
          }
          {{- end }}
          {{- end }}
        ]
        buckets = {{ toTf $.Spec.S3.DbNames }}
      }
    })
  ]
}

resource "random_password" "minio_distributed_admin_password" {
  for_each = toset({{ toTf $.Spec.S3.DbNames }})
  length   = 16
  special  = false
}

resource "helm_release" "minio_distributed" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "minio"

  for_each = var.HA ? toset({{ toTf $.Spec.S3.DbNames }}) : []

  name      = "${local.deployment_name}-db-minio-${each.value}"
  namespace = local.namespace
  version   = local.external_versions.minio_chart

  set {
    name  = "mode"
    value = "distributed"
  }

  set {
    name  = "auth.rootPassword"
    value = random_password.minio_distributed_admin_password[each.value].result
  }

  values = [
    yamlencode({
      global = {
        imageRegistry = var.EXTERNAL_IMAGE_REPO
      }
      persistence = {
        size = var.DEV_MODE ? "8Gi" : "64Gi"
      }
      commonLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "minio-${each.value}"
      })
      provisioning = {
        enabled = true
        users = [
          {{- range $entry := $.ContainerList }}
          {{- if $entry.Container.S3.Use }}
          {
            username    = {{ quote $entry.Fullname }}
            password    = random_password.minio_passwords[{{ quote $entry.Container.S3.Db }}].result
            setPolicies = true # overwrite any existing policies each time
            disabled    = false
            policies = [
              "readwrite",
              "diagnostics",
              {{- if $entry.Container.Mongo.Priviledged }}
              "userAdmin",
              "dbAdmin",
              {{- end }}
            ]
          }
          {{- end }}
          {{- end }}
        ]
        buckets = [
          {
            name = each.value
          }
        ]
      }
    })
  ]
}
{{- end }}{{/* end s3 enabled */}}

##############################################################
# Container variables
#
# Some variables are re-used throughout components so they are
# set here to avoid repetition and ensure consistency.
##############################################################

locals {

  {{- if $.Spec.Mongo.Enabled }}
  mongodb_ha_connstrings = {
    {{-  range $i, $db := $.Spec.Mongo.Dbs }}
    {{ with .Name }}
    {{ quote . }} =  "mongodb+srv://db-user:${random_password.mongo_prod_password["{{.}}"].result}@${local.deployment_name}-db-mongo-{{.}}-mongodb-headless.${local.namespace}.svc.cluster.local/{{.}}?replicaSet=rs0&ssl=false&tls=false"
    {{- end }}{{/* end with .name */}}
    {{- end }}{{/* end range mongo.dbs */}}
  }
  mongo_dev_connstrings = {
    {{-  range $i, $db := $.Spec.Mongo.Dbs }}
    {{ with .Name }}
    {{ quote . }} = "mongodb://${local.deployment_name}-db-mongo-mongodb/{{.}}"
    {{- end }}{{/* end with .name */}}
    {{- end }}{{/* end range mongo.dbs */}}
  }
  {{- end }}{{/* end if mongo.enabled */}}

{{ range $entry := $.ContainerList }}
  {{$entry.Fullname}}-secrets = {

  {{- with $entry.Container.Mongo }}
    {{- if .Use }}
    MONGO_CONNECTION_STRING = var.HA ? local.mongodb_ha_connstrings["{{ .Db}}"] : local.mongo_dev_connstrings["{{ .Db }}"]
    {{- end }}
  {{- end }}

  {{ with $entry.Container.S3 }}
    {{- if .Use }}
    S3_ENDPOINT          = var.HA ? "http://${local.deployment_name}-db-minio-{{.Db}}:9000" : "http://${local.deployment_name}-db-minio:9000"
    S3_BUCKET            = {{ quote .Db }}
    S3_ACCESS_KEY_ID     = {{ quote $entry.Fullname }}
    S3_SECRET_ACCESS_KEY = random_password.minio_passwords[{{ quote .Db }}].result
    {{- end }}
  {{- end }}

  {{- with $entry.Container.Postgresql }}
    {{- if .Use }}
    PGHOST = var.HA ? "${local.deployment_name}-db-pg-{{.Db}}-pgpool" : "${local.deployment_name}-db-pg-postgresql"

    PGUSER = {{ quote $entry.Fullname }}
    PGPASSWORD = random_password.postgresql-secret-{{$entry.Fullname}}.result
    PGDATABASE = {{ quote .Db }}
    {{- end }}
  {{- end }}

  {{ range $secret := $entry.Container.Secrets }}
    {{$secret.Var}} = local.secrets["{{$secret.Var}}"]
  {{- end }}
  }
{{- end }}{{/* end range ContainerList */}}

  component_common_labels = {
    "appdef.io/release"        = local.deployment_name
  }

  proxy_common_labels = merge(local.component_common_labels, {
    "appdef.io/component-type" = "proxy"
  })

  db_common_labels = merge(local.component_common_labels, {
    "appdef.io/component-type" = "db"
  })

  app_common_labels = merge(local.component_common_labels, {
    "appdef.io/component-type" = "app"
  })

  cron_common_labels = merge(local.component_common_labels, {
    "appdef.io/component-type" = "cron"
  })

  startup_common_labels = merge(local.component_common_labels, {
    "appdef.io/component-type" = "startup"
  })

  container_labels = {
  {{ range $entry := $.ContainerList }}
    {{$entry.Fullname | quote}} = merge(local.{{ $entry.Type }}_common_labels, {
      "appdef.io/component-name" = {{ $entry.Name | quote }}
    })
  {{- end }}{{/* end range ContainerList */}}
  }

  external_route_map = {
    {{- range $appName, $app := $.Spec.ExposedApps }}

    {{- if eq $app.Subdomain "" }}
    {{ $appName | quote }} = "https://${var.BASE_DOMAIN}{{ $app.Path }}"
    {{- else }}
    {{ $appName | quote }} = "https://${var.BASE_DOMAIN}{{ $app.Path }}"

    {{- end }}

    {{- end }}{{/* end range apps */}}
  }

  internal_route_map = {
    {{- range $appName, $app := $.Spec.Apps }}
    {{ $appName | quote }} = "http://${local.deployment_name}-app-{{$appName}}{{ $app.Path }}"
    {{- end }}{{/* end range apps */}}
  }
}

# Each component gets an explicitly define service account
{{ range $entry := $.ContainerList }}
resource "kubernetes_service_account_v1" "{{ $entry.Fullname }}" {
  metadata {
    name      = "${local.deployment_name}-{{$entry.Fullname}}"
    namespace = local.namespace
    labels    = local.container_labels[{{$entry.Fullname | quote}}]
  }
}

{{- if len ($entry.Container.Secrets) }}
resource "kubernetes_secret_v1" "{{$entry.Fullname}}-secrets" {

  metadata {
    name      = "${local.deployment_name}-{{$entry.Fullname}}"
    namespace = local.namespace
    labels    = local.container_labels[{{$entry.Fullname | quote}}]
  }

  data = local.{{$entry.Fullname}}-secrets
}
{{- end }}{{/* end if secrets */}}

{{- end }}{{/* end range ContainerList */}}



##############################################################
# Global network policy
#
# By default pods cannot initiate outbound connections
# (except) for DNS requests.
#
# We don't restrict inbound connections to pods globaly to
# allow for external tools to communicate with components.
#
# For any pod to connect to the internet it has to go via a
# pre-created proxy pod.
##############################################################

resource "kubernetes_network_policy_v1" "global-policy" {
  # This disallows all outbound traffic apart from DNS
  metadata {
    name      = "${local.deployment_name}-global-policy"
    namespace = local.namespace
    labels    = local.component_common_labels
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      ports {
        port = 53
        protocol = "UDP"
      }
    }
  }
}

resource "kubernetes_network_policy_v1" "global-proxy-policy" {
  # This allows all proxies to connect to the outside world
  metadata {
    name      = "${local.deployment_name}-global-proxy-policy"
    namespace = local.namespace
    labels    = local.component_common_labels
  }

  spec {
    pod_selector {
      match_labels = local.proxy_common_labels
    }
    policy_types = ["Egress"]

    egress {}
  }
}

##############################################################
# Component policies
##############################################################

{{ range $entry := $.ContainerList }}
resource "kubernetes_network_policy_v1" "{{ $entry.Fullname }}-egress" {
  metadata {
    name      = "${local.deployment_name}-{{ $entry.Fullname }}-egress"
    namespace = local.namespace
    labels    = local.container_labels[{{$entry.Fullname | quote}}]
  }

  spec {
    pod_selector {
      match_labels = local.container_labels[{{$entry.Fullname | quote}}]
    }
    policy_types = ["Egress"]

    egress {

      to {
        # Allow connection to all apps
        pod_selector {
          match_labels = local.app_common_labels
        }
      }

      {{- if $entry.Container.Mongo.Use }}
      to {
        # Allow connection to the mongo ha {{$entry.Container.Mongo.Db}} db
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "mongo-{{$entry.Container.Mongo.Db}}" })
        }
      }

      to {
        # Allow connection to the mongo standalone
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "mongo" })
        }
      }
      {{- end }}

      {{- if $entry.Container.Postgresql.Use }}
      to {
        # Allow connection to the pg ha {{$entry.Container.Postgresql.Db}} db
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "postgresql-{{$entry.Container.Postgresql.Db}}" })
        }
      }

      to {
        # Allow connection to the pg standalone
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "postgresql" })
        }
      }
      {{- end }}

      {{- if $entry.Container.S3.Use }}
      to {
        # Allow connection to the minio ha {{$entry.Container.S3.Db}} db
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "minio-{{$entry.Container.S3.Db}}" })
        }
      }

      to {
        # Allow connection to the minio standalone
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "minio" })
        }
      }
      {{- end }}

      {{ range $ext := $entry.Container.External }}
      to {
        # Allow connection to {{ $ext.Name }} proxy
        pod_selector {
          match_labels = merge(local.proxy_common_labels, {
            "appdef.io/proxy-name" = {{ quote $ext.Name }}
          })
        }
      }
      {{ end }}
    }
  }
}
{{ end }}

{{ range $proxyName, $ext := $.Spec.External }}

##############################################################
# Proxy
#
# Proxies are simply Envoy services that route all inbound
# traffic to the external endpoint. This gives us control over
# what can access the outside world and allows us to audit all
# outbound connections.
##############################################################

resource "kubernetes_config_map" "proxy-{{$proxyName}}" {
  metadata {
    name   = "${local.deployment_name}-proxy-{{$proxyName}}"
    labels = merge(local.proxy_common_labels, {
      "appdef.io/proxy-name" = {{ quote $proxyName }}
    })
    namespace = local.namespace
  }

  data = {
    "envoy.yaml" = <<-EOF
    static_resources:
      listeners:
      {{ range $i, $port := $ext.Ports }}
        - name: listener_{{$i}}
          address:
            socket_address:
              address: 0.0.0.0 # We can listen on all traffic as network policies restrict acces.
              port_value: 300{{$i}}
          filter_chains:
            - filters:
                - name: envoy.filters.network.tcp_proxy
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy
                    stat_prefix: destination
                    cluster: endpoint_{{$i}}
                    access_log:
                      - name: envoy.access_loggers.stdout
                        typed_config:
                          "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
      {{ end }}
      clusters:
      {{ range $i, $port := $ext.Ports }}
        - name: endpoint_{{$i}}
          connect_timeout: 30s
          type: LOGICAL_DNS
          dns_lookup_family: V4_ONLY
          load_assignment:
            cluster_name: endpoint_{{$i}}
            endpoints:
              - lb_endpoints:
                  - endpoint:
                      address:
                        socket_address:
                          address: {{ $ext.Hostname }}
                          port_value: {{ $port }}
      {{ end }}
    EOF
  }
}

resource "kubernetes_deployment" "proxy-{{$proxyName}}" {
  metadata {
    name   = "${local.deployment_name}-proxy-{{$proxyName}}"
    labels = merge(local.proxy_common_labels, {
      "appdef.io/proxy-name" = {{ quote $proxyName }}
    })
    namespace = local.namespace
  }

  spec {
    replicas = 2
    selector {
      match_labels = merge(local.proxy_common_labels, {
        "appdef.io/proxy-name" = {{ quote $proxyName }}
      })
    }
    template {
      metadata {
        labels = merge(local.proxy_common_labels, {
          "appdef.io/proxy-name" = {{ quote $proxyName }}
        })
      }
      spec {
        container {
          name = "envoy"
          image = "${var.EXTERNAL_IMAGE_REPO}/envoyproxy/envoy-alpine:v1.21.2"

          {{ range $i, $port := $ext.Ports }}
          port {
            name = "port-{{$i}}"
            container_port = 300{{$i}}
            protocol = "TCP"
          }
          {{ end }}

          volume_mount {
            name = "config"
            mount_path = "/etc/envoy/"
          }

          security_context {
            run_as_non_root            = true
            run_as_user                = 1001
            read_only_root_filesystem  = true
            allow_privilege_escalation = false
            privileged                 = false
          }
        }
        volume {
          name = "config"
          config_map {
            name = "${local.deployment_name}-proxy-{{$proxyName}}"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "proxy-{{$proxyName}}" {
  metadata {
    name   = "${local.deployment_name}-proxy-{{$proxyName}}"
    labels = merge(local.proxy_common_labels, {
      "appdef.io/proxy-name" = {{ quote $proxyName }}
    })
    namespace = local.namespace
  }
  spec {
    selector = merge(local.proxy_common_labels, {
      "appdef.io/proxy-name" = {{ quote $proxyName }}
    })

    {{ range $i, $port := $ext.Ports }}
    port {
      name = "port-{{$i}}"
      target_port = 300{{$i}}
      port = {{$port}}
    }
    {{ end }}

    type = "ClusterIP"
  }
}

{{ end }}




{{ range $appName, $app := $.Spec.Apps }}

##############################################################
# App {{$appName}}
##############################################################

resource "kubernetes_service_v1" "app-{{$appName}}" {

  metadata {
    name      = "${local.deployment_name}-app-{{$appName}}"
    namespace = local.namespace
    labels    = local.container_labels["app-{{ $appName }}"]
  }

  spec {
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = "http"
    }
    selector = local.container_labels["app-{{ $appName }}"]
    type     = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "{{$appName}}-app" {

  metadata {
    name      = "${local.deployment_name}-app-{{$appName}}"
    namespace = local.namespace
    labels    = local.container_labels["app-{{ $appName }}"]
  }

  spec {
    replicas = var.HA ? null : 2
    selector {
      match_labels = local.container_labels["app-{{ $appName }}"]
    }
    template {
      metadata {
        annotations = {
          # This causes the pods to restart when the secrets change
          "checksum/secret" = base64encode(jsonencode(local.app-{{$appName}}-secrets))
        }
        labels = local.container_labels["app-{{ $appName }}"]
      }
      spec {
        {{ include "init_containers" $app | nindent 8 }}

        {{ range $appExt := $app.External }}
        host_aliases {
          {{ with $ext := index $.Spec.External $appExt.Name }}
          hostnames = [{{ quote $ext.Hostname }}]
          ip = kubernetes_service_v1.proxy-{{ $appExt.Name }}.spec.0.cluster_ip
          {{ end }}{{/* end with ext */}}
        }
        {{ end }}{{/* end range app.external */}}

        container {
          name = "{{$appName}}"

          {{ include "image" $app | nindent 10 }}

          image_pull_policy = "IfNotPresent"

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

          {{- with $app.Port }}
          env {
            name  = "PORT"
            value = "{{.}}"
          }
          {{- else }}
          env {
            name  = "PORT"
            value = "8080"
          }
          {{- end }}

          dynamic "env" {
            for_each = local.app-{{$appName}}-secrets
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key = env.key
                  name = "${local.deployment_name}-app-{{ $appName }}"
                }
              }
            }
          }

          {{- with $app.Port }}
          port {
            container_port = {{.}}
            name           = "http"
            protocol       = "TCP"
          }
          {{- else }}
          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }
          {{- end }}

          {{ include "container_security_context" $app | nindent 10 }}

          {{- with $app.HealthCheck }}
          liveness_probe {
            http_get {
              path = {{ . | quote }}
              port = "http"
            }
          }

          readiness_probe {
            http_get {
              path = {{ . | quote }}
              port = "http"
            }
          }
          {{- end }}

          {{ include "container_resources" $app | nindent 10 }}

        }
        service_account_name = "${local.deployment_name}-app-{{$appName}}"
      }
    }
  }

  # On failure the ci will just wait around unless we fail-fast
  wait_for_rollout = false
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "app-{{$appName}}" {
  # Only use a hpa when ha mode is on
  count = var.HA ? 1 : 0

  metadata {
    name      = "${local.deployment_name}-app-{{$appName}}"
    namespace = local.namespace
    labels    = local.container_labels["app-{{ $appName }}"]
  }

  spec {
    max_replicas = 60
    min_replicas = 3

    target_cpu_utilization_percentage = 80

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "${local.deployment_name}-app-{{$appName}}"
    }
  }
}

{{- end }} {{/* end app */}}


{{ range $cronName, $cron := $.Spec.Cron }}

##############################################################
# Cron {{$cronName}}
##############################################################


resource "kubernetes_cron_job_v1" "{{$cronName}}-cron" {

  metadata {
    name      = "${local.deployment_name}-cron-{{$cronName}}"
    namespace = local.namespace
    labels    = local.container_labels["cron-{{ $cronName }}"]
  }

  spec {
    schedule = {{ $cron.Schedule | quote }}
    job_template {
      metadata {
        labels = local.container_labels["cron-{{ $cronName }}"]
      }

      spec {
        template {
          metadata {
            labels = local.container_labels["cron-{{ $cronName }}"]
          }
          spec {
            {{ include "init_containers" $cron | nindent 12 }}

            container {
              name = "{{$cronName}}"

              {{ include "image" $cron | nindent 14 }}

              image_pull_policy = "IfNotPresent"

              env {
                name  = "NODE_ENV"
                value = var.DEV_MODE ? "development" : "production"
              }

              env {
                name = "EXT_ROUTE_MAP"
                value = jsonencode(local.external_route_map)
              }

              dynamic "env" {
                for_each = local.cron-{{$cronName}}-secrets
                content {
                  name = env.key
                  value_from {
                    secret_key_ref {
                      key = env.key
                      name = "${local.deployment_name}-cron-{{ $cronName }}"
                    }
                  }
                }
              }

              {{ include "container_security_context" $cron | nindent 14 }}
              {{ include "container_resources" $cron | nindent 14 }}

            }
            service_account_name = "${local.deployment_name}-cron-{{$cronName}}"
          }
        }
      }
    }
  }
}

{{- end }} {{/* end cron */}}


{{ range $startupName, $startup := $.Spec.Startup }}

##############################################################
# Startup {{$startupName}}
##############################################################


resource "kubernetes_job_v1" "{{$startupName}}-startup" {

  metadata {
    name      = "${local.deployment_name}-startup-{{$startupName}}"
    namespace = local.namespace
    labels    = local.container_labels["startup-{{ $startupName }}"]
  }

  spec {
    template {
      metadata {
        labels = local.container_labels["startup-{{ $startupName }}"]
      }
      spec {
        {{ include "init_containers" $startup | nindent 8 }}

        container {
          name = "{{$startupName}}"

          {{ include "image" $startup | nindent 10 }}

          image_pull_policy = "IfNotPresent"

          env {
            name  = "NODE_ENV"
            value = var.DEV_MODE ? "development" : "production"
          }

          env {
            name = "EXT_ROUTE_MAP"
            value = jsonencode(local.external_route_map)
          }

          dynamic "env" {
            for_each = local.startup-{{$startupName}}-secrets
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key = env.key
                  name = "${local.deployment_name}-startup-{{ $startupName }}"
                }
              }
            }
          }

          {{ include "container_security_context" $startup | nindent 10 }}

          {{ include "container_resources" $startup | nindent 10 }}

        }
        service_account_name = "${local.deployment_name}-startup-{{$startupName}}"
      }
    }
  }
}

{{- end }} {{/* end startup */}}


{{- if len $.Subdomains }}
##############################################################
# Ingresses
#
# This is where we define our ingresses into the cluster. All
# ingresses are defined with external-dns and certmanager
# annotations for DNS and TLS integration.
##############################################################

variable "CLUSTERISSUER" {
  type        = string
  default     = "letsencrypt"
  description = "clusterissuer which will create the ssl cert used by these ingresses"
}

variable "INGRESS_CLASS_NAME" {
  type        = string
  default     = "nginx"
  description = "ingress class that all ingresses will use"
}

variable "INGRESS_AUTH_REQUEST" {
  type = string
  default = null
}

locals {
  default_ingress_annotations = merge(
    {
      "cert-manager.io/cluster-issuer" = var.CLUSTERISSUER
    },
    # Add auth annotations if ingress_auth_request is passed in
    var.INGRESS_AUTH_REQUEST != null ? {
      "nginx.ingress.kubernetes.io/auth-signin" = "https://${var.INGRESS_AUTH_REQUEST}/oauth2/start?rd=https://$host$escaped_request_uri"
      "nginx.ingress.kubernetes.io/auth-url"    = "https://${var.INGRESS_AUTH_REQUEST}/oauth2/auth"
    } :{}
  )
}

{{ range $subdomain := $.Subdomains }}
resource "kubernetes_ingress_v1" "ingress-{{$subdomain}}" {

  metadata {
    name      = "${local.deployment_name}-{{$subdomain}}-ingress"
    namespace = local.namespace

    annotations = merge(local.default_ingress_annotations, {
      "external-dns.alpha.kubernetes.io/hostname" = {{ if eq $subdomain "" -}} var.BASE_DOMAIN {{- else -}} "{{$subdomain}}.${var.BASE_DOMAIN}" {{- end }}
    })
  }

  spec {
    ingress_class_name = var.INGRESS_CLASS_NAME

    tls {
      secret_name = "${local.deployment_name}-{{$subdomain}}-cert"
      hosts       = [{{ if eq $subdomain "" -}} var.BASE_DOMAIN {{- else -}} "{{$subdomain}}.${var.BASE_DOMAIN}" {{- end }}]
    }

    rule {
      host = {{ if eq $subdomain "" -}} var.BASE_DOMAIN {{- else -}} "{{$subdomain}}.${var.BASE_DOMAIN}" {{- end }}
      http {
        
        {{- range $k, $app := $.Spec.ExposedApps }}
        {{- if eq $app.Subdomain $subdomain }}
        path {
          {{- if eq $app.Path "/" }}
          path = "/"
          {{- else }}
          path = "{{$app.Path}}/"
          {{- end }}
          backend {
            service {
              name = "${local.deployment_name}-app-{{$k}}"
              port {
                name = "http"
              }
            }
          }
        }
        {{- end }}
        {{- end }}
      }
    }
  }
}
{{- end }}{{/* end range .Subdomains */}}
{{- end }}{{/* end len .Subdomains */}}
