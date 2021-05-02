# FFmpeg-AWS-Lambda-Layer Example

## What is it?
This is a sample project demonstrating how to use the Lambda Layer deployed by this repository.

## What does it do?
The example will deploy an upload bucket, a results bucket and a sample Lambda Function making use of FFmpeg to create an image thumbnail. The Lambda Function is invoked asynchrnously whenever an object is uploaded to the input bucket. When invoked, the function will make use of FFmpeg in a child process to create the thumbnail. Finally, the function will upload the resulting thumbnail to the result bucket.

## How to deploy it?
```
make deploy
```

## How to use it?
Upload an image file to the Upload Bucket, wait a bit, then retrieve your thumbnail in the Result Bucket.