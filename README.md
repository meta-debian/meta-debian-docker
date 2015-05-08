meta-debian-docker
==================

Dockerfile to create a build environment for meta-debian.

Setup
-----

- Create a docker image

    ./make-docker-image.sh

- Run the image

    sudo docker run -i -t meta-debian:1 /bin/bash

