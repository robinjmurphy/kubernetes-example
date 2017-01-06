version = 1.0.0

build:
	docker build -t robinjmurphy/kubernetes-example-service-a:$(version) ./service-a
	docker build -t robinjmurphy/kubernetes-example-service-b:$(version) ./service-b
	docker build -t robinjmurphy/kubernetes-example-service-c:$(version) ./service-c

push:
	docker push robinjmurphy/kubernetes-example-service-a:$(version)
	docker push robinjmurphy/kubernetes-example-service-b:$(version)
	docker push robinjmurphy/kubernetes-example-service-c:$(version)
