---
layout: post
title:  "Using SNS Service Integration from API Gateway"
date:   2022-02-06 23:11:29 -0500
categories: AWS SNS APIGW
---
# Introduction
This is a tutorial on setting up AWS API GW to talk to SNS. The code below is in Powershell. You should verify your setup from the console as you follow along. 

# References
- [API Proxy Integration](https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-proxy-integrate-service/)
- [API to SNS](https://www.alexdebrie.com/posts/aws-api-gateway-service-proxy/)

# Create SNS Topic
Nothing fancy. Just regular topic. Keep the ARN handy

# Create IAM Role
Create a new IAM Role with following properties. Keep this ARN handy.
  - Permission Policy
    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:Publish"
            ],
            "Resource": "arn:aws:sns:us-east-1:999999999999:delete_me_hyon"
        }
      ]
    }  
    ```
  - Trust Policy
    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "apigateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
      ]
    }  
    ```
# API GW
## Create REST API
<script src="https://gist.github.com/quickmute/bf0730f512e6ab1e4b62711ee2506b37.js"></script>
You can also verify via console here:
![New Image](/assets/api_sns_step1.png)

## Create a Resource
Create a resource under root called `my_ingest`
```powershell
$INGEST_RESOURCE_ID = aws apigateway create-resource `   
  --rest-api-id $API_ID `
  --parent-id $ROOT_RESOURCE_ID `
  --path-part my_ingest `
  --output text `
  --query 'id' `
  --region $REGION
```
![New Image](/assets/api_sns_step2.png)

## Create a method
Create a method
```powershell
aws apigateway put-method `
  --rest-api-id $API_ID `
  --resource-id $INGEST_RESOURCE_ID `
  --http-method POST `
  --authorization-type NONE `
  --region $REGION
```
![New Image](/assets/api_sns_step3.png)

## Put integration
```powershell
$requesttemplates = '{\"application/json\":' +  '\"Action=Publish&TopicArn=$util.urlEncode(''' + $SNS_TOPIC_ARN + ''')&Message=$util.urlEncode($input.body)\"}'
aws apigateway put-integration `
  --rest-api-id $API_ID `
  --resource-id $INGEST_RESOURCE_ID `
  --http-method POST `
  --type AWS `
  --integration-http-method POST `
  --uri "arn:aws:apigateway:${REGION}:sns:path//" `
  --credentials $ROLE_ARN `
  --request-parameters '{\"integration.request.header.Content-Type\" : \"''application/x-www-form-urlencoded''\"}' `
  --request-templates $requesttemplates `
  --passthrough-behavior NEVER
```
Expected Output:
```json
{
    "type": "AWS",
    "httpMethod": "POST",
    "uri": "arn:aws:apigateway:us-east-1:sns:path//",
    "credentials": "arn:aws:iam::999999999999:role/delete_me_hyon",
    "requestParameters": {
        "integration.request.header.Content-Type": "'application/x-www-form-urlencoded'"
    },
    "requestTemplates": {
        "application/json": "Action=Publish&TopicArn=$util.urlEncode('arn:aws:sns:us-east-1:999999999999:delete_me_hyon')&Message=$util.urlEncode($input.body)"
    },
    "passthroughBehavior": "NEVER",
    "timeoutInMillis": 29000,
    "cacheNamespace": "cvevrl",
    "cacheKeyParameters": []
}
```
![New Image](/assets/api_sns_step4.png)
![New Image](/assets/api_sns_step5.png)

## Put integration Response
```powershell
aws apigateway put-integration-response `
  --rest-api-id $API_ID `
  --resource-id $INGEST_RESOURCE_ID `
  --http-method POST `
  --status-code 200 `
  --response-templates '{\"application/json\": \"{''body'': ''Message received.''}\"}' 
```
Expected Output:
```json
{
    "statusCode": "200",
    "selectionPattern": "\"\"",
    "responseTemplates": {
        "application/json": "{'body': 'Message received.'}"
    }
}
```
![New Image](/assets/api_sns_step6.png)

## Put Method Response
```powershell
aws apigateway put-method-response `
  --rest-api-id $API_ID `
  --resource-id $INGEST_RESOURCE_ID `
  --http-method POST `
  --status-code 200 `
  --response-models '{\"application/json\": \"Empty\" }'
```
Expected Output:
```json
{
    "statusCode": "200",
    "responseModels": {
        "application/json": "Empty"
    }
}
```
![New Image](/assets/api_sns_step7.png)

## Deploy it
```powershell
aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod
```
Expected Output:
```json
{
    "id": "55n8z8",
    "createdDate": "2022-02-06T15:29:21-06:00"
}
```
![New Image](/assets/api_sns_step8.png)

## Test it
- Click here to test
![New Image](/assets/api_sns_step9.png)
- Expected Output
![New Image](/assets/api_sns_stepx.png)
