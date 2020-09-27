### CloudFormation Templates to run Kinesis to RedShift
#### How to run

1. Deploy resources on Amazon Web Services

```bash
export AWS_PROFILE=
export AWS_DEFAULT_REGION=
export CF_STACK_NAME_VPC=
./deploy.sh yes
```

Values for Environment Variables:

|        Variable       | Example       | Description                                                                                                                                                                                                                           |
|:---------------------:|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AWS_PROFILE           | default       | A named profile is a collection of settings and credentials that you can apply to a AWS CLI command                                                                                                                                   |
| AWS_DEFAULT_REGION    | us-west-2     | Specifies the AWS Region to send the request to.  If defined, this environment variable overrides the value for the profile setting region.  You can override this environment variable by using the --region command line parameter. |
| CF_STACK_NAME_VPC     | test-vpc      | Name for the basic CloudFormation stack with VPC                                                                                                                                                                                      |
| CF_STACK_NAME_RS      | test-redshift | Name for the CloudFormation stack with AWS Redshift Cluster                                                                                                                                                                           |
| CF_STACK_NAME_KINESIS | test-kinesis  | Name for the CloudFormation stack with AWS Kinesis                                                                                                                                                                                    |
| MasterUserPassword    |               | A password for the AWS Redshift Cluster                                                                                                                                                                                               |

2. Run Kinesis producer

```bash

 docker-compose up
```


3. Kinesis Streams consumer:


### Decomission
```bash
./deploy.sh no

```


* [Issue Template error: Fn::Select cannot select nonexistent value at index 2](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html)
You need to check that your region has at least 3 Aviability Zones

Kudos:
* Using https://github.com/jkehler/awslambda-psycopg2 for Lambda ( [link](https://stackoverflow.com/questions/36607952/using-psycopg2-with-lambda-to-update-redshift-python) )
