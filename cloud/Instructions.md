# Cloud setup

If you would like to run the setup on a cloud (your own server)

1. Deploy superset using `dashverse-values-with-ingress.yaml`

1. Get the application URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace superset -o jsonpath="{.spec.ports[0].nodePort}" services superset)
  export NODE_IP=$(kubectl get nodes --namespace superset -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT

1. Set up the domain

1. Set DNS to point to your server ( you will need to setup a reverse proxy to be able to access the service)
