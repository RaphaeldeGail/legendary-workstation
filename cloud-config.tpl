#cloud-config

## Setup of SSH server
ssh_deletekeys: true
ssh_keys:
    rsa_private: |
        ${indent(8, trimspace(rsa_private))}
    rsa_public: ${trimspace(rsa_public)}

## Setup users profiles
users:
  - name: raphael
    primary_group: raphael
    groups: users
    no_create_home: true
    lock_passwd: true
    ssh_authorized_keys:
      - ${trimspace(ssh_public)}