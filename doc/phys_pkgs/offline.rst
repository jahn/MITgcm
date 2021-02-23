.. _sub_phys_pkg_offline:

OFFLINE Package
---------------


.. _ssub_phys_pkg_offline_intro:

Introduction
++++++++++++

A package which allows to advect passive tracers with dynamical fields read
from files.


Key subroutines and parameters
++++++++++++++++++++++++++++++

Runtime parameters are set in :code:`data.off`.
The parameters in :numref:`pkg_offline_parm01` specify where forcing
fields are read from.
Actual filenames are constructed by appending '.', a 10-digit iteration number
and '.data'.

.. csv-table:: Namelist OFFLINE_PARM01
   :name: pkg_offline_parm01
   :class: longtable
   :widths: auto
   :delim: &
   :header: Flag/Parameter, Default, Description

   :varlink:`UvelFile`      & :kbd:`' '` & Filename prefix for velocity x component
   :varlink:`VvelFile`      & :kbd:`' '` & Filename prefix for velocity y component
   :varlink:`WvelFile`      & :kbd:`' '` & Filename prefix for vertical velocity
   :varlink:`ThetFile`      & :kbd:`' '` & Filename prefix for temperature
   :varlink:`SaltFile`      & :kbd:`' '` & Filename prefix for salinity
   :varlink:`GMwxFile`      & :kbd:`' '` & Filename prefix for w-x component of GM tensor
   :varlink:`GMwyFile`      & :kbd:`' '` & Filename prefix for w-y component of GM tensor
   :varlink:`GMwzFile`      & :kbd:`' '` & Filename prefix for w-z component of GM tensor
   :varlink:`ConvFile`      & :kbd:`' '` & Filename prefix for vertical diffusion convection count
   :varlink:`KPP_DiffSFile` & :kbd:`' '` & Filename prefix for vertical diffusivity (kpp package)
   :varlink:`KPP_ghatKFile` & :kbd:`' '` & Filename prefix for non-local vertical mixing (kpp package)
   :varlink:`HFluxFile`     & :kbd:`' '` & Filename prefix for heat flux
   :varlink:`SFluxFile`     & :kbd:`' '` & Filename prefix for salt flux
   :varlink:`IceFile`       & :kbd:`' '` & Filename prefix for ice area fraction

The parameters in :numref:`pkg_offline_parm02` control the timing of the
forcing fields, see the following section.

.. tabularcolumns:: |\Y{.21}|\Y{.16}|\Y{.63}|

.. csv-table:: Namelist OFFLINE_PARM02
   :name: pkg_offline_parm02
   :class: longtable
   :widths: auto
   :delim: &
   :header: Flag/Parameter, Default, Description

   :varlink:`offlineIter0`         & 0                         & Shift in iteration numbers used to label files (see below for examples).         
   :varlink:`deltaToffline`        & :varlink:`deltaTclock`    & Time step used to compute the iteration numbers (in seconds).
   :varlink:`offlineTimeOffset`    & 0.0                       & Time offset of forcing fields (in seconds, default 0); this is relative to time averages starting at :math:`t=0`, i.e., the first forcing record/file is placed at (:varlink:`offlineTimeOffset` + :varlink:`offlineForcingPeriod` )/2; see below for examples.
   :varlink:`offlineForcingPeriod` & 0.0                       & Time interval between forcing fields (in seconds), zero means constant-in-time forcing.      
   :varlink:`offlineForcingCycle`  & 0.0                       & Repeat cycle of forcing fields (in seconds), zero means non-repeating forcing.     
   :varlink:`offlineLoadPrec`      & :varlink:`readBinaryPrec` & Precision of offline forcing files (in bits).



Timing of offline forcing fields
++++++++++++++++++++++++++++++++

:numref:`tab_phys_pkg_offline_timing` illustrates the relation between
model time and the iteration number appearing in forcing filenames.

.. tabularcolumns:: |l|l|l|c|

.. _tab_phys_pkg_offline_timing:

.. table:: Timing of offline forcing fields

  +-------------------+---------------------------------------------+---------------------------------------------+
  | **model time**    |                                **file iteration number**                                  |
  +-------------------+---------------------------------------------+---------------------------------------------+
  |                   |    :math:`c=0`                              |    :math:`c\ne0`                            |
  +===================+=============================================+=============================================+
  | :math:`t_0 - p/2` | :math:`i_0`                                 | :math:`i_0 + c/{\Delta t_{\text{offline}}}` |
  +-------------------+---------------------------------------------+---------------------------------------------+
  | :math:`t_0 + p/2` | :math:`i_0 + p/{\Delta t_{\text{offline}}}` | :math:`i_0 + p/{\Delta t_{\text{offline}}}` |
  +-------------------+---------------------------------------------+---------------------------------------------+
  | :math:`t_0+p+p/2` | :math:`i_0 + 2p/{\Delta t_{\text{offline}}}`| :math:`i_0 + 2p/{\Delta t_{\text{offline}}}`|
  +-------------------+---------------------------------------------+---------------------------------------------+
  | ...               |               ...                           |      ...                                    |
  +-------------------+---------------------------------------------+---------------------------------------------+
  | :math:`t_0+c-p/2` | ...                                         | :math:`i_0 + c/{\Delta t_{\text{offline}}}` |
  +-------------------+---------------------------------------------+---------------------------------------------+
  | ...               |               ...                           |      ...                                    |
  +-------------------+---------------------------------------------+---------------------------------------------+

