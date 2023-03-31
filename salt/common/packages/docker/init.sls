{% from "common/packages/docker/map.jinja" import docker with context %}

install_requisites:
  pkg.installed:
    - pkgs: {{ docker.packages_prereqs }}
    - failhard: True

remove_packages:
  pkg.removed:
    - pkgs: {{ docker.packages_remove }}
    - failhard: True

configure_docker_repository:
  file.managed:
    - source: {{ docker.repository.source }}
    - name: {{ docker.repository.name }}
    - skip_verify: True
    - failhard: True

install_docker:
  pkg.installed:
    - pkgs: {{ docker.packages_install }}
    - failhard: True

configure_docker_systemd_service:
  service.running:
    - name: docker
    - enable: True
    - failhard: True
    - full_restart: True