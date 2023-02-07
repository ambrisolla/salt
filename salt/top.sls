base:
  '*':
    - common.packages
    - common.configurations
    - common.services
  'G@nodetype:salt-master':
    - salt_master