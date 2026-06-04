FROM alpine:3.23
RUN apk update && apk add openssh
RUN ssh-keygen -A
RUN echo "UsePAM no" >> /etc/ssh/sshd_config
