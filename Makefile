version = 1.0.0

build: buildgo
	docker build -t robinjmurphy/kubernetes-example-service-a:$(version) ./service-a
	docker build -t robinjmurphy/kubernetes-example-service-b:$(version) ./service-b
	docker build -t robinjmurphy/kubernetes-example-service-c:$(version) ./service-c

buildgo: clean
	cd service-a && CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o main
	cd service-b && CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o main
	cd service-c && CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o main

clean:
	rm -f service-{a,b,c}/main

push:
	docker push robinjmurphy/kubernetes-example-service-a:$(version)
	docker push robinjmurphy/kubernetes-example-service-b:$(version)
	docker push robinjmurphy/kubernetes-example-service-c:$(version)

.PHONY: buildgo build push
