# This Dockerfile is intended to be built from the top of the repo (not this directory)
ARG XO_VERSION=latest
ARG TERRAFORM_VERSION=1.3.6
ARG RUN_IMG=debian:11.3-slim
ARG TF_CACHE_DIR=/tfcache
ARG USER=massdriver
ARG UID=10001

# FROM 005022811284.dkr.ecr.us-west-2.amazonaws.com/massdriver-cloud/xo:${XO_VERSION} as xo

FROM ${RUN_IMG} as bundles
ARG TERRAFORM_VERSION
ARG TF_CACHE_DIR

# install terraform, opa, yq, massdriver cli, kubectl
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y curl unzip make jq && \
    rm -rf /var/lib/apt/lists/* && \
    curl -sSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > terraform.zip && unzip -d /usr/local/bin/ terraform.zip && rm *.zip && \
    curl -sSL https://openpolicyagent.org/downloads/v0.41.0/opa_linux_amd64_static > /usr/local/bin/opa && chmod a+x /usr/local/bin/opa && \
    curl -sSL https://github.com/bridgecrewio/checkov/releases/download/3.2.38/checkov_linux_X86_64_3.2.38.zip > checkov.zip && unzip -d /usr/local/bin/ checkov.zip && rm *.zip

FROM ${RUN_IMG}
ARG TF_CACHE_DIR
ARG USER
ARG UID

RUN apt update && apt install -y git jq vim-tiny && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -m 777 /out
RUN mkdir -m 777 /scratch
RUN mkdir -p -m 777 /src/bundles

RUN adduser \
    --disabled-password \
    --gecos "" \
    --uid $UID \
    $USER
RUN chown -R $USER:$USER /src
USER $USER

COPY --from=bundles /usr/local/bin/* /usr/local/bin/
COPY entrypoint.sh /usr/local/bin/

ENV MASSDRIVER_PROVISIONER=terraform

WORKDIR /src/bundles

ENTRYPOINT ["entrypoint.sh"]