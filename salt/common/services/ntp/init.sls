{% from "common/services/ntp/map.jinja" import ntp with context %}

ntp:
  file.managed:
    - source: salt://common/services/ntp/files/chrony.conf
    - name: /etc/chrony.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        servers: {{ ntp.servers }}
  service.running:
    - name: chronyd
    - enable: True
      watch:
        - file: ntp
