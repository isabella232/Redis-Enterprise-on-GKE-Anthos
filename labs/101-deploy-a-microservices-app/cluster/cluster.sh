#!/usr/bin/env bash
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Sample script for creating a cluster for deploying microservices app
# to demo Cloud Run for Anthos
#
# PREREQUISITES
# =============
# 1) Ensure you have created a project with billing enabled
# https://support.google.com/googleapi/answer/6251787?hl=en
#

CLUSTER="${CLUSTER:-${USER}-cluster-1}"
ZONE="${ZONE:-us-central1-c}"
NODES="${NODES:-3}"
MAXNODES="${MAXNODES:-6}"
MACHINE="${MACHINE:-n2-standard-4}"
CHANNEL="${CHANNEL:-regular}"

gcloud container clusters create "${CLUSTER:-tobys-k8s-cluster}" \
  --release-channel "${CHANNEL:-regular}" \
  --zone "${ZONE:-us-west2-a}" --num-nodes "${NODES:-3}" --machine-type "${MACHINE:-n1-standard-8}" \
  --enable-autoscaling --min-nodes "${NODES:-3}" --max-nodes "${MAXNODES:-6}" \
  --enable-ip-alias \
  --addons CloudRun,HttpLoadBalancing --enable-stackdriver-kubernetes --enable-basic-auth
