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

You just have to run the main script typing `./main.sh`. This script will prompt you with questions about which tests you want to launch, in case you just want to launch a specific tool. By now, you have to choose the tool with a 1 (yes) or a 0 (no)

## Contributing

Pull requests are welcome. For major changes, please open an issue first
to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
