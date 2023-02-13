#!/usr/bin/env python3

import yaml
import sys

def check_yaml():
  try:
    ydata   = open(sys.argv[1], 'r')
    data    = yaml.safe_load(ydata)
    is_dict = isinstance(data, dict)
    return is_dict
  except:
    return False

check_yaml().lower()