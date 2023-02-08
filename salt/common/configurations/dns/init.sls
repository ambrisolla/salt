{% from "common/configurations/dns/map.jinja" import dns with context %}
{% set  nameservers = dns.nameservers %}
{% set  search      = dns.search %}
{% set  options     = dns.options %}

dns:
  file.managed:
    - source: salt://common/configurations/dns/files/resolv.conf
    - name: /etc/resolv.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - defaults:
        nameservers: {{ nameservers }}
        search: {{ search }}
        options: {{ options }}