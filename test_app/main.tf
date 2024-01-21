 

terraform {
  required_version = "> 1.1.0"

  backend "kubernetes" {
    secret_suffix = "noddy-state"
    namespace     = "kube-system"
  }

  required_providers {
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
  deployment_name = "noddy-${terraform.workspace}"

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
  default     = "registry.gitlab.builder.ai"
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

resource "kubernetes_namespace" "ns" {
  metadata {
    name = local.deployment_name
  }
}

locals {
  ns        = kubernetes_namespace.ns
  namespace = kubernetes_namespace.ns.metadata[0].name
}
resource "random_password" "postgresql-secret-app-api" {
  # This is the postgresql password for app-api
  length   = 16
  special  = false
}

##############################################################
# Postgresql HA app database
#
# In HA mode we create a postgresql pool and pgpool request
# balancer for this database.
##############################################################

resource "random_password" "postgresql-root-app" {
  # This is the root postgresql password for app
  length   = 16
  special  = false
}

resource "random_password" "postgresql-repmgr-app" {
  # This is the postgresql repmgr password for app
  length   = 16
  special  = false
}

resource "random_password" "postgresql-admin-app" {
  # This is the postgresql pgpool admin password for app
  length   = 16
  special  = false
}

resource "kubernetes_network_policy_v1" "pg-db-policy-app" {
  count = var.HA ? 1 : 0
  metadata {
    name      = "${local.deployment_name}-db-pg-policy-app"
    namespace = local.namespace
    labels = merge(local.db_common_labels, {
      "appdef.io/component-name" = "postgresql-app"
    })
  }

  spec {
    pod_selector {
      match_labels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "postgresql-app"
      })
    }
    policy_types = ["Egress"]

    egress {
      to {
        # Allow pods for this postgresql instance to connect to each other
        pod_selector {
          match_labels = merge(local.db_common_labels, {
            "appdef.io/component-name" = "postgresql-app"
          })
        }
      }
    }
  }
}

resource "kubernetes_secret_v1" "postgresql-ha-app-initdb" {
  count = var.HA ? 1 : 0
  metadata {
    name      = "${local.deployment_name}-db-pg-app-initdb"
    namespace = local.namespace
    labels = merge(local.db_common_labels, {
      "appdef.io/component-name" = "postgresql-app"
    })
  }

  data = {
    "10-create-db-app.sh" = <<-EOF
    PGUSER=postgres PGPASSWORD=$POSTGRESQL_INITSCRIPTS_PASSWORD psql -c 'create database app' || true
    EOF

    "20-init.sql" = <<-EOF
    REVOKE CONNECT ON DATABASE app FROM PUBLIC;

    \c app
    REVOKE ALL ON SCHEMA public FROM PUBLIC;
    REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC ;
    DO
    $$
    BEGIN
       IF EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = 'app-api') THEN

          RAISE NOTICE 'Role "app-api" already exists. Skipping.';
       ELSE
          CREATE ROLE "app-api" LOGIN PASSWORD '${random_password.postgresql-secret-app-api.result}';
          GRANT  CONNECT ON DATABASE app TO "app-api";
          GRANT  USAGE   ON SCHEMA public TO "app-api";
          ALTER DEFAULT PRIVILEGES GRANT SELECT, UPDATE, DELETE, INSERT ON TABLES TO "app-api";

       END IF;
    END
    $$;
    EOF
  }
}

