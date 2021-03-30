#!/bin/bash -x

username=`id -u -n`

test_podman(){
  podman image exists docker.io/library/debian:stable-slim
  if [ $? -eq 0 ]
  then
    return
  fi
  podman pull debian:stable-slim
  if [ $? -ne 0 ]
  then
    fail_podman=1
  fi
}

test_ssh(){
  nc -z localhost 22
  if [ $? -ne 0 ]
  then
    fail_ssh=1
  fi
}

test_ssh_key(){
  ssh -o BatchMode=yes ${username}@localhost true
  if [ $? -ne 0 ]
  then
    fail_ssh_key=1
  fi
}

configure_podman(){
  sudo apt install -y podman
  sudo systemctl enable podman.service
  sudo systemctl start podman.service
  
  containers_config_path=~/.config/containers
  script_path="`dirname \"$0\"`/.."
  
  mkdir -p ${containers_config_path}
  cp ${script_path}/config/policy.json ${containers_config_path}
  cp ${script_path}/config/registries.conf ${containers_config_path}
} 

configure_ssh(){
  sudo apt install -y openssh-server
  sudo systemctl enable ssh.service
  sudo systemctl start ssh.service
}

configure_ssh_key(){
  ssh-keygen -b 2048 -t rsa -f /home/${username}/.ssh/id_rsa -q -N ""
  cat /home/${username}/.ssh/id_rsa.pub >> /home/${username}/.ssh/authorized_keys
}

configure_ansible(){
  sudo ln -s /usr/bin/python3 /usr/bin/python
}

test_podman
if [ -z ${fail_podman+x} -z ]
then
  configure_podman
fi

test_ssh
if [ ! -z ${fail_ssh+x} ]
then
  configure_ssh
fi

test_ssh_key
if [ ! -z ${fail_ssh_key+x} ]
then
  configure_ssh_key
fi

configure_ansible
