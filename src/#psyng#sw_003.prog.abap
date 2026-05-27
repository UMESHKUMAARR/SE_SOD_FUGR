*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_003
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_003 .
TABLES: /psyng/mcusrgrp, /psyng/mcauditor, /psyng/mcuser,
        /psyng/conflict, /psyng/swaudhdr, /psyng/mchdr.

TYPE-POOLS: slis.

DATA: BEGIN OF mcuser OCCURS 0,
      type,   "C = Critical Auth, S = SOD Conflict
      contid LIKE /psyng/mcuser-contid,
      contdesc LIKE /psyng/mchdr-description,
      mittype LIKE /psyng/mchdr-type,
      mittype_text LIKE /psyng/sw_mctype-text,
      conid LIKE /psyng/mcuser-conid,  "Object ID
      condesc LIKE /psyng/conflict-description,
      asg_grp LIKE /psyng/mcuser-approved,
      asg_usr LIKE /psyng/mcuser-approved,
      class LIKE /psyng/mcusrgrp-class,
      userid LIKE /psyng/mcuser-userid,
      name_text    LIKE adrp-name_text,
      vrsio(3), "LIKE /PSYNG/MCUSER-VRSIO,
      auditor LIKE /psyng/mcuseraud-auditor,
      auditor_name_text    LIKE adrp-name_text,
      company LIKE /psyng/mcauditor-company, "auditor's company
      from_date LIKE /psyng/mcuser-from_date,
      to_date LIKE /psyng/mcuser-to_date,
      approved LIKE /psyng/mcuser-approved,
     END OF mcuser.

DATA: gt_mcuser LIKE mcuser OCCURS 0 WITH HEADER LINE.
DATA: mcuser_woaudtr LIKE STANDARD TABLE OF mcuser INITIAL SIZE 0 WITH
      HEADER LINE.
DATA: l_sort TYPE slis_t_sortinfo_alv.
DATA: gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

TYPES : BEGIN OF ty_usrgrp,
      bname LIKE usr02-bname,
      class LIKE usr02-class,
      END OF ty_usrgrp.

DATA gt_usrgrp TYPE TABLE OF ty_usrgrp WITH HEADER LINE.
DATA: g_current_user TYPE sy-uname. "C0700
*DATA lt_usrgrp TYPE TABLE OF ty_usrgrp.

SELECTION-SCREEN: BEGIN OF BLOCK bywhat WITH FRAME TITLE text-004.
SELECT-OPTIONS:   userid FOR /psyng/mcuser-userid,  "user ID
                  s_class FOR /psyng/mcusrgrp-class,   "User grp
                  contid FOR /psyng/mchdr-contid,  "control ID
                  auditor FOR /psyng/mcuser-userid.  "AUDITOR
PARAMETERS: sodcon AS CHECKBOX DEFAULT 'X'.
SELECT-OPTIONS:   conid FOR /psyng/conflict-conid.  "conflict ID
SELECTION-SCREEN: SKIP 1.
PARAMETERS: criaut AS CHECKBOX DEFAULT ' '.
SELECT-OPTIONS:   swaudid FOR /psyng/swaudhdr-swaudid. "Critical Auth ID
SELECTION-SCREEN: SKIP 1.
PARAMETERS :      sodvrsio LIKE /psyng/conflict-vrsio .
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: expcn AS CHECKBOX DEFAULT ' '.
SELECTION-SCREEN COMMENT 3(45) text-013 FOR FIELD expcn.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: END OF BLOCK bywhat.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM exelog.

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
  PERFORM get_mc_content.

*  Start of mitigation assignment to critical authorizatoins
  IF criaut = 'X'.
    PERFORM get_miti_cri_auths.
    APPEND LINES OF gt_mcuser TO mcuser.
  ENDIF.
***  Auhthority check for Username, company & group
  PERFORM authority_check.
** Get Full Names for User ID & auditors
  PERFORM get_full_names.

  IF gf_missing_auth_ugroup = 'X'.
  MESSAGE s398(00) WITH 'Missing some user group authorizations.'(001).
  ENDIF.

  IF mcuser[] IS INITIAL.
    MESSAGE s150(/psyng/sw).
    EXIT.
  ENDIF.

  PERFORM output_alv.

