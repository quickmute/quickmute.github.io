---
layout: post
title:  "Getting started with AWS Lambda SnapStart"
date:   2024-12-13 20:11:29 -0500
categories: AWS Lambda
---
# Introduction
This is a tutorial on getting started using AWS Lambda's SnapStart feature on Python. 

# References
- [Announcement](https://aws.amazon.com/blogs/aws/aws-lambda-snapstart-for-python-and-net-functions-is-now-generally-available/)
- [AWS Lambda Snapstart Dev Guide](hhttps://docs.aws.amazon.com/lambda/latest/dg/snapstart.html)

# Limitations
- Best for when you have relatively large Import and Initialization code
- Best for when your code doesn't run frequently
  - Frequently ran function would not need initiation time and it would nullify the benefit of SnapStart
- Must be attached to version of Function
  - This means all the calling services must reference the version (or Alias) and this must be updated accordingly whenever the Lambda is updated
  - This can be simplifed by using IAC such as Terraform
- You cannot remove SnapStart setting on existing version, must delete version

# Setup
https://github.com/quickmute/terraform-aws-mod-lambda/tree/main/Examples/snapstart
- SNS Topic and Lambda
- Add a Lambda layer for Pandas and openpyxl (just to add some overhead)
- Create a version off of $LATEST
- Assign a "Default" Alias off of latest version
- Enable SnapStart on "Default" Alias
- Subscribe both "$LATEST" and "Default" to SNS topic
- This was deployed using Terraform

## Python Code
```
import boto3
import pandas
import openpyxl
import time
import logging
import os
import json

## Initialization Code here
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def reverse_print(s):
    reversed_str = ""
    for char in s:
        reversed_str = char + reversed_str
        print(reversed_str)

def lambda_handler(event, context):
    for item in event['Records']:
        for key, value in item.items():
            print(key, value)
            if key == 'Sns':
                for k, v in value.items():
                    print(k, v)
                    if k == 'Message':
                        reverse_print(v)
    
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html; charset=utf-8'
        },
        'body': '<p>Hello world!</p>'
    }
```

# Testing
- Published a work of Shakespeare onto SNS topic and recorded duration as shown in CloudWatch
- Cold Start (odd) followed immedately by a Warm Start (even)

| Test | SnapStart Restore | SnapStart Duration | Standard Init | Standard Duration | SnapStart Total | Standard Total |
|------|-------------------|--------------------|---------------|-------------------|-----------------|----------------|
| 1    | 431.95            | 2260.89            | 2811.36       | 2154.2            | 2692.84         | 4965.56        |
| 2    | 0                 | 2094.38            | 0             | 2083.34           | 2094.38         | 2083.34        |
| 3    | 343.85            | 2296.17            | 2912.7        | 2034.59           | 2640.02         | 4947.29        |
| 4    | 0                 | 2110.37            | 0             | 2062.88           | 2110.37         | 2062.88        |
| 5    | 606.46            | 2277               | 2839.19       | 2117.31           | 2883.46         | 4956.5         |
| 6    | 0                 | 2139.26            | 0             | 1929.82           | 2139.26         | 1929.82        |
| 7    | 393.19            | 2019.49            | 3142.53       | 2288.43           | 2412.68         | 5430.96        |
| 8    | 0                 | 1819.09            | 0             | 2115.96           | 1819.09         | 2115.96        |
| 9    | 422.25            | 2220.36            | 2918.62       | 2116.05           | 2642.61         | 5034.67        |
| 10   | 0                 | 1981.42            | 0             | 2118.57           | 1981.42         | 2118.57        |

# Conclusion
- Storing snapshot of the Python initalization can increase the start to about 5 to 9 times regular start time
- There is virtually no improvement if comparing against warmed function 

# Cost Consideration
AWS Lambda Snapstart is charged for the snapshot stored (cache) and time it takes to restore the snapshot. 
```
Cache	$0.0000015046 per GB-second (minimum 3 hours)
Restore	$0.0001397998 for every GB restored
```
Whereas for non-snapstart enabled function, there is no charge for standard initialization. You are only charged for duration period and number of requests. 