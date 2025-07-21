# Kubernexus

> **“A personal exploration of best practices and modern (over?) engineering.”**

---

## Overview

**00-init** - contains the cluster startup scripts which will enable addons, configure 1Password, etc. You would execute
this script from the repo root by calling `make init`. **Note that you need a working kubernetes cluster and a working
kubectl command before this script will do you any good.**

**base** - contains base application configurations. These have been sanitized of any sensitive values and are provided
as a reference for how to install and run these applications. NOTE: the base applications are not in an immediately
operable state. For the configurations in this repo to work, you'll need to create your own overlays/patches and
use Kustomize to apply them. 

**examples** - contains overlays/patches for the base applications. These have been cleansed of any sensitive values,
but the data structures are intact. Here you can see exactly which settings I'm overlaying on those base applications,
and start to piece out how to create your own overlays. I hope this gives you a significant head start. 

