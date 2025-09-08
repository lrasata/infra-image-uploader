# Image uploader infrastructure - managed with Terraform on AWS

> Status : under construction 🚧


<img src="docs/upload-image-infra.png" alt="image-uploader-infrastructure">

## TODO

- [x] Clean up permissions in terraform-user
- [x] ~~Set up AWS event bridge + virus scan~~
  - [ ] You should be using GuardDuty - it uses ec2 malware scan. --> test this after destroying it looks like inspector2 is triggerd only the 1st time it is up
- [ ] Set up the other lambdas - those lambdas should only treat files from clean bucket ** this should trigger GuardDuty when attempting to manipulate corrupted file ?!?


- [ ] The frontend (which is actually the Cloudfront distribution) should provide a  `x-custom-auth` and only treated by the lambda only if correct (same as for the locations API) (how do you link this with existing infrastructure ?) --> look at the python code to know how to upload this. ideally the name of the file should not cause any issue

- [ ] Actually you should be using S3 transfer acceleration feature Enabled because wherever the user might be in the world vs eu-central-1, this data upload performance can be really bad. But how does that work with the presigned url ? because there is a specific endpoint to use s3-accelerate...com to use