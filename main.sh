#!/bin/bash

source settings.sh

# We check that there is connectivity with the server
ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1

# There is connectivity between the hosts
if [ $success -eq 1 ]; then
  # Default values
  test_iperf3=1
  test_netperf=1
  test_nuttcp=1

  # We ask the user which tests they want to perform
  echo "Hello user, it looks like there is connectivity with the host..."
  echo "Now I will ask you which tests you want to run"
  echo "----------------------------------------------"

  # iperf3
  echo "Do you want to run iperf3 tests? (1=yes | 0=no)"
  read -t 10 -p "Enter your input: " test_iperf3
  # netperf
  echo "Do you want to run netperf tests? (1=yes | 0=no)"
  read -t 10 -p "Enter your input: " test_netperf
  # nuttcp
  echo "Do you want to run nuttcp tests? (1=yes | 0=no)"
  read -t 10 -p "Enter your input: " test_nuttcp

  # iperf3
  if [ $test_iperf3 -eq 1 ]; then
      # Launch the iperf3 server in the prototype
      ssh -i /home/antonio/.ssh/id_ed25519 ${USERNAME}@${HOST_B} "iperf3 -s -B ${SERVER_IP} &"
      ./throughput-iperf3.sh
  fi

  # netperf
  if [ $test_netperf -eq 1 ]; then
      # Launch the netperf server in the prototype
      ssh -i /home/antonio/.ssh/id_ed25519 ${USERNAME}@${HOST_B} "netserver"
      ./throughput-netperf.sh
  fi

  # nuttcp
  if [ $test_nuttcp -eq 1 ]; then
      # Launch the nuttcp server in the prototype
      ssh -i /home/antonio/.ssh/id_ed25519 ${USERNAME}@${HOST_B} "nuttcp -S"
      ./throughput-nuttcp.sh
  fi

# No connectivity
else
	echo "----------------------------------------------"
	echo "| ! There is no connectivity with the server |"
	echo "----------------------------------------------"
	echo ""
	echo "* Check ping against the server is successfull"
	echo ""
fi
