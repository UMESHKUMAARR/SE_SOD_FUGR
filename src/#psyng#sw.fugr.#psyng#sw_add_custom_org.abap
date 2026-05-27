FUNCTION /PSYNG/SW_ADD_CUSTOM_ORG.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             REFERENCE(LS_CORG) TYPE  /PSYNG/SWSODORGO
*"             REFERENCE(I_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO
*"             REFERENCE(F_CORG) TYPE  CHAR1
*"       EXPORTING
*"             REFERENCE(FCORG_ADDED) TYPE  CHAR1
*"----------------------------------------------------------------------
DATA: l_objid        TYPE cdhdr-objectid,
      ls_corg_n      TYPE /psyng/swsodorgo,
      ls_corg_O      TYPE /psyng/swsodorgo.
FCORG_ADDED = 'N'.

CONCATENATE ls_corg-vrsio ls_corg-conid ls_corg-field ls_corg-type INTO
l_objid.

* Lock conflict ID
  CALL FUNCTION 'ENQUEUE_/PSYNG/CONFLICT'
       EXPORTING
            CONID          = ls_corg-conid
            vrsio          = i_vrsio
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
*            RAISING locked.
    EXIT.
  ENDIF.
* Check if record exists

  SELECT SINGLE * FROM /PSYNG/SWSODORGO INTO ls_corg_O
  WHERE vrsio = i_vrsio AND
        conid = ls_corg-conid AND
        field = ls_corg-field AND
        type  = ls_corg-type.
  IF sy-subrc <> 0.
    INSERT /PSYNG/SWSODORGO FROM ls_corg.   "#EC CI_IMUD_NESTED
    IF sy-subrc = 0.
     FCORG_ADDED = 'Y'.      "if new record inserted
    ENDIF.
  ELSE.
    MODIFY   /PSYNG/SWSODORGO FROM ls_corg.   "#EC CI_IMUD_NESTED
    FCORG_ADDED = 'Y'.      "if new record modified
  ENDIF.
*--Unlock conflict ID
  CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
   EXPORTING
     CONID                      = ls_corg-conid
     VRSIO                      = i_vrsio
            .

ENDFUNCTION.
