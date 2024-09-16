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

## Best Practices

1. Always use pull requests for significant changes.
2. Regularly update Flux and its components.
3. Use semantic versioning for production releases.
4. Implement proper access controls and RBAC for your Git repository and Kubernetes cluster.
5. Regularly backup your Git repository and etcd data.
6. Use separate branches for staging and production configurations.
7. Implement automated testing before promoting changes to production.

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