*&---------------------------------------------------------------------*
*&      Form  get_mc_content
*&---------------------------------------------------------------------*
FORM get_mc_content.
  DATA: lt_mcuser TYPE TABLE OF /psyng/mcuser WITH HEADER LINE.
  DATA: lt_mcgrp TYPE TABLE OF /psyng/mcusrgrp INITIAL SIZE 0 WITH
  HEADER LINE,
  lt_conflicts TYPE HASHED  TABLE OF /psyng/conflict
      WITH UNIQUE KEY conid
      WITH HEADER LINE.
  TYPES : BEGIN OF typ_mchdr,
          contid TYPE /psyng/contid,
          description TYPE /psyng/desc,
          type TYPE /psyng/mittype,
          type_text TYPE /psyng/longvalue,
          END OF typ_mchdr.
  DATA : lt_mchdr TYPE HASHED TABLE OF typ_mchdr
  WITH HEADER LINE
  WITH UNIQUE KEY contid.

  DATA: l_auditor TYPE /psyng/mcauditor-auditor,
        l_company TYPE /psyng/mcauditor-company,
       l_reject  TYPE /psyng/bapiflagx.

*--Get conflict descriptions
  SELECT DISTINCT conid  description FROM /psyng/conflict INTO
  CORRESPONDING FIELDS OF TABLE lt_conflicts
  WHERE conid  IN conid AND vrsio = sodvrsio.
*--Get Mitigation decriptions
  SELECT DISTINCT
  m~contid AS contid
  m~description AS description
  t~type AS type
  t~text AS type_text
  FROM /psyng/mchdr AS m LEFT OUTER JOIN
  /psyng/sw_mctype AS t ON m~type = t~type
  INTO
 CORRESPONDING FIELDS OF TABLE lt_mchdr
 WHERE m~contid  IN contid .


  SELECT bname class
   FROM usr02
   INTO TABLE gt_usrgrp
   WHERE bname IN userid
   AND class IN s_class.


  IF sodcon = 'X'.

    IF expcn = 'X'.
      if not gt_usrgrp[] is initial.
        SELECT *                 "#EC CI_NO_TRANSFORM
        INTO TABLE lt_mcuser
        FROM /psyng/mcuser
        FOR ALL ENTRIES IN gt_usrgrp[]
               WHERE userid = gt_usrgrp-bname AND
                     conid  IN conid   AND
                     contid IN contid  AND
                     vrsio  =  sodvrsio.
        SELECT *                 "#EC CI_NO_TRANSFORM
        INTO TABLE lt_mcgrp
        FROM /psyng/mcusrgrp
        FOR ALL ENTRIES IN gt_usrgrp[]
        WHERE class = gt_usrgrp-class AND
              conid  IN conid   AND
              contid IN contid  AND
              vrsio  =  sodvrsio.
      endif.
    ELSEIF expcn EQ space.
      if not gt_usrgrp[] is initial.
        SELECT *               "#EC CI_NO_TRANSFORM
        INTO TABLE lt_mcuser
        FROM /psyng/mcuser
               FOR ALL ENTRIES IN gt_usrgrp[]
               WHERE userid = gt_usrgrp-bname AND
                       conid     IN conid    AND
                       contid    IN contid   AND
                       vrsio     =  sodvrsio AND
                       from_date LE sy-datum AND
                       to_date   GE sy-datum.
        SELECT *                "#EC CI_NO_TRANSFORM
        INTO TABLE lt_mcgrp
        FROM /psyng/mcusrgrp
        FOR ALL ENTRIES IN gt_usrgrp[]
        WHERE class = gt_usrgrp-class AND
              conid     IN conid    AND
              contid    IN contid   AND
              vrsio     =  sodvrsio AND
              from_date LE sy-datum AND
              to_date   GE sy-datum.
      endif.
    ENDIF.
    SORT gt_usrgrp.
    SORT lt_mcuser BY userid.
    SORT lt_mcgrp BY class.
    LOOP AT gt_usrgrp.
      LOOP AT lt_mcgrp WHERE class = gt_usrgrp-class.
        mcuser_woaudtr-contid = lt_mcgrp-contid.
        mcuser_woaudtr-conid = lt_mcgrp-conid.
        mcuser_woaudtr-asg_grp = 'X'.
        mcuser_woaudtr-asg_usr = ' '.
        mcuser_woaudtr-class = gt_usrgrp-class.
        mcuser_woaudtr-userid = gt_usrgrp-bname.
        mcuser_woaudtr-vrsio = lt_mcgrp-vrsio.
        mcuser_woaudtr-from_date = lt_mcgrp-from_date.
        mcuser_woaudtr-to_date = lt_mcgrp-to_date.
        mcuser_woaudtr-approved = lt_mcgrp-approved.
        mcuser_woaudtr-auditor = lt_mcgrp-auditor.
        APPEND mcuser_woaudtr.
      ENDLOOP.

      LOOP AT lt_mcuser WHERE userid = gt_usrgrp-bname.
        READ TABLE mcuser_woaudtr WITH KEY contid = lt_mcuser-contid
        conid = lt_mcuser-conid
        class = gt_usrgrp-class
        userid = lt_mcuser-userid.
        IF sy-subrc <> 0.
          mcuser_woaudtr-contid = lt_mcuser-contid.
          mcuser_woaudtr-conid = lt_mcuser-conid.
          mcuser_woaudtr-asg_usr = 'X'.
          mcuser_woaudtr-asg_grp = ' '.
          mcuser_woaudtr-class = gt_usrgrp-class.
          mcuser_woaudtr-userid = lt_mcuser-userid.
          mcuser_woaudtr-vrsio = lt_mcuser-vrsio.
          mcuser_woaudtr-from_date = lt_mcuser-from_date.
          mcuser_woaudtr-to_date = lt_mcuser-to_date.
          mcuser_woaudtr-approved = lt_mcuser-approved.
          mcuser_woaudtr-auditor = lt_mcuser-auditor.
          APPEND mcuser_woaudtr.
        ELSE.
