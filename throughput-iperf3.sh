#!/bin/bash

# Constants
SERVER_IP=192.168.0.20
CLIENT_IP=192.168.0.10
TESTS=100

# Variables
success=0
ip3=0

part_transfer_tcp=0
total_transfer_tcp=0
avg_transfer_tcp=0
part_transfer_udp=0
total_transfer_udp=0
avg_transfer_udp=0

part_bitrate_tcp=0
total_bitrate_tcp=0
avg_bitrate_tcp=0
part_bitrate_udp=0
total_bitrate_udp=0
avg_bitrate_udp=0

part_jitter_udp=0
total_jitter_udp=0
avg_jitter_udp=0

part_loss_udp=0
total_loss_udp=0
avg_loss_udp=0

# We delete previous result files
if [ -f "throughput.txt" ]; then
	rm throughput.txt
fi

if [ -f "jitter.txt" ]; then
	rm jitter.txt
fi

if [ -f "loss.txt" ]; then
	rm loss.txt
fi

if [ -f "box-plot.txt" ]; then
	rm box-plot.txt
fi

# We check that there is connectivity with the server
ping -c 1 $SERVER_IP > /dev/null 2>&1 && success=1
iperf3 -c $SERVER_IP -B $CLIENT_IP -t 1 > /dev/null 2>&1 && ip3=1

if [ $success -eq 1 ] && [ $ip3 -eq 1 ]
then
# We run the TCP iperf3 test with the default options
	for i in $(seq 1 $TESTS); do
		# Transfer for TCP
		result_tcp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -O1 -t11 -f m| grep receiver)
		part_transfer_tcp=$(echo $result_tcp | awk '{print $5}')
		units_transfer_tcp=$(echo $result_tcp | awk '{print $6}')
		total_transfer_tcp=$(echo $total_transfer_tcp + $part_transfer_tcp | bc)

		# Bitrate for TCP
		part_bitrate_tcp=$(echo $result_tcp | awk '{print $7}')
		units_bitrate_tcp=$(echo $result_tcp | awk '{print $8}')
		total_bitrate_tcp=$(echo $total_bitrate_tcp + $part_bitrate_tcp | bc)

		echo -n "$part_bitrate_tcp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "TCP" >> box-plot.txt
		fi
	done

	# We calculate the average transfered bytes for TCP
	echo "---------------------"
	echo "TCP - DEFAULT OPTIONS"
	echo "---------------------"
	avg_transfer_tcp=$(echo "scale=3; $total_transfer_tcp / $TESTS" | bc -l)
	echo "The average transfer for TCP in $TESTS runs is $avg_transfer_tcp $units_transfer_tcp"

	# We calculate the average transfered bytes and bitrate for TCP
	avg_bitrate_tcp=$(echo "scale=3; $total_bitrate_tcp / $TESTS" | bc -l)
	echo "The average bitrate for TCP in $TESTS runs is $avg_bitrate_tcp $units_bitrate_tcp"
	echo ""

	total_transfer_tcp=0
	total_bitrate_tcp=0

# We run the UDP iperf3 test with an injection bitrate of 10 MB
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b10M -O1 -t11 | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

	done

# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an injection of 10MB
	echo "------------------------------"
	echo "UDP - DEFAULT OPTIONS AND 10MB"
	echo "------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and 10MB is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and 10MB is $avg_bitrate_udp $units_bitratre_udp"

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and 10MB is $avg_jitter_udp $units_jitter_udp"

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and 10MB is $avg_loss_udp"

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

# We run the UDP iperf3 test with an injection bitrate of 100 MB
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b100M -O1 -t11 | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

		echo -n "$part_bitrate_udp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "100" >> box-plot.txt
		fi

	done

	# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an injection of 100MB
	echo "----------------------------------------------------"
	echo "UDP - DEFAULT OPTIONS AND INJECTION BITRATE OF 100MB"
	echo "----------------------------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and 100MB is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and 100MB is $avg_bitrate_udp $units_bitrate_udp"
	echo "100 $avg_bitrate_udp" >> throughput.txt

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and 100MB is $avg_jitter_udp $units_jitter_udp"
	echo "100 $avg_jitter_udp" >> jitter.txt

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and 100MB is $avg_loss_udp"
	echo "100 $avg_loss_udp" >> loss.txt

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

