{% if grains['kernel'] != 'Windows' %}
wrong-os-version:
  test.succeed_without_changes:
    - name: This is not a Windows OS!
{% else %}
Install windows_exporter:
  pkg.installed:
    - name: windows_exporter
{% endif %}

