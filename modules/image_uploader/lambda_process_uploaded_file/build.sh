#!/bin/bash
set -e

cd "$(dirname "$0")"

docker run --rm \
  -v "$PWD:/var/task" \
  -w /var/task \
  public.ecr.aws/lambda/nodejs:20 \
  /bin/bash -c "npm ci && npm install sharp aws-sdk"
