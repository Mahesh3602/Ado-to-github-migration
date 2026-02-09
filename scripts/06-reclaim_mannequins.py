import csv
import requests
import os
import sys

def reclaim_users():
    # 1. Load details from Environment (GitHub Actions provides these)
    token = os.getenv("GH_PAT")
    org_name = os.getenv("GITHUB_ORG_NAME")
    url = "https://api.github.com/graphql"
    headers = {"Authorization": f"Bearer {token}"}

    if not token or not org_name:
        print("❌ Error: GH_PAT or GITHUB_ORG_NAME environment variables are missing.")
        sys.exit(1)

    # 2. Find the CSV file (checks root first, then scripts folder)
    csv_path = "mannequins.csv"
    if not os.path.exists(csv_path):
        csv_path = "scripts/mannequins.csv"
        
    if not os.path.exists(csv_path):
        print("❌ Error: mannequins.csv not found in root or scripts/ folder.")
        sys.exit(1)

    print(f"📂 Using data from: {csv_path}")
    print(f"🏢 Targeting Organization: {org_name}")

    # 3. Get the Organization ID
    org_query = f'{{ organization(login: "{org_name}") {{ id }} }}'
    org_resp = requests.post(url, json={'query': org_query}, headers=headers).json()
    
    if 'errors' in org_resp:
        print(f"❌ GraphQL Error (Org ID): {org_resp['errors'][0]['message']}")
        sys.exit(1)
        
    org_id = org_resp['data']['organization']['id']

    # 4. Process the CSV
    with open(csv_path, mode='r', encoding='utf-8-sig') as file:
        # Strip whitespace from headers and values
        reader = csv.DictReader((line.replace(' ', '') for line in file))
        
        for row in reader:
            target_username = row.get('target-user', '').strip()
            mannequin_id = row.get('mannequin-id', '').strip()
            
            if not target_username:
                print(f"⚠️ Skipping {row.get('mannequin-user')}: No target-user provided.")
                continue

            print(f"🔄 Processing {target_username}...")

            # 5. Convert Username to Global Node ID
            user_query = f'{{ user(login: "{target_username}") {{ id }} }}'
            user_resp = requests.post(url, json={'query': user_query}, headers=headers).json()
            
            if 'errors' in user_resp:
                print(f"❌ Could not find GitHub user: {target_username}")
                continue
            
            target_node_id = user_resp['data']['user']['id']

            # 6. Run the Reclamation Mutation
            reclaim_mutation = """
            mutation($orgId: ID!, $mannequinId: ID!, $targetUserId: ID!) {
              createAttributionInvitation(input: {
                ownerId: $orgId,
                sourceId: $mannequinId,
                targetId: $targetUserId
              }) {
                source { ... on Mannequin { login } }
                target { ... on User { login } }
              }
            }
            """
            
            variables = {
                "orgId": org_id,
                "mannequinId": mannequin_id,
                "targetUserId": target_node_id
            }

            response = requests.post(url, json={'query': reclaim_mutation, 'variables': variables}, headers=headers)
            result = response.json()

            if "errors" in result:
                print(f"❌ Failed for {row['mannequin-user']}: {result['errors'][0]['message']}")
            else:
                print(f"✅ Success! Invitation sent to {target_username}")

if __name__ == "__main__":
    reclaim_users()