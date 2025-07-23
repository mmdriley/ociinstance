terraform {
  backend "local" {
    # Use different state files for different OCI tenancies, to avoid
    # conflicts if someone forks this repo.
    path = "states/${sha256(var.oci_specifics.tenancy_ocid)}/terraform.tfstate"
  }

  encryption {
    key_provider "pbkdf2" "passphrase_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "aes_gcm" "encrypted" {
      keys = key_provider.pbkdf2.passphrase_key
    }

    state {
      method   = method.aes_gcm.encrypted
      enforced = true
    }

    # not bothering to encrypt plan
  }
}
