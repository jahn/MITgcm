from os.path import join as pjoin, dirname
import numpy as np
import MITgcmutils as mit

def test_readstats():
    locals, totals, itrs = mit.readstats('diagstats/hs94.cs-32x32x5/tr_run.impIGW/dynStDiag.0000025920.txt')
    assert itrs['ETAN'] == [25920, 25923, 25926, 25929]
    assert itrs['UVEL'] == [25920, 25923, 25926, 25929]
    assert set(locals) == {'ETAN', 'UVEL', 'VVEL', 'WVEL', 'THETA', 'PHIHYD', 'DETADT2'}
    assert set(totals) == {'ETAN', 'UVEL', 'VVEL', 'WVEL', 'THETA', 'PHIHYD', 'DETADT2'}
    assert locals['THETA'].shape == (4, 5, 5)
    assert locals['DETADT2'].shape == (4, 1, 5)
    assert totals['THETA'].shape == (4, 5)
    assert totals['DETADT2'].shape == (4, 5)
    assert locals['THETA'][1, 4, 1] == 8.4845124949601

