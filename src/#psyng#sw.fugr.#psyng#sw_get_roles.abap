FUNCTION /psyng/sw_get_roles.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_COMPOSITE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SINGLE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_ASSIGNED_ROLES) TYPE  FLAG OPTIONAL
*"     VALUE(I_RCHDATF) TYPE  MENU_DATE OPTIONAL
*"     VALUE(I_RCHDATT) TYPE  MENU_DATE DEFAULT SY-DATUM
*"     VALUE(I_GET_ACTUAL_DATA) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_COUNT) TYPE  I
*"  TABLES
*"      IT_ROLES STRUCTURE  /PSYNG/RANGE_AGR_NAME OPTIONAL
*"      IT_BA STRUCTURE  /PSYNG/RANGE_BUSAREA_ROLE OPTIONAL
*"      ET_ROLES STRUCTURE  /PSYNG/COMP_ROLE_TCODE OPTIONAL
*"      ET_TEXTS STRUCTURE  AGR_TEXTS OPTIONAL
*"      ET_BUSAREA_ROLE STRUCTURE  /PSYNG/BUSAREA_ROLE OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_ROLES'.
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
  DATA : lt_roles TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_comp_roles TYPE TABLE OF agr_agrs WITH HEADER LINE,
         lt_assnroles TYPE TABLE OF agr_users WITH HEADER LINE,
         lt_agr_flags TYPE TABLE OF agr_flags WITH HEADER LINE,
         lt_comp_agr_flags TYPE TABLE OF agr_flags WITH HEADER LINE,
         l_single_numb TYPE i,
         l_comp_numb TYPE i,
         lt_ba_roles type table of /PSYNG/BUSAREA_ROLE with header line.
  RANGES: idatseltab FOR sy-datum.


CALL FUNCTION '/PSYNG/BC_071'
 EXPORTING
   IF_SINGLE                = I_SINGLE_ROLES
   IF_COMPOSITE             = I_COMPOSITE_ROLES
   IF_ASSIGNED              = I_ASSIGNED_ROLES
   I_CHANGE_FROM_DATE       = I_RCHDATF
   I_CHANGE_TO_DATE         = I_RCHDATT
 TABLES
   IT_ROLES                 = IT_ROLES
   IT_BUSAREA               = IT_BA
*   IT_RFCDEST               =
*   IT_TCODES                =
   ET_BUSAREA_ROLE          = lt_ba_roles
*   ET_BUSAREA_RANGE         =
          .
 e_count = lines( lt_ba_roles ).

  IF i_get_actual_data = 'X'.
  IF i_composite_roles = 'X'
  AND lt_ba_roles[] IS NOT INITIAL.
    SELECT s~agr_name p~flag_value
    INTO CORRESPONDING FIELDS OF TABLE lt_comp_agr_flags
    FROM agr_define AS s
    inner JOIN agr_flags AS p
         ON  p~agr_name   = s~agr_name
         AND p~flag_type  = 'COLL_AGR'
         AND p~flag_value = 'X'
    FOR ALL ENTRIES IN lt_ba_roles
    WHERE s~agr_name EQ lt_ba_roles-agr_name.

      IF NOT lt_comp_agr_flags[] IS INITIAL.
        SELECT agr_name  child_agr FROM agr_agrs
        APPENDING CORRESPONDING FIELDS OF TABLE et_roles
        FOR ALL ENTRIES IN lt_comp_agr_flags
        WHERE agr_name = lt_comp_agr_flags-agr_name.
      ENDIF.
  ENDIF.
    loop at lt_ba_roles.
      CLEAR et_roles.
      READ TABLE et_roles WITH KEY agr_name = lt_ba_roles-agr_name.
      IF sy-subrc NE 0.
*--It's single role
      et_roles-agr_name = lt_ba_roles-agr_name.
      append et_roles.
      ENDIF.
    endloop.
*-- Get Text
    IF NOT et_roles[] IS INITIAL.
      SELECT agr_name text FROM agr_texts            "#EC CI_SEL_NESTED
         INTO CORRESPONDING FIELDS OF TABLE et_texts
         FOR ALL ENTRIES IN et_roles
        WHERE ( agr_name = et_roles-agr_name
                OR agr_name = et_roles-child_agr )
        AND spras = sy-langu
        AND line = 00000.
    ENDIF.
  ENDIF.
  if ET_BUSAREA_ROLE is requested.
    ET_BUSAREA_ROLE[] = lt_ba_roles[].
  endif.
ENDFUNCTION.
