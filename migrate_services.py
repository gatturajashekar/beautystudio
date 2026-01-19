import boto3
from botocore.exceptions import NoCredentialsError, ClientError

# Replace with your DynamoDB table name (Amplify usually prefixes with project name)
TABLE_NAME = "SalonServices"

# Sample services data
services = [
    {"id": "1", "name": "Haircut", "duration": "45 mins", "price": 500},
    {"id": "2", "name": "Hair Coloring", "duration": "90 mins", "price": 1500},
    {"id": "3", "name": "Facial", "duration": "60 mins", "price": 1200},
    {"id": "4", "name": "Manicure", "duration": "30 mins", "price": 400},
    {"id": "5", "name": "Pedicure", "duration": "45 mins", "price": 600},
]

def migrate_services():
    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table(TABLE_NAME)

        for service in services:
            table.put_item(Item=service)
            print(f"✅ Added service: {service['name']}")

    except NoCredentialsError:
        print("❌ AWS credentials not found. Run `aws configure` or use Amplify CLI to set them.")
    except ClientError as e:
        print(f"❌ DynamoDB error: {e}")

if __name__ == "__main__":
    migrate_services()
