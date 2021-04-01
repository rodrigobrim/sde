#!/bin/bash

username=`id -u -n`
ansible_inv=/home/${username}/invs/localhost
repo_path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; cd .. ; pwd -P )"

ansible_container=docker.io/rodrigobrim/ansible:latest

test_podman(){
  skopeo >/dev/null 2>&1
  if [ $? -ne 0 ]
  then
    fail_podman=1
  fi
  podman image exists docker.io/library/debian:stable-slim >/dev/null 2>&1
  if [ $? -eq 0 ]
  then
    return
  fi
  podman pull debian:stable-slim >/dev/null 2>&1
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
  ls /home/${username}/.ssh/id_rsa >/dev/null 2>&1
  if [ $? -ne 0 ]
  then
    fail_ssh_key=1
  fi
}

test_authorized_keys(){
  grep -F -f /home/${username}/.ssh/id_rsa.pub /home/${username}/.ssh/authorized_keys >/dev/null 2>&1
  if [ $? -ne 0 ]
  then
    fail_authorized_keys=1
  fi
}

configure_podman(){
  sudo apt install -y podman skopeo runc
  sudo systemctl enable podman.service
  sudo systemctl start podman.service
  
  containers_config_path=~/.config/containers
  
  mkdir -p ${containers_config_path}
  cp ${repo_path}/config/policy.json ${containers_config_path}
  cp ${repo_path}/config/registries.conf ${containers_config_path}
} 

configure_ssh(){
  sudo apt install -y openssh-server
  sudo systemctl enable ssh.service
  sudo systemctl start ssh.service
}

configure_ssh_key(){
  ssh-keygen -b 2048 -t rsa -f /home/${username}/.ssh/id_rsa -q -N ""
}

configure_authorized_keys(){
  cat /home/${username}/.ssh/id_rsa.pub >> /home/${username}/.ssh/authorized_keys
}

configure_sudo_nopasswd(){
  echo "${username} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${username}
}

configure_ansible(){
  primary_network=`ip ro | grep default | head -1 | awk '{print $3}' | cut -d'.' -f'1-3'`
  primary_address=`ip ad | grep ${primary_network} | awk '{print $2}' | cut -d'/' -f1`
  mkdir -p `dirname ${ansible_inv}`
  cp ${repo_path}/config/ansible.cfg /home/${username}/invs
cat > ${ansible_inv} <<end_inv
[all]
${primary_address}
end_inv
  podman run -v "/home/${username}:/home" -v "${repo_path}/ansible:/root/ansible" -v "/home/${username}/invs:/etc/ansible" ${ansible_container} ansible-playbook -i /home/invs/`basename ${ansible_inv} suffix` -u ${username} ansible/bashrc.yml
}

test_podman
if [ ! -z ${fail_podman+x} ]
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

test_authorized_keys
if [ ! -z ${fail_authorized_keys+x} ]
then
  configure_authorized_keys
fi

configure_ansible
configure_sudo_nopasswd

read -p "Press any key to reload .bashrc (finish this session) or ctrl+c to cancel" -n 1 -r
kill -USR1 $PPID
