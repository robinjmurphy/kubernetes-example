package main

import (
	"fmt"
	"net/http"
)

const service string = "Service C"
const emoji string = "✌️"
const version string = "2.0.0"

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello from %s (Version %s) %s", service, version, emoji)
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Printf("Starting %s at http://127.0.0.1:8080\n", service)
	http.ListenAndServe(":8080", nil)
}
