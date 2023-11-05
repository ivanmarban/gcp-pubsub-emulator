#!/bin/bash

DEFAULT_SETUP='{"topics":[{"name":"mytopic","subscriptions":[{"name":"mysubscription"}]}]}'
config="${PUBSUB_SETUP:-$DEFAULT_SETUP}"
port="${PUBSUB_PORT:-8085}"
project="${PUBSUB_PROJECT:-myproject}"
retries="${SETUP_RETRIES:-10}"
sleep_interval="${SETUP_SLEEP_INTERVAL:-2}"

function check_port() {
  (exec 3<>/dev/tcp/127.0.0.1/"$port") 2>/dev/null
  return $?
}

function logger() {
  echo "[setup] $1"
}

for ((i = 1; i <= retries; i++)); do
  if check_port; then
    logger "Port $port on localhost is available."
    break
  else
    logger "Port $port on localhost is not available. Retry $i of $retries..."
    sleep "$sleep_interval"
  fi
done

for ((j = 0; j < $(yq '.topics | length' <<< "$config"); j++)); do
  topic=$(yq '.topics['"$j"'].name' <<< "$config")
  topic_response=$(curl -s -o /dev/null -w '%{http_code}' -X PUT localhost:"$port"/v1/projects/"$project"/topics/"$topic")
  if [ "$topic_response" -eq 200 ]; then
    logger "Topic [projects/$project/topics/$topic] created successfully"
  else
    logger "Error creating topic [projects/$project/topics/$topic]"
  fi
  for ((k = 0; k < $(yq '.topics['"$j"'].subscriptions | length' <<< "$config"); k++)); do
    subscription=$(yq '.topics['"$j"'].subscriptions['"$k"'].name' <<< "$config")
    subscription_response=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H "Content-Type: application/json" \
      -d "{\"topic\": \"projects/$project/topics/$topic\"}" \
      localhost:"$port"/v1/projects/"$project"/subscriptions/"$subscription")
    if [ "$subscription_response" -eq 200 ]; then
      logger "Subscription [projects/$project/subscriptions/$subscription] created successfully"
    else
      logger "Error creating subscription [projects/$project/subscriptions/$subscription]"
    fi
  done
done