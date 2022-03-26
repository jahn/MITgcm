.. _sub_phys_sal:

SAL: self attraction and loading
********************************

.. _ssub_phys_sal_intro:

Introduction
============

:filelink:`pkg/sal` adds forcing due to the effects of ocean self-attraction
and loading (SAL) to the tide-generating potential, :varlink:`phiTide2d`.


.. _ssub_phys_sal_config:

SAL configuration and compiling
===============================

Compile-time options
--------------------

As with all MITgcm packages, the sal package can be turned on or off at
compile time

-  using the ``packages.conf`` file by adding ``sal`` to it,

-  or using ``genmake2`` adding ``-enable=sal`` or ``-disable=sal``
   switches

-  *required packages and CPP options*:
   sal requires the exf package to be enabled.

Parts of the sal code can be enabled or disabled at compile time via CPP
preprocessor flags. These options are set in ``SAL_OPTIONS.h``.
:numref:`tab_phys_pkg_sal_cpp_options` summarizes these options.

.. table:: sal CPP options
   :name: tab_phys_pkg_sal_cpp_options

   +--------------------------------+-----------------------------------------------------------+
   | **CPP option**                 |  **Description**                                          |
   +================================+===========================================================+
   | :varlink:`SAL_SKIP_GRID_CALCS` | skip application of spectral kernel (only for debugging!) |
   +--------------------------------+-----------------------------------------------------------+

The mass density field is interpolated to a Gaussian grid for spherical
harmonic analysis.  The size parameters of this grid are given in file
``SAL_SIZE.h``, see :numref:`tab_phys_pkg_sal_cpp_size`.

.. csv-table:: sal compile time parameters in file SAL_SIZE.h
   :name: tab_phys_pkg_sal_cpp_size
   :delim: &
   :widths: auto
   :header: CPP option, Description

   :varlink:`SAL_NLAT`   & number of latitudes for harmonic analysis
   :varlink:`SAL_NLON`   & number of longitudes for harmonic analysis
   :varlink:`SAL_LMAX`   & max. degree of spherical harmonics, must be < SAL_NLAT
   :varlink:`SAL_MAXM2G` & max. number of sparse matrix entries for model-lat-lon interp; at least SAL_NLON*SAL_NLAT for nearest interp, larger for bilinear and bicubic

Typical choices are SAL_NLAT=n, SAL_NLON=n*2, SAL_LMAX=n-1 where n is a number
of latitudes appropriate for the given grid resolution.

The SHTns library is required for compiling and using the sal package.  It can
be obtained here: https://bitbucket.org/nschaeff/shtns/.  It also requires
FFTW3 and OpenMP to function.  The appropriate libraries have to be included in
the optfile.  For gfortran, for instance,

::

   LIBS="$LIBS -lshtns_omp -lfftw3_omp -lfftw3 -lm -fopenmp”

and for ifort

::

   LIBS="$LIBS -lshtns_omp -lfftw3_omp -lfftw3 -lm -liomp5"

but details may depend on the installation.  To make full use of the
multi-threading capabilities of the library, the model may have to be run with
only 1 process on the first node.  On some queueing systems, this can be
achieved by providing a machine file in which the first node only appears once.
Consult the documentation for your queueing system to find the correct
procedure.  The following code snippet show an examples of how to generate such
a file for SLURM.  It is assumed that each node has 16 CPUs and we want to run
a total of 64 processes.

