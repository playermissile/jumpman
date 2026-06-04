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
                if options.debug: print(pc,label)
                names[label] = int(pc, 16)
    return names

def add_bytes(data, num):
    if num > 255:
        hi, lo = divmod(num, 256)
        data.extend([lo, hi])
    else:
        data.append(num)

def add_word(data, num):
    hi, lo = divmod(num, 256)
    data.extend([lo, hi])

def iter_patch(patch_path, names):
    org = None
    offset = 0
    data = []
    info = []
    if len(options.address) > 0:
        # using patch_path as a binary file
        org = text_to_int(options.address)
        if patch_path == "HEX":
            src_data = [text_to_int(i, "hex") for i in extra_args]
            data = np.array(src_data, dtype=np.uint8)
        elif patch_path == "BYTES":
            src_data = [text_to_int(i) for i in extra_args]
            data = np.array(src_data, dtype=np.uint8)
        elif patch_path == "ZEROS":
            count = text_to_int(extra_args[0])
            data = np.zeros([count], dtype=np.uint8)
        elif patch_path == "GAMELOOP":
            src_data = [text_to_int(i, "hex") for i in "20 D0 49 20 00 4B AD 3E 28 C9 00 F0 11 AD BE 30 C9 08 90 EF AD F0 30 C9 FF D0 E5 4C 3F 28 6C 44 28".split()]
            data = np.array(src_data, dtype=np.uint8)
        else:
            data = np.fromfile(patch_path, dtype=np.uint8)
        yield offset + org, offset + org + len(data), data, info
        return
    with open(patch_path) as fh:
        for line in fh.readlines():
            line = line.lstrip()
            if not line or line.startswith(";"):
                continue
            if ";" in line:
                line, _ = line.split(";", 1)
            # tokens are comma seperated values or space separated values
            cmd, args = line.split(None, 1)
            tokens = [x.strip() for x in args.split(',')]
            cmd = cmd.lower()
            if cmd == ".org":
                if org and data:
                    yield offset + org, offset + org + len(data), data, info
                    data = []
                    info = []
                org = text_to_int(tokens[0])
            elif cmd == ".offset":
                offset = text_to_int(tokens[0])
            elif cmd == ".file":
                path = tokens[0]
                data = np.fromfile(path, dtype=np.uint8)
                yield offset + org, offset + org + len(data), data, info
                org += len(data)
                data = []
            elif cmd == ".byte":
                values = []
                for v in tokens:
                    if v in names:
                        add_bytes(values, names[v])
                        info.append(f"{v}={names[v]:x}")
                    elif "*" in v:
                        v, rept = v.split("*")
                        v = text_to_int(v)
                        for i in range(text_to_int(rept)):
                            add_bytes(values, v)
                    else:
                        add_bytes(values, text_to_int(v))
                data.extend(values)
            elif cmd == ".word":
                values = []
                for v in tokens:
                    if v in names:
                        add_word(values, names[v])
                        info.append(f"{v}={names[v]:x}")
                    elif "*" in v:
                        v, rept = v.split("*")
                        v = text_to_int(v)
                        for i in range(text_to_int(rept)):
                            add_word(values, v)
                    else:
                        add_word(values, text_to_int(v))
                data.extend(values)
            elif cmd == ".copy":
                values = []
                for v in tokens:
                    rept = 1
                    if "*" in v:
                        v, rept = v.split("*")
                        rept = text_to_int(rept)
                    if v in names:
                        v = names[v]
                        info.append(f"src={names[v]:x}")
                    values = None
                data.extend(values)
            elif cmd.endswith(":"):
                values = []
                int = text_to_int(cmd[0:-1], 'hex')
                tokens = [x.strip() for x in args.split()]
                for v in tokens:
                    add_bytes(values, text_to_int(v, "hex"))
                data.extend(values)

        if org and data:
            yield offset + org, offset + org + len(data), data, info

class XEX:
    def __init__(self, data):
        self.segments = self.parse(data)

    def parse(self, b):
        size = np.alen(b)
        pos = 0
        first = True
        segments = []
        while pos < size:
            if pos + 1 < size:
                header, = b[pos:pos+2].view(dtype='<u2')
            else:
                raise RuntimeError("Incomplete Data")
            if header == 0xffff:
                # Apparently 0xffff header can appear in any segment, not just
                # the first.  Regardless, it is ignored everywhere.
                pos += 2
                first = False
                continue
            elif first:
                raise RuntimeError("Object file doesn't start with 0xffff")
            if options.debug: print("header parsing: header=0x%x" % header)
            if len(b[pos:pos + 4]) < 4:
                raise RuntimeError("Short Segment Header")
            start, end = b[pos:pos + 4].view(dtype='<u2')
            if end < start:
                raise RuntimeError(f"end address {end:x} less than start {start:x}")
            count = end - start + 1
            found = len(b[pos + 4:pos + 4 + count])
            if found < count:
                raise RuntimeError("Incomplete Data")
            segments.append((b[pos:pos + 4 + count], start, end))
            pos += 4 + count
        return segments

    def patch(self, start, end, data, info):
        for b, s, e in self.segments:
            # NOTE: numpy end and XEX segment end are reported differently.
            # numpy 0:2 means bytes 0 and 1, where XEX 0:1 means bytes 0 and 1
            if start >= s and end <= e+1:
                b[start - s + 4:end - s + 4] = data
                txt = " ".join(info)
                print(f"patched {start:x}-{end-1:x} in {s:x}-{e:x}: {len(data):x} bytes {txt}")
                break
        else:
            RuntimeError(f"range {start}-{end} not in segments")

    def save(self, path):
        with open(path, "wb") as fh:
            fh.write(b"\xff\xff") # force XEX header
            for b, s, e in self.segments:
                fh.write(b.tobytes())

class ATR:
    def __init__(self, data):
        self.src = data

    def patch(self, start, end, data, info):
        self.src[start:end] = data
        txt = " ".join(info)
        print(f"patched {start:x}-{end:x}: {len(data):x} bytes {txt}")

    def save(self, path):
        self.src.tofile(path)

def patch_image(src_path, patch_path, list_path, dest_path):
    src = np.fromfile(src_path, dtype=np.uint8)
    if list_path:
        names = nm(list_path)
    else:
        names = {}

    if src_path.lower().endswith("xex"):
        f = XEX(src)
    else:
        f = ATR(src)
    for start, end, data, info in iter_patch(patch_path, names):
        f.patch(start, end, data, info)
    f.save(dest_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Insert file into another file")
    parser.add_argument('src_file')           # Jumpman Level Tester ATR disk image
    parser.add_argument('patch_file', type=str)           # XEX of assembled level source code
    parser.add_argument("-v", "--verbose", default=0, action="count")
    parser.add_argument("-d", "--debug", action="store_true", default=False, help="debug the currently under-development parser")
    parser.add_argument("-o", "--output", default="", help="output file")
    parser.add_argument("-a", "--address", default="", type=str, help="use patch_file as binary and insert at this address")
    options, extra_args = parser.parse_known_args()
    if extra_args and options.patch_file != "HEX" and options.patch_file != "BYTES" and options.patch_file != "ZEROS" and options.patch_file != "GAMELOOP":
        list_file = extra_args[0]
    else:
        list_file = ""

    patch_image(options.src_file, options.patch_file, list_file, options.output)
