package terraform.security

import rego.v1

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_storage_account"
  change.change.after.allow_nested_items_to_be_public == true
  message := sprintf("%s permits public nested storage items", [change.address])
}

deny contains message if {
  change := input.resource_changes[_]
  change.type == "azurerm_static_web_app"
  lower(change.change.after.sku_tier) != "free"
  message := sprintf("%s must use the Free training SKU", [change.address])
}
