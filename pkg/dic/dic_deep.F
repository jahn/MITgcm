#include "DIC_OPTIONS.h"

CBOP
C !ROUTINE: DIC_DEEP

C !INTERFACE: ==========================================================
      SUBROUTINE DIC_DEEP( iCO2 , iALK, iPO4, iSi,
     O           CO3,
     I           ptr2mM, restart,
     I           bi,bj,iMin,iMax,jMin,jMax,kLev,
     I           myIter,myTime,myThid)

C !DESCRIPTION:
C  Calculate pH, pCO2 and carbonate at grid-cell center of level kLev

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "DYNVARS.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "FFIELDS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_FIELDS.h"
#include "DIC_VARS.h"

C !INPUT PARAMETERS: ===================================================
C  myThid               :: thread number
C  myIter               :: current timestep
C  myTime               :: current time
c  PTR_CO2              :: DIC tracer field
      INTEGER iCO2, iALK, iPO4, iSi
      INTEGER iMin,iMax,jMin,jMax, bi, bj, kLev
      INTEGER myIter, myThid
      LOGICAL restart
      _RL ptr2mM
      _RL myTime

C !OUTPUT PARAMETERS: ===================================================
c GDC                   :: tendency due to air-sea exchange
      _RL CO3(1-OLx:sNx+OLx,1-OLy:sNy+OLy)

#ifdef ALLOW_DIC

C !LOCAL VARIABLES: ====================================================
       INTEGER i,j,CO3iter,CO3itermax
       LOGICAL debugPrt
