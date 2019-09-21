#!/usr/bin/python

import sys

def name_split(name):
    offload=3
    nvmetlso=0
    try: # before tls
        nginx, zc, cores, conns, size = name.split('-')
    except:
        try: # before nvmetls
            nginx, zc, cores, conns, size, offload = name.split('-')
        except:
            nginx, zc, cores, conns, size, offload, nvmetlso = name.split('-')
    return nginx, zc, cores, conns, size, offload, nvmetlso


def get_other_value(lines, name, val, target_zc = '1', target_offload = '3', target_nvmetlso = '1'):
    nginx, zc, cores, conns, size, offload, nvmetlso = name_split(name)
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _nginx, _zc, _cores, _conns, _size, _offload, _nvmetlso = name_split(lname)
        if _zc == str(target_zc) and _cores == cores and _conns == conns and\
                _size == size and _offload == str(target_offload) and\
                _nvmetlso == str(target_nvmetlso):
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
        return '#{:25},' + '{:>13s},' * 2 + '{:>11s},' * 2 + '{:>6s},' * 2 + '{:>12s},' + '{:>7s},' + '{:>11s},'

    @classmethod
    def format(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return '{:26},'+ '{:>13d},' * 2 + '{:>11.2f},' * 2 + '{:>6d},' * 2 + '{:>12d},' + '{:>7.2f},' + '{:>11.2f},'

    @classmethod
    def title(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        #return ('test', 'cpu_baseline', 'cpu_offload', 'bw_baseline', 'bw_offload', 'conns', 'cores', 'size', 'bw_std', 'bw_off_std')
        return ('test', 'cpu_baseline', 'cpu_offload', 'wrk_tps', 'wrk_tps_off', 'conns', 'cores', 'size', 'bw_std', 'bw_off_std')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        _nginx, self.zc, self.cores, self.conns, self.size, self.offload, self.nvmetlso = name_split(test)
        self.cores = int(self.cores)
        self.conns = int(self.conns)
        self.size = int(self.size)
        self.offload = int(self.offload)
        self.nvmetlso = int(self.nvmetlso)
        assert len(elements) > 2

        # bandwidth based on TPS * size
        self.wrk_tps    = float(elements[4])
        try:
            self.wrk_tps_zc = get_other_value(lines, test, 4, 1, 1) / 1.0
            if self.wrk_tps_zc == None:
                self.wrk_tps_zc = 0
        except:
            self.wrk_tps_zc = get_other_value(lines, test, 4, 1, 2) / 1.0
            if self.wrk_tps_zc == None:
                self.wrk_tps_zc = 0
        self.wrk_tps_std    = float(elements[5]) / self.wrk_tps * 100.0
        try:
            self.wrk_tps_zc_std = get_other_value(lines, test, 5, 1, 1) / self.wrk_tps_zc
            if self.wrk_tps_zc_std == None:
                self.wrk_tps_zc_std = 0
        except:
            self.wrk_tps_zc_std = get_other_value(lines, test, 5, 1, 2) / self.wrk_tps_zc * 100.0
            if self.wrk_tps_zc_std == None:
                self.wrk_tps_zc_std = 0
        #self.bw_baseline          = self.wrk_tps    * self.size * 8 / float(10**9)
        #self.bw_offload           = self.wrk_tps_zc * self.size * 8 / float(10**9)
        self.bw_baseline          = self.wrk_tps
        self.bw_offload           = self.wrk_tps_zc
        self.bw_baseline_std      = self.wrk_tps_std
        self.bw_offload_std       = self.wrk_tps_zc_std

        ## bandwidth based on port bytes
        #self.bw_baseline        = float(elements[8]) / float(10**9) * 8
        #bw = 0
        #try:
        #    bw = get_other_value(lines, test, 8, 1, 1) / float(10**9) * 8
        #except:
        #    bw = get_other_value(lines, test, 8, 1, 2) / float(10**9) * 8
        #self.bw_offload = bw

        #self.bw_baseline_std = float(elements[9]) / float(10**9) * 8 / self.bw_baseline
        #try:
        #    bw_std = get_other_value(lines, test, 9, 1, 1) / float(10**9) * 8
        #except:
        #    bw_std = get_other_value(lines, test, 9, 1, 2) / float(10**9) * 8
        #self.bw_offload_std = bw_std / self.bw_offload


        self.cpu_baseline = self.cpu_offload = 0
        for j in range(12, 12 + self.cores):
            self.cpu_baseline     += int(float(elements[j]))
            cpu = 0
            try:
                cpu = get_other_value(lines, test, j, 1, 1) / 1.0
            except:
                cpu = get_other_value(lines, test, j, 1, 2) / 1.0
            self.cpu_offload += int(cpu)
        print (self.name,
                self.cpu_baseline, self.cpu_offload,
                self.bw_baseline, self.bw_offload,
                self.conns, self.cores, self.size,
                self.bw_baseline_std, self.bw_offload_std,
               )

    def __repr__(self):
        return Exp.format().format(self.name,
                self.cpu_baseline, self.cpu_offload,
                self.bw_baseline, self.bw_offload,
                self.conns, self.cores, self.size,
                self.bw_baseline_std, self.bw_offload_std,
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
        _nginx, _zc, _cores, _conns, _size, _offload, _nvmetlso = name_split(test)
        if _zc != '0':
            continue
        if _offload != '0':
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
