#!/usr/bin/python
from sys import argv,exit

def sortit(fmodel, fsetup):
    model = open(argv[1], 'rb').read().split('\n')[:-1]
    setup = open(argv[2], 'rb').read().split('\n')[:-1]

    model_names = [lm.split(',')[0] for lm in model[1:]]

    def keys(ls):
        name = ls.split(',')[0]
        #print model_names
        #print name
        assert model_names.index(name) != -1
        return model_names.index(name)

    return [model[0]] + sorted(setup[1:], key=keys)

if __name__ == '__main__':
    # argv[1] is a directory containing subdirectories with test results
    if len(argv) < 2:
        print 'Usage: %s <model> <setup.csv>'
        exit(1)
    model = argv[1]
    setup = argv[2]
    new_setup = sortit(model, setup)
    print '\n'.join(new_setup)

