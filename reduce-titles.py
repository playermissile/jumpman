#!/usr/bin/env python

import numpy as np

from omnivore.utils.textutil import text_to_int

titles = "$c0,$c0,$c0,$c0,$e5,$e1,$f3,$f9,$c0,$e4,$ef,$e5,$f3,$c0,$e9,$f4,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f2,$ef,$e2,$ef,$f4,$f3,$c0,$e9,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e2,$ef,$ed,$e2,$f3,$c0,$e1,$f7,$e1,$f9,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ea,$f5,$ed,$f0,$e9,$ee,$e7,$c0,$e2,$ec,$ef,$e3,$eb,$f3,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f6,$e1,$ed,$f0,$e9,$f2,$e5,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e9,$ee,$f6,$e1,$f3,$e9,$ef,$ee,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e7,$f2,$e1,$ee,$e4,$c0,$f0,$f5,$fa,$fa,$ec,$e5,$c0,$e9,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e2,$f5,$e9,$ec,$e4,$e5,$f2,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ec,$ef,$ef,$eb,$c0,$ef,$f5,$f4,$c0,$e2,$e5,$ec,$ef,$f7,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e8,$ef,$f4,$c0,$e6,$ef,$ef,$f4,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f2,$f5,$ee,$e1,$f7,$e1,$f9,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f2,$ef,$e2,$ef,$f4,$f3,$c0,$e9,$e9,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e8,$e1,$e9,$ec,$f3,$f4,$ef,$ee,$e5,$f3,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e4,$f2,$e1,$e7,$ef,$ee,$c0,$f3,$ec,$e1,$f9,$e5,$f2,$c0,$c0,$c0,$c0,$c0,$c0,$e7,$f2,$e1,$ee,$e4,$c0,$f0,$f5,$fa,$fa,$ec,$e5,$c0,$e9,$e9,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f2,$e9,$e4,$e5,$c0,$e1,$f2,$ef,$f5,$ee,$e4,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f4,$e8,$e5,$c0,$f2,$ef,$ef,$f3,$f4,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f2,$ef,$ec,$ec,$c0,$ed,$e5,$c0,$ef,$f6,$e5,$f2,$c0,$c0,$c0,$c0,$c0,$c0,$ec,$e1,$e4,$e4,$e5,$f2,$c0,$e3,$e8,$e1,$ec,$ec,$e5,$ee,$e7,$e5,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e6,$e9,$e7,$f5,$f2,$e9,$f4,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ea,$f5,$ed,$f0,$cd,$ee,$cd,$f2,$f5,$ee,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e6,$f2,$e5,$e5,$fa,$e5,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e6,$ef,$ec,$ec,$ef,$f7,$c0,$f4,$e8,$e5,$c0,$ec,$e5,$e1,$e4,$e5,$f2,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f4,$e8,$e5,$c0,$ea,$f5,$ee,$e7,$ec,$e5,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ed,$f9,$f3,$f4,$e5,$f2,$f9,$c0,$ed,$e1,$fa,$e5,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ed,$f9,$f3,$f4,$e5,$f2,$f9,$c0,$ed,$e1,$fa,$e5,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ed,$f9,$f3,$f4,$e5,$f2,$f9,$c0,$ed,$e1,$fa,$e5,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e7,$f5,$ee,$e6,$e9,$e7,$e8,$f4,$e5,$f2,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$f2,$ef,$e2,$ef,$f4,$f3,$c0,$e9,$e9,$e9,$c0,$c0,$c0,$c0,$c0,$c0,$ee,$ef,$f7,$c0,$f9,$ef,$f5,$c0,$f3,$e5,$e5,$c0,$e9,$f4,$ce,$ce,$ce,$ce,$c0,$c0,$c0,$c0,$c0,$e7,$ef,$e9,$ee,$e7,$c0,$e4,$ef,$f7,$ee,$df,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$e7,$f2,$e1,$ee,$e4,$c0,$f0,$f5,$fa,$fa,$ec,$e5,$c0,$e9,$e9,$e9,$c0,$c0"

data = [text_to_int(v) for v in titles.split(",")]
print data
a = np.empty([len(data)], dtype=np.uint8)
a[:] = data
t = a.reshape([32,20])
print t
output = []
output_map = []
text = []
for i in range(32):
    title = t[i]
    for num in range(10):
        if title[num] == title[20 - num - 1] == 192:
            num += 1
        else:
            break
    small = title[num:20 - num]
    print num, small
    output_map.append(len(output))
    output.append(num)
    output.extend(list(small))
    text.append("        .byte $%02x,%s" % (num, ",".join(["$%02x" % i for i in small])))
print len(output), output
print output_map

print "levelname_offset:"
print "        .byte %s" % (",".join([str(i) for i in output_map]))
print "levelnames:"
print "\n".join(text) + "\n"
