#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import atexit
import termios
import tty

from sys import stdin

try:
    from ctypes import CDLL, c_int, c_char_p, POINTER
    term_c = CDLL('./term.so')

    term_c.init_term.argtypes = []
    term_c.init_term.restype = None

    term_c.fini_term.argtypes = []
    term_c.fini_term.restype = None

    term_c.int_to_chars.argtypes = [c_int, POINTER(c_int)]
    term_c.int_to_chars.restype = c_int

    term_c.hypercall_log.argtypes = [c_char_p, c_int]
    term_c.hypercall_log.restype = None

    term_c.termcall_beep.argtypes = []
    term_c.termcall_beep.restype = None

    term_c.termcall_putc.argtypes = [c_int, c_int, c_int, c_int, c_int, c_int]
    term_c.termcall_putc.restype = None

    term_c.termcall_getc.argtypes = [c_int, c_int]
    term_c.termcall_getc.restype = c_int
except OSError:
    pass

import numpy as np

try:
    import pynq
    import pynq.ps
except ImportError:
    pass


DECODE_MASK = 0b1111111
DECODE_T_BEAP = 0b0000011
DECODE_T_PUTC = 0b0000000
DECODE_T_GETC = 0b0000001
DECODE_H_EXIT = 0b1000000
DECODE_H_LOG = 0b1000001
DECODE_H_OPEN_NB = 0b1000111
DECODE_H_READ = 0b1000100
DECODE_H_OPEN_TXT = 0b1000101


f_err = None


def debug(s):
    global f_err
    if f_err is None:
        f_err = open('./out.err', 'w')

    f_err.write(s)
    f_err.flush()


def init_term():
    term_c.init_term()


def fini_term():
    term_c.fini_term()


def trits_to_int(trits):
    acc = 0
    t = 1
    for trit in reversed(trits):
        acc += trit * t
        t *= 3
    return acc


def decode_tryte(n):
    trits = [
        {0b11: -1, 0b00: 0, 0b01: 1}[(n & (0b11 << b)) >> b]
        for b in range(16, -1, -2)
    ]
    return trits


def encode_tryte(trits):
    #  assert len(trits) <= 9
    trits = trits[-9:]
    n = np.uint32(0)
    for i, trit in enumerate(reversed(trits)):
        b = np.uint32({-1: 0b11, 0: 0b00, 1: 0b01}[trit])
        b <<= 2 * i
        n |= b
    return n


def int_to_trits(n):
    trits = []
    while n > 0:
        if n % 3 == 0:
            trits.append(0)
        elif n % 3 == 1:
            trits.append(1)
            n -= 1
        else:
            trits.append(-1)
            n += 1
        n /= 3
    return list(reversed(trits))


