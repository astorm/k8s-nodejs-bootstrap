#!/bin/bash

set -e

depcheck() {
  echo "checking for needed commands"
  ## check to see if all required commands are present
  kind version > /dev/null
  kubectl version > /dev/null
  npm --version > /dev/null
  node --version > /dev/null
  docker --version > /dev/null
}

install() {
  # create the cluster with an exposed port
  # for the NodePort
  kind create cluster --config kubectl/cluster-nodeport.yaml --name elastic

  # add the dashboard to our cluster
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.5.0/aio/deploy/recommended.yaml

  # create a user for our dashboard
  # and a role binding.
  # run
  # kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
  # to get a token for the dashboard
  kubectl apply -f kubectl/create-service-account.yaml
  kubectl apply -f kubectl/create-cluster-role-binding.yaml

  # build container
  cd service
  npm install
  docker build . -t elasticapm/node-web-app:0.0.1
  cd ..

  # load the docker image into the k8s cluster
  kind load docker-image elasticapm/node-web-app:0.0.1 --name=elastic

  # create deployment using above image
  kubectl apply -f kubectl/create-deployment.yaml

  # expose deployment as a NodePort service, using
  # same port that was exposed when running kind
  # create cluster
  kubectl apply -f kubectl/create-service.yaml
}

postinstall() {
  echo '+--------------------------------------------------+'
  echo 'To access the dashbaord, run'
  echo '    kubectl proxy'
  echo 'and the load the following URL in your browser'
  echo '    http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/'
  echo '+--------------------------------------------------+'
  echo 'To get a key for your dashboard, run the following small command'
  echo '    kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"'
  echo 'Command may be different in k8s v1.24+, see'
  echo '    https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md'
  echo '+--------------------------------------------------+'
  echo 'Service will be avaiable outside of the cluster via'
  echo '    curl http://localhost:32525'
  echo 'See the following URL for bash-ing into individual pods'
  echo '    https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/'
  echo '+--------------------------------------------------+'
}

depcheck
install
postinstall
