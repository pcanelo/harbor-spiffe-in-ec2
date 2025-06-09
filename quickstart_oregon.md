# Quickstart: Harbor Deployment Resources in AWS (Oregon)

This guide provides step-by-step AWS CLI commands to deploy the basic infrastructure for Harbor in the **us-west-2** (Oregon) region. A helper script [`setup_harbor_resources.sh`](setup_harbor_resources.sh) is included to automate the process.

## Steps Covered
1. Create a VPC and subnet
2. Create a security group
3. Launch an EC2 instance named `Harbor_Server`
4. Create an S3 bucket `harbor_s3`
5. Create an IAM role and policy so the EC2 instance can read/write to the bucket

Run the script:

```bash
./setup_harbor_resources.sh
```

The script prints the IDs of the created resources and associates the IAM instance profile with the EC2 instance.
