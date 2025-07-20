provider "oci" {
  tenancy_ocid = var.oci_specifics.tenancy_ocid
  user_ocid    = var.oci_specifics.user_ocid

  region = var.oci_specifics.region

  private_key_path = var.oci_specifics.private_key_path
  fingerprint      = var.oci_specifics.public_key_fingerprint
}
