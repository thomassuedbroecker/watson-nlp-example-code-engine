#!/bin/bash

# **************** Global variables
source ./.env

######### Watson NLP information ##############
# Information on https://www.ibm.com/docs/en/watson-libraries?topic=containers-run-docker-run
IMAGE_REGISTRY="cp.icr.io/cp/ai"
RUNTIME_IMAGE="watson-nlp-runtime"
WATSON_NLP_TAG="1.0.20"
export MODELS="${MODELS:-"watson-nlp_syntax_izumo_lang_en_stock:1.0.7,watson-nlp_syntax_izumo_lang_fr_stock:1.0.7"}"
IFS=',' read -ra models_arr <<< "${MODELS}"
MODEL_CONTAINERS_NAME=watson-nlp-models
TEMP_MODEL_DIR=models
DOWNLOAD_IMAGE=alpine

######### Create custom Watson NLP image ##############
CUSTOM_WATSON_NLP_IMAGE_NAME=watson-nlp-runtime-with-models
CUSTOM_TAG=1.0.0

######### IBM Cloud Container registry for custom image ##############
CR_CUSTOM_REGISTRY_URL=us.icr.io
#CR_NAMESPACE="custom-watson-nlp-YOURNAME"

######### IBM Cloud configuration ##############
RESOURCE_GROUP="default"
REGION="us-south"

######### IBM Cloud Code Engine #############
#CE_PROJECT_NAME="custom-watson-nlp-YOURNAME"
CE_SECRET_NAME="custom.watson.nlp.cr.sec"
#CE_EMAIL="your@email"
CE_APPLICATION_NAME="custom-watson-nlp-application"
CE_ACCEPT_LICENSE="true"

# **********************************************************************************
# Functions definition
# **********************************************************************************

############# Custom container related ##############

function connectToModelsInIBMContainerRegistry () {
    echo ""
    echo "# ******"
    echo "# Connect to IBM Cloud Container Image Registry: $IMAGE_REGISTRY"
    echo "# ******"
    echo ""
    echo "IBM_ENTITLEMENT_KEY: $IBM_ENTITLEMENT_KEY"
    echo ""
    docker login cp.icr.io --username cp --password $IBM_ENTITLEMENT_KEY
}

function listModelArray () {

    echo ""
    echo "# ******"
    echo "# List model array content"
    echo "# ******"
    echo ""

    i=0
    for model in "${models_arr[@]}"
    do
      echo "Model $i : $model"
      i=$((i+1))
    done
}

function downloadTheModels() {
    
    echo ""
    echo "# ******"
    echo "# Download the models"
    echo "# ******"
    echo ""

    ${CONTAINER_RUNTIME} login cp.icr.io --username cp --password ${IBM_ENTITLEMENT_KEY}

    # Clear out existing volume
    ${CONTAINER_RUNTIME} volume rm MODEL_DATA 2>/dev/null || true

    # Create a shared volume and initialize with open permissions
    echo "# 0. Create a volume to save the model locally"	
    ${CONTAINER_RUNTIME} volume create --label MODEL_DATA

    echo "# 1. Run a container in an interactive mode to set the permissions"
    ${CONTAINER_RUNTIME} build -f ./DownloadModel.Dockerfile -t downloadmodel:v1.0.0 .
    ${CONTAINER_RUNTIME} run --rm --name $MODEL_CONTAINERS_NAME -it -v MODEL_DATA:/model_data downloadmodel:v1.0.0 chmod 777 /model_data

    echo "# 2. Put models into the file share"
    i=0
    for model in "${models_arr[@]}"
    do
        ${CONTAINER_RUNTIME} run --rm --name $MODEL_CONTAINERS_NAME -it -v MODEL_DATA:/app/models -e ACCEPT_LICENSE=true $IMAGE_REGISTRY/$model
        i=$((i+1))
        echo "$i $MODEL_CONTAINERS_NAME $IMAGE_REGISTRY/$model"
    done
}

function createCustomContainerImageLocally () {
    echo ""
    echo "# ******"
    echo "# Create container image"
    echo "# ******"
    echo ""
    echo "Image name: $CUSTOM_WATSON_NLP_IMAGE_NAME"
    docker build --build-arg TAG=$WATSON_NLP_TAG ./ -t "$CUSTOM_WATSON_NLP_IMAGE_NAME":"$CUSTOM_TAG"
}

############# Code Engine related ############

function loginIBMCloud() {

    echo ""
    echo "# ******"
    echo "# Log in to IBM Cloud"
    echo "# ******"
    echo ""

    ibmcloud login --apikey $IBMCLOUD_APIKEY
    ibmcloud target -g $RESOURCE_GROUP
    ibmcloud target -r $REGION
}

function configureIBMCloudRegistry () {

    echo ""
    echo "# ******"
    echo "# Configure IBM Cloud Registry"
    echo "# ******"
    echo ""

    ibmcloud cr region-set $CR_CUSTOM_REGISTRY_URL
    ibmcloud cr namespace-add $CR_NAMESPACE
    ibmcloud cr login

}

