#/bin/bash

# Test
export TEST_NAME="nuttcp"

# Constants
SERVER_IP=127.0.0.1
CLIENT_IP=192.168.0.10

# Variables
success=0
nuttcp=0
injection_bitrate=(100 500 1000 2000 3000 10000 0)
packet_burst=(5 10 20 50 100 200)
message_size=(1472 8972)
export TEST_DURATION=10
export TESTS=2

part_bitrate_tcp=0
total_bitrate_tcp=0
avg_bitrate_tcp=0

part_retransmisssions_tcp=0
total_retransmissions_tcp=0
avg_retransmissions_tcp=0

part_latency_tcp=0
total_latency_tcp=0
avg_latency_tcp=0

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

if [ -f "../results/${TEST_NAME}/tcp-retransmissions.txt" ]; then
	rm ../results/${TEST_NAME}/tcp-retransmissions.txt
fi

if [ -f "../results/${TEST_NAME}/tcp-latency.txt" ]; then
	rm ../results/${TEST_NAME}/tcp-latency.txt
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
nuttcp -i1 -T 1 $SERVER_IP > /dev/null 2>&1 && nuttcp=1

if [ $success -eq 1 ] && [ $nuttcp -eq 1 ]
then

#	: <<'END'
  # We run the TCP netperf test 
  echo "----------------"
	echo "| TCP - NUTTCP |"
	echo "----------------"

	for i in $(seq 1 $TESTS); do
    # We save the output as a log file and extract the last line to get the results
    echo "nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP" >> ../logs/${TEST_NAME}/tcp-log.txt
    nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP >> ../logs/${TEST_NAME}/tcp-log.txt
    nuttcp_result_tcp=$(tail -1 ../logs/${TEST_NAME}/tcp-log.txt)
    echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/tcp-log.txt
    echo "" >> ../logs/${TEST_NAME}/tcp-log.txt

		# Throughput for TCP
		part_bitrate_tcp=$(echo $nuttcp_result_tcp | awk '{print $7}')
    units_bitrate_tcp=$(echo $nuttcp_result_tcp | awk '{print $8}')
		total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)

    # Retransmissions for TCP
		part_retransmissions_tcp=$(echo $nuttcp_result_tcp | awk '{print $13}')
		total_retransmissions_tcp=$(echo $total_retransmissions_tcp + $part_retransmissions_tcp | bc)

    # RTT for TCP
		part_latency_tcp=$(echo $nuttcp_result_tcp | awk '{print $15}')
    units_latency_tcp=$(echo $nuttcp_result_tcp | awk '{print $16}')
		total_latency_tcp=$(echo $total_latency_tcp + $part_latency_tcp | bc)

		echo -n "$part_bitrate_tcp " >> ../results/${TEST_NAME}/box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "TCP" >> ../results/${TEST_NAME}/box-plot.txt
		fi
	done

	
	# We calculate the average throughput for TCP
	avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
	echo "NUTTCP - The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp $units_bitrate_tcp"
	echo "throughput $avg_bitrate_tcp" >> ../results/${TEST_NAME}/tcp-throughput.txt

  # We calculate the average retransmissions for TCP
	avg_retransmissions_tcp=$(echo "scale=3; $total_retransmissions_tcp / $TESTS" | bc -l)
	echo "NUTTCP - The average retransmissions for TCP in $TESTS runs is $avg_retransmissions_tcp"
	echo "retransmissions $avg_retransmissions_tcp" >> ../results/${TEST_NAME}/tcp-retransmissions.txt

  # We calculate the average latency for TCP
	avg_latency_tcp=$(echo "scale=3; $total_latency_tcp / $TESTS" | bc -l)
	echo "NUTTCP - The average latency for TCP in $TESTS runs is $avg_latency_tcp $units_latency_tcp"
	echo "latency $avg_latency_tcp" >> ../results/${TEST_NAME}/tcp-latency.txt

	total_bitrate_tcp=0
  total_retransmissions_tcp=0
  total_latency_tcp=0

  # We run the UDP netperf test 
  echo "----------------"
	echo "| UDP - NUTTCP |"
	echo "----------------"

  # We calculate the average UDP throughput for different message sizes, injection bitrates and packet bursts
  for size in "${message_size[@]}"; do
    echo "Message size set to $size"
    echo "Message size set to $size" >> ../logs/${TEST_NAME}/udp-log.txt
    for bitrate in "${injection_bitrate[@]}"; do
      echo "Injection bitrate set to $bitrate"
      echo "Injection bitrate set to $bitrate" >> ../logs/${TEST_NAME}/udp-log.txt
      for burst in "${packet_burst[@]}"; do
        echo "Packet burst set to $burst"
        echo "Packet burst set to $burst" >> ../logs/${TEST_NAME}/udp-log.txt
        echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log.txt
        for i in $(seq 1 $TESTS); do
          echo "RUN: $i - MSG SIZE: $size - INJ BITRATE: $bitrate - PKT BURST: $burst"
          echo "RUN: $i - MSG SIZE: $size - INJ BITRATE: $bitrate - PKT BURST: $burst" >> ../logs/${TEST_NAME}/udp-log.txt

          # We save the output as a log file and extract the last line to get the results
          echo "nuttcp -u -l${size} -Ri${bitrate}/${burst} -i 1 -T ${TEST_DURATION} ${SERVER_IP}" >> ../logs/${TEST_NAME}/udp-log.txt
          nuttcp -u -l${size} -Ri${bitrate}/${burst} -i 1 -T ${TEST_DURATION} ${SERVER_IP} >> ../logs/${TEST_NAME}/udp-log.txt
          nuttcp_result_udp=$(tail -1 ../logs/${TEST_NAME}/udp-log.txt)

          echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log.txt
          echo "" >> ../logs/${TEST_NAME}/udp-log.txt

          # UDP throughput
          part_bitrate_udp=$(echo $nuttcp_result_udp | awk '{print $7}')
          units_bitrate_udp=$(echo $nuttcp_result_udp | awk '{print $8}')
          total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

          # UDP errors
          part_loss_udp=$(echo $nuttcp_result_udp | awk '{print $17}')
          part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
          total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)
        done
        # We calculate the average throughput for UDP 
        avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
        echo "NUTTCP - The average throughput for UDP in $TESTS runs, message size of $size MB, injection bitrate of $bitrate Mbps and a packet burst of $burst packets is $avg_bitrate_udp $units_bitrate_udp"
        echo "$size $avg_bitrate_udp" >> ../results/${TEST_NAME}/udp-throughput.txt

        # We calculate the average errors for UDP 
        avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
        echo "NUTTCP - The average errors for UDP in $TESTS runs, message size of $size MB, injection bitrate of $bitrate Mbps and a packet burst of $burst packets is $avg_loss_udp %"
        echo "$size $bitrate $burst $avg_loss_udp" >> ../results/${TEST_NAME}/udp-error.txt
        echo ""

        total_bitrate_udp=0
        part_bitrate_udp=0
        avg_bitrate_udp=0

        total_loss_udp=0
        part_loss_udp=0
        avg_loss_udp=0
      done
    done
	done

else
	echo "---------------------------------"
	echo "El servidor nuttcp no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'nuttcp -S' en el servidor y asegurese de que hay conexion con ping"
	echo ""
fi

