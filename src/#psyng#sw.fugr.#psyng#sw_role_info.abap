FUNCTION /psyng/sw_role_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_SPRAS) TYPE  LANGU DEFAULT 'EN'
*"  TABLES
*"      IT_ROLES STRUCTURE  /PSYNG/SW_ROLEINFO
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_ROLE_INFO'.
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
  DATA : BEGIN OF  lt_roles_single_flag OCCURS 0.
          INCLUDE STRUCTURE /psyng/sw_roleinfo.
  DATA : flag_value TYPE c,
  END OF lt_roles_single_flag,

lt_roles_composite TYPE TABLE OF /psyng/sw_roleinfo WITH HEADER LINE,
lt_roles_single TYPE TABLE OF /psyng/sw_roleinfo WITH HEADER LINE,


         lt_roles2 TYPE TABLE OF /psyng/sw_roleinfo WITH HEADER LINE.

*--Select composite roles
  if not it_roles[] is initial.
  SELECT  p~agr_name
  APPENDING CORRESPONDING FIELDS OF TABLE lt_roles_composite
    FROM agr_define AS s
    INNER JOIN agr_flags AS p
         ON  p~agr_name   = s~agr_name
         AND p~flag_type  = 'COLL_AGR'
         AND p~flag_value = 'X'
    FOR ALL ENTRIES IN it_roles
    WHERE
    s~agr_name = it_roles-agr_name
.
  endif.

*--get names of comp roles
if not lt_roles_composite[] is initial.
  SELECT agr_name  text AS title
  INTO CORRESPONDING FIELDS OF TABLE lt_roles2
  FROM agr_texts
  FOR ALL ENTRIES IN lt_roles_composite
  WHERE
  line < 1 AND
  spras = i_spras AND
  agr_name = lt_roles_composite-agr_name.
*--Make sure roles without names are included
  loop at lt_roles_composite.
    read table lt_roles2
    with key agr_name = lt_roles_composite-agr_name.
    if sy-subrc <> 0.
      lt_roles2-agr_name = lt_roles_composite-agr_name.
      append lt_roles2.
    endif.

  endloop.
  lt_roles_composite[] = lt_roles2[].

  lt_roles_composite-composite = 'X'.
  MODIFY lt_roles_composite TRANSPORTING composite WHERE composite = ''.
endif.

*--Select single roles
if not it_roles[] is initial.
    SELECT s~agr_name p~flag_value
      APPENDING CORRESPONDING FIELDS OF TABLE lt_roles_single_flag
      FROM agr_define AS s
      LEFT OUTER JOIN agr_flags AS p
           ON  p~agr_name   = s~agr_name
           AND p~flag_type  = 'COLL_AGR'
      FOR ALL ENTRIES IN it_roles
      WHERE
      s~agr_name = it_roles-agr_name    .
endif.
  DELETE lt_roles_single_flag WHERE flag_value = 'X'.

*--get names of single roles
  IF NOT lt_roles_single_flag[] IS INITIAL.
    SELECT agr_name  text AS title
    INTO CORRESPONDING FIELDS OF TABLE lt_roles2
    FROM agr_texts
    FOR ALL ENTRIES IN lt_roles_single_flag
    WHERE
    line < 1 AND
    spras = i_spras AND
    agr_name = lt_roles_single_flag-agr_name.

    lt_roles_single[] = lt_roles2[].
*--Make sure roles without names are included
    loop at lt_roles_single_flag.
      read table lt_roles_single
      with key agr_name = lt_roles_single_flag-agr_name.
      if sy-subrc <> 0.
        lt_roles_single-agr_name = lt_roles_single_flag-agr_name.
        append lt_roles_single.
      endif.

    endloop.
  ENDIF.

  FREE it_roles.

  APPEND LINES OF lt_roles_single TO it_roles.
  APPEND LINES OF lt_roles_composite TO it_roles.
  FREE : lt_roles_single, lt_roles_composite.
  SORT it_roles BY agr_name.

*--Set rfc destination to sysid mandt
  CONCATENATE sy-sysid sy-mandt INTO it_roles-rfcdest.
  MODIFY it_roles TRANSPORTING rfcdest WHERE rfcdest = ''.


ENDFUNCTION.