function uploadCustomImageToIBMCloudRegistry () {
    # Tag the image
    echo "Container image: ${CR_CUSTOM_REGISTRY_URL}/${CR_NAMESPACE}/$CUSTOM_WATSON_NLP_IMAGE_NAME:$CUSTOM_TAG"
    docker tag $CUSTOM_WATSON_NLP_IMAGE_NAME:$CUSTOM_TAG ${CR_CUSTOM_REGISTRY_URL}/${CR_NAMESPACE}/$CUSTOM_WATSON_NLP_IMAGE_NAME:$CUSTOM_TAG

    # Push the image
    docker push ${CR_CUSTOM_REGISTRY_URL}/${CR_NAMESPACE}/$CUSTOM_WATSON_NLP_IMAGE_NAME:$CUSTOM_TAG
}

function createCE_Project () {
  echo "**********************************"
  echo " Create Code Engine project: $CE_PROJECT_NAME" 
  echo "**********************************"

  ibmcloud target -g $RESOURCE_GROUP
  ibmcloud target -r $REGION

  ibmcloud ce project create --name $CE_PROJECT_NAME 
}

function setupCE_CRenv() {

   echo "**********************************"
   echo " Configure IBM Cloud Container Registry Access ($CR_CUSTOM_REGISTRY_URL) for ($CE_PROJECT_NAME)" 
   echo "**********************************"
   
   IBMCLOUDCLI_KEY_NAME="cliapikey_$CE_PROJECT_NAME"
   IBMCLOUDCLI_KEY_DESCRIPTION="CLI APIkey $IBMCLOUDCLI_KEY_NAME"
   CLIKEY_FILE="cli_key.json"
   USERNAME="iamapikey"

   echo "**********************************"
   echo " Create Code Engine project: $CE_PROJECT_NAME" 
   echo "**********************************"
   
   RESULT=$(ibmcloud iam api-keys | grep '$IBMCLOUDCLI_KEY_NAME' | awk '{print $1;}' | head -n 1)
   echo "API key: $RESULT"
   if [[ $RESULT == $IBMCLOUDCLI_KEY_NAME ]]; then
        echo "*** The Cloud API key '$IBMCLOUDCLI_KEY_NAME' already exists !"
        echo "*** The script 'ce-install-application.sh' ends here!"
        echo "*** Review your existing API keys 'https://cloud.ibm.com/iam/apikeys'."
        exit 1
   fi

   ibmcloud iam api-key-create $IBMCLOUDCLI_KEY_NAME -d "My IBM CLoud CLI API key for project $PROJECT_NAME" --file $CLIKEY_FILE
   CLIAPIKEY=$(cat $CLIKEY_FILE | grep '"apikey":' | awk '{print $2;}' | sed 's/"//g' | sed 's/,//g' )
   #echo $CLIKEY
   rm -f $CLIKEY_FILE

   ibmcloud ce registry create --name $CE_SECRET_NAME \
                               --server $CR_CUSTOM_REGISTRY_URL \
                               --username $USERNAME \
                               --password $CLIAPIKEY \
                               --email $CE_EMAIL
}

function createCE_App() {

    echo ""
    echo "# ******"
    echo "# Create Code Engine application $CE_APPLICATION_NAME"
    echo "# ******"
    echo ""

    ibmcloud ce application create --name $CE_APPLICATION_NAME \
                                   --image "${CR_CUSTOM_REGISTRY_URL}/${CR_NAMESPACE}/$CUSTOM_WATSON_NLP_IMAGE_NAME:$CUSTOM_TAG" \
                                   --cpu "1" \
                                   --memory "2G" \
                                   --port 8080 \
                                   --registry-secret "$CE_SECRET_NAME" \
                                   --env ACCEPT_LICENSE="$CE_ACCEPT_LICENSE" \
                                   --max-scale 1 \
                                   --min-scale 1 
                                       
    CE_APPLICATION_NAME_URL=$(ibmcloud ce application get --name "$CE_APPLICATION_NAME" -o url)
    echo "Set CE_APPLICATION_NAME URL: $CE_APPLICATION_NAME_URL"
}

############# Verify Custom Watson NLP Image ############

function verifyRunningApplication () {
    
    echo ""
    echo "# ******"
    echo "# Verify the application $CE_APPLICATION_NAME"
    echo "# ******"
    echo ""

    curl -X POST "$CE_APPLICATION_NAME_URL/v1/watson.runtime.nlp.v1/NlpService/SyntaxPredict" \
                -H "accept: application/json" \
                -H "grpc-metadata-mm-model-id: syntax_izumo_lang_en_stock" \
                -H "content-type: application/json" \
                -d '{ "rawDocument": { "text": "This is a test sentence." }}'
}

#**********************************************************************************
# Execution
# *********************************************************************************

echo ""
echo "# ******"
echo "# Create custom Watson NLP container imager "
echo "# ******"
echo "" 

connectToModelsInIBMContainerRegistry

listModelArray

downloadTheModels

createCustomContainerImageLocally

echo ""
echo "# ******"
echo "# Upload image to IBM Cloud container registry "
echo "# ******"
echo "" 

loginIBMCloud

configureIBMCloudRegistry

uploadCustomImageToIBMCloudRegistry

echo ""
echo "# ******"
echo "# Create Code Engine project"
echo "# ******"
echo "" 

createCE_Project

setupCE_CRenv

createCE_App

echo "" 
echo "# ******"
echo "# Verify the custom image"
echo "# ******"
echo "" 

verifyRunningApplication



