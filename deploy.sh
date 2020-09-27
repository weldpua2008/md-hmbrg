#!/usr/bin/env bash


_DEPLOY="${1:-yes}"
export AWS_PROFILE="us-west-2"
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}
export CF_STACK_NAME_VPC=${CF_STACK_NAME_VPC:-"test-vpc"}
export CF_STACK_NAME_RS=${CF_STACK_NAME_RS:-"test-redshift"}
export CF_STACK_NAME_KINESIS=${CF_STACK_NAME_KINESIS:="test-kinesis"}
export MasterUserPassword=${MasterUserPassword:=$(echo MasterUserPassword | sha256sum | base64 | head -c 32 )}

##### Internal
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[INFO]${Font_color_suffix}"
Error="${Red_font_prefix}[ERROR]${Font_color_suffix}"
echoerr() { if [[ ${QUIET:-0} -ne 1 ]]; then echo -e "${Error} $@" 1>&2; fi }
echoinfo() { if [[ ${QUIET:-0} -ne 1 ]]; then echo -e "${Info} $@" 1>&2; fi }

START_TIME=$(date +%s)

function usage()
{
    echo "Script that helps provision CloudFormation stacks:
    usage:  $0
        yes     - Deploy all stacks
        no      - Delete all provisioned stacks
        -h      - call this help (exit status 1)
        "
}

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

get_bucket_name() {
    local _stack_name=${1}
    local _resource_id=${2}
    local _bucket_name=""
    for i in {1..2};do

        _bucket_name=$(aws cloudformation describe-stack-resource --stack-name ${_stack_name} --logical-resource-id ${_resource_id} --query 'StackResourceDetail.PhysicalResourceId' --output text)
        if [[ -z ${_bucket_name} ]];then
            sleep $((i + 1))
            continue
        fi
    done
    echo ${_bucket_name}
    if [[ -z ${_bucket_name} ]];then
        return 1
    fi
}
get_lambda_path(){
    export S3_BUCKET_NAME=""
    export S3_LAMBDA_PATH=""
    if [[ -z ${S3_BUCKET_NAME} ]];then
        for i in {1..2};do

            S3_BUCKET_NAME=$(aws cloudformation describe-stack-resource --stack-name ${CF_STACK_NAME_VPC} --logical-resource-id S3Bucket --query 'StackResourceDetail.PhysicalResourceId' --output text)
            if [[ -z ${S3_BUCKET_NAME} ]];then
                sleep $((i + 1))
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

}

upload_lambda_to_s3(){
    get_lambda_path
    [[ -d ./target ]] && rm -rf ./target || true
    mkdir -p target \
    && cp -R psycopg2-3.7/ target/psycopg2 \
    && cp lambda_function.py target \
    && cd target \
    && zip -qq -r9 ${OLDPWD}/lambda.zip . \
    && echoinfo "Uploading ${OLDPWD}/lambda.zip => ${S3_LAMBDA_PATH}" \
    && aws s3 cp ${OLDPWD}/lambda.zip ${S3_LAMBDA_PATH} 2> /dev/null \
    && cd ${OLDPWD}
    return $?
}

#### functions

_deploy() {
    cd "$(dirname $0)"
    echoinfo "Executing CloudFormation Stack in ${AWS_DEFAULT_REGION} with AWS Profile [${AWS_PROFILE}]" \
    && echoinfo "Deploying CloudFormation Stack [${CF_STACK_NAME_VPC} ] VPC" \
    && aws cloudformation deploy --template-file vpc.template \
        --stack-name ${CF_STACK_NAME_VPC} \
    && echoinfo "Deploying CloudFormation Stack [${CF_STACK_NAME_RS} ] RedShift" \
    && aws cloudformation deploy --template-file redshift.template \
        --stack-name ${CF_STACK_NAME_RS} \
        --parameter-overrides ParentVPCStack=${CF_STACK_NAME_VPC}  MasterUserPassword=${MasterUserPassword} \
    && upload_lambda_to_s3 \
    && get_lambda_path \
    && aws cloudformation deploy --template-file kinesis.template \
        --stack-name ${CF_STACK_NAME_KINESIS} \
        --parameter-overrides ParentRedshiftStack=${CF_STACK_NAME_RS} ParentVPCStack=${CF_STACK_NAME_VPC}  MasterUserPassword=${MasterUserPassword} LambdaPath=${S3_BUCKET_NAME} --capabilities CAPABILITY_IAM --capabilities CAPABILITY_NAMED_IAM \
    && echoinfo "Run the following command to generate test data: docker-compose up "
}

_remove_bucket_by_name(){
    if [[ ! -z ${1} ]];then
        aws s3 rb s3://${1} --force
        python -c "import boto3;boto3.resource('s3').Bucket('${1}').object_versions.all().delete()" 2> /dev/null
        python3 -c "import boto3;boto3.resource('s3').Bucket('${1}').object_versions.all().delete()" 2> /dev/null
        aws s3 rb s3://${1} --force
    fi
}

_wipe() {
    _destoy_s3_bucket=$(get_bucket_name "${CF_STACK_NAME_RS}" "DataBucket" 2> /dev/null)
    if [[ ! -z ${_destoy_s3_bucket} ]];then
        echoinfo "Destroying S3 Bucket ${_destoy_s3_bucket}"
        _remove_bucket_by_name "${_destoy_s3_bucket}"
    fi
    _destoy_s3_bucket=$(get_bucket_name "${CF_STACK_NAME_VPC}" "S3Bucket")
    if [[ ! -z ${_destoy_s3_bucket} ]];then
        echoinfo "Destroying S3 Bucket ${_destoy_s3_bucket}"
        _remove_bucket_by_name "${_destoy_s3_bucket}"
    fi
    get_lambda_path && \
    aws s3 rm ${S3_LAMBDA_PATH}
    echoinfo "!DESTROYING CloudFormation Stack in ${AWS_DEFAULT_REGION} with AWS Profile [${AWS_PROFILE}]"

    echoinfo "Destroying CloudFormation Stack [${CF_STACK_NAME_KINESIS} ] Kinesis" \
    && aws cloudformation delete-stack \
        --stack-name ${CF_STACK_NAME_KINESIS}
    aws cloudformation wait stack-delete-complete     --stack-name ${CF_STACK_NAME_KINESIS}
    echoinfo "Destroying CloudFormation Stack [${CF_STACK_NAME_RS} ] RedShift" \
    && aws cloudformation delete-stack \
        --stack-name ${CF_STACK_NAME_RS}

    aws cloudformation wait stack-delete-complete     --stack-name ${CF_STACK_NAME_RS}
    echoinfo "Destroying CloudFormation Stack [${CF_STACK_NAME_VPC} ] VPC" \
    && aws cloudformation delete-stack  \
        --stack-name ${CF_STACK_NAME_VPC}
    aws cloudformation wait stack-delete-complete     --stack-name ${CF_STACK_NAME_VPC}

}
_help(){
    usage
    exit 127
}
main(){
    if [[ "${_DEPLOY}" = "yes" ]];then
        _deploy
    elif [[ "${_DEPLOY}" = "no" ]];then
        _wipe
    else
        _help
    fi
}
###  Execution
main
