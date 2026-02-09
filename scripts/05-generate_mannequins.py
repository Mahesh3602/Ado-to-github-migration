import requests
import csv
import os

def load_settings():
    """Attempts to load from .env for local use, otherwise uses system environment variables."""
    env_file = "migrate_repo.env"
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                if line.strip() and not line.startswith("#"):
                    line = line.replace("export ", "").strip()
                    if "=" in line:
                        key, value = line.split("=", 1)
                        os.environ[key] = value.strip('"').strip("'")
    
    return os.getenv("GH_PAT"), os.getenv("GITHUB_ORG_NAME")

def fetch_mannequins():
    token, org_name = load_settings()
    
    if not token or not org_name:
        print("❌ Error: GH_PAT or GITHUB_ORG_NAME not found.")
        return

    url = "https://api.github.com/graphql"
    headers = {"Authorization": f"Bearer {token}"}

    query = """
    query($org: String!) {
      organization(login: $org) {
        mannequins(first: 100) {
          nodes {
            id
            login
          }
        }
      }
    }
    """
    
    variables = {"org": org_name}
    
    print(f"🔍 Fetching mannequins for {org_name}...")
    response = requests.post(url, json={'query': query, 'variables': variables}, headers=headers)
    data = response.json()

    if "errors" in data:
        print(f"❌ GraphQL Error: {data['errors'][0]['message']}")
        return

    mannequins = data['data']['organization']['mannequins']['nodes']

    if not mannequins:
        print("⚠️ No mannequins found. This usually means all users are already linked.")
        return

    # 3. Write to CSV (Saved in the root for easier GitHub Action artifacts)
    output_file = 'mannequins.csv'
    with open(output_file, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.writer(file)
        writer.writerow(['mannequin-user', 'mannequin-id', 'target-user'])
        
        for m in mannequins:
            writer.writerow([m['login'], m['id'], ''])

    print(f"✅ Created {output_file} with {len(mannequins)} entries.")

if __name__ == "__main__":
    fetch_mannequins()