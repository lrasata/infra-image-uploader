# How to build `sharp`

`sharp` is used in the Lambda function which process files after they are uploaded in S3 bucket. It is use to generate thumbnail of uplaoded images.

See in folder : `lambda_process_uploaded_file\processUploadedFile.js`

## On Linux or MacOS
Execute  the following command locally in the root folder : `cd infra-image-uploader`

```txt
commands to be provided in here
```

## On Windows

Execute  the following command locally in the root folder : `cd infra-image-uploader`

### Run an Amazon Linux container

`docker run -it --rm -v ${PWD}:/var/task amazonlinux:2023 bash`

### Inside container

```txt
dnf install -y nodejs npm make gcc-c++ libpng-devel

cd /var/task/lambda_process_uploaded_file
npm install sharp

exit
```

At this point you should have `node_modules` folder generated inside `lambda_process_uploaded_file` which has been generated on the docker container.
