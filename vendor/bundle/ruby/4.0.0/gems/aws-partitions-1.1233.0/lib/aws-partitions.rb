# frozen_string_literal: true

require_relative 'aws-partitions/endpoint_provider'
require_relative 'aws-partitions/partition'
require_relative 'aws-partitions/partition_list'
require_relative 'aws-partitions/region'
require_relative 'aws-partitions/service'
require_relative 'aws-partitions/metadata'

require 'json'

module Aws

  # A {Partition} is a group of AWS {Region} and {Service} objects. You
  # can use a partition to determine what services are available in a region,
  # or what regions a service is available in.
  #
  # ## Partitions
  #
  # **AWS accounts are scoped to a single partition**. You can get a partition
  # by name. Valid partition names include:
  #
  # * `"aws"` - Public AWS partition
  # * `"aws-cn"` - AWS China
  # * `"aws-us-gov"` - AWS GovCloud
  #
  # To get a partition by name:
  #
  #     aws = Aws::Partitions.partition('aws')
  #
  # You can also enumerate all partitions:
  #
  #     Aws::Partitions.each do |partition|
  #       puts partition.name
  #     end
  #
  # ## Regions
  #
  # A {Partition} is divided up into one or more regions. For example, the
  # "aws" partition contains, "us-east-1", "us-west-1", etc. You can get
  # a region by name. Calling {Partition#region} will return an instance
  # of {Region}.
  #
  #     region = Aws::Partitions.partition('aws').region('us-west-2')
  #     region.name
  #     #=> "us-west-2"
  #
  # You can also enumerate all regions within a partition:
  #
  #     Aws::Partitions.partition('aws').regions.each do |region|
  #       puts region.name
  #     end
  #
  # Each {Region} object has a name, description and a list of services
  # available to that region:
  #
  #     us_west_2 = Aws::Partitions.partition('aws').region('us-west-2')
  #
  #     us_west_2.name #=> "us-west-2"
  #     us_west_2.description #=> "US West (Oregon)"
  #     us_west_2.partition_name "aws"
  #     us_west_2.services #=> #<Set: {"APIGateway", "AutoScaling", ... }
  #
  # To know if a service is available within a region, you can call `#include?`
  # on the set of service names:
  #
  #     region.services.include?('DynamoDB') #=> true/false
  #
  # The service name should be the service's module name as used by
  # the AWS SDK for Ruby. To find the complete list of supported
  # service names, see {Partition#services}.
  #
  # Its also possible to enumerate every service for every region in
  # every partition.
  #
  #     Aws::Partitions.partitions.each do |partition|
  #       partition.regions.each do |region|
  #         region.services.each do |service_name|
  #           puts "#{partition.name} -> #{region.name} -> #{service_name}"
  #         end
  #       end
  #     end
  #
  # ## Services
  #
  # A {Partition} has a list of services available. You can get a
  # single {Service} by name:
  #
  #     Aws::Partitions.partition('aws').service('DynamoDB')
  #
  # You can also enumerate all services in a partition:
  #
  #     Aws::Partitions.partition('aws').services.each do |service|
  #       puts service.name
  #     end
  #
  # Each {Service} object has a name, and information about regions
  # that service is available in.
  #
  #     service.name #=> "DynamoDB"
  #     service.partition_name #=> "aws"
  #     service.regions #=> #<Set: {"us-east-1", "us-west-1", ... }
  #
  # Some services have multiple regions, and others have a single partition
  # wide region. For example, {Aws::IAM} has a single region in the "aws"
  # partition. The {Service#regionalized?} method indicates when this is
  # the case.
  #
  #     iam = Aws::Partitions.partition('aws').service('IAM')
  #
  #     iam.regionalized? #=> false
  #     service.partition_region #=> "aws-global"
  #
  # Its also possible to enumerate every region for every service in
  # every partition.
  #
  #     Aws::Partitions.partitions.each do |partition|
  #       partition.services.each do |service|
  #         service.regions.each do |region_name|
  #           puts "#{partition.name} -> #{region_name} -> #{service.name}"
  #         end
  #       end
  #     end
  #
  # ## Service Names
  #
  # {Service} names are those used by the the AWS SDK for Ruby. They
  # correspond to the service's module.
  #
  module Partitions

    class << self

      include Enumerable

      # @return [Enumerable<Partition>]
      def each(&block)
        default_partition_list.each(&block)
      end

      # Return the partition with the given name. A partition describes
      # the services and regions available in that partition.
      #
      #     aws = Aws::Partitions.partition('aws')
      #
      #     puts "Regions available in the aws partition:\n"
      #     aws.regions.each do |region|
      #       puts region.name
      #     end
      #
      #     puts "Services available in the aws partition:\n"
      #     aws.services.each do |services|
      #       puts services.name
      #     end
      #
      # @param [String] name The name of the partition to return.
      #   Valid names include "aws", "aws-cn", and "aws-us-gov".
      #
      # @return [Partition]
      #
      # @raise [ArgumentError] Raises an `ArgumentError` if a partition is
      #   not found with the given name. The error message contains a list
      #   of valid partition names.
      def partition(name)
        default_partition_list.partition(name)
      end

      # Returns an array with every partitions. A partition describes
      # the services and regions available in that partition.
      #
      #     Aws::Partitions.partitions.each do |partition|
      #
      #       puts "Regions available in #{partition.name}:\n"
      #       partition.regions.each do |region|
      #         puts region.name
      #       end
      #
      #       puts "Services available in #{partition.name}:\n"
      #       partition.services.each do |service|
      #         puts service.name
      #       end
      #     end
      #
      # @return [Enumerable<Partition>] Returns an enumerable of all
      #   known partitions.
      def partitions
        default_partition_list
      end

      # @param [Hash] new_partitions
      # @api private For internal use only.
      def add(new_partitions)
        new_partitions['partitions'].each do |partition|
          default_partition_list.add_partition(Partition.build(partition))
          defaults['partitions'] << partition
        end
      end

      # @param [Hash] partition_metadata
      # @api private For Internal use only
      def merge_metadata(partition_metadata)
        default_partition_list.merge_metadata(partition_metadata)
      end

      # @api private For internal use only.
      def clear
        default_partition_list.clear
        defaults['partitions'].clear
      end

      # @return [PartitionList]
      # @api private
      def default_partition_list
        @default_partition_list ||= begin
          partitions = PartitionList.build(defaults)
          partitions.merge_metadata(default_metadata)
          partitions
        end
      end

      # @return [Hash]
      # @api private
      def defaults
        @defaults ||= begin
          path = File.expand_path('../../partitions.json', __FILE__)
          defaults = JSON.parse(File.read(path), freeze: true)
          defaults.merge('partitions' => defaults['partitions'].dup)
        end
      end

      # @return [Hash]
      # @api private
      def default_metadata
        @default_metadata ||= begin
          path = File.expand_path('../../partitions-metadata.json', __FILE__)
          defaults = JSON.parse(File.read(path), freeze: true)
          defaults.merge('partitions' => defaults['partitions'].dup)
        end
      end

      # @return [Hash<String,String>] Returns a map of service module names
      #   to their id as used in the endpoints.json document.
      # @api private For internal use only.
      def service_ids
        @service_ids ||= begin
          # service ids
          {
            'ACM' => 'acm',
            'ACMPCA' => 'acm-pca',
            'AIOps' => 'aiops',
            'APIGateway' => 'apigateway',
            'ARCRegionswitch' => 'arc-region-switch',
            'ARCZonalShift' => 'arc-zonal-shift',
            'AccessAnalyzer' => 'access-analyzer',
            'Account' => 'account',
            'Amplify' => 'amplify',
            'AmplifyBackend' => 'amplifybackend',
            'AmplifyUIBuilder' => 'amplifyuibuilder',
            'ApiGatewayManagementApi' => 'execute-api',
            'ApiGatewayV2' => 'apigateway',
            'AppConfig' => 'appconfig',
            'AppConfigData' => 'appconfigdata',
            'AppFabric' => 'appfabric',
            'AppIntegrationsService' => 'app-integrations',
            'AppMesh' => 'appmesh',
            'AppRegistry' => 'servicecatalog-appregistry',
            'AppRunner' => 'apprunner',
            'AppStream' => 'appstream2',
            'AppSync' => 'appsync',
            'Appflow' => 'appflow',
            'ApplicationAutoScaling' => 'application-autoscaling',
            'ApplicationCostProfiler' => 'application-cost-profiler',
            'ApplicationDiscoveryService' => 'discovery',
            'ApplicationInsights' => 'applicationinsights',
            'ApplicationSignals' => 'application-signals',
            'Artifact' => 'artifact',
            'Athena' => 'athena',
            'AuditManager' => 'auditmanager',
            'AugmentedAIRuntime' => 'a2i-runtime.sagemaker',
            'AutoScaling' => 'autoscaling',
            'AutoScalingPlans' => 'autoscaling-plans',
            'B2bi' => 'b2bi',
            'BCMDashboards' => 'bcm-dashboards',
            'BCMDataExports' => 'bcm-data-exports',
            'BCMPricingCalculator' => 'bcm-pricing-calculator',
            'BCMRecommendedActions' => 'bcm-recommended-actions',
            'Backup' => 'backup',
            'BackupGateway' => 'backup-gateway',
            'BackupSearch' => 'backup-search',
            'Batch' => 'batch',
            'Bedrock' => 'bedrock',
            'BedrockAgent' => 'bedrock-agent',
            'BedrockAgentCore' => 'bedrock-agentcore',
            'BedrockAgentCoreControl' => 'bedrock-agentcore-control',
            'BedrockAgentRuntime' => 'bedrock-agent-runtime',
            'BedrockDataAutomation' => 'bedrock-data-automation',
            'BedrockDataAutomationRuntime' => 'bedrock-data-automation-runtime',
            'BedrockRuntime' => 'bedrock-runtime',
            'Billing' => 'billing',
            'BillingConductor' => 'billingconductor',
            'Braket' => 'braket',
            'Budgets' => 'budgets',
            'Chatbot' => 'chatbot',
            'Chime' => 'chime',
            'ChimeSDKIdentity' => 'identity-chime',
            'ChimeSDKMediaPipelines' => 'media-pipelines-chime',
            'ChimeSDKMeetings' => 'meetings-chime',
            'ChimeSDKMessaging' => 'messaging-chime',
            'ChimeSDKVoice' => 'voice-chime',
            'CleanRooms' => 'cleanrooms',
            'CleanRoomsML' => 'cleanrooms-ml',
            'Cloud9' => 'cloud9',
            'CloudControlApi' => 'cloudcontrolapi',
            'CloudDirectory' => 'clouddirectory',
            'CloudFormation' => 'cloudformation',
            'CloudFront' => 'cloudfront',
            'CloudFrontKeyValueStore' => 'cloudfront-keyvaluestore',
            'CloudHSM' => 'cloudhsm',
            'CloudHSMV2' => 'cloudhsmv2',
            'CloudSearch' => 'cloudsearch',
            'CloudTrail' => 'cloudtrail',
            'CloudTrailData' => 'cloudtrail-data',
            'CloudWatch' => 'monitoring',
            'CloudWatchEvents' => 'events',
            'CloudWatchLogs' => 'logs',
            'CloudWatchRUM' => 'rum',
            'CodeArtifact' => 'codeartifact',
            'CodeBuild' => 'codebuild',
            'CodeCatalyst' => 'codecatalyst',
            'CodeCommit' => 'codecommit',
            'CodeConnections' => 'codeconnections',
            'CodeDeploy' => 'codedeploy',
            'CodeGuruProfiler' => 'codeguru-profiler',
            'CodeGuruReviewer' => 'codeguru-reviewer',
            'CodeGuruSecurity' => 'codeguru-security',
            'CodePipeline' => 'codepipeline',
            'CodeStarNotifications' => 'codestar-notifications',
            'CodeStarconnections' => 'codestar-connections',
            'CognitoIdentity' => 'cognito-identity',
            'CognitoIdentityProvider' => 'cognito-idp',
            'CognitoSync' => 'cognito-sync',
            'Comprehend' => 'comprehend',
            'ComprehendMedical' => 'comprehendmedical',
            'ComputeOptimizer' => 'compute-optimizer',
            'ComputeOptimizerAutomation' => 'aco-automation',
            'ConfigService' => 'config',
            'Connect' => 'connect',
            'ConnectCampaignService' => 'connect-campaigns',
            'ConnectCampaignsV2' => 'connect-campaigns',
            'ConnectCases' => 'cases',
            'ConnectContactLens' => 'contact-lens',
            'ConnectHealth' => 'health-agent',
            'ConnectParticipant' => 'participant.connect',
            'ConnectWisdomService' => 'wisdom',
            'ControlCatalog' => 'controlcatalog',
            'ControlTower' => 'controltower',
            'CostExplorer' => 'ce',
            'CostOptimizationHub' => 'cost-optimization-hub',
            'CostandUsageReportService' => 'cur',
            'CustomerProfiles' => 'profile',
            'DAX' => 'dax',
            'DLM' => 'dlm',
            'DSQL' => 'dsql',
            'DataExchange' => 'dataexchange',
            'DataPipeline' => 'datapipeline',
            'DataSync' => 'datasync',
            'DataZone' => 'datazone',
            'DatabaseMigrationService' => 'dms',
            'Deadline' => 'deadline',
            'Detective' => 'api.detective',
            'DevOpsAgent' => 'aidevops',
            'DevOpsGuru' => 'devops-guru',
            'DeviceFarm' => 'devicefarm',
            'DirectConnect' => 'directconnect',
            'DirectoryService' => 'ds',
            'DirectoryServiceData' => 'ds-data',
            'DocDB' => 'rds',
            'DocDBElastic' => 'docdb-elastic',
            'Drs' => 'drs',
            'DynamoDB' => 'dynamodb',
            'DynamoDBStreams' => 'streams.dynamodb',
            'EBS' => 'ebs',
            'EC2' => 'ec2',
            'EC2InstanceConnect' => 'ec2-instance-connect',
            'ECR' => 'api.ecr',
            'ECRPublic' => 'api.ecr-public',
            'ECS' => 'ecs',
            'EFS' => 'elasticfilesystem',
            'EKS' => 'eks',
            'EKSAuth' => 'eks-auth',
            'EMR' => 'elasticmapreduce',
            'EMRContainers' => 'emr-containers',
            'EMRServerless' => 'emr-serverless',
            'ElastiCache' => 'elasticache',
            'ElasticBeanstalk' => 'elasticbeanstalk',
            'ElasticLoadBalancing' => 'elasticloadbalancing',
            'ElasticLoadBalancingV2' => 'elasticloadbalancing',
            'ElasticsearchService' => 'es',
            'ElementalInference' => 'elemental-inference',
            'EntityResolution' => 'entityresolution',
            'EventBridge' => 'events',
            'Evs' => 'evs',
            'FIS' => 'fis',
            'FMS' => 'fms',
            'FSx' => 'fsx',
            'FinSpaceData' => 'finspace-api',
            'Finspace' => 'finspace',
            'Firehose' => 'firehose',
            'ForecastQueryService' => 'forecastquery',
            'ForecastService' => 'forecast',
            'FraudDetector' => 'frauddetector',
            'FreeTier' => 'freetier',
            'GameLift' => 'gamelift',
            'GameLiftStreams' => 'gameliftstreams',
            'GeoMaps' => 'geo-maps',
            'GeoPlaces' => 'geo-places',
            'GeoRoutes' => 'geo-routes',
            'Glacier' => 'glacier',
            'GlobalAccelerator' => 'globalaccelerator',
            'Glue' => 'glue',
            'GlueDataBrew' => 'databrew',
            'Greengrass' => 'greengrass',
            'GreengrassV2' => 'greengrass',
            'GroundStation' => 'groundstation',
            'GuardDuty' => 'guardduty',
            'Health' => 'health',
            'HealthLake' => 'healthlake',
            'IAM' => 'iam',
            'IVS' => 'ivs',
            'IVSRealTime' => 'ivsrealtime',
            'IdentityStore' => 'identitystore',
            'Imagebuilder' => 'imagebuilder',
            'ImportExport' => 'importexport',
            'Inspector' => 'inspector',
            'Inspector2' => 'inspector2',
            'InspectorScan' => 'inspector-scan',
            'InternetMonitor' => 'internetmonitor',
            'Invoicing' => 'invoicing',
            'IoT' => 'iot',
            'IoTDeviceAdvisor' => 'api.iotdeviceadvisor',
            'IoTEvents' => 'iotevents',
            'IoTEventsData' => 'data.iotevents',
            'IoTFleetWise' => 'iotfleetwise',
            'IoTJobsDataPlane' => 'data.jobs.iot',
            'IoTManagedIntegrations' => 'api.iotmanagedintegrations',
            'IoTSecureTunneling' => 'api.tunneling.iot',
            'IoTSiteWise' => 'iotsitewise',
            'IoTThingsGraph' => 'iotthingsgraph',
            'IoTTwinMaker' => 'iottwinmaker',
            'IoTWireless' => 'api.iotwireless',
            'Ivschat' => 'ivschat',
            'KMS' => 'kms',
            'Kafka' => 'kafka',
            'KafkaConnect' => 'kafkaconnect',
            'Kendra' => 'kendra',
            'KendraRanking' => 'kendra-ranking',
            'Keyspaces' => 'cassandra',
            'KeyspacesStreams' => 'cassandra-streams',
            'Kinesis' => 'kinesis',
            'KinesisAnalytics' => 'kinesisanalytics',
            'KinesisAnalyticsV2' => 'kinesisanalytics',
            'KinesisVideo' => 'kinesisvideo',
            'KinesisVideoArchivedMedia' => 'kinesisvideo',
            'KinesisVideoMedia' => 'kinesisvideo',
            'KinesisVideoSignalingChannels' => 'kinesisvideo',
            'KinesisVideoWebRTCStorage' => 'kinesisvideo',
            'LakeFormation' => 'lakeformation',
            'Lambda' => 'lambda',
            'LaunchWizard' => 'launchwizard',
            'Lex' => 'runtime.lex',
            'LexModelBuildingService' => 'models.lex',
            'LexModelsV2' => 'models-v2-lex',
            'LexRuntimeV2' => 'runtime-v2-lex',
            'LicenseManager' => 'license-manager',
            'LicenseManagerLinuxSubscriptions' => 'license-manager-linux-subscriptions',
            'LicenseManagerUserSubscriptions' => 'license-manager-user-subscriptions',
            'Lightsail' => 'lightsail',
            'LocationService' => 'geo',
            'LookoutEquipment' => 'lookoutequipment',
            'MPA' => 'mpa',
            'MQ' => 'mq',
            'MTurk' => 'mturk-requester',
            'MWAA' => 'airflow',
            'MWAAServerless' => 'airflow-serverless',
            'MachineLearning' => 'machinelearning',
            'Macie2' => 'macie2',
            'MailManager' => 'mail-manager',
            'MainframeModernization' => 'm2',
            'ManagedBlockchain' => 'managedblockchain',
            'ManagedBlockchainQuery' => 'managedblockchain-query',
            'ManagedGrafana' => 'grafana',
            'MarketplaceAgreement' => 'agreement-marketplace',
            'MarketplaceCatalog' => 'catalog.marketplace',
            'MarketplaceCommerceAnalytics' => 'marketplacecommerceanalytics',
            'MarketplaceDeployment' => 'deployment-marketplace',
            'MarketplaceEntitlementService' => 'entitlement.marketplace',
            'MarketplaceMetering' => 'metering.marketplace',
            'MarketplaceReporting' => 'reporting-marketplace',
            'MediaConnect' => 'mediaconnect',
            'MediaConvert' => 'mediaconvert',
            'MediaLive' => 'medialive',
            'MediaPackage' => 'mediapackage',
            'MediaPackageV2' => 'mediapackagev2',
            'MediaPackageVod' => 'mediapackage-vod',
            'MediaStore' => 'mediastore',
            'MediaStoreData' => 'data.mediastore',
            'MediaTailor' => 'api.mediatailor',
            'MedicalImaging' => 'medical-imaging',
            'MemoryDB' => 'memory-db',
            'Mgn' => 'mgn',
            'MigrationHub' => 'mgh',
            'MigrationHubConfig' => 'migrationhub-config',
            'MigrationHubOrchestrator' => 'migrationhub-orchestrator',
            'MigrationHubRefactorSpaces' => 'refactor-spaces',
            'MigrationHubStrategyRecommendations' => 'migrationhub-strategy',
            'Neptune' => 'rds',
            'NeptuneGraph' => 'neptune-graph',
            'Neptunedata' => 'neptune-db',
            'NetworkFirewall' => 'network-firewall',
            'NetworkFlowMonitor' => 'networkflowmonitor',
            'NetworkManager' => 'networkmanager',
            'NetworkMonitor' => 'networkmonitor',
            'Notifications' => 'notifications',
            'NotificationsContacts' => 'notifications-contacts',
            'NovaAct' => 'nova-act',
            'OAM' => 'oam',
            'OSIS' => 'osis',
            'ObservabilityAdmin' => 'observabilityadmin',
            'Odb' => 'odb',
            'Omics' => 'omics',
            'OpenSearchServerless' => 'aoss',
            'OpenSearchService' => 'es',
            'Organizations' => 'organizations',
            'Outposts' => 'outposts',
            'PCS' => 'pcs',
            'PI' => 'pi',
            'Panorama' => 'panorama',
            'PartnerCentralAccount' => 'partnercentral-account',
            'PartnerCentralBenefits' => 'partnercentral-benefits',
            'PartnerCentralChannel' => 'partnercentral-channel',
            'PartnerCentralSelling' => 'partnercentral-selling',
            'PaymentCryptography' => 'controlplane.payment-cryptography',
            'PaymentCryptographyData' => 'dataplane.payment-cryptography',
            'PcaConnectorAd' => 'pca-connector-ad',
            'PcaConnectorScep' => 'pca-connector-scep',
            'Personalize' => 'personalize',
            'PersonalizeEvents' => 'personalize-events',
            'PersonalizeRuntime' => 'personalize-runtime',
            'Pinpoint' => 'pinpoint',
            'PinpointEmail' => 'email',
            'PinpointSMSVoice' => 'sms-voice.pinpoint',
            'PinpointSMSVoiceV2' => 'sms-voice',
            'Pipes' => 'pipes',
            'Polly' => 'polly',
            'Pricing' => 'api.pricing',
            'PrometheusService' => 'aps',
            'Proton' => 'proton',
            'QApps' => 'data.qapps',
            'QBusiness' => 'qbusiness',
            'QConnect' => 'wisdom',
            'QuickSight' => 'quicksight',
            'RAM' => 'ram',
            'RDS' => 'rds',
            'RDSDataService' => 'rds-data',
            'RTBFabric' => 'rtbfabric',
            'RecycleBin' => 'rbin',
            'Redshift' => 'redshift',
            'RedshiftDataAPIService' => 'redshift-data',
            'RedshiftServerless' => 'redshift-serverless',
            'Rekognition' => 'rekognition',
            'Repostspace' => 'repostspace',
            'ResilienceHub' => 'resiliencehub',
            'ResourceExplorer2' => 'resource-explorer-2',
            'ResourceGroups' => 'resource-groups',
            'ResourceGroupsTaggingAPI' => 'tagging',
            'RolesAnywhere' => 'rolesanywhere',
            'Route53' => 'route53',
            'Route53Domains' => 'route53domains',
            'Route53GlobalResolver' => 'route53globalresolver',
            'Route53Profiles' => 'route53profiles',
            'Route53RecoveryCluster' => 'route53-recovery-cluster',
            'Route53RecoveryControlConfig' => 'route53-recovery-control-config',
            'Route53RecoveryReadiness' => 'route53-recovery-readiness',
            'Route53Resolver' => 'route53resolver',
            'S3' => 's3',
            'S3Control' => 's3-control',
            'S3Outposts' => 's3-outposts',
            'S3Tables' => 's3tables',
            'S3Vectors' => 's3vectors',
            'SES' => 'email',
            'SESV2' => 'email',
            'SNS' => 'sns',
            'SQS' => 'sqs',
            'SSM' => 'ssm',
            'SSMContacts' => 'ssm-contacts',
            'SSMGuiConnect' => 'ssm-guiconnect',
            'SSMIncidents' => 'ssm-incidents',
            'SSMQuickSetup' => 'ssm-quicksetup',
            'SSO' => 'portal.sso',
            'SSOAdmin' => 'sso',
            'SSOOIDC' => 'oidc',
            'STS' => 'sts',
            'SWF' => 'swf',
            'SageMaker' => 'api.sagemaker',
            'SageMakerFeatureStoreRuntime' => 'featurestore-runtime.sagemaker',
            'SageMakerGeospatial' => 'sagemaker-geospatial',
            'SageMakerMetrics' => 'metrics.sagemaker',
            'SageMakerRuntime' => 'runtime.sagemaker',
            'SageMakerRuntimeHTTP2' => 'runtime.sagemaker',
            'SagemakerEdgeManager' => 'edge.sagemaker',
            'SavingsPlans' => 'savingsplans',
            'Scheduler' => 'scheduler',
            'Schemas' => 'schemas',
            'SecretsManager' => 'secretsmanager',
            'SecurityAgent' => 'securityagent',
            'SecurityHub' => 'securityhub',
            'SecurityIR' => 'security-ir',
            'SecurityLake' => 'securitylake',
            'ServerlessApplicationRepository' => 'serverlessrepo',
            'ServiceCatalog' => 'servicecatalog',
            'ServiceDiscovery' => 'servicediscovery',
            'ServiceQuotas' => 'servicequotas',
            'Shield' => 'shield',
            'Signer' => 'signer',
            'SignerData' => 'data-signer',
            'Signin' => 'signin',
            'SimSpaceWeaver' => 'simspaceweaver',
            'SimpleDB' => 'sdb',
            'SimpleDBv2' => 'sdb',
            'SnowDeviceManagement' => 'snow-device-management',
            'Snowball' => 'snowball',
            'SocialMessaging' => 'social-messaging',
            'SsmSap' => 'ssm-sap',
            'States' => 'states',
            'StorageGateway' => 'storagegateway',
            'SupplyChain' => 'scn',
            'Support' => 'support',
            'SupportApp' => 'supportapp',
            'Sustainability' => 'sustainability',
            'Synthetics' => 'synthetics',
            'TaxSettings' => 'tax',
            'Textract' => 'textract',
            'TimestreamInfluxDB' => 'timestream-influxdb',
            'TimestreamQuery' => 'query.timestream',
            'TimestreamWrite' => 'ingest.timestream',
            'Tnb' => 'tnb',
            'TranscribeService' => 'transcribe',
            'TranscribeStreamingService' => 'transcribestreaming',
            'Transfer' => 'transfer',
            'Translate' => 'translate',
            'TrustedAdvisor' => 'trustedadvisor',
            'Uxc' => 'uxc',
            'VPCLattice' => 'vpc-lattice',
            'VerifiedPermissions' => 'verifiedpermissions',
            'VoiceID' => 'voiceid',
            'WAF' => 'waf',
            'WAFRegional' => 'waf-regional',
            'WAFV2' => 'wafv2',
            'WellArchitected' => 'wellarchitected',
            'Wickr' => 'admin.wickr',
            'WorkDocs' => 'workdocs',
            'WorkMail' => 'workmail',
            'WorkMailMessageFlow' => 'workmailmessageflow',
            'WorkSpaces' => 'workspaces',
            'WorkSpacesThinClient' => 'thinclient',
            'WorkSpacesWeb' => 'workspaces-web',
            'WorkspacesInstances' => 'workspaces-instances',
            'XRay' => 'xray',
          }
          # end service ids
        end
      end

    end
  end
end
