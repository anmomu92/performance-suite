## Introduction 
This repo contains the following scripts:

<ul>
    <li>format-box-plot-data.py (Deprecated): this python script was used to transform the boxplot data into a gnuplot-readable format. As `R` is now used to make the boxplots, this script is not necessary anymore.</li>
    <li>latency-qperf.sh: it performs several `qperf` tests and measures the average latency. It needs further work.</li>
    <li>main.sh: this is the script meant to be launched in the prototype. It launches the tests designed for the different tools. From this script, you can type the number of runs that each tool is going to perform, as well as the duration of each run.</li>
    <li>run-test.sh: this script is meant to be launched from a local workstation. This script calls the `main.sh` script in the remote side (the prototype) and brings back the results.</li>
    <li>throughput-iperf3.sh: this script sets the `iperf3` connection and gathers the data necessary to make boxplots and performance comparisons between different buffer sizes for TCP and UDP.</li>
    <li>throughput-netperf.sh: this script sets the `netperf` connection and gathers the data necessary to make boxplots and performance comparisons between different buffer sizes for TCP and UDP.</li>
    <li>throughput-nuttcp.sh: this script sets the `nuttcp` connection and gathers the data necessary to make boxplots and performance comparisons between different buffer sizes for TCP and UDP.</li>
</ul>

Overall, these scripts provide a way to automate the execution of different network testing tools. Currently, the following testing tools are automatized:

- iperf3
- netperf
- nuttcp

## Installation

For the scripts to work it is necessary to download the tools that the different scripts use:

```
sudo apt update
sudo apt install iperf3 netperf nuttcp
```
## Usage

You just have to run the main script as sudo by typing `sudo ./main.sh`. This script will prompt you with questions about which tests you want to launch, in case you just want to launch a specific tool. By now, you have to choose the tool with a 1 (yes) or a 0 (no)

The script will generate two directories: `logs` and `results`. The `logs` directory contains the output of the execution of the given tool, while the `results` directory contains the data extracted from the output of the given tool.

### Examples of usage

- To run the performance tests directly withing the prototype run `sudo ./main.sh` and choose select just the `iperf3` option, then two sets of files will be created: one under the `iperf3` directory within the `log` directory, and another set under the `iperf3` directory within the results` directory.

- To run the performance tests from a local workstation (or from gitlab), run the `run-tests.sh` script.

## TODO
<ol>
    <li>main.sh: pass the number of tests and the duration as parameters. Also, it is necessary to make the prototype not request the password, as this script must be executed with `sudo`</li>
    <li>run-test.sh: do not bring back the results from this script. The results should be sent by the prototype once the tests finish. Also, before running this script, the other scripts should be sent to the prototype.</li>
    <li>throughput-<tool>.sh: each script should send its results when finished. Also, each tool should launch the server with an `ssh` call from within the script. </li>
</ol>

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