************** MODIFY AFTER MAIL  ****************************
          IF lt_mcuser-from_date <> mcuser_woaudtr-from_date OR
          lt_mcuser-to_date <> mcuser_woaudtr-to_date OR
          lt_mcuser-approved <> mcuser_woaudtr-approved.
            mcuser_woaudtr-contid = lt_mcuser-contid.
            mcuser_woaudtr-conid = lt_mcuser-conid.
            mcuser_woaudtr-asg_usr = 'X'.
            mcuser_woaudtr-asg_grp = ' '.
            mcuser_woaudtr-class = gt_usrgrp-class.
            mcuser_woaudtr-userid = lt_mcuser-userid.
            mcuser_woaudtr-vrsio = lt_mcuser-vrsio.
            mcuser_woaudtr-from_date = lt_mcuser-from_date.
            mcuser_woaudtr-to_date = lt_mcuser-to_date.
            mcuser_woaudtr-approved = lt_mcuser-approved.
            mcuser_woaudtr-auditor = lt_mcuser-auditor.
            APPEND mcuser_woaudtr.
          ELSE.
***************************************************************
            mcuser_woaudtr-asg_usr = 'X'.
            MODIFY mcuser_woaudtr  INDEX sy-tabix TRANSPORTING asg_usr.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    SORT mcuser_woaudtr BY contid conid
    class userid vrsio auditor from_date to_date approved.
    DELETE ADJACENT DUPLICATES FROM mcuser_woaudtr COMPARING
    contid conid class userid vrsio auditor from_date to_date approved.

*DHO 20101202
**Authorization check
*    DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
*           lf_reject TYPE flag.
*    LOOP AT mcuser_woaudtr.
*      lt_uinfo-bname = mcuser_woaudtr-userid.
*      APPEND lt_uinfo.
*    ENDLOOP.
*
*    CHECK NOT lt_uinfo[] IS INITIAL.
*    CALL FUNCTION '/PSYNG/SW_USER_INFO'
*     EXPORTING
*       vrsio                    = sodvrsio
**       ENHANCED_SCANTABLE       = ''
*       i_name_only              = 'X'
*       i_mr_company             = 'X'
*      TABLES
*        sw_uinfo                 = lt_uinfo.
*    LOOP AT lt_uinfo.
*      PERFORM check_rpoug_auth USING lt_uinfo sodvrsio
*                             CHANGING lf_reject.
*      IF lf_reject = 'X'.
*        DELETE mcuser_woaudtr WHERE userid = lt_uinfo-bname.
*        gf_missing_auth_ugroup = 'X'.
*      ELSE.
*        mcuser_woaudtr-name_text = lt_uinfo-name_text.
*        MODIFY mcuser_woaudtr TRANSPORTING name_text
*        WHERE userid = lt_uinfo-bname.
*      ENDIF.
*    ENDLOOP.
*
*




    SORT mcuser_woaudtr BY contid.
    LOOP AT mcuser_woaudtr.
      CLEAR l_reject.
*DHO 20101202
*      PERFORM check_ugroup_auth USING mcuser_woaudtr-userid
*                                CHANGING l_reject.
*      CHECK l_reject IS INITIAL.

      mcuser = mcuser_woaudtr.
      mcuser-type = 'S'.  "SOD Conflict
*--Get conflict description
      READ TABLE lt_conflicts WITH TABLE KEY conid = mcuser-conid.
      IF sy-subrc = 0.
        mcuser-condesc = lt_conflicts-description.
      ENDIF.
