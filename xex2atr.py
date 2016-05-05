#!/usr/bin/env python

import numpy as np

from atrcopy import SegmentData, BootDiskImage

def make_bootable_atr(xex_path, header_path, atr_path):
    xex = np.fromfile(xex_path, dtype=np.uint8)
    xex_size = np.alen(xex)
    bootcode = np.fromfile(header_path, dtype=np.uint8)
    v = bootcode[9:11].view(dtype="<u2")
    v[0] = xex_size
    size = np.alen(bootcode)
    bootsectors = np.zeros([384], dtype=np.uint8)
    bootsectors[0:size] = bootcode

    _, remainder = divmod(xex_size, 128)
    if remainder > 0:
        xex = np.append(xex, np.zeros([128-remainder], dtype=np.uint8))

    data = np.append(bootsectors, xex)
    rawdata = SegmentData(data)
    atr = BootDiskImage(rawdata, atr_path)
    atr.rebuild_header()
    print atr.header
    print bootcode[0:16]
    atr.save()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Insert file into another file")
    parser.add_argument("-v", "--verbose", default=0, action="count")
    parser.add_argument("-d", "--debug", action="store_true", default=False, help="debug the currently under-development parser")
    parser.add_argument("-o", "--output", default="", help="output file")
    parser.add_argument("-b", "--bootloader", default="", help="bootloader file")
    options, extra_args = parser.parse_known_args()


    make_bootable_atr(extra_args[0], options.bootloader, options.output)
