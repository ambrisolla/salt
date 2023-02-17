#!/usr/bin/env python3

import os
import re
import sys
import json
import yaml
import shutil
import psycopg2
import subprocess as sb
from   argparse   import ArgumentParser

# set colors
class message:
  Black='\033[0;30m'        # Black
  Red='\033[0;31m'          # Red
  Green='\033[0;32m'        # Green
  Yellow='\033[0;33m'       # Yellow
  Blue='\033[0;34m'         # Blue
  Purple='\033[0;35m'       # Purple
  Cyan='\033[0;36m'         # Cyan
  White='\033[0;37m'        # White
  Color_Off='\033[0m'      # Color Off
  success=f'{Green}SUCCESS{Color_Off}'
  warning=f'{Yellow}WARNING{Color_Off}'
  failed=f'{Red}FAILED{Color_Off}'

def create_temporary_environment(kwargs):
  try:
    ''' set variables '''
    temp_states_dir = kwargs['temp_states_dir']
    temp_pillar_dir = kwargs['temp_pillar_dir']
    salt_env   = kwargs['salt_env']

    ''' create temporary directories, if exists, removes and creates again '''
    if not re.match('^/srv/[a-z]',temp_states_dir):
      print('Error: States directory needs to be within /srv/ !')
      sys.exit(1)
    elif not re.match('^/srv/[a-z]',temp_pillar_dir):
      print('Error: Pillar directory needs to be within /srv/ !')
      sys.exit(1)
    else:
      directories = [temp_states_dir, temp_pillar_dir]
      for directory in directories:
        if not os.path.exists(directory):
          os.makedirs(directory)
        else:
          shutil.rmtree(directory)
          os.makedirs(directory)
      
      ''' copy states '''
      rsync_state_cmd = f'rsync -av salt/ {temp_states_dir}/ --delete'
      rsync_state = sb.run(rsync_state_cmd, shell=True, stdout=sb.PIPE, stderr=sb.PIPE)
      if rsync_state.returncode != 0:
        print(f'Error: {sb.stderr}')
        sys.exit(1)
      
      ''' copy pillars '''
      rsync_pillar_cmd = f'rsync -av pillar/ {temp_pillar_dir}/ --delete'
      rsync_pillar = sb.run(rsync_pillar_cmd, shell=True, stdout=sb.PIPE, stderr=sb.PIPE)
      if rsync_pillar.returncode != 0:
        print(f'Error: {sb.stderr}')
        sys.exit(1)
      
      '''
        Replace environment "base" to "{salt_env}" in top.sls file.
        This is necessary because the environment variable "base" is used 
        as a main environment in Salt.
      '''
      top_sls = open(f'{temp_pillar_dir}/top.sls', 'r').read()
      top_sls_test = re.sub('^base:',f'{salt_env}:', top_sls)
      with open(f'{temp_pillar_dir}/top.sls', 'w') as file:
        file.write(top_sls_test)
        file.close()
  except Exception as err:
    print(err)
    sys.exit(1)

def test_states(kwargs):
  try:
    temp_states_dir = kwargs['temp_states_dir']
    salt_env = kwargs['salt_env']
    sls_files = [ x for x in os.walk(temp_states_dir) ]
    states = []
    for root,dir,filenames in sls_files:
      for filename in filenames:
        sls_file = f'{root}/{filename}'.replace(f'{temp_states_dir}/','')
        if re.search('.sls$',sls_file):
          state = sls_file.replace('.sls','').replace('/','.')
          state = re.sub('.init$','',state)

          ''' Do not append top.sls state and all states that 
              placed in reactor directory or reactor.sls file 
          '''
          #excluded_pattern = '(\.reactor(.|$)|^win.repo-ng)'
          excluded_pattern = '^win.repo-ng'
          if state != 'top' and not re.search(excluded_pattern, state):
            states.append(state)
    states_status = []
    for state in states:
      cmd = sb.run(f'salt-call state.sls_exists {state} saltenv={salt_env} --out=json', 
        shell=True, stderr=sb.PIPE, stdout=sb.PIPE)
      states_status.append(cmd.returncode)
      if cmd.returncode == 0:
        state_is_valid = message.success
      else:
        state_is_valid = message.failed
      print(f' - testing state {state}: {state_is_valid}')    
    return 1 not in states_status
  except Exception as err:
    print(err)
    sys.exit(1)

def test_pillar(kwargs):
  try:
    sls_files = [ x for x in os.walk(kwargs['temp_pillar_dir']) ]
    pillar_status = []
    for root,dir,filenames in sls_files:
      for filename in filenames:
        try:
          sls_file = open(f'{root}/{filename}','r').read()
          yaml_data = yaml.safe_load(sls_file)
          pillar_is_valid = isinstance(yaml_data, dict)
          print(f' - testing pillar file {root}/{filename}: {message.success if pillar_is_valid else message.failed}')    
          pillar_status.append(pillar_is_valid)
        except:
          print(f' - testing pillar file {root}/{filename}: {message.failed}')    
          pillar_status.append(False)
    return False not in pillar_status
  except Exception as err:
    print(err)
    sys.exit(1)

