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
    assert locals['DETADT2'].shape == (4, 0, 5)
    assert totals['THETA'].shape == (4, 5)
    assert totals['DETADT2'].shape == (4, 5)
    assert locals['THETA'][1, 4, 1] == 8.4845124949601

def compare_stats(fname):
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

def test_readstats5():
    compare_stats('diagstats/offline_exf_seaice/tr_run.dyn_paralens/iceStDiag.0000000000.txt')

def test_readstats6():
    compare_stats('diagstats/offline_exf_seaice/tr_run.dyn_teardrop/iceStDiag.0000000000.txt')

def test_readstats7():
    compare_stats('diagstats/offline_exf_seaice/tr_run.thermo/iceStDiag.0000000000.txt')

def test_readstats8():
    compare_stats('diagstats/offline_exf_seaice/tr_run.dyn_ellnnfr/iceStDiag.0000000000.txt')

def test_readstats9():
    compare_stats('diagstats/offline_exf_seaice/tr_run.dyn_jfnk/iceStDiag.0000000000.txt')

def test_readstats10():
    compare_stats('diagstats/offline_exf_seaice/run/iceStDiag.0000000000.txt')

def test_readstats11():
    compare_stats('diagstats/offline_exf_seaice/tr_run.thsice/iceStDiag.0000000000.txt')

def test_readstats12():
    compare_stats('diagstats/offline_exf_seaice/tr_run.dyn_mce/iceStDiag.0000000000.txt')

def test_readstats13():
    compare_stats('diagstats/offline_exf_seaice/tr_run.dyn_lsr/iceStDiag.0000000000.txt')

def test_readstats15():
    compare_stats('diagstats/aim.5l_cs/tr_run.thSI/landStDiag.0000000000.txt')

def test_readstats16():
    compare_stats('diagstats/aim.5l_cs/tr_run.thSI/dynStDiag.0000000000.txt')

def test_readstats17():
    compare_stats('diagstats/aim.5l_cs/tr_run.thSI/thSIceStDiag.0000000000.txt')

def test_readstats20():
    compare_stats('diagstats/hs94.cs-32x32x5/tr_run.impIGW/dynStDiag.0000025920.txt')

def test_readstats32():
    compare_stats('diagstats/isomip/tr_run.obcs/dynStDiag.0000000000.txt')

def test_readstats40():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.seaice/dynStDiag.0000072000.txt')

def test_readstats41():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.seaice/seaiceStDiag.0000072000.txt')

def test_readstats42():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.in_p/seaiceStDiag.0000000000.txt')

def test_readstats43():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.in_p/dynStDiag.0000000000.txt')

def test_readstats44():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.thsice/thSIceStDiag.0000036000.txt')

def test_readstats45():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.thsice/instStDiag.0000036000.txt')

def test_readstats46():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.thsice/dynStDiag.0000036000.txt')

def test_readstats47():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.thsice/surfStDiag.0000036000.txt')

def test_readstats48():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.icedyn/thSIceStDiag.0000072000.txt')

def test_readstats49():
    compare_stats('diagstats/global_ocean.cs32x15/tr_run.icedyn/dynStDiag.0000072000.txt')

def test_readstats57():
    compare_stats('diagstats/global_ocean.90x40x15/tr_run.dwnslp/oceStDiag.0000036000.txt')

def test_readstats58():
    compare_stats('diagstats/global_ocean.90x40x15/tr_run.dwnslp/dynStDiag.0000036000.txt')

def test_readstats59():
    compare_stats('diagstats/global_ocean.90x40x15/run/oceStDiag.0000036000.txt')

def test_readstats60():
    compare_stats('diagstats/global_ocean.90x40x15/run/dynStDiag.0000036000.txt')

