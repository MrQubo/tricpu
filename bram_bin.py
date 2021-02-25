#!/usr/bin/env python
# -*- coding: utf-8 -*-

import numpy as np

from main import int_to_trits, trits_to_int, encode_tryte


def compress_addr_trits(trits):
    last_5_trits = trits[-5:]
    n = np.uint8(np.int8(trits_to_int(last_5_trits)))
    acc = (encode_tryte(trits) & 0b1111111110000000000) >> 2
    i = np.uint32(0)
    while n > 0:
        if n % 2:
            acc |= (np.uint32(1) << i)
        i += 1
        n >>= 1
    return acc


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

    file_buf = []
    with in_f:
        for line in in_f:
            line = line.strip()
            if len(line) <= 0:
                continue
            assert len(line) >= 18

            bits_str, comment = line[:18], line[18:]
            assert comment.lstrip()[0] == '#'

            file_buf.append(np.uint32(int(bits_str, 2)))

    bram = [None] * (2**17)

    for n in range(len(file_buf)):
        trits = int_to_trits(n)
        addr_compressed = compress_addr_trits(trits)
        bram[addr_compressed] = file_buf[n]

    with out_f:
        for val in bram:
            if val is None:
                val = 0
            line = f'{val :018b}\n'
            assert len(line) == 19
            out_f.write(line)


if __name__ == '__main__':
    main()
