FROM ubuntu:16.04
MAINTAINER Hasan Turken

RUN apt-get update && apt-get install -y rsyslog iputils-ping netbase net-tools python openssh-server vim sudo curl python-yaml python-jinja2 python-paramiko python-crypto net-tools openjdk-8-jre netcat bash

RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64

RUN chmod +x /usr/bin/dumb-init

RUN mkdir ~/.ssh && ssh-keygen -N "" -t rsa -f ~/.ssh/id_rsa

COPY common/id_rsa.pub /root/.ssh/authorized_keys
COPY ["common/.vimrc", "common/.profile", "./root/"]
COPY common/start.sh /start.sh

WORKDIR /root

ENV ALLOW_EXIT true

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/start.sh"]
#CMD ["bash"]
