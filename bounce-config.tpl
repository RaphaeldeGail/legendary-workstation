#cloud-config for bounce VM

## Setup of SSH server
ssh_deletekeys: true

# By default, the fingerprints of the authorized keys for the users
# cloud-init adds are printed to the console. Setting
# no_ssh_fingerprints to true suppresses this output.
no_ssh_fingerprints: false
# By default, (most) ssh host keys are printed to the console. Setting
# emit_keys_to_console to false suppresses this output.
ssh:
  emit_keys_to_console: false
## Setup users profiles
users:
  - name: raphael
    primary_group: raphael
    groups: users
    no_create_home: false
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${trimspace(ssh_public)}
