#!/bin/bash

# Create the cluster
kind create cluster --name istio-opa

# Install Istio with the ambient profile
istioctl install --set profile=ambient --skip-confirmation

# Install gateway-api CRDs
kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml; }

# Create a namespace for the bookinfo application
kubectl create namespace app

# Install bookinfo applications
kubectl apply -n app -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -n app -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/platform/kube/bookinfo-versions.yaml

# Install sleep application to test in-cluster requests
kubectl apply -n app -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/sleep/sleep.yaml

# Create a gateway for the productpage app
kubectl apply -n app -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/gateway-api/bookinfo-gateway.yaml
istioctl waypoint apply -n app --enroll-namespace --wait

# Annotate the namespace to use cluster IP
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=app

# Label the namespace to use the ambient dataplane mode, adding the workloads in the namespace to the mesh
kubectl label namespace app istio.io/dataplane-mode=ambient

# Install OPA-envoy-plugin in the platform namespace
kubectl create namespace platform


