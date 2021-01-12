from __future__ import print_function
from os.path import join as pjoin, dirname
import numpy as np
import MITgcmutils as mit

TEST_DATA_PATH = pjoin(dirname(__file__), 'data')

def test_rdmds():
    fname = pjoin(TEST_DATA_PATH, 'global_ocean.90x40x15/pickup.ckptA')
    etah = mit.rdmds(fname, rec=137)
    assert etah.shape == (40, 90)

