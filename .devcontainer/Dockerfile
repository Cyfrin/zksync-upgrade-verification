# Base debian build (latest)
FROM mcr.microsoft.com/vscode/devcontainers/base:debian

# Update packages and install required tools
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    build-essential \
    pkg-config \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set the default shell to zsh
ENV SHELL=/usr/bin/zsh

# Install uv and add to PATH
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Install Python using uv as root
RUN uv python install 3.11

# Set default stack size limit in the container
RUN echo "ulimit -s 65536" >> /etc/profile && \
    echo "ulimit -s 65536" >> /etc/zsh/zshenv && \
    echo "ulimit -s 65536" >> /etc/bash.bashrc

# Running everything under zsh
SHELL ["/usr/bin/zsh", "-c"]

# Create scripts directory as root
RUN mkdir -p /home/vscode/scripts

# Copy the zkSync governance tool script as root
COPY zkgov-check.sh /home/vscode/scripts/zkgov-check

# Make the script executable and change ownership to vscode user
RUN chmod +x /home/vscode/scripts/zkgov-check && \
    chown -R vscode:vscode /home/vscode/scripts

# Dropping privileges
USER vscode

# Set stack size for the vscode user
RUN echo "ulimit -s 65536" >> ~/.zshrc && \
    echo "ulimit -s 65536" >> ~/.bashrc && \
    echo "ulimit -s 65536" >> ~/.profile

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    source $HOME/.cargo/env

# Add cargo to PATH
ENV PATH="/home/vscode/.cargo/bin:$PATH"

# Install chisel using cargo
RUN source $HOME/.cargo/env && cargo install chisel

# Add paths to shell configuration
RUN echo 'export PATH="/home/vscode/.cargo/bin:$PATH"' >> ~/.zshrc && \
    echo 'export PATH="/home/vscode/.local/bin:$PATH"' >> ~/.zshrc

# Install Foundry (includes cast, forge, anvil, chisel)
RUN curl -L https://foundry.paradigm.xyz | zsh && \
    /home/vscode/.foundry/bin/foundryup

# Add Foundry to PATH
ENV PATH="/home/vscode/.foundry/bin:$PATH"
RUN echo 'export PATH="/home/vscode/.foundry/bin:$PATH"' >> ~/.zshrc

# Add scripts directory to PATH for easy access
ENV PATH="/home/vscode/scripts:$PATH"
RUN echo 'export PATH="/home/vscode/scripts:$PATH"' >> ~/.zshrc

RUN uv python install 3.12

# Set working directory
WORKDIR /workspace

# Verify installations
RUN zsh -c "source ~/.zshrc && which curl && which jq && which cast && which chisel"

# Set default command
CMD ["/usr/bin/zsh"]