#!/usr/bin/env python
# Create a Jumpman peanut allergy mask

import cStringIO

import numpy as np
from PIL import Image

from omnivore.utils.imageutil import *

if __name__ == "__main__":
    hx = 0
    hy = 6
    xb = lambda x:x+0x30+hx
    yb = lambda y:2*y+0x20+hy
    def is_allergic(x, y, hx, hy):
        return (x + 0x30 + hx) & 0x1f < 7 or (2 * y + 0x20 + hy) & 0x1f < 5
    w = 160
    h = 88
    good = (64, 178, 200, 100)
    bad = (203, 144, 161, 100)
    playfield = get_rect(w, h, good)
    for x in range(w):
        for y in range(h):
            if is_allergic(x, y, hx, hy):
                playfield[y, x] = bad
    save_image(playfield, "bad_peanut.png")
    
    # Create a location table that also takes into account the bomb being 4 pixels wide and 3 pixels tall, so this table will show all the legal positions to place a bomb, not the legal pixels

    print "X bomb location,hx=0,hx=16,hx=f0,hx=fc"
    hy = 6
    for x in range(w):
        #print "$%02x,%s" % (x, "OK" if not is_allergic(x, 0, hx, 6) else "BAD!")
        badlist = []
        for hx in [0, 16, -16, -4]:
            badlist.append("ok" if not is_allergic(x, 0, hx, hy) and not is_allergic(x + 3, 0, hx, hy) else "BAD!")
        print "$%02x,%s" % (x, ",".join(badlist))
    
    print "Y bomb location,hy=0,hy=2,hy=4,hy=6,hy=f6"
    hx = 0
    for y in range(h):
        #print "$%02x,%s" % (x, "OK" if not is_allergic(x, 0, hx, 6) else "BAD!")
        badlist = []
        for hy in [0, 2, 4, 6, -10]:
            badlist.append("ok" if not is_allergic(0, y, hx, hy) and not is_allergic(0, y + 2, hx, hy) else "BAD!")
        print "$%02x,%s" % (y, ",".join(badlist))
