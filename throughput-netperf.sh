#!/bin/bash

# Test
export TEST_NAME="netperf"

# Constants
SERVER_IP=127.0.0.1
CLIENT_IP=192.168.0.10

# Variables
success=0
nperf=0
message_size=(512 1024 2048 4096 8192 16384)
export TEST_DURATION=10
export TESTS=10

part_bitrate_tcp=0
total_bitrate_tcp=0
avg_bitrate_tcp=0

part_bitrate_udp=0
total_bitrate_udp=0
avg_bitrate_udp=0

part_loss_udp=0
total_loss_udp=0
avg_loss_udp=0

# We create results directory if it doesn't exist
if [ ! -d "../results/${TEST_NAME}" ]; then
	mkdir -p ../results/${TEST_NAME}
fi

# We create logs directory if it doesn't exist
if [ ! -d "../logs/${TEST_NAME}" ]; then
	mkdir -p ../logs/${TEST_NAME}
fi


# We delete previous result files
if [ -f "../results/${TEST_NAME}/tcp-throughput.txt" ]; then
	rm ../results/${TEST_NAME}/tcp-throughput.txt
fi

if [ -f "../results/${TEST_NAME}/udp-throughput.txt" ]; then
	rm ../results/${TEST_NAME}/udp-throughput.txt
fi

if [ -f "../results/${TEST_NAME}/udp-error.txt" ]; then
	rm ../results/${TEST_NAME}/udp-error.txt
fi

if [ -f "../results/${TEST_NAME}/box-plot.txt" ]; then
	rm ../results/${TEST_NAME}/box-plot.txt
fi

# We delete previous log files
if [ -f "../logs/${TEST_NAME}/tcp-log.txt" ]; then
	rm ../logs/${TEST_NAME}/tcp-log.txt
fi

if [ -f "../logs/${TEST_NAME}/udp-log.txt" ]; then
	rm ../logs/${TEST_NAME}/udp-log.txt
fi

# We check that there is connectivity with the server
ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1
netperf -H $SERVER_IP -l 1 -t TCP_STREAM > /dev/null 2>&1 && nperf=1

if [ $success -eq 1 ] && [ $nperf -eq 1 ]
then

#	: <<'END'
  # We run the TCP netperf test 
  echo "-----------------"
	echo "| TCP - NETPERF |"
	echo "-----------------"

	for i in $(seq 1 $TESTS); do
    # We save the output as a log file and extract the last line to get the results
    netperf -H $SERVER_IP -l ${TEST_DURATION} -t TCP_STREAM -f m >> ../logs/${TEST_NAME}/tcp-log.txt
    netperf_result_tcp=$(tail -1 ../logs/${TEST_NAME}/tcp-log.txt)

		# Throughput for TCP
		part_bitrate_tcp=$(echo $netperf_result_tcp | awk '{print $5}')
		total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)

		echo -n "$part_bitrate_tcp " >> ../results/${TEST_NAME}/box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "TCP" >> ../results/${TEST_NAME}/box-plot.txt
		fi
	done

	
	# We calculate the average throughput for TCP
	avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
	echo "NETPERF - The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp Mbps"
	echo "bitrate $avg_bitrate_tcp" >> ../results/${TEST_NAME}/tcp-throughput.txt

	total_bitrate_tcp=0

  # We run the UDP netperf test 
  echo "-----------------"
	echo "| UDP - NETPERF |"
	echo "-----------------"

  # We calculate the average UDP throughput for different message sizes 
  for size in "${message_size[@]}"; do
	  for i in $(seq 1 $TESTS); do
      echo "RUN = $i"
      # We save the output as a log file and extract the last line to get the results
      netperf -H ${SERVER_IP} -t UDP_STREAM -l ${TEST_DURATION} -- -m ${size} -- -f m >> ../logs/${TEST_NAME}/udp-log.txt
      netperf_result_udp=$(tail -3 ../logs/${TEST_NAME}/udp-log.txt | head -1)

      # Throughput for UDP
      part_bitrate_udp=$(echo $netperf_result_udp | awk '{print $6}')
      total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

      # Errors for UDP
      part_loss_udp=$(echo $netperf_result_udp | awk '{print $5}')
      total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)
    done

	  # We calculate the average throughput for UDP 
	  avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	  echo "NETPERF - The average throughput for UDP in $TESTS runs and message size of $size is $avg_bitrate_udp Mbps"
	  echo "$size $avg_bitrate_udp" >> ../results/${TEST_NAME}/udp-throughput.txt

    # We calculate the average errors for UDP 
	  avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	  echo "NETPERF - The average errors for UDP in $TESTS runs and message size of $size is $avg_loss_udp"
	  echo "$size $avg_loss_udp" >> ../results/${TEST_NAME}/udp-error.txt

    total_bitrate_udp=0
    part_bitrate_udp=0
    avg_bitrate_udp=0

    total_loss_udp=0
    part_loss_udp=0
    avg_loss_udp=0


	done

else
	echo "---------------------------------"
	echo "El servidor netperf no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'netperf' en el servidor y asegurese de que hay conexion con ping"
	echo ""
fi

