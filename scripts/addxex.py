#!/usr/bin/env python

import numpy as np

def text_to_int(text, default_base="dec"):
    """ Convert text to int, raising exeception on invalid input
    """
    if text.startswith("0x"):
        value = int(text[2:], 16)
    elif text.startswith("$"):
        value = int(text[1:], 16)
    elif text.startswith("#"):
        value = int(text[1:], 10)
    elif text.startswith("%"):
        value = int(text[1:], 2)
    else:
        if default_base == "dec":
            value = int(text)
        else:
            value = int(text, 16)
    return value


def add_atr_header(disk_image):
    format = np.dtype([
        ('wMagic', '<u2'),
        ('wPars', '<u2'),
        ('wSecSize', '<u2'),
        ('btParsHigh', 'u1'),
        ('dwCRC','<u4'),
        ('unused','<u4'),
        ('btFlags','u1'),
        ])
    raw = np.zeros([16], dtype=np.uint8)
    values = raw.view(dtype=format)[0]
    values[0] = 0x296
    paragraphs = len(disk_image) // 16
    parshigh, pars = divmod(paragraphs, 256*256)
    values[1] = pars
    values[2] = 128
    values[3] = parshigh
    values[4] = 0 # crc
    values[5] = 0 # unused
    values[6] = 0 # flags

    image = np.append(raw, disk_image)
    return image


def add_xexboot_header(bytes, bootcode):
    sec_size = 128
    xex_size = len(bytes)
    num_sectors = (xex_size + sec_size - 1) // sec_size
    padded_size = num_sectors * sec_size
    if xex_size < padded_size:
        bytes = np.append(bytes, np.zeros([padded_size - xex_size], dtype=np.uint8))
    paragraphs = padded_size // 16
    bootsize = np.alen(bootcode)
    v = bootcode[9:11].view(dtype="<u2")
    v[0] = xex_size

    bootsectors = np.zeros([384], dtype=np.uint8)
    bootsectors[0:bootsize] = bootcode

    image = np.append(bootsectors, bytes)
    return image


def add_data(src_path, options, extra_args):
    if src_path == "BYTES":
        src_data = [text_to_int(i) for i in extra_args]
        src = np.array(src_data, dtype=np.uint8)
    else:
        src = np.fromfile(src_path, dtype=np.uint8)
    if options.atr:
        start = options.atr[0]
        end = options.atr[1]
        if src[0] != 0x96 or src[1] != 0x02:
           raise RuntimeError("ATR specified, but ATR header not found")
        start = 16 + ((text_to_int(start) - 1) * 128)
        end = 16 + ((text_to_int(end)) * 128)
    else:
        start = 0
        end = np.alen(src)
    data = src[start:end]
    start_addr = text_to_int(options.address)
    last_addr = start_addr + np.alen(data) - 1
    header = np.array([start_addr & 0xff, start_addr >> 8, last_addr & 0xff, last_addr >> 8], dtype=np.uint8)
    print(f"{start_addr:x}, {last_addr:x}")
    try:
        existing = np.fromfile(options.output, dtype=np.uint8)
    except FileNotFoundError:
        existing = np.array([0xff, 0xff], dtype=np.uint8)
    dest = np.concatenate((existing, header, data))
    print(dest, np.alen(dest))
    dest.tofile(options.output)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Insert file into another file")
    parser.add_argument('src_file')           # Jumpman Level Tester ATR disk image
    #parser.add_argument('start', type=str)           # XEX of assembled level source code
    #parser.add_argument('end', type=str)           # XEX of assembled level source code
    parser.add_argument("-v", "--verbose", default=0, action="count")
    parser.add_argument("-d", "--debug", action="store_true", default=False, help="debug the currently under-development parser")
    parser.add_argument("-o", "--output", default="", help="output file")
    parser.add_argument("-a", "--address", default="0", type=str, help="address for segment")
    parser.add_argument("--atr", nargs=2, help="use START and END sector numbers in ATR file")
    options, extra_args = parser.parse_known_args()

    add_data(options.src_file, options, extra_args)
