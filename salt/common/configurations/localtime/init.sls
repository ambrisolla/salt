{% if grains.os_family == 'RedHat' %}
  {% set localtime_path = '/usr/share/zoneinfo/UTC' %}
{% elif grains.os_family == 'Debian' %}
  {% set localtime_path = '/usr/share/zoneinfo/Etc/UTC' %}
{% endif %}

{% set localtime = {
    'current_config' : salt['cmd.run']('readlink -f /etc/localtime'),
    'config'         : localtime_path
  } 
%}

{% if localtime.config != localtime.current_config %}
locatime config:
  file.absent:
    - name: /etc/localtime
/etc/localtime:
  file.symlink:
    - target: {{ localtime.config }}
{% else %}
localtime configuration:
  test.succeed_without_changes:
    - name: Localtime is defined to {{ localtime.config }}
{% endif %}


