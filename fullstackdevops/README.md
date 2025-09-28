# Stack DevOps Unifié avec Dashboard Grafana Avancé

🚀 **Stack complète DevOps locale avec monitoring professionnel - 9 dashboards visuels**

## 🎯 Features Principales

### **Stack Technique Complète**
- ✅ **FastAPI** avec métriques Prometheus intégrées
- ✅ **Kubernetes (Minikube)** avec driver Docker
- ✅ **Prometheus** pour la collecte de métriques
- ✅ **Grafana** avec dashboard avancé pré-configuré
- ✅ **Alertmanager** pour la gestion des alertes
- ✅ **Terraform** pour Infrastructure as Code
- ✅ **Makefile** pour l'automatisation complète

### **Dashboard Grafana Professionnel (9 Panneaux)**
1. **🚀 API Request Rate** - Taux de requêtes avec seuils colorés
2. **⚡ Response Time Percentiles** - Latence 95e/50e + moyenne
3. **🎯 HTTP Status Codes** - Graphique camembert interactif
4. **📈 Request Rate by Endpoint** - Analyse détaillée par endpoint
5. **🔧 Business Operations** - Métriques métier personnalisées
6. **⚠️ Error Rate** - Pourcentage d'erreurs avec alertes visuelles
7. **🚦 Service Health** - Indicateur UP/DOWN du service
8. **📊 Request Volume** - Graphique en barres empilées
9. **⏱️ Response Time Heatmap** - Carte thermique avancée

### **Fonctionnalités Avancées**
- 🔄 **Refresh automatique** toutes les 5 secondes
- 🎨 **Seuils colorés** (vert/jaune/rouge) sur tous les graphiques
- 📊 **Légendes détaillées** avec min/max/moyenne
- 🖱️ **Tooltips multi-séries** pour analyses approfondies
- 🔗 **Datasource Prometheus** automatiquement configuré
- ⏰ **Time range flexible** (5m à 30d)

## 🚀 Installation et Utilisation

### **Prérequis (Ubuntu/Debian)**
```bash
# Docker
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER

# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Redémarrer la session pour Docker
newgrp docker
```

### **Déploiement Ultra-Rapide**
```bash
# 1. Exécuter le script unifié
bash script-unifie.sh

# 2. Aller dans le dossier
cd fullstackdevops

# 3. Lancer la stack complète (tout automatique)
make apply

# 4. Obtenir les URLs d'accès
make geturlsgrafana

# 5. Générer du trafic pour voir les dashboards
make simulate
```

## 📊 Utilisation des Dashboards

### **Accès Grafana**
```bash
# Obtenir l'URL Grafana
make geturlsgrafana

# Login: admin / admin123
# Dashboard: "FastAPI DevOps Stack - Complete Monitoring"
```

### **Génération de Métriques**
```bash
make simulate          # Trafic normal (400 requêtes)
make simulate-load     # Charge intensive (1250 requêtes sur 5 rounds)
make test-metrics      # Vérifier les métriques Prometheus
```

### **Monitoring en Temps Réel**
- **Request Rate** : Mise à jour continue chaque 5s
- **Latence** : 95e percentile, médiane, moyenne en temps réel
- **Status Codes** : Répartition visuelle des codes HTTP
- **Health Status** : Indicateur vert/rouge du service
- **Heatmap** : Distribution des temps de réponse

## 🔧 Commandes Disponibles

### **Commandes Principales**
```bash
make help              # Affiche toutes les commandes
make apply             # Lance la stack complète
make geturlsgrafana    # URLs d'accès aux services
make simulate          # Génère du trafic normal
make simulate-load     # Simulation intensive
make status            # Statut de tous les services
make cleanup           # Nettoie tout l'environnement
```

### **Commandes de Debug**
```bash
make logs              # Logs FastAPI
make logs-grafana      # Logs Grafana
make logs-prometheus   # Logs Prometheus
make restart-grafana   # Redémarre Grafana
make test-metrics      # Teste les métriques
make dashboard-info    # Info sur les 9 panneaux
```

### **Commandes de Développement**
```bash
make dev-restart-app   # Redémarre FastAPI
make dev-shell         # Shell dans un pod FastAPI
make quick-deploy      # Déploiement sans Terraform
make port-forward-grafana      # Port-forward Grafana (localhost:3000)
make port-forward-prometheus   # Port-forward Prometheus (localhost:9090)
```

## 🌐 URLs d'Accès

Après `make apply`, les services sont accessibles via :

- **FastAPI** : `http://192.168.49.2:xxxxx`
  - Métriques : `/metrics`
  - Health : `/health`
  - Simulation : `/simulate-load`

- **Grafana** : `http://192.168.49.2:xxxxx`
  - Login : `admin` / `admin123`
  - Dashboard automatiquement chargé

- **Prometheus** : `http://192.168.49.2:xxxxx`
- **Alertmanager** : `http://192.168.49.2:xxxxx`

## 📈 Exemple d'Utilisation

```bash
# 1. Déploiement
make apply
# ✅ Stack DevOps Unifié déployée avec succès!
# 📊 Dashboard Grafana avancé avec 9 panneaux configuré!

# 2. Obtenir les URLs
make geturlsgrafana
# 🚀 FastAPI App: http://192.168.49.2:30180
# 📈 Grafana: http://192.168.49.2:31000
# 🔍 Prometheus: http://192.168.49.2:32000

# 3. Générer des métriques
make simulate
# ✅ Trafic simulé! Consultez Grafana pour voir les 9 dashboards avancés.

# 4. Ouvrir Grafana et voir les dashboards en action !
```

## 🚨 Dépannage

### **Problèmes courants**
```bash
# Si pods bloqués en ContainerCreating
kubectl describe pod <pod-name>
make restart-grafana

# Si métriques vides
make test-metrics
make simulate

# Si services non accessibles
make status
minikube service list

# Accès direct via port-forward
make port-forward-grafana    # http://localhost:3000

# Reset complet
make cleanup
make apply
```

## 📁 Structure du Projet

```
fullstackdevops/
├── apps/fastapi/           # Application FastAPI + métriques
├── k8s/                    # Manifests Kubernetes
│   ├── fastapi/           # Déploiement FastAPI
│   └── monitoring/        # Stack monitoring complète
├── monitoring/terraform/   # Infrastructure as Code
├── scripts/               # Scripts d'automatisation
├── Makefile              # Commandes unifiées
└── README.md            # Cette documentation
```

## 🎯 Métriques Disponibles

### **HTTP Metrics**
```
http_requests_total                # Nombre total de requêtes
http_request_duration_seconds      # Distribution des temps de réponse
```

### **Business Metrics**
```
business_operations_total          # Opérations métier
  - operation="data_processing"    # Traitement de données
  - operation="user_fetch"         # Récupération d'utilisateurs
```

### **System Metrics**
```
up                                # Statut du service (0/1)
```

## 🎉 Résultat Final

Après exécution, vous obtenez :
- ✅ **Stack DevOps complète** fonctionnelle
- ✅ **Dashboard Grafana professionnel** avec 9 visualisations
- ✅ **Métriques temps réel** avec refresh automatique
- ✅ **Alertes visuelles** avec seuils colorés
- ✅ **Simulation de charge** intégrée
- ✅ **Monitoring de production** prêt à l'emploi

---

**🚀 Votre stack DevOps professionnelle est prête !**

Lancez `make apply`, ouvrez Grafana, et profitez de votre monitoring avancé !
