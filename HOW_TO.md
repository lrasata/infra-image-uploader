# How to build sharp for Lambda on Windows

# Run an Amazon Linux container
docker run -it --rm -v ${PWD}:/var/task amazonlinux:2023 bash

# Inside container:
dnf install -y nodejs npm make gcc-c++ libpng-devel

cd /var/task/lambda_node
npm install sharp

exit