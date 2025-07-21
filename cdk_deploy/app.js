#!/usr/bin/env node

const { App } = require('aws-cdk-lib');
const { CPDocusealStack } = require('./lib/cp-docuseal-stack');
const fs = require('fs');

const app = new App();

const userDataScript = fs.readFileSync('./userdata.txt', 'utf8');

// Get staging number from context if provided
const stagingNumber = app.node.tryGetContext('stagingNumber');

// Function to get certificate ARN based on staging number
function getStagingCertificateArn(stagingNumber) {
  if (!stagingNumber) {
    // Default certificate for staging when no staging number is provided
    return 'arn:aws:acm:us-east-1:788066832395:certificate/5b1f59b9-ab27-4056-a5e2-0d89554e5f35';
  }

  const num = parseInt(stagingNumber);

  if (num >= 1 && num <= 11) {
    return 'arn:aws:acm:us-east-1:788066832395:certificate/d3ae2320-6da3-4a6f-a3d9-0f00f85033cb';
  } else if (num >= 12 && num <= 22) {
    return 'arn:aws:acm:us-east-1:788066832395:certificate/5b1f59b9-ab27-4056-a5e2-0d89554e5f35';
  } else if (num >= 23 && num <= 24) {
    return 'arn:aws:acm:us-east-1:788066832395:certificate/69a8fe61-f12f-4251-9e55-d68c21553388';
  } else if (num >= 25 && num <= 27) {
    return 'arn:aws:acm:us-east-1:788066832395:certificate/3ce231d1-b2ec-4013-80db-b231db5a1e02';
  } else {
    // Default certificate for staging numbers outside defined ranges
    return 'arn:aws:acm:us-east-1:788066832395:certificate/5b1f59b9-ab27-4056-a5e2-0d89554e5f35';
  }
}

// Environment configurations
const environments = {
  dev: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    vpcId: 'vpc-95c19df2',
    publicSubnetIds: ['subnet-ff02dbb6', 'subnet-69fe1132', 'subnet-cb8e63f7' ],
    instanceCount: 1,
    instanceSize: 'SMALL',
    cpu: 512,
    memory: 1024,
    securityGroupIds: ["sg-0f0da2fa2d6088742", "sg-006e8df67aec60469"],
    userDataScript: userDataScript,
    certificateArn: 'arn:aws:acm:us-east-1:788066832395:certificate/5b1f59b9-ab27-4056-a5e2-0d89554e5f35',
  },
  staging: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
    vpcId: 'vpc-95c19df2',
    publicSubnetIds: ['subnet-ff02dbb6', 'subnet-69fe1132', 'subnet-cb8e63f7'],
    instanceCount: 1,
    instanceSize: 'SMALL',
    apiCpu: 512,
    apiMemory: 1024,
    securityGroupIds: ["sg-0f0da2fa2d6088742", "sg-006e8df67aec60469"],
    userDataScript: userDataScript,
    certificateArn: getStagingCertificateArn(stagingNumber),
  },
  // production: {
  //   account: process.env.CDK_DEFAULT_ACCOUNT,
  //   region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  //   vpcId: 'vpc-95c19df2',
  //   publicSubnetIds: ['subnet-ff02dbb6', 'subnet-69fe1132', 'subnet-cb8e63f7' ],
  //   instanceCount: 2,
  //   instanceSize: 'LARGE',
  //   apiCpu: 900,
  //   apiMemory: 3000,
  //   sidekiqCpu: 900,
  //   sidekiqMemory: 3000,
  //   securityGroupIds: ["sg-09fa17711757036e6", "sg-006e8df67aec60469"],
  //   userDataScript: userDataScript,
  //   certificateArn: 'arn:aws:acm:us-east-1:788066832395:certificate/05fa2bb8-5589-4425-9f28-427f1082a64b',
  // }
};

// Create stacks for each environment
Object.entries(environments).forEach(([envName, config]) => {
  // Construct stack name with staging number if provided
  let stackName = `CPDocusealStack-${envName}`;
  let environmentName = envName;

  // Append staging number for staging environments
  if (envName === 'staging' && stagingNumber) {
    stackName += `-${stagingNumber}`;
    environmentName += `-${stagingNumber}`;
  }

  new CPDocusealStack(app, stackName, {
    env: {
      account: config.account,
      region: config.region
    },
    environment: envName,
    vpcConfig: {
      vpcId: config.vpcId,
      publicSubnetIds: config.publicSubnetIds
    },
    ecsConfig: config,
    certificateArn: config.certificateArn,
    securityGroupIds: config.securityGroupIds,
    userDataScript: config.userDataScript
  });
}); 
