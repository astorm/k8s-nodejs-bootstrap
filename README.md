# k8s-nodejs-bootstrap

A small script that bootstraps a Node.js service in a k8s cluster running via `kind`.

## Getting Started

If you're lucky just run

    % ./bootstrap.sh
    # lots of output and installing!

If you want to see the post install instructions again

    ./bootstrap.sh postinstall

## More Information

This script will

1. Use `kind` to create a K8s cluster with an exposed port (`32525`)
2. Install the K8s Dashboard into that cluster
3. Create an admin user and role binding for the K8s Dashboard
4. Build a docker container image from the Node.js service in `./service` (exposed on port 8080)
5. Load that just built image into your `kind` cluster
6. Create a "K8s Deployment" based on that image
7. Exposes that K8s Deployment via a "K8s NodePort Service" via port `32525`, forwarded to `8080`
8. Allows you to invoke your Node.js program from the outside world via `curl http://localhost:32525`


## A Note on Dashboard Tokens

Kubernetes 1.24 changed how tokens for the dashboard are generated.  The `postinstall` script above contains _both_ command [for generating a token](https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md).

However -- if your `kubectl` version and your cluster version are out of sync (a common case with the Docker provided `kubectl` or a version of `kind` that's been sitting on your computer for a while) you may not be able to install a token.  We recommend syncing both versions to the latest version available.
