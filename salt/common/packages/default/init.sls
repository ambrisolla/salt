{% from "common/packages/default/map.jinja" import packages with context %}

{% if grains['kernel'] == 'Linux' %}
Install Linux Packages:
  pkg.installed:
    - pkgs: {{ packages.to_install }}
Uninstall Linux Packages:
  pkg.removed:
    - pkgs: {{ packages.to_remove }}
{% elif grains['kernel'] == 'Windows' %}
  {% for pkg in packages.to_install %}
Install Windows {{ pkg }} Package:
  chocolatey.installed:
    - name: {{ pkg }}
  {% endfor %}
  {% for pkg in packages.to_remove %}
Uninstall Windows {{ pkg }} Package:
  chocolatey.uninstalled:
    - name: {{ pkg }}
  {% endfor %}
{% else %}
common.packages:
  test.succeed_without_changes:
    - name: OS not supported!
{% endif %}