resource "helm_release" "postgresql-ha-app" {
  count = var.HA ? 1 : 0
  depends_on = [kubernetes_network_policy_v1.pg-db-policy-app]

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql-ha"

  name      = "${local.deployment_name}-app"
  namespace = local.namespace
  version   = local.external_versions.postgresql_ha_chart

  wait = false # This can take a long time to come up

  values = [
    yamlencode({
      // We override the name as it can get a bit long otherwise
      fullnameOverride = "${local.deployment_name}-db-pg-app",
      global = {
        imageRegistry = var.EXTERNAL_IMAGE_REPO
        postgresql = {
          password = random_password.postgresql-root-app.result
          repmgrPassword = random_password.postgresql-root-app.result
        }
      }
      pgpool = {
        adminPassword = random_password.postgresql-admin-app.result
      }
      commonLabels = merge(local.db_common_labels, {
        "appdef.io/component-name" = "postgresql-app"
      })
      metrics = {
        enabled = true
      }
      persistence = {
        size = var.DEV_MODE ? "8Gi" : "64Gi"
      }
      postgresql = {
        password = random_password.postgresql-root-app.result
        repmgrPassword = random_password.postgresql-root-app.result

        podLabels = merge(local.db_common_labels, {
          "appdef.io/component-name" = "postgresql-app"
        })

        initdbScriptsSecret = kubernetes_secret_v1.postgresql-ha-app-initdb[count.index].metadata[0].name
      }
    })
  ]
}

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
    
    "10-create-db-app.sh" = <<-EOF
      PGUSER=postgres PGPASSWORD=$POSTGRESQL_INITSCRIPTS_PASSWORD psql -c 'create database app' || true
      EOF

    "20-init.sql" = <<-EOF
      

      \c app
      REVOKE CONNECT ON DATABASE app FROM PUBLIC;
      REVOKE ALL ON SCHEMA public FROM PUBLIC;
      REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC ;
      DO
      $$
      BEGIN
         IF EXISTS (
            SELECT FROM pg_catalog.pg_roles
            WHERE  rolname = 'app-api') THEN

            RAISE NOTICE 'Role "app-api" already exists. Skipping.';
         ELSE
            CREATE ROLE "app-api" LOGIN PASSWORD '${random_password.postgresql-secret-app-api.result}';
            GRANT  CONNECT ON DATABASE app TO "app-api";
            GRANT  USAGE   ON SCHEMA public TO "app-api";
            ALTER DEFAULT PRIVILEGES GRANT SELECT, UPDATE, DELETE, INSERT ON TABLES TO "app-api";

         END IF;
      END
      $$;
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

##############################################################
# Container variables
#
# Some variables are re-used throughout components so they are
# set here to avoid repetition and ensure consistency.
##############################################################

locals {


  app-ui-secrets = {

  

  
  }
  app-api-secrets = {

  
    PGHOST = var.HA ? "${local.deployment_name}-db-pg-app-pgpool" : "${local.deployment_name}-db-pg-postgresql"

    PGUSER = "app-api"
    PGPASSWORD = random_password.postgresql-secret-app-api.result
    PGDATABASE = "app"

  
  }

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
  
    "app-ui" = merge(local.app_common_labels, {
      "appdef.io/component-name" = "ui"
    })
    "app-api" = merge(local.app_common_labels, {
      "appdef.io/component-name" = "api"
    })
  }

  external_route_map = {
    "api" = "https://${var.BASE_DOMAIN}/api"
    "ui" = "https://${var.BASE_DOMAIN}/"
  }

  internal_route_map = {
    "api" = "http://${local.deployment_name}-app-api/api"
    "ui" = "http://${local.deployment_name}-app-ui/"
  }
}

# Each component gets an explicitly define service account

resource "kubernetes_service_account_v1" "app-ui" {
  metadata {
    name      = "${local.deployment_name}-app-ui"
    namespace = local.namespace
    labels    = local.container_labels["app-ui"]
  }
}
resource "kubernetes_service_account_v1" "app-api" {
  metadata {
    name      = "${local.deployment_name}-app-api"
    namespace = local.namespace
    labels    = local.container_labels["app-api"]
  }
}



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


