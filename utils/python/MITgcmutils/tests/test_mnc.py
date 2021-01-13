from __future__ import print_function
from os.path import join as pjoin, dirname
import numpy as np
import MITgcmutils as mit

TEST_DATA_PATH = pjoin(dirname(__file__), 'data')

def test_mnc_files_aste():
    vars = '''
    AngleCS AngleSN Depth HFacC HFacS HFacW RC RF RL RU R_low Ro_surf X XC XG Xp1
    Y YC YG Yp1 Z Zl Zp1 Zu drC drF dxC dxF dxG dxV dyC dyF dyG dyU fCori fCoriG
    rA rAs rAw rAz
    '''.split()
    shapes = [(50, 150, 90), (50, 90, 90), (50, 90, 60), (50, 90, 150)]
    shapesW = [(50, 150, 91), (50, 90, 91), (50, 90, 61), (50, 90, 151)]
    stds = [0.47173731430490717, 0.48145571873661164, 0.43067785739294573, 0.38271133195229601]
    stdsW = [0.12965844673176288, 0.17049717169412615, 0.19584112953893676, 0.13181097328506711]

    ds = mit.mnc.mnc_files(pjoin(TEST_DATA_PATH, 'aste', 'grid.t*.nc'), 'faces')
    a = ds.variables['HFacC'][:]
    assert sorted(ds.variables) == vars
    assert [x.shape for x in a] == shapes
    assert [x.std() for x in a] == stds
    a = ds.variables['HFacW'][:]
    assert [x.shape for x in a] == shapesW
    assert [(np.diff(x, 1, -1).std(dtype=np.float64)) for x in a] == stdsW

    ds.close()


def test_rdmnc_eccov3():
    a = mit.rdmnc(pjoin(TEST_DATA_PATH, 'eccov3', 'dic_tave.*.nc'))
    assert sorted(a) == '''
    T X Y dic_SUR_ave dic_SURC_ave dic_SURO_ave dic_pH_ave dic_pCO2_ave iter
    '''.split()
    p = a['dic_pH_ave']
    assert p.shape == (1, 160, 360)
    assert p.std(dtype=np.float64) == 14.666781019324926
    assert np.diff(p, 1, -2).std(dtype=np.float64) == 5.2839897375324201


def test_rdmnc_cs32():
    ds = mit.rdmnc(pjoin(TEST_DATA_PATH, 'global_ocean.cs32x15', 'run',
                         'mnc_test_0001', 'oceDiag.*.nc'))
    assert sorted(ds) == '''
    CONVADJ DRHODR GM_Kwx GM_Kwy GM_Kwz GM_PsiX GM_PsiY RHOAnoma T X Xp1 Y Yp1 diag_levels iter
    '''.split()
    assert ds['GM_PsiX'].shape == (2, 15, 32, 193)
    assert np.diff(ds['GM_PsiX'], 1, -1).std(dtype=np.float64) == 0.27289287170849497

