{% from "common/configurations/localtime/map.jinja" import localtime with context %}

{% if localtime.localtime_path != localtime.current_config %}
locatime config:
  file.absent:
    - name: /etc/localtime
/etc/localtime:
  file.symlink:
    - target: {{ localtime.localtime_path }}
{% else %}
localtime configuration:
  test.succeed_without_changes:
    - name: Localtime is defined to {{ localtime.localtime_path }}
{% endif %}