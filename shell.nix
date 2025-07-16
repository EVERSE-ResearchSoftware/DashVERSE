# shell.nix
{ pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
  name = "dashverse-shell";
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
}
