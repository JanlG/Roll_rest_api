import random
import boto3
import ast
from collections import Counter
from boto3.dynamodb.conditions import Key, Attr
dynamodb = boto3.resource('dynamodb', 
             region_name = 'ap-southeast-1')
table_name = 'rollDB'
table = dynamodb.Table(table_name)


def dump_table(table_name):
    results = []
    last_evaluated_key = None
    while True:
        if last_evaluated_key:
            response = table.scan(
                TableName=table_name,
                ExclusiveStartKey=last_evaluated_key
            )
        else: 
            response = table.scan(TableName=table_name)
        last_evaluated_key = response.get('LastEvaluatedKey')
        
        results.extend(response['Items'])
        
        if not last_evaluated_key:
            break
    return results



        
def lambda_handler(event, context):
    
    data = dump_table(table_name)
    new_data=[]
    for x in data:
    #print(x)
    
        result_set = ast.literal_eval(x['result_set'])
        result_set = {k: v*100 / x['n_occurences'] for k, v in result_set.items()}
        x['result_set'] = result_set
    
        new_data.append(x)
        
    return {
        'statusCode': 200,
        'body': str(new_data)
    }