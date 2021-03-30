ARG image_version=stable-slim
FROM debian:${image_version}

RUN apt-get update || true \
 && apt install -y python3 curl gnupg software-properties-common python3-pip \
 && apt clean

RUN pip3 install --no-cache-dir ansible paramiko

WORKDIR /root/
