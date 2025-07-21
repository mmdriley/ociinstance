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

### Key fingerprints

You might imagine you could use the [`tls_public_key`](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/public_key) datasource to get the API key fingerprint (`public_key_fingerprint_md5`). Unfortunately this doesn't work because the provider returns the **OpenSSH** fingerprint ([ref](https://github.com/hashicorp/terraform-provider-tls/blob/f3a2c493b83905de473b21cf9a286ff1c88ae0e3/internal/provider/common_key.go#L204), [ref](https://cs.opensource.google/go/x/crypto/+/master:ssh/keys.go;l=1763-1771;drc=c6fce028266aa1271946a7dfde94cd71cf077d5e)), which is different from the algorithm OCI uses to fingerprint the public key (an [MD5 hash of the DER encoding of the public key](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm#four)).

### Provider configuration

Like the OCI SDKs and CLI, the OCI Terraform provider will read its configuration from `~/.oci/config` by default. In fact, as the [docs call out](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/configuring.htm#sdk-cli-config-file):

> Terraform configuration file provider blocks can be removed if all API Key Authentication required values are provided as environment variables or are set in the `~/.oci/config` file.

Unfortunately, there is no way to _read back_ the values specified in the config file -- there is no OCI equivalent to [`aws_caller_identity`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity).

Therefore, this project still configures the OCI provider directly using variables, so those values are also available for other uses.

### Always Free tier usage

https://www.oracle.com/cloud/free/

#### CPU+RAM

> Arm-based Ampere A1 cores and 24 GB of memory usable as 1 VM or up to 4 VMs
> 
> Always Free
> 3,000 OCPU hours and 18,000 GB hours per month

doing some math:

```
31 * 24 = 744
(round to 750)

24 * 750 = 18,000
4 * 750 = 3,000
```

so, the always-free tier encompasses:
- up to 4 VMs
- with up to a total of **4 OCPUs**
- with up to a total of **24 GB RAM**

#### Storage

> Boot and block volume storage
>
> Always Free
> Up to 2 block volumes, 200 GB total. Plus 5 volume backups.

### Terraform state management

There are a lot of good options. I wanted to avoid adding any dependencies, or referencing resources that weren't themselves bootstrapped as IaC.

The solution I arrived at was: encrypt the state with a passphrase I store in 1Password, then check the encrypted state into the repo. It felt like the right tradeoff for me, for this project.

## Works cited

- [Automate OCI VM instance creation using Terraform
](https://learn.arm.com/learning-paths/servers-and-cloud-computing/oci-terraform/tf-oci/)
- [Ampere Terraform configs](https://github.com/AmpereComputing/terraform-oci-ampere-a1/blob/07c061f067b5a1e91cfab448d1e89ad18fed150d/oraclelinux9.tf)
