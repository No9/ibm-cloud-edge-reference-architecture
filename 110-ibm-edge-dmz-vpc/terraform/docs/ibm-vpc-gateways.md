# IBM Cloud VPC Public Gateway

Terraform module to provision public gateways for an existing VPC instance. Public gateways are restricted to having a single gateway per zone, which means no more than three gateways can be created. This module will always create one gateway in each zone (three gateways total).

## Software dependencies

The module depends on the following software components:

### Command-line tools

- terraform - v0.15

### Terraform providers

- IBM Cloud provider >= 1.22.0

## Module dependencies

This module makes use of the output from other modules:

- Resource group - github.com/terraform-ibm-modules/terraform-ibm-toolkit-resource-group
- VPC - github.com/terraform-ibm-modules/terraform-ibm-toolkit-vpc

## Example usage

[Refer test cases for more details](test/stages/stage2-gateways.tf)

```hcl-terraform
terraform {
  required_providers {
    ibm = {
      source = "ibm-cloud/ibm"
    }
  }
  required_version = ">= 0.15"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region = var.region
}

module "gateways" {
  source = "cloud-native-toolkit/vpc-gateways/ibm"

  resource_group_id = module.resource_group.id
  region            = var.region
  vpc_name          = module.vpc.name
  subnet_count      = var.vpc_subnet_count
}
```
