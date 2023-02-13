{% from "common/packages/prometheus/node_exporterS/map.jinja" import node_exporter with context %}
{% set install_path = node_exporter['install_path'] %}

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