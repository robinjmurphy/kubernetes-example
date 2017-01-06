build: buildgo
	docker build -t robinjmurphy/kubernetes-example-service-a:latest ./service-a
	docker build -t robinjmurphy/kubernetes-example-service-b:latest ./service-b
	docker build -t robinjmurphy/kubernetes-example-service-c:latest ./service-c

buildgo: clean
	cd service-a && CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o main
	cd service-b && CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o main
	cd service-c && CGO_ENABLED=0 GOOS=linux go build -ldflags "-s" -a -installsuffix cgo -o main

clean:
	rm -f service-{a,b,c}/main

push:
	docker push robinjmurphy/kubernetes-example-service-a:latest
	docker push robinjmurphy/kubernetes-example-service-b:latest
	docker push robinjmurphy/kubernetes-example-service-c:latest

.PHONY: buildgo build push