C local variables for carbon chem
      _RL localk(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locphos(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locsi(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL loctemp(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locsalt(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locdic(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL pHlocal(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL pCO2local(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
CEOP

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

cc if coupled to atmsopheric model, use the
cc Co2 value passed from the coupler
c#ifndef USE_ATMOSCO2
cC PRE-INDUSTRIAL STEADY STATE pCO2 = 278.0 ppmv
c       DO j=1-OLy,sNy+OLy
c        DO i=1-OLx,sNx+OLx
c           AtmospCO2(i,j,bi,bj)=278.0 _d -6
c        ENDDO
c       ENDDO
c#endif

C =================================================================
C determine inorganic carbon chem coefficients
        DO j=jMin,jMax
         DO i=iMin,iMax
           IF (iALK .GT. 0) THEN
            localk(i,j) = pTracer(i,j,kLev,bi,bj,iALK)*ptr2mM
           ELSE
            localk(i,j) = 2.366595 _d 0 * salt(i,j,kLev,bi,bj)/gsm_s
           ENDIF
           IF (iPO4 .GT. 0) THEN
            locphos(i,j) = pTracer(i,j,kLev,bi,bj,iPO4)*ptr2mM
           ELSE
           locphos(i,j) = 5.1225 _d -4
           ENDIF
           IF (iSi .GT. 0) THEN
            locsi(i,j) = pTracer(i,j,kLev,bi,bj,iSi)*ptr2mM
           ELSE
            locsi(i,j) = SILICA(i,j,bi,bj)
           ENDIF
           loctemp(i,j) = theta(i,j,kLev,bi,bj)
           locsalt(i,j) = salt(i,j,kLev,bi,bj)
           locdic(i,j)  = pTracer(i,j,kLev,bi,bj,iCO2)*ptr2mM
C apply bounds
#ifdef DIC_BOUNDS
           locdic(i,j) =MAX(dic_CO2Min, MIN(dic_CO2Max, locdic(i,j)))
           localk(i,j) =MAX(dic_ALKMin, MIN(dic_ALKMax, localk(i,j)))
           locphos(i,j)=MAX(dic_PO4Min, MIN(dic_PO4Max, locphos(i,j)))
           locsi(i,j)  =MAX(dic_SiMin,  MIN(dic_SiMax,  locsi(i,j)))
           loctemp(i,j)=MAX(dic_tempMin,MIN(dic_tempMax,loctemp(i,j)))
           locsalt(i,j)=MAX(dic_saltMin,MIN(dic_saltMax,locsalt(i,j)))
#endif
C apply mask
           localk(i,j)  = localk(i,j) * maskC(i,j,kLev,bi,bj)
           locphos(i,j) = locphos(i,j) * maskC(i,j,kLev,bi,bj)
           locsi(i,j)   = locsi(i,j) * maskC(i,j,kLev,bi,bj)
          ENDDO
         ENDDO

#ifdef CARBONCHEM_SOLVESAPHE
#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_CALL('DIC_COEFFS_SURF',myThid)
#endif
        CALL DIC_COEFFS_SURF(
     I                       loctemp,locsalt,
     I                       bi,bj,iMin,iMax,jMin,jMax,myThid)

C Now correct the coefficients for pressure dependence
        CALL DIC_COEFFS_DEEP(
     I                       locTemp, locSalt,
     I                       bi,bj,iMin,iMax,jMin,jMax,
     I                       kLev,myThid)
#else /* CARBONCHEM_SOLVESAPHE */
#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_CALL('CARBON_COEFFS',myThid)
#endif
        CALL CARBON_COEFFS_PRESSURE_DEP(
     I                       loctemp,locsalt,
     I                       bi,bj,iMin,iMax,jMin,jMax,kLev,myThid)
#endif /* CARBONCHEM_SOLVESAPHE */
C====================================================================

       debugPrt = debugMode
c pCO2 solver...
C$TAF LOOP = parallel
       DO j=jMin,jMax
C$TAF LOOP = parallel
        DO i=iMin,iMax
          IF ( maskC(i,j,kLev,bi,bj).NE.0. _d 0 ) THEN
#ifdef CARBONCHEM_SOLVESAPHE
            IF ( selectPHsolver.GT.0 ) THEN
C Use Munhoven (2013) Solvesaphe routine to calculate pH and pCO2
              IF (restart) THEN
#ifdef ALLOW_DEBUG
               IF (debugPrt) CALL DEBUG_CALL('AHINI_FOR_AT',myThid)
#endif
C call AHINI_FOR_AT to get better initial guess of pH
               CALL AHINI_FOR_AT(localk(i,j)*permil,
     I           locdic(i,j)*permil,
     I           bt(i,j,bi,bj),
     O           pHlocal(i,j),
     I           i,j,kLev,bi,bj,myIter,myThid )
              ENDIF

#ifdef ALLOW_DEBUG
              IF (debugPrt) CALL DEBUG_CALL(
     &     'CALC_PCO2_SOLVESAPHE from DIC_locFORCING',myThid)
#endif
              CALL CALC_PCO2_SOLVESAPHE(
     I          loctemp(i,j),locsalt(i,j),
     I          locdic(i,j), locphos(i,j),
     I          locsi(i,j),localk(i,j),
     U          pHlocal(i,j),pCO2local(i,j),CO3(i,j),
     I          i,j,kLev,bi,bj, debugPrt, myIter, myThid )
              debugPrt = .FALSE.
            ELSE
C Use the original Follows et al. (2006) solver
#endif /* CARBONCHEM_SOLVESAPHE */
#ifdef ALLOW_DEBUG
              IF (debugPrt) CALL DEBUG_CALL(
     &        'CALC_PCO2_APPROX',myThid)
              debugPrt = .FALSE.
#endif
              IF (restart) THEN
               pHlocal(i,j) = 7.9 _d 0
Cmick -DEC 04
Cmick- NOW ITERATE pH SOLVER AT DEPTH ONLY
Cmick  TO ENSURE ACCURATE ESTIMATE OF CO3 AT DEPTH
Cmick - NOTE Si STILL USING A UNIFORM DUMMY VALUE
               CO3itermax = 10
Cmick - SO NOW WE ITERATE, UPDATING THE ESTIMATE OF pH and CO3--
Cmick - SINCE WE CALL THIS FOR DEEP OCEAN INFREQUENTLY (MONTHLY?)
CMIKC - CAN AFFORD TO MAKE SEVERAL ITERATIONS...
              ELSE
               CO3itermax = 1
              ENDIF
              DO CO3iter = 1, CO3itermax
               CALL CALC_PCO2_APPROX(
     I          loctemp(i,j),locsalt(i,j),
     I          locdic(i,j), locphos(i,j),
     I          locsi(i,j),localk(i,j),
     I          ak1(i,j,bi,bj),ak2(i,j,bi,bj),
     I          ak1p(i,j,bi,bj),ak2p(i,j,bi,bj),ak3p(i,j,bi,bj),
     I          aks(i,j,bi,bj),akb(i,j,bi,bj),akw(i,j,bi,bj),
     I          aksi(i,j,bi,bj),akf(i,j,bi,bj),
     I          ak0(i,j,bi,bj), fugf(i,j,bi,bj), ff(i,j,bi,bj),
     I          bt(i,j,bi,bj),st(i,j,bi,bj),ft(i,j,bi,bj),
     U          pHlocal(i,j),pCO2local(i,j),CO3(i,j),
     I          i,j,kLev,bi,bj,myIter, myThid )
              ENDDO
#ifdef CARBONCHEM_SOLVESAPHE
            ENDIF
#endif /* CARBONCHEM_SOLVESAPHE */
          ELSE
            pCO2local(i,j)=0. _d 0
          ENDIF
        ENDDO
       ENDDO

#endif /* ALLOW_DIC */

      RETURN
      END
