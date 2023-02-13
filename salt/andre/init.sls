{% set andre = pillar.get('andre') %}

always-passes:
  test.succeed_without_changes:
    - name: {{ andre.nome }} {{ andre.gender }}