#ifdef ALLOW_DIC

CBOP
C    !ROUTINE: DIC_INDICES.h
C    !INTERFACE:
C #include DIC_INDICES.h

C    !DESCRIPTION:
C Contains indices into ptracer array

      INTEGER iDIC
      INTEGER iALK
      INTEGER iPO4
      INTEGER iDOP
      INTEGER iO2
      INTEGER iFeT
      INTEGER iSiO2
      PARAMETER (iDIC   =1)
      PARAMETER (iALK   =2)
      PARAMETER (iPO4   =3)
      PARAMETER (iDOP   =4)
#ifdef ALLOW_O2
      PARAMETER (iO2    =5)
#else
      PARAMETER (iO2    =0)
#endif
#ifdef ALLOW_FE
      PARAMETER (iFeT   =6)
#else
      PARAMETER (iFeT   =0)
#endif
      PARAMETER (iSiO2  =0)
C
      _RL ptr2mM
      PARAMETER (ptr2mM=1 _d 0)
CEOP
#endif /* ALLOW_DIC */
