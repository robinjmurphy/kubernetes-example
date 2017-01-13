# kubernetes-example

> An example of using [Kubernetes](http://kubernetes.io/) to run multiple containerized services

_This is currently a work in progress 🚧_

This project contains three simple Go HTTP services:

* [`service-a`](service-a)
* [`service-b`](service-b)
* [`service-c`](service-c)

It demonstrates how to build minimal (_~5MB_) Docker images for each of them and deploy them to a local [Kubernetes](http://kubernetes.io/) cluster.

## Requirements

* [Docker](https://docs.docker.com/engine/installation/mac/)
* [kubectl](http://kubernetes.io/docs/user-guide/kubectl-overview/) (`brew install kubectl`)
* [minikube](https://github.com/kubernetes/minikube) (`brew cask install minikube`)

## Setup

### Building the service images

> _This step is optional. You can use the pre-built images in the Docker Hub repositories_

```
make build
```

This creates [minimal](https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/) Go images for the three services.

To push the images to Docker Hub:

```
make push
```

### Creating the services and deployments

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

You can also use the `--url` flag to return the URL of each service for use on the command line:

```bash
minikube service service-a --url
# http://192.168.99.100:32363
curl -i $(minikube service service-a --url)
# HTTP/1.1 200 OK
# Date: Fri, 13 Jan 2017 10:50:13 GMT
# Content-Length: 41
# Content-Type: text/plain; charset=utf-8
#
# Hello from Service A (Version 2.0.0) 👋
```

## Making changes

When making changes to our deployed services we'll always be following the same process:

1. Make changes to the [`kubernetes.yaml`](kubernetes.yaml) confiuguration file
2. Apply the changes to the cluster using [`kubectl apply`](http://kubernetes.io/docs/user-guide/kubectl/kubectl_apply/)

Working in this way means that we'll always have an accurate description of the cluster in the `kubernetes.yaml` file that can be checked into version control. This makes it easy for us rollback to a previous configuration or even completely recreate the cluster if we need to.

### Scaling a service

Each of the three services is currently configured to run in a single pod, but we can scale them to run on more using  [replicas](http://kubernetes.io/docs/user-guide/replicasets/).

Update the `replicas` property for the `service-a` deployment defined in `kubernetes.yaml` to be `3`.

```yaml
#...
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: service-a
spec:
  replicas: 3
# ...
```

We can then apply this change to the cluster:

```bash
kubectl apply -f kubernetes.yaml
```

And check that three `service-a` pods are now running or in the process of spinning up:

```bash
kubectl get pods
# NAME                         READY     STATUS              RESTARTS   AGE
# service-a-1760996314-1vll6   0/1       ContainerCreating   0          4s
# service-a-1760996314-dc0v7   1/1       Running             0          7m
# service-a-1760996314-sx4qj   1/1       Running             0          4s
# service-b-2010885085-01fhw   1/1       Running             0          7m
# service-c-2260773856-crl49   1/1       Running             0          7m
```

### Deploying a new version of a service

So far we've only used the `latest` tag when deploying the three services. This is works fine in development, but a better approach is to deploy _versioned_ images in production:

> Note: you should avoid using :latest tag when deploying containers in production, because this makes it hard to track which version of the image is running and hard to roll back.

_Source: [Best Practices for Configuration](http://kubernetes.io/docs/user-guide/config-best-practices/)_

Let's update our deployments to use versioned images.

Update the `image` field for each deployment in [`kubernetes.yaml`](kubernetes.yaml) to use the `v1.0.0` tag:

```yaml
# ...
image: robinjmurphy/kubernetes-example-service-a:v1.0.0
# ...
image: robinjmurphy/kubernetes-example-service-b:v1.0.0
# ...
image: robinjmurphy/kubernetes-example-service-c:v1.0.0
# ...
```

We can apply the change to the cluster:

```bash
kubectl apply -f kubernetes.yaml
```

We can then find the pod running `service-a` and check that the image has been updated:

```
kubectl describe pods -l app=service-a
```

The `-l` option lets us find the pods running `service-a` based on the `app` label.

In the output you should see the line:

```
Image: robinjmurphy/kubernetes-example-service-a:v1.0.0
```

Calling the service should return the version `1.0.0` response:

```bash
curl $(minikube service service-a --url)
# Hello from Service A (Version 1.0.0) 👋
```

Now that version `1.0.0` of each service is deployed, let's deploy a new version of `service-a`. This is as simple as updating the image tag in the configuration file to point to a new version (`2.0.0`) and running `kubectl apply`.

Let's first update the `image` field in [kubernetes.yaml](kubernetes.yaml):

```
# ...
image: robinjmurphy/kubernetes-example-service-a:v2.0.0
# ...
```

And apply the change to the cluster:

```bash
kubectl apply -f kubernetes.yaml
```

We can now check that the correct image is being used by the pod running `service-a`:

```bash
kubectl describe pods -l app=service-a
# ...
# Image: robinjmurphy/kubernetes-example-service-a:v2.0.0
# ...
```

And the service should now return version `2.0.0` in its responses:

```bash
curl $(minikube service service-a --url)
# Hello from Service A (Version 2.0.0) 👋
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
