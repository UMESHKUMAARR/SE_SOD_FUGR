REPORT /psyng/synch_role_position MESSAGE-ID /psyng/sw.
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& REPORT /PSYNG/SYNCH_ROLE_POSITION                                   *
*&                                                                     *
*&---------------------------------------------------------------------*
*&                                                                     *
*&                                                                     *
*&---------------------------------------------------------------------*

TABLES: /psyng/rolehdr, /psyng/position, /psyng/posndet.

DATA: gt_itab TYPE STANDARD TABLE OF /psyng/rolehdr WITH HEADER LINE.
DATA:gf_missing_auth TYPE flag.
DATA : g_position(12).

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: roleid FOR /psyng/rolehdr-roleid,
                saprole FOR /psyng/rolehdr-saptechname.

PARAMETERS : p_trun TYPE flag AS CHECKBOX.

SELECTION-SCREEN END OF BLOCK blk1.



START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024

  CLEAR:gf_missing_auth.
  IF p_trun = 'X'.
    WRITE  / 'Test Run Mode'(004) COLOR COL_HEADING.
    WRITE / sy-uline.
  ENDIF.

  PERFORM get_roles.
  PERFORM update_positions.
*************************************
  IF gf_missing_auth = 'X'.
*  **SF 1665
    MESSAGE s398(00) WITH
*      'Analysis Complete.'(083)
        'Missing some user authorizations'(084).
  ENDIF.
*************************************
*&---------------------------------------------------------------------*
*&      Form  GET_ROLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_roles.
  DATA : l_agr TYPE agr_define-agr_name,
         l_roleid TYPE /psyng/rolehdr-roleid.

*  SELECT * INTO TABLE itab FROM /psyng/rolehdr
*   WHERE roleid IN roleid
*   AND   saptechname IN saprole.

  SELECT roleid description saptechname
    INTO CORRESPONDING FIELDS OF TABLE gt_itab FROM /psyng/rolehdr
   WHERE roleid IN roleid
   AND   saptechname IN saprole.

  IF sy-subrc NE 0.
    WRITE: / 'No Role ID exist for corresponding Selection'(005).
  ENDIF.


ENDFORM.                    " GET_ROLES
*&---------------------------------------------------------------------*
*&      Form  UPDATE_POSITIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM update_positions.
  DATA: lf_success TYPE /psyng/bapiflagx,
        lf_position TYPE /psyng/bapiflagx,
        l_position TYPE /psyng/position-positionid,
        l_agr TYPE agr_define-agr_name.
* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
  LOOP AT gt_itab.

*******************************************
**SF 1665
**Authorization check for Reading SW Roles
    AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
               ID 'ACTVT' FIELD '33'
               ID 'Y&SW_ROLID' FIELD gt_itab-roleid.
    IF sy-subrc EQ 0.
* **SF 1665
*******************************************

***   Check for existing position
      SELECT SINGLE positionid INTO l_position "#EC CI_SEL_NESTED
      FROM /psyng/position
      WHERE positionid = gt_itab-roleid.
      IF sy-subrc = 0.
*        g_position = l_position.
*        CONDENSE g_position NO-GAPS.
        WRITE: / 'Position '(003), l_position,
        'already exists; Role was not Copied. '(002).
*        CLEAR g_position.
        CONTINUE.
      ENDIF.
      /psyng/position-positionid  = gt_itab-roleid.
      /psyng/position-description = gt_itab-description.
      /psyng/position-saptechname = gt_itab-saptechname.
      /psyng/position-create_usr  = l_current_user. "sy-uname. C0700
      /psyng/position-create_dat  = sy-datum.
      /psyng/position-create_tim  = sy-uzeit.
*******************************************
* **SF 1665
*Authorization check for Create/Change SW Positions
**SF 1665
      AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
                 ID 'ACTVT' FIELD '01'
                 ID 'ACTVT' FIELD '02'
                ID 'Y&SW_POSID' FIELD /psyng/position-positionid.
      IF sy-subrc EQ 0.
*******************************************
        IF p_trun NE 'X'.
          INSERT /psyng/position.
          IF sy-subrc = 0.
            lf_position = 'X'.
          ENDIF.
        ENDIF.

        WRITE: / 'Role ID'(000),gt_itab-roleid,
        'successfully copied to Position ID'(001),
        gt_itab-roleid.

        /psyng/posndet-positionid   = gt_itab-roleid.
        /psyng/posndet-roleid       = gt_itab-roleid.
        IF p_trun NE 'X'.
          IF lf_position = 'X'.
            INSERT /psyng/posndet.
            lf_success = 'X'.
          ENDIF.
        ENDIF.
*          Endif.
*        ELSE.
*          WRITE: / 'Role'(000), itab-roleid, 'already exists.'(002).
*        ENDIF.

*********************************************
* **SF 1665
      ELSE.
        gf_missing_auth = 'X'.
      ENDIF.
************************************************
*********************************************
* **SF 1665
    ELSE.
      gf_missing_auth = 'X'.
    ENDIF.
************************************************
    CLEAR lf_position.
  ENDLOOP.

  IF lf_success = 'X'.
    MESSAGE s120.
  ENDIF.
ENDFORM.                    " UPDATE_POSITIONS
