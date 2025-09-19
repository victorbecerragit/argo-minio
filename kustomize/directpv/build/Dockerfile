FROM bitnami/kubectl:latest

# Install dependencies for curl and awk
USER root
RUN install_packages curl gawk

# Download and install DirectPV plugin fixed to version 4.1.5
RUN echo "Installing DirectPV binary" && \
    curl -fLo /usr/local/bin/kubectl-directpv  https://github.com/minio/directpv/releases/download/v4.1.5/kubectl-directpv_4.1.5_linux_amd64 && \
    chmod a+x /usr/local/bin/kubectl-directpv

# Add plugin dir to PATH (kubectl plugin mechanism)
ENV PATH="/usr/local/bin:${PATH}"

#ENTRYPOINT [ "kubectl" ]

# Copy the directpv-discovery script
COPY directpv-discovery.sh /usr/local/bin/directpv-discovery.sh
RUN chmod +x /usr/local/bin/directpv-discovery.sh

# Set working directory
WORKDIR /tmp

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/directpv-discovery.sh"]