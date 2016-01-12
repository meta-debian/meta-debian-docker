
Meta-debian-docker
==================

Dockerfile to create a docker image which has all source repositries for bitbake of meta-debian.  
You can reduce the time of bitbake meta-debian by using git repositries in the docker image   
instead of git repositries in https://github.com/ystk/.

Create a docker image
---------------------

Create a docker iamge by running below command.

    $ ./make-docker-image.sh

If you use proxy server for making this docker image,  
you need to set HTTP_PROXY and HTTPS_PROXY in make-docker-image.sh.  
And don't forget proxy setting of docker command in your machine.  


Run git daemon
--------------

Run git daemon with this docker image.
 
    $ sudo docker run -d -p 10022:22 meta-debian:1 /etc/sv/git-daemon/run -D

Then you can access to all git repositries. For example,

    $ git clone git://${IP_ADDRESS}/debian-acl.git

${IP_ADDRESS} is default address of docker image. It may be 172.17.0.2.

Bitbake with meta-debian-docker
-------------------------------

Please read README of https://github.com/meta-debian/meta-debian for setting meta-debian.  
Before you run below commands,  

    # Setup build directory
    $ export TEMPLATECONF=meta-debian/conf
    $ source ./poky/oe-init-build-env

you need to modify meta-debian/conf/distro/debian.conf file.

    DEBIAN_GIT_URI ??= "git://github.com/ystk"       ==>    DEBIAN_GIT_URI ??= "git://${IP_ADDRESS}"
    DEBIAN_GIT_PROTOCOL ??= "https"                  ==>    DEBIAN_GIT_PROTOCOL ??= "git"
    LINUX_GIT_URI ??= "git://github.com/meta-debian" ==>    LINUX_GIT_URI ??= "git://${IP_ADDRESS}"

${IP_ADDRESS} is default address of docker image. It may be 172.17.0.2.

Login docker image
------------------

If you'd like to check something in docker image, you can login the docker image by running sshd.

    $ sudo docker run -d -p 10022:22 meta-debian:1 /usr/sbin/sshd -D

then

    $ ssh -p 10022 debian@localhost

password is debian.

Update docker image
-------------------

After you created docker image at once, git repositroies may be updated.
In that case, please update git repositories in docker image by runnning some commands manually.

Run sshd in docker, 

    $ sudo docker run -d -p 10022:22 meta-debian:1 /usr/sbin/sshd -D

then, login docker image.

    $ ssh -p 10022 debian@localhost

Create new src-jessie_meta-debian_all.txt, 

    $ cd /home/debian/meta-debian-scripts/repo-lists
	# if you need proxy server setting, please set $https_proxy value here.
	$ ./generate_src-jessie_meta-debian_all.sh
	$ cp src-jessie_meta-debian_all.txt /home/debian/repo-list/repo-meta-debian_all.txt

Update git repositories.

	$ cd /home/debian/meta-debian-scripts/setup-local-gitrepo
	$ ./pull-repos.sh -c ../config.sh -l /home/debian/repo-list/repo-meta-debian_all.txt

Exit and save current container.

    $ exit
	# check current docker container id and save it by meta-debian:new tag.
	$ sudo docker ps -a
	$ sudo docker commit <#container id> meta-debian:<#new tag>

#new tag is any number you like.

Finally, you run git daemon with the latest docker image.

    $ sudo docker run -d -p 10022:22 meta-debian:<#new tag> /etc/sv/git-daemon/run -D
