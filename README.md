# kubernetes-example

> An example of using [Kubernetes](http://kubernetes.io/) to run multiple containerized services

_This is currently a work in progress. I'm using it to help me learn more about Kubernetes and Docker 🚧_

* [Overview](#overview)
* [Requirements](#requirements)
* [Setup](#setup)
  * [Building the service images](#building-the-service-images)
  * [Creating the services and deployments](#creating-the-services-and-deployments)
* [Making changes](#making-changes)
  * [Scaling a service](#scaling-a-service)
  * [Deploying a new version of a service](#deploying-a-new-version-of-a-service)
  * [Zero-downtime deployments](#zero-downtime-deployments)
  * [Rolling back to a previous verson of a service](#rolling-back-to-a-previous-verison-of-a-service)
* [Monitoring](#monitoring)
  * [Accessing the logs for a service](#accessing-the-logs-for-a-service)
* [Dashboard](#dashboard)
* [Reading list](#reading-list)

## Overview

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

So far we've only used the `latest` tag when deploying the three services. This works fine in development, but a better approach is to deploy _versioned_ images in production:

> Note: you should avoid using :latest tag when deploying containers in production, because this makes it hard to track which version of the image is running and hard to roll back.
>
> Source: [Best Practices for Configuration](http://kubernetes.io/docs/user-guide/config-best-practices/)

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

Now that version `1.0.0` of each service is deployed, let's deploy a new version of `service-a`.

This is as simple as updating the image tag in the configuration file to point to a new version (`2.0.0`) and running `kubectl apply`.

Let's first update the `image` field in [kubernetes.yaml](kubernetes.yaml):

```yaml
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

### Zero-downtime deployments

One of the key features of Kubernetes is its ability to perform [rolling updates](https://kubernetes.io/docs/user-guide/rolling-updates/). This means a new version of a service can be deployed into production without downtime.

In the last example we deployed a new version of a service by updating its image. However, when the service is only running on a single pod there will be some downtime while the image is updated and the container is replaced.

We can see this for ourselves by deploying a new version of `service-b` whilst it's busy serving requests.

Start the [`load.sh`](load.sh) script in a new tab with the argument `service-b`. This will send a request to `service-b` every 500ms and report the response. Any request that takes longer than 1 second to complete will trigger a timeout.

```bash
./load.sh service-b
# Hello from Service B (Version 1.0.0) 👊
# Hello from Service B (Version 1.0.0) 👊
# Hello from Service B (Version 1.0.0) 👊
# ...
```

We can now update the image tag for `service-b` to `v2.0.0` in the [kubernetes.yaml](kubernetes.yaml) file:

```yaml
# ...
image: robinjmurphy/kubernetes-example-service-b:v2.0.0
# ...
```

Let's apply the change to the cluster and watch what happens to the `load.sh` script that's running in a separate tab.

```
kubectl apply -f kubernetes.yaml
```

```
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
curl: (52) Empty reply from server
curl: (28) Operation timed out after 1001 milliseconds with 0 bytes received
curl: (28) Operation timed out after 1003 milliseconds with 0 bytes received
Hello from Service B (Version 2.0.0) 👊
Hello from Service B (Version 2.0.0) 👊
Hello from Service B (Version 2.0.0) 👊
```

You can see that the new version of the service has been successfully deployed. However, during the update there was one request that failed in-flight with an empty reply and then two requests that timed out.

If we increase the number of replica pods for `service-b`, Kubernetes will be able to perform a _rolling update_ where some of the pods are kept in service while the others are updated.

Let's reset the image tag for `service-b` back to `v1.0.0` and increase the number of replicas to `2`.

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: service-b
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: service-b
    spec:
      containers:
        - name: service-b
          image: robinjmurphy/kubernetes-example-service-b:v1.0.0
```

Apply these changes to the cluster:

```
kubectl apply -f kubernetes.yaml
```

We can now re-attempt the upgrade to version `2.0.0` and watch what happens in the tab running the `load.sh` script:

```yaml
# ...
image: robinjmurphy/kubernetes-example-service-b:v2.0.0
# ...
```

```
kubectl apply -f kubernetes.yaml
```

```
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 2.0.0) 👊
Hello from Service B (Version 2.0.0) 👊
Hello from Service B (Version 2.0.0) 👊
```

This time the deployment went smoothly. We experienced zero downtime because Kubernetes updated the pods one at a time, keeping one in service whilst the other was updating.

There is, however, still a risk of in-flight connections being dropped. This is because the containers running `service-b` are terminated as soon as the update begins, leaving the application unable to respond to in-flight requests.

Here's an example where running the deployment again didn't go quite so smoothly:

```
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
Hello from Service B (Version 1.0.0) 👊
curl: (52) Empty reply from server
Hello from Service B (Version 2.0.0) 👊
Hello from Service B (Version 2.0.0) 👊
Hello from Service B (Version 2.0.0) 👊
```

Luckily we can use the [`terminationGracePeriodSeconds`](https://kubernetes.io/docs/user-guide/production-pods/#lifecycle-hooks-and-termination-notice) property to provide a _grace period_ during which the application can finish handling any open requests without taking on new ones. This is managed via the signals sent to the process running inside the containers (`SIGTERM` vs `SIGKILL`.)

> 🚧 The simple services in this project don't currently support a graceful shutdown when issued with a `SIGTERM` so for now we can't take advantage of `terminationGracePeriodSeconds`. Watch this space!

### Rolling back a service

## Monitoring

### Accessing the logs for a service

## Dashboard

Throughout this guide we've been using the `kubectl` command line tool to manage our cluster. This, coupled with a [configuration-driven approach](http://kubernetes.io/docs/user-guide/config-best-practices/), makes it easy make deployments, rollbacks and infrastructure changes reproducible and automated. It can, however, still be useful to explore the cluster in a more visual way, which is where the Kubernetes [dashboard](https://kubernetes.io/docs/user-guide/ui/) comes in.

The dashboard runs inside the Kubernetes cluster. To access the dashboard in a Minikube cluster, just run:

```
minikube dashboard
```

This will open the dashboard in a browser window. Here you'll see all of the services, deployments and pods that we have already created from our configuration file using `kubectl`.

## Reading list

* [Deploying Go servers with Docker](https://blog.golang.org/docker)
* [Static Go binaries with Docker on OSX](https://developer.atlassian.com/blog/2015/07/osx-static-golang-binaries-with-docker/)
* [Building Minimal Docker Containers for Go Applications](https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/)
* [Five Months of Kubernetes](http://danielmartins.ninja/posts/five-months-of-kubernetes.html)
* [Graceful shutdown of pods with Kubernetes](https://pracucci.com/graceful-shutdown-of-kubernetes-pods.html)

_Kubernetes documentation_

* [Deployments](http://kubernetes.io/docs/user-guide/deployments)
* [Services](http://kubernetes.io/docs/user-guide/services)
* [kubectl apply](http://kubernetes.io/docs/user-guide/kubectl/kubectl_apply/)
* [Best Practices for Configuration](http://kubernetes.io/docs/user-guide/config-best-practices/)
