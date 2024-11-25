## Api builder
FROM golang:1.22.9-alpine3.20 AS builder

COPY api/ /opt
WORKDIR /opt
RUN go build -o appdef-service-api main.go

## Ui builder
FROM node:23-alpine3.19 AS ui-builder

COPY ui/ /opt
WORKDIR /opt
RUN npm ci && npm run build

## Main image
FROM alpine:3.20.2
RUN mkdir /srv/ui
COPY --from=builder /opt/appdef-service-api /usr/local/bin/appdef-service
COPY --from=ui-builder /opt/build /srv/ui/build
RUN chmod 755 /usr/local/bin/appdef-service
RUN adduser -u 1066 -D rss-user 
WORKDIR /srv/

USER 1066
CMD ["/usr/local/bin/appdef-service"]
