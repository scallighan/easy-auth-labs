# Logic App (Standard) to Azure Function

This example demonstrates a Logic App (Standard) calling an Azure Function (Flex Consumption) that is protected by Easy Auth. The Logic App authenticates using its User Assigned Managed Identity to obtain a token for the Function App's App Registration.

## Architecture

```
Logic App (Standard) --[Bearer Token]--> Azure Function (Flex Consumption)
       |                                         |
  User Assigned MI                         Easy Auth (Entra ID)
  gets token for                           validates token against
  App Registration audience                App Registration
```

### Resources Deployed

- **VNet** with subnets for Logic App, Function App, and Private Endpoints
- **Storage Account** with private endpoints (blob, queue, table, file)
- **User Assigned Managed Identity** — shared by both Logic App and Function App
- **App Registration** — with exposed API (`api://<client-id>`) and `user_impersonation` scope
- **Logic App (Standard)** — Windows, workflow app on WS1 plan
- **Azure Function (Flex Consumption)** — Linux, Python 3.12, FC1 plan
- **Easy Auth** — configured on the Function App to require authentication and allow only the MI's client ID

## Prerequisites

- Azure CLI authenticated (`az login`)
- Terraform >= 1.0
- [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local) (for deploying the function code)

## Setup

### 1. Deploy Infrastructure

```bash
cd terraform
cp env.sample .env
# Fill in your values
source .env
terraform init
terraform apply
```

### 2. Deploy the Function Code

```bash
cd function
cp .env.sample .env
# Set FUNC_NAME to the terraform output "function_name"
source .env
func azure functionapp publish $FUNC_NAME --python
```

### 3. Deploy the Logic App Workflow

Upload `workflows/sample.json` to the Logic App and replace the placeholders:

| Placeholder | Value |
|-------------|-------|
| `$FUNCTION_NAME` | Terraform output `function_name` |
| `$MI_ID` | The User Assigned Managed Identity resource ID |
| `$CLIENT_ID` | Terraform output `app_registration_client_id` |

## How It Works

1. The Logic App workflow is triggered by an HTTP request
2. The HTTP action authenticates using the User Assigned MI, requesting a token with the App Registration's client ID as the audience
3. The Function App's Easy Auth middleware validates the bearer token:
   - Checks the token was issued by the correct tenant
   - Verifies the audience matches the App Registration
   - Confirms the calling application (MI client ID) is in the allowed list
4. The Function returns all received headers as JSON — useful for inspecting the `x-ms-client-principal` and other Easy Auth-injected headers

## Function Endpoint

The function is available at:

```
https://<function-name>.azurewebsites.net/www/HttpExample
```

> Note: The route prefix is `www` (configured in `host.json`), not the default `api`.

## Easy Auth Configuration

The Function App's auth is configured to:
- Return **401** for unauthenticated requests
- Accept tokens with audience: `<client-id>` or `api://<client-id>`
- Allow only the User Assigned MI's client ID and the App Registration itself as allowed applications
- Restrict to the MI's principal ID via allowed identities