*--Get mitigation description
      READ TABLE lt_mchdr WITH TABLE KEY contid = mcuser-contid.
      IF sy-subrc = 0.
        mcuser-contdesc = lt_mchdr-description.
        mcuser-mittype  = lt_mchdr-type.
        mcuser-mittype_text  = lt_mchdr-type_text.

      ENDIF.

*   Nov 12, 2010 - Below code added because there can be auditor in
*   header table and the mitigation control can have multiple auditors
*   also.
      IF NOT mcuser-auditor IS INITIAL.
        PERFORM get_user_comp USING mcuser-auditor
                              CHANGING mcuser-company.
      ENDIF.

      APPEND mcuser.

*   end of insertion Nov 12, 2010

*      SELECT auditor company INTO (mcuser-auditor, mcuser-company)
*        FROM /psyng/mcauditor
*        WHERE contid   = mcuser_woaudtr-contid
*          AND auditor IN auditor.
*        APPEND mcuser.
*      ENDSELECT.

*   Nov 12, 2010 - Below code commented because there can be auditor in
*   header table and the mitigation control can have multiple auditors
*   also.
*      IF sy-subrc <> 0.
*        APPEND mcuser.
*      ENDIF.

    ENDLOOP.

    DELETE mcuser WHERE NOT auditor IN auditor.
    SORT mcuser BY contid conid class userid auditor from_date.
    DELETE ADJACENT DUPLICATES FROM mcuser COMPARING ALL FIELDS.
  ENDIF.  " if sodcon = 'X'.


*--Get auditor full names
*  FREE : lt_uinfo[].
*  LOOP AT mcuser.
*    CHECK NOT mcuser-auditor IS INITIAL.
*    lt_uinfo-bname = mcuser-auditor.
*    APPEND lt_uinfo.
*  ENDLOOP.
*  SORT lt_uinfo.
*  DELETE ADJACENT DUPLICATES FROM lt_uinfo.
*  CHECK NOT lt_uinfo[] IS INITIAL.
*  CALL FUNCTION '/PSYNG/SW_USER_INFO'
*   EXPORTING
*     vrsio                    = sodvrsio
**   ENHANCED_SCANTABLE       = ''
*     i_name_only              = 'X'
*     i_mr_company             = 'X'
*    TABLES
*      sw_uinfo                 = lt_uinfo.
*  LOOP AT lt_uinfo.
*    mcuser-auditor_name_text = lt_uinfo-name_text.
*    MODIFY mcuser TRANSPORTING auditor_name_text
*    WHERE auditor = lt_uinfo-bname.
*  ENDLOOP.


ENDFORM.                    " get_mc_content
*&---------------------------------------------------------------------*
*&      Form  output_alv
*&---------------------------------------------------------------------*
FORM output_alv.
  DATA: program         LIKE sy-repid,                   "For ALV call
        i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
        alv_layout      TYPE slis_layout_alv,            "For ALV call
        wa_fieldcat_alv TYPE slis_fieldcat_alv,
        ls_variant      TYPE disvariant.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'MCUSER'
            i_inclname         = program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  wa_fieldcat_alv-seltext_s = 'Description'(014).
  wa_fieldcat_alv-seltext_m = 'Mit. Cont. Description'(015).
  wa_fieldcat_alv-seltext_l = 'Mitigation Control ID Description'(016).
  wa_fieldcat_alv-reptext_ddic = 'Mit. Cont. Description'(015).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CONTDESC'.

  wa_fieldcat_alv-seltext_s = 'Description'(017).
  wa_fieldcat_alv-seltext_m = 'Mit. Type Description'(018).
  wa_fieldcat_alv-seltext_l = 'Mitigation Type description'(019).
  wa_fieldcat_alv-reptext_ddic = 'Mit. Type Description'(018).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'MITTYPE_TEXT'.

  wa_fieldcat_alv-seltext_l = 'Version'(008).
  wa_fieldcat_alv-seltext_m = 'Version'(008).
  wa_fieldcat_alv-seltext_s = 'Version'(008).
  wa_fieldcat_alv-reptext_ddic = 'Version'(008).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'VRSIO'.
*******************************************
  wa_fieldcat_alv-seltext_l = 'Auditor'(003).
  wa_fieldcat_alv-seltext_m = 'Auditor'(003).
  wa_fieldcat_alv-seltext_s = 'Auditor'(003).
  wa_fieldcat_alv-reptext_ddic = 'Auditor'(003).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUDITOR'.

  wa_fieldcat_alv-seltext_l = 'Object ID'(011).
  wa_fieldcat_alv-seltext_m = 'Object ID'(011).
  wa_fieldcat_alv-seltext_s = 'Object ID'(011).
  wa_fieldcat_alv-reptext_ddic = 'Object ID'(011).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CONID'.