::

   cpus=(1 16 16 16 15)
   nodes=($(scontrol show hostname "$SLURM_NODELIST"))
   n=${#nodes[@]}
   let n--
   ncpu=0
   rm mf
   for i in $(seq 0 $n); do
     for j in $(seq ${cpus[$i]}); do
       echo ${nodes[$i]} >> mf
       let ncpu++
     done
   done
   mpirun -n $ncpu --machine mf ./mitgcmuv


.. _ssub_phys_sal_runtime:

Run-time parameters
===================

The run-time parameters for package sal are set in ``data.sal``, see
:numref:`tab_phys_sal_runtimeparms`.

.. csv-table:: Run-time parameters for sal package, namelist :varlink:`SAL_PARM01`
  :name: tab_phys_sal_runtimeparms
  :delim: &
  :widths: auto
  :header: Name, Default value, Description

  :varlink:`SAL_LoveFile`       & 'Love.txt' & Path to text file with load Love numbers
  :varlink:`SAL_refFile`        & ' '        & Path to binary file with reference bottom pressure anomaly
  :varlink:`SAL_usePhiHydLow`   & .FALSE.    & Whether to use bottom pressure from previous time step instead of integrating density
  :varlink:`SAL_maskLand`       & .TRUE.     & Whether to exclude land when computing mass load [#mask]_
  :varlink:`SAL_rhoEarth`       & 5517.0     & Mean density of the Earth (in kg/m\ :math:`^3`)
  :varlink:`SAL_startTime`      & baseTime   & When to start applying SAL effects (in seconds since baseTime)
  :varlink:`SAL_model2llFile`   & ' '        & Path prefix for files with interpolation weights and indices
  :varlink:`SAL_lon_0`          & 0.0        & Starting longitude of grid for harmonic analysis (in degrees East)
  :varlink:`SAL_lat`            & unset      & List of latitudes of grid for harmonic analysis (in degrees North)
  :varlink:`SAL_ll2modelMethod` & 2          & Method for interpolating back to model grid: 1 means bilinear, 2 bicubic
  :varlink:`SAL_diagIter`       & 0          & Iterations between lat-lon SAL debug diags (0: no diagnostics)
  :varlink:`SAL_cilmIter`       & 0          & Iterations between spectral SAL debug diags (0: no diagnostics)
  :varlink:`SAL_loadSaveCfg`    & .FALSE.    & Load SHTns configuration from files shtns_cfg and shtns_cfg_fftw; create files if not found

.. rubric:: Notes:

.. [#mask] If land is not excluded, blank tiles cannot be used.
           The model domain must cover the entire globe.

:varlink:`SAL_LoveFile` points to a text file with load Love numbers.  The
format is ``(I6,3F18)`` for :math:`(n, h'_n, l’_n, k'_n`) and values for
:math:`n` from 1 (or 0) to :varlink:`SAL_MAXNLOVE` must be provided.

If SAL_model2llFile is set, the model-to-Gaussian interpolation map will be
read as a sparse matrix in csr representation from the files in
:numref:`tab_phys_pkg_sal_interp`.  The files must be big-endian.  Indices and
pointers are zero based and the last value in the pointer file must be the
size n of the indices and weights file.  If SAL_model2llFile is not set,
nearest-neighbor interpolation will be used.  The latitudes of the Gaussian
grid will be computed if not given in SAL_lat.  The starting longitude of the
Gaussian grid must be given in SAL_lon_0 if different from zero.

.. csv-table:: Files for interpolation from model to Gaussian grid
   :name: tab_phys_pkg_sal_interp
   :delim: &
   :widths: 37,14,14,35
   :header: File, Type, Size, Description

   «SAL_model2llFile»_weights.bin & real*8    & n                     & interpolation weights
   «SAL_model2llFile»_indices.bin & integer*4 & n                     & model grid index for each weight
   «SAL_model2llFile»_indptr.bin  & integer*4 & SAL_NLON* SAL_NLAT+ 1 & start pointer into `indices` and `weights` for each lat-long grid point


Description
===========

The following additional term is added to the tide-generating potential,
:varlink:`phiTide2d`:

.. math::
   :label: eq_phys_pkg_sal_potential

   \phi_{\mathrm{SAL}}(\lambda,\varphi) = -\frac{3 g}{\rho_{\mathrm{E}}}
       \sum_{l=0}^{l_\max} \sum_{m=-l}^l
          \frac{\sigma'_{l m}}{2l+1} (1 + k'_l - h'_l) Y_{l m}(\varphi,\lambda)
   \;.

Here, :math:`\sigma'_{lm}` are the spherical harmonic expansion coefficients
of the 2-dimensional mass density anomaly,

.. math::
   :label: eq_phys_pkg_sal_expand

   \sigma'(\lambda,\varphi) =
   \sum_{l=0}^{\infty} \sum_{m=-l}^l \sigma'_{lm} Y_{lm}(\varphi,\lambda)
   \;.

It is expressed in terms of the bottom pressure anomaly,

.. math::

   g\sigma' = p'_{\mathrm{B}} - p'_{\mathrm{ref}}
   \;.

The bottom pressure includes atmospheric loading and the mass of sea ice and shelf ice,

.. math::

   p_{\mathrm{B}}(x,y) = p_{\mathrm{atm}}(x,y)
   + g\int\rho_{\mathrm{ice}}(x,y,z) dz
   + g\int_{-H_o(x,y)}^{\eta(x,y)} \rho(x,y,z) dz
   \;.

The bottom pressure anomaly is defined relative to an ocean of constant
density, :math:`\rho_c`, at rest,

.. math::

   p'_{\mathrm{B}}(x,y) = p_{\mathrm{B}}(x,y) - g\rho_c H_o(x,y)
   \;.

We subtract an additional reference pressure anomaly,
:math:`p'_{\mathrm{ref}}`, representing the long-term mean equilibrium state of
the ocean in motion.  This reference bottom pressure anomaly in geopotential
units, :math:`p'_{\mathrm{ref}}/\rho_c`, can be read in from a binary file,
:varlink:`SAL_refFile`.  If no file is given, the initial value of
:math:`p'_{\mathrm{B}}` is used.

By default, sal uses the bottom pressure anomaly computed in a finite-volume
formulation.  This requires :varlink:`INCLUDE_PHIBOT_FV_CODE` to be defined
in CPP_OPTIONS.h.  If :varlink:`SAL_usePhiHydLow` is set to true in data.sal,
the variable :varlink:`phiHydLow` computed in the previous time step is used
instead.  SAL computations can therefore not start until the second time step
and a pickup is required for restarts.


Implementation
--------------

The mass density anomaly on the model grid is mapped to a Gaussian grid on
each processor in parallel and then collected on the first processor via
MPI_REDUCE.  Here, SHTns transforms it to spherical harmonics coefficients.
This is done on multiple cores on the first node using OpenMP if configured
correctly. After the spectral factors in :eq:`eq_phys_pkg_sal_potential` are
applied, it is transformed back to the Guassian grid.  It is then broadcast to
all processors who will map it back to the model grid in parallel.  This is
done using the exf package.



Derivation
----------

The additional geopotential from changes of the mass of the ocean can be
represented in terms of a 2-dimensional surface mass density anomaly,
:math:`\sigma'`,

.. math::

   \phi_{\mathrm{SA}}(\mathbf{x}) = -G \int\!\!\!\int_S
     \frac{\sigma'(\mathbf{y})}{\overline{\mathbf{xy}}}
     dS(\mathbf{y})

Inserting the expansion :eq:`eq_phys_pkg_sal_expand`, the potential becomes

.. math::

   \phi_{\mathrm{SA}}(\varphi,\lambda) = -\frac{3 g}{\rho_{\mathrm{E}}}
                         \sum_{l=0}^{\infty} \sum_{m=-l}^l
                         \frac{\sigma'_{l m}}{2l+1} Y_{l m}(\lambda,\varphi)

where :math:`\rho_{\mathrm{E}}` is Earth’s mean density and we have used
:math:`g=G M_{\mathrm{E}}/R_{\mathrm{E}}^2=4\pi G \rho_{\mathrm{E}} R_{\mathrm{E}}/3`.
The additional weight also loads the Earth’s mantel and causes it to deform.
This will cause additional terms proportional to the self-attraction ones,
parameterized by load Love numbers, :math:`h'_l` and :math:`k'_l`,

.. math::

   \phi_{\mathrm{SAL}}(\varphi,\lambda) = -\frac{3 g}{\rho_{\mathrm{E}}}
     \sum_{l=0}^{\infty} \sum_{m=-l}^l
       \frac{\sigma'_{l m}}{2l+1} (1 + k'_l - h'_l) Y_{l m}(\lambda,\varphi)
   \;.



Call tree
---------

::

   the_model_main
     initialise_fixed
       packages_readparms
         sal_readparms
       packages_init_fixed
         sal_init_fixed
           sal_init_shtns
           sal_init_model2ll
           sal_init_nearest
           sal_diagnostics_init
       packages_check
         sal_check
     the_main_loop
       initialise_varia
         packages_init_variables
           sal_init_varia
             sal_read_pickup
       main_do_loop
         forward_step
           do_oceanic_phys
             sal_apply
               sal_compute_mass_anomaly
               sal_compute_loading
                 sal_grid_calcs
                 sal_latlon2model
           do_write_pickup
             packages_write_pickup
               sal_write_pickup



.. _sal_diagnostics:

SAL diagnostics
===============

Diagnostic output is available via the diagnostics package (see
:numref:`outp_pack`). Available output fields are summarized as follows:


::

   --------+----------+----------------+---------------------------------------------
   <-Name->|<- code ->|<--  Units   -->|<- Tile (max=80c)
   --------+----------+----------------+---------------------------------------------
   SAL     |SM      U1|m^2/s^2         |Geopotential from self-attraction and loading
   PHLSAL  |SM      U1|m^2/s^2         |Source term for self-attraction and loading
   SALptid1|SM      U1|m^2/s^2         |Tide geopotential after SAL
   SALptid0|SM      U1|m^2/s^2         |Tide geopotential before SAL

