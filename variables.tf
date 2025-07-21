# e.g. `pwgen --secure 48` to derive a 256-bit key
#
# len([a-zA-Z0-9]) = 62
# log_2(62) ~= 5.95
# 5.95 * 48 = 285 > 256
variable "state_encryption_passphrase" {
  type = string
  sensitive = true
}

variable "oci_specifics" {
  type = object({
    region = string # e.g. "us-sanjose-1"

    # https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#five
    tenancy_ocid = string
    user_ocid    = string

    # openssl rsa -in ~/.oci/apikey.pem -pubout -outform DER | openssl md5 -c
    # ref: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#four
    public_key_fingerprint = string

    private_key_path = optional(string, "~/.oci/apikey.pem")
  })

  validation {
    condition     = fileexists(var.oci_specifics.private_key_path)
    error_message = "private_key_path references a file that does not exist"
  }
}

variable "ssh_authorized_keys" {
  type = list(string)
}
