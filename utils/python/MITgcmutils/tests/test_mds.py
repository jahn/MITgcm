from __future__ import print_function
from os.path import join as pjoin, dirname
import numpy as np
import MITgcmutils as mit

TEST_DATA_PATH = pjoin(dirname(__file__), 'data')

def test_rdmds():
    fname = pjoin(TEST_DATA_PATH, 'global_ocean.90x40x15/pickup.ckptA')
    etah = mit.rdmds(fname, rec=137)
    assert etah.shape == (40, 90)

def test_rdmds_large(tmp_path):
    '''
    Test if we can read past 2GB
    '''
    meta = tmp_path / 'UVEL.meta'
    meta.symlink_to(pjoin(TEST_DATA_PATH, 'sose/UVEL.0000000060.meta'))
    data = tmp_path / 'UVEL.data'
    np.zeros((40,42,320,2160), ">f4").tofile(data)
    base = tmp_path / 'UVEL'
    u = mit.rdmds(str(base), rec=38)
    assert u.shape == (42,320,2160)

