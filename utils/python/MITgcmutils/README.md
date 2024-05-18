# MITgcmutils

Python utilities for the MIT General Circulation Model,
[MITgcm](http://mitgcm.org).

This package is developed as a part of MITgcm on
[github](https://github.com/MITgcm/MITgcm/tree/master/utils/python/MITgcmutils).

It is documented in the MITgcm
[manual](http://mitgcm.rtfd.io/en/latest/utilities/utilities.html#mitgcmutils).

To test any changes to MITgcmutils, do the following in a clone of the MITgcm repository:
1. Check out the submodule with reference data:
```
    git submodule init
    git submodule update
```
2. Install the needed python versions (python3.7 through python3.12).
3. Install tox: https://tox.wiki/en/4.15.0/installation.html.
   On a mac, it may be necessary to install pipx via macports/brew
   or use the "pip" method.
4. Run "tox" in the top MITgcmutils directory (here).
