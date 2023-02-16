#!/usr/bin/env python3

import os
import re
import sys
import json
import yaml
import shutil
import subprocess as sb
from   argparse   import ArgumentParser

def create_temporary_environment(kwargs):
  try:
    ''' set variables '''
    states_dir = kwargs['states_dir']
    pillar_dir = kwargs['pillar_dir']
    salt_env   = kwargs['salt_env']

    ''' create temporary directories, if exists, removes and creates again '''
    if not re.match('^/srv/[a-z]',states_dir):
      print('Error: States directory needs to be within /srv/ !')
      sys.exit(1)
    elif not re.match('^/srv/[a-z]',pillar_dir):
      print('Error: Pillar directory needs to be within /srv/ !')
      sys.exit(1)
    else:
      directories = [states_dir, pillar_dir]
      for directory in directories:
        if not os.path.exists(directory):
          os.makedirs(directory)
        else:
          shutil.rmtree(directory)
          os.makedirs(directory)
      
      ''' copy states '''
      rsync_state_cmd = f'rsync -av salt/ {states_dir}/ --delete'
      rsync_state = sb.run(rsync_state_cmd, shell=True, stdout=sb.PIPE, stderr=sb.PIPE)
      if rsync_state.returncode != 0:
        print(f'Error: {sb.stderr}')
        sys.exit(1)
      
      ''' copy pillars '''
      rsync_pillar_cmd = f'rsync -av pillar/ {pillar_dir}/ --delete'
      rsync_pillar = sb.run(rsync_pillar_cmd, shell=True, stdout=sb.PIPE, stderr=sb.PIPE)
      if rsync_pillar.returncode != 0:
        print(f'Error: {sb.stderr}')
        sys.exit(1)
      
      '''
        Replace environment "base" to "{salt_env}" in top.sls file.
        This is necessary because the environment variable "base" is used 
        as a main environment in Salt.
      '''
      top_sls = open(f'{pillar_dir}/top.sls', 'r').read()
      top_sls_test = re.sub('^base:',f'{salt_env}:', top_sls)
      with open(f'{pillar_dir}/top.sls', 'w') as file:
          file.write(top_sls_test)
          file.close()

  except Exception as err:
    print(err)
    sys.exit(1)

def test_states(kwargs):
  try:
    states_dir = kwargs['states_dir']
    salt_env = kwargs['salt_env']
    sls_files = [ x for x in os.walk(states_dir) ]
    states = []
    for root,dir,filenames in sls_files:
      for filename in filenames:
        sls_file = f'{root}/{filename}'.replace(f'{states_dir}/','')
        if re.search('.sls$',sls_file):
          state = sls_file.replace('.sls','').replace('/','.')
          state = re.sub('.init$','',state)

          ''' Do not append top.sls state and all states that 
              placed in reactor directory or reactor.sls file 
          '''
          excluded_pattern = '(\.reactor(.|$)|^win.repo-ng)'
          if state != 'top' and not re.search(excluded_pattern, state):
            states.append(state)
    states_status = []
    for state in states:
      cmd = sb.run(f'salt-call state.sls_exists {state} saltenv={salt_env} --out=json', 
        shell=True, stderr=sb.PIPE, stdout=sb.PIPE)
      states_status.append(cmd.returncode)
      if cmd.returncode == 0:
        state_is_valid = 'PASSED'
      else:
        state_is_valid = 'FAILED'
      print(f' - testing state {state}: {state_is_valid}')    
    return 1 not in states_status
  except Exception as err:
    print(err)
    sys.exit(1)

def test_pillar(kwargs):
  try:
    sls_files = [ x for x in os.walk(kwargs['pillar_dir']) ]
    pillar_status = []
    for root,dir,filenames in sls_files:
      for filename in filenames:
        try:
          sls_file = open(f'{root}/{filename}','r').read()
          yaml_data = yaml.safe_load(sls_file)
          pillar_is_valid = isinstance(yaml_data, dict)
          print(f' - testing pillar file {root}/{filename}: {pillar_is_valid}')    
          pillar_status.append(pillar_is_valid)
        except:
          print(f' - testing pillar file {root}/{filename}: {False}')    
          pillar_status.append(False)
    return False not in pillar_status
  except Exception as err:
    print(err)
    sys.exit(1)

def test_salt(**kwargs):
  create_temporary_environment(kwargs)
  states_checked = test_states(kwargs)
  pillar_checked = test_pillar(kwargs)
  print(f'\n - Check States summary: {"SUCCESS" if states_checked else "FAILED"}')
  print(f' - Check Pillar summary: {"SUCCESS" if pillar_checked else "FAILED"}')

def test_db_tables(**kwargs):
  pass

if __name__ == '__main__':
  parser = ArgumentParser()
  parser.add_argument('--salt-env',        help='Salt environment')
  parser.add_argument('--test-salt',       help='Test States', action='store_true')
  parser.add_argument('--states-dir',      help='Directory to store temporary States files')
  parser.add_argument('--pillar-dir',      help='Directory to store temporary Pillar files')
  parser.add_argument('--test-db-tables',  help='Test Database tables', action='store_true')
  parser.add_argument('--db-tables',       help='Database tables to test', nargs='+')
  parser.add_argument('--db-host',         help='Database host')
  parser.add_argument('--db-name',         help='Database name')
  parser.add_argument('--db-username',     help='Database username')
  parser.add_argument('--db-password',     help='Database password')
  parser.add_argument('--db-port',         help='Database port')
  args = vars(parser.parse_args())
  actions = [
    args['test_salt'],
    args['test_db_tables']]
  if actions.count(True) < 1:
    print('Error: At least one action (--test-states, --test-db-tables, --test-pillar) needs to be specified.')
    sys.exit(1)
  elif actions.count(True) > 1:
    print('Error: Only one action (--test-states, --test-db-tables, --test-pillar) needs to be specified.')
    sys.exit(1)
  else:
    if args['test_salt']:
      if args['states_dir'] == None or args['salt_env'] == None or args['pillar_dir'] == None:
        print('Error: Missing parameters (--states-dir, --pillar-dir, --salt-env)!')
        sys.exit(1)
      else:
        test_salt(
          states_dir=args['states_dir'],
          pillar_dir=args['pillar_dir'],
          salt_env=args['salt_env'])
    elif args['test_db_tables']:
      if args['db_tables']    == None or \
          args['db_host']     == None or \
          args['db_name']     == None or \
          args['db_username'] == None or \
          args['db_password'] == None or \
          args['db_port']     == None:
        print('Error: Missing parameters (--db-tables',
          '--db-host, --db-name, --db-username, --db-password, --db-port)!')
        sys.exit(1)
      else:
        test_db_tables(
          database_tables=args)