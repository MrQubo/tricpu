#!/usr/bin/env python
# -*- coding: utf-8 -*-


def str2trits(s):
    return [{'-': -1, '0': 0, '+': 1}[c] for c in s]


def trits2bits(trits):
    bits = []
    for trit in trits:
        if trit == -1:
            bits += [1, 1]
        elif trit == 0:
            bits += [0, 0]
        elif trit == 1:
            bits += [0, 1]
        else:
            assert False
    return bits


def bits2str(bits):
    return ''.join({0: '0', 1: '1'}[x] for x in bits)


def main():
    from sys import argv
    if len(argv) == 3:
        in_f = open(argv[1], 'r')
        out_f = open(argv[2], 'w')
    elif len(argv) == 1:
        from sys import stdin, stdout
        in_f = stdin
        out_f = stdout
    else:
        print(f'Usage: {argv[0]} [in_filename out_filename]')
        exit(1)

    with out_f, in_f:
        for line in in_f:
            line = line.strip()
            if len(line) <= 0:
                continue
            assert len(line) >= 9

            trits_str, comment = line[:9], line[9:]
            assert comment.lstrip()[0] == '#'

            trits = str2trits(trits_str)
            bits = trits2bits(trits)
            bits_str = bits2str(bits)
            out_line = f'{bits_str}{comment}\n'
            out_f.write(out_line)


if __name__ == '__main__':
    main()
