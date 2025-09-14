# How to build `sharp`

`sharp` is used in the Lambda function which process files after they are uploaded in S3 bucket. It is use to generate thumbnail of uplaoded images.

See in folder: `modules\image_uploader\lambda_process_uploaded_file\processUploadedFile.js`

## On Linux or MacOS

Please refer to [the official documentation](https://www.npmjs.com/package/sharp)

Execute commands locally in the folder : `cd infra-image-uploader\modules\image_uploader\lambda_process_uploaded_file`

## On Windows

Execute  the following commands locally in the folder : `cd infra-image-uploader\modules\image_uploader`

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
