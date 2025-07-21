# CP Docuseal CDK Infrastructure

This directory contains AWS CDK v2 infrastructure code for deploying the CP Docuseal app. At present it only deploys to development and staging; production will follow.

## Architecture Overview

This infrastructure is basically nicked wholesale from the Integration Station application, just dialed down a notch as our needs are a bit less than theirs.

- **Internal Application Load Balancer (ALB)** - Routes traffic to ECS services within the VPC
- **Amazon ECS Cluster** - Runs containerized applications on EC2 instances (ARM64 t4g.small)
- **ECS Service** - Manages container deployment and scaling
- **ECS Task Definition** - Defines container configuration and resource requirements
- **CloudWatch Logging** - Centralized logging for application monitoring
- **Security Groups** - Network security controls
- **ECR Integration** - Uses existing "integration-station" ECR repository

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Node.js** (version 22 or later)
3. **AWS CDK v2** installed globally: `npm install -g aws-cdk`
4. **Existing AWS Infrastructure**:
   - VPC with public and private subnets
   - ECR repository named "cp-docuseal"
   - Appropriate IAM permissions for CDK deployment

## Setup

1. **Install dependencies**:
   ```bash
   cd cdk_deploy
   npm install
   ```

2. **Bootstrap CDK** (application setup ONLY):
   ```bash
   npm run bootstrap
   ```

3. **Update VPC and Subnet IDs**:
   Edit `app.js` and replace the placeholder IDs with your actual VPC and subnet IDs:
   ```javascript
   vpcId: 'vpc-your-actual-vpc-id',
   privateSubnetIds: ['subnet-your-private-1', 'subnet-your-private-2'],
   publicSubnetIds: ['subnet-your-public-1', 'subnet-your-public-2']
   ```

## Environment Configuration

The infrastructure supports three environments with different resource allocations:

### Development
- **Instances**: 1 ECS instance
- **CPU**: 512 units
- **Memory**: 1024 MB

### Staging
- **Instances**: 1 ECS instance
- **CPU**: 512 units
- **Memory**: 1024 MB

### Production
- N/A


## Deployment

### Deploy to Development
```bash
npm run deploy:dev
```

### Deploy to Staging
```bash
npm run deploy:staging
```

### Deploy to Production - NOT YET SUPPORTED
```bash
npm run deploy:prod
```

### View CloudFormation Template
```bash
npm run synth
```

### Compare Changes
```bash
npm run diff
```

## Cleanup

### Destroy Development Environment
```bash
npm run destroy:dev
```

### Destroy Staging Environment
```bash
npm run destroy:staging
```

### Destroy Production Environment - NOT YET SUPPORTED
```bash
npm run destroy:prod
```

## Important Notes

1. **Internal ALB**: The Application Load Balancer is configured as internal-only and deployed in private subnets for security.

2. **ARM64 Instances**: The ECS cluster uses t4g.small ARM64 instances for cost efficiency. Ensure your container images are built for ARM64 architecture.

3. **Health Checks**: The ALB target group is configured to perform health checks on `/health` endpoint. Make sure your application responds to this endpoint.

4. **Logging**: All ECS tasks automatically log to CloudWatch under `/ecs/cp-docuseal-{environment}` log groups.

5. **Security**: Security groups are configured to allow:
   - ALB: HTTP (80) and HTTPS (443) traffic
   - ECS: Traffic from ALB on port 3000

## Troubleshooting

1. **VPC Lookup Issues**: Ensure the VPC IDs and subnet IDs in `app.js` are correct and exist in your AWS account.

2. **ECR Repository**: Verify that the "cp-docuseal" ECR repository exists and contains the required Docker images.

3. **Permissions**: Ensure your AWS credentials have sufficient permissions for:
   - EC2 (VPC, Security Groups, Launch Templates)
   - ECS (Clusters, Services, Tasks)
   - ELB (Application Load Balancers, Target Groups)
   - CloudWatch (Log Groups)
   - IAM (Roles and Policies)

4. **Container Health**: If services fail to start, check CloudWatch logs for container startup issues.

## Customization

You can modify the following aspects:

- **Instance Types**: Change `ec2.InstanceClass.T4G` and `ec2.InstanceSize.SMALL` in the stack
- **Container Port**: Update port mappings if your application uses a different port
- **Resource Limits**: Adjust CPU and memory allocations in the environment configurations
- **Auto Scaling**: Modify `minCapacity` and `maxCapacity` for different scaling behaviors

## Stack Outputs

After deployment, the stack provides:
- **ALB DNS Name**: Internal DNS name for the Application Load Balancer
- **ECS Cluster Name**: Name of the created ECS cluster
- **ECS Service Name**: Name of the ECS service 