# We run the UDP iperf3 test with an injection bitrate of 500 MB
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b500M -O1 -t11 | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

		echo -n "$part_bitrate_udp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "500" >> box-plot.txt
		fi

	done

	# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an injection of 500MB
	echo "----------------------------------------------------"
	echo "UDP - DEFAULT OPTIONS AND INJECTION BITRATE OF 500MB"
	echo "----------------------------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and 500MB is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and 500MB is $avg_bitrate_udp $units_bitrate_udp"
	echo "500 $avg_bitrate_udp" >> throughput.txt

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and 500MB is $avg_jitter_udp $units_jitter_udp"
	echo "500 $avg_jitter_udp" >> jitter.txt

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and 500MB is $avg_loss_udp"
	echo "500 $avg_loss_udp" >> loss.txt

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

# We run the UDP iperf3 test with an injection bitrate of 1000 MB
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b1000M -O1 -t11 -f m | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

		echo -n "$part_bitrate_udp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "1000" >> box-plot.txt
		fi

	done

	# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an injection of 1000MB
	echo "-----------------------------------------------------"
	echo "UDP - DEFAULT OPTIONS AND INJECTION BITRATE OF 1000MB"
	echo "-----------------------------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and 1000MB is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and 1000MB is $avg_bitrate_udp $units_bitrate_udp"
	echo "1000 $avg_bitrate_udp" >> throughput.txt

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and 1000MB is $avg_jitter_udp $units_jitter_udp"
	echo "1000 $avg_jitter_udp" >> jitter.txt

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and 1000MB is $avg_loss_udp"
	echo "1000 $avg_loss_udp" >> loss.txt

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

# We run the UDP iperf3 test with an injection bitrate of 2000 MB
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b2000M -O1 -t11 -f m | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

		echo -n "$part_bitrate_udp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "2000" >> box-plot.txt
		fi

	done

	# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an injection of 2000MB
	echo "-----------------------------------------------------"
	echo "UDP - DEFAULT OPTIONS AND INJECTION BITRATE OF 2000MB"
	echo "-----------------------------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and 2000MB is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and 2000MB is $avg_bitrate_udp $units_bitrate_udp"
	echo "2000 $avg_bitrate_udp" >> throughput.txt

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and 2000MB is $avg_jitter_udp $units_jitter_udp"
	echo "2000 $avg_jitter_udp" >> jitter.txt

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and 2000MB is $avg_loss_udp"
	echo "2000 $avg_loss_udp" >> loss.txt

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

# We run the UDP iperf3 test with an injection bitrate of 3000 MB
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b3000M -O1 -t11 -f m | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

		echo -n "$part_bitrate_udp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "3000" >> box-plot.txt
		fi

	done

	# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an injection of 3000MB
	echo "-----------------------------------------------------"
	echo "UDP - DEFAULT OPTIONS AND INJECTION BITRATE OF 3000MB"
	echo "-----------------------------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and 3000MB is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and 3000MB is $avg_bitrate_udp $units_bitrate_udp"
	echo "3000 $avg_bitrate_udp" >> throughput.txt

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and 3000MB is $avg_jitter_udp $units_jitter_udp"
	echo "3000 $avg_jitter_udp" >> jitter.txt

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and 3000MB is $avg_loss_udp"
	echo "3000 $avg_loss_udp" >> loss.txt

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