where

| :math:`c` = :varlink:`offlineForcingCycle`
| :math:`p` = :varlink:`offlineForcingPeriod`
| :math:`t_0` = :varlink:`offlineTimeOffset`
| :math:`i_0` = :varlink:`offlineIter0`
| :math:`{\Delta t_{\text{offline}}}` = :varlink:`deltaToffline`


Example 1: Time averages
########################

The following example :code:`data.off` illustrates how to read time averages
as written by MITgcm.
It assumes that iteration 0 of the current simulation corresponds to
iteration 10000 of the dynamical simulation that produced the velocity fields.
Forcing fields are daily averages and the timestep of the dynamical simulation
was 1 hour.

::

   &OFFLINE_PARM01
   UvelFile = 'uVeltave',
   ...
   /
   &OFFLINE_PARM02
   offlinePeriod = 86400.,
   offlineTimeOffset = 0.,
   offlineIter0 = 10000,
   deltaToffline = 3600.,
   /

The following table shows which forcing fields are used at which model times:

.. table::

   +------------------+--------------------------+-------------------------------+
   | **model time**   | **filename**                                             |
   +------------------+--------------------------+-------------------------------+
   |                  | offlineForcingCycle = 0  | offlineForcingCycle = 432000. |
   +==================+==========================+===============================+
   | 43200.0          | uVeltave.0000010024.data | uVeltave.0000010024.data      |
   +------------------+--------------------------+-------------------------------+
   | 129600.0         | uVeltave.0000010048.data | uVeltave.0000010048.data      |
   +------------------+--------------------------+-------------------------------+
   | 216600.0         | uVeltave.0000010072.data | uVeltave.0000010072.data      |
   +------------------+--------------------------+-------------------------------+
   | 302400.0         | uVeltave.0000010096.data | uVeltave.0000010092.data      |
   +------------------+--------------------------+-------------------------------+
   | 388800.0         | uVeltave.0000010120.data | uVeltave.0000010120.data      |
   +------------------+--------------------------+-------------------------------+
   | 475200.0         | uVeltave.0000010144.data | uVeltave.0000010024.data      |
   +------------------+--------------------------+-------------------------------+
   | 561600.0         | uVeltave.0000010168.data | uVeltave.0000010048.data      |
   +------------------+--------------------------+-------------------------------+

For non-repeating forcing, fields read from the files in column 2 will be used
at the model times given in column 1.
For other model times, the forcing fields are interpolated linearly.
Column 3 is for forcing repeating every 5 days.


Example 2: Snapshots
####################

These settings are appropriate for reading snapshots:

::

   &OFFLINE_PARM01
   UvelFile = 'U',
   ...
   /
   &OFFLINE_PARM02
   offlinePeriod = 86400.,
   offlineTimeOffset = 43200.,
   offlineIter0 = 10000,
   deltaToffline = 3600.,
   /

.. table::

   +------------------+--------------------------+-------------------------------+
   | **model time**   | **filename**                                             |
   +------------------+--------------------------+-------------------------------+
   |                  | offlineForcingCycle = 0  | offlineForcingCycle = 432000. |
   +==================+==========================+===============================+
   | 0.0              | U.0000010000.data        | U.0000010120.data             |
   +------------------+--------------------------+-------------------------------+
   | 86400.0          | U.0000010024.data        | U.0000010024.data             |
   +------------------+--------------------------+-------------------------------+
   | 172000.0         | U.0000010048.data        | U.0000010048.data             |
   +------------------+--------------------------+-------------------------------+
   | 259200.0         | U.0000010072.data        | U.0000010072.data             |
   +------------------+--------------------------+-------------------------------+
   | 345600.0         | U.0000010096.data        | U.0000010092.data             |
   +------------------+--------------------------+-------------------------------+
   | 432000.0         | U.0000010120.data        | U.0000010120.data             |
   +------------------+--------------------------+-------------------------------+
   | 518400.0         | U.0000010144.data        | U.0000010024.data             |
   +------------------+--------------------------+-------------------------------+


Do’s and Don’ts
+++++++++++++++

Reference Material
++++++++++++++++++

Experiments and tutorials that use offline
++++++++++++++++++++++++++++++++++++++++++

In the directory :filelink:`verification`, the following experiments use :code:`offline`:

-  :filelink:`~verification/tutorial_cfc_offline`\ :
   Offline form of the MITgcm to study advection of a passive tracer and
   vection of a passive tracer and CFCs. This experiment is described in detail in [sec:eg-offline-cfc].


