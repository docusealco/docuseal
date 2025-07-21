const {
  Stack,
  Duration,
  aws_ec2: ec2,
  aws_ecs: ecs,
  aws_elasticloadbalancingv2: elbv2,
  aws_logs: logs,
  aws_iam: iam,
  aws_ecr: ecr,
  aws_secretsmanager: secretsmanager,
  aws_certificatemanager: acm,
  aws_route53: route53,
  aws_route53_targets: targets,
  Aspects,
  RemovalPolicy
} = require('aws-cdk-lib');
const { Construct } = require('constructs');

class CPDocusealStack extends Stack {
  constructor(scope, id, props) {
    super(scope, id, props);

    const { environment, vpcConfig, ecsConfig, securityGroupIds, userDataScript } = props;
    
    // Get the image tag from CDK context, default to 'latest' if not provided
    const imageTag = this.node.tryGetContext('imageTag') || 'latest';
    const stagingNumber = this.node.tryGetContext('stagingNumber') || null;
    const envDescription = stagingNumber ? `${environment}-${stagingNumber}` : environment;

    // Import existing VPC
    const vpc = ec2.Vpc.fromLookup(this, 'VPC', {
      vpcId: vpcConfig.vpcId
    });

    // Import existing subnets
    const publicSubnets = vpcConfig.publicSubnetIds.map((subnetId, index) =>
      ec2.Subnet.fromSubnetId(this, `PublicSubnet${index}`, subnetId)
    );

    // Security Group for ALB
    const albSecurityGroup = new ec2.SecurityGroup(this, 'ALBSecurityGroup', {
      vpc,
      description: `ALB Security Group for ${envDescription}`,
      allowAllOutbound: true
    });

    // we may not need this...
    albSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'Allow HTTP traffic'
    );

    albSecurityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(443),
      'Allow HTTPS traffic'
    );

    // Security Group for ECS Tasks
    const ecsSecurityGroup = new ec2.SecurityGroup(this, 'ECSSecurityGroup', {
      vpc,
      description: `ECS Security Group for ${envDescription}`,
      allowAllOutbound: true
    });

    ecsSecurityGroup.addIngressRule(
      albSecurityGroup,
      ec2.Port.tcp(3001),
      'Allow traffic from ALB'
    );

    // Internal Application Load Balancer
    const alb = new elbv2.ApplicationLoadBalancer(this, 'InternalALB', {
      vpc,
      internetFacing: true,
      vpcSubnets: {
        subnets: publicSubnets
      },
      securityGroup: albSecurityGroup,
      loadBalancerName: `cpd-alb-${envDescription}`
    });

    // Target Group for ECS Service
    const targetGroup = new elbv2.ApplicationTargetGroup(this, 'ECSTargetGroup', {
      vpc,
      port: 3001,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targetType: elbv2.TargetType.INSTANCE,
      healthCheck: {
        enabled: true,
        healthyHttpCodes: '200',
        path: '/up',
        protocol: elbv2.Protocol.HTTP,
        interval: Duration.seconds(30),
        timeout: Duration.seconds(5),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 5
      },
      deregistrationDelay: Duration.seconds(20),
      targetGroupName: `cpd-tg-${envDescription}`
    });

    // ALB Listener
    const listener = alb.addListener('ALBListener', {
      port: 80,
      protocol: elbv2.ApplicationProtocol.HTTP,
      defaultTargetGroups: [targetGroup]
    });

    // Accept certificateArn as input (default to provided value if not in props)
    const certificateArn = props.certificateArn || 'arn:aws:acm:us-east-1:788066832395:certificate/05fa2bb8-5589-4425-9f28-427f1082a64b';

    // Add HTTPS Listener with ACM certificate
    const certificate = acm.Certificate.fromCertificateArn(this, 'ALBCertificate', certificateArn);
    alb.addListener('ALBListenerHTTPS', {
      port: 443,
      protocol: elbv2.ApplicationProtocol.HTTPS,
      certificates: [certificate],
      defaultTargetGroups: [targetGroup]
    });

    // Create Route53 A record for staging and production environments
    let hostedZoneDomain = null;
    
    if (environment === 'staging' && stagingNumber) {
      hostedZoneDomain = `cpstaging${stagingNumber}.name`;
    // } else if (environment === 'production') {
    //   hostedZoneDomain = 'careerplug.com';
    }

    if (hostedZoneDomain) {
      const recordName = 'cpd';

      // Import the existing hosted zone
      const hostedZone = route53.HostedZone.fromLookup(this, 'HostedZone', {
        domainName: hostedZoneDomain
      });

      // Create A record pointing to ALB
      new route53.ARecord(this, 'ALBARecord', {
        zone: hostedZone,
        recordName: recordName,
        target: route53.RecordTarget.fromAlias(new targets.LoadBalancerTarget(alb)),
        ttl: Duration.minutes(1),
        comment: `A record for CP Docuseal ${envDescription}`
      });
    }

    // ECS Cluster
    const cluster = new ecs.Cluster(this, 'ECSCluster', {
      vpc,
      clusterName: `cp-docuseal-${envDescription}`,
      containerInsightsV2: ecs.ContainerInsights.ENABLED
    });

    // Determine instance size based on configuration
    const instanceSize = ecsConfig.instanceSize || 'SMALL';
    
    // Import additional existing security groups by ID from props
    const importedSecurityGroups = (securityGroupIds || []).map((sgId, idx) =>
      ec2.SecurityGroup.fromSecurityGroupId(this, `ImportedSG${idx + 1}`, sgId)
    );

    // Auto Scaling Group for ECS with ARM64 instances
    const autoScalingGroup = cluster.addCapacity('ECSAutoScalingGroup', {
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize[instanceSize]), // ARM64
      machineImage: ecs.EcsOptimizedImage.amazonLinux2(ecs.AmiHardwareType.ARM),
      minCapacity: ecsConfig.instanceCount,
      maxCapacity: ecsConfig.instanceCount,
      vpcSubnets: {
        subnets: publicSubnets
      }
    });

    // Attach imported security groups to the EC2 instances
    importedSecurityGroups.forEach((sg, idx) => {
      autoScalingGroup.addSecurityGroup(sg);
    });

    // Add security group rule to EC2 instances for HOST network mode
    // Allow ALB to reach containers on port 3001
    autoScalingGroup.addSecurityGroup(ecsSecurityGroup);

    if (userDataScript) {
      autoScalingGroup.addUserData(userDataScript);
    }

    // CloudWatch Log Groups
    const apiLogGroup = new logs.LogGroup(this, 'APILogGroup', {
      logGroupName: `/ecs/cp-docuseal-api-${envDescription}`,
      retention: logs.RetentionDays.ONE_WEEK
    });
    apiLogGroup.applyRemovalPolicy(RemovalPolicy.DESTROY);

    // const sidekiqLogGroup = new logs.LogGroup(this, 'SidekiqLogGroup', {
    //   logGroupName: `/ecs/cp-docuseal-sidekiq-${envDescription}`,
    //   retention: logs.RetentionDays.ONE_WEEK
    // });
    // sidekiqLogGroup.applyRemovalPolicy(RemovalPolicy.DESTROY);

    // Import ECR Repository
    const ecrRepository = ecr.Repository.fromRepositoryName(
      this,
      'ECRRepository',
      'cp-docuseal'
    );

    // Task Definition
    const taskDefinition = new ecs.Ec2TaskDefinition(this, 'TaskDefinition', {
      family: `cp-docuseal-task-${envDescription}`,
      networkMode: ecs.NetworkMode.HOST
    });

    // Base environment variables
    const containerEnvironment = {
      NODE_ENV: environment,
      PORT: '3001',
      RAILS_ENV: environment
    };

    // Add environment-specific variables
    if (environment === 'staging') { // || environment === 'production') {
      // For staging and production, we'll use Secrets Manager
      containerEnvironment.AWS_REGION = this.region;
      // Map production environment to prod for secret naming
      const secretEnvironment = environment; // === 'production' ? 'prod' : environment;
      containerEnvironment.DB_SECRETS_NAME = `${secretEnvironment}/db_creds`;

      // set DB name
      containerEnvironment.DB_NAME = `cpdocuseal${stagingNumber ? `${stagingNumber}` : ''}`;
    }

    // Check if we need multi-container setup (staging and production)
    const isMultiContainer = environment === 'staging'; // || environment === 'production';

    if (isMultiContainer) {
      // API Container Definition
      const apiContainerConfig = {
        image: ecs.ContainerImage.fromEcrRepository(ecrRepository, imageTag),
        cpu: ecsConfig.apiCpu,
        memoryLimitMiB: ecsConfig.apiMemory,
        essential: true,
        logging: ecs.LogDrivers.awsLogs({
          streamPrefix: 'api',
          logGroup: apiLogGroup
        }),
        environment: containerEnvironment,
        healthCheck: {
          command: ['CMD-SHELL', 'curl -f http://localhost:3001/up || exit 1'],
          interval: Duration.seconds(30),
          timeout: Duration.seconds(5),
          retries: 3,
          startPeriod: Duration.seconds(60)
        }
      };

      // Set the appropriate startup script for staging and production
      if (environment === 'staging') {
        apiContainerConfig.command = ['./bin/start_staging', 'api'];
      }
      // } else if (environment === 'production') {
      //   apiContainerConfig.command = ['./bin/start_production', 'api'];
      // }

      const apiContainer = taskDefinition.addContainer('APIContainer', apiContainerConfig);
      
      // Add port mapping for HOST network mode
      apiContainer.addPortMappings({
        containerPort: 3001,
        protocol: ecs.Protocol.TCP
      });

      // Sidekiq Container Definition
      // const sidekiqContainerConfig = {
      //   image: ecs.ContainerImage.fromEcrRepository(ecrRepository, imageTag),
      //   cpu: ecsConfig.sidekiqCpu,
      //   memoryLimitMiB: ecsConfig.sidekiqMemory,
      //   essential: true,
      //   logging: ecs.LogDrivers.awsLogs({
      //     streamPrefix: 'sidekiq',
      //     logGroup: sidekiqLogGroup
      //   }),
      //   environment: containerEnvironment,
      // };

      // Set the appropriate startup script for staging and production
      // if (environment === 'staging') {
      //   sidekiqContainerConfig.command = ['./bin/start_staging', 'sidekiq'];
      // } else if (environment === 'production') {
      //   sidekiqContainerConfig.command = ['./bin/start_production', 'sidekiq'];
      // }

      // const sidekiqContainer = taskDefinition.addContainer('SidekiqContainer', sidekiqContainerConfig);

      // // Make Sidekiq container depend on API container
      // sidekiqContainer.addContainerDependencies({
      //   container: apiContainer,
      //   condition: ecs.ContainerDependencyCondition.HEALTHY
      // });

    } else {
      // Single container setup for dev environment
      const containerConfig = {
        image: ecs.ContainerImage.fromEcrRepository(ecrRepository, imageTag),
        cpu: ecsConfig.cpu,
        memoryLimitMiB: ecsConfig.memory,
        essential: true,
        logging: ecs.LogDrivers.awsLogs({
          streamPrefix: 'ecs',
          logGroup: apiLogGroup
        }),
        environment: containerEnvironment
      };

      const container = taskDefinition.addContainer('CPDocusealContainer', containerConfig);
      
      // Add port mapping for HOST network mode
      container.addPortMappings({
        containerPort: 3001,
        protocol: ecs.Protocol.TCP
      });
    }

    // ECS Service
    const service = new ecs.Ec2Service(this, 'ECSService', {
      cluster,
      taskDefinition,
      serviceName: `cp-docuseal-service-${envDescription}`,
      desiredCount: ecsConfig.instanceCount,
      deploymentConfiguration: {
        maximumPercent: 200,
        minimumHealthyPercent: 50
      },
      enableExecuteCommand: true // For debugging
      // vpcSubnets and securityGroups removed - HOST network mode uses EC2 instance network configuration
    });

    // Attach the service to the target group
    service.attachToApplicationTargetGroup(targetGroup);

    // Task Role for CloudWatch logging and ECR access
    taskDefinition.taskRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy')
    );

    // Add Secrets Manager permissions for staging and production environments
    if (environment === 'staging') { // || environment === 'production') {
      // Map production environment to prod for secret naming
      const secretEnvironment = environment; // === 'production' ? 'prod' : environment;
      const secretsManagerPolicy = new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          'secretsmanager:GetSecretValue',
          'secretsmanager:DescribeSecret'
        ],
        resources: [
          `arn:aws:secretsmanager:${this.region}:${this.account}:secret:${secretEnvironment}/db_creds*`,
          // `arn:aws:secretsmanager:${this.region}:${this.account}:secret:integration_station/encryption_key*`
        ]
      });

      taskDefinition.taskRole.addToPolicy(secretsManagerPolicy);
    }

    // Output important values
    this.albDnsName = alb.loadBalancerDnsName;
    this.clusterName = cluster.clusterName;
    this.serviceName = service.serviceName;

    // Output Route53 record name for environments that create DNS records
    if (hostedZoneDomain) {
      if (environment === 'staging' && stagingNumber) {
        this.route53RecordName = `cpd.cpstaging${stagingNumber}.name`;
      // } else if (environment === 'production') {
      //   this.route53RecordName = 'cpd.careerplug.com';
      }
    }
  }
}

module.exports = { CPDocusealStack }; 
