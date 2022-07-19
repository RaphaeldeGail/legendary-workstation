#cloud-config

## Setup of SSH server
ssh_deletekeys: true
ssh_keys:
    rsa_private: |
        ${indent(8, trimspace(rsa_private))}
    rsa_public: ${trimspace(rsa_public)}

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
    lock_passwd: true
    ssh_authorized_keys:
      - ${trimspace(ssh_public)}

write_files:
  - path: /etc/envoy.yaml
    permissions: 0644
    owner: root
    content: |
      static_resources:

        listeners:
        - name: listener_0
          address:
            socket_address:
              address: 0.0.0.0
              port_value: 443
          filter_chains:
          - filters:
            - name: envoy.filters.network.http_connection_manager
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
                stat_prefix: ingress_http
                access_log:
                - name: envoy.access_loggers.stdout
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.access_loggers.stream.v3.StdoutAccessLog
                http_filters:
                - name: envoy.filters.http.router
                  typed_config:
                    "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
                route_config:
                  name: local_route
                  virtual_hosts:
                  - name: local_service
                    domains: ["*"]
                    routes:
                    - match:
                        prefix: "/"
                      route:
                        host_rewrite_literal: www.envoyproxy.io
                        cluster: service_envoyproxy_io

        clusters:
        - name: service_envoyproxy_io
          type: LOGICAL_DNS
          # Comment out the following line to test on v6 networks
          dns_lookup_family: V4_ONLY
          load_assignment:
            cluster_name: service_envoyproxy_io
            endpoints:
            - lb_endpoints:
              - endpoint:
                  address:
                    socket_address:
                      address: www.envoyproxy.io
                      port_value: 443
          transport_socket:
            name: envoy.transport_sockets.tls
            typed_config:
              "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
              sni: www.envoyproxy.io

  - path: /etc/systemd/system/envoy.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=The ENVOY proxy server
      After=syslog.target network-online.target remote-fs.target nss-lookup.target
      Wants=network-online.target

      [Service]
      Type=simple
      PIDFile=/run/envoy.pid
      ExecStartPre=/bin/bash -c '/usr/local/bin/envoy --mode validate -c /etc/envoy.yaml | tee'
      ExecStart=/bin/bash -c '/usr/local/bin/envoy -c /etc/envoy.yaml | tee'
      ExecStop=/bin/kill -s QUIT $MAINPID
      PrivateTmp=true

      [Install]
      WantedBy=multi-user.target

runcmd:
  - systemctl daemon-reload
  - systemctl start envoy.service
