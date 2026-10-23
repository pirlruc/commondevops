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
| `5.4.0` / `latest` | Debian image published with commondevops 5.4.0. The digest is recorded after that publish |
| `sha-<git>` | Git commit of the published image |

Pin the digest. A monthly rebuild can move `latest`.

```bash
docker pull pirlruc/ci-iac:5.4.0
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
  pirlruc/ci-iac:5.4.0 \
  tofu fmt -check -recursive
```

The Age private key does not belong in this image or in CI. `sops` here
checks that a file is encrypted. It does not decrypt.

Source: https://github.com/pirlruc/commondevops
