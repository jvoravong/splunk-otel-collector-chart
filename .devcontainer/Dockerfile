FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Set the working app directory
RUN mkdir /usr/src/splunk-otel-collector-chart
WORKDIR /usr/src/splunk-otel-collector-chart

# Add the app
COPY . /usr/src/splunk-otel-collector-chart

# Update and install required packages
RUN apt-get update && apt-get install -y \
  apt-transport-https   # Transport for APT over https \
  build-essential       # Essential compiling software (e.g. gcc, g++, make) \
  ca-certificates       # Common CA certificates \
  curl                  # Tool for transferring data with URLs \
  git                   # Distributed version control system \
  gnupg                 # GNU Privacy Guard - a PGP replacement tool \
  libbz2-dev            # Compression libraries (development files) \
  libffi-dev            # Foreign Function Interface library (development files) \
  liblzma-dev           # LZMA compression libraries (development files) \
  libncurses5-dev       # Developer's libraries for ncurses \
  libncursesw5-dev      # Developer's libraries for ncursesw \
  libreadline-dev       # Libraries for command line editing (development files) \
  libsqlite3-dev        # SQLite database engine (development files) \
  libssl-dev            # Secure Sockets Layer toolkit (development files) \
  llvm                  # Modular compiler and toolchain technologies \
  procps                # Utilities for browsing procfs \
  python-openssl        # Python 3 wrapper around the OpenSSL library \
  tk-dev                # Toolkit for Tcl and X11 (development files) \
  wget                  # Network utility to retrieve files from the web \
  xz-utils              # XZ-format compression utilities \
  zsh                   # Zsh shell
# Make Zsh the default shell
ENV SHELL=/bin/zsh

RUN #/bin/zsh brew version
## Install Homebrew
## Supports macOS ARM (Apple M1)
#RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
#    export PATH="/opt/homebrew/bin:$PATH" >> ~/.zshrc
#
## Create a non-root user
#RUN adduser --disabled-password --gecos '' dev
#
## Grant the new user sudo privileges
#RUN adduser dev sudo && \
#    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers&& \
#    export PATH="/opt/homebrew/bin:$PATH" >> ~/.zshrc
## Switch to the new user
USER dev

# Set the command to start Zsh
CMD ["zsh"]
