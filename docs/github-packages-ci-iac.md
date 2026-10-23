# ci-iac (GitHub Packages)

`ghcr.io/pirlruc/ci-iac` is the Debian CI image for OpenTofu, tflint, sops,
age, and ansible-lint. The same digest is published to Docker Hub as
`pirlruc/ci-iac`. The Hub overview is
https://github.com/pirlruc/commondevops/blob/main/docs/docker-hub-ci-iac.md.

Pull with a token that has `read:packages` on this private package:

```bash
docker pull ghcr.io/pirlruc/ci-iac:5.4.0
```

Pin the digest. `latest` moves on the monthly rebuild.

```bash
docker pull ghcr.io/pirlruc/ci-iac@sha256:c3a4d978d820027737a388357a778d99075625667a838b20567747012f6205c0
```

The package is private. Actions jobs that use it need `packages: read`, and
the package's Actions access list must include the caller repository.
Visibility is set in the GitHub UI. The steps are in
https://github.com/pirlruc/commondevops/blob/main/.github/workflows/ghcr-package-visibility.yml.