resource "kubernetes_network_policy_v1" "app-ui-egress" {
  metadata {
    name      = "${local.deployment_name}-app-ui-egress"
    namespace = local.namespace
    labels    = local.container_labels["app-ui"]
  }

  spec {
    pod_selector {
      match_labels = local.container_labels["app-ui"]
    }
    policy_types = ["Egress"]

    egress {

      to {
        # Allow connection to all apps
        pod_selector {
          match_labels = local.app_common_labels
        }
      }

      
    }
  }
}

resource "kubernetes_network_policy_v1" "app-api-egress" {
  metadata {
    name      = "${local.deployment_name}-app-api-egress"
    namespace = local.namespace
    labels    = local.container_labels["app-api"]
  }

  spec {
    pod_selector {
      match_labels = local.container_labels["app-api"]
    }
    policy_types = ["Egress"]

    egress {

      to {
        # Allow connection to all apps
        pod_selector {
          match_labels = local.app_common_labels
        }
      }
      to {
        # Allow connection to the pg ha app db
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "postgresql-app" })
        }
      }

      to {
        # Allow connection to the pg standalone
        pod_selector {
          match_labels = merge(local.db_common_labels, { "appdef.io/component-name": "postgresql" })
        }
      }

      
    }
  }
}









##############################################################
# App api
##############################################################

resource "kubernetes_service_v1" "app-api" {

  metadata {
    name      = "${local.deployment_name}-app-api"
    namespace = local.namespace
    labels    = local.container_labels["app-api"]
  }

  spec {
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = "http"
    }
    selector = local.container_labels["app-api"]
    type     = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "api-app" {

  metadata {
    name      = "${local.deployment_name}-app-api"
    namespace = local.namespace
    labels    = local.container_labels["app-api"]
  }

  spec {
    replicas = var.HA ? null : 2
    selector {
      match_labels = local.container_labels["app-api"]
    }
    template {
      metadata {
        annotations = {
          # This causes the pods to restart when the secrets change
          "checksum/secret" = base64encode(jsonencode(local.app-api-secrets))
        }
        labels = local.container_labels["app-api"]
      }
      spec {
        
        
        
        init_container {
          name  = "init-pg"
          image = "${var.EXTERNAL_IMAGE_REPO}/busybox:${local.external_versions.busybox_image}"
          command = ["sh", "-c", <<-EOF
             %{if var.HA}
             pg_host="${local.deployment_name}-db-pg-app-pgpool"
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

        

        container {
          name = "api"

          
          
          image = "${var.INTERNAL_IMAGE_REPO}/noddy-api:${var.LIVE_TAG}"

          image_pull_policy = "IfNotPresent"

          env {
            name  = "NODE_ENV"
            value = var.DEV_MODE ? "development" : "production"
          }

          env {
            name = "EXT_ROUTE_MAP"
            value = jsonencode(local.external_route_map)
          }
          env {
            name  = "MOUNT_PATH"
            value = "/api"
          }

          env {
            name  = "APP_URL"
            value = "https://${var.BASE_DOMAIN}/api"
          }
          env {
            name  = "PORT"
            value = "8080"
          }

          dynamic "env" {
            for_each = local.app-api-secrets
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key = env.key
                  name = "${local.deployment_name}-app-api"
                }
              }
            }
          }
          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          
          
          
          security_context {
            read_only_root_filesystem  = true
          
            allow_privilege_escalation = false
            privileged                 = false
          }

          
          
          
          resources {
            limits   = { cpu = "1", memory = "4Gi" }
            requests = {
              cpu    = var.DEV_MODE ? "50m"  : "200m",
              memory = var.DEV_MODE ? "128Mi" : "256Mi"
            }
          }

        }
        service_account_name = "${local.deployment_name}-app-api"
      }
    }
  }

  # On failure the ci will just wait around unless we fail-fast
  wait_for_rollout = false
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "app-api" {
  # Only use a hpa when ha mode is on
  count = var.HA ? 1 : 0

  metadata {
    name      = "${local.deployment_name}-app-api"
    namespace = local.namespace
    labels    = local.container_labels["app-api"]
  }

  spec {
    max_replicas = 60
    min_replicas = 3

    target_cpu_utilization_percentage = 80

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "${local.deployment_name}-app-api"
    }
  }
}

