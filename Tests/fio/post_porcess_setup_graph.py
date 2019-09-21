#!/usr/bin/python

import sys

def get_non_trace_value(lines, name, val):
    assert name.endswith('-0'), "Searching for copy_cycles for test with trace"
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        if lname[-1] == '1' and name[:-2] == lname[:-2]:
            return float(elements[val])
    return None

def post_process(setup = 'setup.csv'):
    FORMAT = '%17s %10s %10s %10s %10s %10s %10s %10s %7s %7s %7s %7s'
    FORMAT2 = '%17s %10.2f %10.2f %10.2f %10.2f %10.2f %10.2f %10s %7s %7s %7s %7s %10s'
    # membwReal- is for membwReal with no prefetch
    # bw- is for bw with no prefetch
    print '#' + FORMAT % ('test', 'copy (%)', 'copy (Mc)', 'ops (Mc)', 'copy/io (Mc)', 'ops (Mc)', 'bw (MB)', 'iops', 'zc', 'bs', 'iodepth', 'freq' 'rx_bytes (MB)')
    data = open(setup, 'rb').read()
    lines = data.split('\n')[1:]

    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        test = elements[0]
        _fio,_bs,_depth,_zc,_trace = test.split('-')
        if _trace == '1':
            continue
        #copy_cycles = float(elements[3])
        copy_cycles = get_non_trace_value(lines, test, 3)
        perf_cycles = float(elements[4])
        perf_runtime = float(elements[5]) / 1000.0
        perf_cycles = perf_cycles / perf_runtime # should be similar to freq
        bs = elements[6]
        zc = elements[7]
        bw = float(elements[8]) / 1000.0
        copy = copy_cycles / perf_cycles * 100.0
        iops = float(elements[9])
        cycles_per_io = perf_cycles / float(iops)
        copy_per_io = copy_cycles / float(iops)
        iodepth = elements[10]
        rx_bytes = get_non_trace_value(lines, test, 11) / (10**6)
        print FORMAT2 % (test, copy , copy_cycles / (10**6), perf_cycles / (10**6), copy_per_io / (10**3), cycles_per_io / (10**3), bw, iops, zc, bs, iodepth, '2GHz', rx_bytes)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        post_process(sys.argv[1])
    else:
        post_process()
