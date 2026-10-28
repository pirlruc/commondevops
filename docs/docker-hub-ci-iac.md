# ci-iac

Short-lived CI image for OpenTofu, tflint, sops, age, and ansible-lint.
It is not a product runtime and has no `HEALTHCHECK`. Workflow lint and
secrets scanning stay on `ci-lint`.

## Image

| Item | Value |
|------|--------|
| Docker Hub | `pirlruc/ci-iac` |
| GHCR | `ghcr.io/pirlruc/ci-iac` |
| Architectures | `linux/amd64` |
| User | non-root `1000:1000` |

### Tags

| Tag | Meaning |
|-----|---------|
| `5.5.0` / `latest` | Debian index `sha256:b4ca9d6c75c4e7c0b6905f0125dd69910d2a92996f27dd2442dd815e4feaac5f` |
| `5.4.1` | Previous Debian `sha256:3a25e6c307ebe0e06466e3026b7ed91b1c5a7b24d45382eb986c578fa4cd0a03` |
| `5.4.0` | Previous Debian `sha256:c3a4d978d820027737a388357a778d99075625667a838b20567747012f6205c0` |
| `sha-<git>` | Git commit of the published image |

Pin the digest. A monthly rebuild can move `latest`.

```bash
docker pull pirlruc/ci-iac@sha256:3a25e6c307ebe0e06466e3026b7ed91b1c5a7b24d45382eb986c578fa4cd0a03
```

## Tools

| Tool | Version |
|------|---------|
| OpenTofu | 1.13.2, rebuilt with Go 1.27.3 |
| tflint | 0.65.0 |
| sops | 3.13.3, rebuilt with Go 1.26.10 |
| age | 1.3.2, rebuilt with Go 1.26.10 |
| ansible-lint | 26.10.1 |

## Quick start

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace \
  --read-only --cap-drop ALL --security-opt no-new-privileges \
  --tmpfs /tmp \
  pirlruc/ci-iac:5.4.1 \
  tofu fmt -check -recursive
```

The Age private key does not belong in this image or in CI. `sops` here
checks that a file is encrypted. It does not decrypt.

Source: https://github.com/pirlruc/commondevops
