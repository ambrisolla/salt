beacons:
  inotify:
    - files:
        /etc/localtime:
          mask:
            - modify
        /etc/resolv.conf:
          mask:
            - modify
        /etc/ssh/sshd_config:
          mask:
            - modify
    - disable_during_state_run: True