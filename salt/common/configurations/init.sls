{% if grains['kernel'] == 'Linux' %}
include:
  - common.configurations.dns
  - common.configurations.localtime
{% elif grains['kernel'] == 'Windows' %}
common.configurations:
  test.succeed_without_changes:
    - name: There is no configurations for Windows machines!

{% endif %}