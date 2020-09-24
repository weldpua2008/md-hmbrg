#!/usr/bin/env bash
export AWS_PROFILE="bi-use1"
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}
export CLOUD_FORMATION_STACK_NAME_VPC=${CLOUD_FORMATION_STACK_NAME_VPC:-"test-vpc"}
export CLOUD_FORMATION_STACK_NAME_RS=${CLOUD_FORMATION_STACK_NAME_RS:-"test-redshift"}
export CLOUD_FORMATION_STACK_NAME_KINESIS=${CLOUD_FORMATION_STACK_NAME_KINESIS:="test-kinesis"}
export MasterUserPassword=${MasterUserPassword:=$(echo MasterUserPassword | sha256sum | base64 | head -c 32 )}

##### Internal
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[INFO]${Font_color_suffix}"
Error="${Red_font_prefix}[ERROR]${Font_color_suffix}"
echoerr() { if [[ ${QUIET:-0} -ne 1 ]]; then echo -e "${Error} $@" 1>&2; fi }
echoinfo() { if [[ ${QUIET:-0} -ne 1 ]]; then echo -e "${Info} $@" 1>&2; fi }

START_TIME=$(date +%s)

function on_exit(){
    local _exit_code=${1:-1}
    local runtime=$(($(date +%s) - START_TIME))
    if [[ ${_exit_code} -eq 0  ]];then
    echoinfo "++++++++++++++++++++++++++++++++++++++++++++++
Took ${runtime} seconds to execute exit code: ${_exit_code}
++++++++++++++++++++++++++++++++++++++++++++++"
else
echoerr "++++++++++++++++++++++++++++++++++++++++++++++
Failed after ${runtime} seconds exit code: ${_exit_code}
++++++++++++++++++++++++++++++++++++++++++++++"
fi
    exit ${_exit_code}

}
trap 'on_exit $?' EXIT HUP TERM INT

upload_lambda_to_s3(){
    # export S3_BUCKET_NAME=""
    if [[ -z ${S3_BUCKET_NAME} ]];then
        for i in {1..3};do

            S3_BUCKET_NAME=$(aws cloudformation describe-stack-resource --stack-name ${CLOUD_FORMATION_STACK_NAME_VPC} --logical-resource-id S3Bucket --query 'StackResourceDetail.PhysicalResourceId' --output text)
            if [[ -z ${S3_BUCKET_NAME} ]];then
                sleep $((i + 6))
                continue
            fi
        done
    fi
    export S3_BUCKET_NAME="${S3_BUCKET_NAME}"
    if [[ -z ${S3_BUCKET_NAME} ]];then
        echoerr "FAILED to detect S3 bucket for AWS Lambda upload"
        return 1
    fi
    export S3_LAMBDA_PATH="s3://${S3_BUCKET_NAME}/lambda.zip"
    [[ -d ./target ]] && rm -rf ./target || true
    mkdir -p target \
    && cp -R psycopg2-3.7/ target/psycopg2 \
    && cp lambda_function.py target \
    && cd target \
    && zip -r9 ${OLDPWD}/lambda.zip . \
    && echoinfo "Uploading ${OLDPWD}/lambda.zip => ${S3_LAMBDA_PATH}" \
    && aws s3 cp ${OLDPWD}/lambda.zip ${S3_LAMBDA_PATH} \
    && cd ${OLDPWD}
    return $?
}

#### functions

main() {
    cd "$(dirname $0)"
    # echoinfo "Executing CloudFormation Stack in ${AWS_DEFAULT_REGION} with AWS Profile [${AWS_PROFILE}]" \
    # && echoinfo "Deploying CloudFormation Stack [${CLOUD_FORMATION_STACK_NAME_VPC} ] VPC" \
    # && aws cloudformation deploy --template-file vpc.template \
    #     --stack-name ${CLOUD_FORMATION_STACK_NAME_VPC} \
    # && echoinfo "Deploying CloudFormation Stack [${CLOUD_FORMATION_STACK_NAME_VPC} ] RedShift" \
    # && aws cloudformation deploy --template-file redshift.template \
    #     --stack-name ${CLOUD_FORMATION_STACK_NAME_RS} \
    #     --parameter-overrides ParentVPCStack=${CLOUD_FORMATION_STACK_NAME_VPC}  MasterUserPassword=${MasterUserPassword} \
    # && upload_lambda_to_s3 \
    echo && aws cloudformation deploy --template-file kinesis.template \
        --stack-name ${CLOUD_FORMATION_STACK_NAME_KINESIS} \
        --parameter-overrides ParentRedshiftStack=${CLOUD_FORMATION_STACK_NAME_RS} ParentVPCStack=${CLOUD_FORMATION_STACK_NAME_VPC}  MasterUserPassword=${MasterUserPassword} --capabilities CAPABILITY_IAM

    # aws cloudformation set-stack-policy --stack-name ${CLOUD_FORMATION_STACK_NAME_RS} \
    # --stack-policy-body file://redshift_stack_policy.json \

        # ParentRedshiftStack=${CLOUD_FORMATION_STACK_NAME_VPC} MasterUserPassword=$(date +%s | sha256sum | base64 | head -c 32 )


}

###  Execution
main
