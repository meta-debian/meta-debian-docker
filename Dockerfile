#
# Build git-daemon server for deby build environment
#
FROM debian:jessie
MAINTAINER KOBAYASHI Yoshitake

# Please change the follows
ENV DEFAULT_USERNAME debian
ENV DEFAULT_PASSWORD debian
ENV GIT_REPO         /home/$USERNAME/repositories
ENV DEBIAN_MIRROR    http://ftp.jp.debian.org/debian/
ENV DEBIAN_SECURITY  http://security.debian.org/

# NOTE: Please reset the password if you need.
RUN useradd -c "$DEFAULT_USERNAME" -p "" -u 1000 -g users -m \
            -s /bin/bash $DEFAULT_USERNAME
RUN echo "$DEFAULT_USERNAME:$DEFAULT_PASSWORD" | chpasswd
RUN mkdir -p /home/$DEFAULT_USERNAME/repositories

# ---------------------------------------
# Might be do not need to edit from here
# ---------------------------------------
ENV DEBIAN_FRONTEND noninteractive

RUN echo "deb $DEBIAN_MIRROR jessie main contrib" > /etc/apt/sources.list
RUN echo "deb $DEBIAN_SECURITY jessie/updates main contrib" >> \
         /etc/apt/sources.list
RUN echo "deb $DEBIAN_MIRROR jessie-updates main contrib" >> \
         /etc/apt/sources.list

RUN bash -c 'if test -n "$HTTP_PROXY" ; then echo "Acquire::http::Proxy \"$HTTP_PROXY\";"; fi'
RUN bash -c 'if test -n "$HTTP_PROXY" ; then echo "Acquire::http::Proxy \"$HTTP_PROXY\";" >> /etc/apt/apt.conf; fi'
RUN apt-get update
#
# Install packages for ssh, poky, git-daemon and deby
#
RUN apt-get -y upgrade
RUN apt-get -y install git git-core git-daemon-run
RUN apt-get -y install dialog
RUN apt-get -y install sudo man lv vim-tiny screen
RUN apt-get -y install gawk wget diffstat unzip
RUN apt-get -y install openssh-server
RUN apt-get -y install jq curl
RUN apt-get -y install texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev xterm

#
# Setup git-daemon
#
RUN sed -i -e"s/--base-path=\/var\/lib \/var\/lib\/git/--export-all --base-path=\/home\/$DEFAULT_USERNAME\/repositories --enable=receive-pack \/home\/$DEFAULT_USERNAME\/repositories/g" \
    /etc/sv/git-daemon/run

# Add $USERNAME to sudoers file
RUN echo "$DEFAULT_USERNAME ALL=(ALL:ALL) ALL" >> \
         /etc/sudoers.d/$DEFAULT_USERNAME

RUN chown -R $DEFAULT_USERNAME:users /home/$DEFAULT_USERNAME
RUN mkdir -p /var/run/sshd
USER $DEFAULT_USERNAME
WORKDIR /home/$DEFAULT_USERNAME
RUN bash -c 'if test -n "$HTTP_PROXY" ; then git config --global http.proxy "$HTTP_PROXY"; fi'
RUN bash -c 'if test -n "$HTTPS_PROXY" ; then git config --global https.proxy "$HTTP_PROXY"; fi'
######################################################################
RUN mkdir -p /home/$DEFAULT_USERNAME/repo-list
RUN git clone https://github.com/ystk/meta-debian-scripts.git
WORKDIR /home/$DEFAULT_USERNAME/meta-debian-scripts/repo-lists
RUN ./generate_src-deby_all.sh
WORKDIR /home/$DEFAULT_USERNAME/meta-debian-scripts/setup-local-gitrepo
RUN sed -i -e"s/\/debian\//\/$DEFAULT_USERNAME\//g" ../config.sh
RUN cp ../repo-lists/src-deby_all.txt \
       /home/$DEFAULT_USERNAME/repo-list/repo-deby_all.txt
#RUN ./pull-repos.sh -c ../config.sh \
#    -l /home/$DEFAULT_USERNAME/repo-list/repo-deby_all.txt

# Set permission for git push command
#RUN chmod -R a+rw /home/$DEFAULT_USERNAME/repositories
######################################################################

EXPOSE 9418
USER root
# ENTRYPOINT
