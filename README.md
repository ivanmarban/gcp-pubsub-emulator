# gcp-pubsub-emulator

[![Release](https://img.shields.io/github/v/release/ivanmarban/gcp-pubsub-emulator?logo=github)](https://github.com/ivanmarban/gcp-pubsub-emulator/releases)
[![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/ivanmarban/gcp-pubsub-emulator/build-test-push.yaml?logo=github&label=build)](https://github.com/ivanmarban/gcp-pubsub-emulator/actions/workflows/build-test-push.yaml)
[![Image tags](https://ghcr-badge.egpl.dev/ivanmarban/gcp-pubsub-emulator/tags?trim=major&label=image%20tags)](https://github.com/ivanmarban/gcp-pubsub-emulator/pkgs/container/gcp-pubsub-emulator)
[![Latest image](https://ghcr-badge.egpl.dev/ivanmarban/gcp-pubsub-emulator/latest_tag?trim=major&label=latest)](https://github.com/ivanmarban/gcp-pubsub-emulator/pkgs/container/gcp-pubsub-emulator)
[![Image size](https://ghcr-badge.egpl.dev/ivanmarban/gcp-pubsub-emulator/size?trim=major&label=image%20size)](https://github.com/ivanmarban/gcp-pubsub-emulator/pkgs/container/gcp-pubsub-emulator)

A Docker container image of GCP PubSub emulator

## Installation

A pre-built Docker container is available from ghcr.io:

```
docker run --rm -ti -p 8085:8085 --name pubsub ghcr.io/ivanmarban/gcp-pubsub-emulator:latest
```

Or, if you prefer to build it yourself:

```
git clone https://github.com/ivanmarban/gcp-pubsub-emulator.git
cd gcp-pubsub-emulator
docker build --build-arg GOOGLE_CLOUD_SDK_VERSION=453.0.0 -t gcp-cloud-emulator:latest .
```
Where `GOOGLE_CLOUD_SDK_VERSION` corresponds for version of Google Cloud SDK

## Prerequisites

- Docker runtime

## Usage

After running the above `docker run` command, the container will start and configure automatically following resources:

- project id: `myproject`
- topic: `mytopic`
- subscription: `mysubscription`
- emulator listening port: `8085`

Publishing a message:

```
docker exec pubsub curl -s -X POST 'http://localhost:8085/v1/projects/myproject/topics/mytopic:publish' \
    -H 'Content-Type: application/json' \
    --data '{"messages":[{"attributes":{"attribute1":"value1","attribute2":"value2"},"data":"eyJrZXkiOiAidmFsdWUifQ=="}]}'
```

- The [publish](https://cloud.google.com/pubsub/docs/reference/rest/v1/projects.topics/publish) API accepts an array of messages
- The [message](https://cloud.google.com/pubsub/docs/reference/rest/v1/PubsubMessage) payload must be base64-encoded



## Configuration

If the default configuration does not meet your needs, you can tune it using environment variables.

### Environment variables

| Parameter Name       | Description                                                                | Default value                                                               |
|----------------------|----------------------------------------------------------------------------|-----------------------------------------------------------------------------|
| PUBSUB_PORT          | Port number to run the emulator                                            | 8085                                                                        |
| PUBSUB_PROJECT       | The project id                                                             | myproject                                                                   |
| PUBSUB_SETUP         | A json representation of topics & subscriptions to be created              | {"topics":[{"name":"mytopic","subscriptions":[{"name":"mysubscription"}]}]} |
| SETUP_RETRIES        | Number of retries of the setup script waiting for the emulator to be ready | 10                                                                          |
| SETUP_SLEEP_INTERVAL | Specify a duration for which the setup script should sleep between retries | 2                                                                           |

### Topics and subscriptions json schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Topics and subscriptions",
  "type": "object",
  "properties": {
    "topics": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "name": {
            "type": "string"
          },
          "subscriptions": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string"
                }
              },
              "required": [
                "name"
              ]
            }
          }
        },
        "required": [
          "name",
          "subscriptions"
        ]
      }
    }
  },
  "required": [
    "topics"
  ]
}
```

## Examples

```
docker run --rm -ti -p 8888:8888 \
    -e PUBSUB_PORT=8888 \
    -e PUBSUB_PROJECT=project1 \
    -e 'PUBSUB_SETUP={"topics":[{"name":"topic1","subscriptions":[{"name":"subscription1"},{"name":"subscription2"}]}]}' \
    -e SETUP_RETRIES=5 \
    -e SETUP_SLEEP_INTERVAL=1 \
    --name pubsub ghcr.io/ivanmarban/gcp-pubsub-emulator:latest
```

```yaml
---
version: '3.9'
services:
  pubsub-emulator:
    container_name: pubsub
    image: ghcr.io/ivanmarban/gcp-pubsub-emulator:latest
    ports:
      - "8888:8888"
    environment:
      PUBSUB_PORT: 8888
      PUBSUB_PROJECT: project1
      PUBSUB_SETUP: '{"topics":[{"name":"topic1","subscriptions":[{"name":"subscription1"},{"name":"subscription2"}]}]}'
      SETUP_RETRIES: 5
      SETUP_SLEEP_INTERVAL: 1
    healthcheck:
      test: curl --fail localhost:8888/v1/projects/project1/subscriptions/subscription2 || exit 1
      interval: 5s
      retries: 10
```

## Special Thanks
This project was inspired by [marcelcorso/gcloud-pubsub-emulator](https://github.com/marcelcorso/gcloud-pubsub-emulator)