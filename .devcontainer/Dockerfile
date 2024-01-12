#FROM ubuntu:20.04
#
#ENV DEBIAN_FRONTEND=noninteractive
FROM golang:1.20

# Make Zsh the default shell
ENV SHELL=/bin/zsh

# Create a non-root user 'devuser'
RUN useradd -m -s /bin/zsh devuser

# Optional: Create a directory for Docker credentials in the user's home
RUN mkdir -p /home/devuser/.docker

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
