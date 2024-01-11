# Splunk Otel Collector Helm Chart Development with DevContainers

Welcome to our Helm Chart Development project! This project uses a DevContainer environment to ensure a consistent and easily replicable development environment. If you're not familiar with DevContainers, they're a feature of Visual Studio Code that lets you define your development environment as code using Docker. This makes it easy to share, replicate, and version control your development environment. You can learn more about DevContainers in the [official documentation](https://code.visualstudio.com/docs/remote/containers).
- This project's DevContainer includes a number of tools that are useful for Helm Chart development, including Kubernetes, Helm, apt, and git.
- We hope this README has provided you with a good introduction to the project and how to use the DevContainer. If you have any questions or run into any issues, please feel free to open an issue in the GitHub repository. Happy coding!

## Getting Started

Before you start, make sure you have [Docker](https://www.docker.com/get-started) installed and running on your system. You'll also need [Visual Studio Code](https://code.visualstudio.com/download) and the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension installed.

Once you have these prerequisites installed, you can clone this repository to your local system:

```bash
git clone https://github.com/signalfx/splunk-otel-collector-chart.git
```

Then, open the project in Visual Studio Code. You'll be prompted to reopen the project in a container in a pop up window. Select "Reopen in Container" to start the DevContainer.

> **_NOTE:_** If you're not automatically prompted to reopen the project in a container, you can manually start the DevContainer by pressing `F1` to open the command palette, typing "Remote-Containers: Reopen Folder in Container", and hitting `Enter`.

## Starting and Working with the DevContainer

Once your DevContainer is running, you can start developing as if you were working locally. Visual Studio Code's features like IntelliSense, linting, and debugging all work in the DevContainer.
You can also use the [devcontainer-cli](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli) much like you would with other container clis like Docker or Kubernetes.

### Starting the DevContainer

As mentioned above, you can start the DevContainer by opening the command palette with `F1`, typing "Remote-Containers: Reopen Folder in Container", and hitting `Enter`.

### Stopping the DevContainer

To stop the DevContainer, you can close Visual Studio Code or use the "Remote-Containers: Close Remote Connection" command in the command palette.

### Deleting the DevContainer

If you want to completely delete the DevContainer and start from scratch, you can use the "Remote-Containers: Rebuild Container" command in the command palette. This will delete the container and create a new one from the Dockerfile.

### Checking the DevContainer Status

To check the status of the DevContainer, you can use the "Remote-Containers: Show Container Status" command in the command palette.

### Connecting to the DevContainer

If you've stopped your DevContainer and want to reconnect to it, you can use the "Remote-Containers: Attach to Running Container..." command in the command palette.

#### Prerequisites

- Docker installed and running on your machine
- A Docker Hub account

1. **Building the Docker Image**

   Run the following command to build the Docker image:

   ```bash
   make docker-devcontainer-build
   ```

   This command builds a Docker image according to the Dockerfile in your current directory. The image will be tagged with your Docker username, the image name, and the tag you specified in your `Makefile`.

2. **Pushing the Docker Image**

   After successfully building the Docker image, you can push it to Docker Hub with the following command:

   ```bash
   make docker-devcontainer-push
   ```

### Debugging a DevContainer

Debugging a DevContainer largely depends on the specific issue you're facing. However, here are some general tips:

1. **Check the Dockerfile and devcontainer.json files:** Make sure there are no syntax errors or invalid configurations.
2. **Check the build logs:** When you build the DevContainer, Visual Studio Code displays logs in the terminal. These logs can provide useful information about any issues.
3. **Check the Docker daemon:** Ensure that Docker is running properly on your system. You can test this by running a simple command like `docker run hello-world`.
4. **Rebuild the DevContainer:** If you've made changes to the Dockerfile or devcontainer.json, you need to rebuild the DevContainer. You can do this using the "Remote-Containers: Rebuild Container" command in the command palette.
5. **Check your system resources:** If your system is low on resources (like memory or disk space), it could cause problems when building or running the DevContainer.

### Recommended Resource Requirements

For the best performance, we recommend the following minimum system resources for running the DevContainer:

- **CPU:** 2 cores
- **Memory:** 6 GB

Please note that these are just recommendations. The actual resources you need could be more or less depending on the specifics of your project. Also, remember that other applications running on your system will also use resources, so make sure to take that into account.

If you're running Docker Desktop, you can adjust the allocated resources in the Docker Desktop settings. For other Docker installations, the process may vary.
