from os.path import join as pjoin, dirname
import numpy as np
import MITgcmutils as mit

def test_iolabel():
    for i, s in zip([99, 105, 130, 999, 3800, 3843],
                    ['99', '0f', '0E', 'g7', 'Zi', 'ZZ']):
        assert mit.iolabel(i) == s

    for i in range(1, 3844):
        assert mit.iolabel2num(mit.iolabel(i)) == i

