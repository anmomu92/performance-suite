#!/bin/bash

# Constants
export TEST_NAME=iperf3
injection_bitrate=(100 500 1000 2000 3000 10000 0)
buffer_size=(212992 157286400)
packet_burst=(5 10 20 50 100 200)
message_size=(1472 8972)

# Variables specific to this bash script
ip3=0
injection_bitrate=(100 500 1000 2000 3000 10000 0)
buffer_size=(212992 157286400)
message_size=(1472 8972)


# We create results directory if it doesn't exist
if [ ! -d "../results/${TEST_NAME}" ]; then
	mkdir -p ../results/${TEST_NAME}
fi

# We create logs directory if it doesn't exist
if [ ! -d "../logs/${TEST_NAME}" ]; then
	mkdir -p ../logs/${TEST_NAME}
fi

# We show the test name
echo "---------------------------------------------------------- IPERF3 ----------------------------------------------------------"

# We check that the server is running iperf3
iperf3 -c $SERVER_IP -B $CLIENT_IP -t 1 > /dev/null 2>&1 && ip3=1

if [ $ip3 -eq 1 ]
then

  for buffer in "${buffer_size[@]}"; do
    
    # We delete previous result files
    if [ -f "../results/${TEST_NAME}/tcp-throughput-${buffer}.txt" ]; then
      rm ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt
    fi

    if [ -f "../results/${TEST_NAME}/tcp-transfer-${buffer}.txt" ]; then
      rm ../results/${TEST_NAME}/tcp-transfer-${buffer}.txt
    fi

    if [ -f "../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt" ]; then
      rm ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt
    fi

    if [ -f "../results/${TEST_NAME}/udp-transfer-${buffer}.txt" ]; then
      rm ../results/${TEST_NAME}/udp-transfer-${buffer}.txt
    fi

    if [ -f "../results/${TEST_NAME}/udp-throughput-${buffer}.txt" ]; then
      rm ../results/${TEST_NAME}/udp-throughput-${buffer}.txt
    fi

    if [ -f "../results/${TEST_NAME}/udp-jitter-${buffer}.txt" ]; then
      rm ../results/${TEST_NAME}/udp-jitter-${buffer}.txt
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

    # We set the buffer kernel
    echo ""
    echo "Setting the size of the kernel buffer"
    echo "-------------------------------------"

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

    echo ""
    echo "----------------------------------------"
    echo "| TCP - IPERF3 - BUFFER SIZE: $buffer B |"
    echo "----------------------------------------"
    echo ""

    # We initialize the variables
    total_transfer_tcp=0
    total_bitrate_tcp=0
    total_retransmissions_tcp=0
    
    # We run the TCP iperf3 test with the default options
    for i in $(seq 1 $TESTS); do
      
      # We send the output to a log file
      echo "iperf3 -c $SERVER_IP -B $CLIENT_IP -O1 -t${TEST_DURATION} -f m" >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
      iperf3 -c $SERVER_IP -B $CLIENT_IP -O1 -t${TEST_DURATION} -f m >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
      iperf3_result_tcp_sender=$(tail -4 ../logs/${TEST_NAME}/tcp-log-${buffer}.txt | head -1)
      iperf3_result_tcp_receiver=$(tail -3 ../logs/${TEST_NAME}/tcp-log-${buffer}.txt | head -1)

      # TCP transfer
      part_transfer_tcp=$(echo $iperf3_result_tcp_receiver | awk '{print $5}')
      units_transfer_tcp=$(echo $iperf3_result_tcp_receiver | awk '{print $6}')
      total_transfer_tcp=$(echo $total_transfer_tcp + $part_transfer_tcp | bc)

      # We check that, in case of error, no string is passed to the variable
      if [[ ! $part_transfer_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        part_transfer_tcp=0
      fi

      # TCP bitrate
      part_bitrate_tcp=$(echo $iperf3_result_tcp_receiver | awk '{print $7}')
      units_bitrate_tcp=$(echo $iperf3_result_tcp_receiver | awk '{print $8}')
      total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)

      # We check that, in case of error, no string is passed to the variable
      if [[ ! $part_bitrate_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        part_bitrate_tcp=0
      fi
      
      # TCP retransmissions
      part_retransmissions_tcp=$(echo $iperf3_result_tcp_sender | awk '{print $9}')
      total_retransmissions_tcp=$(echo $total_retransmissions_tcp + $part_retransmissions_tcp | bc)

      # We check that, in case of error, no string is passed to the variable
      if [[ ! $part_retransmissions_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        part_retransmissions_tcp=0
      fi

      # We add data to the boxplot text file
      echo "$part_bitrate_tcp " >> ../results/${TEST_NAME}/tcp-box-plot-${buffer}.txt

      echo "RUN: $i ------- Partial transfered data: $part_transfer_tcp $units_transfer_tcp - Partial bitrate: $part_bitrate_tcp $units_bitrate_tcp - Partial retransmissions: $part_retransmissions_tcp"

    done

    # We calculate the average transfered bytes for TCP
    echo "---------------------"
    echo "TCP - DEFAULT OPTIONS"
    echo "---------------------"
    avg_transfer_tcp=$(echo "scale=3; $total_transfer_tcp / $TESTS" | bc -l)
    echo "The average transfer for TCP in $TESTS runs is $avg_transfer_tcp $units_transfer_tcp"
    echo "# The average transfer after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-transfer-${buffer}.txt
    echo "$avg_transfer_tcp" >> ../results/${TEST_NAME}/tcp-transfer-${buffer}.txt

    # We calculate the average bitrate for TCP
    avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
    echo "The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp $units_bitrate_tcp"
    echo "# The average bitrate after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt
    echo "$avg_bitrate_tcp" >> ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt

    # We calculate the average bitrate for TCP
    avg_retransmissions_tcp=$(echo "scale=3; $total_retransmissions_tcp / $TESTS" | bc -l)
    echo "The average retransmissions for TCP in $TESTS runs is $avg_retransmissions_tcp"
    echo "# The average number of retransmissions after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt
    echo "$avg_retransmissions_tcp" >> ../results/${TEST_NAME}/tcp-retransmissions-${buffer}.txt


    echo ""
    echo "----------------------------------------"
    echo "| UDP - IPERF3 - BUFFER SIZE: $buffer B |"
    echo "----------------------------------------"
    
    # We run the UDP iperf3 varying the injection bitrate
    for bitrate in "${injection_bitrate[@]}"; do 

      if [ -f "../results/${TEST_NAME}/udp-box-plot-${buffer}-${bitrate}.txt" ]; then
        rm ../results/${TEST_NAME}/udp-box-plot-${buffer}-${bitrate}.txt
      fi

      # We initialize the variables
      total_transfer_udp=0
      total_bitrate_udp=0
      total_jitter_udp=0
      total_loss_udp=0

      echo ""
      echo "Injection bitrate set to $bitrate Mbps"
      echo "-----------------------------------------------"
      echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
      echo "# INJ BITRATE: $bitrate Mbps - BUFFER SIZE: $buffer B" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt
      echo "# INJ BITRATE: $bitrate Mbps - BUFFER SIZE: $buffer B" >> ../results/${TEST_NAME}/udp-transfer-${buffer}.txt
      echo "# INJ BITRATE: $bitrate Mbps - BUFFER SIZE: $buffer B" >> ../results/${TEST_NAME}/udp-jitter-${buffer}.txt
      echo "# INJ BITRATE: $bitrate Mbps - BUFFER SIZE: $buffer B" >> ../results/${TEST_NAME}/udp-loss-${buffer}.txt
      for i in $(seq 1 $TESTS); do
        echo "RUN: $i - INJ BITRATE: $bitrate Mbps - BUFFER SIZE: $buffer B" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

        # We save the output as a log file
        echo "iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b${bitrate}M -O1 -t${TEST_DURATION}" -f m >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
        iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b${bitrate}M -O1 -t${TEST_DURATION} -f m >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

        # We get the relevant line from the output
        iperf3_result_udp=$(tail -3 ../logs/${TEST_NAME}/udp-log-${buffer}.txt | head -1)

        echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
        echo "" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

        # UDP transfer
        part_transfer_udp=$(echo $iperf3_result_udp | awk '{print $5}')
        units_transfer_udp=$(echo $iperf3_result_udp | awk '{print $6}')
        total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

        # We check that, in case of error, no string is passed to the variable
        if [[ ! $part_transfer_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
          part_transfer_udp=0
	fi

        # UDP bitrate
        part_bitrate_udp=$(echo $iperf3_result_udp | awk '{print $7}')
        units_bitrate_udp=$(echo $iperf3_result_udp | awk '{print $8}')
        total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

        # We check that, in case of error, no string is passed to the variable
        if [[ ! $part_bitrate_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
          part_bitrate_udp=0
	fi

      	echo "$part_bitrate_udp " >> ../results/${TEST_NAME}/udp-box-plot-${buffer}-${bitrate}.txt

        # UDP jitter
        part_jitter_udp=$(echo $iperf3_result_udp | awk '{print $9}')
        units_jitter_udp=$(echo $iperf3_result_udp | awk '{print $10}')
        total_jitter_udp=$(echo "$total_jitter_udp + $part_jitter_udp" | bc)

        # We check that, in case of error, no string is passed to the variable
        if [[ ! $part_jitter_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
          part_bitter_udp=0
	fi

        # UDP datagram loss
        part_loss_udp=$(echo $iperf3_result_udp | awk '{print $12}')
        part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
        total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

        # We check that, in case of error, no string is passed to the variable
        if [[ ! $part_loss_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
          part_loss_udp=0
	fi

        echo "RUN: $i ------- Partial bitrate: $part_bitrate_udp $units_bitrate_udp - Partial jitter: $part_jitter_udp $units_jitter_udp - Partial loss: $part_loss_udp %"
      done
      echo "-----------------------------------------------"

      # We calculate the average UDP transfer
      avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
      echo "The average transfer for UDP in $TESTS runs and injection bitrate of $bitrate Mbps is $avg_transfer_udp $units_transfer_udp"
      echo "$bitrate $avg_transfer_udp" >> ../results/${TEST_NAME}/udp-transfer-${buffer}.txt

      # We calculate the average UDP bitrate 
      avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
      echo "The average bitrate for UDP in $TESTS runs and injection bitrate of $bitrate is $avg_bitrate_udp $units_bitrate_udp"
      echo "$bitrate $avg_bitrate_udp" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt

      # We calculate the average UDP jitter
      avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
      echo "The average jitter for UDP in $TESTS runs and injection bitrate of $bitrate is $avg_jitter_udp $units_jitter_udp"
      echo "$bitrate $avg_jitter_udp" >> ../results/${TEST_NAME}/udp-jitter-${buffer}.txt

      # We calculate the average UDP datagram loss
      avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
      echo "The average datagram loss for UDP in $TESTS runs and injection bitrate of $bitrate is $avg_loss_udp %"
      echo "$bitrate $avg_loss_udp" >> ../results/${TEST_NAME}/udp-loss-${buffer}.txt

    done
  done
else
	echo "---------------------------------"
	echo "El servidor iperf3 no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'iperf3 -s -B <SERVER_IP>' en el servidor"
	echo ""
fi

