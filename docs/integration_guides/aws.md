# DNA_RNA_processing on AWS
This guide aims to suggest how to run the main script on Amazon Web Service AWS (EC2 instance) from scratch.
No prior knowledge of AWS should be necessary but several steps can be skipped with experience.
+ Create AWS account
+ Launch and configure EC2 server
+ Set up the environment
+ Upload data
+ Run the script
+ Download results

### Prerequisites
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

5. Launch the cluster `pcluster create-cluster --cluster-name my-genomics-cluster --cluster-configuration pcluster-config.yaml`
6. Connect to the cluster `pcluster ssh --cluster-name my-genomics-cluster -i ~/.ssh/your-key-name.pem`

## Launch instance Option 2 EC2:
1. Go to the AWS management console and search for EC2 and click launch
2. Pick a preferred OS, such as Ubuntu 22.04 LTS
3. Choose an instance type:
   +  Large-scale genomics e.g. r6i.sxlarge (64GB RAM, 8vCPUs)
   +  Small-scale testing e.g. t3.medium (4GB RAM, 2 vCPUs)
4. Create a security key pair (RSA) and download the `.pem` file
5. Add storage. A rough rule of thumb example (6 samples, each 5GB forward and reverse Fastqs = 35GB. Mapped doubles to 70GB. + Containers, intermediary files... 150GB)
6. Set security settings
   + Allow for SSH (port 22)
   + You could allow HTTPS to host web outputs like MultiQC reports
7. Hit launch

## Connect to your sever
1. Launch your local terminal (I use MobaXterm normally)
2. Set up a working directory and move your `.pem` file into it.
3. `chmod 400 your-key.pem`
4. `ssh -i your-key.pem ubuntu@<YOUR-EC2-PUBLIC-IP>` (You may choose to save this as a session)

## Set up the environment
1. Check the environment on login. Where you are. Familiarise yourself.
2. `sudo apt update && sudo apt upgrade -y`
3. `sudo apt install -y build-essential libseccomp-dev pkg-config squashfs-tools cryptsetup curl wget unzip git`
4. Install singularity
   1. `export VERSION=3.8.5`
   2. `wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz`
   3. `tar -xzf singularity-ce-${VERSION}.tar.gz`
   4. `cd singularity-ce-${VERSION}`
   5. `./mconfig && make -C builddir && sudo make -C builddir install`
   6. `singularity --version`
5. Upload input data option 2.
   1. `scp -i your-key.pem samples_names.txt ubuntu@<EC2-IP>:~/`
   2. `scp -i your-key.pem -r Inputs/ ubuntu@<EC2-IP>:~/`
6.  Upload input data option 2:
   1. Use AWS's S3 for large datasets.
   2. First install locally
   3. `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"`
   4. `unzip awscliv2.zip && sudo ./aws/install`
   5. `aws configure`
   6. `aws s3 cp  ~/Inputs/ s3://your-bucket-name/Inputs/ --recursive`
7. Setup SIFS
   1. You may choose to clone the repository `git clone https://github.com/IainPerry/DNA_RNA_processing.git`
   2. Then modify, check, and run make_sifs.sh
   3. Alternitively `mkdir -p SIFS` and build/upload your own containers
8. Setup the script
   1. Make the DNA_RNA_processing.sh script executable `chmod +x DNA_RNA_processing.sh`
   2. Make any necessary changes to options and variables.
  
## Modify script for SLURM
As SLURM is not used on EC2 by default. If you want to use ParellelCluster. It uses EC2 "under the hood" but has SLURM running.
You can define your cluster in `pcluster-config.yaml`. The script should need fewer changes then.

If you chose EC2, you'll need to change the script to run without SLURM. See the example section of code for the trimming stage.

```
WAITFOR=":1"
if [ "$SKIPQCTRIM" = "TRUE" ]; then
    echo "$(date '+%F %T') - Skipping Trimming" >> $log_file
else
    for i in $SamplesRaw; do
        echo "$(date '+%F %T') - Starting trimming job ${i}" >> $log_file

        if [ "$RUNTYPE" = "PE" ]; then
            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTP_SIF fastp \
                --in1 $TMP/${i}_M_F.fq.gz \
                --in2 $TMP/${i}_M_R.fq.gz \
                --out1 $TRIM/${i}_trimmed_F.fq.gz \
                --out2 $TRIM/${i}_trimmed_R.fq.gz \
                --thread 2 \
                -h $LOGS/trim/${i}_fastp.html \
                -j $LOGS/trim/${i}_fastp.json \
                2> "$LOGS/trim/${i}_trim.err" \
                > "$LOGS/trim/${i}_trim.out"
        else
            singularity exec --bind $Base/:$Base/ --bind $SIF_DIR/:$SIF_DIR/ $FASTP_SIF fastp \
                --in1 $TMP/${i}_M_F.fq.gz \
                --out1 $TRIM/${i}_trimmed_F.fq.gz \
                --thread 2 \
                -h $LOGS/trim/${i}_fastp.html \
                -j $LOGS/trim/${i}_fastp.json \
                2> "$LOGS/trim/${i}_trim.err" \
                > "$LOGS/trim/${i}_trim.out"
        fi

    done
fi
```

## Run
If you're happy with the modified script for EC2 or have set up ParallelCluster and configured everything. Run.

## Download and shutdown
1. Locally run `scp -i your-key.pem -r ubuntu@<EC2-IP>:~/VCF/ ./Results/`
2. Go to your AWS EC2 dashboard, instances, select, actions, terminate. OR carry on if you plan on using this continually.
