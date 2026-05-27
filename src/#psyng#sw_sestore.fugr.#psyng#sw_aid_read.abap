FUNCTION /psyng/sw_aid_read.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_READ) TYPE  FLAG OPTIONAL
*"     VALUE(I_AID) TYPE  /PSYNG/SERESID OPTIONAL
*"     VALUE(I_ROLE_AID) TYPE  /PSYNG/SERRSID OPTIONAL
*"     VALUE(IF_ROLE) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_RESULTSET STRUCTURE  /PSYNG/SWRESHDR OPTIONAL
*"      ET_ROLE_RESULTSET STRUCTURE  /PSYNG/SWRRSHDR OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AID_READ'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  DATA : ls_aid TYPE /psyng/swreshdr,
         ls_role_aid TYPE /psyng/swrrshdr.

  ef_success = 'X'.
  IF if_role IS INITIAL.
*  --Validate the aid exists
    IF NOT i_aid IS INITIAL.
      SELECT SINGLE * FROM /psyng/swreshdr INTO ls_aid
      WHERE aid = i_aid.
      IF sy-subrc <> 0.
        log et_return 'E' 'INVALID_AID' 'Result Set' i_aid
                                        'does not exist.'
                                        ''.
        CLEAR ef_success.
      ENDIF.
    ENDIF.

    CHECK ef_success = 'X'.

    CASE 'X'.
      WHEN if_read.
*  --read the stored result set for this aid
        IF i_aid IS INITIAL.
*         Read ALL Stored ID's
          SELECT * FROM /psyng/swreshdr
          INTO TABLE et_resultset. ""#EC CI_NOWHERE
        ELSE.
          SELECT * FROM /psyng/swreshdr INTO TABLE et_resultset
          WHERE aid = i_aid.
        ENDIF.
    ENDCASE.
  ELSE.
*  --Validate the role aid exists
    IF NOT i_role_aid IS INITIAL.
      SELECT SINGLE * FROM /psyng/swrrshdr INTO ls_role_aid
      WHERE aid = i_role_aid.
      IF sy-subrc <> 0.
        log et_return 'E' 'INVALID_AID' 'Result Set' i_role_aid
                                        'does not exist.'
                                        ''.
        CLEAR ef_success.
      ENDIF.
    ENDIF.

    CHECK ef_success = 'X'.

    CASE 'X'.
      WHEN if_read.
*  --read the stored result set for this aid
        IF i_role_aid IS INITIAL.
*         Read ALL Stored ID's
          SELECT * FROM /psyng/swrrshdr
          INTO TABLE et_role_resultset. ""#EC CI_NOWHERE
        ELSE.
          SELECT * FROM /psyng/swrrshdr INTO TABLE et_role_resultset
          WHERE aid = i_role_aid.
        ENDIF.
    ENDCASE.
  ENDIF.

ENDFUNCTION.
