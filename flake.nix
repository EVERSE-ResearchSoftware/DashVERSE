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
            echo "Entered the project shell."
            echo "Minikube version: $(minikube version)"
            echo "Python version: $(python --version)"
            echo "Podman version: $(podman --version)"
            echo "kubectl version: $(kubectl version)"
            . <(minikube completion bash)
            . <(kubectl completion bash)
            . <(helm completion bash)
            minikube config set rootless true
            minikube config set driver podman
            minikube start --cpus='4' --memory='4g' --driver=podman  --container-runtime=containerd
            minikube status
            minikube ip
          '';
        };
      });
}
