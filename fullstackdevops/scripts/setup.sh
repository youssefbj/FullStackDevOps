#!/bin/bash

set -e

echo "🚀 Configuration de l'environnement DevOps..."

command -v minikube >/dev/null 2>&1 || { echo "❌ Minikube non installé"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker non installé"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform non installé"; exit 1; }

echo "✅ Prérequis validés"

echo "🔄 Démarrage de Minikube..."
minikube start --driver=docker --memory=4096 --cpus=2

echo "🔧 Configuration de l'environnement Docker..."
eval $(minikube docker-env)

echo "✅ Environnement configuré avec succès!"
