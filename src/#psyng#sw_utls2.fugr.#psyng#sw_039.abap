FUNCTION /PSYNG/SW_039.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_POSITIONID) TYPE  /PSYNG/POSITION-POSITIONID
*"  TABLES
*"      ET_ALL_ROLES STRUCTURE  /PSYNG/ROLES3 OPTIONAL
*"      ET_SW_ROLES STRUCTURE  /PSYNG/ROLES3 OPTIONAL
*"      ET_PFCG_ROLES STRUCTURE  /PSYNG/ROLES3 OPTIONAL
*"----------------------------------------------------------------------
DATA: lt_sw_pfcg    TYPE TABLE OF /PSYNG/ROLES3 with header line,
      l_subrc       TYPE sy-subrc,
      l_saptechname TYPE /psyng/position-saptechname.


  SELECT SINGLE saptechname INTO l_saptechname FROM /psyng/position
      WHERE positionid = i_positionid.
  IF sy-subrc = 0.
    SELECT rol~roleid rol~saptechname rol~description
      INTO (et_all_roles-roleid, et_all_roles-saptechname,
            et_all_roles-description)
      FROM /psyng/posndet AS posn INNER JOIN /psyng/rolehdr AS rol
        ON posn~roleid = rol~roleid
     WHERE posn~positionid = i_positionid.

      IF NOT et_all_roles-saptechname IS INITIAL.
        lt_sw_pfcg = et_all_roles.
        APPEND lt_sw_pfcg.
      ENDIF.

      APPEND et_all_roles.
    ENDSELECT.
  ENDIF.

* Check if PFCG role from position is in sync
  IF NOT l_saptechname IS INITIAL.
    PERFORM check_role_in_sync TABLES lt_sw_pfcg
                                      et_sw_roles
                                      et_pfcg_roles
                               USING l_saptechname
                               CHANGING l_subrc.
    CHECK l_subrc = 0.
  ENDIF.

* Check if PFCG role from roles are in sync
  LOOP AT lt_sw_pfcg.
    PERFORM check_role_in_sync TABLES lt_sw_pfcg
                                      et_sw_roles
                                      et_pfcg_roles
                               USING lt_sw_pfcg-saptechname
                               CHANGING l_subrc.
    IF l_subrc <> 0.
      EXIT.
    ENDIF.
  ENDLOOP.
ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  check_role_in_sync
*&---------------------------------------------------------------------*
*       Check that the role is in sync with PFCG
*----------------------------------------------------------------------*
*      -->IT_SW_ROLES    PFCG role names from SW roles
*      -->I_SAPTECHNAME  PFCG role name
*      <--E_SUBRC        Return code
*----------------------------------------------------------------------*
FORM check_role_in_sync TABLES   it_sw_roles structure /PSYNG/ROLES3
                                 et_sw_roles structure /PSYNG/ROLES3
                                 et_pfcg_roles structure /PSYNG/ROLES3
                        USING    i_saptechname
                                        TYPE /psyng/position-saptechname
                        CHANGING e_subrc TYPE sy-subrc.
data: BEGIN OF lt_pfcg occurs 0,
        saptechname TYPE /psyng/rolehdr-saptechname,
      END OF Lt_pfcg.


  SELECT child_agr INTO TABLE lt_pfcg FROM agr_agrs
         WHERE agr_name = i_saptechname
         AND   attributes <> 'X'.
  CHECK sy-subrc = 0.

  LOOP AT it_sw_roles.
    READ TABLE lt_pfcg WITH KEY saptechname = it_sw_roles-saptechname
               TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      e_subrc = sy-subrc.
      et_sw_roles = it_sw_roles.
      append et_sw_roles.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_pfcg.
    READ TABLE it_sw_roles WITH KEY saptechname = lt_pfcg-saptechname
               TRANSPORTING NO FIELDS.

    IF sy-subrc <> 0.
      e_subrc = sy-subrc.
      et_pfcg_roles-saptechname = lt_pfcg-saptechname.
      append et_pfcg_roles.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " check_role_in_sync
