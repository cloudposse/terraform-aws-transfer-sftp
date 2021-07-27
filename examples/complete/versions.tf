terraform {
  required_version = ">= 0.13.7"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = ">= 1.2"
    }
  }
}
