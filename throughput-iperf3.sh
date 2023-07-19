#!/bin/bash

# Constants
export TEST_NAME=iperf3
injection_bitrate=(100 500 1000 2000 3000 10000 0)
packet_burst=(5 10 20 50 100 200)
message_size=(1472 8972)

# Variables specific to this bash script
ip3=0

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

if [ -f "../results/${TEST_NAME}/udp-transfer.txt" ]; then
	rm ../results/${TEST_NAME}/udp-transfer.txt
fi


if [ -f "../results/${TEST_NAME}/udp-throughput.txt" ]; then
	rm ../results/${TEST_NAME}/udp-throughput.txt
fi

if [ -f "../results/${TEST_NAME}/udp-jitter.txt" ]; then
	rm ../results/${TEST_NAME}/udp-jitter.txt
fi

if [ -f "../results/${TEST_NAME}/udp-loss.txt" ]; then
	rm ../results/${TEST_NAME}/udp-loss.txt
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


# We check that the server is running iperf3
iperf3 -c $SERVER_IP -B $CLIENT_IP -t 1 > /dev/null 2>&1 && ip3=1

if [ $ip3 -eq 1 ]
then

  echo "----------------"
	echo "| TCP - IPERF3 |"
	echo "----------------"
  
  # We run the TCP iperf3 test with the default options
	for i in $(seq 1 $TESTS); do
    
    # We send the output to a log file
    echo "iperf3 -c $SERVER_IP -B $CLIENT_IP -O1 -t${TEST_DURATION} -f m" >> ../logs/${TEST_NAME}/tcp-log.txt
    iperf3 -c $SERVER_IP -B $CLIENT_IP -O1 -t${TEST_DURATION} -f m >> ../logs/${TEST_NAME}/tcp-log.txt
		iperf3_result_tcp=$(tail -4 ../logs/${TEST_NAME}/tcp-log.txt | head -1)
    echo "$iperf3_result_tcp"

		# TCP transfer
		part_transfer_tcp=$(echo $iperf3_result_tcp | awk '{print $5}')
		units_transfer_tcp=$(echo $iperf3_result_tcp | awk '{print $6}')
		total_transfer_tcp=$(echo $total_transfer_tcp + $part_transfer_tcp | bc)

		# TCP bitrate
		part_bitrate_tcp=$(echo $iperf3_result_tcp | awk '{print $7}')
		units_bitrate_tcp=$(echo $iperf3_result_tcp | awk '{print $8}')
		total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)
		
		# TCP retransmissions
		part_retransmissions_tcp=$(echo $iperf3_result_tcp | awk '{print $9}')
		total_retransmissions_tcp=$(echo $total_retransmissions_tcp + $part_retransmissions_tcp | bc)

    # We add data to the boxplot text file
		echo -n "$part_bitrate_tcp " >> ../results/${TEST_NAME}/box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "TCP" >> ../results/${TEST_NAME}/box-plot.txt
		fi
	done

	# We calculate the average transfered bytes for TCP
	echo "---------------------"
	echo "TCP - DEFAULT OPTIONS"
	echo "---------------------"
	avg_transfer_tcp=$(echo "scale=3; $total_transfer_tcp / $TESTS" | bc -l)
	echo "The average transfer for TCP in $TESTS runs is $avg_transfer_tcp $units_transfer_tcp"
	echo "transfer $avg_transfer_tcp" >> ../results/${TEST_NAME}/tcp-throughput.txt

	# We calculate the average bitrate for TCP
	avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
	echo "The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp $units_bitrate_tcp"
	echo "bitrate $avg_bitrate_tcp" >> ../results/${TEST_NAME}/tcp-throughput.txt

	# We calculate the average bitrate for TCP
	avg_retransmissions_tcp=$(echo "scale=3; $total_retransmissions_tcp / $TESTS" | bc -l)
	echo "The average retransmissions for TCP in $TESTS runs is $avg_retransmissions_tcp"
	echo "retransmissions $avg_retransmissions_tcp" >> ../results/${TEST_NAME}/tcp-throughput.txt

	total_transfer_tcp=0
	total_bitrate_tcp=0
	total_retransmissions_tcp=0


  echo "----------------"
	echo "| UDP - IPERF3 |"
	echo "----------------"
  
  # We run the UDP iperf3 varying the injection bitrate
  for bitrate in "${injection_bitrate[@]}"; do 
    for i in $(seq 1 $TESTS); do
      echo "RUN: $i - INJ BITRATE: $bitrate"
      echo "RUN: $i - INJ BITRATE: $bitrate" >> ../logs/${TEST_NAME}/udp-log.txt

      # We save the output as a log file
      echo "iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b${bitrate}M -O1 -t${TEST_DURATION}" >> ../logs/${TEST_NAME}/udp-log.txt
      iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b${bitrate}M -O1 -t${TEST_DURATION} >> ../logs/${TEST_NAME}/udp-log.txt

      # We get the relevant line from the output
      iperf3_result_udp=$(tail -4 ../logs/${TEST_NAME}/udp-log.txt | head -1)

      # UDP transfer
      part_transfer_udp=$(echo $iperf3_result_udp | awk '{print $5}')
      units_transfer_udp=$(echo $iperf3_result_udp | awk '{print $6}')
      total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

      # UDP bitrate
      part_bitrate_udp=$(echo $iperf3_result_udp | awk '{print $7}')
      units_bitrate_udp=$(echo $iperf3_result_udp | awk '{print $8}')
      total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

      # UDP jitter
      part_jitter_udp=$(echo $iperf3_result_udp | awk '{print $9}')
      units_jitter_udp=$(echo $iperf3_result_udp | awk '{print $10}')
      total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

      # UDP datagram loss
      part_loss_udp=$(echo $iperf3_result_udp | awk '{print $12}')
      part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
      total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

    done

    # We calculate the average UDP transfer
    avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
    echo "The average transfer for UDP in $TESTS runs and injection bitrate of $bitrate Mbps is $avg_transfer_udp $units_transfer_udp"
    echo "$size $avg_transfer_udp" >> ../results/${TEST_NAME}/udp-transfer.txt

    # We calculate the average UDP bitrate 
    avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
    echo "The average bitrate for UDP in $TESTS runs and injection bitrate of $bitrate is $avg_bitrate_udp $units_bitratre_udp"
    echo "$size $avg_bitrate_udp" >> ../results/${TEST_NAME}/udp-throughput.txt

    # We calculate the average UDP jitter
    avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
    echo "The average jitter for UDP in $TESTS runs and injection bitrate of $bitrate is $avg_jitter_udp $units_jitter_udp"
    echo "$size $avg_jitter_udp" >> ../results/${TEST_NAME}/udp-jitter.txt

    # We calculate the average UDP datagram loss
    avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
    echo "The average datagram loss for UDP in $TESTS runs and injection bitrate of $bitrate is $avg_loss_udp %"
    echo "$size $avg_loss_udp" >> ../results/${TEST_NAME}/udp-loss.txt

    total_transfer_udp=0
    total_bitrate_udp=0
    total_jitter_udp=0
    part_loss_udp=0
    total_loss_udp=0
  done

else
	echo "---------------------------------"
	echo "El servidor iperf3 no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'iperf3 -s -B <SERVER_IP>' en el servidor"
	echo ""
fi