def test_salt(**kwargs):
  create_temporary_environment(kwargs)
  states_checked = test_states(kwargs)
  pillar_checked = test_pillar(kwargs)
  print(f'\n - Check States summary: {message.success if states_checked else message.failed}')
  print(f' - Check Pillar summary: {message.success if pillar_checked else message.failed}')
  if not pillar_checked or not states_checked:
    print(f'Error: Some tests failed!')
    sys.exit(1)

def show_changes(kwargs):
  states_dir      = kwargs['states_dir']
  states_files    = os.walk(states_dir)
  current_states  = [] 
  for root,dir,filenames in states_files:
    for filename in filenames:
      if re.search('.sls$', filename) and not re.match(f'top.sls', filename) and not re.search(f'{states_dir}/win/repo-ng',root):
        path = f'{root}/{filename}'        
        state = re.sub(f'{states_dir}/|.init.sls|.sls','',path).replace('/','.')
        current_states.append(state)
  temp_states_dir      = kwargs['temp_states_dir']
  temp_states_files    = os.walk(temp_states_dir)
  new_states  = [] 
  for root,dir,filenames in temp_states_files:
    for filename in filenames:
      if re.search('.sls$', filename) and not re.match(f'top.sls', filename) and not re.search(f'{temp_states_dir}/win/repo-ng',root):
        path = f'{root}/{filename}'
        state = re.sub(f'{temp_states_dir}/|.init.sls|.sls','',path).replace('/','.')
        new_states.append(state)
  states_will_removed    = [ x for x in current_states if x not in new_states]
  states_will_not_change = [ x for x in current_states if x in new_states]
  states_will_be_added   = [ x for x in new_states if x not in current_states]
  for state in states_will_not_change:
    print(f'{message.Green} Will not be changed:{message.Color_Off} {state}')
  for state in states_will_be_added:
    print(f'{message.Yellow} Will be added:{message.Color_Off} {state}')
  for state in states_will_removed:
    print(f'{message.Red} Will be removed:{message.Color_Off} {state}')
  print(f'\n{message.Yellow}WARNING! This job step compares states names/paths, not states contents! {message.Color_Off}')


def test_db_tables(kwargs):
  try:
    conn = psycopg2.connect(
      host=kwargs['db_host'],
      database=kwargs['db_name'],
      user=kwargs['db_username'],
      password=kwargs['db_password']
    )
    ''' Run a simple query to check if the table exists '''
    for table in kwargs['db_tables']:    
      cursor = conn.cursor()
      cursor.execute(f'select count(*) from {table}')
      res = cursor.fetchone()
      table_verified = isinstance(list(res)[0], int)
      print(f' - testing table {table}: {message.success if table_verified else message.failed}')
      if not table_verified:
        print('Error: table {table}')
        sys.exit(1)
      cursor.close()
  except (Exception, psycopg2.DatabaseError) as err:
    print(err)
    sys.exit(1)

if __name__ == '__main__':
  parser = ArgumentParser()
  parser.add_argument('--salt-env',        help='Salt environment')
  parser.add_argument('--test-salt',       help='Test States', action='store_true')
  parser.add_argument('--temp-states-dir', help='Directory to store temporary States files')
  parser.add_argument('--temp-pillar-dir', help='Directory to store temporary Pillar files')
  parser.add_argument('--test-db-tables',  help='Test Database tables', action='store_true')  
  parser.add_argument('--db-tables',       help='Database tables to test', nargs='+')
  parser.add_argument('--db-host',         help='Database host')
  parser.add_argument('--db-name',         help='Database name')
  parser.add_argument('--db-username',     help='Database username')
  parser.add_argument('--db-password',     help='Database password')
  parser.add_argument('--db-port',         help='Database port')
  parser.add_argument('--show-changes',    help='Show changed States', action='store_true')
  parser.add_argument('--states-dir',      help='Directory where States files are stored')
  args = vars(parser.parse_args())
  actions = [
    args['test_salt'],
    args['test_db_tables'],
    args['show_changes']]
  if actions.count(True) < 1:
    print('Error: At least one action (--test-salt, --test-db-tables, --show-changes) needs to be specified.')
    sys.exit(1)
  elif actions.count(True) > 1:
    print('Error: Only one action (--test-salt, --test-db-tables, --show-changes) needs to be specified.')
    sys.exit(1)
  else:
    if args['test_salt']:
      if args['temp_states_dir'] == None or args['salt_env'] == None or args['temp_pillar_dir'] == None:
        print('Error: Missing parameters (--states-dir, --pillar-dir, --salt-env)!')
        sys.exit(1)
      else:
        test_salt(
          temp_states_dir=args['temp_states_dir'],
          temp_pillar_dir=args['temp_pillar_dir'],
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
        test_db_tables(args)
    elif args['show_changes']:
      show_changes(args)