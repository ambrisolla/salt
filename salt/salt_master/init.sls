salt_master_files:
  file.managed:
    - names: 
      - /etc/salt/autosign.conf: 
        - source: salt://salt_master/files/autosign.conf
      - /etc/salt/master.d/master.conf:
        - source: salt://salt_master/files/master.conf
      - /etc/salt/master.d/external_auth.conf:
        - source: salt://salt_master/files/external_auth.conf
      - /etc/salt/master.d/reactor.conf:
        - source: salt://salt_master/files/reactor.conf
      - /etc/salt/master.d/returners.conf:
        - source: salt://salt_master/files/returners.conf
  service.running:
    - name: salt-master
    - enable: True
      watch: 
        - file: salt_master_files
salt_api:
  file.managed:
    - name: /etc/salt/master.d/salt_api.conf
    - source: salt://salt_master/files/salt_api.conf
  service.running:
    - name: salt-api
    - enable: True
      watch: 
        - file: salt_api