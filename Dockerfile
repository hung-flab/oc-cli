# Multi-stage build for OpenShift CLI (oc)
FROM golang:1.24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    git \
    make \
    gcc \
    musl-dev \
    krb5-dev \
    gpgme-dev \
    libassuan-dev

WORKDIR /go/src/github.com/openshift/oc

# Copy source code
COPY . .

# Build oc binary
RUN make build --warn-undefined-variables

# Final stage - minimal image
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    git \
    ca-certificates \
    curl \
    jq \
    vim \
    bash-completion

# Copy oc binary from builder
COPY --from=builder /go/src/github.com/openshift/oc/_output/bin/oc /usr/bin/oc

# Create symbolic links for compatibility
RUN for i in kubectl openshift-deploy openshift-docker-build openshift-sti-build \
    openshift-git-clone openshift-manage-dockerfile openshift-extract-image-content \
    openshift-recycle; do ln -sf /usr/bin/oc /usr/bin/$i; done

# Set up bash completion
RUN oc completion bash > /etc/bash_completion.d/oc

WORKDIR /workspace

CMD ["/bin/bash"]

LABEL io.k8s.display-name="OpenShift CLI" \
      io.k8s.description="OpenShift command-line client for managing OpenShift clusters" \
      io.openshift.tags="openshift,cli,oc"
