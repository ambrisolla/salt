localtime:
  local.cmd.run:
    - tgt: {{ data['id'] }}
    - arg:
      - salt-call state.apply common.configurations.localtime