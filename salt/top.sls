# top.sls file is responsible for mapping all States that will be executed when 
# a Highstate is called. This is the place to put configurations that not be changed,
# as well as a DNS settings, NTP settings and packages that needs to be installed 
# and removed from a server.
base:
  '*':
    - common.packages
    - common.configurations
    - common.services
    - common.schedules
  'G@os_family:RedHat':  
    - common.configurations.rhsm
  'G@nodetype:salt-master':
    - salt_master
  'G@tribe:TIS':
    - tribes.tis