class Main:
    def __init__(self):
        self.file_buffer = []
        self.buf1 = pynq.allocate(shape=(1,), dtype=np.uint32)

    def run(self):
        mhz = 20.
        pynq.ps.Clocks.fclk0_mhz = mhz

        self.ol = pynq.Overlay('./tricpu.bit')
        self.dma = self.ol.axi_dma

        pynq.ps.Clocks.fclk0_mhz = mhz

        self.main_loop()

    def main_loop(self):
        case = {
            DECODE_T_BEAP: self.termcall_beep,
            DECODE_T_PUTC: self.termcall_putc,
            DECODE_T_GETC: self.termcall_getc,
            DECODE_H_EXIT: self.hypercall_exit,
            DECODE_H_LOG: self.hypercall_log,
            DECODE_H_OPEN_NB: self.hypercall_open_nb,
            DECODE_H_READ: self.hypercall_read,
            DECODE_H_OPEN_TXT: self.hypercall_open_txt,
        }
        flag = True
        debug('loop start\n')
        while flag:
            self.dma.recvchannel.transfer(self.buf1)
            self.dma.recvchannel.wait()
            selector = self.buf1[0] & DECODE_MASK
            cb = case[selector]
            flag = cb()
        debug('loop end\n')

    def recv_str(self):
        s = bytearray()
        while True:
            self.dma.recvchannel.transfer(self.buf1)
            self.dma.recvchannel.wait()
            c = trits_to_int(decode_tryte(self.buf1[0]))
            chars = (c_int * 3)(0, 0, 0)
            res = term_c.int_to_chars(c, chars)
            if res == 0:
                break
            for i in range(res):
                s.append(chars[i])
        return bytes(s)

    def termcall_beep(self):
        debug('termcall_beep()\n')
        term_c.termcall_beep()
        return True

    def termcall_putc(self):
        debug('termcall_putc()\n')
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        x = trits_to_int(decode_tryte(self.buf1[0]))
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        y = trits_to_int(decode_tryte(self.buf1[0]))
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        c = trits_to_int(decode_tryte(self.buf1[0]))
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        r4 = decode_tryte(self.buf1[0])
        fg = trits_to_int(r4[-2:])
        bg = trits_to_int(r4[-4:-2])
        bold = r4[-5]
        term_c.termcall_putc(x, y, c, fg, bg, bold)
        return True

    def termcall_getc(self):
        debug('termcall_getc()\n')
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        x = trits_to_int(decode_tryte(self.buf1[0]))
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        y = trits_to_int(decode_tryte(self.buf1[0]))
        res = term_c.termcall_getc(x, y)
        if res == -1:
            return False
        self.buf1[0] = encode_tryte(int_to_trits(res))
        self.dma.sendchannel.transfer(self.buf1)
        self.dma.sendchannel.wait()
        return True

    def hypercall_exit(self):
        debug('hypercall_exit()\n')
        return False

    minlevel = -1

    def hypercall_log(self):
        debug('hypercall_log()\n')
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        level = trits_to_int(decode_tryte(self.buf1[0]))

        if level < self.minlevel:
            return True
        if level < -1:
            debug(f'level: {level}\n')
            level = -1
        if level > 3:
            debug(f'level: {level}\n')
            level = 3

        s = self.recv_str()
        term_c.hypercall_log(s, level)
        return True

    filenames_whitelist = [
        'enemy.nb',
        'pc.nb',
        'valis.nb',
    ]

    def hypercall_open_nb(self):
        debug('hypercall_open_nb()\n')
        filename = self.recv_str()
        try:
            filename = filename.decode('ascii')
        except UnicodeDecodeError:
            debug(f'wrong filename {repr(filename)}\n')
            res = -1
        else:
            if filename not in self.filenames_whitelist:
                debug(f'wrong filename {repr(filename)}\n')
                res = -1
            else:
                self.file_buffer = []
                for line in open(f'./static/{filename}r', 'r'):
                    line = line.strip()
                    if len(line) <= 0:
                        continue
                    assert len(line) >= 18

                    bits_str, comment = line[:18], line[18:]
                    assert comment.lstrip()[0] == '#'

                    self.file_buffer.append(np.uint32(int(bits_str, 2)))
                res = len(self.file_buffer)
        self.buf1[0] = encode_tryte(int_to_trits(res))
        self.dma.sendchannel.transfer(self.buf1)
        self.dma.sendchannel.wait()
        return True

    def hypercall_open_txt(self):
        debug('hypercall_open_txt()\n')
        filename = self.recv_str()
        try:
            filename = filename.decode('ascii')
        except UnicodeDecodeError:
            debug(f'wrong filename {repr(filename)}\n')
            res = -1
        else:
            if filename[0] == '.' or '/' in filename:
                debug(f'wrong filename {repr(filename)}\n')
                res = -1
            else:
                try:
                    f = open(f'./static/{filename}', 'rb')
                except FileNotFoundError:
                    debug(f'wrong filename {repr(filename)}\n')
                    res = -1
                else:
                    self.file_buffer = []
                    with f:
                        while True:
                            s = f.read(1)
                            if len(s) < 1:
                                break
                            c = ord(s)
                            self.file_buffer.append(encode_tryte(int_to_trits(c)))
                    res = len(self.file_buffer)
        self.buf1[0] = encode_tryte(int_to_trits(res))
        self.dma.sendchannel.transfer(self.buf1)
        self.dma.sendchannel.wait()
        return True

    def hypercall_read(self):
        debug('hypercall_read()\n')
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        sz = trits_to_int(decode_tryte(self.buf1[0]))
        self.dma.recvchannel.transfer(self.buf1)
        self.dma.recvchannel.wait()
        pos = trits_to_int(decode_tryte(self.buf1[0]))
        if pos + sz > len(self.file_buffer) or pos < 0 or sz < 0:
            res = -1
        else:
            res = 0
        self.buf1[0] = encode_tryte(int_to_trits(res))
        self.dma.sendchannel.transfer(self.buf1)
        self.dma.sendchannel.wait()
        if res == 0:
            for i in range(sz):
                self.buf1[0] = self.file_buffer[pos + i]
                self.dma.sendchannel.transfer(self.buf1)
                self.dma.sendchannel.wait()
            self.buf1[0] = 0xffffffff
            self.dma.sendchannel.transfer(self.buf1)
            self.dma.sendchannel.wait()
        else:
            self.buf1[0] = 0xffffffff
            self.dma.sendchannel.transfer(self.buf1)
            self.dma.sendchannel.wait()
        return True


def run():
    Main().run()


def main():
    init_term()
    run()


if __name__ == '__main__':
    main()
