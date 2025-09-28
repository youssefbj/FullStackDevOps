


#!/bin/bash

# =============================================================================
# SCRIPT DEVOPS UNIFIÉ - STACK COMPLÈTE AVEC DASHBOARD GRAFANA AVANCÉ
# =============================================================================

# Création de la structure complète du projet
mkdir -p fullstackdevops/{apps/fastapi,k8s/{fastapi,monitoring/{prometheus,grafana,alertmanager}},monitoring/{terraform,dashboards},scripts}

cd fullstackdevops

# =============================================================================
# 1. APPLICATION FASTAPI avec métriques Prometheus
# =============================================================================

cat > apps/fastapi/app.py << 'EOF'
from fastapi import FastAPI
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
import time
import random
import uvicorn

app = FastAPI(title="DevOps Stack API", version="1.0.0")

# Métriques Prometheus
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
BUSINESS_METRIC = Counter('business_operations_total', 'Business operations counter', ['operation'])

@app.middleware("http")
async def prometheus_middleware(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    REQUEST_DURATION.observe(duration)
    
    return response

@app.get("/")
def read_root():
    return {"message": "Stack DevOps API is running!", "version": "1.0.0"}

@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": time.time()}

@app.get("/simulate-load")
def simulate_load():
    processing_time = random.uniform(0.1, 2.0)
    time.sleep(processing_time)
    
    BUSINESS_METRIC.labels(operation="data_processing").inc()
    
    return {
        "message": "Load simulation completed",
        "processing_time": processing_time,
        "load_level": "high" if processing_time > 1.0 else "normal"
    }

@app.get("/api/users")
def get_users():
    BUSINESS_METRIC.labels(operation="user_fetch").inc()
    return {"users": [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]}

@app.get("/metrics")
def get_metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOF

cat > apps/fastapi/requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
prometheus-client==0.19.0
EOF

cat > apps/fastapi/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# =============================================================================
# 2. KUBERNETES FASTAPI
# =============================================================================

cat > k8s/fastapi/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi-app
  labels:
    app: fastapi-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fastapi-app
  template:
    metadata:
      labels:
        app: fastapi-app
    spec:
      containers:
      - name: fastapi
        image: fastapi-devops:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 8000
        env:
        - name: ENV
          value: "production"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        readinessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 10
EOF

cat > k8s/fastapi/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: fastapi-service
  labels:
    app: fastapi-app
spec:
  selector:
    app: fastapi-app
  ports:
  - port: 80
    targetPort: 8000
    protocol: TCP
  type: ClusterIP
EOF

# =============================================================================
# 3. PROMETHEUS CONFIGURATION
# =============================================================================

cat > k8s/monitoring/prometheus/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s

    rule_files:
      - "alert_rules.yml"

    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093

    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']

      - job_name: 'fastapi-app'
        metrics_path: '/metrics'
        static_configs:
          - targets: ['fastapi-service:80']
        scrape_interval: 5s

      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)

  alert_rules.yml: |
    groups:
      - name: fastapi-alerts
        rules:
          - alert: HighRequestLatency
            expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 1
            for: 2m
            labels:
              severity: warning
            annotations:
              summary: "High request latency detected"
              description: "95th percentile latency is above 1s"

          - alert: HighErrorRate
            expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
            for: 1m
            labels:
              severity: critical
            annotations:
              summary: "High error rate detected"
              description: "Error rate is above 10%"
EOF

cat > k8s/monitoring/prometheus/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        args:
          - '--config.file=/etc/prometheus/prometheus.yml'
          - '--storage.tsdb.path=/prometheus/'
          - '--web.console.libraries=/etc/prometheus/console_libraries'
          - '--web.console.templates=/etc/prometheus/consoles'
          - '--web.enable-lifecycle'
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: prometheus-config
          mountPath: /etc/prometheus/
        resources:
          requests:
            memory: "400Mi"
            cpu: "100m"
          limits:
            memory: "800Mi"
            cpu: "200m"
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
EOF

