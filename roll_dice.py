import random
import boto3
import ast
from collections import Counter
from boto3.dynamodb.conditions import Key, Attr
dynamodb = boto3.resource('dynamodb', 
             #aws_access_key_id='xxxAKIA3M226TU7AMMX5EPAT',
             #aws_secret_access_key= 'xxx/wLdoUPMhUefEvB0B9De1utgQ85pehtF8S63TWAAj',
             region_name = 'ap-southeast-1')
table_name = 'rollDB'
table = dynamodb.Table(table_name)


def roll_dice(n_dice_count,n_sides,n_occurences):
    
    #Error Handling
    if int(n_dice_count) < 1:
        return 0
    if int(n_sides) < 3:
        return 0
    if int(n_occurences) < 1:
        return 0
    

    rand_list=[]
    
    for i in range(n_occurences):
        sum = 0
        for i in range(n_dice_count):
            sum = sum + random.randint(1,n_sides)
        rand_list.append(sum)
        
    rand_list=Counter(rand_list)
    #print(n_dice_count,n_sides,n_occurences)
    return dict(rand_list)

def fetch_records(n_dice_count,n_sides):
    table = dynamodb.Table(table_name)
    query_text=str(n_dice_count)+'_'+str(n_sides)
    #grouped by all existing dice number–dice side combinations
    response = table.query(
        KeyConditionExpression=Key('n_dice_count_n_sides').eq(query_text)
    )
    
    return response


def add_records(rand_dict,n_dice_count,n_sides,n_occurences):
    
    response = fetch_records(n_dice_count,n_sides)

    if response['Count'] == 0:
        
        response = table.put_item(
           Item={
                'n_dice_count_n_sides': str(n_dice_count) + '_' + str(n_sides),
                'n_occurences': n_occurences,
                'result_set': str(rand_dict)
            }
        )
        return str(rand_dict)
    else:
        
        responses=response['Items']
        #print(response)
        responses_n_occurences=responses[0]['n_occurences'] + n_occurences
        responses_Result = ast.literal_eval(responses[0]['result_set'])
        #print(Counter(dict(responses_Result)))
        #print(Counter(rand_dict))
        updated_responses_Result = Counter(dict(responses_Result)) + Counter(rand_dict)
        
        
        response = table.update_item(
        Key={
            'n_dice_count_n_sides': responses[0]['n_dice_count_n_sides']
        },
        UpdateExpression="set n_occurences=:n, result_set=:r",
        ExpressionAttributeValues={
            ':n': responses_n_occurences,
            ':r': str(dict(updated_responses_Result))
        },
        ReturnValues="UPDATED_NEW"
        )
        
    
    return str(rand_dict)
        
        
def lambda_handler(event, context):
    
    n_dice_count=event.get('n_dice_count', 3)
    n_sides=event.get('n_sides', 6)
    n_occurences=event.get('n_occurences', 100)
    
    rand_dict=roll_dice(n_dice_count,n_sides,n_occurences)
    records =add_records(rand_dict,n_dice_count,n_sides,n_occurences)
    
    return {
        'statusCode': 200,
        'body': str(records)
    }

'''
{
    "n_dice_count":10,
    "n_sides":3,
    "n_occurences":100
}
'''