#!/usr/bin/env python3
import argparse
import json
from statistics import mean
from time import time, sleep, strftime
from typing import Dict, Any

import iperf3

"""
Using a script to automate several tests with iperf3. Ten total runs, save output of each run
"""


def run_test(bind_addr: str = '127.0.0.1',
             srv_addr: str = '127.0.0.1',
             port: int = 5201,
             duration: int = 30,
             zerocopy: bool = False
             ) -> Dict[str, Any]:
    """
    Simple method to automate testing, returns a list of KPIs, i.e. Mbps, retransmits, time, CPU usage
    :param bind_addr: Local address used by client
    :param srv_addr: Server address
    :param port: Server address port
    :param duration: How long to perform test, default is 30s
    :param zerocopy: Use zerocopy to reduce CPU load, default is False
    :param run_no: ID for the current run, useful for later parsing of the results
    :return: Dict of KPIs
    """
    client = iperf3.Client()

    client.bind_address = bind_addr
    client.server_hostname = srv_addr
    client.port = port
    client.duration = duration
    client.zerocopy = zerocopy

    time_start = time()
    timestamp = strftime('%Y%m%d-%H%M%S')
    result = client.run()
    time_end = time()

    total_time = time_end - time_start
    to_return = {
        'timestamp': timestamp,
        'sent_mbps': result.sent_Mbps,
        'retransmits': result.retransmits,
        'cpu_load': result.local_cpu_total,
        'total_time': total_time
    }

    return to_return


def read_results(filename: str):
    with open(filename, 'r') as f:
        to_return = json.loads(f.read())
    return to_return


def main():
    parser = argparse.ArgumentParser(description='Perform several runs of Iperf3')
    parser.add_argument('-B', '--bind_addr',
                        help='Client Address',
                        default='127.0.0.1',
                        type=str)
    parser.add_argument('-s', '--srv_addr',
                        help='Server Address',
                        default='127.0.0.1',
                        type=str)
    parser.add_argument('-r', '--runs',
                        help='Number of runs to perform',
                        default=1,
                        type=int)
    parser.add_argument('-P', '--pause',
                        help='How long to pause between runs in seconds',
                        default=30,
                        type=int)
    parser.add_argument('-t', '--duration',
                        help='How long to perform each run in seconds',
                        default=5,
                        type=int)
    parser.add_argument('-Z', '--zerocopy',
                        help='Use zerocopy method, see Iperf3 docs.',
                        action='store_true')
    parser.add_argument('-p', '--port',
                        help='Bind to specific port or default 5201',
                        default=5201,
                        type=int)
    parser.add_argument('-e', '--suffix',
                        help='Suffix to add to results file',
                        default='',
                        type=str)
    parser.add_argument('-R', '--read',
                        help='Start script in read-mode, opens a file with given filename using -F flag',
                        action='store_true')
    parser.add_argument('-F', '--filename',
                        help='Specify filename to read',
                        default='',
                        type=str)

    args = parser.parse_args()

    arg_runs = args.runs
    arg_pause = args.pause
    arg_bind = args.bind_addr
    arg_srv = args.srv_addr
    arg_port = args.port
    arg_duration = args.duration
    arg_zerocopy = args.zerocopy
    arg_suffix = args.suffix
    arg_read = args.read
    arg_filename = args.filename

    if arg_read:
        if not arg_filename:
            print('A filename must be provided if using the -R flag')
            exit(1)
        else:
            results = read_results(arg_filename)
            for item in results:
                print(item)
            exit(0)

    filename = f'{strftime("%Y%m%d-%H%M")}-iperf-results'
    if arg_suffix:
        filename = filename + f'-{arg_suffix}'
    filename = filename + '.json'

    print(f'Will perform {arg_runs} runs with {arg_duration} seconds duration with'
          f' {arg_pause} seconds pause between each run and store results to {filename}')
    results = []
    for i in range(1, arg_runs + 1):
        # Wrap in try-except to ensure results are written to fail even in failure
        try:
            print(f'performing run {i} of {arg_runs}')
            to_add = run_test(bind_addr=arg_bind,
                              srv_addr=arg_srv,
                              port=arg_port,
                              duration=arg_duration,
                              zerocopy=arg_zerocopy)
            results.append(to_add)
            if arg_runs > 1:
                sleep(arg_pause)
        except Exception as err:
            print(err)
            break

    with open(filename, 'w') as f:
        f.write(json.dumps(results))


if __name__ == '__main__':
    main()
