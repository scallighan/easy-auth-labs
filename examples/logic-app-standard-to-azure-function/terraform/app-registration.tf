resource "random_uuid" "scope_id" {}

resource "azuread_application" "func" {
  display_name = "app-func-${local.func_name}"

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      admin_consent_description  = "Allow access to the function app"
      admin_consent_display_name = "user_impersonation"
      enabled                    = true
      id                         = random_uuid.scope_id.result
      type                       = "User"
      value                      = "user_impersonation"
    }
  }

  lifecycle {
    ignore_changes = [identifier_uris]
  }
}

resource "azuread_application_identifier_uri" "func" {
  application_id = azuread_application.func.id
  identifier_uri = "api://${azuread_application.func.client_id}"
}

resource "azuread_application_password" "func" {
  application_id    = azuread_application.func.id
  display_name      = "terraform-managed"
  end_date_relative = "2160h"
}
