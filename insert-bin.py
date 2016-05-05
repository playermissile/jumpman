#!/usr/bin/env python

import numpy as np

import argparse

def make_image(src_path, insert_path, loc, dest_path):
    src = np.fromfile(src_path, dtype=np.uint8)
    obj = np.fromfile(insert_path, dtype=np.uint8)
    size = len(obj)
    src[loc:loc+size] = obj
    src.tofile(dest_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Insert file into another file")
    parser.add_argument("-v", "--verbose", default=0, action="count")
    parser.add_argument("-d", "--debug", action="store_true", default=False, help="debug the currently under-development parser")
    parser.add_argument("-o", "--output", default="", help="output file")
    options, extra_args = parser.parse_known_args()

    make_image(extra_args[0], extra_args[1], int(extra_args[2]), options.output)
