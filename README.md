# Image uploader infrastructure - managed with Terraform on AWS

> Status : under construction 🚧

## Overview

<img src="docs/upload-image-infra.png" alt="image-uploader-infrastructure">

## Key attributes

**Maintainability**

- 
- 

**Reliability**

- 
- 

**Scalability**

- 
- 

**Security**

- 
- 

## 🔍 Gotchas -  Lessons learned

## Features to implement

- [] Integrate antivirus - prevent malware to end up in s3 bucket on upload.
  - [x] Tested BucketAV on AWS Console
  - [x] Integrate with Tearrform + Lambda should subscribe to SNS Topic when file is clean to process it.
  - [ ] Create BucketAV from cloudformation automatically in Terraform
  - [ ] check why file is scanned many times when running pythin script
- [x] Enable S3 transfer acceleration feature for uploads ?
- [ ] Make this settings as a module to be easily integrated in other terraform projects.