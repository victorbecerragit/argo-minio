#!/bin/bash
set -e

kubectl apply -f ../argocd/project &&

kubectl apply -f ../argocd/bootstrap/
