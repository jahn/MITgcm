#include "DIC_OPTIONS.h"

CBOP
C !ROUTINE: DIC_ABIOTIC_FORCING

C !INTERFACE: ==========================================================
      SUBROUTINE DIC_ABIOTIC_FORCING(
     U                      SURC, SURA, SURO,
     I                      iDIC, iALK, iPO4, iSi, iO2,
     I                      ptr2mM,
     I                      bi, bj, iMin, iMax, jMin, jMax,
     I                      myIter, myTime, myThid )

C !DESCRIPTION:
C updates all the tracers for the effects of air-sea exchange, biological
c activity and remineralization

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#include "DIC_VARS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_FIELDS.h"

C !INPUT/OUTPUT PARAMETERS: ===================================================
C  iDIC              :: ptracer index for dissolced inorganic carbon
C  iALK              :: ptracer index for alkalinity
C  iPO4              :: ptracer index for phosphate
c  iO2               :: ptracer index for oxygen
C  SURA              :: tendency of alkalinity due to freshwater
C  SURC              :: tendency of DIC due to air-sea exchange
C                       and virtual flux
C  SURO              :: tendency of O2 due to air-sea exchange
c  bi, bj               :: current tile indices
C  myIter               :: current timestep
C  myTime               :: current time
C  myThid               :: thread number
      _RL SURA(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL SURC(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL SURO(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      INTEGER iDIC, iALK, iPO4, iSi, iO2
      INTEGER bi, bj, iMin, iMax, jMin, jMax
      INTEGER myIter
      _RL ptr2mM
      _RL myTime
      INTEGER myThid

#ifdef ALLOW_DIC

#ifdef ALLOW_DIAGNOSTICS
C     !FUNCTIONS:
      LOGICAL  DIAGNOSTICS_IS_ON
      EXTERNAL DIAGNOSTICS_IS_ON
#endif

C !LOCAL VARIABLES: ====================================================
C  i,j,k :: loop indices
      INTEGER i,j,k
      INTEGER nDEEPstep
      LOGICAL restart
#ifdef CAR_DISS
      _RL calcium
#endif
      _RL carbonate(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
CEOP

#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_ENTER('DIC_AIRSEAFLUX',myThid)
#endif

      IF ( useThSIce .OR. useSEAICE .OR. useCoupler ) THEN
#ifdef ALLOW_DEBUG
        IF (debugMode) CALL DEBUG_CALL('DIC_FIELDS_UPDATE',myThid)
#endif
        CALL DIC_FIELDS_UPDATE(
     I                    bi, bj, myTime, myIter, myThid )
      ENDIF

C carbon air-sea interaction
#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_CALL('DIC_SURFFORCING',myThid)
#endif
      CALL DIC_SURFFORCING(
     I                       iDIC, iALK, iPO4, iSi,
     O                       SURC,
     I                       ptr2mM,
     I                       bi, bj, iMin, iMax, jMin, jMax,
     I                       myIter, myTime, myThid )

#ifdef ALLOW_OLD_VIRTUALFLUX
C alkalinity air-sea interaction
#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_CALL('ALK_SURFFORCING',myThid)
#endif
      CALL ALK_SURFFORCING(
     O                       SURA,
     I                       bi, bj, iMin, iMax, jMin, jMax,
     I                       myIter, myTime, myThid )
#endif

      IF (iO2 .GT. 0) THEN
C oxygen air-sea interaction
#ifdef ALLOW_DEBUG
       IF (debugMode) CALL DEBUG_CALL('O2_SURFFORCING',myThid)
#endif
       CALL O2_SURFFORCING(
     I                       iO2,
     O                       SURO,
     I                       ptr2mM,
     I                       bi, bj, iMin, iMax, jMin, jMax,
     I                       myIter, myTime, myThid )
      ENDIF

C     don't compute deep pH, etc by default
      nDEEPstep = 0
#ifdef CAR_DISS
      nDEEPstep = 3600
#endif
#ifdef ALLOW_DIAGNOSTICS
      IF (useDiagnostics) THEN
       IF (DIAGNOSTICS_IS_ON('DICPHAVC',myThid) .OR.
     &     DIAGNOSTICS_IS_ON('DICPCO2C',myThid)) THEN
        nDEEPstep = 1
       ENDIF
      ENDIF
#endif
      IF(nDEEPstep .GT. 0 .AND. (myIter .LT. (nIter0+5) .OR.
     &                        MOD(myIter,MAX(1,nDEEPstep)) .EQ. 0))THEN
#ifdef ALLOW_DEBUG
       IF (debugMode) CALL DEBUG_CALL('CALCITE_SATURATION',myThid)
#endif
       restart = nDEEPstep .GT. 1
       DO k=1,Nr
        CALL DIC_DEEP(
     I                 iDIC, iALK, iPO4, iSi,
     O                 carbonate,
     I                 ptr2mM, restart,
     I                 bi, bj, iMin, iMax, jMin, jMax, k,
     I                 myIter, myTime, myThid )

#ifdef CAR_DISS
        DO j=jMin,jMax
         DO i=iMin,iMax
           IF ( maskC(i,j,k,bi,bj).EQ.oneRS ) THEN
#ifdef CARBONCHEM_SOLVESAPHE
             calcium = cat(i,j,bi,bj)
#else
             calcium = 1.028 _d -2*salt(i,j,k,bi,bj)/35. _d 0
#endif
             omegaC(i,j,k,bi,bj) = calcium * carbonate /
     &                          Ksp_TP_Calc(i,j,bi,bj)
           ELSE
             omegaC(i,j,k,bi,bj) = 0. _d 0
           ENDIF
         ENDDO
        ENDDO
#endif /* CAR_DISS */
C      end k loop
       ENDDO
C      endif myIter
      ENDIF

#ifdef ALLOW_DEBUG
      IF (debugMode) CALL DEBUG_LEAVE('DIC_AIRSEAFLUX',myThid)
#endif

#endif /* ALLOW_DIC */

      RETURN
      END
