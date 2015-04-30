#!/bin/bash

# Config
FLAG_DOCKER_INSTALL=0

usage() {
    echo "Usage: $0 [-i] [-h]"
    echo "       i: Install Docker"
    echo "       h: Ptint help message"
    exit 0
}

# Check options
while getopts "i" OPT
do
    case $OPT in
        i)
            echo "INFO    : Installing Docker" 
            FLAG_DOCKER_INSTALL=1
            ;;
	h)
	    usage
	    ;;
	*)
	    usage
	    ;;
    esac
done
shift $((OPTIND - 1))

# Check distro information
if [ `which apt-get` ]; then
    # Debian and Ubuntu
    sudo apt-get install lsb-release
else
    # Other distro
    echo "ERROR: Not tested (e.g. yum)"
    exit 1
fi
DISTNAME=`lsb_release --id --short`        # Distribution
DISTCODE=`lsb_release --codename --short`  # Codename
echo "Distribution: $DISTNAME   Codename: $DISTCODE"

# Preparation
if [ $FLAG_DOCKER_INSTALL -ne 0 ]; then
    if [ $DISTNAME = 'Ubuntu' ]; then
	if [ $DISTCODE = "trusty" ]; then
            sudo apt-get install -y apt-transport-https
            sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
            sudo sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
            sudo apt-get update
            sudo apt-get install -y lxc-docker
	else
            echo "ERROR: Not tested on $DISTCODE"
            exit 1
	fi
    elif [ $DISTNAME = 'Debian' ]; then
	if [ $DISTCODE = 'jessie' ]; then
            sudo apt-get install -y curl
	    curl -sSL https://get.docker.com/ | sh
	else
            echo "ERROR: Not tested on $DISTCODE"
            exit 1
	fi
    else
        echo "ERROR: Not tested"
        exit 1
    fi # DISTNAME
fi # FLAG_DOCKER_INSTALL

# Check docker installation
if [ ! `which docker` ]; then
    echo "ERROR: Please install docker first!"
    exit 1
fi

# Build a docker container
if [ -f Dockerfile ]; then
    sudo docker build -t meta-debian:1 .
else
    echo "ERROR: Dockerfile does not exist"
    exit 1
fi
# Check the CONTAINER ID
CONTAINER_ID=`docker ps -l -q`

# Commit it
sudo docker commit $CONTAINER_ID meta-debian:1
