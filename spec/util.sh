#!/bin/bash

## JJM Variables for exit codes
## NOTE: There is a distinction between test failure
## and an error running the test.  Make sure to
## exit $EXIT_FAILURE if the test failed.  Other non-
## zero exit codes will be interpreted as an error
## running the script.
EXIT_FAILURE=10
EXIT_NOT_APPLICABLE=11
EXIT_OK=0
EXIT_ERROR=1

# JJM Raise an error when unbound variables are used.
set -u

# JJM Start the puppet agent against port 18140
start_puppet_agent() {
  local master_port=${MASTER_PORT:=18140}
  puppet agent --vardir /tmp/puppet-$$-agent-var \
    --confdir /tmp/puppet-$$-agent \
    --rundir /tmp/puppet-$$-agent \
    --test --debug \
    --server localhost \
    --masterport ${master_port} "$@"
  return $?
}

start_puppet_master() {
  local master_port=${MASTER_PORT:=18140}
  mkdir -p /tmp/puppet-$$-master/manifests/
  puppet master --vardir \
    /tmp/puppet-$$-master-var \
    --confdir /tmp/puppet-$$-master \
    --rundir /tmp/puppet-$$-master \
    --no-daemonize --autosign=true \
    --certname=localhost \
    --masterport ${master_port} $@ &
  local master_pid=$!
  # JJM Set the master PID available outside
  MASTER_PID=${master_pid}

  # Watch for the puppet master port to come online
  for x in $(seq 0 10); do
    rval=2
    if (lsof -i -n -P|grep '\*:'${master_port}|grep -q ${master_pid})
    then
      rval=${EXIT_OK}
      break
    else
      sleep 1
    fi
  done
  return ${rval}
}

# JJM Stop the puppet master.  Expects ${MASTER_PID}
stop_puppet_master() {
  echo "Killing puppet master PID: ${MASTER_PID}"
  kill -TERM ${MASTER_PID}
}

start_puppetd() {
  local master_port=${MASTER_PORT:=18140}
  puppetd --vardir /tmp/puppet-$$-agent-var \
    --confdir /tmp/puppet-$$-agent \
    --rundir /tmp/puppet-$$-agent \
    --test --debug \
    --server localhost --masterport ${master_port} "$@"
}

# JJM This function takes a PID and PORT and waits until
# that process is listening on that port.
# example: wait_until_master_is_listening 3000 18140
wait_until_master_is_listening() {
  local pid=${1}
  local port=${2:-18140}
  # JJM Wait for puppet master to start and open up the TCP port.
  for i in $(seq 0 20); do
    ( lsof -i -n -P |\
      awk 'BEGIN {r=1} $2 ~ /'${pid}'/ && $8 ~ /'${pid}'/ {r=0} END {exit r}')\
      && break || sleep 1
  done
  # JJM TODO: Add a return code if the time expires.
}

start_puppetmasterd() {
  local master_port=${MASTER_PORT:=18140}
  mkdir -p /tmp/puppet-$$-master/manifests
  puppetmasterd \
    --vardir /tmp/puppet-$$-master-var \
    --confdir /tmp/puppet-$$-master \
    --rundir /tmp/puppet-$$-master \
    --no-daemonize --autosign=true \
    --certname=localhost --masterport ${master_port} "$@" &
  MASTER_PID=$!
  echo "puppet master started with PID: ${MASTER_PID}"

  # JJM Wait for puppet master to start and open up the TCP port.
  for i in $(seq 0 10); do
    if lsof -i -n -P | grep '\*:'${master_port} | grep -q $MASTER_PID
    then
      break
    else
      sleep 1
    fi
  done
}

stop_puppetmasterd() {
  echo "Killing puppetmasterd PID: ${MASTER_PID}"
  kill -TERM $MASTER_PID
}

NOT_APPLICABLE() {
  exit $EXIT_NOT_APPLICABLE
}

killwait() {
  local pid=${1}
  if [ -z "${pid}" ]; then
    echo "Must pass a pid to kill"
    return 2
  fi
  kill -TERM ${pid}
  for i in $(seq 0 10) ; do
    test -d /proc/${pid} || return 0
    sleep 1
  done
  return 1
}
#
