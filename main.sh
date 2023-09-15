#!/bin/bash

# Constants
export USERNAME="antonio"
export HOST_A=161.67.133.94
export HOST_B=161.67.133.93
export SWITCH=161.67.133.92
export SERVER_IP=192.168.0.20
export CLIENT_IP=192.168.0.10
export TESTS=1
export TEST_DURATION=10

# Variables shared among different bash scripts
success=0
export injection_bitrate=(100 500 1000 2000 3000 10000 0)
export message_size=(1472 8972)

export part_transfer_tcp=0
export total_transfer_tcp=0
export avg_transfer_tcp=0
 
export part_retransmissions_tcp=0
export total_retransmissions_tcp=0
export avg_retransmissions_tcp=0
 
export part_transfer_udp=0
export total_transfer_udp=0
export avg_transfer_udp=0
 
export part_bitrate_tcp=0
export total_bitrate_tcp=0
export avg_bitrate_tcp=0
export part_bitrate_udp=0
export total_bitrate_udp=0
export avg_bitrate_udp=0
 
export part_jitter_udp=0
export total_jitter_udp=0
export avg_jitter_udp=0
 
export part_loss_udp=0
export total_loss_udp=0
export avg_loss_udp=0

# We check that there is connectivity with the server
ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1

if [ $success -eq 1 ] 
then

  # We ask the user which test they want to perform
  #echo "Hello user, it looks like there is connectivity with the host..."
  #echo "Now I will ask you which tests you want to run"
  #echo "----------------------------------------------"
  #echo "Do you want to run iperf3 tests? (1=yes | 0=no)"
  #read test_iperf3
  #echo "Do you want to run netperf tests? (1=yes | 0=no)"
  #read test_netperf
  #echo "Do you want to run nuttcp tests? (1=yes | 0=no)"
  #read test_nuttcp

  # Default values
  test_iperf3=1
  test_netperf=1
  test_nuttcp=1

  if [ $test_iperf3 -eq 1 ]; then
      ssh -i /home/antonio/.ssh/id_ed25519 ${USERNAME}@${HOST_B} "iperf3 -s -B ${SERVER_IP} &"
      ./throughput-iperf3.sh
  fi

  if [ $test_netperf -eq 1 ]; then
      ssh ${USERNAME}@${HOST_B} "netserver"
      ./throughput-netperf.sh
  fi

  if [ $test_nuttcp -eq 1 ]; then
      ssh ${USERNAME}@${HOST_B} "nuttcp -S"
      ./throughput-nuttcp.sh
  fi

else
	echo "----------------------------------------------"
	echo "| ! There is no connectivity with the server |"
	echo "----------------------------------------------"
	echo ""
	echo "* Check ping against the server is successfull"
	echo ""
fi

