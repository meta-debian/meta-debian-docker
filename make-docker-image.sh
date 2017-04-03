#!/bin/bash

# Config
FLAG_DOCKER_INSTALL=0
FLAG_UPDATE=0
HTTP_PROXY=`printenv http_proxy`
HTTPS_PROXY=`printenv https_proxy`

usage() {
    echo "Usage: $0 [-i] [-u] [-h]"
    echo "       i: Install Docker"
    echo "       u: Update Docker image"
    echo "       h: Ptint help message"
    exit 0
}

get_latest_tag() {
    local TAG=`sudo docker images | grep deby | sed 's/[\t ]\+/\t/g' | cut -f2 | head -1 | tail -1`
	return $TAG
}

abort() {
	echo "ERROR: $@" 1>&2
	exit 1
}

# Check options
while getopts "iu" OPT
do
    case $OPT in
	i)
            echo "INFO    : Installing Docker"
            FLAG_DOCKER_INSTALL=1
            ;;
	u)
            echo "INFO    : Updating Docker image"
            FLAG_UPDATE=1
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
    echo "ERROR: Please install Docker."
    echo "       To install Docker, you can type as the follows:"
    echo "         ./make-docker-image.sh -i"
    exit 1
fi

# Update currrent deby docker image
if [ $FLAG_UPDATE -ne 0 ]; then
    if [ ! -f Dockerfile-update ]; then
        echo "ERROR: Dockerfile-update does not exist"
        exit 1
    fi
    get_latest_tag
    LATEST_TAG=$?
    NEW_TAG=`expr $LATEST_TAG + 1`
    if [ $LATEST_TAG -le 0 ]; then
        echo "ERROR: Latest tag of docker image cannot found"
        exit 1
	else
	    # Update FROM section in Dockerfile-update with LATEST_TAG
    	sed -i -e "s/FROM deby:.*/FROM deby:$LATEST_TAG/g" ./Dockerfile-update
        if [ -z "${HTTP_PROXY}" ] || [ -z "${HTTPS_PROXY}" ]; then
            sudo docker build -t deby:$NEW_TAG -f Dockerfile-update . || abort "ERROR: Cannot update docker image"
        else
            sudo docker build --build-arg HTTP_PROXY=$HTTP_PROXY --build-arg HTTPS_PROXY=$HTTPS_PROXY \
                               -t deby:$NEW_TAG -f Dockerfile-update . || abort "ERROR: Cannot update docker image"
        fi
        echo "INFO: New tag is deby:$NEW_TAG"
        exit 0
    fi
fi

# Build a docker container
if [ -f Dockerfile ]; then
    if [ -z "${HTTP_PROXY}" ] || [ -z "${HTTPS_PROXY}" ]; then
        sudo docker build -t deby:1 . || abort "ERROR: Cannot create docker image"
    else
        sudo docker build --build-arg HTTP_PROXY=$HTTP_PROXY --build-arg HTTPS_PROXY=$HTTPS_PROXY -t deby:1 . \
                          || abort "ERROR: Cannot create docker image"
    fi
    exit 0
else
    echo "ERROR: Dockerfile does not exist"
    exit 1
fi
# Check the CONTAINER ID
# CONTAINER_ID=`sudo docker ps -l -q`

# Commit it
# sudo docker commit $CONTAINER_ID deby:1