cat > k8s/monitoring/prometheus/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: prometheus
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: NodePort
EOF

# =============================================================================
# 4. GRAFANA AVEC DASHBOARD COMPLET ET AVANCÉ
# =============================================================================

cat > k8s/monitoring/grafana/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
data:
  prometheus.yaml: |
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        access: proxy
        url: http://prometheus:9090
        isDefault: true
        editable: true

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards-config
data:
  dashboards.yaml: |
    apiVersion: 1
    providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-complete
data:
  fastapi-complete-dashboard.json: |
    {
      "id": null,
      "title": "FastAPI DevOps Stack - Complete Monitoring",
      "tags": ["fastapi", "devops", "prometheus", "kubernetes"],
      "timezone": "browser",
      "refresh": "5s",
      "time": {
        "from": "now-15m",
        "to": "now"
      },
      "timepicker": {
        "refresh_intervals": ["5s", "10s", "30s", "1m", "5m"],
        "time_options": ["5m", "15m", "1h", "6h", "12h", "24h", "2d", "7d", "30d"]
      },
      "panels": [
        {
          "id": 1,
          "title": "🚀 API Request Rate (req/s)",
          "type": "stat",
          "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "palette-classic"},
              "mappings": [],
              "thresholds": {
                "steps": [
                  {"color": "green", "value": null},
                  {"color": "yellow", "value": 5},
                  {"color": "red", "value": 10}
                ]
              },
              "unit": "reqps",
              "custom": {
                "displayMode": "lcd",
                "orientation": "horizontal"
              }
            }
          },
          "options": {
            "reduceOptions": {
              "values": false,
              "calcs": ["lastNotNull"],
              "fields": ""
            },
            "orientation": "auto",
            "textMode": "auto",
            "colorMode": "background",
            "graphMode": "area",
            "justifyMode": "auto"
          },
          "targets": [
            {
              "expr": "sum(rate(http_requests_total[1m]))",
              "legendFormat": "Total Requests/sec",
              "refId": "A"
            }
          ]
        },
        {
          "id": 2,
          "title": "⚡ Response Time Percentiles",
          "type": "timeseries",
          "gridPos": {"h": 8, "w": 10, "x": 6, "y": 0},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "palette-classic"},
              "custom": {
                "drawStyle": "line",
                "lineInterpolation": "smooth",
                "lineWidth": 2,
                "fillOpacity": 15,
                "gradientMode": "opacity",
                "spanNulls": false,
                "insertNulls": false,
                "showPoints": "never",
                "pointSize": 5,
                "stacking": {"mode": "none", "group": "A"},
                "axisPlacement": "auto",
                "axisLabel": "",
                "scaleDistribution": {"type": "linear"},
                "hideFrom": {"legend": false, "tooltip": false, "vis": false}
              },
              "mappings": [],
              "thresholds": {
                "steps": [
                  {"color": "green", "value": null},
                  {"color": "yellow", "value": 0.5},
                  {"color": "red", "value": 1}
                ]
              },
              "unit": "s",
              "min": 0
            }
          },
          "options": {
            "tooltip": {"mode": "multi", "sort": "none"},
            "legend": {
              "displayMode": "table",
              "placement": "bottom",
              "values": ["min", "max", "mean"]
            }
          },
          "targets": [
            {
              "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
              "legendFormat": "95th percentile",
              "refId": "A"
            },
            {
              "expr": "histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))",
              "legendFormat": "50th percentile (median)",
              "refId": "B"
            },
            {
              "expr": "rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])",
              "legendFormat": "Average",
              "refId": "C"
            }
          ]
        },
        {
          "id": 3,
          "title": "🎯 HTTP Status Codes Distribution",
          "type": "piechart",
          "gridPos": {"h": 8, "w": 8, "x": 16, "y": 0},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "palette-classic"},
              "custom": {
                "hideFrom": {"legend": false, "tooltip": false, "vis": false}
              },
              "mappings": [
                {"options": {"200": {"color": "green", "index": 0, "text": "200 Success"}}, "type": "value"},
                {"options": {"404": {"color": "yellow", "index": 1, "text": "404 Not Found"}}, "type": "value"},
                {"options": {"500": {"color": "red", "index": 2, "text": "500 Server Error"}}, "type": "value"}
              ]
            }
          },
          "options": {
            "reduceOptions": {
              "values": false,
              "calcs": ["lastNotNull"],
              "fields": ""
            },
            "pieType": "pie",
            "tooltip": {"mode": "single", "sort": "none"},
            "legend": {"displayMode": "table", "placement": "right", "values": ["value", "percent"]},
            "displayLabels": ["name", "percent"]
          },
          "targets": [
            {
              "expr": "sum by (status) (rate(http_requests_total[5m]))",
              "legendFormat": "{{status}}",
              "refId": "A"
            }
          ]
        },
        {
          "id": 4,
          "title": "📈 Request Rate by Endpoint",
          "type": "timeseries",
          "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "palette-classic"},
              "custom": {
                "drawStyle": "line",
                "lineInterpolation": "smooth",
                "lineWidth": 1,
                "fillOpacity": 10,
                "gradientMode": "none",
                "spanNulls": false,
                "insertNulls": false,
                "showPoints": "never",
                "pointSize": 5,
                "stacking": {"mode": "none", "group": "A"},
                "axisPlacement": "auto",
                "axisLabel": "",
                "scaleDistribution": {"type": "linear"},
                "hideFrom": {"legend": false, "tooltip": false, "vis": false}
              },
              "mappings": [],
              "unit": "reqps"
            }
          },
          "options": {
            "tooltip": {"mode": "multi", "sort": "desc"},
            "legend": {"displayMode": "table", "placement": "bottom", "values": ["min", "max", "mean"]}
          },
          "targets": [
            {
              "expr": "sum by (endpoint) (rate(http_requests_total[1m]))",
              "legendFormat": "{{endpoint}}",
              "refId": "A"
            }
          ]
        },
        {
          "id": 5,
          "title": "🔧 Business Operations Rate",
          "type": "timeseries",
          "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "palette-classic"},
              "custom": {
                "drawStyle": "line",
                "lineInterpolation": "smooth",
                "lineWidth": 2,
                "fillOpacity": 20,
                "gradientMode": "hue",
                "spanNulls": false,
                "insertNulls": false,
                "showPoints": "never",
                "pointSize": 5,
                "stacking": {"mode": "none", "group": "A"},
                "axisPlacement": "auto",
                "axisLabel": "",
                "scaleDistribution": {"type": "linear"},
                "hideFrom": {"legend": false, "tooltip": false, "vis": false}
              },
              "mappings": [],
              "unit": "ops"
            }
          },
          "options": {
            "tooltip": {"mode": "multi", "sort": "desc"},
            "legend": {"displayMode": "table", "placement": "bottom", "values": ["min", "max", "mean"]}
          },
          "targets": [
            {
              "expr": "rate(business_operations_total[1m])",
              "legendFormat": "{{operation}}",
              "refId": "A"
            }
          ]
        },
        {
          "id": 6,
          "title": "⚠️ Error Rate (%)",
          "type": "stat",
          "gridPos": {"h": 4, "w": 6, "x": 0, "y": 16},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "thresholds"},
              "mappings": [],
              "thresholds": {
                "steps": [
                  {"color": "green", "value": null},
                  {"color": "yellow", "value": 1},
                  {"color": "orange", "value": 5},
                  {"color": "red", "value": 10}
                ]
              },
              "unit": "percent",
              "custom": {"displayMode": "lcd", "orientation": "horizontal"}
            }
          },
          "options": {
            "reduceOptions": {
              "values": false,
              "calcs": ["lastNotNull"],
              "fields": ""
            },
            "orientation": "auto",
            "textMode": "auto",
            "colorMode": "background",
            "graphMode": "area",
            "justifyMode": "auto"
          },
          "targets": [
            {
              "expr": "sum(rate(http_requests_total{status=~\"4..|5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100",
              "legendFormat": "Error Rate %",
              "refId": "A"
            }
          ]
        },
        {
          "id": 7,
          "title": "🚦 Service Health Status",
          "type": "stat",
          "gridPos": {"h": 4, "w": 6, "x": 6, "y": 16},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "thresholds"},
              "mappings": [
                {"options": {"0": {"color": "red", "index": 0, "text": "DOWN"}}, "type": "value"},
                {"options": {"1": {"color": "green", "index": 1, "text": "UP"}}, "type": "value"}
              ],
              "thresholds": {
                "steps": [
                  {"color": "red", "value": null},
                  {"color": "green", "value": 1}
                ]
              },
              "unit": "short",
              "custom": {"displayMode": "lcd", "orientation": "horizontal"}
            }
          },
          "targets": [
            {
              "expr": "up{job=\"fastapi-app\"}",
              "legendFormat": "FastAPI Health",
              "refId": "A"
            }
          ]
        },
        {
          "id": 8,
          "title": "📊 Request Volume Over Time",
          "type": "timeseries",
          "gridPos": {"h": 4, "w": 12, "x": 12, "y": 16},
          "fieldConfig": {
            "defaults": {
              "color": {"mode": "palette-classic"},
              "custom": {
                "drawStyle": "bars",
                "lineInterpolation": "linear",
                "lineWidth": 1,
                "fillOpacity": 80,
                "gradientMode": "none",
                "spanNulls": false,
                "insertNulls": false,
                "showPoints": "never",
                "pointSize": 5,
                "stacking": {"mode": "normal", "group": "A"},
                "axisPlacement": "auto",
                "axisLabel": "",
                "scaleDistribution": {"type": "linear"},
                "hideFrom": {"legend": false, "tooltip": false, "vis": false}
              },
              "mappings": [],
              "unit": "short"
            }
          },
          "options": {
            "tooltip": {"mode": "multi", "sort": "desc"},
            "legend": {"displayMode": "list", "placement": "bottom"}
          },
          "targets": [
            {
              "expr": "sum by (method) (increase(http_requests_total[1m]))",
              "legendFormat": "{{method}}",
              "refId": "A"
            }
          ]
        },
        {
          "id": 9,
          "title": "⏱️ Response Time Heatmap",
          "type": "heatmap",
          "gridPos": {"h": 8, "w": 24, "x": 0, "y": 20},
          "fieldConfig": {
            "defaults": {
              "custom": {
                "hideFrom": {"legend": false, "tooltip": false, "vis": false}
              }
            }
          },
          "options": {
            "calculate": false,
            "yAxis": {"unit": "s"},
            "cellGap": 1,
            "color": {"mode": "scheme", "scheme": "Spectral", "steps": 128},
            "yBucketBound": "auto"
          },
          "targets": [
            {
              "expr": "sum(increase(http_request_duration_seconds_bucket[1m])) by (le)",
              "legendFormat": "{{le}}",
              "refId": "A",
              "format": "heatmap"
            }
          ]
        }
      ],
      "schemaVersion": 27,
      "version": 0,
      "uid": "fastapi-devops-complete"
    }
