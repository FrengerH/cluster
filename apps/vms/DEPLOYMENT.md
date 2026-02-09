# NixOS ARM64 VM Deployment Summary

## Overview

Deploy a NixOS ARM64 headless VM with SSH enabled using KubeVirt.

## Quick Start

```bash
# 1. Build NixOS image
cd apps/vms/nixos-build
./build-image.sh

# 2. Create PVC in cluster
kubectl apply -f ../nixos-pvc.yaml

# 3. Upload qcow2 to PVC
./upload-to-pvc.sh

# 4. Deploy VM and service
kubectl apply -f ../nixos-vm.yaml
```

## Architecture

```
Local Machine                    Kubernetes Cluster
├── nixos-build/              ├── PersistentVolumeClaim (20GB)
│   ├── configuration.nix       │   └── nixos-disk-pvc
│   ├── flake.nix            ├── VirtualMachineInstance
│   ├── build-image.sh        │   └── nixos-vm
│   └── upload-to-pvc.sh     │       └── CPU: 2 cores, RAM: 4GB
└── output/                  └── Service (LoadBalancer)
    └── nixos-disk.qcow2        └── nixos-ssh (Port: 22)
```

## Files Created

### Build Scripts (`apps/vms/nixos-build/`)
- `configuration.nix` - NixOS system configuration
- `flake.nix` - Nix build configuration
- `build-image.sh` - Build qcow2 disk image
- `upload-to-pvc.sh` - Upload to Kubernetes PVC
- `README.md` - Detailed documentation

### Kubernetes Manifests (`apps/vms/`)
- `nixos-pvc.yaml` - PersistentVolumeClaim for disk storage
- `nixos-vm.yaml` - VMI, secret, and service definitions

## VM Specifications

| Setting | Value |
|---------|-------|
| CPU | 2 cores |
| Memory | 4GB RAM |
| Architecture | ARM64 (aarch64) |
| Storage | 20GB PVC |
| OS | NixOS 24.11 |
| SSH | Enabled with password auth |

## Access Credentials

| User | Password | Sudo |
|------|----------|------|
| root | passwd | Yes |
| nixos | passwd | Yes |

## Accessing the VM

```bash
# Get LoadBalancer IP
kubectl get svc nixos-ssh -n kubevirt

# SSH to VM
ssh root@<LB_IP>
# Password: passwd
```

## Customization

Edit `apps/vms/nixos-build/configuration.nix` and rebuild:

```bash
cd apps/vms/nixos-build
./build-image.sh
./upload-to-pvc.sh
```

## Notes

- Images are NOT pushed to any registry
- qcow2 file is stored locally and uploaded directly to PVC
- Requires virtctl for uploading images to PVC
- Works with any StorageClass supporting ReadWriteOnce
- Can be deployed via ArgoCD (apps/vms.yaml)
