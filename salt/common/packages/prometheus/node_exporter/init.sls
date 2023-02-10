{% from "common/packages/prometheus/node_exporter/map.jinja" import node_exporter with context %}

{% set port         = node_exporter['port'] %}
{% set version      = node_exporter['version'] %}
{% set source_hash  = node_exporter['source_hash'] %}
{% set install_path = node_exporter['install_path'] %}


{% if grains['kernel'] != 'Linux' %}
wrong-os-version:
  test.succeed_without_changes:
    - name: This is not a Linux OS!    
{% else %}
create group prometheus:
  group.present:
    - name: prometheus
    - failhard: True

create user prometheus:
  user.present:
    - name : prometheus
    - shell: /sbin/nologin
    - groups:
      - prometheus
    - failhard: True

download node_exporter:
  file.managed:
    - source: https://github.com/prometheus/node_exporter/releases/download/v{{ version }}/node_exporter-{{ version }}.linux-amd64.tar.gz
    - name: /tmp/node_exporter-{{ version }}.linux-amd64.tar.gz
    - source_hash: {{ source_hash }}
    - failhard: True

extract node_exporter:
  archive.extracted:
    - name: /tmp
    - source: /tmp/node_exporter-{{ version }}.linux-amd64.tar.gz
    - user: prometheus
    - group: prometheus
    - if_missing: /tmp/node_exporter-{{ version }}.linux-amd64
    - failhard: True

copy binaries:
  file.managed:
    - name: {{ install_path }}/node_exporter
    - source: /tmp/node_exporter-{{ version }}.linux-amd64/node_exporter
    - user: prometheus
    - group: prometheus
    - makedirs: True
    - mode: 755
    - failhard: True
    
configure systemd service:
  file.managed:
    - source: salt://common/packages/prometheus/node_exporter/files/node_exporter.service
    - name: /etc/systemd/system/node_exporter.service
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        install_path: {{ install_path }}
        port: {{ port }}
    - failhard: True

enable and start service:
  service.running:
    - name: node_exporter
    - enable: True
    - reload: True
    - failhard: True
{% endif %}