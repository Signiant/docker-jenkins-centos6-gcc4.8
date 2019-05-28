FROM signiant/docker-jenkins-centos6-java8
MAINTAINER devops@signiant.com

ENV BUILD_USER bldmgr
ENV BUILD_USER_GROUP users

# Set the timezone
RUN sed -ri '/ZONE=/c ZONE="America\/New York"' /etc/sysconfig/clock
RUN rm -f /etc/localtime && ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

# Install yum packages required for cmake build node
COPY yum-packages.list /tmp/yum.packages.list
RUN chmod +r /tmp/yum.packages.list
RUN yum install -y `cat /tmp/yum.packages.list`

# Install c/c++ development tools
RUN wget http://people.centos.org/tru/devtools-2/devtools-2.repo -O /etc/yum.repos.d/devtools-2.repo
RUN yum -y install devtoolset-2-gcc devtoolset-2-binutils
RUN yum -y install devtoolset-2-gcc-c++ devtoolset-2-gcc-gfortran
#RUN scl enable devtoolset-2 bash
#RUN source /opt/rh/devtoolset-2/enable

#install python2.7
RUN yum install -y centos-release-scl
RUN yum install -y python27
RUN source scl_source enable python27 && pip install --upgrade pip

# Install cmake3.12
RUN mv /usr/bin/cmake /usr/bin/cmake2
RUN mv /usr/bin/ccmake /usr/bin/ccmake2
RUN wget https://cmake.org/files/v3.12/cmake-3.12.0-Linux-x86_64.tar.gz -O /tmp/cmake-3.12.0-Linux-x86_64.tar.gz
RUN cd /usr/local/bin && \
tar -xzf /tmp/cmake-3.12.0-Linux-x86_64.tar.gz
RUN ln -s /usr/local/bin/cmake-3.12.0-Linux-x86_64/bin/cmake /usr/bin/cmake

RUN printf "\nsource scl_source enable devtoolset-2 python27\n" >> /root/.bashrc
RUN printf "\nsource scl_source enable devtoolset-2 python27\n" >> /home/$BUILD_USER/.bashrc

# Install umpire
ENV UMPIRE_VERSION 0.5.5
RUN source scl_source enable python27 && pip install umpire==${UMPIRE_VERSION}

# Make sure anything/everything we put in the build user's home dir is owned correctly
RUN chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER

EXPOSE 22

# This entry will either run this container as a jenkins slave or just start SSHD
# If we're using the slave-on-demand, we start with SSH (the default)

# Default Jenkins Slave Name
ENV SLAVE_ID JAVA_NODE
ENV SLAVE_OS Linux

ADD start.sh /
RUN chmod 777 /start.sh

CMD ["sh", "/start.sh"]
