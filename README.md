# RKE2 Vagrant Environment

This repository provides a fully automated Vagrant-based environment for deploying [RKE2](https://docs.rke2.io/), Rancher's Kubernetes distribution, in either a **single-node control plane** or a **high-availability (HA) control plane** configuration. In HA mode, the control plane spans three nodes and uses [kube-vip](https://kube-vip.io/) for virtual IP failover and leader election. You can also customize the number of worker nodes and network settings, making this setup ideal for local testing, development, and experimentation.

---

## Features

- Deploy RKE2 with either:
  - A **single-node control plane** (no VIP, lightweight setup)
  - A **three-node HA control plane** with **kube-vip**
- Automatically provisions control plane and worker nodes
- Configurable number of worker nodes
- Customizable CPU, memory, and network settings via `settings.yaml`

---

## Usage

### 1. Install Prerequisites

- [Vagrant](https://www.vagrantup.com/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### 2. Configure `settings.yaml`

Edit the file to match your desired topology and network.

### 3. Start the Environment

```bash
vagrant up
```

This will:
- Create the required folders
- Provision each node with its role (control plane or worker)
- Configure networking and kube-vip
- Wait for ingress controller health before removing bootstrap IP

### 4. Access the Cluster

After provisioning, you can access the cluster using:

```bash
vagrant ssh node1
kubectl get nodes
```

---

## Cleanup

To destroy all VMs and remove resources:

```bash
vagrant destroy -f
```

---

## Notes

- VIP is assigned to `eth1` and used for control plane bootstrapping.
- The script waits for both kube-vip and ingress-nginx to be healthy before removing the temporary `/24` IP.
- You can customize the kube-vip manifest and RBAC files in `files/`.

---

## License

MIT License. See `LICENSE` file for details.
