# How to build `sharp` for Lambda on Windows

Execute  the following command locally in the root folder : `cd infra-image-uploader`

## Run an Amazon Linux container

`docker run -it --rm -v ${PWD}:/var/task amazonlinux:2023 bash`

## Inside container

```txt
dnf install -y nodejs npm make gcc-c++ libpng-devel

cd /var/task/lambda_node
npm install sharp

exit
```

At this point you should have `node_modules` folder generated inside `lambda_node` which has been generated on the docker container.