##############################################################
# App ui
##############################################################

resource "kubernetes_service_v1" "app-ui" {

  metadata {
    name      = "${local.deployment_name}-app-ui"
    namespace = local.namespace
    labels    = local.container_labels["app-ui"]
  }

  spec {
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = "http"
    }
    selector = local.container_labels["app-ui"]
    type     = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "ui-app" {

  metadata {
    name      = "${local.deployment_name}-app-ui"
    namespace = local.namespace
    labels    = local.container_labels["app-ui"]
  }

  spec {
    replicas = var.HA ? null : 2
    selector {
      match_labels = local.container_labels["app-ui"]
    }
    template {
      metadata {
        annotations = {
          # This causes the pods to restart when the secrets change
          "checksum/secret" = base64encode(jsonencode(local.app-ui-secrets))
        }
        labels = local.container_labels["app-ui"]
      }
      spec {
        
        
        

        

        container {
          name = "ui"

          
          
          image = "${var.INTERNAL_IMAGE_REPO}/noddy-ui:${var.LIVE_TAG}"

          image_pull_policy = "IfNotPresent"

          env {
            name  = "NODE_ENV"
            value = var.DEV_MODE ? "development" : "production"
          }

          env {
            name = "EXT_ROUTE_MAP"
            value = jsonencode(local.external_route_map)
          }
          env {
            name  = "MOUNT_PATH"
            value = "/"
          }

          env {
            name  = "APP_URL"
            value = "https://${var.BASE_DOMAIN}/"
          }
          env {
            name  = "PORT"
            value = "8080"
          }

          dynamic "env" {
            for_each = local.app-ui-secrets
            content {
              name = env.key
              value_from {
                secret_key_ref {
                  key = env.key
                  name = "${local.deployment_name}-app-ui"
                }
              }
            }
          }
          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          
          
          
          security_context {
          
            allow_privilege_escalation = false
            privileged                 = false
          }

          
          
          
          resources {
            limits   = { cpu = "1", memory = "4Gi" }
            requests = {
              cpu    = var.DEV_MODE ? "50m"  : "200m",
              memory = var.DEV_MODE ? "128Mi" : "256Mi"
            }
          }

        }
        service_account_name = "${local.deployment_name}-app-ui"
      }
    }
  }

  # On failure the ci will just wait around unless we fail-fast
  wait_for_rollout = false
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "app-ui" {
  # Only use a hpa when ha mode is on
  count = var.HA ? 1 : 0

  metadata {
    name      = "${local.deployment_name}-app-ui"
    namespace = local.namespace
    labels    = local.container_labels["app-ui"]
  }

  spec {
    max_replicas = 60
    min_replicas = 3

    target_cpu_utilization_percentage = 80

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "${local.deployment_name}-app-ui"
    }
  }
} 


 


 
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


resource "kubernetes_ingress_v1" "ingress-" {

  metadata {
    name      = "${local.deployment_name}--ingress"
    namespace = local.namespace

    annotations = merge(local.default_ingress_annotations, {
      "external-dns.alpha.kubernetes.io/hostname" = var.BASE_DOMAIN
    })
  }

  spec {
    ingress_class_name = var.INGRESS_CLASS_NAME

    tls {
      secret_name = "${local.deployment_name}--cert"
      hosts       = [var.BASE_DOMAIN]
    }

    rule {
      host = var.BASE_DOMAIN
      http {
        path {
          path = "/api/"
          backend {
            service {
              name = "${local.deployment_name}-app-api"
              port {
                name = "http"
              }
            }
          }
        }
        path {
          path = "/"
          backend {
            service {
              name = "${local.deployment_name}-app-ui"
              port {
                name = "http"
              }
            }
          }
        }
      }
    }
  }
}

