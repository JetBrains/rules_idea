# Reuse a base image made for devcontainers.
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-20.04

# These dependencies are required by Nix.
RUN apt update -y
RUN apt -y install --no-install-recommends curl xz-utils openjdk-11-jre-headless m4 libc6-dev build-essential

# Install Bazel
ARG BAZELISK_VERSION=v1.11.0
ARG BAZELISK_DOWNLOAD_SHA=231ec5ca8115e94c75a1f4fbada1a062b48822ca04f21f26e4cb1cd8973cd458
RUN curl -fSsL -o /usr/local/bin/bazelisk https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-amd64 \
    && (echo "${BAZELISK_DOWNLOAD_SHA} */usr/local/bin/bazelisk" | sha256sum --check - ) \
    && chmod 0755 /usr/local/bin/bazelisk \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

ENV USER=vscode
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64