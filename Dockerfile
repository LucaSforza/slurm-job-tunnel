FROM ubuntu:22.04
RUN apt-get update && apt-get install -y openssh-server
RUN echo "UsePAM=no" > /etc/ssh/sshd_config
