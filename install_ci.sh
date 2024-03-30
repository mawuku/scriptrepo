#!/bin/bash

# Author: Makafui Awuku
# Date Created: 01/03/2024
# Date Modified: 01/03/2024

# Description
# Install Cloudbees CI operaton center on Linux

show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help      Display this help message and exit."
    echo
    echo "Example:"
    echo "  $0 -f input.txt -o output.txt -v"
    echo
    echo "Notes:"
    echo "  - This script requires an input file to operate."
    echo "  - Output file will be overwritten if it already exists."
    echo "  - Verbose mode provides detailed logging."
}

installOC () {
    # Set version of the operations center.
    CBCI_OC_VERSION_SHORT=$(echo $CBCI_OC_VERSION | cut -c 1,3-5)

    # Updating packages
    echo "Updating Unix packages"
    yum update -y > /dev/null 2>&1

    # Check for daemonize dependency and install. 
    if [ $(($CBCI_OC_VERSION_SHORT)) -lt 2426 ]; then
        echo "daemonize needed. Installing it now"
        yum install epel-release -y > /dev/null 2>&1
        yum install daemonize -y > /dev/null 2>&1
    fi

    if [ $(($CBCI_OC_VERSION_SHORT)) -lt 2332 ]; then
        # Detected a CI version below 2.332.1.4, Will install Java 8
        echo "Detected a CI version below 2.332.1.4, Will install Java 8"
        yum install java-1.8.0-openjdk-devel -y > /dev/null 2>&1
    else
        # Detected a CI version 2.332.1.4 or higher. Installing Java 11
        echo "Detected a CI version 2.332.1.4 or higher. Installing Java 11"
        yum install java-11-openjdk -y > /dev/null 2>&1
    fi

    echo "Installing wget"
    yum install wget -y > /dev/null 2>&1

    echo "Downloading Cloudbees CI package"
    wget -c https://downloads.cloudbees.com/cloudbees-core/traditional/operations-center/rolling/rpm/RPMS/noarch/cloudbees-core-oc-$CBCI_OC_VERSION.noarch.rpm > /dev/null 2>&1

    echo "Installing Cloudbees CI OC package"
    rpm -ivh cloudbees-core-oc-$CBCI_OC_VERSION.noarch.rpm > /dev/null 2>&1

    echo "Starting Cloudbees CI OC"
    systemctl enable cloudbees-core-oc > /dev/null 2>&1
    systemctl start cloudbees-core-oc > /dev/null 2>&1
    echo "Installation complete"
}

while getopts ":h" opt; do
    case "$opt" in
        h) 
            show_help
            ;;
        \?) 
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

# Directory where script is run from
HERE="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set default version if environment variable not set
CBCI_OC_VERSION=${CBCI_OC_VERSION_ENV:-'2.375.4.2-1.1'}
echo $CBCI_OC_VERSION

# Check for EC2 instance metadata service version
# Check if the output contains the word "Unauthorized" this is IMDSv2.
output=$(curl -IL  http://169.254.169.254/) 

if [[ $output == *"Unauthorized"* ]]; then
    # Check for IMDv2
    echo "EC2 IMDv2 detected. Will get instance version from EC2 tags with token"
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    CBCI_OC_VERSION=$(curl http://169.254.169.254/latest/meta-data/tags/instance/CB_VERSION -H "X-aws-ec2-metadata-token: $TOKEN")"-1.1"

elif [[ $output == *"200 OK"* ]]; then
    # Check IMDv1
    echo "TEC2 IMDv1 detected. Will get instance version from EC2 tags without a token."
    CBCI_OC_VERSION=$(curl http://169.254.169.254/latest/meta-data/tags/instance/CB_VERSION)"-1.1"

elif [[ $output == *"Failed connect"* ]]; then
    # Check if Server is not EC2
    echo "EC2 not detected, starting installation"
    installOC
else
    # Catch all
    echo "EC2 not detected, starting installation"
    installOC
fi

exit 0

# TODO
# Get instance metadata 
# Get token for IMDV2:- TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
# Get specific tag:- VERS=$(curl http://169.254.169.254/latest/meta-data/tags/instance/CB_VERSION -H "X-aws-ec2-metadata-token: $TOKEN")
