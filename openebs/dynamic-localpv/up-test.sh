#!/usr/bin/env bash

# Up test for dynamic-localpv provisioner

# install chart
helm repo add openebs-localpv https://openebs.github.io/dynamic-localpv-provisioner
helm repo update
helm upgrade \
    --install openebs-localpv openebs-localpv/localpv-provisioner \
    --namespace openebs-localpv \
    --create-namespace \
    -f chart/values.yaml


