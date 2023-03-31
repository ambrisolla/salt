{% if data is defined %}
dns:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
      - salt-call state.apply common.configurations.dns
{% endif %}