******************************************
**  * *  rkanaka latest changes
  wa_fieldcat_alv-seltext_l = 'Assigned to Group'(005).
  wa_fieldcat_alv-seltext_m = 'Assigned to Group'(005).
  wa_fieldcat_alv-seltext_s = 'Assigned to Group'(005).
  wa_fieldcat_alv-reptext_ddic = 'Assigned to Group'(005).
  wa_fieldcat_alv-checkbox = 'X'.

* *  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
  wa_fieldcat_alv-just = 'X'.

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                   WHERE
                      fieldname = 'ASG_GRP'.

  wa_fieldcat_alv-seltext_l = 'Assigned to User'(006).
  wa_fieldcat_alv-seltext_m = 'Assigned to User'(006).
  wa_fieldcat_alv-seltext_s = 'Assigned to User'(006).
  wa_fieldcat_alv-reptext_ddic = 'Assigned to User'(006).
  wa_fieldcat_alv-checkbox = 'X'.

* *  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
  wa_fieldcat_alv-just = 'X'.


  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                   WHERE
                      fieldname = 'ASG_USR'.

  wa_fieldcat_alv-seltext_l = 'Approved'(007).
  wa_fieldcat_alv-seltext_m = 'Approved'(007).
  wa_fieldcat_alv-seltext_s = 'Approved'(007).
  wa_fieldcat_alv-reptext_ddic = 'Approved'(007).
  wa_fieldcat_alv-checkbox = 'X'.

* *  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
  wa_fieldcat_alv-just = 'X'.


  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                   WHERE
                      fieldname = 'APPROVED'.

* *  rkanaka latest changes
*******************************************************
  wa_fieldcat_alv-seltext_l = 'Type'(009).
  wa_fieldcat_alv-seltext_m = 'Type'(009).
  wa_fieldcat_alv-seltext_s = 'Type'(009).
  wa_fieldcat_alv-reptext_ddic = 'Type'(009).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TYPE'.

  wa_fieldcat_alv-seltext_l = 'Company'(010).
  wa_fieldcat_alv-seltext_m = 'Company'(010).
  wa_fieldcat_alv-seltext_s = 'Company'(010).
  wa_fieldcat_alv-reptext_ddic = 'Company'(010).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'COMPANY'.

*  wa_fieldcat_alv-seltext_l = text-012.
*  wa_fieldcat_alv-seltext_m = text-012.
*  wa_fieldcat_alv-seltext_s = text-012.
*  wa_fieldcat_alv-reptext_ddic = text-012.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'MITTYPE_TEXT'.

  PERFORM build_sort.
***************************************
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = program
            is_layout          = alv_layout
            it_fieldcat        = i_fieldcat_alv
            it_sort            = l_sort
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = mcuser
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_alv

*&---------------------------------------------------------------------*
*&      Form  check_ugroup_auth
*&---------------------------------------------------------------------*
*       Check authority to user group
*----------------------------------------------------------------------*
*      -->I_BNAME   User ID
*      <--E_REJECT  Reject record?  X = Reject, Space = Keep
*----------------------------------------------------------------------*
FORM check_ugroup_auth USING    i_bname TYPE usr02-bname
                       CHANGING e_reject TYPE /psyng/bapiflagx.
