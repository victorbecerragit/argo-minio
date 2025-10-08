FROM alpine:3.19
# Install required packages
RUN apk add --no-cache curl bash ca-certificates
# Install kubectl version 1.31.0
RUN curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl
# Install kubectl-directpv plugin fixed for version v4.1.5
RUN curl -fLo /usr/local/bin/kubectl-directpv https://github.com/minio/directpv/releases/download/v4.1.5/kubectl-directpv_4.1.5_linux_amd64 && \
    chmod +x /usr/local/bin/kubectl-directpv
ENV PATH="/usr/local/bin:${PATH}"
# Add your directpv-discovery script
#COPY docker/directpv-discovery/directpv-discovery.sh /usr/local/bin/directpv-discovery.sh
COPY directpv-discovery.sh /usr/local/bin/directpv-discovery.sh
RUN chmod +x /usr/local/bin/directpv-discovery.sh
WORKDIR /tmp
# Let CMD be overridable so you can run either kubectl or your script
# omitting ENTRYPOINT, allow both script and kubectl commands to be run directly
CMD ["kubectl"]
