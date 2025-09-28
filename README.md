# Enterprise DevOps Monitoring Stack

**Complete local DevOps stack with professional monitoring - 9 visual dashboards**

## Key Features

### **Complete Technical Stack**
- **FastAPI** with integrated Prometheus metrics
- **Kubernetes (Minikube)** with Docker driver
- **Prometheus** for metrics collection
- **Grafana** with pre-configured advanced dashboard
- **Alertmanager** for alert management
- **Terraform** for Infrastructure as Code
- **Makefile** for complete automation

### **Professional Grafana Dashboard (9 Panels)**
1. **API Request Rate** - Request rate with color-coded thresholds
2. **Response Time Percentiles** - 95th/50th percentile + average latency
3. **HTTP Status Codes** - Interactive pie chart
4. **Request Rate by Endpoint** - Detailed endpoint analysis
5. **Business Operations** - Custom business metrics
6. **Error Rate** - Error percentage with visual alerts
7. **Service Health** - UP/DOWN service indicator
8. **Request Volume** - Stacked bar chart
9. **Response Time Heatmap** - Advanced thermal map

### **Advanced Features**
- **Auto-refresh** every 5 seconds
- **Color-coded thresholds** (green/yellow/red) on all charts
- **Detailed legends** with min/max/average
- **Multi-series tooltips** for in-depth analysis
- **Prometheus datasource** automatically configured
- **Flexible time range** (5m to 30d)

## Installation and Usage

### **Prerequisites (Ubuntu/Debian)**
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

# Restart session for Docker
newgrp docker
```

### **Ultra-Fast Deployment**
```bash
# 1. Execute the unified script
bash unified-script.sh

# 2. Navigate to the folder
cd fullstackdevops

# 3. Launch the complete stack (fully automated)
make apply

# 4. Get access URLs
make geturlsgrafana

# 5. Generate traffic to see the dashboards
make simulate
```

## Dashboard Usage

### **Grafana Access**
```bash
# Get Grafana URL
make geturlsgrafana

# Login: admin / admin123
# Dashboard: "FastAPI DevOps Stack - Complete Monitoring"
```

### **Metrics Generation**
```bash
make simulate          # Normal traffic (400 requests)
make simulate-load     # Intensive load (1250 requests over 5 rounds)
make test-metrics      # Verify Prometheus metrics
```

### **Real-Time Monitoring**
- **Request Rate**: Continuous updates every 5s
- **Latency**: 95th percentile, median, average in real-time
- **Status Codes**: Visual distribution of HTTP codes
- **Health Status**: Green/red service indicator
- **Heatmap**: Response time distribution

## Available Commands

### **Main Commands**
```bash
make help              # Display all commands
make apply             # Launch complete stack
make geturlsgrafana    # Service access URLs
make simulate          # Generate normal traffic
make simulate-load     # Intensive simulation
make status            # Status of all services
make cleanup           # Clean entire environment
```

### **Debug Commands**
```bash
make logs              # FastAPI logs
make logs-grafana      # Grafana logs
make logs-prometheus   # Prometheus logs
make restart-grafana   # Restart Grafana
make test-metrics      # Test metrics
make dashboard-info    # Info on 9 panels
```

### **Development Commands**
```bash
make dev-restart-app   # Restart FastAPI
make dev-shell         # Shell in FastAPI pod
make quick-deploy      # Deployment without Terraform
make port-forward-grafana      # Port-forward Grafana (localhost:3000)
make port-forward-prometheus   # Port-forward Prometheus (localhost:9090)
```

## Access URLs

After `make apply`, services are accessible via:

- **FastAPI**: `http://192.168.49.2:xxxxx`
  - Metrics: `/metrics`
  - Health: `/health`
  - Simulation: `/simulate-load`

- **Grafana**: `http://192.168.49.2:xxxxx`
  - Login: `admin` / `admin123`
  - Dashboard automatically loaded

- **Prometheus**: `http://192.168.49.2:xxxxx`
- **Alertmanager**: `http://192.168.49.2:xxxxx`

## Usage Example

```bash
# 1. Deployment
make apply
# ✅ Unified DevOps Stack deployed successfully!
# 📊 Advanced Grafana dashboard with 9 panels configured!

# 2. Get URLs
make geturlsgrafana
# 🚀 FastAPI App: http://192.168.49.2:30180
# 📈 Grafana: http://192.168.49.2:31000
# 🔍 Prometheus: http://192.168.49.2:32000

# 3. Generate metrics
make simulate
# ✅ Traffic simulated! Check Grafana to see the 9 advanced dashboards.

# 4. Open Grafana and see the dashboards in action!
```

## Troubleshooting

### **Common Issues**
```bash
# If pods stuck in ContainerCreating
kubectl describe pod <pod-name>
make restart-grafana

# If metrics empty
make test-metrics
make simulate

# If services not accessible
make status
minikube service list

# Direct access via port-forward
make port-forward-grafana    # http://localhost:3000

# Complete reset
make cleanup
make apply
```

## Project Structure

```
fullstackdevops/
├── apps/fastapi/           # FastAPI application + metrics
├── k8s/                    # Kubernetes manifests
│   ├── fastapi/           # FastAPI deployment
│   └── monitoring/        # Complete monitoring stack
├── monitoring/terraform/   # Infrastructure as Code
├── scripts/               # Automation scripts
├── Makefile              # Unified commands
└── README.md            # This documentation
```

## Available Metrics

### **HTTP Metrics**
```
http_requests_total                # Total number of requests
http_request_duration_seconds      # Response time distribution
```

### **Business Metrics**
```
business_operations_total          # Business operations
  - operation="data_processing"    # Data processing
  - operation="user_fetch"         # User retrieval
```

### **System Metrics**
```
up                                # Service status (0/1)
```

## Final Result

After execution, you get:
- ✅ **Complete DevOps stack** functional
- ✅ **Professional Grafana dashboard** with 9 visualizations
- ✅ **Real-time metrics** with auto-refresh
- ✅ **Visual alerts** with color-coded thresholds
- ✅ **Integrated load simulation**
- ✅ **Production-ready monitoring**

## Skills Demonstrated

- **Container Orchestration**: Advanced Kubernetes deployment and management
- **Infrastructure as Code**: Terraform for automated provisioning
- **Monitoring Strategy**: Comprehensive observability implementation
- **API Development**: Production-ready FastAPI with metrics integration
- **DevOps Automation**: End-to-end pipeline automation
- **System Administration**: Linux configuration and optimization

## Technical Highlights

- **Scalable Architecture**: Microservice design with horizontal scaling
- **Service Discovery**: Automatic registration and health checking
- **Resource Management**: Optimized CPU/memory allocation
- **High Availability**: Replica sets with automated failover
- **Monitoring as Code**: Dashboard configurations in version control

---

**Your professional DevOps stack is ready!**

Run `make apply`, open Grafana, and enjoy your advanced monitoring!