*  STATICS: BEGIN OF lt_user OCCURS 0,
*             bname  TYPE usr02-bname,
*             reject TYPE /psyng/bapiflagx,
*           END OF lt_user,
*
*           BEGIN OF lt_ugroup OCCURS 0,
*             class  TYPE usr02-class,
*             reject TYPE /psyng/bapiflagx,
*           END OF lt_ugroup.
*
*  DATA: l_class        TYPE usr02-class,
*        l_user_tabix   TYPE i,
*        l_ugroup_tabix TYPE i.
*
** Check if user has already been found
*  READ TABLE lt_user WITH KEY bname = i_bname BINARY SEARCH.
*  IF sy-subrc = 0.
*    e_reject = lt_user-reject.
*    EXIT.
*  ENDIF.
*
*  l_user_tabix = sy-tabix.
*
*  SELECT SINGLE class INTO l_class FROM usr02
*                WHERE bname = i_bname.
*
** Check if user group has already been found
*  READ TABLE lt_ugroup WITH KEY class = l_class BINARY SEARCH.
*  IF sy-subrc = 0.
*    lt_user-bname  = i_bname.
*    lt_user-reject = lt_ugroup-reject.
*    INSERT lt_user INDEX l_user_tabix.
*
*    e_reject = lt_ugroup-reject.
*    EXIT.
*  ENDIF.
*
*  l_ugroup_tabix = sy-tabix.
*
*  IF NOT l_class IS INITIAL.
**DHO 20101202
**    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
**             ID 'CLASS' FIELD l_class.
*    IF sy-subrc <> 0.
*      gf_missing_auth_ugroup = 'X'.
*      lt_ugroup-reject       = 'X'.
*      lt_user-reject         = 'X'.
*      e_reject               = 'X'.
*    ENDIF.
*  ENDIF.
*
*  lt_user-bname = i_bname.
*  INSERT lt_user INDEX l_user_tabix.
*  lt_ugroup-class = l_class.
*  INSERT lt_ugroup INDEX l_ugroup_tabix.
ENDFORM.                    " check_ugroup_auth
*&---------------------------------------------------------------------*
*&      Form  BUILD_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_sort.
  DATA: w_sort TYPE slis_sortinfo_alv.

  w_sort-spos = '1'.
  w_sort-fieldname = 'TYPE'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '2'.
  w_sort-fieldname = 'CONTID'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '3'.
  w_sort-fieldname = 'CONTDESC'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '4'.
  w_sort-fieldname = 'MITTYPE'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '5'.
  w_sort-fieldname = 'MITTYPE_TEXT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '6'.
  w_sort-fieldname = 'CONID'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '7'.
  w_sort-fieldname = 'CONDESC'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '8'.
  w_sort-fieldname = 'CLASS'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '9'.
  w_sort-fieldname = 'USERID'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '10'.
  w_sort-fieldname = 'NAME_TEXT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '11'.
  w_sort-fieldname = 'ASG_USR '.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '12'.
  w_sort-fieldname = 'ASG_GRP'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '13'.
  w_sort-fieldname = 'AUDITOR'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '14'.
  w_sort-fieldname = 'COMPANY'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '15'.
  w_sort-fieldname = 'AUDITOR_NAME_TEXT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '16'.
  w_sort-fieldname = 'FROM_DATE'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

ENDFORM.                    " BUILD_SORT
*&---------------------------------------------------------------------*
*&      Form  get_miti_cri_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_miti_cri_auths.
  gt_mcuser-type = 'C'.  "critical authorization
  gt_mcuser-asg_usr = 'X'.
  SORT gt_usrgrp BY bname.

  IF expcn = 'X'.

    SELECT contid swaudid userid vrsio auditor from_date
            to_date approved
      INTO (gt_mcuser-contid, gt_mcuser-conid, gt_mcuser-userid,
            gt_mcuser-vrsio, gt_mcuser-auditor, gt_mcuser-from_date,
            gt_mcuser-to_date, gt_mcuser-approved)
      FROM /psyng/mccauser
      WHERE userid IN userid   AND
            swaudid IN swaudid AND
            contid IN contid   AND
            vrsio = sodvrsio   AND
***  Case 3455 Bug 1990 Item 3 - Only auditor in selection screen should
***  be displayed
          ( auditor IN auditor
**          OR auditor = space
          ) .

*     get only the user in selection screen user groups
      READ TABLE gt_usrgrp WITH KEY bname = gt_mcuser-userid.
      CHECK gt_usrgrp-class IN s_class.
      gt_mcuser-class = gt_usrgrp-class.

*     if there is an auditor defined in the assignment table
      IF NOT gt_mcuser-auditor IS INITIAL.

        PERFORM get_user_comp USING gt_mcuser-auditor
                               CHANGING gt_mcuser-company.
       ENDIF.

        APPEND gt_mcuser.
**     get only the auditors in selection screen auditors
*      SELECT contid auditor company
*        INTO (/psyng/mcauditor-contid, /psyng/mcauditor-auditor,
*              /psyng/mcauditor-company)
*        FROM /psyng/mcauditor
*        WHERE contid = gt_mcuser-contid AND
*              auditor IN auditor.
*
*        gt_mcuser-auditor = /psyng/mcauditor-auditor.
*        gt_mcuser-company = /psyng/mcauditor-company.
*        APPEND gt_mcuser.
*      ENDSELECT.   "/psyng/mcauditor

**     if no auditors are assigned in auditors table
*      CHECK sy-subrc NE 0.
*      APPEND gt_mcuser.

    ENDSELECT.     "/psyng/mccauser

  ELSE.   "only include valid mitigation assignments

    SELECT contid swaudid userid vrsio auditor from_date
            to_date approved
      INTO (gt_mcuser-contid, gt_mcuser-conid, gt_mcuser-userid,
            gt_mcuser-vrsio, gt_mcuser-auditor, gt_mcuser-from_date,
            gt_mcuser-to_date, gt_mcuser-approved)
      FROM /psyng/mccauser
      WHERE userid IN userid      AND
            swaudid IN swaudid    AND
            contid IN contid      AND
            vrsio = sodvrsio      AND
            from_date LE sy-datum AND
            to_date GE sy-datum   AND
