# Roll_rest_api

I have created an architecture review for this and decided to go with schema 2 as a solution.
Several factors will change which architecture we want to deploy.
The reason behind is it combines schema1 and schema3 with both inserts and update to the dynamoDB table.


Assignment 3:
 Answer the following questions:
a. How would you publish the API?
  The API will be published using AWS API Gateway.
  
b. How would you pen-test/secure the API?
  We can create a restrictive IAM with a limited IP Range.
  We can limit the invokes to known AWS resources.
  We can add authenticators, API Keys.
  We can also limit the number of triggers.
  
c. How would you test the quality of the API?
  We can create unit and smoke tests to automatically test the lambda's first and rollback any changes if it does not pass the criteria.
  
d. How would you monitor the Lambda functions?
  We can create a custom logging to output to S3.
  We can check and create custom cloudwatch logs.


Important Decisions:
  The percentage calculation is being done on the lambda side.
    This is done so that the calculation for the raw data is not disturbed.
    Additionally we can delegate this calculation to the user for cheaper lambda costs.
    
