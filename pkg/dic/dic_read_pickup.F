#include "DIC_OPTIONS.h"

      SUBROUTINE DIC_READ_PICKUP(
     O                            pH_isLoaded,
     O                            pHC_isLoaded,
     I                            myIter, myThid )

      IMPLICIT NONE
C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "DIC_VARS.h"

C     == Routine arguments ==
C     myThid  :: my Thread Id number
      LOGICAL pH_isLoaded
      LOGICAL pHC_isLoaded
      INTEGER myIter
      INTEGER myThid

#ifdef ALLOW_DIC

C     !FUNCTIONS

C     !LOCAL VARIABLES:
      INTEGER fp, ioUnit
      INTEGER filePrec, nbFields
      INTEGER j, nj
      INTEGER warnCnts
      INTEGER missFldDim, nMissing
      PARAMETER(missFldDim=2)
      CHARACTER*(10) suff
      CHARACTER*(MAX_LEN_FNAM) fn
      CHARACTER*(8) missFldList(missFldDim)
      CHARACTER*(MAX_LEN_MBUF) msgBuf
CEOP

      pH_isLoaded =.FALSE.
      pHC_isLoaded =.FALSE.
      ioUnit = errorMessageUnit

C--   pickup file name :
      IF (pickupSuff.EQ.' ') THEN
        IF ( rwSuffixType.EQ.0 ) THEN
          WRITE(fn,'(A,I10.10)') 'pickup_dic.', myIter
        ELSE
          CALL RW_GET_SUFFIX( suff, startTime, myIter, myThid )
          WRITE(fn,'(A,A)') 'pickup_dic.', suff
        ENDIF
      ELSE
        WRITE(fn,'(A,A10)') 'pickup_dic.', pickupSuff
      ENDIF
      fp = precFloat64

C--   First check if pickup file exist
#ifndef ALLOW_MDSIO
      STOP 'ABNORMAL END: S/R DIC_READ_PICKUP: Needs MDSIO pkg'
#endif
      CALL READ_MFLDS_SET(
     I                      fn,
     O                      nbFields, filePrec,
     I                      Nr, myIter, myThid )
      _BEGIN_MASTER( myThid )
      IF ( nbFields.GE.0 .AND. filePrec.NE.fp ) THEN
        WRITE(msgBuf,'(2A,I4)') 'DIC_READ_PICKUP: ',
     &   'pickup-file binary precision do not match !'
        CALL PRINT_ERROR( msgBuf, myThid )
        WRITE(msgBuf,'(A,2(A,I4))') 'DIC_READ_PICKUP: ',
     &   'file prec.=', filePrec, ' but expecting prec.=', fp
        CALL PRINT_ERROR( msgBuf, myThid )
        STOP 'ABNORMAL END: S/R DIC_READ_PICKUP (data-prec Pb)'
      ENDIF
      _END_MASTER( myThid )

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

      IF ( nbFields.LE.0 ) THEN
C-      No meta-file or old meta-file without List of Fields
        ioUnit = errorMessageUnit
        IF ( pickupStrictlyMatch ) THEN
          WRITE(msgBuf,'(4A)') 'DIC_READ_PICKUP: ',
     &      'no field-list found in meta-file',
     &      ' => cannot check for strick-matching'
          CALL PRINT_ERROR( msgBuf, myThid )
          WRITE(msgBuf,'(4A)') 'DIC_READ_PICKUP: ',
     &      'try with " pickupStrictlyMatch=.FALSE.,"',
     &      ' in file: "data", NameList: "PARM03"'
          CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
          STOP 'ABNORMAL END: S/R DIC_READ_PICKUP'
        ELSE
          WRITE(msgBuf,'(4A)') 'WARNING >> DIC_READ_PICKUP: ',
     &      ' no field-list found'
          CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
         IF ( nbFields.EQ.-1 ) THEN
C-      No meta-file
          WRITE(msgBuf,'(4A)') 'WARNING >> ',
     &      ' try to read pickup as currently written'
          CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
         ELSE
