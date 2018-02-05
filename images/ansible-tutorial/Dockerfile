#FROM turkenh/nutsh:1.0
FROM ubuntu:16.04

RUN apt-get update 
RUN apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:ansible/ansible
RUN apt-get update 
RUN apt-get install -y ansible openssh-server openssh-client fping curl nmap bmon htop iotop git build-essential bash-completion bash dnsutils iputils-ping iproute2 mc man-db vim sudo net-tools openjdk-8-jre netcat

WORKDIR /root

RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh
RUN mkdir -p /root/workspace
RUN mkdir /tutorials

COPY common/ansible.cfg /etc/ansible/ansible.cfg

COPY ["common/id_rsa", "common/id_rsa.pub", "/root/.ssh/"]
COPY ["common/.vimrc", "common/.profile", "/root/"]
COPY common/start.sh /start.sh

RUN chmod 644 /root/.ssh/id_rsa.pub && chmod 600 /root/.ssh/id_rsa


ENV GOPATH /root/go/
ENV GOROOT /usr/lib/go-1.9
ENV PATH $PATH:$GOPATH:$GOROOT/bin


RUN mkdir /root/go && apt-get install -y golang-1.9 && go get -u github.com/turkenh/nutsh && cd /root/go/src/github.com/turkenh/nutsh && go build && mv /root/go/src/github.com/turkenh/nutsh/nutsh /usr/bin

WORKDIR /root/workspace


RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64

RUN chmod +x /usr/bin/dumb-init

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bash"]


#ENTRYPOINT ["bash"]
#ENTRYPOINT ["nutsh", "run", "/tutorials"]