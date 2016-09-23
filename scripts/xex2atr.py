#!/usr/bin/env python

import numpy as np

from atrcopy import SegmentData, BootDiskImage, add_xexboot_header, add_atr_header

def make_bootable_atr(xex_path, header_path, atr_path):
    xex = np.fromfile(xex_path, dtype=np.uint8)
    bootcode = np.fromfile(header_path, dtype=np.uint8)
    bootdata = add_xexboot_header(xex, bootcode)
    atrdata = add_atr_header(bootdata)
    rawdata = SegmentData(atrdata)
    atr = BootDiskImage(rawdata, atr_path)
    print atr.header
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
