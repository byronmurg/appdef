# appdef

Use the live web version here [https://appdef.omanom.com](https://appdef.omanom.com)

`appdef` is a tool for describing a multi-container application (UIs, APIs, databases, cron
jobs, etc.) in a single declarative spec file, `appdef.yaml`, and turning that spec into a
working local environment or deployment artifacts.

Instead of hand-writing `docker-compose.yaml`, nginx config, and Terraform for every app, you
describe the app's shape once and let `appdef` generate the rest.

## How it fits together

- **[`appdef.schema.json`](appdef.schema.json)** — the JSON Schema that defines a valid
  `appdef.yaml` spec (apps, cron jobs, startup tasks, and backing services like Postgres,
  MongoDB, S3, and secrets).
- **[`cli/`](cli/)** — the `appdef-tool` command line tool (Go). It validates a spec, and can
  build the app's Docker images, write out a compose file + nginx config for local development,
  spin the environment up directly, or generate a skeleton spec for a new app. See
  [`cli/README.md`](cli/README.md) for installation instructions.
- **[`web/`](web/)** — a web UI + API (`appdef-service`) for generating and editing appdef specs
  in the browser.
- **[`test_app/`](test_app/)** — a small example application (`ui` + `api` + Postgres) with its
  own `appdef.yaml`, used for testing the tool end to end.

## Example spec

```yaml
spec_version: 1
name: noddy
apps:
  ui:
    description: The noddy ui
    image: noddy-ui
    build: ui/
    path: /
    port: 8080
  api:
    description: A simple api
    image: noddy-api
    build: api/
    path: /api
    port: 8080
    postgresql:
      use: true
      db: app
postgresql:
  enabled: true
  dbs:
    - name: app
```

## Quick start

Install the CLI (see [`cli/README.md`](cli/README.md) for other install options):

```
git clone omanom.com:git/appdef.git /tmp/appdef && sh /tmp/appdef/tool/easy_installer
```

From a directory containing an `appdef.yaml`:

```
appdef-tool check    # validate the spec
appdef-tool write    # write out compose + nginx config for local dev
appdef-tool up        # write the config and start it with docker compose
appdef-tool build     # build (and optionally push) the app's docker images
appdef-tool create <name>  # print a skeleton appdef.yaml
```

Try it against the bundled example:

```
cd test_app
appdef-tool up
```

## License

MIT — see [LICENSE](LICENSE).
