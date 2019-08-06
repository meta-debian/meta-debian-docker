Meta-debian-docker
==================

Dockerfile to create a docker image which has all dependencies for
bitbake of Deby image. You can reduce the time for bitbake deby image
by using git repositries in local storage instead of git repositries
in Github.

Preparation
-----------

If you want to have all source code outside the Docker image, please
follow the following steps:

    $ git clone https://github.com/meta-debian/meta-debian-scripts.git
    $ cd meta-debian-scripts/setup-local-repos
    $ ./pull-repos.sh -c ../config.sh -l ../repo-lists/src-deby_minimal.txt

The above command will create a set of repositories on your host.


Create a docker image
---------------------

Create a docker image by running below command.

    $ ./make-docker-image.sh

If you use a proxy for making this docker image, you need to export
http_proxy and https_proxy environment values. And don't forget proxy
setting for docker command in your machine.


Run git daemon
--------------

Run git daemon with this docker image.

    $ docker run -d -p 10022:22 -v /home/debian/repositories:/home/debian/repositories deby:1 /etc/sv/git-daemon/run -D

or

    $ docker run -d -p 10022:22 deby:1 /etc/sv/git-daemon/run -D

Then you can access to all git repositries. For example,

    $ git clone git://${IP_ADDRESS}/debian-acl.git

${IP_ADDRESS} is default address of docker image. It may be
172.17.0.2. If you cannot find the address, check ip address by
running below command.

    $ sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${CONTAINER ID}


Bitbake with meta-debian-docker
-------------------------------

Please read README of https://github.com/meta-debian/meta-debian for
setting Deby.  Before you run below commands,

    # Setup build directory
    $ export TEMPLATECONF=meta-debian/conf
    $ source ./poky/oe-init-build-env

you need to modify meta-debian/conf/distro/deby.conf file.

    DEBIAN_GIT_URI ??= "git://github.com/ystk"   ==>  DEBIAN_GIT_URI ??= "git://${IP_ADDRESS}"
    DEBIAN_GIT_PROTOCOL ??= "https"              ==>  DEBIAN_GIT_PROTOCOL ??= "git"
    MISC_GIT_URI ??= "git://github.com/ystk"     ==>  MISC_GIT_URI ??= "git://${IP_ADDRESS}"
    MISC_GIT_PROTOCOL ??= "https"                ==>  MISC_GIT_PROTOCOL ??= "git"
    LINUX_GIT_URI ??= "git://github.com/ystk"    ==>  LINUX_GIT_URI ??= "git://${IP_ADDRESS}"
    LINUX_GIT_PROTOCOL ??= "https"               ==>  LINUX_GIT_PROTOCOL ??= "git"
    SRC_URI_ALLOWED ??= "git://github.com/ystk/" ==>  SRC_URI_ALLOWED ??= "git://${IP_ADDRESS}"

${IP_ADDRESS} is the address of docker image.


Update repositories from docker image (Not working at the moment)
-----------------------------------------------------------------

After you created docker image at once, git repositroies in https://github.com/ystk may be updated.

In that case, bitbake command maybe fail.

So please update git repositories in your docker image by following command.

    $ ./make-docker-image.sh -u

Then, you can find new tag number in the console.

    $ INFO: New tag is deby:$NEW_TAG

$NEW_TAG is the latest tag number of meta-debian-docker.

Finally, you can run git daemon with the latest docker image and bitbake will succeed.

    $ sudo docker run -d -p 10022:22 deby:$NEW_TAG /etc/sv/git-daemon/run -D

Login docker image
------------------

If you'd like to check something in docker image, you can login the docker image by running sshd.

    $ sudo docker run -d -p 10022:22 -v /home/debian/repositories:/home/debian/repositories deby:1 /usr/sbin/sshd -D

or

    $ sudo docker run -d -p 10022:22 deby:1 /usr/sbin/sshd -D

then

    $ ssh -p 10022 debian@localhost

password is debian.
