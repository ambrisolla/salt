{% if data is defined %}
ssh:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
      - salt-call state.apply common.services.ssh
{% endif %}