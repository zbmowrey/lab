# 🚨 DO NOT TREAD LIGHTLY 🚨
## 📂 This Directory Is Intentionally Git-Ignored

---

### ❓ What is this folder?

This directory is **automatically managed** by the `00-init/01-cluster-setup.sh` script.

When you run that script and choose to initialize your Talos cluster, it will:
1. 🛠️ Generate configuration for your **control plane** and **worker nodes**
2. 📦 Save those config files right here

You *can* move these files elsewhere if you know what you're doing —  
BUT if the script is run again and it doesn't find those files, it may recreate them.

You can choose another location by copying `config_location.example` to `config_location`
in this folder. The script will use that specified location instead. 

---

### ⚠️ Why you shouldn't mess with this folder

- 🔐 The contents are **extremely sensitive** — these are the keys to your Kubernetes kingdom.
- 🚫 **Never** commit these files to version control.
- 🤖 They contain machine and cluster credentials, and even `kubeconfig`.

**Treat this folder like a password manager** — keep it secure and private.

---

### 📁 Files you’ll find here

| File Name           | Purpose                                                    |
|---------------------|------------------------------------------------------------|
| `talosconfig`        | 🧠 TalosCTL config: used for managing the cluster          |
| `controlplane.yaml`  | 🧭 Configuration for control plane nodes                   |
| `worker.yaml`        | ⚙️ Configuration for worker nodes                         |
| `kubeconfig`         | 🔑 Kubernetes config file — lets you interact with the cluster |

---

### 📌 Reminder:
> Only this `README.md` is safe to view or share. The rest? **Lock it down.**
