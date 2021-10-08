# HELMOLINT

## Description

You can use `server-snippet` annotations in ingress manifests. If an incorrect nginx expression is used in the annotation,
the annotation will still be loaded into the ingress config.
But it will not be able to apply due to an error and thus will block the next changes in the entire ingress config.

To check annotations, you can use `admissionWebhooks` setting in ingress controller:

```yaml
## nginx configuration
## Ref: https://github.com/kubernetes/ingress/blob/master/controllers/nginx/configuration.md
```

If you can't enable `admissionWebhooks`, you can use `helmolint` (helm ingress linter) in the gitlab pipeline.

## Build image

- run `docker build -t helmolint:0.1.0 .`
- tag and save image in private registry
- or use `.gitlab-ci.yml` for auto builds (look `.gitlab-ci.yml.example`)

## Use helm ingress linter in GitLab CI

1. Save rendered helm template with name `helm_template.yaml` in helm_lint job

```yaml

helm_lint:
  script:
    - helm repo update
    - helm template $CHART_APP_NAME $CHART $CHART_VALUES --version $CHART_VERSION --debug
    - helm template $CHART_APP_NAME $CHART $CHART_VALUES --version $CHART_VERSION --debug > ./helm_template.yaml
  stage: lint
  artifacts:
    paths:
      - ./helm_template.yaml
    expire_in: 30m
```

2. Run check job

```yaml

lint:helm:ingress:
  image: registry.local/kube-public/helmolint:0.1.0
  stage: ingress_lint
  dependencies:
    - helm_lint
  script:
    - echo "Check ingress snippets."
```

## Linter algorithm

- find ingress manifests in rendered helm template
- load objects `server-snippet` from file
- put snippets in nginx config
- validate config `nginx -t -c custom.conf`
