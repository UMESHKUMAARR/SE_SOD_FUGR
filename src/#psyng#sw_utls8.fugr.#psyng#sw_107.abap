FUNCTION /psyng/sw_107.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_VALID_DATES) TYPE  CHAR1 DEFAULT 'X'
*"     VALUE(IF_ROLE) TYPE  AGR_NAME
*"  TABLES
*"      OT_USERS STRUCTURE  /PSYNG/BC_BNAME
*"----------------------------------------------------------------------
*--> BOC SE VF Scan changes - UMITTAL - 02/12/24
CONSTANTS: lc_fname TYPE rs38l_fnam VALUE '/PSYNG/SW_107'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e089(/psyng/sw) WITH lc_fname.
  ENDIF.

*--> EOC SO VF Scan changes - UMITTAL - 02/12/24
  IF if_valid_dates = 'X'.
    SELECT DISTINCT uname AS bname INTO     "#EC CI_SEL_NESTED
           CORRESPONDING FIELDS OF  TABLE ot_users
           FROM agr_users
           WHERE agr_name = if_role AND
                 from_dat <= sy-datum AND
                 to_dat >= sy-datum.
  ELSE.
    SELECT DISTINCT uname AS bname INTO    "#EC CI_SEL_NESTED
           CORRESPONDING FIELDS OF  TABLE ot_users
           FROM agr_users
           WHERE agr_name = if_role .
  ENDIF.
  SORT ot_users BY bname.
ENDFUNCTION.
