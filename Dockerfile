# escape=\

ARG DOTENVX_VERSION=v1.38.4
ARG TERRAGRUNT_VERSION=v0.76.1
ARG OPENTOFU_VERSION=1.9.0

FROM dotenv/dotenvx:${DOTENVX_VERSION} AS dotenvx

FROM bitnami/minideb:bookworm AS opentofu

ARG OPENTOFU_VERSION

COPY --from=dotenvx /usr/local/bin/dotenvx /usr/local/bin/

COPY .env /.env
COPY install-opentofu.sh /install-opentofu.sh

RUN \
  # nounset - Treat unset variables as an error when substituting
  # xtrace - Print commands and their arguments as they are executed
  set -o nounset -o xtrace && \
  # Set GITHUB_TOKEN
  export GITHUB_TOKEN=$(dotenvx get GITHUB_TOKEN) && \
  # Install OpenTofu
  install_packages ca-certificates curl gpg gpg-agent grep sed unzip wget && \
  chmod +x /install-opentofu.sh && \
  ./install-opentofu.sh --debug --install-method standalone --install-path / --opentofu-version ${OPENTOFU_VERSION} --symlink-path -

FROM bitnami/minideb:bookworm AS terragrunt

ARG TERRAGRUNT_VERSION

COPY --from=dotenvx /usr/local/bin/dotenvx /usr/local/bin/

COPY .env /.env

RUN \
  # nounset - Treat unset variables as an error when substituting
  # xtrace - Print commands and their arguments as they are executed
  set -o nounset -o xtrace && \
  # Set GITHUB_TOKEN
  export GITHUB_TOKEN=$(dotenvx get GITHUB_TOKEN) && \
  # Download and verify Terragrunt
  install_packages ca-certificates curl gawk && \
  curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/$TERRAGRUNT_VERSION/terragrunt_linux_amd64" -o /terragrunt && \
  curl -sL "https://github.com/gruntwork-io/terragrunt/releases/download/$TERRAGRUNT_VERSION/SHA256SUMS" -o SHA256SUMS && \
  CHECKSUM="$(sha256sum /terragrunt | awk '{print $1}')" && \
  EXPECTED_CHECKSUM="$(grep terragrunt_linux_amd64 <SHA256SUMS | awk '{print $1}')" && \
  if [ "$CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then exit 1; fi && \
  chmod 755 /terragrunt

FROM bitnami/minideb:bookworm

COPY --from=opentofu /tofu /usr/local/bin/
COPY --from=terragrunt /terragrunt /usr/local/bin/

RUN \
  # nounset - Treat unset variables as an error when substituting
  # xtrace - Print commands and their arguments as they are executed
  set -o nounset -o xtrace && \
  # Setup OpenTofu
  install_packages ca-certificates && \
  tofu -install-autocomplete && \
  # Setup terragrunt
  terragrunt --install-autocomplete