C-      Old meta-file without List of Fields
          WRITE(msgBuf,'(4A)') 'WARNING >> ',
     &      ' try to read pickup as it used to be written'
          CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(4A)') 'WARNING >> ',
     &      ' until checkpoint59i (2007 Oct 22)'
          CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
         ENDIF
        ENDIF
      ENDIF

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

C---   Old way to read model fields:
      IF ( nbFields.EQ.0 ) THEN
#ifdef DIC_ALLOW_3D_PH
        WRITE(msgBuf,'(4A)') 'DIC_READ_PICKUP: ',
     &      'DIC_ALLOW_3D_PH requires pickup up with field-list',
     &      ' in meta file'
        CALL PRINT_ERROR( msgBuf, myThid )
        STOP 'ABNORMAL END: S/R DIC_READ_PICKUP'
#endif
        CALL READ_REC_3D_RL( fn, fp, 1, pH, 1, myIter, myThid )
        pH_isLoaded = .TRUE.
      ELSE
        nj = 0
#ifdef DIC_ALLOW_3D_PH
        CALL READ_MFLDS_3D_RL('DIC_pHC ',pHC,nj,fp,Nr,myIter,myThid)
#endif
        nj = nj*Nr
        CALL READ_MFLDS_3D_RL('DIC_pH2d',pH,nj,fp,1,myIter,myThid)
        pH_isLoaded = .TRUE.
        pHC_isLoaded = .TRUE.
      ENDIF

C--   Check for missing fields:
      nMissing = missFldDim
      CALL READ_MFLDS_CHECK(
     O                    missFldList,
     U                    nMissing,
     I                    myIter, myThid )
      IF ( nMissing.GT.missFldDim ) THEN
         WRITE(msgBuf,'(2A,I4)') 'DIC_READ_PICKUP: ',
     &     'missing fields list has been truncated to', missFldDim
         CALL PRINT_ERROR( msgBuf, myThid )
         STOP 'ABNORMAL END: S/R DIC_READ_PICKUP (list-size Pb)'
      ENDIF
      IF ( nMissing.GE.1 ) THEN
        warnCnts = nMissing
        DO j=1,nMissing
C-    Case where missing field is not essential or can be recomputed
         IF ( missFldList(j).EQ.'DIC_pH2d' ) THEN
          pH_isLoaded = .FALSE.
          IF ( .NOT.pickupStrictlyMatch ) THEN
           WRITE(msgBuf,'(2A)') 'WARNING >> DIC_READ_PICKUP: ',
     &      'will restart from approximated pH'
           CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
          ENDIF
         ELSEIF ( missFldList(j).EQ.'DIC_pHC ' ) THEN
          pHC_isLoaded = .FALSE.
          IF ( .NOT.pickupStrictlyMatch ) THEN
           WRITE(msgBuf,'(2A)') 'WARNING >> DIC_READ_PICKUP: ',
     &      'will restart from approximated pHC'
           CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
          ENDIF
         ENDIF
        ENDDO

        IF ( pickupStrictlyMatch ) THEN
         WRITE(msgBuf,'(4A)') 'DIC_READ_PICKUP: ',
     &      'try with " pickupStrictlyMatch=.FALSE.,"',
     &      ' in file: "data", NameList: "PARM03"'
         CALL PRINT_ERROR( msgBuf, myThid )
         STOP 'ABNORMAL END: S/R CHECK_PICKUP'
        ELSEIF ( warnCnts .GT. 0 ) THEN
         WRITE(msgBuf,'(4A)') '** WARNING ** DIC_READ_PICKUP: ',
     &     'Will get only an approximated Restart'
         CALL PRINT_MESSAGE( msgBuf, ioUnit, SQUEEZE_RIGHT, myThid )
        ENDIF
      ENDIF

#ifdef DIC_ALLOW_3D_PH
      CALL EXCH_3D_RL( pHC, Nr, myThid )
#endif
      _EXCH_XY_RL( pH, myThid )

#endif /*  ALLOW_DIC  */

      RETURN
      END
