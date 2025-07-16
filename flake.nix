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

            python313
            minikube
            podman
            # poetry
            # kubernetes
            kubernetes-helm
            kubectl
          ];

          shellHook = ''
            echo "Entered the project shell."
            echo "Minikube version: $(minikube version)"
            echo "Python version: $(python --version)"
            echo "Podman version: $(podman --version)"
            echo "kubectl version: $(kubectl version)"
          '';
        };
      });
}