# We run the UDP iperf3 test with an injection bitrate of 10 GB
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b10G -O1 -t11 -f m | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

		echo -n "$part_bitrate_udp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "10000" >> box-plot.txt
		fi

	done

	# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an injection of 10GB
	echo "---------------------------------------------------"
	echo "UDP - DEFAULT OPTIONS AND INJECTION BITRATE OF 10GB"
	echo "---------------------------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and 10GB is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and 10GB is $avg_bitrate_udp $units_bitrate_udp"
	echo "10000 $avg_bitrate_udp" >> throughput.txt

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and 10GB is $avg_jitter_udp $units_jitter_udp"
	echo "10000 $avg_jitter_udp" >> jitter.txt

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and 10GB is $avg_loss_udp"
	echo "10000 $avg_loss_udp" >> loss.txt

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

# We run the UDP iperf3 test with an unlimited injection bitrate
	for i in $(seq 1 $TESTS); do
		# Transfer for UDP
		result_udp=$(iperf3 -c $SERVER_IP -B $CLIENT_IP -u -b0 -O1 -t11 -f m | grep receiver)
		part_transfer_udp=$(echo $result_udp | awk '{print $5}')
		units_transfer_udp=$(echo $result_udp | awk '{print $6}')
		total_transfer_udp=$(echo $total_transfer_udp + $part_transfer_udp | bc)

		# Bitrate for UDP
		part_bitrate_udp=$(echo $result_udp | awk '{print $7}')
		units_bitrate_udp=$(echo $result_udp | awk '{print $8}')
		total_bitrate_udp=$(echo $total_bitrate_udp + $part_bitrate_udp | bc)

		# Jitter for UDP
		part_jitter_udp=$(echo $result_udp | awk '{print $9}')
		units_jitter_udp=$(echo $result_udp | awk '{print $10}')
		total_jitter_udp=$(echo $total_jitter_udp + $part_jitter_udp | bc)

		# Datagram loss for UDP
		part_loss_udp=$(echo $result_udp | awk '{print $12}')
		part_loss_udp=$(echo $part_loss_udp | tr -d -c 0-9,\.)
		total_loss_udp=$(echo $total_loss_udp + $part_loss_udp | bc)

		echo -n "$part_bitrate_udp " >> box-plot.txt

		if [ $i -eq $TESTS ]; then
			echo "99999" >> box-plot.txt
		fi

	done

	# We calculate the average transfered bytes, bitrate, jitter and datagram loss for UDP and an unlimited injection
	echo "-----------------------------------------------------"
	echo "UDP - DEFAULT OPTIONS AND UNLIMITED INJECTION BITRATE"
	echo "-----------------------------------------------------"
	avg_transfer_udp=$(echo "scale=3; $total_transfer_udp / $TESTS" | bc -l)
	echo "The average transfer for UDP in $TESTS runs and unlimited is $avg_transfer_udp $units_transfer_udp"

	# We calculate the average transfered bytes for TCP
	avg_bitrate_udp=$(echo "scale=3; $total_bitrate_udp / $TESTS" | bc -l)
	echo "The average bitrate for UDP in $TESTS runs and unlimited is $avg_bitrate_udp $units_bitrate_udp"
	echo "99999 $avg_bitrate_udp" >> throughput.txt

	# We calculate the average transfered bytes for TCP
	avg_jitter_udp=$(echo "scale=3; $total_jitter_udp / $TESTS" | bc -l)
	echo "The average jitter for UDP in $TESTS runs and unlimited is $avg_jitter_udp $units_jitter_udp"
	echo "99999 $avg_jitter_udp" >> jitter.txt

	# We calculate the average transfered bytes for TCP
	avg_loss_udp=$(echo "scale=3; $total_loss_udp / $TESTS" | bc -l)
	echo "The average datagram loss for UDP in $TESTS runs and unlimited is $avg_loss_udp"
	echo "99999 $avg_loss_udp" >> loss.txt

	total_transfer_udp=0
	total_bitrate_udp=0
	total_jitter_udp=0
	part_loss_udp=0
	total_loss_udp=0

else
	echo "---------------------------------"
	echo "El servidor iperf3 no esta activo"
	echo "---------------------------------"
	echo ""
	echo "* Para activarlo ejecute el comando 'iperf3 -s -B <SERVER_IP>' en el servidor y asegurese de que hay conexion con ping"
	echo ""
fi

