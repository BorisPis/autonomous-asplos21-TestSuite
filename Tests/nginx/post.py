#!/usr/bin/python

import sys

def name_split(name):
    offload=3
    try: # before tls
        nginx, zc, cores, conns, size = name.split('-')
    except:
        nginx, zc, cores, conns, size, offload = name.split('-')
    return nginx, zc, cores, conns, size, offload


def get_other_value(lines, name, val, target_zc = '1', offload = 3):
    nginx, zc, cores, conns, size, offload = name_split(name)
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _nginx, _zc, _cores, _conns, _size, _offload = name_split(lname)
        if _zc == target_zc and _cores == cores and _conns == conns \
                and _size == size and _offload == offload:
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
        return '#{:20},' + '{:^15s},' * 13

    @classmethod
    def format(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return '{:21},' + '{:^15.2f},' * 13

    @classmethod
    def title(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return ('test', 'wrk_tps', 'wrk_tps_zc', 'cpu', 'cpu_zc', 'bw', 'bw_zc', 'conns', 'cores', 'zc_mult', 'size', 'offload', 'tps_std', 'tps_zc_std')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        _nginx, self.zc, self.cores, self.conns, self.size, self.offload = name_split(test)
        self.cores = int(self.cores)
        self.conns = int(self.conns)
        self.size = int(self.size)
        self.offload = int(self.offload)
        assert len(elements) > 2
        #test,bandwidth,cpu,wrk_bw,wrk_tps
        self.bw     = float(elements[8]) / float(10**9) * 8
        self.bw_zc  = get_other_value(lines, test, 8) / float(10**9) * 8
        if self.bw_zc == None:
            self.bw_zc = 0
        self.wrk_tps    = float(elements[4])
        self.wrk_tps_zc = get_other_value(lines, test, 4)
        if self.wrk_tps_zc == None:
            self.wrk_tps_zc = 0
        self.wrk_tps_std    = float(elements[5]) / self.wrk_tps * 100.0
        self.wrk_tps_zc_std = get_other_value(lines, test, 5) / self.wrk_tps_zc * 100.0
        if self.wrk_tps_zc_std == None:
            self.wrk_tps_zc_std = 0
        self.zc_mult = self.wrk_tps_zc / self.wrk_tps
        self.cpu = self.cpu_zc = 0
        for j in range(12, 12 + self.cores):
            self.cpu    += float(elements[j])
            if self.wrk_tps_zc != 0: # only makes sense when there are zc results
                self.cpu_zc += get_other_value(lines, test, j)
            else:
                self.cpu_zc = 0
        #self.cpu    = float(elements[2]) * 28.0
        #self.cpu_zc = get_other_value(lines, test, 2) * 28.0
        print (self.name, self.wrk_tps, self.wrk_tps_zc,
                self.cpu, self.cpu_zc,
                self.bw, self.bw_zc,
                self.conns, self.cores, self.zc_mult,
                self.size, self.offload,
                self.wrk_tps_std, self.wrk_tps_zc_std)

    def __repr__(self):
        return Exp.format().format(
                self.name, self.wrk_tps, self.wrk_tps_zc,
                self.cpu, self.cpu_zc,
                self.bw, self.bw_zc,
                self.conns, self.cores, self.zc_mult,
                self.size, self.offload,
                self.wrk_tps_std, self.wrk_tps_zc_std,
        )

def post_process2(setup = 'setup.csv', output = 'result.csv'):
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
        _nginx, _zc, _cores, _conns, _size, _offload = name_split(test)
        if _zc != '0':
            continue
        print test
        exps.append(Exp(lines, i))

    print Exp.format_title().format(*Exp.title())
    of.write(Exp.format_title().format(*Exp.title()) + '\n')
    for e in sorted(sorted(exps, key = lambda x : x.conns), key = lambda x:x.cores):
        #print e.__repr__()
        print repr(e)
        of.write(repr(e) + '\n')
    of.close()

    #print '############################################################\n' * 3
    #for e in sorted(exps, key = lambda x : x.bs):
    #    if e.iodepth == '8192':
    #        print ('%-5d' + '%9.2f' * 4) % (e.bs, e.no / e.no_iops, e.nocpy_op / e.nocpy_iops, e.nocrc_op / e.nocrc_iops, e.op_cycles / e.iops)

if __name__ == '__main__':
    if len(sys.argv) > 2:
        post_process2(sys.argv[1], sys.argv[2])
    else:
        print 'Usage %s <test-base-dir> <out-model2>' % sys.argv[0]
