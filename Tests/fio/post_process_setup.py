#!/usr/bin/python

import sys

def get_trace_value(lines, name, val):
    assert name.endswith('-0'), "Searching for trace value for test with trace"
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        if lname[-1] == '1' and name[:-2] == lname[:-2]:
            return float(elements[val])
    return None

def get_copy_value(lines, name, val):
    assert name.endswith('-1-0'), "Searching for copy value for test with copy"
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _fio1, _bs1, _depth1, _zc1, _trace1 = name.split('-')
        _fio, _bs, _depth, _zc, _trace = lname.split('-')
        assert _fio == 'fio'
        assert _fio1 == 'fio'
        if _trace == '1' and _zc == '0' and _bs == _bs1 and _depth1 == _depth:
            print '# %s %s %s' % (name, val, l)
            return float(elements[val])
    return None

def post_process(setup = 'setup.csv', out_copy = 'model_copy.csv', out_zcopy = 'model_zcopy.csv'):
    FORMAT = '%17s, %10s, %10s, %10s, %12s, %10s, %10s, %10s, %4s, %7s, %7s, %7s, %16s, %17s, %17s, %17s, %17s %17s'
    FORMAT2 = '%17s, %10.1f, %10.2f, %10.2f, %12.2f, %10.2f, %10.2f, %10s, %4s, %7s, %7s, %7s, %16s, %17s, %17s, %17.2f, %17.2f, %17.2f'

    output_c = open(out_copy, 'wb')
    output_zc = open(out_zcopy, 'wb')
    s = FORMAT % ('test', 'copy(%)', 'copy(Mc)', 'ops(Mc)', 'copy/io(Kc)', 'op/io(Kc)',
                  'bw(MB)', 'iops', 'zc', 'bs(KB)', 'depth', 'freq', 'rx_bytes(MB)',
                  'exp_zcopy_iops', 'exp_zcopy_cycles', 'op/io copy(Kc)', 'copy/io copy(Kc))',
                  'rx_packets(KP)')
    print s
    output_c.write(s + '\n')
    output_zc.write(s + '\n')
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
        #if _bs in ['4M', '2M']:
        #    continue
        #copy_cycles = float(elements[3])
        copy_cycles = get_trace_value(lines, test, 3)
        perf_cycles = float(elements[4])
        perf_runtime = float(elements[5]) / 1000.0
        perf_cycles = perf_cycles / perf_runtime # should be similar to freq
        bs = elements[6]
        bs = int(bs[:-1]) if bs[-1] == 'K' else int(bs[:-1]) * 1024
        zc = elements[7]
        bw = float(elements[8]) / 1000.0
        copy = copy_cycles / perf_cycles * 100.0
        iops = float(elements[9])
        cycles_per_io = perf_cycles / iops
        copy_per_io = copy_cycles / iops
        iodepth = elements[10]
        rx_bytes = float(elements[11]) / (10**6)
        rx_packets = get_trace_value(lines, test, 12) / (10**3)
        if zc == '0':
            expected_zcopy_iops = iops / (1.0 - copy_cycles / perf_cycles)
            expected_zcopy_cycles = cycles_per_io * (100 - copy) / 100.0
            copy_perf_cycles_per_io = cycles_per_io / (10**3)
            copy_perf_copy_per_io = copy_per_io / (10**3)
        else:
            expected_zcopy_iops = iops
            expected_zcopy_cycles = cycles_per_io
            copy_perf_cycles = get_copy_value(lines, test, 4)
            copy_perf_runtime = get_copy_value(lines, test, 5) / 1000.0
            copy_perf_cycles = (copy_perf_cycles / copy_perf_runtime)
            copy_perf_iops = get_copy_value(lines, test, 9)
            copy_perf_cycles_per_io = (copy_perf_cycles / copy_perf_iops) / (10**3)
            copy_perf_copy_cycles = get_copy_value(lines, test, 3)
            print '# %s %s' % (copy_perf_copy_cycles, copy_perf_iops)
            copy_perf_copy_per_io = (copy_perf_copy_cycles / copy_perf_iops) / (10**3)

        s = FORMAT2 % (test, copy ,
                       copy_cycles / (10**6), perf_cycles / (10**6),
                       copy_per_io / (10**3), cycles_per_io / (10**3),
                       bw, iops, zc, bs, iodepth, '2GHz', rx_bytes,
                       expected_zcopy_iops, expected_zcopy_cycles / (10**3),
                       copy_perf_cycles_per_io, copy_perf_copy_per_io, rx_packets)
        print s
        if zc == '1':
            output_zc.write(s + '\n')
        else:
            output_c.write(s + '\n')
    output_c.close()
    output_zc.close()

def post_process_bargraph(setup = 'setup.csv', out = 'breakdown.csv'):
    prefix = \
'''
=stackcluster; other; copy
#=sortbmarks
#=nogridy
=patterns
=noupperright
legendx=right
legendy=center
yformat=%g
xlabel=io depth
ylabel=cycles per io (Kilo cycles)
fontsz=14
#extraops=plot "breakdown.csv" using
=table
'''
    output = open(out, 'wb')
    print prefix
    output.write(prefix)

    TITLE_FORMAT = 'multimulti=%s'
    LINE_FORMAT = '%-7s %-7.2f %-7.2f'

    data = open(setup, 'rb').read()
    lines = data.split('\n')[1:-1]
    iodepths = sorted([l.split(',')[0].split('-')[2] for l in lines])
    groups = {depth : {} for depth in iodepths}
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        test = elements[0]
        _fio,_bs,_depth,_zc,_trace = test.split('-')
        if _trace == '1':
            continue
        if _zc == '1':
            continue
        if _bs in ['4M', '2M']:
            continue
        assert _bs == elements[6], "Bad blocksize, did you move things?"
        assert _depth == elements[10], "Bad iodepth, did you move things?"
        iops = float(elements[9])
        copy_cycles = get_trace_value(lines, test, 3)
        perf_cycles = float(elements[4])
        perf_runtime = float(elements[5]) / 1000.0
        perf_cycles = perf_cycles / perf_runtime # should be similar to freq

        copy_cycles_per_io = copy_cycles / (10**3) / float(iops)
        cycles_per_io = perf_cycles / (10**3) / float(iops)
        groups[_depth][_bs] = {'copy' : copy_cycles_per_io,
                               'cpio' : cycles_per_io - copy_cycles_per_io}

    for depth in groups.keys():
        print TITLE_FORMAT % depth
        output.write(TITLE_FORMAT % depth + '\n')
        for bs in sorted(groups[depth].keys(), key = sort_size):
            print LINE_FORMAT % (bs,
                                 groups[depth][bs]['cpio'],
                                 groups[depth][bs]['copy'])
            output.write(LINE_FORMAT % (bs,
                                 groups[depth][bs]['cpio'],
                                 groups[depth][bs]['copy']) + '\n')
    output.close()


def sort_size(k):
    return int(k[:-1]) * (1000 if k[-1] == 'K' else 1000000)



if __name__ == '__main__':
    if len(sys.argv) > 3:
        post_process_bargraph(sys.argv[1], sys.argv[2])
        post_process(sys.argv[1], sys.argv[3], sys.argv[4])
    else:
        print 'Usage %s <test-base-dir> <out-model> <out-barchart>' % sys.argv[0]
