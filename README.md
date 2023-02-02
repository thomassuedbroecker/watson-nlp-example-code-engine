# Run Watson NLP for Embed with Code Engine on IBM Cloud

This is example how to use Watson NLP based on the official example documentation:[`IBM Watson Libraries for Embed`](https://www.ibm.com/docs/en/watson-libraries?topic=watson-natural-language-processing-library-embed-home).

Related blog post [`Run Watson NLP for Embed on IBM Cloud Code Engine`](https://suedbroecker.net/2022/12/21/run-watson-nlp-for-embed-on-ibm-cloud-code-engine/).

### Step 1: Clone the example project to your local computer

```sh
git clone https://github.com/thomassuedbroecker/watson-nlp-example-code-engine
cd watson-nlp-example-code-engine/code
```

### Step 2:  Set your IBM_ENTITLEMENT_KEY in the `.env` file

```sh
cat .env-template > .env
```

Edit the `.env` file.

```sh
# used as 'environment' variables
IBMCLOUD_ENTITLEMENT_KEY="YOUR_KEY"
IBMCLOUD_APIKEY="YOUR_KEY"
CR_NAMESPACE="custom-watson-nlp-YOUR_NAME"
CE_EMAIL="YOUR_EMAIL"
CE_PROJECT_NAME="custom-watson-nlp-YOURNAME"
```

### Step 3: Execute the `run-watson-nlp-with-docker.sh` bash script

```sh
sh run-watson-nlp-with-code-engine.sh
```

* Example output:

```sh
# ******
# Create custom Watson NLP container imager 
# ******


# ******
# Connect to IBM Cloud Container Image Registry: cp.icr.io/cp/ai
# ******

CONTAINER_ENTITLEMENT_KEY: XXXX

WARNING! Using --password via the CLI is insecure. Use --password-stdin.
Login Succeeded

# ******
# List model array content
# ******

Model 0 : watson-nlp_syntax_izumo_lang_en_stock:1.0.7
Model 1 : watson-nlp_syntax_izumo_lang_fr_stock:1.0.7

# ******
# Download the models
# ******

# 1. Run a container in an interactive mode to set the permissions
# 2. Put models into the file share
Archive:  /app/model.zip
  inflating: config.yml              
1 watson-nlp-models cp.icr.io/cp/ai/watson-nlp_syntax_izumo_lang_en_stock:1.0.7
Archive:  /app/model.zip
  inflating: config.yml              
2 watson-nlp-models cp.icr.io/cp/ai/watson-nlp_syntax_izumo_lang_fr_stock:1.0.7

# ******
# Create container image
# ******

Image name: watson-nlp-runtime-with-models
[+] Building 0.1s (7/7) FINISHED                                                
 => [internal] load build definition from Dockerfile                       0.0s
 => => transferring dockerfile: 126B                                       0.0s
 ...
 => => writing image sha256:da130d25dbcf3eaa5d8ad7f47c6d4fdb9e460ae2de931  0.0s
 => => naming to docker.io/library/watson-nlp-runtime-with-models:1.0.0    0.0s

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them

# ******
# Upload image to IBM Cloud container registry 
# ******


# ******
# Log in to IBM Cloud
# ******

API endpoint: https://cloud.ibm.com
Region: us-south
Authenticating...
OK

Targeted account XXX

                   
API endpoint:      https://cloud.ibm.com
Region:            us-south
User:              XXXX
Account:           XXXX
Resource group:    No resource group targeted, use 'ibmcloud target -g RESOURCE_GROUP'
CF API endpoint:   
Org:               
Space:             
Targeted resource group default


                   
API endpoint:      https://cloud.ibm.com
Region:            us-south
User:              XXXX
Account:           XXXX
Resource group:    default
CF API endpoint:   
Org:               
Space:             
Switched to region us-south


                   
API endpoint:      https://cloud.ibm.com
Region:            us-south
User:              XXXX
Account:           XXXX
Resource group:    default
CF API endpoint:   
Org:               
Space:             

# ******
# Configure IBM Cloud Registry
# ******

The region is set to 'us-south', the registry is 'us.icr.io'.

OK
Adding namespace 'custom-watson-nlp-tsued' in resource group 'default' for account XXXX Account in registry us.icr.io...

The requested namespace is already owned by your account.

OK
Logging 'docker' in to 'us.icr.io'...
Logged in to 'us.icr.io'.

OK
Container image: us.icr.io/custom-watson-nlp-tsued/watson-nlp-runtime-with-models:1.0.0
The push refers to repository [us.icr.io/custom-watson-nlp-tsued/watson-nlp-runtime-with-models]
2de7f9fb3378: Pushed 
...
9aaca8eae7c0: Pushed 
1.0.0: digest: sha256:8ad1b4bdd6a89b0686c48fc2325900018a1ddfec0ffb1689457b5c433300d61c size: 4290

# ******
# Create Code Engine project
# ******

**********************************
 Create Code Engine project: custom-watson-nlp-tsued
**********************************
Targeted resource group default
                 
API endpoint:      https://cloud.ibm.com
Region:            us-south
User:              XXXX
Account:           XXXX
Resource group:    default
CF API endpoint:   
Org:               
Space:             
Switched to region us-south


                   
API endpoint:      https://cloud.ibm.com
Region:            us-south
User:              XXXX
Account:           XXXX
Resource group:    default
CF API endpoint:   
Org:               
Space:             

Creating project 'custom-watson-nlp-tsued'...
ID for project 'custom-watson-nlp-tsued' is 'b879a212-XXXX'.
Waiting for project 'custom-watson-nlp-tsued' to be active...
Now selecting project 'custom-watson-nlp-tsued'.
OK
**********************************
 Configure IBM Cloud Container Registry Access (us.icr.io) for (custom-watson-nlp-tsued)
**********************************
**********************************
 Create Code Engine project: custom-watson-nlp-tsued
**********************************
API key: 
Creating API key cliapikey_custom-watson-nlp-tsued under 641ebfXXXXXXb45279e as XXXXX...
OK
API key cliapikey_custom-watson-nlp-tsued was created
Successfully save API key information to cli_key.json
Creating image registry access secret 'custom.watson.nlp.cr.sec'...
OK

# ******
# Create Code Engine application custom-watson-nlp-application
# ******

Creating application 'custom-watson-nlp-application'...
Configuration 'custom-watson-nlp-application' is waiting for a Revision to become ready.
Ingress has not yet been reconciled.
Waiting for load balancer to be ready.
Run 'ibmcloud ce application get -n custom-watson-nlp-application' to check the application status.
OK

Set CE_APPLICATION_NAME URL: https://custom-watson-nlp-application.wqtmqy9e03u.us-south.codeengine.appdomain.cloud

# ******
# Verify the custom image
# ******


# ******
# Verify the application custom-watson-nlp-application
# ******

{"text":"This is a test sentence.", "producerId":{"name":"Izumo Text Processing", "version":"0.0.1"}, "tokens":[{"span":{"begin":0, "end":4, "text":"This"}, 
...
"features":[]}], "sentences":[{"span":{"begin":0, "end":24, "text":"This is a test sentence."}}], "paragraphs":[{"span":{"begin":0, "end":24, "text":"This is a test sentence."}}]}
```

