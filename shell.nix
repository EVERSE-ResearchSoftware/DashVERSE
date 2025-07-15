# shell.nix
{ pkgs ? import <nixpkgs> {}}:

pkgs.mkShell {
  name = "dashverse-shell";
  packages = with pkgs; [
    python313
    minikube
    podman
    poetry
    kubernetes
    kubernetes-helm
    kubectl
  ];
}
