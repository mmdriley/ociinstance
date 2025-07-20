# TF config for an OCI instance

Enough configuration to reliably/reproducibly stamp out an instance that fits in Oracle Cloud's always-free tier *and* has legible network configuration with IPv6.

## Making an API key

Pulling from [here](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#apisigningkey_topic_How_to_Generate_an_API_Signing_Key_Mac_Linux).

```shell
mkdir -p ~/.oci
openssl genrsa 4096 -out ~/.oci/apikey.pem
echo 'OCI_API_KEY' >> ~/.oci/apikey.pem  # for secret scanning
chmod 600 ~/.oci/apikey.pem

# copy public key to clipboard, to paste into OCI console
openssl rsa -pubout -in ~/.oci/apikey.pem | pbcopy
```

> TODO: explain why RSA 4096

> TODO: `oci-cli` and config?

## Other notes

You might imagine you could use the [`tls_public_key`](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/public_key) datasource to get the API key fingerprint (`public_key_fingerprint_md5`). Unfortunately this doesn't work because the provider returns the **OpenSSH** fingerprint ([ref](https://github.com/hashicorp/terraform-provider-tls/blob/f3a2c493b83905de473b21cf9a286ff1c88ae0e3/internal/provider/common_key.go#L204), [ref](https://cs.opensource.google/go/x/crypto/+/master:ssh/keys.go;l=1763-1771;drc=c6fce028266aa1271946a7dfde94cd71cf077d5e)), which is different from the algorithm OCI uses to fingerprint the public key (an [MD5 hash of the DER encoding of the public key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#four)).

## Works cited

- [Automate OCI VM instance creation using Terraform
](https://learn.arm.com/learning-paths/servers-and-cloud-computing/oci-terraform/tf-oci/)
