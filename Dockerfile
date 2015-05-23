#
# Build git-daemon server for meta-debian build environment
#
FROM debian:jessie
MAINTAINER KOBAYASHI Yoshitake

# Please change the follows
ENV DEFAULT_USERNAME debian
ENV DEFAULT_PASSWORD debian
ENV GIT_REPO         /home/$USERNAME/repositories
ENV DEBIAN_MIRROR    http://ftp.jp.debian.org/debian/

# NOTE: The following line will create an account with EMPTY password.
#       Please set a password if you need.
RUN useradd -c "$DEFAULT_USERNAME" -p "" -u 1000 -g users -m \
            -s /bin/bash $DEFAULT_USERNAME
RUN echo "$DEFAULT_USERNAME:$DEFAULT_PASSWORD" | chpasswd
RUN mkdir -p /home/$DEFAULT_USERNAME/repositories

# Might be do not need to edit from here
ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb $DEBIAN_MIRROR jessie main contrib" > /etc/apt/sources.list
RUN echo "deb $DEBIAN_MIRROR jessie-updates main contrib" >> \
         /etc/apt/sources.list

RUN apt-get update
RUN apt-get -y install apt-utils
RUN apt-get -y upgrade
RUN apt-get -y install dialog
RUN apt-get -y install sudo man lv vim-tiny screen
RUN apt-get -y install gcc-multilib build-essential chrpath python cpio
RUN apt-get -y install gawk wget diffstat unzip texinfo
RUN apt-get -y install git git-core git-daemon-run
RUN apt-get -y install openssh-server
# RUN apt-get install make xsltproc docbook-utils fop dblatex xmlto
# RUN apt-get install autoconf automake libtool libglib2.0-dev

# Setup git-daemon
RUN sed -i -e"s/--base-path=\/var\/lib \/var\/lib\/git/--export-all --base-path=\/home\/$DEFAULT_USERNAME\/repositories \/home\/$DEFAULT_USERNAME\/repositories/g" \
    /etc/sv/git-daemon/run

# Add $USERNAME to sudoers file
RUN echo "$DEFAULT_USERNAME ALL=(ALL:ALL) ALL" >> \
         /etc/sudoers.d/$DEFAULT_USERNAME

RUN chown -R $DEFAULT_USERNAME:users /home/$DEFAULT_USERNAME
RUN mkdir -p /var/run/sshd
USER $DEFAULT_USERNAME
WORKDIR /home/$DEFAULT_USERNAME
RUN mkdir -p /home/$DEFAULT_USERNAME/repo-list
RUN git clone https://github.com/ystk/meta-debian-scripts.git
WORKDIR /home/$DEFAULT_USERNAME/meta-debian-scripts/setup-local-gitrepo
RUN sed -i -e"s/\/debian\//\/$DEFAULT_USERNAME\//g" ../config.sh
RUN cp ../repo-lists/src-jessie_meta-debian_tiny-minimal.txt \
       /home/$DEFAULT_USERNAME/repo-list/repo-meta-debian_tiny-minimal.txt
RUN ./pull-repos.sh -c ../config.sh \
    -l /home/$DEFAULT_USERNAME/repo-list/repo-meta-debian_tiny-minimal.txt 

EXPOSE 9148

USER root
# ENTRYPOINT 
