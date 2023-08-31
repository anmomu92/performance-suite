import argparse

# Function to calculate the different statistics
def calculate_statistics(data):
    # Sort the data in ascending order
    sorted_data = sorted(data)

    # Calculate the statistics
    n = len(sorted_data)
    min_value = sorted_data[0]
    max_value = sorted_data[-1]
    q1 = sorted_data[n // 4]
    median = sorted_data[n // 2] if n % 2 == 0 else (sorted_data[n // 2] + sorted_data[n // 2 - 1]) / 2
    q3 = sorted_data[n // 4 * 3]

    return min_value, q1, median, q3, max_value

def write_statistics_to_file(datafile, outputfile):
    # Read data from the file
    with open(datafile, "r") as file:
        data = [float(line.strip()) for line in file]

    # Calculate statistics
    min_value, q1, median, q3, max_value = calculate_statistics(data)

    # Write the results to the output file with tab-separated values
    with open(outputfile, "w") as output:
        output.write(f"Minimum\tQ1\tMedian (Q2)\tQ3\tMaximum\n")
        output.write(f"{min_value:.6f}\t{q1:.6f}\t{median:.6f}\t{q3:.6f}\t{max_value:.6f}\n")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate statistics from data files.")
    parser.add_argument("datafiles", nargs='+', type=str, help="Paths to the data files")
    args = parser.parse_args()

    # Process each data file and write the output file
    for datafile in args.datafiles:
        outputfile = f"boxplot-output-{datafile}"
        write_statistics_to_file(datafile, outputfile)

