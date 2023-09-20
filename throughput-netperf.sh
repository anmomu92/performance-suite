#!/bin/bash

source settings.sh

# Variables
TEST_NAME="netperf"
nperf=0

# We create results directory if it doesn't exist
	if [ ! -d "../results/${TEST_NAME}" ]; then
		mkdir -p ../results/${TEST_NAME}
	fi

	# We create logs directory if it doesn't exist
	if [ ! -d "../logs/${TEST_NAME}" ]; then
		mkdir -p ../logs/${TEST_NAME}
	fi

# Print the test name
echo "---------------------------------------------------------- NETPERF ----------------------------------------------------------"

# Check that there is connectivity with the server
netperf -H $SERVER_IP -l 1 -t TCP_STREAM > /dev/null 2>&1 && nperf=1

# Server is running
if [ $nperf -eq 1 ]: then
    for buffer in "${buffer_size[@]}"; do # Buffer size
        # Delete previous result files
        if [ -f "../results/${TEST_NAME}/tcp-throughput-${buffer}.txt" ]; then
            rm ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt
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

        # Convert the B in KB for better readability
        buffer_in_kb=$(echo "scale=2; $buffer / 1024")

        echo ""
        echo "Kernel buffer size set to $buffer_in_kb KB"

    #	: <<'END'
      # We run the TCP netperf test 
        echo "-----------------------------------------"
        echo "| TCP - NETPERF - BUFFER SIZE: $buffer B |"
        echo "-----------------------------------------"

        # We initialize the variables
        total_bitrate_tcp=0

        for i in $(seq 1 $TESTS); do
                # We save the output as a log file and extract the last line to get the results
                netperf -H $SERVER_IP -l ${TEST_DURATION} -t TCP_STREAM -f m >> ../logs/${TEST_NAME}/tcp-log-${buffer}.txt
                netperf_result_tcp=$(tail -1 ../logs/${TEST_NAME}/tcp-log-${buffer}.txt)

            # Throughput for TCP
            part_bitrate_tcp=$(echo $netperf_result_tcp | awk '{print $5}')
            total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)

                # We check that, in case of error, no string is passed to the variable
                if [[ ! $part_bitrate_tcp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    part_bitrate_tcp=0
                fi

            echo "$part_bitrate_tcp " >> ../results/${TEST_NAME}/tcp-box-plot-${buffer}.txt

                echo "RUN: $i ------- Partial bitrate: $part_bitrate_tcp Mbps"
        done
            echo "-----------------------------------------------"
        
        # We calculate the average throughput for TCP
        avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
        echo "The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp Mbps"
            echo "# The average throughput after $TESTS runs is the following: " >> ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt
        echo "bitrate $avg_bitrate_tcp" >> ../results/${TEST_NAME}/tcp-throughput-${buffer}.txt


      # We run the UDP netperf test 
        echo "----------------------------------------"
        echo "| UDP - NETPERF - BUFFER SIZE: $buffer B|"
        echo "----------------------------------------"

      # We calculate the average UDP throughput for different message sizes 
      for size in "${message_size[@]}"; do

        if [ -f "../results/${TEST_NAME}/udp-box-plot-${buffer}-${size}.txt" ]; then
            rm ../results/${TEST_NAME}/udp-box-plot-${buffer}-${size}.txt
        fi

        echo ""
        echo "Message size set to $size"
        echo "-----------------------------------------------"
        echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
        echo "MSG_SIZE = $size - BUFFER_SIZE = $rmem_default" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt
        echo "MSG_SIZE = $size - BUFFER_SIZE = $rmem_default" >> ../results/${TEST_NAME}/udp-error-${buffer}.txt

        # We initialize the variables
        total_bitrate_udp=0
        total_loss_udp=0

          for i in $(seq 1 $TESTS); do
            echo "RUN = $i - MSG_SIZE = $size - BUFFER_SIZE = $rmem_default" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
            # We save the output as a log file and extract the last line to get the results
            netperf -H ${SERVER_IP} -t UDP_STREAM -l ${TEST_DURATION} -- -m ${size} -- -f m >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
            netperf_result_udp=$(tail -3 ../logs/${TEST_NAME}/udp-log-${buffer}.txt | head -1)

            echo "------------------------------------------------------------------------------" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt
            echo "" >> ../logs/${TEST_NAME}/udp-log-${buffer}.txt

            # Throughput for UDP
            part_bitrate_udp=$(echo $netperf_result_udp | awk '{print $6}')
            total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

            # We check that, in case of error, no string is passed to the variable
            if [[ ! $part_bitrate_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
              part_bitrate_udp=0
            fi

        echo "$part_bitrate_udp " >> ../results/${TEST_NAME}/udp-box-plot-${buffer}-${size}.txt

            # Errors for UDP
            part_loss_udp=$(echo $netperf_result_udp | awk '{print $5}')
            total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

            # We check that, in case of error, no string is passed to the variable
            if [[ ! $part_loss_udp =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
              part_loss_udp=0
            fi

            echo "RUN = $i ------- Partial bitrate: $part_bitrate_udp Mbps - Partial loss: $part_loss_udp"
          done
        echo "-----------------------------------------------"

        # We calculate the average throughput for UDP 
        avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
        echo "The average throughput for UDP in $TESTS runs and message size of $size is $avg_bitrate_udp Mbps"
        echo "$size $avg_bitrate_udp" >> ../results/${TEST_NAME}/udp-throughput-${buffer}.txt

        # We calculate the average errors for UDP 
        avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
        echo "The average errors for UDP in $TESTS runs and message size of $size is $avg_loss_udp"
        echo "$size $avg_loss_udp" >> ../results/${TEST_NAME}/udp-error-${buffer}.txt


      done
    done

else
	echo "---------------------------------"
	echo "El servidor netperf no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'netserver' en el servidor y asegurese de que hay conexion con ping"
	echo ""
fi