EOF

cat > k8s/monitoring/grafana/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: "admin123"
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        volumeMounts:
        - name: grafana-datasources
          mountPath: /etc/grafana/provisioning/datasources
        - name: grafana-dashboards-config
          mountPath: /etc/grafana/provisioning/dashboards
        - name: grafana-dashboard-complete
          mountPath: /var/lib/grafana/dashboards
        resources:
          requests:
            memory: "200Mi"
            cpu: "100m"
          limits:
            memory: "400Mi"
            cpu: "200m"
      volumes:
      - name: grafana-datasources
        configMap:
          name: grafana-datasources
      - name: grafana-dashboards-config
        configMap:
          name: grafana-dashboards-config
      - name: grafana-dashboard-complete
        configMap:
          name: grafana-dashboard-complete
EOF

cat > k8s/monitoring/grafana/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: grafana
spec:
  selector:
    app: grafana
  ports:
  - port: 3000
    targetPort: 3000
  type: NodePort
EOF

# =============================================================================
# 5. ALERTMANAGER
# =============================================================================

cat > k8s/monitoring/alertmanager/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
data:
  alertmanager.yml: |
    global:
      smtp_smarthost: 'localhost:587'
      smtp_from: 'alertmanager@devops.local'

    route:
      group_by: ['alertname']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 1h
      receiver: 'web.hook'

    receivers:
    - name: 'web.hook'
      webhook_configs:
      - url: 'http://localhost:5001/'
        send_resolved: true

    inhibit_rules:
      - source_match:
          severity: 'critical'
        target_match:
          severity: 'warning'
        equal: ['alertname', 'dev', 'instance']
