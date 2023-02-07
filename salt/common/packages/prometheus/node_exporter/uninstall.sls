{% set port = pillar['prometheus']['node_exporter']['port'] %}
{% set version = pillar['prometheus']['node_exporter']['version'] %}
{% set source_hash = pillar['prometheus']['node_exporter']['source_hash'] %}
{% set install_path = pillar['prometheus']['node_exporter']['install_path'] %}

stop service:
  service.dead:
    - name: node_exporter
    - enable: False
    - failhard: True

remove systemd service:
  file.absent:
    - name: /etc/systemd/system/node_exporter.service

remove {{ install_path }} directory:
  file.absent:
    - name: {{ install_path }}

remove user prometheus:
  user.absent:
    - name : prometheus
    - failhard: True

remove group prometheus:
  group.absent:
    - name: prometheus
    - failhard: True