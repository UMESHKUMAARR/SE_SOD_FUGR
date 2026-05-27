FORM CD_CALL_PSYNG_CRIT_OBJ                .
   IF   ( UPD_PSYNG_CRIPROF                  NE SPACE )
     OR ( UPD_PSYNG_CRIROLES                 NE SPACE )
     OR ( UPD_PSYNG_CRITCODES                NE SPACE )
     OR ( UPD_ICDTXT_CRIT_OBJ        NE SPACE )
   .
     CALL FUNCTION '/PSYNG/CRIT_OBJ_WRITE_DOCUMENT' IN UPDATE TASK
        EXPORTING OBJECTID              = OBJECTID
                  TCODE                 = TCODE
                  UTIME                 = UTIME
                  UDATE                 = UDATE
                  USERNAME              = USERNAME
                  PLANNED_CHANGE_NUMBER = PLANNED_CHANGE_NUMBER
                  OBJECT_CHANGE_INDICATOR = CDOC_UPD_OBJECT
                  PLANNED_OR_REAL_CHANGES = CDOC_PLANNED_OR_REAL
                  NO_CHANGE_POINTERS = CDOC_NO_CHANGE_POINTERS
                  O_PSYNG_CRIPROF
                      = */PSYNG/CRIPROF
                  N_PSYNG_CRIPROF
                      = /PSYNG/CRIPROF
                  UPD_PSYNG_CRIPROF
                      = UPD_PSYNG_CRIPROF
                  O_PSYNG_CRIROLES
                      = */PSYNG/CRIROLES
                  N_PSYNG_CRIROLES
                      = /PSYNG/CRIROLES
                  UPD_PSYNG_CRIROLES
                      = UPD_PSYNG_CRIROLES
                  O_PSYNG_CRITCODES
                      = */PSYNG/CRITCODES
                  N_PSYNG_CRITCODES
                      = /PSYNG/CRITCODES
                  UPD_PSYNG_CRITCODES
                      = UPD_PSYNG_CRITCODES
                  UPD_ICDTXT_CRIT_OBJ
                      = UPD_ICDTXT_CRIT_OBJ
          TABLES  ICDTXT_CRIT_OBJ
                      = ICDTXT_CRIT_OBJ
     .
   ENDIF.
   CLEAR PLANNED_CHANGE_NUMBER.
ENDFORM.
