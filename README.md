# Introduction 

The following scripts provide a way to automate the execution of different network testing tools. Currently, the following testing tools are automatized:

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

If you run `sudo ./main.sh` and choose select just the `iperf3` option, then two sets of files will be created: one under the `iperf3` directory within the `log` directory, and another set under the `iperf3` directory within the results` directory.

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