EOF

cat > k8s/monitoring/alertmanager/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alertmanager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:latest
        args:
          - '--config.file=/etc/alertmanager/alertmanager.yml'
          - '--storage.path=/alertmanager'
        ports:
        - containerPort: 9093
        volumeMounts:
        - name: alertmanager-config
          mountPath: /etc/alertmanager
        resources:
          requests:
            memory: "200Mi"
            cpu: "100m"
          limits:
            memory: "300Mi"
            cpu: "200m"
      volumes:
      - name: alertmanager-config
        configMap:
          name: alertmanager-config
EOF

cat > k8s/monitoring/alertmanager/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: alertmanager
spec:
  selector:
    app: alertmanager
  ports:
  - port: 9093
    targetPort: 9093
  type: NodePort
EOF

# =============================================================================
# 6. TERRAFORM CONFIGURATION
# =============================================================================

cat > monitoring/terraform/providers.tf << 'EOF'
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
EOF

cat > monitoring/terraform/variables.tf << 'EOF'
variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "fastapi-devops"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "local"
}
EOF

cat > monitoring/terraform/main.tf << 'EOF'
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name = "prometheus"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name = "prometheus"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.prometheus.metadata[0].name
    namespace = kubernetes_service_account.prometheus.metadata[0].namespace
  }
}

