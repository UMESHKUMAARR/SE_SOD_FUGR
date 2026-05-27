FORM CD_CALL_PSYNG_SWAUDC                   .
   IF   ( UPD_PSYNG_SWAUDC                    NE SPACE )
     OR ( UPD_ICDTXT_SWAUDC           NE SPACE )
   .
     CALL FUNCTION '/PSYNG/SWAUDC_WRITE_DOCUMENT   '  IN UPDATE TASK
        EXPORTING OBJECTID              = OBJECTID
                  TCODE                 = TCODE
                  UTIME                 = UTIME
                  UDATE                 = UDATE
                  USERNAME              = USERNAME
                  PLANNED_CHANGE_NUMBER = PLANNED_CHANGE_NUMBER
                  OBJECT_CHANGE_INDICATOR = CDOC_UPD_OBJECT
                  PLANNED_OR_REAL_CHANGES = CDOC_PLANNED_OR_REAL
                  NO_CHANGE_POINTERS = CDOC_NO_CHANGE_POINTERS
                  O_PSYNG_SWAUDC
                      = */PSYNG/SWAUDC2
                  N_PSYNG_SWAUDC
                      = /PSYNG/SWAUDC2
                  UPD_PSYNG_SWAUDC
                      = UPD_PSYNG_SWAUDC
                  UPD_ICDTXT_SWAUDC
                      = UPD_ICDTXT_SWAUDC
          TABLES  ICDTXT_SWAUDC
                      = ICDTXT_SWAUDC
     .
   ENDIF.
   CLEAR PLANNED_CHANGE_NUMBER.
ENDFORM.
