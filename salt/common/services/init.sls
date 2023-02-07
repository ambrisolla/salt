{% if grains.kernel == 'Linux' %}
include:
  - common.services.ssh
{% elif grains.kernel == 'Windows' %}
common.services:
  test.succeed_without_changes:
    - name: There is no services for Windows machines!
{% endif %}