output "monitoring_namespace" {
  value = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_service_account" {
  value = kubernetes_service_account.prometheus.metadata[0].name
}
EOF


# =============================================================================
# 7. SCRIPTS D'AUTOMATISATION
# =============================================================================

cat > scripts/setup.sh << 'EOF'
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
EOF

cat > scripts/cleanup.sh << 'EOF'
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
EOF

cat > scripts/urls.sh << 'EOF'
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
EOF

# =============================================================================
# 8. MAKEFILE COMPLET UNIFIÉ
# =============================================================================

cat > Makefile << 'EOF'
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
EOF

# =============================================================================
# 9. README UNIFIÉ COMPLET
# =============================================================================

cat > README.md << 'EOF'
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
EOF

echo "✅ SCRIPT DEVOPS UNIFIÉ CRÉÉ AVEC SUCCÈS!"
echo ""
echo "🎯 FEATURES INCLUSES:"
echo "   ✅ Stack technique complète (FastAPI + K8s + Prometheus + Grafana + Alertmanager)"
echo "   ✅ Dashboard Grafana avancé avec 9 panneaux visuels"
echo "   ✅ Métriques temps réel avec refresh automatique"
echo "   ✅ Seuils colorés et alertes visuelles"
echo "   ✅ Simulation de charge intégrée"
echo "   ✅ Scripts d'automatisation complets"
echo "   ✅ Infrastructure as Code avec Terraform"
echo "   ✅ Documentation complète et troubleshooting"
echo ""
echo "🚀 POUR UTILISER:"
echo "1. cd fullstackdevops"
echo "2. make apply"
echo "3. make geturlsgrafana"
echo "4. make simulate"
echo "5. Ouvrir Grafana → Dashboard: 'FastAPI DevOps Stack - Complete Monitoring'"
echo ""
echo "🎉 STACK DEVOPS PROFESSIONNELLE PRÊTE À L'EMPLOI !"