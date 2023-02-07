{% from "common/services/ssh/map.jinja" import sshd_config with context %}

ssh:
  file.managed:
    - source: salt://common/services/ssh/files/sshd_config
    - name: /etc/ssh/sshd_config
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        sshd_config: {{ sshd_config }}
  service.running:
    - name: sshd
    - enable: true
    - reload: true
      watch:
        - file: ssh
