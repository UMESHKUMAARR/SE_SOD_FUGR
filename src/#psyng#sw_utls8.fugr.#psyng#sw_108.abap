FUNCTION /psyng/sw_108.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_VALID_DATES) TYPE  CHAR1 DEFAULT 'X'
*"     VALUE(IF_ROLE) TYPE  AGR_NAME
*"  TABLES
*"      OT_USERS STRUCTURE  /PSYNG/BC_BNAME
*"----------------------------------------------------------------------
*--> BOC SE VF Scan changes - UMITTAL - 02/12/24
CONSTANTS: lc_fname TYPE rs38l_fnam VALUE '/PSYNG/SW_108'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e089(/psyng/sw) WITH lc_fname.
  ENDIF.

*--> EOC SO VF Scan changes - UMITTAL - 02/12/24
  DATA: lf_parent_agr TYPE agr_name.

  DATA: lt_users TYPE SORTED TABLE OF /psyng/bc_bname
        WITH UNIQUE KEY bname
        WITH HEADER LINE.

  DATA: lt_users_temp TYPE SORTED TABLE OF /psyng/bc_bname
       WITH UNIQUE KEY bname
       WITH HEADER LINE.

  SELECT SINGLE parent_agr INTO lf_parent_agr FROM agr_define
         WHERE agr_name = if_role .
  IF sy-subrc <> 0 OR lf_parent_agr IS INITIAL.
*--The role is not a derived role, is it a parent role?
    SELECT SINGLE parent_agr INTO lf_parent_agr  "#EC CI_SEL_NESTED
       FROM agr_define
           WHERE parent_agr = if_role .
  ENDIF.
*--The role is a derived or parent role
  IF NOT lf_parent_agr IS INITIAL.
    IF if_valid_dates = 'X'.
*   are there any users assigned to roles derived from the same parent
      SELECT DISTINCT u~uname AS bname  "#EC CI_SEL_NESTED
         INTO CORRESPONDING FIELDS OF TABLE lt_users
             FROM agr_define AS a
             INNER JOIN agr_users AS u
             ON
               a~agr_name = u~agr_name
             WHERE
             a~parent_agr = lf_parent_agr AND
             u~from_dat <= sy-datum AND
             u~to_dat >= sy-datum.
*     are there any users assigned to the parent?

*-- Appending values in lt_users will dump if we have parent-child role
*-- assign to same user
      SELECT DISTINCT uname  AS bname INTO   "#EC CI_SEL_NESTED
             CORRESPONDING FIELDS OF TABLE lt_users_temp
             FROM agr_users
             WHERE agr_name = lf_parent_agr AND
                   from_dat <= sy-datum AND
                   to_dat   >= sy-datum.

      IF NOT lt_users_temp[] IS INITIAL.
        LOOP AT lt_users_temp.
          READ TABLE lt_users WITH KEY bname = lt_users_temp-bname.
          IF sy-subrc NE 0.
            INSERT lt_users_temp INTO TABLE lt_users.
          ENDIF.
        ENDLOOP.
        REFRESH lt_users_temp.
      ENDIF.
    ELSE.
*   are there any users assigned to roles derived from the same parent
      SELECT DISTINCT u~uname AS bname INTO     "#EC CI_SEL_NESTED
             CORRESPONDING FIELDS OF TABLE lt_users
             FROM agr_define AS a
             INNER JOIN agr_users AS u
             ON
               a~agr_name = u~agr_name
             WHERE
             a~parent_agr = lf_parent_agr.
*     are there any users assigned to the parent?

      SELECT DISTINCT uname  AS bname INTO          "#EC CI_SEL_NESTED
             CORRESPONDING FIELDS OF TABLE lt_users_temp
             FROM agr_users
             WHERE agr_name = lf_parent_agr.

      IF NOT lt_users_temp[] IS INITIAL.
        LOOP AT lt_users_temp.
          READ TABLE lt_users WITH KEY bname = lt_users_temp-bname.
          IF sy-subrc NE 0.
            INSERT lt_users_temp INTO TABLE lt_users.
          ENDIF.
        ENDLOOP.
        REFRESH lt_users_temp.
      ENDIF.
    ENDIF.
  ELSE.
*--The role is not a derived role
*     are there any users assigned directly to this role?
    IF if_valid_dates = 'X'.
      SELECT DISTINCT uname  AS bname APPENDING     "#EC CI_SEL_NESTED
             CORRESPONDING FIELDS OF TABLE lt_users
             FROM agr_users
             WHERE agr_name = if_role AND
                   from_dat <= sy-datum AND
                   to_dat   >= sy-datum.
    ELSE.

      DELETE ADJACENT DUPLICATES FROM lt_users COMPARING bname.

      SELECT DISTINCT uname  AS bname APPENDING       "#EC CI_SEL_NESTED
             CORRESPONDING FIELDS OF TABLE lt_users
             FROM agr_users
             WHERE agr_name = if_role.
    ENDIF.
  ENDIF.
  ot_users[] = lt_users[].
ENDFUNCTION.
