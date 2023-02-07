include:
  - common.packages.default
{% if grains.kernel == 'Linux' %}
  - common.packages.prometheus.node_exporter
{% elif grains.kernel == 'Windows' %}
  - common.packages.prometheus.windows_exporter
{% endif %}