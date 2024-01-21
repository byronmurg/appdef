# appdef-service
Web interface for appdef generation

## Platform

Look in `platform/` subdirectory for the underlying infrastructure.

## Deployment

With the following terraform vars you can deploy from this repo.
```
PROJECT_ID          = "appdef-service"
BASE_DOMAIN         = "spec.appdef.io"
ZONE                = "spec-appdef.io"
INTERNAL_IMAGE_REPO = "eu.gcr.io/appdef-service"
LIVE_TAG            = "751aeecbf653d48923bf47ae04ddd8680790d0f6" # Or the latest commit
HA                  = false
DEV_MODE            = false
REGION              = "europe-west1"
IAP_CLIENT_ID       = "IAP_CLIENT_HERE"
IAP_CLIENT_SECRET   = "IAP_SECRET_HERE"
ALLOWED_GROUPS      = ["group:all@appdef.io"]
```
