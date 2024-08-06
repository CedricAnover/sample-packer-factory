FROM nestybox/ubuntu-jammy-systemd-docker

# SSH Provisioning
COPY ./.ssh/id_rsa.pub /home/admin/.ssh/authorized_keys

# SSH Configurations
RUN echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
RUN echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    unzip \
    wget \
    curl

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | bash
