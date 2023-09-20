#!/bin/bash

###################################
# Environment Variables
###################################

# Variables to communicate with the prototype
export USERNAME="antonio"
export HOST_A=161.67.133.94
export HOST_B=161.67.133.93
export SWITCH=161.67.133.92
export SSH_KEY=$HOME/.ssh/id_ed25519
export REMOTE_HOME="/home/${USERNAME}"
export REMOTE_RESULTS_DIR="${REMOTE_HOME}/results"
export REMOTE_SCRIPTS_DIR="${REMOTE_HOME}/scripts"
export RESULTS_DIR="../local/results/corundum"

# Variables to set the tests
export SERVER_IP=192.168.0.20
export CLIENT_IP=192.168.0.10
export TESTS=50
export TEST_DURATION=10

buffer_size=(106496 212992 524288 1048576 52428800 157286400) # 104KB 208KB 512KB 1MB 50MB  150MB
injection_bitrate=(100 500 1000 2000 3000 10000 0)
message_size=(512 1024 2048 4096 8192 16384)

 
###################################
# Variables
###################################

# Set to 1 if there is connection when using the tool
success=0

# Bitrate (throughput) in TCP connection
part_bitrate_tcp=0
total_bitrate_tcp=0
avg_bitrate_tcp=0

# Transfer in TCP connection
part_transfer_tcp=0
total_transfer_tcp=0
avg_transfer_tcp=0

# Retransmissions in TCP connection
part_retransmissions_tcp=0
total_retransmissions_tcp=0
avg_retransmissions_tcp=0

# Transfer in UDP connection
part_transfer_udp=0
total_transfer_udp=0
avg_transfer_udp=0

# Bitrate (throughput) in UDP connection
part_bitrate_udp=0
total_bitrate_udp=0
avg_bitrate_udp=0

# Jitter in UDP connection
part_jitter_udp=0
total_jitter_udp=0
avg_jitter_udp=0

# Datagram loss in UDP connection
part_loss_udp=0
total_loss_udp=0
avg_loss_udp=0