***  Case 3455 Bug 1990 Item 3 - Only auditor in selection screen should
***  be displayed
          ( auditor IN auditor
*          OR auditor = space
          ) .

*     get only the user in selection screen user groups
      READ TABLE gt_usrgrp WITH KEY bname = gt_mcuser-userid.
      CHECK gt_usrgrp-class IN s_class.
      gt_mcuser-class = gt_usrgrp-class.

*     if there is an auditor defined in the assignment table
      IF NOT gt_mcuser-auditor IS INITIAL.

        PERFORM get_user_comp USING gt_mcuser-auditor
                               CHANGING gt_mcuser-company.

      ENDIF.
      APPEND gt_mcuser.
*     get only the auditors in selection screen auditors
*      SELECT contid auditor company
*        INTO (/psyng/mcauditor-contid, /psyng/mcauditor-auditor,
*              /psyng/mcauditor-company)
*        FROM /psyng/mcauditor
*        WHERE contid = gt_mcuser-contid AND
*              auditor IN auditor.
*
*        gt_mcuser-auditor = /psyng/mcauditor-auditor.
*        gt_mcuser-company = /psyng/mcauditor-company.
*        APPEND gt_mcuser.
*      ENDSELECT.     "/psyng/mcauditor

**     if no auditors are assigned in auditors table
*      CHECK sy-subrc NE 0.
*      APPEND gt_mcuser.

    ENDSELECT.    "/psyng/mccauser
  ENDIF.



  SORT gt_mcuser.
  DELETE ADJACENT DUPLICATES FROM gt_mcuser COMPARING ALL FIELDS.
*--Fill text fields
 DATA : lt_swauds TYPE HASHED TABLE OF /psyng/swaudhdr WITH HEADER LINE
  WITH UNIQUE KEY swaudid.
  TYPES : BEGIN OF typ_mchdr,
          contid TYPE /psyng/contid,
          description TYPE /psyng/desc,
          type TYPE /psyng/mittype,
          type_text TYPE /psyng/longvalue,
          END OF typ_mchdr.
  DATA : lt_mchdr TYPE HASHED TABLE OF typ_mchdr  WITH HEADER LINE
  WITH UNIQUE KEY contid.


*--Get Mitigation decriptions
  SELECT DISTINCT
  m~contid AS contid
  m~description AS description
  t~type AS type
  t~text AS type_text
  FROM /psyng/mchdr AS m LEFT OUTER JOIN
  /psyng/sw_mctype AS t ON m~type = t~type
  INTO
 CORRESPONDING FIELDS OF TABLE lt_mchdr
 WHERE m~contid  IN contid .


  SELECT swaudid description FROM /psyng/swaudhdr
  INTO CORRESPONDING FIELDS OF TABLE lt_swauds
  WHERE swaudid IN swaudid AND vrsio = sodvrsio .

  FIELD-SYMBOLS : <mcuser> LIKE LINE OF gt_mcuser.
  LOOP AT gt_mcuser ASSIGNING <mcuser>.
*--Get CA description
    READ TABLE lt_swauds WITH TABLE KEY swaudid = <mcuser>-conid.
    IF sy-subrc = 0.
      <mcuser>-condesc = lt_swauds-description.
    ENDIF.
*--Get mitigation description
    READ TABLE lt_mchdr WITH TABLE KEY contid = <mcuser>-contid.
    IF sy-subrc = 0.
      <mcuser>-contdesc = lt_mchdr-description.
      <mcuser>-mittype  = lt_mchdr-type.
      <mcuser>-mittype_text  = lt_mchdr-type_text.
    ENDIF.


  ENDLOOP.



ENDFORM.                    " get_miti_cri_auths

