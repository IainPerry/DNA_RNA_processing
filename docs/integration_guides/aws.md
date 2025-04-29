# DNA_RNA_processing on AWS
This guide aims to suggest how to run the main script on Amazon Web Service AWS (EC2 instance) from scratch.
No prior knowledge of AWS should be necessary but several steps can be skipped with experience.
+ Create AWS account
+ Launch and configure EC2 server
+ Set up the environment
+ Upload data
+ Run the script
+ Download results

## Prerequisites
+ It is highly advised a medium to high level of linux command line knowledge
+ A terminal with ssh and scp enabled

## Setup AWS account
1. Sign up for an AWS [account](https://signin.aws.amazon.com/signup?request_type=register).
2. You'll need to provide details of ID and payment.
3. Choose a tier you can budget for, free, or paid.

## Launch instance Option 1 ParallelCluster with SLURM
1. Install prerequisites
   1. [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
   2. [Install AWS ParallelCluster CLI](https://docs.aws.amazon.com/parallelcluster/latest/ug/install-v3.html)
   3. [Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
2. Locally run `aws configure`
3. Create an SSH key pair `ssh-keygen -t rsa -f ~/.ssh/your-key-name`
4. Create config file, see example config.

```
Region: Europe 
Image:
    Os: ubuntu2004

HeadNode:
  InstanceType: t3.medium
  Ssh:
    KeyName: your-key-name
  Networking:
    SubnetId: subnet-xxxxxxxx
  LocalStorage:
    RootVolume:
      Size: 100

Scheduling:
  Scheduler: slurm
  SlurmQueues:
    - Name: compute
      ComputeResources:
        - Name: c5n_large
          InstanceType: c5n.large
          MinCount: 0
          MaxCount: 4
      Networking:
        SubnetIds:
          - subnet-xxxxxxxx

SharedStorage:
  - MountDir: /shared
    Name: shared
    StorageType: Ebs
    EbsSettings:
      VolumeSize: 150

ClusterName: my-genomics-cluster
```
