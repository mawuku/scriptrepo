#!/bin/bash

# Author: Makafui Awuku
# Description: Install CloudBees CI Controller on RPM-based Linux systems

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help      Display this help message and exit."
}

parse_version_number() {
    # Converts version like 2.479.3.1 to 24793 for numeric comparison
    echo "$1" | awk -F '.' '{ printf "%d%02d%02d\n", $2, $3, $4 }'
}

install_java_by_version() {
    version_numeric=$(parse_version_number "$CBCI_CM_VERSION")

    if [ "$version_numeric" -lt 23321 ]; then
        echo "Installing Java 8"
        yum install java-1.8.0-openjdk-devel -y > /dev/null 2>&1
    elif [ "$version_numeric" -lt 24791 ]; then
        echo "Installing Java 11"
        yum install java-11-openjdk -y > /dev/null 2>&1
    elif [ "$version_numeric" -lt 24793 ]; then
        echo "Installing Java 17"
        yum install java-17-openjdk -y > /dev/null 2>&1
    else
        echo "Installing Java 21"
        yum install java-21-openjdk -y > /dev/null 2>&1
    fi
}

installCM() {
    echo "Updating packages"
    yum update -y > /dev/null 2>&1

    version_numeric=$(parse_version_number "$CBCI_CM_VERSION")
    if [ "$version_numeric" -lt 24260 ]; then
        echo "Installing daemonize (required for older versions)"
        yum install epel-release -y > /dev/null 2>&1
        yum install daemonize -y > /dev/null 2>&1
    fi

    install_java_by_version

    echo "Installing wget"
    yum install wget -y > /dev/null 2>&1

    echo "Downloading CloudBees CI controller package: $CBCI_CM_VERSION"
    wget -c https://downloads.cloudbees.com/cloudbees-core/traditional/controller/rolling/rpm/RPMS/noarch/cloudbees-core-cm-$CBCI_CM_VERSION.noarch.rpm > /dev/null 2>&1

    echo "Installing CloudBees CI controller package"
    rpm -ivh cloudbees-core-cm-$CBCI_CM_VERSION.noarch.rpm > /dev/null 2>&1

    echo "Starting CloudBees CI controller service"
    systemctl enable cloudbees-core-cm > /dev/null 2>&1
    systemctl start cloudbees-core-cm > /dev/null 2>&1

    echo "Installation complete"
}

# Parse options
while getopts ":h" opt; do
    case "$opt" in
        h) show_help; exit 0 ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# --- EC2 Metadata Detection and Version Assignment ---
metadata_output=$(curl -IL http://169.254.169.254/ 2>/dev/null)

if [[ $metadata_output == *"401 Unauthorized"* ]]; then
    echo "EC2 IMDSv2 detected"
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
    TAG_VALUE=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/CB_VERSION \
        -H "X-aws-ec2-metadata-token: $TOKEN")
    if [ -n "$TAG_VALUE" ]; then
        CBCI_CM_VERSION="$TAG_VALUE-1.1"
    fi
elif [[ $metadata_output == *"200 OK"* ]]; then
    echo "EC2 IMDSv1 detected"
    TAG_VALUE=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/CB_VERSION)
    if [ -n "$TAG_VALUE" ]; then
        CBCI_CM_VERSION="$TAG_VALUE-1.1"
    fi
else
    echo "EC2 metadata not detected"
fi

# --- Final fallback if nothing set yet ---
CBCI_CM_VERSION="${CBCI_CM_VERSION:-${CBCI_CM_VERSION_ENV:-'2.375.4.2-1.1'}}"
echo "Using CloudBees CI version: $CBCI_CM_VERSION"

# Begin install
installCM
exit 0
