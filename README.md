# GitOps Infrastructure with FluxCD

## Overview

This repository demonstrates a GitOps-based infrastructure management system using FluxCD. It showcases a complete setup for managing Kubernetes resources across multiple environments (staging and production) with automated image updates and deployment strategies.

## Project Structure

The project is organized into several key directories:

- `apps/`: Contains application-specific configurations
  - `base/`: Base configurations for applications
  - `staging/`: Staging environment-specific configurations
  - `prod/`: Production environment-specific configurations
- `clusters/`: Cluster-specific configurations
- `infrastructure/`: Infrastructure-related resources
  - `image-update-automation/`: Image update automation configurations
  - `sources/`: Source configurations for FluxCD

## Key Features

1. **Multi-Environment Support**: Separate configurations for staging and production environments.
2. **Automated Image Updates**: Utilizes FluxCD's image automation controllers to automatically update image tags.
3. **Kustomize Integration**: Leverages Kustomize for managing environment-specific configurations.
4. **GitOps Workflow**: All changes to the infrastructure are made through Git, ensuring version control and auditability.
5. **Continuous Deployment**: Automatic synchronization between Git repository and Kubernetes cluster.

## Deployment Strategy

### Staging Environment
- Automatically updates to the latest image tag matching the pattern `staging-[commit-hash]-[timestamp]`.
- Allows for rapid testing of new features and bug fixes.
- Configured with 1 replica for resource efficiency.

### Production Environment
- Uses semantic versioning (SemVer) for image tags.
- Automatically updates to the latest patch version within the v1.x.x range.
- Ensures stability while allowing for minor updates and patches.
- Configured with 3 replicas for high availability.

## Installation and Setup

### Prerequisites
- Kubernetes cluster (version 1.20+)
- kubectl configured to communicate with your cluster
- GitHub account and personal access token with repo permissions

### Installing FluxCD

1. Install the Flux CLI:
   ```bash
   curl -s https://fluxcd.io/install.sh | sudo bash
   ```

2. Export your GitHub personal access token and username:
   ```bash
   export GITHUB_TOKEN=<your-token>
   export GITHUB_USER=<your-username>
   ```

3. Check your Kubernetes cluster:
   ```bash
   flux check --pre
   ```

4. Bootstrap Flux on your cluster:
   ```bash
   flux bootstrap github \
     --owner=$GITHUB_USER \
     --repository=gls-fleet-infra \
     --branch=master \
     --path=./clusters/prod \
     --personal \
     --components-extra=image-reflector-controller,image-automation-controller
   ```

5. Verify the installation:
   ```bash
   flux get all
   ```

## Usage

After installation, Flux will automatically synchronize the cluster state with the Git repository. To make changes:

1. Clone the repository:
   ```bash
   git clone https://github.com/$GITHUB_USER/gls-fleet-infra.git
   ```

2. Make changes to the YAML files as needed.

3. Commit and push your changes:
   ```bash
   git add .
   git commit -m "Update configuration"
   git push
   ```

4. Flux will automatically detect and apply the changes to your cluster.

## Monitoring and Troubleshooting

- Use `flux get all` to see the status of all Flux resources.
- Check logs with `flux logs -f --level debug`.
- For more detailed troubleshooting, use `kubectl` commands to inspect specific resources.
- Monitor image update automation: `flux get images all`


## Configuration Details

### Image Update Automation

The image update automation is configured in `infrastructure/image-update-automation/` directory. It includes:

- ImageRepository definition for the application
- ImagePolicies for both staging and production environments
- ImageUpdateAutomation configuration

### Environment-Specific Configurations

- Staging: `apps/staging/gls-python-helloworld-app/kustomization.yaml`
- Production: `apps/prod/gls-python-helloworld-app/kustomization.yaml`

These files define environment-specific settings like namespaces, replicas, and image tags.

## Related Repositories

### Application Repository

The application code for this infrastructure is maintained in a separate repository:

