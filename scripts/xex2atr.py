#!/usr/bin/env python

import numpy as np

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


def make_bootable_atr(xex_path, header_path, atr_path):
    xex = np.fromfile(xex_path, dtype=np.uint8)
    bootcode = np.fromfile(header_path, dtype=np.uint8)
    xfddata = add_xexboot_header(xex, bootcode)
    atrdata = add_atr_header(xfddata)
    with open(atr_path, "wb") as fh:
        atrdata.tofile(fh)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Insert file into another file")
    parser.add_argument("-v", "--verbose", default=0, action="count")
    parser.add_argument("-d", "--debug", action="store_true", default=False, help="debug the currently under-development parser")
    parser.add_argument("-o", "--output", default="", help="output file")
    parser.add_argument("-b", "--bootloader", default="", help="bootloader file")
    options, extra_args = parser.parse_known_args()


    make_bootable_atr(extra_args[0], options.bootloader, options.output)
