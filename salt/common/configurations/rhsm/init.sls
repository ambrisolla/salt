{% from "common/configurations/rhsm/map.jinja" import activation_key, hostname, ca_consumer, organization with context %}

# Check if the System is registered
{% set is_registered    = True if salt['cmd.retcode']("subscription-manager status") == 0 else False %}

# check if is registered on correct server
{% set rhsm_hostname_output = salt['cmd.shell']('egrep "^hostname" /etc/rhsm/rhsm.conf') | replace(' ','') %}
{% set rhsm_hostname = rhsm_hostname_output.split('=')[1] %}
{% set is_updated = True if rhsm_hostname == hostname else False %}

# show message if all configuration is in correct state
{% if is_registered and is_updated %}
rhsm-message:
  test.succeed_without_changes:
    - name: This is already registered! {{ is_updated }} {{ is_registered }}
{% else  %}

# Install katello-ca-consumer if not installed
{% set is_ca_installed = True if salt['cmd.retcode']("yum list installed katello-ca-consumer-*") == 0 else False %}
{% if not is_ca_installed %}
    download_ca_consumer:
    file.managed:
      - name: /tmp/katello-ca-consumer.rpm
      - source: {{ ca_consumer }}
      - skip_verify: True
      - failhard: True
    install_ca_consumer:
    cmd.run:
      - name: rpm -ivh /tmp/katello-ca-consumer.rpm
      - failhard: True
{% endif %}      
 
# Clean subscription-manage data
rhsm-clean:
  cmd.run:
    - name: subscription-manager clean

rhsm-register:
  cmd.run:
    - name: subscription-manager register --org="{{ organization }}" --activationkey="{{ activation_key }}"

{% endif %}