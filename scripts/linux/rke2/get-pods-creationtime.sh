#!/bin/bash

# Get list of all namespaces with at least one pod
namespaces=$(kubectl get namespaces --no-headers | awk '$2 > 0 {print $1}')

# Loop through each namespace
for namespace in $namespaces; do
  echo "Namespace: $namespace"
  
  # Get list of pod names in the current namespace
  pod_names=$(kubectl get pods -n $namespace --no-headers | awk '{print $1}')
  
  # Loop through each pod and print creation timestamp
  for pod in $pod_names; do
    creation_time=$(kubectl get pod $pod -n $namespace -o=jsonpath='{.metadata.creationTimestamp}')
    echo "  Pod: $pod, Created: $creation_time"
  done
  
  echo ""
done