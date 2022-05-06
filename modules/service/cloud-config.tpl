#cloud-config

## Setup of SSH server
ssh_deletekeys: true
ssh_keys:
    rsa_private: |
        ${indent(8, trimspace(rsa_private))}
    rsa_public: ${trimspace(rsa_public)}
    dsa_private: |
        ${indent(8, trimspace(dsa_private))}
    dsa_public: ${trimspace(dsa_public)}