FORM CD_CALL_PSYNG_FUNCTS                  .
   IF   ( UPD_PSYNG_FUNCTION                 NE SPACE )
     OR ( UPD_PSYNG_FUNCTTRAN                NE SPACE )
     OR ( UPD_ICDTXT_FUNCTS          NE SPACE )
   .
     CALL FUNCTION 'SWE_REQUESTER_TO_UPDATE'.
     CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT  ' IN UPDATE TASK
        EXPORTING OBJECTID              = OBJECTID
                  TCODE                 = TCODE
                  UTIME                 = UTIME
                  UDATE                 = UDATE
                  USERNAME              = USERNAME
                  PLANNED_CHANGE_NUMBER = PLANNED_CHANGE_NUMBER
                  OBJECT_CHANGE_INDICATOR = CDOC_UPD_OBJECT
                  PLANNED_OR_REAL_CHANGES = CDOC_PLANNED_OR_REAL
                  NO_CHANGE_POINTERS = CDOC_NO_CHANGE_POINTERS
                  O_PSYNG_FUNCTION
                      = */PSYNG/FUNCTION
                  N_PSYNG_FUNCTION
                      = /PSYNG/FUNCTION
                  UPD_PSYNG_FUNCTION
                      = UPD_PSYNG_FUNCTION
                  O_PSYNG_FUNCTTRAN
                      = */PSYNG/FUNCTTRAN
                  N_PSYNG_FUNCTTRAN
                      = /PSYNG/FUNCTTRAN
                  UPD_PSYNG_FUNCTTRAN
                      = UPD_PSYNG_FUNCTTRAN
                  UPD_ICDTXT_FUNCTS
                      = UPD_ICDTXT_FUNCTS
          TABLES  ICDTXT_FUNCTS
                      = ICDTXT_FUNCTS
     .
   ENDIF.
   CLEAR PLANNED_CHANGE_NUMBER.
ENDFORM.
