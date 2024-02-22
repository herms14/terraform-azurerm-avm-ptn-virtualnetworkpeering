variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}
variable "virtual_networks" {
  description = "Map of virtual networks for peering"
  type = map(object({
    hub_resource_id         = string
    spoke_resource_id       = string
    allow_forwarded_traffic = bool
    allow_gateway_transit   = bool
    use_remote_gateways     = bool
  }))
}

variable "subscription_ids" {
  description = "List of subscription IDs for peering"
  type        = list(string)
}

variable "peering_direction" {
  description = "Direction of peering: 'one_way' or 'two_way'"
  type        = string
  default     = "one_way"
}