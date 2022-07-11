#! /usr/bin/python3

"""
This python script will test following:
* Try ping test for all IP addresses in ping_list
* If ping fails, retry up to 3 times.
* Write PASS/FAIL to result file.
"""
import sys
import time
import re
import os
import getopt
import subprocess

def main(argv):
  result = 'PASS'
  ping_list = ''
  if len(argv) == 0:
    print('usage: PROG [-h] --ping_list <list_of_ip_addresses>')
    sys.exit(2)
  try:
    opts, args = getopt.getopt(argv,'h',['ping_list='])
  except getopt.GetoptError:
    print('usage: PROG [-h] --ping_list <list_of_ip_addresses>')
    sys.exit(2)
  for opt, arg in opts:
    if opt == '-h':
      print('usage: PROG [-h] --ping_list <list_of_ip_addresses>')
      sys.exit()
    elif opt in ('',"--ping_list"):
        ping_list = arg.split(",")

  i = 0
  num_of_tries = 0
  f = open('/tmp/log.txt','w')

  '''
    Try ping test for each IP.
    If ping fails, it will re-try up to 3 times.
  '''
  while i < len(ping_list):
    cmd = 'ping -c 3 ' + ping_list[i]
    f.write(subprocess.getoutput('date')+'  :Trying to execute cmd ...\n')
    output = subprocess.getoutput(cmd)
    f.write(subprocess.getoutput('date')+'  :Successfully executed cmd ...\n')
    m = re.search('3 received',output)
    if m:
      i += 1
      num_of_tries = 0
      f.write('###################### Below Test Passes #####################\n')
      f.write('Test Passes for cmd >>>>> '+cmd+'\n')
      f.write('##############################################################\n')
    elif num_of_tries < 3:
      num_of_tries += 1
      f.write('####################### Traffic Failed #######################\n')
      f.write('Executed cmd >>>>> '+cmd+'\n')
      f.write('Number of Tries: '+str(num_of_tries)+'\n')
      f.write(subprocess.getoutput('date')+'  :Will try again. Sleeping now ...\n')
      time.sleep(num_of_tries*30)
    else:
      result = 'FAIL'
      i += 1
      num_of_tries = 0
      f.write('################ Test Failed after 3 re-tries ################\n')
      f.write('Executed cmd >>>>> '+cmd+'\n')
      f.write('Output : \n')
      f.write(output)
      f.write('\n')
      f.write('##############################################################\n')
  f.close()

  with open('/tmp/result.txt','w') as result_file:
    result_file.write(result+'\n')

if __name__ == "__main__":
  main(sys.argv[1:])
