#!/bin/bash

set -ex

depcheck() {
  echo "checking for needed commands"
  ## check to see if all required commands are present

  # Docker Desktop!  Both the best and worst thing to happen to containers
  # https://www.docker.com/products/docker-desktop/
  docker --version > /dev/null

  ## Install: https://kind.sigs.k8s.io/docs/user/quick-start/
  kind version > /dev/null

  ## a version comes preinstalled with docker, but it's an older version
  ## which may cause isses with pre/post 1.24 feature.
  ## Install: https://kubernetes.io/docs/tasks/tools/#kubectl
  kubectl version --client > /dev/null

  # Node and NPM usually come bundled together
  # node version manager: https://github.com/nvm-sh/nvm
  # official dists: https://nodejs.org/en/download/
  npm --version > /dev/null
  node --version > /dev/null
}

install() {
  # create the cluster with an exposed port
  # for the NodePort
  kind create cluster --config kind-config/cluster-nodeport.yaml --name elastic

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
  set +x
  echo '+--------------------------------------------------+'
  echo 'To access the dashbaord, run'
  echo '    kubectl proxy'
  echo 'and the load the following URL in your browser'
  echo '    http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/'
  echo '+--------------------------------------------------+'
  echo 'To get a key for your dashboard, run one of the the following commands'
  echo '    # pre kubernetes 1.24'
  echo '    kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"'
  echo '    # post-kubernetes 1.24'
  echo '    kubectl -n kubernetes-dashboard create token admin-user'
  echo 're: 1.24 -- this is both your kubernetes server version AND kubectl version'
  echo 'if one is pre 1.24 and other is post 1.24 weird things will happen'
  echo '    kubectl version --client # get client version'
  echo '    kubectl get node -owide  # get cluster/server version'
  echo ' '
  echo 'See for more dashbaord user information'
  echo '    https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md'
  echo '+--------------------------------------------------+'
  echo 'Service will be avaiable "outside of the cluster" via'
  echo '    curl http://localhost:32525'
  echo 'See the following URL for bash-ing into individual pods for "inside of'
  echo 'the cluster" access'
  echo '    https://kubernetes.io/docs/tasks/debug/debug-application/get-shell-running-container/'
  echo '+--------------------------------------------------+'
}

if [ "$1" = "postinstall" ]; then
  postinstall
  exit 0
fi

depcheck
install
postinstall
