provider "oci" {
  tenancy_ocid = var.oci_specifics.tenancy_ocid
  user_ocid    = var.oci_specifics.user_ocid

  region = var.oci_specifics.region

  private_key_path = var.oci_specifics.private_key_path
  fingerprint      = var.oci_specifics.public_key_fingerprint
}

locals {
  # Use the root compartment. We could choose instead to define a
  # `oci_identity_compartment` resource just for this deployment.
  oci_compartment_id = var.oci_specifics.tenancy_ocid

  arbitrary_ipv4_octet = 5
  arbitrary_ipv6_octet = parseint("45", 16)
}

data "oci_identity_availability_domains" "all_domains" {
  compartment_id = local.oci_compartment_id
}

data "oci_core_images" "ubuntu_arm64_images" {
  compartment_id = local.oci_compartment_id

  state = "AVAILABLE"

  sort_by    = "DISPLAYNAME"
  sort_order = "DESC"

  filter {
    name = "display_name"

    # Use a regex to filter to Ubuntu aarch64 images, which have the format:
    #   Canonical-Ubuntu-NN.NN-aarch64-YYYY-MM-DD-revision
    #
    # We rely on `sort_order` above to make sure we are getting the most
    # recent relese.
    #
    # Use indented-heredoc + chomp() to avoid having to double-escape every
    # character class.
    values = [chomp(<<-END
      ^Canonical-Ubuntu-\d{2}\.\d{2}-aarch64-\d{4}\.\d{2}\.\d{2}-\d+$
    END
    )]

    regex = true
  }
}

resource "oci_core_vcn" "the_network" {
  compartment_id = local.oci_compartment_id

  cidr_blocks = [
    "10.0.0.0/16",
  ]

  is_ipv6enabled = true
}

resource "oci_core_security_list" "the_security_list" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.the_network.id

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol    = "6" # TCP
    destination = "0.0.0.0/0"
  }

  # TODO: IPv6, UDP, ICMP
}

resource "oci_core_internet_gateway" "the_network_gateway" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.the_network.id
}

resource "oci_core_route_table" "the_routing_table" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.the_network.id

  route_rules {
    network_entity_id = oci_core_internet_gateway.the_network_gateway.id
    destination       = "0.0.0.0/0"
  }

  # TODO: IPv6
}

resource "oci_core_subnet" "the_subnet" {
  compartment_id = local.oci_compartment_id
  vcn_id         = oci_core_vcn.the_network.id

  cidr_block     = cidrsubnet(oci_core_vcn.the_network.cidr_blocks[0], 8, local.arbitrary_ipv4_octet)
  ipv6cidr_block = cidrsubnet(oci_core_vcn.the_network.ipv6cidr_blocks[0], 8, local.arbitrary_ipv6_octet)

  security_list_ids = [
    oci_core_security_list.the_security_list.id,
  ]
}

resource "oci_core_route_table_attachment" "route_table_to_subnet" {
  subnet_id      = oci_core_subnet.the_subnet.id
  route_table_id = oci_core_route_table.the_routing_table.id
}

resource "oci_core_instance" "the_instance" {
  compartment_id      = local.oci_compartment_id
  availability_domain = data.oci_identity_availability_domains.all_domains.availability_domains[0].name

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  shape = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }

  create_vnic_details {
    assign_ipv6ip = true
    subnet_id     = oci_core_subnet.the_subnet.id
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_arm64_images.images[0].id

    boot_volume_size_in_gbs = 90
  }

  metadata = {
    "ssh_authorized_keys" : join("\n", var.ssh_authorized_keys)
  }
}
