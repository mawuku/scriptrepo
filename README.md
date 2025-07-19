# CloudBees CI Auto-Installer (Controller or Operations Center)

This Bash script automates the installation of a **CloudBees CI Controller** (or optionally an **Operations Center**) on RPM-based Linux systems. It intelligently installs the correct Java version based on the CI version, handles EC2 metadata for dynamic version detection, and simplifies the setup of CloudBees CI packages.

---

## 🛠 Features

- ✅ Automatic **Java version selection** based on CI version
- ✅ Supports **Controller (`cloudbees-core-cm`)**
- 🧪 (Optional) Operations Center (`cloudbees-core-oc`) via `--role oc` *(coming soon)*
- ✅ Works on AWS EC2 and retrieves version via instance tag `CB_VERSION`
- ✅ Compatible with both IMDSv1 and IMDSv2
- ✅ Handles daemonize dependency for legacy versions
- ✅ Enables and starts the systemd service

---

## 📦 Requirements

- RPM-based Linux distro: Amazon Linux 2, RHEL 7/8/9, CentOS
- Root privileges
- Internet access
- (Optional) EC2 instance tag `CB_VERSION`

---

## 🚀 Usage

```bash
chmod +x install-cbci-controller.sh
sudo ./install-cbci-controller.sh
