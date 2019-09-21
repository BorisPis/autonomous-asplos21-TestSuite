#!/usr/bin/python

import sys

def get_other_value(lines, name, val, _type1):
    try:
        _iperf1, _unused, _drop1 = name.split('-')
    except:
        _iperf1, _unused, _drop1, _recsz1 = name.split('-')
    for l in lines:
        elements = l.split(',')
        if len(elements) < 2:
            #print elements
            continue
        lname = elements[0]
        try:
            _iperf, _type, _drop = lname.split('-')
        except:
            _iperf, _type, _drop, _recsz = lname.split('-')
        #print _type, _type1, _drop, _drop1
        if _type == _type1 and _drop == _drop1:
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
        return '{:20}' + '{:^15s}' * 17

    @classmethod
    def format(cls):
        return '{:20}' + '{:^15.2f}' * 17

    @classmethod
    def title(cls):
        #mlx0_tx_tls_dump_bytes mlx0_tx_tls_encrypted_bytes mlx0_tx_bytes mlx0_rx_bytes tls_enc tls_enc_full tls_dec mlx0_tx_tls_dump_bytes_std mlx0_tx_bytes_std mlx0_rx_bytes_std
        return ('test', 'drop', 'metadata', 'tx_thpt', 'rx_thpt', 'full_dec', 'part_dec', 'enc', 'metadata_std', 'tx_thpt_std', 'rx_thpt_std', 'full_dec_std', 'part_dec_std', 'enc_std',
                'tx_thpt_to_tls', 'rx_thpt_to_tls', 'tx_thpt_to_tcp', 'rx_thpt_to_tcp')

    def __init__(self, lines, i):
        l = lines[i]
        elements = l.split(',')
        test = elements[0]
        self.name = elements[0]
        #print test
        try:
            self._iperf, self._type, self._drop = test.split('-')
        except:
            self._iperf, self._type, self._drop, self._recsz = test.split('-')
        assert len(elements) > 2
        self.drop = 0 if float(self._drop) == 0 else float(1) / float(self._drop) * 100.0
        # metadata
        try:
            #pcie overhead
            #self.metadata = 0 if float(elements[4]) == 0 else float(elements[3]) / float(elements[4]) * 100.0
            self.metadata = float(elements[3]) * 8
        except:
            self.metadata = 0

        #tx_thpt
        try:
            self.tx_thpt = float(elements[5]) * 8.0
        except:
            self.tx_thpt = 0

        #rx_thpt
        try:
            self.rx_thpt = float(elements[6]) * 8.0
        except:
            self.rx_thpt = 0

        #tls_enc
        try:
            self.tls_enc = int(elements[7])
        except:
            self.tls_enc = 0

        #tls_enc_full
        try:
            self.tls_enc_full = int(elements[8])
        except:
            self.tls_enc_full = 0

        #tls_dec
        try:
            self.tls_dec = int(elements[9])
        except:
            self.tls_dec = 0

        #metadata_std
        try:
            self.metadata_std = float(elements[10]) * 8
        except:
            self.metadata_std = 0

        #tx_thpt_std
        try:
            self.tx_thpt_std = float(elements[11]) * 8
        except:
            self.tx_thpt_std = 0

        #rx_thpt_std
        try:
            self.rx_thpt_std = float(elements[12]) * 8
        except:
            self.rx_thpt_std = 0

        #tls_enc_std
        try:
            self.tls_enc_std = float(elements[13])
        except:
            self.tls_enc_std = 0

        #tls_enc_full
        try:
            self.tls_enc_full_std = float(elements[14])
        except:
            self.tls_enc_full_std = 0

        #tls_dec
        try:
            self.tls_dec_std = float(elements[15])
        except:
            self.tls_dec_std = 0

        #tx_thpt_improv
        try:
            self.tx_thpt_to_tls = float(get_other_value(lines, test, 5, "1")) * 8.0
        except:
            self.tx_thpt_to_tls = 0

        #rx_thpt_improv
        try:
            self.rx_thpt_to_tls = float(get_other_value(lines, test, 6, "1")) * 8.0
        except:
            self.rx_thpt_to_tls = 0

        #tx_thpt_to_opt
        try:
            self.tx_thpt_to_tcp = float(get_other_value(lines, test, 5, "0")) * 8.0
        except:
            self.tx_thpt_to_tcp = 0

        #rx_thpt_improv
        try:
            self.rx_thpt_to_tcp = float(get_other_value(lines, test, 6, "0")) * 8.0
        except:
            self.rx_thpt_to_tcp = 0

    def __repr__(self):
        return Exp.format().format(
                self.name, self.drop, self.metadata, self.tx_thpt,
                self.rx_thpt, self.tls_dec, self.tls_enc, self.tls_enc_full,
                self.metadata_std, self.tx_thpt_std, self.rx_thpt_std,
                self.tls_dec_std, self.tls_enc_std, self.tls_enc_full_std,
                self.tx_thpt_to_tls, self.rx_thpt_to_tls,
                self.tx_thpt_to_tcp, self.rx_thpt_to_tcp
)

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
        try:
            _iperf,_type,_drop = test.split('-')
        except:
            _iperf,_type,_drop,_recsz = test.split('-')

        print test
        exps.append(Exp(lines, i))

    print Exp.format_title().format(*Exp.title())
    of.write(Exp.format_title().format(*Exp.title()) + '\n')
    for e in sorted(exps, key = lambda x : x.drop):
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
