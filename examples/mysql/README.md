# About

In this cluster, I make use of the Percona MySQL Operator to deploy and manage MySQL clusters.
This example folder includes both the base and overlay Kustomize configurations you'd need
to deploy a sample MySQL Cluster.

I also include a reference job to be run concurrently with the cluster creation which will
create the necessary application database and application user.

# Requirements

## Percona MySQL Operator

Percona MySQL Operator is a Kubernetes operator that simplifies the deployment and management
of MySQL clusters on Kubernetes. It provides features like automated backups, scaling, and
failover, making it easier to run MySQL in a cloud-native environment. I rely on this
Operator to manage all MySQL clusters in my home lab.

## 1Password Operator

The 1Password Operator is a Kubernetes operator that integrates with 1Password (through a
1Password Connect server) to manage secrets in Kubernetes. It allows you to manage and
store secrets in 1Password and automatically sync them to Kubernetes secrets. This
operator also has the ability to trigger redeployments when secrets change, enabling
seamless updates to applications that rely on those secrets.

## Kustomize

Kustomize is a tool for customizing Kubernetes YAML configurations. It allows you to
create overlays on top of base configurations, making it easier to manage different
environments or configurations without duplicating YAML files. I use Kustomize to
redact sensitive details from my [public repository](https://github.com/zbmowrey/lab),
while storing overlays in a private repository. This helps to prevent disclosure of
domains, hosts, and other configuration details that might compromise security.