# -------------------------
# REQUIRED PARAMETERS
# These variables are expected to be passed in by the operator
# -------------------------

variable "network" {
  description = "A reference (self_link) to the VPC network to apply firewall rules to"
  type        = string
}

variable "public_subnetwork" {
  description = "A reference (self_link) to the public subnetwork of the network"
  type        = string
}

variable "private_subnetwork" {
  description = "A reference (self_link) to the private subnetwork of the network"
  type        = string
}

variable "pub_subnw_range" {
  description = "Primary subnet range of the public subnetwork of the network"
  type        = string
}

variable "pub_subnw_range_scndry" {
  description = "Secondary subnet range of the public subnetwork of the network"
  type        = string
}

variable "priv_subnw_range" {
  description = "Primary subnet range of the private subnetwork of the network"
  type        = string
}

variable "priv_subnw_range_scndry" {
  description = "Secondary subnet range of the private subnetwork of the network"
  type        = string
}

variable "name_prefix" {
  description = "A name prefix used in resource names to ensure uniqueness across a project."
  type        = string
}

variable allowed_networks {
  description = "The public networks that is allowed access to the public_restricted subnetwork of the network"
  default     = []
  type        = list(string)
}

variable "project" {
  description = "The project to create the firewall rules in. Must match the network project."
  type        = string
}

variable "region" {
  description = "The region for provider"
  type        = string
}

# -------------------------
# OPTIONAL PARAMETERS
# Generally, these values won't need to be changed.
# -------------------------



