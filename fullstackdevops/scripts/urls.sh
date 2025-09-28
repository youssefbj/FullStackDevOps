#!/bin/bash

echo "🌐 URLs d'accès aux services:"
echo "=================================="

FASTAPI_URL=$(minikube service fastapi-service --url 2>/dev/null | head -1)
if [ ! -z "$FASTAPI_URL" ]; then
    echo "🚀 FastAPI App: $FASTAPI_URL"
    echo "   📊 Métriques: $FASTAPI_URL/metrics"
    echo "   💓 Health: $FASTAPI_URL/health"
fi

GRAFANA_URL=$(minikube service grafana --url 2>/dev/null | head -1)
if [ ! -z "$GRAFANA_URL" ]; then
    echo "📈 Grafana: $GRAFANA_URL"
    echo "   👤 Login: admin / admin123"
    echo "   📊 Dashboard: FastAPI DevOps Stack - Complete Monitoring"
fi

PROMETHEUS_URL=$(minikube service prometheus --url 2>/dev/null | head -1)
if [ ! -z "$PROMETHEUS_URL" ]; then
    echo "🔍 Prometheus: $PROMETHEUS_URL"
fi

ALERTMANAGER_URL=$(minikube service alertmanager --url 2>/dev/null | head -1)
if [ ! -z "$ALERTMANAGER_URL" ]; then
    echo "🚨 Alertmanager: $ALERTMANAGER_URL"
fi

echo "=================================="
echo "💡 Utilisez 'make simulate' pour générer du trafic et voir les métriques"
