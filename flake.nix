{
  description = "DashVERSE development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {

          name = "dashverse";

          packages = with pkgs; [
            binutils
            vim
            which
            git
            jq

            python313
            minikube
            podman
            # poetry
            # kubernetes
            kubernetes-helm
            kubectl

            nftables
          ];

          shellHook = ''

            echo "Minikube version: $(minikube version)"
            echo "Python version: $(python --version)"
            echo "Podman version: $(podman --version)"
            echo "kubectl version: $(kubectl version)"

            if [ $(minikube status -o json | jq -r .Host) = "Running" ]; then
              echo
              echo "Minikube is running."
              echo "===================="
            else
              echo
              echo "Starting minikube."
              echo "=================="
              minikube config set rootless true
              minikube config set driver podman
              minikube start --cpus='4' --memory='4g' --driver=podman  --container-runtime=containerd
            fi

            . <(minikube completion bash)
            . <(kubectl completion bash)
            . <(helm completion bash)

            echo
            echo "Minikube status:"
            echo "================"
            minikube status
            #echo "Minikube ip:" $(minikube ip)

          '';
        };
      });
}
