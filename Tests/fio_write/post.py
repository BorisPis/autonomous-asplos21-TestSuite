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
        assert _fio == 'fio_write', _fio
        assert _fio1 == 'fio_write', _fio1
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
        return '{:20}' + '{:^15s}' * 10

    @classmethod
    def format(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return '{:20}' + '{:^15.2f}' * 10

    @classmethod
    def title(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return ('test', 'tx_crc_cyc', 'crc_cyc', 'opcyc', 'opcyc_nocpy', 'opcyc_nocrc', 'opcyc_no', 'iops', 'nocpy_iops', 'nocrc_iops', 'no_iops')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        self._fio, self._bs, self._depth, self._zcrc, self._zc, self._trace = test.split('-')
        assert len(elements) > 2
        assert self._zcrc == '0' and self._zc == '0' and self._trace == '0', "crc %s zc %s trace %s" % (self._zcrc, self._zc, self._trace)
        self.tx_crc_cycles = norm_cyc(get_trace_value(lines, test, 3, trace = '1'))
        self.crc_cycles  = norm_cyc(get_trace_value(lines, test, 14, trace = '1'))
        self.perf_cycles = float(elements[4]) # op_cycles
        self.perf_runtime = norm_runtime(float(elements[5]) / 1000.0)
        #print '#### %s %20d %10d %10d' % (test, self.perf_cycles, self.perf_runtime, self.perf_cycles / self.perf_runtime)
        self.op_cycles = norm_cyc(self.perf_cycles / self.perf_runtime) # should be similar to freq
        print self.tx_crc_cycles, self.op_cycles
        print self.op_cycles
        self.zc = elements[7]
        assert self.zc == self._zc
        self.tx_crc = self.tx_crc_cycles / self.op_cycles * 100.0
        self.iops = float(elements[9])
        self.nocpy_op, self.nocrc_op, self.nocpy_iops, self.nocrc_iops, self.no_iops, self.no = 0, 0, 0, 0, 0, 0
        #self.nocpy_iops = get_trace_value(lines, test, 9, zc = '1', trace = '0')
        #self.nocpy_cycles = norm_cyc(get_trace_value(lines, test, 4, zc = '1', trace = '0'))
        #self.nocpy_runtime = norm_runtime(get_trace_value(lines, test, 5, zc = '1', trace = '0') / (10**3))
        #self.nocpy_op = self.nocpy_cycles / self.nocpy_runtime

        #self.nocrc_iops = get_trace_value(lines, test, 9, zcrc = '1', trace = '0')
        #self.nocrc_cycles = norm_cyc(get_trace_value(lines, test, 4, zcrc = '1', trace = '0'))
        #self.nocrc_runtime = norm_runtime(get_trace_value(lines, test, 5, zcrc = '1', trace = '0') / (10**3))
        #self.nocrc_op = self.nocrc_cycles / self.nocrc_runtime

        #self.no_iops = get_trace_value(lines, test, 9, zc = '1', zcrc = '1', trace = '0')
        #self.no_cycles = norm_cyc(get_trace_value(lines, test, 4, zc = '1', zcrc = '1', trace = '0'))
        #self.no_runtime = norm_runtime(get_trace_value(lines, test, 5, zc = '1', zcrc = '1', trace = '0') / (10**3))
        #self.no = self.no_cycles / self.no_runtime
        ##self.no = self.nocrc_op = self.nocpy_op = self.op_cycles = norm_cyc(2 * (10**9))

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
                self.name, self.tx_crc_cycles, self.crc_cycles, self.op_cycles,
                self.nocpy_op, self.nocrc_op, self.no,
                self.iops, self.nocpy_iops, self.nocrc_iops, self.no_iops)

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

    print '############################################################\n' * 3
    for e in sorted(exps, key = lambda x : x.bs):
        if e.iodepth == '8192':
            print ('%-5d' + '%9.2f' * 4) % (e.bs, e.no / e.no_iops, e.nocpy_op / e.nocpy_iops, e.nocrc_op / e.nocrc_iops, e.op_cycles / e.iops)

if __name__ == '__main__':
    if len(sys.argv) > 2:
        post_process2(sys.argv[1], sys.argv[2])
    else:
        print 'Usage %s <test-base-dir> <out-model2>' % sys.argv[0]
