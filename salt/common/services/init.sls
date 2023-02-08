{% if grains.kernel == 'Linux' %}
include:
  - common.services.ssh
  - common.services.ntp
{% elif grains.kernel == 'Windows' %}
common.services:
  test.succeed_without_changes:
    - name: There is no services for Windows machines!
{% endif %}
