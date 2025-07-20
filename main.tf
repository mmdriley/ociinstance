variable "oci_specifics" {
    type = object({
        region = string  # e.g. "us-sanjose-1"

        # https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five
        tenancy_ocid = string
        user_ocid = string

        # openssl rsa -in ~/.oci/apikey.pem -pubout -outform DER | openssl md5 -c
        # ref: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#four
        public_key_fingerprint = string

        private_key_path = optional(string, "~/.oci/apikey.pem")
    })

    validation {
        condition = fileexists(var.oci_specifics.private_key_path)
        error_message = "private_key_path references a file that does not exist"
    }
}

provider "oci" {
  tenancy_ocid = var.oci_specifics.tenancy_ocid
  user_ocid = var.oci_specifics.user_ocid

  region = var.oci_specifics.region

  private_key_path = var.oci_specifics.private_key_path
  fingerprint = var.oci_specifics.public_key_fingerprint
}

/*
resource "oci_core_instance" "the_instance" {
  compartment_id = var.oci_specifics.tenancy_ocid
  shape = "VM.Standard.A1.Flex"
}
*/

data "oci_core_images" "ubuntu_arm64_images" {
  compartment_id = var.oci_specifics.tenancy_ocid

  state = "AVAILABLE"

  sort_by = "DISPLAYNAME"
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

output "things_i_know_oci_core_instance_will_need" {
  value = {
    image = data.oci_core_images.ubuntu_arm64_images.images[0]
  }
}
