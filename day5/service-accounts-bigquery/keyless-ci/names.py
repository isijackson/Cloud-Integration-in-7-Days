import sys
from google.cloud import bigquery
state = sys.argv[1] if len(sys.argv) > 1 else 'TX'
client = bigquery.Client()
query = f"""
SELECT name, SUM(number) AS total
FROM `bigquery-public-data.usa_names.usa_1910_current`
WHERE state = '{state}'
GROUP BY name ORDER BY total DESC LIMIT 5
"""
print(f"Top names in {state}:")
for row in client.query(query):
    print(f"  {row.name}: {row.total}")
