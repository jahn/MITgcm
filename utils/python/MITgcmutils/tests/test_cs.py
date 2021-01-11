import sys
from packaging import version
import pytest
from os.path import join as pjoin, dirname
import numpy as np
try:
    import matplotlib as mpl
except ImportError:
    havematplotlib = False
else:
    havematplotlib = True
    mpl.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.testing.compare import compare_images
    try:
        from mpl_toolkits.basemap import Basemap
    except ImportError:
        havebasemap = False
    else:
        havebasemap = True
    import MITgcmutils as mit
    from MITgcmutils.cs import pcol

    try:
        import matplotlib.style
    except ImportError:
        pass
    else:
        mpl.style.use('classic')

TEST_DATA_PATH = pjoin(dirname(__file__), 'data')
BASELINE_PATH = pjoin(dirname(__file__), 'baseline_images')

if havematplotlib:
    def test_pcol(tmpdir):
        with tmpdir.as_cwd():
            ds = mit.rdmnc(pjoin(TEST_DATA_PATH, 
                'global_ocean.cs32x15/run/mnc_test_0001/state.0000072000.t*.nc'),
                ['XG', 'YG', 'Eta'])
            x = ds['XG']
            y = ds['YG']
            e = ds['Eta'][-1]
            e = np.squeeze(e)
            e = np.ma.masked_where(e==0., e)

            fig = plt.figure(figsize=(6.4, 4.8))
            plt.clf()
            h = pcol(x, y, e, cmap = 'jet')
            pngname = 'cs_pcol.png'
            plt.savefig(pngname)
            err = compare_images(pjoin(BASELINE_PATH, 'cs_pcol.png'), pngname, 13)
            if err:
                raise AssertionError(err)

