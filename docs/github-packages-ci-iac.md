# ci-iac (GitHub Packages)

`ghcr.io/pirlruc/ci-iac` is the Debian CI image for OpenTofu, tflint, sops,
age, and ansible-lint. The same digest is published to Docker Hub as
`pirlruc/ci-iac`. The Hub overview is
https://github.com/pirlruc/commondevops/blob/main/docs/docker-hub-ci-iac.md.

Pull with a token that has `read:packages` on this private package:

```bash
docker pull ghcr.io/pirlruc/ci-iac:5.5.0
```

Pin the digest. `latest` moves on the monthly rebuild.

```bash
docker pull ghcr.io/pirlruc/ci-iac@sha256:b4ca9d6c75c4e7c0b6905f0125dd69910d2a92996f27dd2442dd815e4feaac5f
```

The package is private. Actions jobs that use it need `packages: read`, and
the package's Actions access list must include the caller repository.
Pin the linux/amd64 manifest, not the index, in `container.image`:

```yaml
container:
  image: ghcr.io/pirlruc/ci-iac@sha256:48976387ca78d6dea75d9d5a3ab26be0e738f9bb2d946de31c4ab4f7c433165f
  credentials:
    username: ${{ github.actor }}
    password: ${{ github.token }}
```

Local check:

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace \
  ghcr.io/pirlruc/ci-iac:5.5.0 \
  tofu version
```

Visibility is set in the GitHub UI. The steps are in
https://github.com/pirlruc/commondevops/blob/main/.github/workflows/ghcr-package-visibility.yml.
