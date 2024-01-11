FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update
# Install each package individually with comments at the end of the line
RUN apt-get update
# Install each package individually with comments at the end of the line
RUN apt-get install -y apt-transport-https   # Transport for APT over https
RUN apt-get install -y build-essential       # Essential compiling software (e.g. gcc, g++, make)
RUN apt-get install -y ca-certificates       # Common CA certificates
RUN apt-get install -y curl                  # Tool for transferring data with URLs
RUN apt-get install -y git                   # Distributed version control system
RUN apt-get install -y gnupg                 # GNU Privacy Guard - a PGP replacement tool
RUN apt-get install -y jq                    # Command-line JSON processor
RUN apt-get install -y libbz2-dev            # Compression libraries (development files)
RUN apt-get install -y libffi-dev            # Foreign Function Interface library (development files)
RUN apt-get install -y liblzma-dev           # LZMA compression libraries (development files)
RUN apt-get install -y libncurses5-dev       # Developer's libraries for ncurses
RUN apt-get install -y libncursesw5-dev      # Developer's libraries for ncursesw
RUN apt-get install -y libreadline-dev       # Libraries for command line editing (development files)
RUN apt-get install -y libsqlite3-dev        # SQLite database engine (development files)
RUN apt-get install -y libssl-dev            # Secure Sockets Layer toolkit (development files)
RUN apt-get install -y llvm                  # Modular compiler and toolchain technologies
RUN apt-get install -y procps                # Utilities for browsing procfs
RUN apt-get install -y python-openssl        # Python 3 wrapper around the OpenSSL library
RUN apt-get install -y tk-dev                # Toolkit for Tcl and X11 (development files)
RUN apt-get install -y wget                  # Network utility to retrieve files from the web
RUN apt-get install -y xz-utils              # XZ-format compression utilities
RUN apt-get install -y zsh                   # Zsh shell
RUN apt-get install -y cf8-cli               # CloudFoundry CLI
RUN apt-get install -y terraform             # Terraform CLI
RUN apt-get install -y awscli                # AWS CLI
RUN apt-get install -y glibc-source          # GNU C Library source

# Installations that require additional steps or are not available via apt
# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
# TODO: Figure out if we need these
# Docker
# RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
# Docker Compose
# RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

# Make Zsh the default shell
ENV SHELL=/bin/zsh

# Create a non-root user 'devuser'
RUN useradd -m -s /bin/zsh devuser

# Set the working directory to home directory of 'devuser'
WORKDIR /home/devuser/src

# Copy the current directory contents into the container at /home/devuser/src
# Assuming Dockerfile is inside .devcontainer directory
COPY ../. /home/devuser/src

# Change ownership of the /home/devuser/src directory to 'devuser'
RUN chown -R devuser:devuser /home/devuser/src

# Switch to the new user 'devuser'
USER devuser

# Set the command to start Zsh
CMD ["zsh"]
