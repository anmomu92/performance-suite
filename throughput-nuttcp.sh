#/bin/bash

# Test
export TEST_NAME="nuttcp"

# Variables
nuttcp=0
injection_bitrate=(100 500 1000 2000 3000 10000 0)
packet_burst=(5 10 20 50 100 200)
message_size=(1448 8972)
buffer_size=(106496 212992 524288 1048576 52428800 157286400) # 104KB 208KB 512KB 1MB 50MB  150MB

# We create results directory if it doesn't exist
if [ ! -d "../results/${TEST_NAME}" ]; then
	mkdir -p ../results/${TEST_NAME}
fi

# We create logs directory if it doesn't exist
if [ ! -d "../logs/${TEST_NAME}" ]; then
	mkdir -p ../logs/${TEST_NAME}
fi

# We show the test name
echo "----------------------------------------------------------  NUTTCP ----------------------------------------------------------"

# We check that there is connectivity with the server
#ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1
nuttcp -i1 -T 1 $SERVER_IP > /dev/null 2>&1 && nuttcp=1

if [ $nuttcp -eq 1 ]
then

for buffer in "${buffer_size[@]}"; do
	
	# We delete previous result files
	if [ -f "../results/${TEST_NAME}/tcp-transfer-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-transfer-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/tcp-throughput-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/tcp-latency-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-latency-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/udp-transfer-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/udp-transfer-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/udp-throughput-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/udp-throughput-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/udp-error-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/udp-error-${buffer}.txt
	fi

	if [ -f "../results/${TEST_NAME}/tcp-box-plot-${buffer}.txt" ]; then
		rm ../results/${TEST_NAME}/tcp-box-plot-${buffer}.txt
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

	echo ""
	echo "Kernel buffer size set to $buffer B"

#	: <<'END'
  	# We run the TCP nuttcp test 
	echo ""
  	echo "----------------------------------------"
	echo "| TCP - NUTTCP - BUFFER SIZE: $buffer B |"
	echo "----------------------------------------"

	# We initialize the variables
	total_latency_tcp=0
	total_bitrate_tcp=0
  	total_retransmissions_tcp=0

	for i in $(seq 1 $TESTS); do
	    # We save the output as a log file and extract the last line to get the results
	    echo "nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP" >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
	    nuttcp -i1 -T ${TEST_DURATION} $SERVER_IP >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
	    nuttcp_result_tcp=$(tail -1 ../logs/${TEST_NAME}/tcp-log-${buffer}.txt)
	    echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
	    echo "" >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt

      	    # TCP transfer
      	    part_transfer_tcp=$(echo $nuttcp_result_tcp | awk '{print $1}')
      	    units_transfer_tcp=$(echo $nuttcp_result_tcp | awk '{print $2}')
      	    total_transfer_tcp=$(echo $total_transfer_tcp + $part_transfer_tcp | bc)

	    # Throughput for TCP
	    part_bitrate_tcp=$(echo $nuttcp_result_tcp | awk '{print $7}')
	    units_bitrate_tcp=$(echo $nuttcp_result_tcp | awk '{print $8}')
	    total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)

      	    # We check that, in case of error, no string is passed to the variable
      	    if [[ ! $part_bitrate_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        	part_bitrate_tcp=0
      	    fi

	    # Retransmissions for TCP
	    part_retransmissions_tcp=$(echo $nuttcp_result_tcp | awk '{print $13}')
	    total_retransmissions_tcp=$(echo $total_retransmissions_tcp + $part_retransmissions_tcp | bc)

      	    # We check that, in case of error, no string is passed to the variable
      	    if [[ ! $part_retransmissions_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        	part_retransmissions_tcp=0
      	    fi

    	    # RTT for TCP
	    part_latency_tcp=$(echo $nuttcp_result_tcp | awk '{print $15}')
    	    units_latency_tcp=$(echo $nuttcp_result_tcp | awk '{print $16}')
	    total_latency_tcp=$(echo $total_latency_tcp + $part_latency_tcp | bc)

      	    # We check that, in case of error, no string is passed to the variable
      	    if [[ ! $part_latency_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        	part_latency_tcp=0
      	    fi

	    echo "$part_bitrate_tcp " >> ../results/${TEST_NAME}/tcp-box-plot-${buffer}.txt

            echo "RUN: $i - Partial transfer: $part_transfer_tcp $units_transfer_tcp - Partial throughput: $part_bitrate_tcp $units_bitrate_tcp - Partial retransmissions: $part_retransmissions_tcp - Partial RTT: $part_latency_tcp $units_latency_tcp"
	done
	echo ""
        echo "-----------------------------------------------"

    	# We calculate the average transfered bytes for TCP
    	avg_transfer_tcp=$(echo "scale=3; $total_transfer_tcp / $TESTS" | bc -l)
    	echo "The average transfer for TCP in $TESTS runs is $avg_transfer_tcp $units_transfer_tcp"
        echo "# The average transfer after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-transfer-${buffer}.txt
    	echo "$avg_transfer_tcp" >> ../results/${TEST_NAME}/tcp-transfer-${buffer}.txt
	
	# We calculate the average throughput for TCP
	avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
	echo "The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp $units_bitrate_tcp"
        echo "# The average throughput after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt
	echo "$avg_bitrate_tcp" >> ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt

  	# We calculate the average retransmissions for TCP
	avg_retransmissions_tcp=$(echo "scale=3; $total_retransmissions_tcp / $TESTS" | bc -l)
	echo "The average retransmissions for TCP in $TESTS runs is $avg_retransmissions_tcp"
        echo "# The average number of retransmissions after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt
	echo "$avg_retransmissions_tcp" >> ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt

  	# We calculate the average latency for TCP
	avg_latency_tcp=$(echo "scale=3; $total_latency_tcp / $TESTS" | bc -l)
	echo "The average latency for TCP in $TESTS runs is $avg_latency_tcp $units_latency_tcp"
        echo "# The average latency after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-latency-${buffer}.txt
	echo "$avg_latency_tcp" >> ../results/${TEST_NAME}/tcp-latency-${buffer}.txt


  # We run the UDP nuttcp test 
  echo ""
  echo "----------------------------------------"
  echo "| UDP - NUTTCP - BUFFER SIZE: $buffer B |"
  echo "----------------------------------------"

  # We calculate the average UDP throughput for different message sizes, injection bitrates and packet bursts
  #for size in "${message_size[@]}"; do
  #  echo "Message size set to $size"
  #  echo "Message size set to $size" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
    for bitrate in "${injection_bitrate[@]}"; do

        if [ -f "../results/${TEST_NAME}/udp-box-plot-${buffer}-${bitrate}.txt" ]; then
		rm ../results/${TEST_NAME}/udp-box-plot-${buffer}-${bitrate}.txt
	fi

	echo ""
        echo "Injection bitrate set to $bitrate Mbps"
	echo "-----------------------------------------"
        echo "Injection bitrate set to $bitrate" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

	# THE VERSION INSTALLED IN THE PROTOYPE DOES NOT SUPPORT BURSTS, SO IT IS COMMENTED OUT
        #for burst in "${packet_burst[@]}"; do
        #  echo "Packet burst set to $burst"
        #  echo "Packet burst set to $burst" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
        echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
        echo "INJ BITRATE: $bitrate - BUFFER SIZE: $buffer" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt
        echo "INJ BITRATE: $bitrate - BUFFER SIZE: $buffer" >> ../results/${TEST_NAME}/udp-error-${buffer}.txt

	# We initialize the variables
	total_transfer_udp=0
        total_bitrate_udp=0
        total_loss_udp=0

        for i in $(seq 1 $TESTS); do
          echo "RUN: $i INJ BITRATE: $bitrate BUFFER SIZE: $buffer" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

          # We save the output as a log file and extract the last line to get the results
          echo "nuttcp -u -Ri${bitrate}m -i 1 -T ${TEST_DURATION} ${SERVER_IP}" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
          nuttcp -u -Ri${bitrate}m -i 1 -T ${TEST_DURATION} ${SERVER_IP} >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
          nuttcp_result_udp=$(tail -1 ../logs/${TEST_NAME}/udp-log-${buffer}.txt)

          echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
          echo "" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

          # UDP transfer
          part_transfer_udp=$(echo $nuttcp_result_udp | awk '{print $1}')
          units_transfer_udp=$(echo $nuttcp_result_udp | awk '{print $2}')
          total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

      	  # We check that, in case of error, no string is passed to the variable
      	  if [[ ! $part_transfer_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            part_transfer_udp=0
      	  fi

          # UDP throughput
          part_bitrate_udp=$(echo $nuttcp_result_udp | awk '{print $7}')
          units_bitrate_udp=$(echo $nuttcp_result_udp | awk '{print $8}')
          total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

      	  # We check that, in case of error, no string is passed to the variable
      	  if [[ ! $part_bitrate_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            part_bitrate_udp=0
      	  fi

	  echo "$part_bitrate_udp " >> ../results/${TEST_NAME}/udp-box-plot-${buffer}-${bitrate}.txt

          # UDP errors
          part_loss_udp=$(echo $nuttcp_result_udp | awk '{print $17}')
          part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
          total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

      	  # We check that, in case of error, no string is passed to the variable
      	  if [[ ! $part_loss_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            part_loss_udp=0
      	  fi

          echo "RUN: $i - Partial transfer: $part_transfer_udp $units_transfer_udp - Partial throughput: $part_bitrate_udp $units_bitrate_udp - Partial error: $part_loss_udp"
        done
        echo "-----------------------------------------------"

        # We calculate the average UDP transfer
        avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
        echo "The average transfer for UDP in $TESTS runs and injection bitrate of $bitrate Mbps is $avg_transfer_udp $units_transfer_udp"
        echo "$bitrate $avg_transfer_udp" >> ../results/${TEST_NAME}/udp-transfer-${buffer}.txt

        # We calculate the average throughput for UDP 
        avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
        echo "The average throughput for UDP in $TESTS runs, injection bitrate of $bitrate Mbps and a packet burst of $burst packets is $avg_bitrate_udp $units_bitrate_udp"
        echo "$bitrate $avg_bitrate_udp" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt

        # We calculate the average errors for UDP 
        avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
        echo "The average errors for UDP in $TESTS runs, injection bitrate of $bitrate Mbps and a packet burst of $burst packets is $avg_loss_udp %"
        echo "$bitrate $avg_loss_udp" >> ../results/${TEST_NAME}/udp-error-${buffer}.txt
        echo ""

      #done
    done
	done
#done

else
	echo "---------------------------------"
	echo "El servidor nuttcp no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'nuttcp -S' en el servidor y asegurese de que hay conexion con ping"
	echo ""
fi

