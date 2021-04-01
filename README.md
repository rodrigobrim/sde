
## This repository was designed to facilitate the creation of a development environment based on containers using podman.

## Requirements:

Sudo permission

## Tested environment:

Ubuntu 20.10

## Setup
```
$ cd sde
$ scripts/env_config.sh
```
## Usage:

### podman run -it ansible
```
$ podmancmdit
```

### podman run ansible-playbook -i invs/localhost /repos/playbooks/playbook.yml -e var=foo
```
$ ans -i invs/localhost /repos/playbooks/playbook.yml -e var=foo
```
See ~/.sde file after setup to see all aliases
