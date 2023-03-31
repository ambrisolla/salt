{% from "common/configurations/dns/map.jinja" import dns with context %}


dns:
  file.managed:
    - source: salt://common/configurations/dns/files/resolv.conf
    - name: /etc/resolv.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        nameservers: {{ dns.nameservers }}
        search: {{ dns.search }}
        options: {{ dns.options }}