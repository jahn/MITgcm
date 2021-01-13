from os.path import join as pjoin, dirname
import numpy as np
from MITgcmutils import mdjwf

TEST_DATA_PATH = pjoin(dirname(__file__), 'data')

def test_dens():
    rho = mdjwf.dens(35., 25., 2000.)
    assert abs(rho - 1031.654229) < .000001
