#!/usr/bin/env python

import numpy as np

import argparse

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

def nm(list_path):
    names = {}
    with open(list_path) as fh:
        start = False
        for line in fh.readlines():
            if not start and line.startswith("000000"):
                start = True
            if not start or ":" not in line:
                continue
            pc = line[0:6]
            label = line[24:].split()[0]
            if label.startswith("@"):
                continue
            if label.endswith(":"):
                label = label[:-1]
                print(pc,label)
                names[label] = int(pc, 16)
    return names

def add_bytes(data, num):
    if num > 255:
        hi, lo = divmod(num, 256)
        data.extend([lo, hi])
    else:
        data.append(num)

def iter_patch(patch_path, names):
    org = None
    offset = 0
    data = []
    with open(patch_path) as fh:
        for line in fh.readlines():
            line = line.lstrip()
            if not line or line.startswith(";"):
                continue
            # tokens are comma seperated values or space separated values
            cmd, args = line.split(None, 1)
            tokens = [x.strip() for x in args.split(',')]
            cmd = cmd.lower()
            if cmd == ".org":
                if org and data:
                    yield offset + org, offset + org + len(data), data
                    data = []
                org = text_to_int(tokens[0])
            elif cmd == ".offset":
                offset = text_to_int(tokens[0])
            elif cmd == ".byte":
                values = []
                for v in tokens:
                    if v in names:
                        add_bytes(values, names[v])
                    else:
                        add_bytes(values, text_to_int(v))
                data.extend(values)
            elif cmd == ".word":
                values = []
                for v in tokens:
                    if v in names:
                        add_bytes(values, names[v])
                    else:
                        add_bytes(values, text_to_int(v))
                data.extend(values)
            elif cmd.endswith(":"):
                values = []
                int = text_to_int(cmd[0:-1], 'hex')
                tokens = [x.strip() for x in args.split()]
                for v in tokens:
                    add_bytes(values, text_to_int(v, "hex"))
                data.extend(values)

        if org and data:
            yield offset + org, offset + org + len(data), data




def patch_image(src_path, patch_path, list_path, dest_path):
    src = np.fromfile(src_path, dtype=np.uint8)
    if list_path:
        names = nm(list_path)
        print(names)
    else:
        names = {}
    for start, end, data in iter_patch(patch_path, names):
        print(start, end, data)
        src[start:end] = data
    src.tofile(dest_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Insert file into another file")
    parser.add_argument('src_file')           # Jumpman Level Tester ATR disk image
    parser.add_argument('patch_file', type=str)           # XEX of assembled level source code
    parser.add_argument("-v", "--verbose", default=0, action="count")
    parser.add_argument("-d", "--debug", action="store_true", default=False, help="debug the currently under-development parser")
    parser.add_argument("-o", "--output", default="", help="output file")
    options, extra_args = parser.parse_known_args()
    if extra_args:
        list_file = extra_args[0]
    else:
        list_file = ""

    patch_image(options.src_file, options.patch_file, list_file, options.output)
