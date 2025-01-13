# DashVERSE

The dashboard prototype for the [EVERSE project](https://everse.software/).

> [!WARNING]
> 🚧 Work in Progress
>
> This project is currently under active development and may not yet be fully stable. Features, functionality, and documentation are subject to change as progress continues.
>
> We welcome feedback, contributions, and suggestions! If you encounter issues or have ideas for improvement, please feel free to open an issue or submit a pull request.

## Requirements

- Python (3.12)
- Poetry (1.8.5)
- Docker (27.4.1)
- minikube (v1.34.0)
- helm (v3.16.4)

<details>
<summary>
    Links for the requirements
</summary>

### Python

<https://www.python.org/downloads>

### Pyenv (optional)

Pyenv allows developers to install multiple versions of Python distribution and easy switching between the installed versions.

Website: <https://github.com/pyenv/pyenv?tab=readme-ov-file#installation>

### Poetry (optional)

Poetry is used for dependency management of the Python packages.

<https://python-poetry.org/docs/#installation>

### Docker

<https://docs.docker.com/engine/install>

### minikube

<https://minikube.sigs.k8s.io/docs/start>

### helm

<https://helm.sh/docs/intro/install>

</details>

## Step-1 Setting up a Kubernetes Cluster

This step will set up a Kubernetes cluster using minikube. The kubernetes cluster will be deployed using Docker driver. For the alternative drivers have a look at [this link](https://minikube.sigs.k8s.io/docs/drivers/).

### Check versions

```shell
$ minikube version
minikube version: v1.34.0
commit: 210b148df93a80eb872ecbeb7e35281b3c582c61
```

```shell
$ kubectl version --client
Client Version: v1.31.1
Kustomize Version: v5.4.2
```

### Start the cluster

```shell
minikube start --driver=docker
```
