#/bin/bash

# Test
export TEST_NAME="nuttcp"

# Constants
#SERVER_IP=192.168.0.20
#CLIENT_IP=192.168.0.10

# Variables
success=0
nuttcp=0
injection_bitrate=(100 500 1000 2000 3000 10000 0)
packet_burst=(5 10 20 50 100 200)
message_size=(1448 8972)
buffer_size=(212992 157286400)
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


# We check that there is connectivity with the server
#ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1
nuttcp -i1 -T 1 $SERVER_IP > /dev/null 2>&1 && nuttcp=1

if [ $nuttcp -eq 1 ]
then

for buffer in "${buffer_size[@]}"; do
	
	# We delete previous result files
	if [ -f "../results/${TEST_NAME}/tcp-throughput-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/tcp-latency-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-latency-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/udp-throughput-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/udp-throughput-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/udp-error-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/udp-error-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/box-plot-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/box-plot-${buffer}.txt
	fi

	# We delete previous log files
	if [ -f "../logs/${TEST_NAME}/tcp-log-${buffer}.txt" ]; then
		rm ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
	fi

	if [ -f "../logs/${TEST_NAME}/udp-log-${buffer}.txt" ]; then
		rm ../logs/${TEST_NAME}/udp-log-${buffer}.txt
	fi

	rb_default="net.core.rmem_default"
	rb_max="net.core.rmem_max"

	wb_default="net.core.wmem_default"
	wb_max="net.core.wmem_max"

	sysctl -w "$rb_default"=$buffer
	sysctl -w "$rb_max"=$buffer

	sysctl -w "$wb_default"=$buffer
	sysctl -w "$wb_max"=$buffer

	rmem_default=$(sysctl net.core.rmem_default)
	rmem_max=$(sysctl net.core.rmem_max)

	wmem_default=$(sysctl net.core.wmem_default)
	wmem_max=$(sysctl net.core.wmem_max)
	
	echo "Kernel buffer size set to $rmem_default"



#	: <<'END'
  # We run the TCP netperf test 
  echo "----------------"
	echo "| TCP - NUTTCP |"
	echo "----------------"

	for i in $(seq 1 $TESTS); do
    # We save the output as a log file and extract the last line to get the results
    echo "nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP" >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
    nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
    nuttcp_result_tcp=$(tail -1 ../logs/${TEST_NAME}/tcp-log-${buffer}.txt)
    echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
    echo "" >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt

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

		echo -n "$part_bitrate_tcp " >> ../results/${TEST_NAME}/box-plot-${buffer}.txt

		if [ $i -eq $TESTS ]; then
			echo "TCP" >> ../results/${TEST_NAME}/box-plot-${buffer}.txt
		fi
	done

	
	# We calculate the average throughput for TCP
	avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
	echo "NUTTCP - The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp $units_bitrate_tcp"
	echo "throughput $avg_bitrate_tcp" >> ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt

  # We calculate the average retransmissions for TCP
	avg_retransmissions_tcp=$(echo "scale=3; $total_retransmissions_tcp / $TESTS" | bc -l)
	echo "NUTTCP - The average retransmissions for TCP in $TESTS runs is $avg_retransmissions_tcp"
	echo "retransmissions $avg_retransmissions_tcp" >> ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt

  # We calculate the average latency for TCP
	avg_latency_tcp=$(echo "scale=3; $total_latency_tcp / $TESTS" | bc -l)
	echo "NUTTCP - The average latency for TCP in $TESTS runs is $avg_latency_tcp $units_latency_tcp"
	echo "latency $avg_latency_tcp" >> ../results/${TEST_NAME}/tcp-latency-${buffer}.txt

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
    echo "Message size set to $size" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
    for bitrate in "${injection_bitrate[@]}"; do
      echo "Injection bitrate set to $bitrate"
      echo "Injection bitrate set to $bitrate" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
      for burst in "${packet_burst[@]}"; do
        echo "Packet burst set to $burst"
        echo "Packet burst set to $burst" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
        echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
        echo "MSG SIZE: $size - INJ BITRATE: $bitrate - PKT BURST: $burst - BUFFER SIZE: $rmem_default" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt
        echo "MSG SIZE: $size - INJ BITRATE: $bitrate - PKT BURST: $burst - BUFFER SIZE: $rmem_default" >> ../results/${TEST_NAME}/udp-error-${buffer}.txt
        for i in $(seq 1 $TESTS); do
          echo "RUN: $i - MSG SIZE: $size - INJ BITRATE: $bitrate - PKT BURST: $burst - BUFFER SIZE: $rmem_default"
          echo "RUN: $i - MSG SIZE: $size - INJ BITRATE: $bitrate - PKT BURST: $burst - BUFFER SIZE: $rmem_default" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

          # We save the output as a log file and extract the last line to get the results
          echo "nuttcp -u -l${size} -Ri${bitrate}/${burst} -i 1 -T ${TEST_DURATION} ${SERVER_IP}" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
          nuttcp -u -l${size} -Ri${bitrate}/${burst} -i 1 -T ${TEST_DURATION} ${SERVER_IP} >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
          nuttcp_result_udp=$(tail -1 ../logs/${TEST_NAME}/udp-log-${buffer}.txt)

          echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
          echo "" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

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
        echo "$size $avg_bitrate_udp" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt

        # We calculate the average errors for UDP 
        avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
        echo "NUTTCP - The average errors for UDP in $TESTS runs, message size of $size MB, injection bitrate of $bitrate Mbps and a packet burst of $burst packets is $avg_loss_udp %"
        echo "$size $bitrate $burst $avg_loss_udp" >> ../results/${TEST_NAME}/udp-error-${buffer}.txt
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
done

else
	echo "---------------------------------"
	echo "El servidor nuttcp no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'nuttcp -S' en el servidor y asegurese de que hay conexion con ping"
	echo ""
fi

