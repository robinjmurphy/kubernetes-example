#! /bin/bash

if [[ -z "$1" ]]; then
  echo "Usage: sh load.sh <service>"
  exit 1
fi

URL=$(minikube service $1 --url)

while true; do
  curl $URL --max-time 1
  sleep 0.5
done
