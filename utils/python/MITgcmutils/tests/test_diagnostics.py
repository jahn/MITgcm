from os.path import join as pjoin, dirname
import numpy as np
import MITgcmutils as mit

def test_readstats_dims():
    locals, totals, itrs = mit.readstats('tests/diagstats/hs94.cs-32x32x5.impIGW/dynStDiag.0000025920.txt')
    assert itrs['ETAN'] == [25920, 25923, 25926, 25929]
    assert itrs['UVEL'] == [25920, 25923, 25926, 25929]
    assert set(locals) == {'ETAN', 'UVEL', 'VVEL', 'WVEL', 'THETA', 'PHIHYD', 'DETADT2'}
    assert set(totals) == {'ETAN', 'UVEL', 'VVEL', 'WVEL', 'THETA', 'PHIHYD', 'DETADT2'}
    assert locals['THETA'].shape == (4, 5, 5)
    assert locals['DETADT2'].shape == (4, 0, 5)
    assert totals['THETA'].shape == (4, 5)
    assert totals['DETADT2'].shape == (4, 5)
    assert locals['THETA'][1, 4, 1] == 8.4845124949601


def test_readstats_regions_dims():
    statsPerLayer, statsVertInt, itrs = mit.readstats(
        'tests/diagstats/aim.5l_cs.thSI/landStDiag.0000000000.txt')
    assert set(statsVertInt) == {'GrdTemp', 'GrdWater', 'LdSnowH', 'GrdSurfT'}
    assert list(itrs) == ['LdSnowH', 'GrdSurfT', 'GrdTemp', 'GrdWater']
    assert itrs['LdSnowH'] == [0, 8]
    assert statsPerLayer['LdSnowH'].shape == (2, 3, 0, 5)
    assert statsVertInt['LdSnowH'].shape == (2, 3, 5)
    assert statsPerLayer['GrdSurfT'].shape == (2, 3, 0, 5)
    assert statsVertInt['GrdSurfT'].shape == (2, 3, 5)
    assert statsPerLayer['GrdTemp'].shape == (2, 3, 2, 5)
    assert statsVertInt['GrdTemp'].shape == (2, 3, 5)
    assert statsPerLayer['GrdWater'].shape == (2, 3, 2, 5)
    assert statsVertInt['GrdWater'].shape == (2, 3, 5)
    assert statsPerLayer['GrdTemp'][1,2,1,0] == -0.24314580344548
    assert statsPerLayer['GrdTemp'][1,2,1,1] == 12.836135666496


def test_readstats_fields_regions():
    statsPerLayer, statsVertInt, itrs = mit.readstats(
        'tests/diagstats/global_ocean.cs32x15.thsice/thSIceStDiag.0000036000.txt')
    assert statsVertInt.dtype.names == ('SI_Fract', 'SI_Thick', 'SI_SnowH', 'SI_Tsrf', 'SI_Tice1', 'SI_Tice2', 'SI_Qice1', 'SI_Qice2', 'SIsnwPrc', 'SIalbedo', 'SIsnwAge', 'SIflx2oc', 'SIfrw2oc', 'SIsaltFx', 'SIflxAtm', 'SIfrwAtm')
    assert list(itrs) == ['SI_Fract', 'SI_Thick', 'SI_SnowH', 'SI_Tsrf', 'SI_Tice1', 'SI_Tice2', 'SI_Qice1', 'SI_Qice2', 'SIsnwPrc', 'SIalbedo', 'SIsnwAge', 'SIflx2oc', 'SIfrw2oc', 'SIsaltFx', 'SIflxAtm', 'SIfrwAtm']
    assert itrs['SI_Fract'] == [36010, 36020]
    assert statsPerLayer['SI_Fract'].shape == (2, 3, 0, 5)
    for fld in statsVertInt.dtype.names:
        assert statsVertInt[fld].shape == (2, 3, 5)

    assert statsVertInt['SIfrwAtm'][1,2,0] == -6.1874458169298e-06
    assert statsVertInt['SIfrwAtm'][1,2,1] == 3.8384508009947e-05
