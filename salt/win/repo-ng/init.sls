#!jinja|yaml
{% set windows_exporter = {
  'version' : '0.20.0',
  'port' : 9109,
  'collectors' : ','.join([
    'cpu',
    'cpu_info',
    'cs',
    'logical_disk',
    'logon',
    'memory',
    'net',
    'os',
    'service',
    'system',
    'textfile'
  ])
} %}

windows_exporter:
  latest:
    full_name: 'Windows Exporter {{ windows_exporter.version }}'
    installer: 'https://github.com/prometheus-community/windows_exporter/releases/download/v{{ windows_exporter.version }}/windows_exporter-{{ windows_exporter.version }}-amd64.msi'
    uninstaller: 'https://github.com/prometheus-community/windows_exporter/releases/download/v{{ windows_exporter.version }}/windows_exporter-{{ windows_exporter.version }}-amd64.msi'
    install_flags: ' ENABLED_COLLECTORS="{{ windows_exporter.collectors }}" LISTEN_PORT=9109 /qn /norestart'
    uninstall_flags: ' /qn /norestart'
    msiexec: True
    locale: en_US
    reboot: False