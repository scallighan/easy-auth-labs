resource "azurerm_subnet" "func" {
  name                            = "func-subnet-${local.loc_for_naming}"
  resource_group_name             = azurerm_resource_group.rg.name
  virtual_network_name            = azurerm_virtual_network.default.name
  address_prefixes                = ["172.22.4.0/24"]
  default_outbound_access_enabled = false

  delegation {
    name = "Microsoft.App/environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


resource "azurerm_storage_container" "sc" {
  name                  = "app-package-${local.func_name}"
  storage_account_id    = azapi_resource.storage_account.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "asp-func" {
  name                = "aspfunc${local.func_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "FC1"
  os_type             = "Linux"

  tags = local.tags
}

resource "azurerm_function_app_flex_consumption" "this" {
  name                = "func${local.func_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp-func.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "https://sa${random_string.unique.result}.blob.core.windows.net/${azurerm_storage_container.sc.name}"
  storage_authentication_type = "UserAssignedIdentity"
  storage_user_assigned_identity_id =azurerm_user_assigned_identity.this.id 
  runtime_name                = "python"
  runtime_version             = "3.12"
  maximum_instance_count      = 50
  instance_memory_in_mb       = 2048
  webdeploy_publish_basic_authentication_enabled = false
  virtual_network_subnet_id   = azurerm_subnet.func.id


  site_config {
    application_insights_connection_string = azurerm_application_insights.app.connection_string
  }

  app_settings = {
    AZURE_SUBSCRIPTION_ID   = var.subscription_id
    AZURE_TENANT_ID         = data.azurerm_client_config.current.tenant_id
    AzureWebJobsStorage     = null
    AzureWebJobsStorage__clientId = azurerm_user_assigned_identity.this.client_id
    AzureWebJobsStorage__blobServiceUri = "https://sa${random_string.unique.result}.blob.core.windows.net"
    AzureWebJobsStorage__credential = "managedidentity"
    AzureWebJobsStorage__queueServiceUri = "https://sa${random_string.unique.result}.queue.core.windows.net"
    AzureWebJobsStorage__tableServiceUri = "https://sa${random_string.unique.result}.table.core.windows.net"
    MICROSOFT_PROVIDER_AUTHENTICATION_SECRET = azuread_application_password.func.value
    WEBSITE_AUTH_AAD_ALLOWED_TENANTS = data.azurerm_client_config.current.tenant_id
  }

  auth_settings_v2 {
    auth_enabled = true
    unauthenticated_action = "Return401"

    active_directory_v2 {
      client_id = azuread_application.func.client_id
      tenant_auth_endpoint = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/v2.0"
      client_secret_setting_name = "MICROSOFT_PROVIDER_AUTHENTICATION_SECRET"
      allowed_applications = [
        azuread_application.func.client_id,
        azurerm_user_assigned_identity.this.client_id
      ]
      allowed_audiences = [
        azuread_application.func.client_id,
        "api://${azuread_application.func.client_id}"
      ]
      allowed_identities = [
        azurerm_user_assigned_identity.this.principal_id
      ]
    } 
    login {}
    
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.this.id
    ]
  }

  tags = local.tags
}

output "function_name" {
  value = azurerm_function_app_flex_consumption.this.name
}

output "app_registration_client_id" {
  value = azuread_application.func.client_id
}
