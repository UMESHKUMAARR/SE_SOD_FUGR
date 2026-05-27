FUNCTION /psyng/sw_066.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_RCHDATF) TYPE  MENU_DATE OPTIONAL
*"     VALUE(I_RCHDATT) TYPE  MENU_DATE OPTIONAL
*"     VALUE(I_COMPOSITE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SINGLE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_ASSIGNED_ROLES) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_ROLES STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      ET_ROLES STRUCTURE  AGR_DEFINE OPTIONAL
*"      ET_CHILDROLES STRUCTURE  AGR_AGRS OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_066'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
*--Get selected roles
  DATA : ls_agr_define TYPE agr_define,
         lt_agr_define TYPE TABLE OF agr_define WITH HEADER LINE,
         wa_agr_users TYPE agr_users..

  REFRESH et_roles.
  SELECT agr_name create_dat change_dat
             INTO CORRESPONDING FIELDS OF ls_agr_define
             FROM agr_define
             WHERE agr_name IN it_roles.
    IF i_rchdatf IS INITIAL.   "role change date from
      INSERT ls_agr_define INTO TABLE et_roles.
    ELSE.
      IF ls_agr_define-change_dat IS INITIAL.
        CHECK ls_agr_define-create_dat >= i_rchdatf AND
              ls_agr_define-create_dat <= i_rchdatt.
        INSERT ls_agr_define INTO TABLE et_roles.
      ELSE.
        CHECK ls_agr_define-change_dat >= i_rchdatf AND
              ls_agr_define-change_dat <= i_rchdatt.
        INSERT ls_agr_define INTO TABLE et_roles.
      ENDIF.
    ENDIF.
  ENDSELECT.

  LOOP AT et_roles.
    SELECT * FROM agr_agrs
    APPENDING TABLE et_childroles
    WHERE agr_name = et_roles-agr_name
    AND attributes <> 'X'.
  ENDLOOP.

  CHECK NOT et_roles[] IS INITIAL.
*** SE 3.1 Get & filter by assigned roles
  IF i_assigned_roles = 'X'.
    LOOP AT et_roles.
** if role is assigned to one user it is assigned
      SELECT SINGLE *  FROM agr_users INTO wa_agr_users
      WHERE agr_name = et_roles-agr_name.
      IF sy-subrc NE 0.
        APPEND et_roles TO lt_agr_define.
      ENDIF.
    ENDLOOP.
    LOOP AT lt_agr_define.
      DELETE et_roles WHERE agr_name = lt_agr_define-agr_name.
    ENDLOOP.
  ENDIF.
*-- filter by single and/or composite roles
  IF i_composite_roles = 'X' AND i_single_roles = 'X'.
*--All roles, no filtering needed
  ELSE.
   DATA : lt_roleinfo TYPE TABLE OF /psyng/sw_roleinfo WITH HEADER LINE.
    CONCATENATE sy-sysid sy-mandt INTO lt_roleinfo.
    LOOP AT  et_roles.
      lt_roleinfo-agr_name = et_roles-agr_name.
      APPEND lt_roleinfo.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/SW_ROLE_INFO'
*   EXPORTING
*     I_SPRAS        = 'EN'
      TABLES
        it_roles       = lt_roleinfo.
    IF i_composite_roles IS INITIAL.
*--filter out composite roles
      LOOP AT lt_roleinfo WHERE composite = 'X'.
        DELETE et_roles WHERE agr_name = lt_roleinfo-agr_name.
      ENDLOOP.
    ENDIF.
    IF i_single_roles IS INITIAL.
*--filter out single roles
      LOOP AT lt_roleinfo WHERE composite <> 'X'.
        DELETE et_roles WHERE agr_name = lt_roleinfo-agr_name.
      ENDLOOP.
    ENDIF.

  ENDIF.


ENDFUNCTION.
