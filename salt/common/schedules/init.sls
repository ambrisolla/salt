# Schedule Highstate. All states in top.sls file will be executed
highstate:
  schedule.present:
    - function: state.highstate
    - minutes: 30
    - splay: 10