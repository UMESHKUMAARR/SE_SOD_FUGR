*----------------------------------------------------------------------*
* Report  /PSYNG/SW_LOCCFG                                             *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_072 MESSAGE-ID /psyng/sw.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/basis_exelog.
TABLES : usr02, /psyng/orgnr_usr .
*data definition
DATA: BEGIN OF gt_usr02 OCCURS 0,
        sysid TYPE sysid,
        bname TYPE usr02-bname,
        gltgv TYPE usr02-gltgv,
        gltgb TYPE usr02-gltgb,
        ustyp TYPE usr02-ustyp,
        class TYPE usr02-class,
        uflag TYPE usr02-uflag,
        orgnr TYPE /psyng/orgnr,
      END OF gt_usr02,
      p_func type rs38l-name.
*selection screen
SELECTION-SCREEN : BEGIN OF BLOCK users WITH FRAME TITLE text-bt1.
SELECT-OPTIONS : users FOR usr02-bname.
SELECT-OPTIONS : groups FOR usr02-class.
SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE text-t02.
PARAMETERS: p_dialog AS CHECKBOX DEFAULT 'X',
            p_comm   AS CHECKBOX DEFAULT 'X',
            p_system AS CHECKBOX DEFAULT 'X',
            p_servic AS CHECKBOX DEFAULT 'X',
            p_refer  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK blk2.
SELECTION-SCREEN BEGIN OF BLOCK blk3 WITH FRAME TITLE text-t03.
PARAMETERS: p_adlock AS CHECKBOX DEFAULT 'X',
            p_ulock  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK blk3.
PARAMETERS: p_inactv AS CHECKBOX DEFAULT 'X'.


SELECTION-SCREEN : END OF BLOCK users .

AT SELECTION-SCREEN OUTPUT.
*Get FM from config table.
  IF p_func IS INITIAL.
    se_config_param 'FM_ORGNR_USER' p_func.
  ENDIF.

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  exelog sy-repid ''.
  PERFORM check_fm.
  PERFORM get_selected_users.
  PERFORM process_selected_users.
*&---------------------------------------------------------------------*
*&      Form  get_selected_users
*&---------------------------------------------------------------------*
FORM get_selected_users.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

* Get user information
  SELECT bname gltgv gltgb ustyp class uflag
         INTO CORRESPONDING FIELDS OF TABLE gt_usr02
         FROM usr02
         WHERE bname IN users AND class IN groups.

* Check user options
  LOOP AT gt_usr02.
    CASE gt_usr02-ustyp.
      WHEN 'A'.
        IF p_dialog = space.           "Exclude dialog users
          DELETE gt_usr02.
          CONTINUE.
        ENDIF.

      WHEN 'B'.
        IF p_system = space.           "Exclude system users
          DELETE gt_usr02.
          CONTINUE.
        ENDIF.

      WHEN 'C'.
        IF p_comm = space.             "Exclude communication users
          DELETE gt_usr02.
          CONTINUE.
        ENDIF.

      WHEN 'L'.
        IF p_refer = space.            "Exclude reference users
          DELETE gt_usr02.
          CONTINUE.
        ENDIF.

      WHEN 'S'.
        IF p_servic = space.           "Exclude service users
          DELETE gt_usr02.
          CONTINUE.
        ENDIF.

    ENDCASE.
*   Exclude administrative locked users
*   IF gt_usr02-uflag > 0 AND gt_usr02-uflag <= 64 AND p_adlock = space.
    IF ( l_uflagx O yusloc OR "locked by admin
       l_uflagx O yugloc )    "locked by CUA admin
       AND
       p_adlock = space.
      DELETE gt_usr02.
      CONTINUE.
    ENDIF.

*   Exclude self-locked users
*    IF gt_usr02-uflag > 64 AND p_ulock = space.
    IF l_uflagx O yulock "User locked by failed logins
       AND p_ulock = space.
      DELETE gt_usr02.
      CONTINUE.
    ENDIF.


    IF p_inactv = space.               "Exclude inactive users
      IF gt_usr02-gltgv > sy-datum OR ( gt_usr02-gltgb < sy-datum
      AND NOT gt_usr02-gltgb IS INITIAL ).
        DELETE gt_usr02.
        CONTINUE.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " get_selected_users
*&---------------------------------------------------------------------*
*&      Form  process_selected_users
*&---------------------------------------------------------------------*
FORM process_selected_users.
  FIELD-SYMBOLS : <usr> LIKE LINE OF  gt_usr02.
  DATA : ls_orgnr_usr TYPE /psyng/orgnr_usr.
  LOOP AT gt_usr02 ASSIGNING <usr>.
    ls_orgnr_usr-bname = <usr>-bname.
    CALL FUNCTION p_func "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(12/12/24)
         EXPORTING
              bname             = ls_orgnr_usr-bname
         IMPORTING
              orgnr             = ls_orgnr_usr-orgnr
         EXCEPTIONS
              no_orgnr_assigned = 1
              user_not_found    = 2
              OTHERS            = 3.
    IF sy-subrc = 0.
      MODIFY /psyng/orgnr_usr FROM ls_orgnr_usr.    "#EC CI_IMUD_NESTED
    ELSEIF sy-subrc = 1.
      DELETE FROM /psyng/orgnr_usr                  "#EC CI_IMUD_NESTED
       WHERE bname = ls_orgnr_usr-bname.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " process_selected_users
*&---------------------------------------------------------------------*
*&      Form  check_fm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_fm.
  CALL FUNCTION 'FUNCTION_EXISTS'
       EXPORTING
            funcname           = p_func
       EXCEPTIONS
            function_not_exist = 1
            OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE e135 WITH text-e01 p_func .
  ENDIF.
ENDFORM.                    " check_fm
