meta-debian-docker
==================

Dockerfile to create a build environment for meta-debian.

Setup
-----

- Create a docker image

    ./make-docker-image.sh

If you use proxy server for making this docker image,  
you need to set HTTP_PROXY and HTTPS_PROXY in make-docker-image.sh.

- Run the image

    sudo docker run -d -p 10022:22 meta-debian:1 /usr/sbin/sshd -D

then

    ssh -p 10022 debian@localhost

