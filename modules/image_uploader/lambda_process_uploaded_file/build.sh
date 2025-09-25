#!/bin/bash
set -euo pipefail

# Go into the Lambda code directory
cd "$(dirname "$0")"

# Run inside AWS Lambda Node.js 20 image so native deps (sharp) build correctly
docker run --rm \
  -v "$PWD:/var/task" \
  -w /var/task" \
  public.ecr.aws/lambda/nodejs:20 \
  /bin/bash -c "npm ci && npm install sharp aws-sdk"
