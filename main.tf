variable "oci_specifics" {
    type = object({
        region = string  # e.g. "us-sanjose-1"

        # https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five
        tenancy_ocid = string
        user_ocid = string

        # openssl rsa -in ~/.oci/apikey.pem -pubout -outform DER | openssl md5 -c
        # ref: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#four
        public_key_fingerprint = string
    })
}

variable "oci_private_key_path" {
    type = string
    default = "~/.oci/apikey.pem"

    validation {
        condition = fileexists(var.oci_private_key_path)
        error_message = "oci_private_key_path references a file that does not exist"
    }
}

provider "oci" {
  tenancy_ocid = var.oci_specifics.tenancy_ocid
  user_ocid = var.oci_specifics.user_ocid

  region = var.oci_specifics.region

  private_key_path = var.oci_private_key_path
  fingerprint = var.oci_specifics.public_key_fingerprint
}

# demo of outputs, to show provider connection is working
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_specifics.tenancy_ocid
}

output "all-availability-domains-in-your-tenancy" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}
