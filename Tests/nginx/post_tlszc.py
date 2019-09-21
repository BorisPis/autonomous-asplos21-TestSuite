#!/usr/bin/python

import sys

def name_split(name):
    offload=3
    try: # before tls
        nginx, zc, cores, conns, size = name.split('-')
    except:
        nginx, zc, cores, conns, size, offload = name.split('-')
    return nginx, zc, cores, conns, size, offload


def get_other_value(lines, name, val, target_zc = '1', target_offload = '3'):
    nginx, zc, cores, conns, size, offload = name_split(name)
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _nginx, _zc, _cores, _conns, _size, _offload = name_split(lname)
        if _zc == str(target_zc) and _cores == cores and _conns == conns and\
                _size == size and _offload == str(target_offload):
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
        return '#{:23},' + '{:>10s},' + '{:>14s},' + '{:>17s},' + '{:>10s},' + '{:>10s},' + '{:>13s},' + '{:>16s},' + '{:>10s},' * 5 + '{:>13s},' + '{:>16s},' + '{:>10s},'

    @classmethod
    def format(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return '{:24},' + '{:>10d},' + '{:>14d},' + '{:>17d},' + '{:>10d},' + '{:>10.2f},' + '{:>13.2f},' + '{:>16.2f},' + '{:>10.2f},' * 5 + '{:>13.2f},' + '{:>16.2f},' + '{:>10.2f},'

    @classmethod
    def title(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return ('test', 'cpu_https', 'cpu_https_off', 'cpu_https_off_zc', 'cpu_http', 'bw_https', 'bw_https_off', 'bw_https_off_zc', 'bw_http', 'conns', 'cores', 'size', 'https_std', 'https_off_std', 'https_off_zc_std', 'http_std')

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
        self.bw_https        = float(elements[8]) * float(8) / (10**9)
        self.bw_https_off    = get_other_value(lines, test, 8, 0, 1) * float(8) / (10**9)
        self.bw_https_off_zc = get_other_value(lines, test, 8, 0, 2) * float(8) / (10**9)
        self.bw_http         = get_other_value(lines, test, 8, 0, 3) * float(8) / (10**9)
        #self.bw_https        = float(elements[1])
        #self.bw_https_off    = get_other_value(lines, test, 1, 0, 1)
        #self.bw_https_off_zc = get_other_value(lines, test, 1, 0, 2)
        #self.bw_http         = get_other_value(lines, test, 1, 0, 3)
        self.bw_https_std        = float(elements[9]) * float(8) / (10**9) / self.bw_https * 100.0
        self.bw_https_off_std    = get_other_value(lines, test, 9, 0, 1) * float(8) / (10**9) / self.bw_https_off * 100.0
        self.bw_https_off_zc_std = get_other_value(lines, test, 9, 0, 2) * float(8) / (10**9) / self.bw_https_off_zc * 100.0
        self.bw_http_std         = get_other_value(lines, test, 9, 0, 3) * float(8) / (10**9) / self.bw_http * 100.0
        self.cpu_https = self.cpu_https_off = self.cpu_https_off_zc = self.cpu_http = 0
        for j in range(12, 12 + self.cores):
            self.cpu_https        += int(float(elements[j]))
            self.cpu_https_off    += int(get_other_value(lines, test, j, 0, 1))
            self.cpu_https_off_zc += int(get_other_value(lines, test, j, 0, 2))
            self.cpu_http         += int(get_other_value(lines, test, j, 0, 3))
        print (self.name,
                self.cpu_https, self.cpu_https_off, self.cpu_https_off_zc, self.cpu_http,
                self.bw_https, self.bw_https_off, self.bw_https_off_zc, self.bw_http,
                self.conns, self.cores, self.size,
                self.bw_https_std, self.bw_https_off_std, self.bw_https_off_zc_std, self.bw_http_std,
               )

    def __repr__(self):
        return Exp.format().format(
                self.name,
                self.cpu_https, self.cpu_https_off, self.cpu_https_off_zc, self.cpu_http,
                self.bw_https, self.bw_https_off, self.bw_https_off_zc, self.bw_http,
                self.conns, self.cores, self.size,
                self.bw_https_std, self.bw_https_off_std, self.bw_https_off_zc_std, self.bw_http_std,
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
