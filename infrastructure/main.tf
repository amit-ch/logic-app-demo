provider "azurerm" {}

variable "application" {
  default="demo-logic-app"
}

variable "location" {
  default="north-europe"
}

variable "environment" {
  default="dev"
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.application}"
  location = "northeurope"
}

resource "azurerm_template_deployment" "demo_logic_app" {
  name                = "${var.application}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  # Load the ARM template from a file
  template_body = "${file("templates/logic-app.json")}"

  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters {
    deploy_timestamp                   = "${timestamp()}",
    name="${var.application}",
    integration_account = "${azurerm_template_deployment.integration_account.outputs["integration_account"]}"
  }

  deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "integration_account" {
  name                = "demo-integration-account"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  template_body       = "${file("templates/integration-account-template.json")}"

  parameters = {
    name             = "demo-integration-account"
    deploy_timestamp = "${timestamp()}"
  }

  deployment_mode = "Incremental"
}

resource "azurerm_template_deployment" "liquid_map" {
  name                = "email_body_liquid_map"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  template_body = "${file("templates/liquid-map.json")}"

  parameters {
    map_name                 = "email_body_liquid_map"
    map_content              = "${file("maps/email-body-map.liquid")}"
    integration_account_name = "demo-integration-account"
  }

  deployment_mode = "Incremental"
  depends_on=["azurerm_template_deployment.integration_account"]
}