*---------------------------------------------------------------------*
*       FORM check_rpoug_auth                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_UINFO                                                      *
*  -->  I_VRSIO                                                       *
*  -->  EF_REJECT                                                     *
*---------------------------------------------------------------------*
FORM check_rpoug_auth USING    is_uinfo TYPE /psyng/sw_uinfo
                               i_vrsio  TYPE /psyng/sodvrsio
                      CHANGING ef_reject TYPE flag.
  TYPES : BEGIN OF typ_rpoug ,
    vrsio TYPE /psyng/sodvrsio,
    class TYPE xuclass,
    company TYPE char20,
    rejected TYPE flag,
    END OF typ_rpoug.
  STATICS : lt_rpoug TYPE HASHED TABLE OF   typ_rpoug WITH UNIQUE KEY
   vrsio class company WITH HEADER LINE.

  READ TABLE lt_rpoug WITH TABLE KEY vrsio = i_vrsio
                                     class = is_uinfo-class
                                     company = is_uinfo-company.
  IF sy-subrc = 0.
    ef_reject =  lt_rpoug-rejected.
  ELSE.
    lt_rpoug-vrsio = i_vrsio.
    lt_rpoug-class = is_uinfo-class.
    lt_rpoug-company = is_uinfo-company.
    IF NOT is_uinfo-class IS INITIAL AND
       NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ENDIF.
    ef_reject =  lt_rpoug-rejected.
    INSERT TABLE lt_rpoug.
  ENDIF.
  CLEAR lt_rpoug.

ENDFORM.                    " check_rpoug_auth

*&---------------------------------------------------------------------*
*&      Form  get_user_comp
*&---------------------------------------------------------------------*
*       Get user's company
*----------------------------------------------------------------------*
*      -->I_BNAME    User ID
*      <--E_COMPANY  Company
*----------------------------------------------------------------------*
FORM get_user_comp USING    i_bname TYPE /psyng/mcauditor-auditor
                   CHANGING e_company TYPE /psyng/mcauditor-company.
  TYPES: BEGIN OF t_user,
           bname   TYPE /psyng/sw_uinfo-bname,
           company TYPE /psyng/sw_uinfo-company,
         END OF t_user.

  STATICS: lt_user TYPE HASHED TABLE OF t_user WITH UNIQUE KEY bname.

  DATA: ls_user  TYPE t_user,
        lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.


  CLEAR e_company.
  READ TABLE lt_user INTO ls_user WITH TABLE KEY bname = i_bname
             TRANSPORTING company.
  IF sy-subrc = 0.
    e_company = ls_user-company.
    EXIT.
  ENDIF.

  lt_uinfo-bname = i_bname.
  APPEND lt_uinfo.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
       EXPORTING
            i_name_only  = 'X'
            i_mr_company = 'X'
       TABLES
            sw_uinfo     = lt_uinfo.

  READ TABLE lt_uinfo INDEX 1.
  ls_user-bname   = lt_uinfo-bname.
  ls_user-company = lt_uinfo-company.
  e_company       = lt_uinfo-company.
  INSERT ls_user INTO TABLE lt_user.
ENDFORM.                    " get_user_comp

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  authority_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM authority_check.
  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
          lf_reject TYPE flag.
  LOOP AT mcuser.
    lt_uinfo-bname = mcuser-userid.
    APPEND lt_uinfo.
  ENDLOOP.

  SORT lt_uinfo.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.
  CHECK NOT lt_uinfo[] IS INITIAL.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
   EXPORTING
     vrsio                    = sodvrsio
*       ENHANCED_SCANTABLE       = ''
     i_name_only              = 'X'
     i_mr_company             = 'X'
    TABLES
      sw_uinfo                 = lt_uinfo.
  LOOP AT lt_uinfo.
    PERFORM check_rpoug_auth USING lt_uinfo sodvrsio
                           CHANGING lf_reject.
    CHECK lf_reject = 'X'.
    DELETE mcuser WHERE userid = lt_uinfo-bname.
    gf_missing_auth_ugroup = 'X'.
  ENDLOOP.

ENDFORM.                    " authority_check
*&---------------------------------------------------------------------*
*&      Form  get_full_names
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_full_names.
  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
           lf_reject TYPE flag..
  LOOP AT mcuser.
    lt_uinfo-bname = mcuser-userid.
    APPEND lt_uinfo.
    CHECK NOT mcuser-auditor IS INITIAL.
    lt_uinfo-bname = mcuser-auditor.
    APPEND lt_uinfo.
  ENDLOOP.


  SORT lt_uinfo.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.
  CHECK NOT lt_uinfo[] IS INITIAL.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
   EXPORTING
     vrsio                    = sodvrsio
*   ENHANCED_SCANTABLE       = ''
     i_name_only              = 'X'
     i_mr_company             = 'X'
    TABLES
      sw_uinfo                 = lt_uinfo.
  LOOP AT lt_uinfo.
    mcuser-auditor_name_text = lt_uinfo-name_text.
    mcuser-name_text = lt_uinfo-name_text.

    MODIFY mcuser TRANSPORTING auditor_name_text
    WHERE auditor = lt_uinfo-bname.

    MODIFY mcuser TRANSPORTING name_text
    WHERE userid = lt_uinfo-bname.
  ENDLOOP.

ENDFORM.                    " get_full_names
