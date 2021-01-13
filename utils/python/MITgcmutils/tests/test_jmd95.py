from os.path import join as pjoin, dirname
import numpy as np
from MITgcmutils import jmd95

TEST_DATA_PATH = pjoin(dirname(__file__), 'data')

def test_dens():
    rho = jmd95.dens(35.5, 3., 3000.)
    assert abs(rho - 1041.83267) < .00001
    # 1041.8326696373254