- Repository: [gls-python-helloworld-app](https://github.com/barissekerciler/gls-python-helloworld-app)
- Description: This repository contains the source code for the Python Hello World application that is deployed and managed by this GitOps infrastructure.

The application repository is an integral part of the overall system and represents the actual workload being deployed through this GitOps setup. It's important to note that changes to the application code in this repository will trigger the image build and update process managed by FluxCD in this infrastructure repository.

## Monitoring and Alerting

### Future Enhancements: Advanced Monitoring

While not currently implemented due to task constraints, a robust monitoring solution using the Prometheus stack is recommended for production environments. This setup would include:

1. **Prometheus**: For metrics collection and storage.
2. **Alertmanager**: For handling alerts and notifications.
3. **Grafana**: For visualization and dashboarding.

This advanced monitoring setup would provide:

- Real-time visibility into cluster and application performance.
- Custom alerting based on predefined thresholds.
- Comprehensive dashboards for both infrastructure and application metrics.
- Long-term metrics storage for trend analysis and capacity planning.

Implementation of this monitoring stack would involve:

- Deploying the Prometheus Operator using Flux.
- Creating custom ServiceMonitors for Flux components and applications.
- Configuring Alertmanager for intelligent alert routing and aggregation.
- Designing Grafana dashboards for visualizing Flux, Kubernetes, and application-specific metrics.

This enhanced monitoring capability would significantly improve observability and incident response times in a production environment.

### Basic Monitoring Setup as Example

To implement basic monitoring for the application and cluster:

1. **Deploy Prometheus and Grafana:**
   Use the kube-prometheus-stack Helm chart via Flux:

   ```yaml:clusters/prod/monitoring/kube-prometheus-stack.yaml
   apiVersion: helm.toolkit.fluxcd.io/v2beta1
   kind: HelmRelease
   metadata:
     name: kube-prometheus-stack
     namespace: monitoring
   spec:
     chart:
       spec:
         chart: kube-prometheus-stack
         sourceRef:
           kind: HelmRepository
           name: prometheus-community
         version: "39.x"
     interval: 1h
     values:
       grafana:
         enabled: true
       prometheus:
         enabled: true
   ```

2. **Configure ServiceMonitors:**
   Create ServiceMonitors for your application:

   ```yaml:apps/base/gls-python-helloworld-app/servicemonitor.yaml
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     name: gls-python-helloworld-app
   spec:
     selector:
       matchLabels:
         app: gls-python-helloworld-app
     endpoints:
     - port: http
       path: /metrics
   ```

3. **Setup Dashboards:**
   Create Grafana dashboards for visualizing metrics. You can import existing dashboards or create custom ones using Grafana's UI.

### Alerting for Critical Issues

To set up alerting for critical issues:

1. **Configure Alertmanager:**
   Alertmanager is included in the kube-prometheus-stack. Configure it in the HelmRelease:

   ```yaml:clusters/prod/monitoring/kube-prometheus-stack.yaml
   spec:
     values:
       alertmanager:
         config:
           global:
             resolve_timeout: 5m
           route:
             group_by: ['job']
             group_wait: 30s
             group_interval: 5m
             repeat_interval: 12h
             receiver: 'slack'
           receivers:
           - name: 'slack'
             slack_configs:
             - api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'
               channel: '#alerts'
   ```

2. **Define PrometheusRules:**
   Create alert rules for your application:

   ```yaml:apps/base/gls-python-helloworld-app/alertrules.yaml
   apiVersion: monitoring.coreos.com/v1
   kind: PrometheusRule
   metadata:
     name: gls-python-helloworld-app-alerts
   spec:
     groups:
     - name: gls-python-helloworld-app
       rules:
       - alert: ApplicationDown
         expr: up{job="gls-python-helloworld-app"} == 0
         for: 5m
         labels:
           severity: critical
         annotations:
           summary: "Application is down"
           description: "gls-python-helloworld-app has been down for more than 5 minutes."
       - alert: HighCPUUsage
         expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
         for: 15m
         labels:
           severity: warning
         annotations:
           summary: "High CPU usage detected"
           description: "CPU usage is above 80% for more than 15 minutes."
   ```

3. **Integrate with Notification Channels:**
   Configure Alertmanager to send notifications to your preferred channels (e.g., Slack, email, PagerDuty).

## Health Checks and Probes

The application deployment includes both liveness and readiness probes to ensure the container is healthy, responsive, and ready to serve traffic:

### Liveness Probe
Checks if the application is running and responsive:
- **Endpoint**: `/` (returns a 200 status code)
- Initial delay: 10 seconds
- Check interval: Every 10 seconds
- Timeout: 5 seconds
- Failure threshold: 3 consecutive failures

The liveness probe helps Kubernetes determine if the application is running correctly and restart the pod if necessary.

### Readiness Probe
Checks if the application is ready to serve traffic:
- **Endpoint**: `/` (returns a 200 status code)
- Initial delay: 5 seconds
- Check interval: Every 10 seconds
- Timeout: 2 seconds
- Success threshold: 1 successful check
- Failure threshold: 3 consecutive failures

The readiness probe ensures that traffic is only sent to pods that are ready to handle requests. This is particularly useful during deployments and when the application needs time to initialize.

These probes help maintain the overall health and reliability of the application in the Kubernetes cluster.

