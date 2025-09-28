#!/bin/bash

echo "🧹 Nettoyage de l'environnement..."

kubectl delete --ignore-not-found=true -f k8s/fastapi/ 2>/dev/null || true
kubectl delete --ignore-not-found=true -f k8s/monitoring/ -R 2>/dev/null || true

cd monitoring/terraform
terraform destroy -auto-approve 2>/dev/null || true
cd ../..

docker rmi fastapi-devops:latest 2>/dev/null || true

echo "🧹 Arrêt de Minikube..."
minikube stop

echo "✅ Nettoyage terminé!"
