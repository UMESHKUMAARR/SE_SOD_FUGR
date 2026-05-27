FORM CD_CALL_PSYNG_FAOBJ                   .
   IF   ( UPD_PSYNG_FAOBJ                    NE SPACE )
     OR ( UPD_PSYNG_FAOBJ2                   NE SPACE )
     OR ( UPD_ICDTXT_FAOBJ           NE SPACE )
   .
     CALL FUNCTION '/PSYNG/FAOBJ_WRITE_DOCUMENT   ' IN UPDATE TASK
        EXPORTING OBJECTID              = OBJECTID
                  TCODE                 = TCODE
                  UTIME                 = UTIME
                  UDATE                 = UDATE
                  USERNAME              = USERNAME
                  PLANNED_CHANGE_NUMBER = PLANNED_CHANGE_NUMBER
                  OBJECT_CHANGE_INDICATOR = CDOC_UPD_OBJECT
                  PLANNED_OR_REAL_CHANGES = CDOC_PLANNED_OR_REAL
                  NO_CHANGE_POINTERS = CDOC_NO_CHANGE_POINTERS
                  O_PSYNG_FAOBJ
                      = */PSYNG/FAOBJ
                  N_PSYNG_FAOBJ
                      = /PSYNG/FAOBJ
                  UPD_PSYNG_FAOBJ
                      = UPD_PSYNG_FAOBJ
                  O_PSYNG_FAOBJ2
                      = */PSYNG/FAOBJ2
                  N_PSYNG_FAOBJ2
                      = /PSYNG/FAOBJ2
                  UPD_PSYNG_FAOBJ2
                      = UPD_PSYNG_FAOBJ2
                  UPD_ICDTXT_FAOBJ
                      = UPD_ICDTXT_FAOBJ
          TABLES  ICDTXT_FAOBJ
                      = ICDTXT_FAOBJ
     .
   ENDIF.
   CLEAR PLANNED_CHANGE_NUMBER.
ENDFORM.
