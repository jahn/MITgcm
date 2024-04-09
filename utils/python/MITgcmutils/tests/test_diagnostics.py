from os.path import join as pjoin, dirname
import numpy as np
import pickle
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

def test_readstats_values():
    for fname in '''
            diagstats/hs94.cs-32x32x5/tr_run.impIGW/dynStDiag.0000025920.txt
            diagstats/offline_exf_seaice/tr_run.thermo/iceStDiag.0000000000.txt
            diagstats/offline_exf_seaice/tr_run.dyn_jfnk/iceStDiag.0000000000.txt
            diagstats/offline_exf_seaice/run/iceStDiag.0000000000.txt
            diagstats/offline_exf_seaice/tr_run.thsice/iceStDiag.0000000000.txt
            diagstats/offline_exf_seaice/tr_run.dyn_lsr/iceStDiag.0000000000.txt
            diagstats/aim.5l_cs/tr_run.thSI/landStDiag.0000000000.txt
            diagstats/aim.5l_cs/tr_run.thSI/dynStDiag.0000000000.txt
            diagstats/aim.5l_cs/tr_run.thSI/thSIceStDiag.0000000000.txt
            diagstats/hs94.cs-32x32x5/tr_run.impIGW/dynStDiag.0000025920.txt
            diagstats/tutorial_deep_convection/run/dynStDiag.0000000000.txt
            diagstats/tutorial_deep_convection/tr_run.smag3d/dynStDiag.0000000000.txt
            diagstats/isomip/tr_run.htd/dynStDiag.0000008640.txt
            diagstats/isomip/tr_run.obcs/dynStDiag.0000000000.txt
            diagstats/global_ocean.cs32x15/tr_run.seaice/dynStDiag.0000072000.txt
            '''.strip().split():
        locals, totals, itrs = mit.readstats(fname)
        lname = fname[:-4]+'.locals.pkl'
        tname = fname[:-4]+'.totals.pkl'
        with open(lname, 'rb') as f:
            loc = pickle.load(f)
        with open(tname, 'rb') as f:
            tot = pickle.load(f)
        if type(tot) == type({}):
            for k in tot:
                assert np.all(totals[k] == tot[k])
        else:
            if tot.size != 0:
                assert np.all(totals == tot)
        if type(loc) == type({}):
            for k in loc:
                assert np.all(locals[k] == loc[k])
        else:
            if loc.size != 0:
                assert np.all(locals == loc)
