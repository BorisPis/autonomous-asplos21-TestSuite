#!/usr/bin/python

import sys

def name_split(test):
    offload='0'
    trace='0'
    try: # before tls
        iperf, bs, trace, isenc, offload = test.split('-')
    except:
        try:
            iperf, bs, trace, isenc = test.split('-')
        except:
            iperf, bs, isenc = test.split('-')
    return iperf, bs, trace, isenc, offload

def get_trace_value(lines, name, val, isenc = '0', trace = '1', offload = '0'):
    #assert name.endswith('-%s-0' % (isenc, offload)), "Searching for value for test with trace"
    _iperf1, _bs1, _trace1, _isenc1, _offload1 = name_split(name)
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _iperf, _bs, _trace, _isenc, _offload = name_split(lname)
        assert _iperf == 'iperf_tx'
        assert _iperf1 == 'iperf_tx'
        if _trace == trace and _bs == _bs1 and _isenc == _isenc1 and\
        _offload == _offload1:
            print ('# %s %s %s' % (name, val, l))
            return float(elements[val])
    return None

def norm_cyc(cyc):
    return cyc

def norm_runtime(runtime):
    #return runtime * 3
    return runtime

class Exp:
    @classmethod
    def format_title(cls):
        return '{:20}' + '{:>16s}' * 4 + '{:>22s}' * 2 + '{:>13s}' * 4

    @classmethod
    def format(cls):
        return '{:20}' + '{:>16.2f}' * 4 + '{:>22.2f}' * 2 + '{:>13.2f}' * 4

    @classmethod
    def title(cls):
        return ('test', 'bs', 'enc_cyc', 'opcyc', 'iperf_thpt', 'enc_per_rec', 'dec_cyc', 'iperf_std', 'opcyc_std', 'enc_cyc_std', 'dec_cyc_std')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        self._iperf, self._bs, self._trace, self._isenc, self.offload = name_split(test)
        assert len(elements) > 2
        self.enc_cycles = norm_cyc(get_trace_value(lines, test, 3, self._isenc, trace = '1'))
        self.perf_cycles = float(elements[4]) # op_cycles
        self.perf_runtime = norm_runtime(float(elements[5]) / 1000.0)
        #print '~~~', self.perf_cycles, self.perf_runtime
        self.dec_cycles = norm_cyc(get_trace_value(lines, test, 7, self._isenc, trace = '1'))
        #print '#### %s %20d %10d %10d' % (test, self.perf_cycles, self.perf_runtime, self.perf_cycles / self.perf_runtime)
        self.op_cycles = norm_cyc(self.perf_cycles / self.perf_runtime) # should be similar to freq
        self.enc = self.enc_cycles / self.op_cycles * 100.0
        self.dec = self.dec_cycles / self.op_cycles * 100.0
        self.throughput = float(elements[6])
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

        self.bs = int(self._bs)
        self.rec =  self.throughput / 8.0 / self.bs
        self.per_rec = self.op_cycles / self.rec
        self.iperf_std = float(elements[8]) / self.throughput * 100.0
        self.opcyc_std = float(elements[9]) / self.op_cycles * 100.0
        try:
            enc_cyc_std = norm_cyc(get_trace_value(lines, test, 10, self._isenc, trace = '1'))
            #print '###', enc_cyc_std, self.enc
            self.enc_std   = enc_cyc_std / self.enc_cycles * 100.0
        except:
            self.enc_std   = 0
        try:
            dec_cyc_std = norm_cyc(get_trace_value(lines, test, 11, self._isenc, trace = '1'))
            self.dec_std   = dec_cyc_std / self.dec_cycles * 100.0
        except:
            self.dec_std   = 0
        print self.name, self.rec * (10**9), self.enc_cycles, self.op_cycles

    def __repr__(self):
        return Exp.format().format(
                self.name, self.bs, self.enc_cycles, self.op_cycles, self.throughput,
                self.per_rec, self.dec_cycles,
                self.iperf_std, self.opcyc_std, self.enc_std, self.dec_std)

def post_process2(setup = 'setup.csv', output = 'model.csv'):
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
        _iperf,_bs,_trace,_isenc,_offload = name_split(test)
        if _trace != '0' or _offload != '0':
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
    #    if e.bs == 16000:
    #        print ('%-5d' + '%9.2f' * 4) % (e.bs, e.no / e.no_iops, e.nocpy_op / e.nocpy_iops, e.nocrc_op / e.nocrc_iops, e.op_cycles / e.iops)


if __name__ == '__main__':
    if len(sys.argv) > 2:
        post_process2(sys.argv[1], sys.argv[2])
    else:
        print 'Usage %s <test-base-dir> <out-model2>' % sys.argv[0]
