#include "DIC_OPTIONS.h"
#include "PTRACERS_OPTIONS.h"

CBOP
C !ROUTINE: DIC_DEEP_INIT

C !INTERFACE: ==========================================================
      SUBROUTINE DIC_DEEP_INIT(
     I          iCO2, iALK, iPO4, iSi,
     I          ptr2mM,
     I          myThid)

C !DESCRIPTION:
C  Calculate first guess of pH

C !USES: ===============================================================
      IMPLICIT NONE
#include "SIZE.h"
#include "DYNVARS.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "FFIELDS.h"
#include "DIC_VARS.h"
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_FIELDS.h"
#include "DIC_LOAD.h"

C !INPUT PARAMETERS: ===================================================
C  myThid               :: thread number
      INTEGER iCO2, iALK, iPO4, iSi
      INTEGER  myThid
      _RL ptr2mM

#ifdef ALLOW_DIC
#ifdef DIC_ALLOW_3D_PH

C !LOCAL VARIABLES: ====================================================
       INTEGER i,j, kLev, it
       _RL pCO2dummy, co3dummy
C Number of iterations for pCO2 solvers...
C Solubility relation coefficients
C local variables for carbon chem
      INTEGER iMin,iMax,jMin,jMax, bi, bj
      _RL localk(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locphos(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locsi(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL loctemp(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locsalt(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      _RL locdic(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      INTEGER iprt,jprt
      LOGICAL debugPrt

C     msgBuf     :: Informational/error message buffer
      CHARACTER*(MAX_LEN_MBUF) msgBuf
CEOP

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      DO kLev=1,Nr

      jMin=1
      jMax=sNy
      iMin=1
      iMax=sNx

      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)
         DO j=1-OLy,sNy+OLy
          DO i=1-OLx,sNx+OLx
            pHC(i,j,kLev,bi,bj) = 8. _d 0
          ENDDO
         ENDDO
       ENDDO
      ENDDO

      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)

C determine inorganic carbon chem coefficients
        DO j=jMin,jMax
         DO i=iMin,iMax
           IF (iALK .GT. 0) THEN
            localk(i,j) = pTracer(i,j,kLev,bi,bj,iALK)*ptr2mM
           ELSE
            localk(i,j) = 2.366595 _d 0 * salt(i,j,kLev,bi,bj)/35 _d 0
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
        CALL DIC_COEFFS_DEEP(
     I                       loctemp,locsalt,
     I                       bi,bj,iMin,iMax,jMin,jMax,myThid)
#else /* CARBONCHEM_SOLVESAPHE */
#ifdef ALLOW_DEBUG
        IF (debugMode) CALL DEBUG_CALL('CARBON_COEFFS',myThid)
#endif
        CALL CARBON_COEFFS_PRESSURE_DEP(
     I                       loctemp,locsalt,
     I                       bi,bj,iMin,iMax,jMin,jMax,kLev,myThid)
#endif /* CARBONCHEM_SOLVESAPHE */

C====================================================================

#ifdef ALLOW_DEBUG
          IF (debugMode) THEN
            WRITE(msgBuf,'(A)') 'Initial pCO2 approximation method'
            CALL DEBUG_MSG(msgBuf(1:33),myThid)
          ENDIF
#endif

          debugPrt = debugMode
c first approximation
C$TAF LOOP = parallel
          DO j=jMin,jMax
C$TAF LOOP = parallel
           DO i=iMin,iMax
            IF ( maskC(i,j,kLev,bi,bj) .NE. 0. _d 0) THEN
C$TAF init dic_loc = static, 10
#ifdef CARBONCHEM_SOLVESAPHE
             IF ( selectPHsolver.GT.0 ) THEN
C Use Munhoven (2013) Solvesaphe routine to initialize pH
#ifdef ALLOW_DEBUG
              IF (debugPrt) CALL DEBUG_CALL('AHINI_FOR_AT',myThid)
#endif
C call AHINI_FOR_AT to get better initial guess of pH
              CALL AHINI_FOR_AT(
     I           localk(i,j)*permil,
     I           locdic(i,j)*permil,
     I           bt(i,j,bi,bj),
     U           pHC(i,j,kLev,bi,bj),
     I           i,j,kLev,bi,bj,nIter0,myThid )

C$TAF STORE pH(i,j,bi,bj)                              = dic_loc
C$TAF STORE localk(i,j), locphos(i,j), locsi(i,j)   = dic_loc

#ifdef ALLOW_DEBUG
              IF (debugPrt)
     &          CALL DEBUG_CALL('CALC_PCO2_SOLVESAPHE',myThid)
#endif
              CALL CALC_PCO2_SOLVESAPHE(
     I         loctemp(i,j),locsalt(i,j),
     I         locdic(i,j), locphos(i,j),
     I         locsi(i,j),localk(i,j),
     U         pHC(i,j,kLev,bi,bj),pCO2dummy,co3dummy,
     I         i,j,kLev,bi,bj, debugPrt, nIter0, myThid )
              debugPrt = .FALSE.
             ELSE
C Use the original Follows et al. (2006) solver
#endif /* CARBONCHEM_SOLVESAPHE */
#ifdef ALLOW_DEBUG
              IF (debugPrt) THEN
                CALL DEBUG_CALL('CALC_PCO2_APPROX',myThid)
                debugPrt = .FALSE.
              ENDIF
#endif
              DO it=1,10
C$TAF STORE pH(i,j,bi,bj)                              = dic_loc
C$TAF STORE localk(i,j), locphos(i,j), locsi(i,j)   = dic_loc
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
     U          pHC(i,j,kLev,bi,bj),pCO2dummy,co3dummy,
     I          i,j,kLev,bi,bj, it ,  myThid )
              ENDDO
#ifdef CARBONCHEM_SOLVESAPHE
             ENDIF
#endif /* CARBONCHEM_SOLVESAPHE */
            ENDIF
           ENDDO
          ENDDO

#ifdef ALLOW_DEBUG
        IF (debugMode) THEN
          iprt = MIN(20,sNx)
          jprt = MIN(20,sNy)
          WRITE(msgBuf,'(4(A,F9.6),2(A,F11.8),A,F9.6)')
     &        ' first guess pH=', pHC(iprt,jprt,kLev,bi,bj),
     &        ', Temp=',theta(iprt,jprt,kLev,bi,bj),
     &        ', Salt=',salt(iprt,jprt,kLev,bi,bj),
     &        ', DIC=', locdic(iprt,jprt),
     &        ', PO4=', locphos(iprt,jprt),
     &        ', SiT=', locsi(iprt,jprt),
     &        ', ALK=', localk(iprt,jprt)
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                        SQUEEZE_RIGHT, myThid )
c         WRITE(standardMessageUnit,*) 'QQ first guess pH ',
c    &        pH(iprt,jprt,bi,bj),' Temp ',theta(iprt,jprt,1,bi,bj),
c    &        ' Salt ',salt(iprt,jprt,1,bi,bj),
c    &        ' DIC ' ,locdic(iprt,jprt),
c    &        ' PO4 ' ,locphos(iprt,jprt),
c    &        ' SiT ' ,locsi(iprt,jprt),
c    &        ' ALK ' ,localk(iprt,jprt)
c        CALL DEBUG_MSG(msgBuf,myThid)
        ENDIF
#endif

C     end bi,bj loops
       ENDDO
      ENDDO

C     end kLev loop
      ENDDO

#endif /* DIC_ALLOW_3D_PH */
#endif /* ALLOW_DIC */

      RETURN
      END
