# kubernetes-example

> An example of using [Kubernetes](http://kubernetes.io/) to run multiple containerized services

_This is currently a work in progress 🚧_

## Requirements

* [Docker](https://docs.docker.com/engine/installation/mac/)
* [kubectl](http://kubernetes.io/docs/user-guide/kubectl-overview/) (`brew install kubectl`)
* [minikube](https://github.com/kubernetes/minikube) (`brew cask install minikube`)

## Setup

#### Building the service images

_This step is optional. You can use the pre-built images in the Docker Hub repositories_

```
make build
```

This creates minimal Go images for the three services.

To push the images to Docker Hub:

```
make push
```

#### Creating the services and deployments

Each service has a Kubernetes [deployment](http://kubernetes.io/docs/user-guide/deployments) and [service](http://kubernetes.io/docs/user-guide/services) configured in the [`kubernetes.yaml`](kubernetes.yaml) file.

To create the resources in the Kubernetes cluster, run:

```
kubectl apply -f kubernetes.yaml
```

You can then list the services that have been created:

```bash
kubectl get services
# NAME         CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
# kubernetes   10.0.0.1     <none>        443/TCP          4d
# service-a    10.0.0.111   <nodes>       8080:32363/TCP   2s
# service-b    10.0.0.207   <nodes>       8080:31190/TCP   2s
# service-c    10.0.0.198   <nodes>       8080:32295/TCP   2s
```

And the deployments:

```bash
kubectl get deployments
# NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
# service-a   1         1         1            1           21s
# service-b   1         1         1            1           21s
# service-c   1         1         1            1           21s
```

And the individual [pods](http://kubernetes.io/docs/user-guide/pods/):

```bash
kubectl get pods
# NAME                         READY     STATUS    RESTARTS   AGE
# service-a-1760996314-dc0v7   1/1       Running   0          52s
# service-b-2010885085-01fhw   1/1       Running   0          52s
# service-c-2260773856-crl49   1/1       Running   0          52s
```

Because each deployment is assigned a service with a `NodePort` type, you can access it on a dedicated port.

Use the `minikube service` command to open each service in your browser:

```bash
minikube service service-a
minikube service service-b
minikube service service-c
```

### Updating a deployment

We can update a deployment to run on more [replica](http://kubernetes.io/docs/user-guide/replicasets/) pods.

Update the `replicas` property for the `service-a` deployment defined in `kubernetes.yaml` to be `3`.

We can then apply this change to the cluster:

```bash
kubectl apply -f kubernetes.yaml
```

And check that three `service-a` pods are running or in the process of spinning up:

```bash
kubectl get pods
# NAME                         READY     STATUS              RESTARTS   AGE
# service-a-1760996314-1vll6   0/1       ContainerCreating   0          4s
# service-a-1760996314-dc0v7   1/1       Running             0          7m
# service-a-1760996314-sx4qj   1/1       Running             0          4s
# service-b-2010885085-01fhw   1/1       Running             0          7m
# service-c-2260773856-crl49   1/1       Running             0          7m
```

## Reading list

* [Deploying Go servers with Docker](https://blog.golang.org/docker)
* [Static Go binaries with Docker on OSX](https://developer.atlassian.com/blog/2015/07/osx-static-golang-binaries-with-docker/)
* [Building Minimal Docker Containers for Go Applications](https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/)
* [Five Months of Kubernetes](http://danielmartins.ninja/posts/five-months-of-kubernetes.html)

_Kubernetes documentation_

* [Deployments](http://kubernetes.io/docs/user-guide/deployments)
* [Services](http://kubernetes.io/docs/user-guide/services)
* [kubectl apply](http://kubernetes.io/docs/user-guide/kubectl/kubectl_apply/)
* [Best Practices for Configuration](http://kubernetes.io/docs/user-guide/config-best-practices/)
