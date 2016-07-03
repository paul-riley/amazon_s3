#!/bin/bash

TESTS=(
"centos7.0"
"ubuntu12.04"
"ubuntu14.04"
"ubuntu15.04"
)
OUT="results.txt"

rm $OUT

function cleanup {
    vagrant destroy -f
}

function test_os {
  echo "require './config/${1}'" > config/testos.rb
}

# Provisions the vm and runs the provisioner
function run_test {
    scripts/run.bash
    if [ $? -eq 1 ] ; then
        echo "${1} - failed test 0" results.txt
        echo "${1} - failed test 0" >> results.txt
    fi
}

# Tests the provision (ie runs the provisioner the 2nd time)
function provision_test {
    scripts/provision.bash
    if [ $? -eq 0 ] ; then
        echo "${1} - passed"
        echo "${1} - passed" >> results.txt
    else
        echo "${1} - failed"
        echo "${1} - failed" >> results.txt
    fi
}

for i in "${TESTS[@]}"
do
    test_os $i
    run_test $i
    provision_test $i
    cleanup
done
