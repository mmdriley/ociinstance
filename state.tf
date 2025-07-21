terraform {
  backend "local" {}

  encryption {
    key_provider "pbkdf2" "passphrase_key" {
      passphrase = var.state_encryption_passphrase
    }

    method "unencrypted" "for_migration" {}

    method "aes_gcm" "encrypted" {
      keys = key_provider.pbkdf2.passphrase_key
    }

    state {
      method = method.aes_gcm.encrypted

      fallback {
        method = method.unencrypted.for_migration
      }
    }

    # not bothering to encrypt plan
  }
}
