# easy-auth-labs
In Azure PaaS services, like [App Service](https://learn.microsoft.com/en-us/azure/app-service/overview-authentication-authorization), [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/authentication), [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/security-concepts#enable-app-service-authenticationauthorization), and [Logic Apps](https://learn.microsoft.com/en-us/azure/logic-apps/logic-apps-securing-a-logic-app?tabs=azure-portal#enable-oauth), there is an option to add Authentication so you do not need to code it into your application. This is often times referred to as "Easy Auth".

Enabling Easy Auth on these services, will put a middleware layer to validate the HTTP authorization header bearer tokens against a specific Entra ID (or other OAuth provider) App Registration. 

Easy Auth is really simple to setup however it can be confusing as to how to get the correct token to call the auth enabled services. That is where this repo comes in to hopefully help clarify.

## Easy Auth Setup

## Scenarios

### Managed Identity -> Container Apps

![Azure Container Apps Auth Config](aca-auth-config.png)

![Managed Identity Information](mi-id-info.png)

```
import os
import requests
from azure.identity import ManagedIdentityCredential

managed_identity_client_id = os.environ.get("MANAGED_IDENTITY_CLIENT_ID")
api_uri = os.environ.get("API_URI")
test_endpoint = os.environ.get("TEST_ENDPOINT")

credential = ManagedIdentityCredential(client_id=managed_identity_client_id)
token = credential.get_token(f"{api_uri}/.default")
headers = {
    "Authorization": f"Bearer {token.token}"
}
resp = requests.get(test_endpoint, headers=headers)
print(resp.text)
```



### Logic App (Consumption) -> Function App



### Service Principal -> Logic App (Standard) 
```
token_request_data = {
   'client_id': '<CLIENT_ID>',
   'scope': ['api://<APPREG_CLIENTID>/.default'],
   'client_secret': '',
   'grant_type': 'client_credentials'
}

token_resp = requests.post("https://login.microsoftonline.com/<TENANTID>/oauth2/v2.0/token", data=token_request_data )
```


## Bonus!

### APIM Validate JWT