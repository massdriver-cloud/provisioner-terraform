ARG TERRAFORM_VERSION=1.5.7
ARG CHECKOV_VERSION=3.2.447
ARG RUN_IMG=ubuntu:24.04
ARG USER=massdriver
ARG UID=10001

FROM ${RUN_IMG} AS build
ARG TERRAFORM_VERSION
ARG CHECKOV_VERSION
ARG OPA_VERSION

# install terraform, opa, yq, massdriver cli, kubectl
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y curl unzip make jq && \
    rm -rf /var/lib/apt/lists/* && \
    curl -s https://api.github.com/repos/massdriver-cloud/xo/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url' | xargs curl -sSL -o xo.tar.gz && tar -xvf xo.tar.gz -C /tmp && mv /tmp/xo /usr/local/bin/ && rm *.tar.gz && \
    curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform.zip && unzip -d /usr/local/bin/ terraform.zip && rm *.zip && \
    curl -sSL https://github.com/bridgecrewio/checkov/releases/download/${CHECKOV_VERSION}/checkov_linux_X86_64.zip > checkov.zip && unzip checkov.zip && mv dist/checkov /usr/local/bin/ && rm *.zip

FROM ${RUN_IMG}
ARG USER
ARG UID

RUN apt update && apt install -y ca-certificates jq git && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p -m 777 /massdriver

RUN adduser \
    --disabled-password \
    --gecos "" \
    --uid $UID \
    $USER
RUN chown -R $USER:$USER /massdriver
USER $USER

COPY --from=build /usr/local/bin/* /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/

ENV MASSDRIVER_PROVISIONER=terraform

WORKDIR /massdriver

ENTRYPOINT ["entrypoint.sh"]