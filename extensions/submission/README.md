# Submission

### 1. Schema file (.json or .graphql) from Question 1

Question: Retrieve the schema via an Introspection Query

Answer:
- JSON location: [schema.json](./schema.json)

  Retrieved and saved using introspection query via [HTTP POST request](https://www.postman.com/kyle-1445084/workspace/kyle-s-workspace/request/43851132-0316e2cd-aeae-474e-b9f0-703be6fe3e3d?action=share&source=copy-link&creator=43851132&ctx=documentation).

- GraphQL location: [schema.graphql](./schema.graphql)

  After retrieving the schema via an introspection query, I used an npm package called [graphql-introspection-json-to-sdl](https://www.npmjs.com/package/graphql-introspection-json-to-sdl) to convert the JSON schema to GraphQL SDL format with the following command:

  ```bash
  # Install the package if you haven't already
  npm install -g graphql-introspection-json-to-sdl

  # Convert the JSON schema to GraphQL SDL format
  npx graphql-introspection-json-to-sdl schema.json > schema.graphql
  ```

### 2. cURL command for Question 2
Question: Using above API, query 100 pools, with below attributes
```
id
token0 id
token0 symbol
token1 id
token1 symbol
```

Answer:
```bash
API_KEY="your_api_key_here"

curl --location "https://gateway.thegraph.com/api/$API_KEY/subgraphs/id/5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV" \
--header "Content-Type: application/json" \
--data @- <<EOF
{
  "query": "query Pools {
    pools(first: 100) {
      id
      token0 {
        id
        symbol
      }
      token1 {
        id
        symbol
      }
    }
}",
  "variables": {}
}
EOF

unset API_KEY
```

[Output](./outputs/q2.json)

### 3. cURL command for Question 3

Question: Repeat #2 with additional conditions: query 100 pools with the highest liquidity that were created in the past week

Answer:

*Note*: I utilized dynamic variable substitution to calculate the timestamp for one week ago.

```bash
API_KEY="your_api_key_here"

curl --location "https://gateway.thegraph.com/api/$API_KEY/subgraphs/id/5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV" \
--header "Content-Type: application/json" \
--data @- <<EOF
{
  "query": "query HighestLiquidityPoolsSincePastWeek(\$since: BigInt!) {
    pools(
      first: 100,
      orderBy: liquidity,
      orderDirection: desc,
      where: { createdAtTimestamp_gte: \$since }
    ) {
      id
      token0 {
        id
        symbol
      }
      token1 {
        id
        symbol
      }
    }
  }",
  "variables": {
    "since": "$(($(date +%s) - 7*24*60*60))"
  }
}
EOF

unset API_KEY
```

[Output](./outputs/q3.json)

### 4. cURL command for Question 4

Question: Using this USDC/WETH pool 0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8, query the below attributes:
```
id
token0 id
token0 symbol
token0 derivedETH
token1 id
token1 symbol
token1 derivedETH
liquidity
token0Price
token1Price
volumeToken0
volumeToken1
volumeUSD
totalValueLockedUSD
```
Answer:
```bash
API_KEY="your_api_key_here"

curl --location "https://gateway.thegraph.com/api/$API_KEY/subgraphs/id/5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV" \
--header "Content-Type: application/json" \
--data @- <<EOF
{
  "query": "query Pool(\$id: ID!) {
    pools(
      where: {
        id: \$id
      }
    ) {
      id
      token0 {
        id
        symbol
        derivedETH
      }
      token1 {
        id
        symbol
        derivedETH
      }
      liquidity
      token0Price
      token1Price
      volumeToken0
      volumeToken1
      volumeUSD
      totalValueLockedUSD
    }
  }",
  "variables": {
    "id": "0x8ad599c3a0ff1de082011efddc58f1908eb6e6d8"
  }
}
EOF

unset API_KEY
```

[Output](./outputs/q4.json)

### 4. Collection export (e.g., Postman .json, Insomnia .yaml, or equivalent from your chosen tool)

Answer: 

- Collection export location: [Uniswap Dex Data (HTTP).postman_collection.json](./Uniswap%20Dex%20Data%20(HTTP).postman_collection.json)
- HTTPS shared collection location: [link](https://www.postman.com/kyle-1445084/workspace/kyle-s-workspace/collection/43851132-50125a1a-8bd4-4daa-bc6c-3ce2235ea186?action=share&creator=43851132postman_collection.json) 
- GraphQL shared collection location: [link](https://www.postman.com/kyle-1445084/workspace/kyle-s-workspace/collection/69995bcb3d43333f162045eb?action=share&creator=43851132)  
