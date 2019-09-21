#!/usr/bin/python

import sys

def get_trace_value(lines, name, val, zc = '0', zcrc = '0', trace = '1', offload = '0'):
    assert name.endswith('-0'), "Searching for value for test with trace"
    _fio1, _bs1, _depth1, _zcrc1, _zc1, _trace1, _offload1= name.split('-')
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _fio, _bs, _depth, _zcrc, _zc, _trace, _offload = lname.split('-')
        assert _fio == 'fio'
        assert _fio1 == 'fio'
        if _trace == trace and _zc == zc and _zcrc == zcrc and _bs == _bs1 and _depth == _depth1 and\
                offload == _offload:
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
        return '{:20}' + '{:^25s}' * 8

    @classmethod
    def format(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return '{:20}' + '{:^25.2f}' * 8

    @classmethod
    def title(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return ('test',
                'rd_avg_lat', 'rd_p95_lat',
                'tls_rd_avg_lat', 'tls_rd_p95_lat',
                'cpy_tls_rd_avg_lat', 'cpy_tls_rd_p95_lat',
                'crc_cpy_tls_rd_avg_lat', 'crc_cpy_tls_rd_p95_lat')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        self._fio, self._bs, self._depth, self._zcrc, self._zc, self._trace, self._offload = test.split('-')
        assert len(elements) > 2
        assert self._zcrc == '0' and self._zc == '0' and self._trace == '0' and self._offload == '0',\
            "crc %s zc %s trace %s tls-offload %s" % (self._zcrc, self._zc, self._trace, self._offload)
        self.rd_avg_lat = float(elements[3])
        self.rd_p95_lat = float(elements[4])
        self.tls_rd_avg_lat = get_trace_value(lines, test, 3, trace = '0', offload = '1')
        self.tls_rd_p95_lat = get_trace_value(lines, test, 4, trace = '0', offload = '1')
        self.cpy_tls_rd_avg_lat = get_trace_value(lines, test, 3, zc = '1', trace = '0', offload = '1')
        self.cpy_tls_rd_p95_lat = get_trace_value(lines, test, 4, zc = '1', trace = '0', offload = '1')
        self.crc_cpy_tls_rd_avg_lat = get_trace_value(lines, test, 3, zc = '1', zcrc = '1', trace = '0', offload = '1')
        self.crc_cpy_tls_rd_p95_lat = get_trace_value(lines, test, 4, zc = '1', zcrc = '1', trace = '0', offload = '1')

        self.perf_runtime = norm_runtime(float(elements[5]) / 1000.0)

        self.zc = elements[7]
        assert self.zc == self._zc
        self.iops = float(elements[9])
        self.tls_iops = get_trace_value(lines, test, 9, trace = '0', offload = '1')
        self.cpy_tls_cycles = get_trace_value(lines, test, 4, zc = '1', trace = '0', offload = '1')
        self.crc_cpy_tls_cycles = get_trace_value(lines, test, 4, zc = '1', zcrc = '1', trace = '0', offload = '1')

        # useless stuff?
        bs = elements[6]
        self.bs = int(bs[:-1]) if bs[-1] == 'K' else int(bs[:-1]) * 1024
        self.iodepth = elements[10]

    def __repr__(self):
        return Exp.format().format(
                self.name,
                self.rd_avg_lat, self.rd_p95_lat,
                self.tls_rd_avg_lat, self.tls_rd_p95_lat,
                self.cpy_tls_rd_avg_lat, self.cpy_tls_rd_p95_lat,
                self.crc_cpy_tls_rd_avg_lat, self.crc_cpy_tls_rd_p95_lat
                )

def print_tex(exps):
    form_title = '{:^15}' + '& {:^10}' * 8 + '\\\\'
    form = '{:^15}' + '& {:^10.2f}' * 8 + '\\\\'
    title =  tuple(['Size/Offload'] + ['avg', 'p95'] * 4)
    print form_title.format(*title)
    for e in sorted(exps, key = lambda x : x.bs):
        a = (str(e.bs) + 'K',
             e.rd_avg_lat, e.rd_p95_lat,
             e.tls_rd_avg_lat, e.tls_rd_p95_lat,
             e.cpy_tls_rd_avg_lat, e.cpy_tls_rd_p95_lat,
             e.crc_cpy_tls_rd_avg_lat, e.crc_cpy_tls_rd_p95_lat
                )
        print form.format(*a)

def print_tex_avg_only(exps):
    form_title = '{:^15}' + '& {:^15}' * 4 + '\\\\'
    form = '{:^15}' + '& {:>8.2f} ({:<4.2f})' * 4 + '\\\\'
    title =  tuple(['Size/Offload'] + ['avg'] * 4)
    print form_title.format(*title)
    for e in sorted(exps, key = lambda x : x.bs):
        a = (str(e.bs) + 'K',
             e.rd_avg_lat, 1,
             e.tls_rd_avg_lat, e.tls_rd_avg_lat / e.rd_avg_lat,
             e.cpy_tls_rd_avg_lat, e.cpy_tls_rd_avg_lat / e.rd_avg_lat,
             e.crc_cpy_tls_rd_avg_lat, e.crc_cpy_tls_rd_avg_lat / e.rd_avg_lat
                )
        print form.format(*a)

def post_process_latency(setup = 'setup.csv', output = 'model.lat.csv', to_latex = True):
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
        _fio,_bs,_depth,_zcrc,_zc,_trace,_offload = test.split('-')
        #print _fio,_bs,_depth,_zcrc,_zc,_trace,_offload
        if _zcrc != '0' or _zc != '0' or _trace != '0' or _offload != '0':
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
        if e.iodepth == '1':
            print ('%-5d' + '%9.2f' * 4) % (e.bs, e.rd_avg_lat, e.tls_rd_avg_lat, e.cpy_tls_rd_avg_lat, e.crc_cpy_tls_rd_avg_lat)
    if to_latex:
        #print_tex(exps)
        print_tex_avg_only(exps)


if __name__ == '__main__':
    if len(sys.argv) > 2:
        post_process_latency(sys.argv[1], sys.argv[2])
    else:
        print 'Usage %s <test-base-dir> <out-model2>' % sys.argv[0]
