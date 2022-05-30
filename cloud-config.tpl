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
  - name: cloudservice
    uid: 2000

write_files:
  - path: /etc/systemd/system/cloudservice.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Start a simple docker container

      [Service]
      ExecStart=/usr/bin/docker run --rm -u 2000 --name=envoy envoyproxy/envoy:v1.21-latest
      ExecStop=/usr/bin/docker stop envoy
      ExecStopPost=/usr/bin/docker rm envoy

runcmd:
  - systemctl daemon-reload
  - systemctl start cloudservice.service
