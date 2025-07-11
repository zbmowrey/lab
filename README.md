# Kubernexus

> **“A personal exploration of best practices and modern engineering.”**

---

## 📚 Table of Contents

- [Overview](#overview)
- [💻 Hardware](#-hardware)
- [🛠️ Software Stack](#️-software-stack)
- [🚀 Deployment / Usage Instructions](#-deployment--usage-instructions)
- [🛣️ Roadmap / Future Plans](#️-roadmap--future-plans)
- [📄 License](#-license)
- [🤝 Contributing](#-contributing)
- [👤 About](#-about)

---

## Overview

Welcome to **Kubernexus** — this repository is a personal showcase of modern Kubernetes engineering practices, demonstrated
by hosting a variety of self-managed applications on a home-lab cluster. 

---

## 💻 Hardware

The promise of containerization is that we can run applications anywhere using our provided runtimes, and Kubernetes offers
the ability to orchestrate that across heterogeneous nodes. Kubernexus runs on a home-lab cluster running both **x86_64** 
and **ARM64** architectures, showcasing the flexibility of Kubernetes in a real-world setting.

---

## 🛠️ Software Stack

All nodes in Kubernexus run on **Ubuntu**. This may change in the future, but my own personal comfort with Debian-based
distributions made it an easy decision for this first iteration. Currently, the cluster uses **microk8s**, though I’m 
exploring other Kubernetes distributions to keep things fresh and interesting.

### CI/CD Pipeline

The cluster’s CI/CD process incorporates modern tools to streamline deployments and maintain a clean separation of concerns:

- **GitHub** — Version control and repository management
- **ArgoCD** — GitOps-based continuous deployment
    - Uses **Kustomize** for configuration management
    - Employs private-repo overlays to keep sensitive data out of public templates
- **nginx ingress** and **cert-manager** — Automated SSL/TLS certificate management for secure ingress

Things I'm interested in hosting include: 

- Airflow
- n8n
- AppSmith
- MinIO
- Grafana LGTM
- EDB Postgres
- ... and a dragon's hoard of other self-hosted applications

---

## 🚀 Deployment / Usage Instructions

This repository serves primarily as a **demonstration of concepts and configurations**. It’s not intended as a plug-and-play install script for production use.

If you’re inspired to replicate any part of Kubernexus:

- Review the configs carefully and adapt them to your own environment.
- Understand the security implications of any changes you make.
- Remember: the joy of a homelab is in the tinkering and learning!

---

## 🛣️ Roadmap / Future Plans

The roadmap for Kubernexus includes deploying a broad collection of self-hosted applications, all integrated via **Authentik** for Single Sign-On (SSO) using SAML. Future goals include:

- Expanding monitoring and observability stacks
- Testing alternative Kubernetes distributions
- Hosting various open-source apps for fun and practical utility
- Documenting advanced networking and service mesh configurations

…and probably a few experiments that seem like a good idea at 2 AM. 🤓

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

**Kubernexus** is a personal project and this repository is primarily **read-only for demonstration purposes**.

However, feel free to:

- Fork the repo
- Adapt configurations for your own use
- Share ideas or improvements via issues (though PRs may not be merged)

All within the terms of the MIT License, of course!

---

## 👤 About

Hi, I’m Zach Mowrey! I’m passionate about modern engineering, Kubernetes, and the intersection of technology and creativity.

Check out my blog for more projects, musings, and technical deep-dives:

👉 [https://zbmowrey.com](https://zbmowrey.com)

---

Thanks for stopping by Kubernexus — may your pods always be healthy and your deployments smooth! 🚀
