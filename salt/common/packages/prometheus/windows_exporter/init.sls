{% if grains['kernel'] != 'Windows' %}
wrong-os-version:
  test.fail_without_changes:
    - name: This is not a Windows OS!
    - failhard: True
{% endif %}

Install windows_exporter:
  pkg.installed:
    - name: windows_exporter