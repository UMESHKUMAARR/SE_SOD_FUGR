FORM CD_CALL_PSYNG_SWAUD                   .
   IF   ( UPD_PSYNG_SWAUDC2                  NE SPACE )
     OR ( UPD_PSYNG_SWAUDHDR                 NE SPACE )
     OR ( UPD_ICDTXT_SWAUD           NE SPACE )
   .
     CALL FUNCTION 'SWE_REQUESTER_TO_UPDATE'.
     CALL FUNCTION '/PSYNG/SWAUD_WRITE_DOCUMENT   ' IN UPDATE TASK
        EXPORTING OBJECTID              = OBJECTID
                  TCODE                 = TCODE
                  UTIME                 = UTIME
                  UDATE                 = UDATE
                  USERNAME              = USERNAME
                  PLANNED_CHANGE_NUMBER = PLANNED_CHANGE_NUMBER
                  OBJECT_CHANGE_INDICATOR = CDOC_UPD_OBJECT
                  PLANNED_OR_REAL_CHANGES = CDOC_PLANNED_OR_REAL
                  NO_CHANGE_POINTERS = CDOC_NO_CHANGE_POINTERS
                  O_PSYNG_SWAUDC2
                      = */PSYNG/SWAUDC2
                  N_PSYNG_SWAUDC2
                      = /PSYNG/SWAUDC2
                  UPD_PSYNG_SWAUDC2
                      = UPD_PSYNG_SWAUDC2
                  O_PSYNG_SWAUDHDR
                      = */PSYNG/SWAUDHDR
                  N_PSYNG_SWAUDHDR
                      = /PSYNG/SWAUDHDR
                  UPD_PSYNG_SWAUDHDR
                      = UPD_PSYNG_SWAUDHDR
                  UPD_ICDTXT_SWAUD
                      = UPD_ICDTXT_SWAUD
          TABLES  ICDTXT_SWAUD
                      = ICDTXT_SWAUD
     .
   ENDIF.
   CLEAR PLANNED_CHANGE_NUMBER.
ENDFORM.
