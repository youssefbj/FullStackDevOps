.PHONY: help init build deploy apply geturlsgrafana simulate cleanup status logs

help: ## Affiche l'aide
	@echo "Stack DevOps Unifié avec Dashboard Grafana Avancé"
	@echo "================================================="
	@echo "Commandes disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialise l'environnement (Minikube + Terraform)
	@echo "🚀 Initialisation de l'environnement..."
	@chmod +x scripts/*.sh
	@./scripts/setup.sh
	@cd monitoring/terraform && terraform init
	@echo "✅ Initialisation terminée!"

build: ## Build l'image Docker FastAPI
	@echo "🔨 Construction de l'image Docker..."
	@eval $$(minikube docker-env) && docker build -t fastapi-devops:latest apps/fastapi/
	@echo "✅ Image construite!"

deploy: ## Déploie les ressources Kubernetes
	@echo "📦 Déploiement des ressources..."
	@cd monitoring/terraform && terraform apply -auto-approve
	@kubectl apply -f k8s/monitoring/ -R
	@kubectl apply -f k8s/fastapi/
	@echo "⏳ Attente que les services soient prêts..."
	@kubectl wait --for=condition=ready pod -l app=prometheus --timeout=120s
	@kubectl wait --for=condition=ready pod -l app=grafana --timeout=120s
	@kubectl wait --for=condition=ready pod -l app=fastapi-app --timeout=120s
	@echo "✅ Déploiement terminé!"

apply: init build deploy ## Lance la stack complète
	@echo "🎉 Stack DevOps Unifié déployée avec succès!"
	@echo "📊 Dashboard Grafana avancé avec 9 panneaux configuré!"
	@echo "📋 Lancez 'make geturlsgrafana' pour obtenir les URLs"

geturlsgrafana: ## Affiche les URLs Grafana et autres services
	@./scripts/urls.sh

simulate: ## Simule du trafic pour générer des métriques
	@echo "🔄 Simulation de trafic..."
	@FASTAPI_URL=$$(minikube service fastapi-service --url 2>/dev/null | head -1); \
	if [ ! -z "$$FASTAPI_URL" ]; then \
		echo "📈 Génération de trafic vers $$FASTAPI_URL"; \
		for i in {1..100}; do \
			curl -s "$$FASTAPI_URL/" > /dev/null & \
			curl -s "$$FASTAPI_URL/simulate-load" > /dev/null & \
			curl -s "$$FASTAPI_URL/api/users" > /dev/null & \
			curl -s "$$FASTAPI_URL/health" > /dev/null & \
		done; \
		wait; \
		echo "✅ Trafic simulé! Consultez Grafana pour voir les 9 dashboards avancés."; \
		echo "📊 Dashboard: 'FastAPI DevOps Stack - Complete Monitoring'"; \
	else \
		echo "❌ Service FastAPI non accessible"; \
	fi

simulate-load: ## Simulation intensive pour plus de métriques
	@echo "🚀 Simulation de charge intensive..."
	@FASTAPI_URL=$$(minikube service fastapi-service --url 2>/dev/null | head -1); \
	if [ ! -z "$$FASTAPI_URL" ]; then \
		for round in {1..5}; do \
			echo "🔄 Round $$round/5"; \
			for i in {1..50}; do \
				curl -s "$$FASTAPI_URL/" > /dev/null & \
				curl -s "$$FASTAPI_URL/simulate-load" > /dev/null & \
				curl -s "$$FASTAPI_URL/api/users" > /dev/null & \
			done; \
			wait; \
			sleep 2; \
		done; \
		echo "✅ Charge intensive terminée!"; \
	fi

status: ## Affiche le statut des services
	@echo "📊 Statut des services:"
	@kubectl get pods -o wide
	@echo "\n🔗 Services:"
	@kubectl get services
	@echo "\n📈 ConfigMaps Grafana:"
	@kubectl get configmaps | grep grafana

logs: ## Affiche les logs de l'application FastAPI
	@kubectl logs -l app=fastapi-app --tail=50

logs-grafana: ## Logs Grafana
	@kubectl logs -l app=grafana --tail=50

logs-prometheus: ## Logs Prometheus
	@kubectl logs -l app=prometheus --tail=50

restart-grafana: ## Redémarre Grafana (utile si dashboard ne s'affiche pas)
	@kubectl rollout restart deployment/grafana
	@kubectl rollout status deployment/grafana
	@echo "✅ Grafana redémarré! Dashboard avancé rechargé."

test-metrics: ## Teste les métriques Prometheus
	@echo "🔍 Test des métriques..."
	@FASTAPI_URL=$$(minikube service fastapi-service --url 2>/dev/null | head -1); \
	if [ ! -z "$$FASTAPI_URL" ]; then \
		echo "📊 Métriques disponibles:"; \
		curl -s "$$FASTAPI_URL/metrics" | grep -E "(http_requests_total|http_request_duration|business_operations)" | head -10; \
	fi

cleanup: ## Nettoie l'environnement complet
	@./scripts/cleanup.sh

dashboard-info: ## Infos sur le dashboard Grafana
	@echo "📊 Dashboard Grafana Unifié - Informations"
	@echo "=========================================="
	@echo "Nom: FastAPI DevOps Stack - Complete Monitoring"
	@echo "Panneaux: 9 visualisations avancées"
	@echo "1. 🚀 API Request Rate - Taux requêtes/sec"
	@echo "2. ⚡ Response Time Percentiles - Latence détaillée"
	@echo "3. 🎯 HTTP Status Codes - Répartition des codes"
	@echo "4. 📈 Request Rate by Endpoint - Par endpoint"
	@echo "5. 🔧 Business Operations - Métriques métier"
	@echo "6. ⚠️  Error Rate - Pourcentage d'erreurs"
	@echo "7. 🚦 Service Health - Statut du service"
	@echo "8. 📊 Request Volume - Volume dans le temps"
	@echo "9. ⏱️  Response Time Heatmap - Heatmap avancée"
	@echo "Refresh: Automatique toutes les 5 secondes"
	@echo "Seuils: Colorés (vert/jaune/rouge)"

dev-restart-app: ## Redémarre l'application FastAPI
	@kubectl rollout restart deployment/fastapi-app
	@kubectl rollout status deployment/fastapi-app

dev-shell: ## Shell interactif dans un pod FastAPI
	@kubectl exec -it $$(kubectl get pods -l app=fastapi-app -o jsonpath='{.items[0].metadata.name}') -- /bin/bash

quick-deploy: ## Déploiement rapide (sans Terraform)
	@echo "🏃‍♂️ Déploiement rapide..."
	@kubectl apply -f k8s/monitoring/ -R
	@kubectl apply -f k8s/fastapi/
	@echo "✅ Déploiement rapide terminé!"

port-forward-grafana: ## Port-forward Grafana sur localhost:3000
	@echo "🔗 Port-forward Grafana vers localhost:3000"
	@kubectl port-forward service/grafana 3000:3000

port-forward-prometheus: ## Port-forward Prometheus sur localhost:9090
	@echo "🔗 Port-forward Prometheus vers localhost:9090"
	@kubectl port-forward service/prometheus 9090:9090
