# Project PLUTO Starter Code
# Assumes a dataset called activities exists
# Assumes a table call resources
# resources schema - single column:  message:string
import base64
from google.cloud import bigquery
table_id = "activities.resources"


def pubsub_to_bigquery(event, context):
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    print("Row To Insert: " + pubsub_message)
    client = bigquery.Client()
    table = client.get_table(table_id)
    row_to_insert = [(pubsub_message,)]     # NOTE - the trailing comma is required for this case - it expects a tuple
    errors = client.insert_rows(table, row_to_insert)
    if errors == []:
        print("Row Inserted: " + pubsub_message)