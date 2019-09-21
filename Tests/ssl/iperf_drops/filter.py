#!/usr/bin/python
from sys import argv,exit
from os import getenv

def parse_csv(csv_data):
    res = {}
    lines = csv_data.split('\n')
    keys = filter(lambda x: len(x) > 0, lines[0].split(','))[2:]
    tests = [l.split(',')[1] for l in lines[:-1]][1:]
    #print 'Tests:', tests
    #print 'Keys:', keys
    for i in xrange(len(tests)):
        t = tests[i]
        res[t] = {}
        values = lines[i + 1].split(',')
        for j in xrange(len(keys)):
            k = keys[j]
            v = values[j + 2]
            if k != '':
                res[t][k] = v
    return res


def filter_csv(csv, keys):
    csv_data = open(csv, 'rb').read()
    res = parse_csv(csv_data)
    out = []
    line = ''
    # print the headers first
    l = 'test,bandwidth,cpu,' + ','.join(keys)
    out.append(l)
    for test in res.keys():
        l = test
        #print (res[test]['Total_rx_bw']), (res[test]['Total_tx_bw'])
        l += ',%.2f,' % (float(res[test]['Total_rx_bw']) + float(res[test]['Total_tx_bw']))
        l += '%.2f,' % float(res[test]['cpu_total'])
        for k in keys:
            if not k in res[test].keys():
                l += '%s,' % 'Nan'
            else:
                l += '%s,' % res[test][k]
        out.append(l)
    print '\n'.join(out)

if __name__ == '__main__':
    # argv[1] is a directory containing subdirectories with test results
    if1 = getenv("if1")
    if if1 == None:
        print 'Missing environment <if1>'
        exit(1)
    if len(argv) < 2:
        print 'Usage: %s <csv> <filter-file>'
        exit(1)
    if len(argv) < 3:
        keys = ('%s_tx_tls_dump_bytes %s_tx_tls_encrypted_bytes %s_tx_bytes %s_rx_bytes tls_enc tls_enc_full tls_dec %s_tx_tls_dump_bytes_std %s_tx_bytes_std %s_rx_bytes_std tls_enc_std tls_enc_full_std tls_dec_std' % (if1, if1, if1, if1, if1, if1, if1)).split()
    else:
        keys = open(argv[2], 'rb').read().split()
    res = filter_csv(argv[1], keys)
