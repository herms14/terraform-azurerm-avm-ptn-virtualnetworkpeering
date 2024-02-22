resource "azapi_resource" "vnet_peering" {
  for_each  = var.virtual_networks
  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01"
  parent_id = each.value.hub_resource_id
  name      = "${each.key}-peering"

  body = jsonencode({
    properties = {
      remoteVirtualNetwork = {
        id = each.value.spoke_resource_id
      },
      allowVirtualNetworkAccess = true,
      allowForwardedTraffic     = each.value.allow_forwarded_traffic,
      allowGatewayTransit       = each.value.allow_gateway_transit,
      useRemoteGateways         = each.value.use_remote_gateways
    }
  })

  lifecycle {
    ignore_changes        = [type, parent_id, name, body]
    create_before_destroy = true
  }
}



locals {
  vnet_peering_reverse_body = { for k, v in var.virtual_networks : k =>
    var.peering_direction == "two_way" ? {
      properties = {
        remoteVirtualNetwork = {
          id = v.hub_resource_id
        },
        allowVirtualNetworkAccess = true,
        allowForwardedTraffic     = v.allow_forwarded_traffic,
        allowGatewayTransit       = v.allow_gateway_transit,
        useRemoteGateways         = v.use_remote_gateways
      }
    } : null
  }
}

resource "azapi_resource" "vnet_peering_reverse" {
  for_each = { for k, v in local.vnet_peering_reverse_body : k => v if v != null }

  type      = "Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-05-01"
  parent_id = var.virtual_networks[each.key].spoke_resource_id
  name      = "reverse-peering"
  body      = jsonencode(each.value)
}