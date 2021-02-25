#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import atexit
import socket
import sys
import termios
import threading
import tty

from sys import stdin, exit


def create_conn():
    global conn

    addr = '127.0.0.1'
    port = 1337
    if len(sys.argv) > 1:
        addr = sys.argv[1]
    if len(sys.argv) > 2:
        port = int(sys.argv[2])

    conn = socket.create_connection((addr, port))


def init_term():
    global old_tio
    global term

    atexit.register(fini_term)
    old_tio = termios.tcgetattr(stdin)
    tty.setraw(stdin, termios.TCSANOW)
    term = open('/dev/tty', 'rb+', buffering=0)
    term.write(b'\033[H\033[J\033[29r\033[29;1H\033[s')


def fini_term():
    if old_tio is None:
        return
    termios.tcsetattr(stdin, termios.TCSANOW, old_tio)
    term.write(b'\033[0m\033[1r\033[u')


def slurp_nb(fname):
    res = ''
    with open(fname) as f:
        for l in f:
            n = 0
            for x in l.strip():
                n *= 3
                n += {'-': -1, '0': 0, '+': 1}[x]
            if n < 0:
                n += 3 ** 9
            res += chr(n)
    return res


def send_nb(data):
    conn.sendall(data.encode())


def thr():
    while True:
        d = conn.recv(1024)
        if not d:
            term.write(b'\x1b[r\x1b[u')
            exit(0)
        term.write(d)


def main():
    create_conn()
    init_term()
    threading.Thread(target=thr).start()
    while True:
        x = term.read(1)
        if x == b'\x03':
            term.write(b'\x1b[r\x1b[u')
            exit(0)
        elif x == b'\x0b':
            input_buf = 2372
            gets_end = 1056
            bksp = b'\x08' * (input_buf - gets_end)
            conn.sendall(bksp)
            send_nb(slurp_nb('shc1.nb'))
            conn.sendall(b'\r')
            s2 = slurp_nb('shc2.nb')
            s3 = slurp_nb('shc3.nb')
            s4 = slurp_nb('shc4.nb')
            data = s2 + s3 + s4
            LEN = (3 ** 9 - 1) // 2
            while len(data) < LEN:
                data += '\0'
            assert len(data) == LEN
            send_nb(data)
        else:
            conn.sendall(x)


if __name__ == '__main__':
    main()
