#!/usr/bin/python

import sys

def name_split(name):
    offload=3
    nvmetlso=0
    zcrc=0
    try: # before tls
        nginx, zc, cores, conns, size = name.split('-')
    except:
        try: # before nvmetls
            nginx, zc, cores, conns, size, offload = name.split('-')
        except:
            try: # before nvmetls latency
                nginx, zc, cores, conns, size, offload, nvmetlso = name.split('-')
            except:
                nginx, _, cores, conns, size, offload, nvmetlso, zc, zcrc = name.split('-')
    return nginx, zc, cores, conns, size, offload, nvmetlso, zcrc


def get_other_value(lines, name, val, target_zc = '1', target_offload = '3', target_nvmetlso = '1', target_zcrc = '1'):
    nginx, zc, cores, conns, size, offload, nvmetlso, zcrc = name_split(name)
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        _nginx, _zc, _cores, _conns, _size, _offload, _nvmetlso, _zcrc = name_split(lname)
        if _zc == str(target_zc) and _cores == cores and _conns == conns and\
                _size == size and _offload == str(target_offload) and\
                _nvmetlso == str(target_nvmetlso) and _zcrc == str(target_zcrc):
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
        return '#{:29},' + '{:^15s},' * 7

    @classmethod
    def format(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return '{:30},' + '{:^15.2f},' * 7

    @classmethod
    def title(cls):
        # test cpy_cyc crc_cyc op_cyc iops nocpy_iops nocrc_iops no_iops
        return ('test', 'lat_baseline', 'lat_tls', 'lat_tls_zc', 'lat_tls_zc_zcrc', 'conns', 'cores', 'size')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        _nginx, self.zc, self.cores, self.conns, self.size, self.offload, self.nvmetlso, self.zcrc = name_split(test)
        self.cores = int(self.cores)
        self.conns = int(self.conns)
        self.size = int(self.size)
        self.offload = int(self.offload)
        self.nvmetlso = int(self.nvmetlso)
        assert len(elements) > 2
        #test,bandwidth,cpu,wrk_bw,wrk_tps
        self.lat_base            = float(elements[6])
        self.lat_tls             = get_other_value(lines, test, 6, 0, 2, 1, 0)
        self.lat_tls_zc          = get_other_value(lines, test, 6, 1, 2, 1, 0)
        self.lat_tls_zc_zcrc     = get_other_value(lines, test, 6, 1, 2, 1, 1)
        self.std_lat_base            = float(elements[7])
        self.std_lat_tls             = get_other_value(lines, test, 7, 0, 2, 1, 0)
        self.std_lat_tls_zc          = get_other_value(lines, test, 7, 1, 2, 1, 0)
        self.std_lat_tls_zc_zcrc     = get_other_value(lines, test, 7, 1, 2, 1, 1)

        print (self.name,
                self.lat_base, self.lat_tls, self.lat_tls_zc, self.lat_tls_zc_zcrc,
                self.conns, self.cores, self.size,
                self.std_lat_base, self.std_lat_tls, self.std_lat_tls_zc, self.std_lat_tls_zc_zcrc,
               )

    def __repr__(self):
        return Exp.format().format(self.name,
                self.lat_base, self.lat_tls, self.lat_tls_zc, self.lat_tls_zc_zcrc,
                self.conns, self.cores, self.size)

def print_tex_avg_only2(exps):
    form_title = '{:^12}' + '& {:^20}' + '& {:^27}' * 3 + '\\\\'
    #form = '{:^15}' + '& {:>8.2f} ({:<4.2f})' * 4 + '\\\\'
    form = '{:^12}' + '& {:>5d}\,$_{{\\pm {:^4.1f}}}$ ' + '& {:>5d}\,$_{{\\pm {:^4.1f}}}\,$({:<4.2f}) ' * 3 + '\\\\'
    title =  ('size', 'base', '+TLS', '+copy', '+CRC')
    print form_title.format(*title)
    for e in sorted(exps, key = lambda x : x.size):
        a = (str(e.size/1024) + 'K',
             int(e.lat_base), float(e.std_lat_base) / float(e.lat_base) * 100.0,
             int(e.lat_tls),         float(e.std_lat_tls) / float(e.lat_tls) * 100.0, e.lat_tls / e.lat_base,
             int(e.lat_tls_zc),      float(e.std_lat_tls_zc) / float(e.lat_tls_zc) * 100.0, e.lat_tls_zc / e.lat_base,
             int(e.lat_tls_zc_zcrc), float(e.std_lat_tls_zc_zcrc) / float(e.lat_tls_zc_zcrc) * 100.0, e.lat_tls_zc_zcrc / e.lat_base
                )
        print form.format(*a)

def print_tex_avg_only(exps):
    form_title = '{:^12}' + '& {:^12}' * 4 + '\\\\'
    #form = '{:^15}' + '& {:>8.2f} ({:<4.2f})' * 4 + '\\\\'
    form = '{:^12}' + '& {:^11f} ' + '& {:^5d}({:<4.2f}) ' * 3 + '\\\\'
    title =  ('size', 'base', '+TLS', '+copy', '+CRC')
    print form_title.format(*title)
    for e in sorted(exps, key = lambda x : x.size):
        a = (str(e.size/1024) + 'K',
             int(e.lat_base),
             int(e.lat_tls), e.lat_tls / e.lat_base,
             int(e.lat_tls_zc), e.lat_tls_zc / e.lat_base,
             int(e.lat_tls_zc_zcrc), e.lat_tls_zc_zcrc / e.lat_base
                )
        print form.format(*a)
        a = (str(e.size/1024) + 'K',
             float(e.std_lat_base / e.lat_base),
             int(e.std_lat_tls), e.std_lat_tls / e.lat_tls,
             int(e.std_lat_tls_zc), e.std_lat_tls_zc / e.lat_tls_zc,
             int(e.std_lat_tls_zc_zcrc), e.std_lat_tls_zc_zcrc / e.lat_tls_zc_zcrc
                )
        print form.format(*a)

def post_process2(setup = 'setup.csv', output = 'result.csv', to_latex = True):
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
        _nginx, _zc, _cores, _conns, _size, _offload, _nvmetlso, _zcrc = name_split(test)
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
    if to_latex:
        #print_tex(exps)
        print_tex_avg_only(exps)
        print_tex_avg_only2(exps)

if __name__ == '__main__':
    if len(sys.argv) > 2:
        post_process2(sys.argv[1], sys.argv[2])
    else:
        print 'Usage %s <test-base-dir> <out-model2>' % sys.argv[0]
