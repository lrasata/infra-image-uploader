# Image uploader infrastructure - managed with Terraform on AWS

> Status : under construction 🚧


<img src="docs/upload-image-infra.png" alt="image-uploader-infrastructure">

## Features to implement

- [ ] Integrate antivirus - prevent malware to end up in s3 bukcet on upload.
- [ ] Save information related to user and linked images in Dynamo DB
- [ ] Enable S3 transfer acceleration feature for uploads ?
- [ ] Make this settings as a module to be easily integrated in other terraform projects.