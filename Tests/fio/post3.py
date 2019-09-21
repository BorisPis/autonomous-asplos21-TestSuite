#!/usr/bin/python

import sys

def get_trace_value(lines, name, val, zc = '0', zcrc = '0', trace = '1'):
    assert name.endswith('-0'), "Searching for value for test with trace"
    _fio1, _bs1, _depth1, _zcrc1, _zc1, _trace1 = name.split('-')
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _fio, _bs, _depth, _zcrc, _zc, _trace = lname.split('-')
        assert _fio == 'fio'
        assert _fio1 == 'fio'
        if _trace == trace and _zc == zc and _zcrc == zcrc and _bs == _bs1 and _depth == _depth1:
            print ('# %s %s %s' % (name, val, l))
            return float(elements[val])
    return None

def norm_cyc(cyc):
    return cyc / (10**3)

def norm_runtime(runtime):
    #return runtime * 3
    return runtime

class Exp:
    @classmethod
    def format_title(cls):
        # test cpy_cyc crc_cyc opcyc op_cyc_nocpy opcyc_nocrc opcyc_no iops nocpy_iops nocrc_iops no_iops
        return '{:23}' + '{:>10s}' * 3 + '{:>10}' * 9 + '{:>9}' * 4

    @classmethod
    def format(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return '{:23}' + '{:>10d}' * 3 + '{:>10.2f}' * 9 + '{:>9.2f}' * 4

    @classmethod
    def title(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return ('test', 'cpy_cyc', 'crc_cyc', 'opcyc', 'opc_nocpy', 'opc_nocrc', 'opc_no', 'iops', 'ncpy_iops', 'ncrc_iops', 'n_iops', 'iodepth', 'cpu_util', 'cpy_std', 'crc_std', 'op_std', 'cpu_std')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        self._fio, self._bs, self._depth, self._zcrc, self._zc, self._trace = test.split('-')
        assert len(elements) > 2
        assert self._zcrc == '0' and self._zc == '0' and self._trace == '0', "crc %s zc %s trace %s" % (self._zcrc, self._zc, self._trace)
        self._depth = int(self._depth)
        self.copy_cycles       = int(norm_cyc(get_trace_value(lines, test, 3, trace = '1')))
        self.cpy_cycles_std    = norm_cyc(get_trace_value(lines, test, 16, trace = '1')) / self.copy_cycles * 100.0
        self.crc_cycles        = int(norm_cyc(get_trace_value(lines, test, 14, trace = '1')))
        self.crc_cycles_std    = norm_cyc(get_trace_value(lines, test, 17, trace = '1')) / self.crc_cycles * 100.0
        self.cpu_util          = float(elements[15]) / 100.0
        self.cpu_util_std      = float(elements[19]) / 100.0 / self.cpu_util * 100.0

        self.perf_cycles = float(elements[4]) #* self.cpu_util # op_cycles
        self.perf_runtime = norm_runtime(float(elements[5]) / 1000.0)
        #print '#### %s %20d %10d %10d' % (test, self.perf_cycles, self.perf_runtime, self.perf_cycles / self.perf_runtime)
        self.op_cycles         = int(norm_cyc(self.perf_cycles / self.perf_runtime)) # should be similar to freq
        self.op_cycles_std     = norm_cyc(float(elements[18]) / self.perf_runtime) / self.op_cycles * 100.0
        self.zc = elements[7]
        assert self.zc == self._zc
        self.copy = self.copy_cycles / self.op_cycles * 100.0
        self.iops = int(float(elements[9]))

        try:
            self.nocpy_iops = int(get_trace_value(lines, test, 9, zc = '1', trace = '0'))
            self.nocpy_cycles = int(norm_cyc(get_trace_value(lines, test, 4, zc = '1', trace = '0')))
            self.nocpy_runtime = int(norm_runtime(get_trace_value(lines, test, 5, zc = '1', trace = '0') / (10**3)))
            self.nocpy_op = int(self.nocpy_cycles / self.nocpy_runtime)
        except:
            self.nocpy_iops = 0
            self.nocpy_cycles = 0
            self.nocpy_runtime = 0
            self.nocpy_op = 0

        try:
            self.nocrc_iops = int(get_trace_value(lines, test, 9, zcrc = '1', trace = '0'))
            self.nocrc_cycles = int(norm_cyc(get_trace_value(lines, test, 4, zcrc = '1', trace = '0')))
            self.nocrc_runtime = int(norm_runtime(get_trace_value(lines, test, 5, zcrc = '1', trace = '0') / (10**3)))
            self.nocrc_op = int(self.nocrc_cycles / self.nocrc_runtime)
        except:
            self.nocrc_iops = 0
            self.nocrc_cycles = 0
            self.nocrc_runtime = 0
            self.nocrc_op = 0

        try:
            self.no_iops = int(get_trace_value(lines, test, 9, zc = '1', zcrc = '1', trace = '0'))
            self.no_cycles = int(norm_cyc(get_trace_value(lines, test, 4, zc = '1', zcrc = '1', trace = '0')))
            self.no_runtime = int(norm_runtime(get_trace_value(lines, test, 5, zc = '1', zcrc = '1', trace = '0') / (10**3)))
            self.no = int(self.no_cycles / self.no_runtime)
            #self.no = self.nocrc_op = self.nocpy_op = self.op_cycles = norm_cyc(2 * (10**9))
        except:
            self.no_iops = 0
            self.no_cycles = 0
            self.no_runtime = 0
            self.no = 0
            #self.no = 0

        # useless stuff?
        bs = elements[6]
        self.bs = int(bs[:-1]) if bs[-1] == 'K' else int(bs[:-1]) * 1024
        self.iodepth = elements[10]
        #self.bw = float(elements[8]) / 1000.0
        #self.cycles_per_io = op_cycles / iops
        #self.copy_per_io = copy_cycles / iops
        #self.rx_bytes = float(elements[11]) / (10**6)
        #self.rx_packets = float(elements[12]) / (10**3)
        #self.rx_packets = get_trace_value(lines, test, 12) / (10**3)

    def __repr__(self):
        return Exp.format().format(
                self.name, self.copy_cycles, self.crc_cycles, self.op_cycles,
                self.nocpy_op, self.nocrc_op, self.no,
                self.iops, self.nocpy_iops, self.nocrc_iops, self.no_iops,
                self._depth, self.cpu_util,
                self.cpy_cycles_std, self.crc_cycles_std, self.op_cycles_std,
                self.cpu_util_std)

def post_process2(setup = 'setup.csv', output = 'model2.csv'):
    of = open(output, 'wb')
    data = open(setup, 'rb').read()
    lines = data.split('\n')[1:]
    exps = []
    for i in xrange(len(lines)):
        l = lines[i]
        elements = l.split(',')
        if len(elements) < 2:
            continue
        test = elements[0]
        _fio,_bs,_depth,_zcrc,_zc,_trace = test.split('-')
        if _zcrc != '0' or _zc != '0' or _trace != '0':
            continue
        print test
        exps.append(Exp(lines, i))

    print Exp.format_title().format(*Exp.title())
    of.write(Exp.format_title().format(*Exp.title()) + '\n')
    for e in sorted(exps, key = lambda x : x.bs):
        #print e.__repr__()
        print repr(e)
        of.write(repr(e) + '\n')
    of.close()

    #print '############################################################\n' * 3
    #for e in sorted(exps, key = lambda x : x.bs):
    #    if e.iodepth == '8192':
    #        print ('%-5d' + '%9.2f' * 4) % (e.bs, e.no / e.no_iops, e.nocpy_op / e.nocpy_iops, e.nocrc_op / e.nocrc_iops, e.op_cycles / e.iops)


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
        print test
        _fio,_bs,_depth,_zcrc,_zc,_trace = test.split('-')
        if _trace == '1':
            continue
        #if _bs in ['4M', '2M']:
        #    continue
        #copy_cycles = float(elements[3])
        copy_cycles = get_trace_value(lines, test, 3)
        perf_cycles = float(elements[4])
        perf_runtime = float(elements[5]) / 1000.0
        bs = elements[6]
        bs = int(bs[:-1]) if bs[-1] == 'K' else int(bs[:-1]) * 1024
        zc = elements[7]
        assert zc == _zc
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
            copy_perf_cycles = get_trace_value(lines, test, 4)
            copy_perf_runtime = get_trace_value(lines, test, 5) / 1000.0
            print 'copy_perf_runtime', get_trace_value(lines, test, 5)
            copy_perf_cycles = (copy_perf_cycles / copy_perf_runtime)
            copy_perf_iops = get_trace_value(lines, test, 9)
            copy_perf_cycles_per_io = (copy_perf_cycles / copy_perf_iops) / (10**3)
            copy_perf_copy_cycles = get_trace_value(lines, test, 3)
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

if __name__ == '__main__':
    if len(sys.argv) > 2:
        post_process2(sys.argv[1], sys.argv[2])
    else:
        print 'Usage %s <test-base-dir> <out-model2>' % sys.argv[0]
