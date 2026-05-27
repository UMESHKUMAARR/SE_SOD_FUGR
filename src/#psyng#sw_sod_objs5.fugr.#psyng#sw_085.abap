FUNCTION /psyng/sw_085.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(I_MATRIX) TYPE  FLAG OPTIONAL
*"     VALUE(I_MITIGATION) TYPE  FLAG OPTIONAL
*"     VALUE(I_MITUSR) TYPE  FLAG OPTIONAL
*"     VALUE(I_USRGRP) TYPE  FLAG OPTIONAL
*"     VALUE(I_ASSROL) TYPE  FLAG OPTIONAL
*"     VALUE(I_AUTUSR) TYPE  FLAG OPTIONAL
*"     VALUE(I_AUTROL) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_FUNID STRUCTURE  /PSYNG/RANGE_FUNID OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_CONTID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      IT_TCODE STRUCTURE  /PSYNG/RANGE_TCODE OPTIONAL
*"      IT_AUDID STRUCTURE  /PSYNG/RANGE_SWAUDID OPTIONAL
*"      IT_AGR STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_PROFIL STRUCTURE  /PSYNG/RANGE_PROFILE OPTIONAL
*"      IT_CUSCON STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      IT_MCUSER STRUCTURE  /PSYNG/MCUSER OPTIONAL
*"      IT_MCUSRGRP STRUCTURE  /PSYNG/MCUSRGRP OPTIONAL
*"      IT_MCROLE STRUCTURE  /PSYNG/MCROLE OPTIONAL
*"      IT_MCCAUSER STRUCTURE  /PSYNG/MCCAUSER OPTIONAL
*"      IT_MCCAROLE STRUCTURE  /PSYNG/MCCAROLE OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_085'.
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

  DATA: BEGIN OF lt_function OCCURS 0,
          funid TYPE /psyng/function-function,
        END OF lt_function.

  DATA: BEGIN OF lt_conflict OCCURS 0,
          conid TYPE /psyng/conflict-conid,
        END OF lt_conflict.

  DATA:lt_swaudhdr     TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
       lt_swaudc2      TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
       lt_sw_cuscon    TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
       lf_missing_auth.

  DATA : lt_mcuser   TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
         lt_mccauser TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
         lt_mccarole TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE,
         lt_mcusrgrp TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
         lt_mcrole   TYPE TABLE OF /psyng/mcrole    WITH HEADER LINE,
         ls_mchdr    TYPE /psyng/mchdr.
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  DATA : lt_mcuser_t   TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
         lt_mccauser_t TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
         lt_mccarole_t TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE,
         lt_mcusrgrp_t TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
         lt_mcrole_t   TYPE TABLE OF /psyng/mcrole    WITH HEADER LINE.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
*  for version header change document
  DATA: ls_vrsio_o TYPE /psyng/swsodvers,
        ls_vrsio_n TYPE /psyng/swsodvers,
        l_objid    TYPE cdhdr-objectid,
        lt_cdtxt   TYPE TABLE OF cdtxt.
  RANGES: r_object FOR /psyng/texts-object.
  FIELD-SYMBOLS: <text> TYPE /psyng/texts.
* BOC by RGUPTA on 08.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700

  SELECT function INTO TABLE lt_function FROM /psyng/function
         WHERE function IN it_funid
           AND vrsio     = i_vrsio.

  LOOP AT lt_function.
    CALL FUNCTION '/PSYNG/SW_CR_DELETE_FUNCTION'
      EXPORTING
        i_vrsio        = i_vrsio
        i_funid        = lt_function-funid
      EXCEPTIONS
        not_authorized = 1
        not_exist      = 2
        locked         = 3
        OTHERS         = 4.                "#EC SAST_CI_GEN_CHECK
    "(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
*Begin of Addition:HBHALLA(PN-17432)(30/01/26)
      MESSAGE s113(/psyng/sw)
      WITH 'Not Authorized to Delete Functions'(e21)
      'in version '(e00) i_vrsio.
*End of Addition:HBHALLA(PN-17432)(30/01/26)
    ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.
  ENDLOOP.

  SELECT conid INTO TABLE lt_conflict FROM /psyng/conflict
         WHERE conid IN it_conid
           AND vrsio  = i_vrsio.

  LOOP AT lt_conflict.
    CALL FUNCTION '/PSYNG/SW_CR_DELETE_CONFLICT'
      EXPORTING
        i_vrsio        = i_vrsio
        i_conid        = lt_conflict-conid
      EXCEPTIONS
        not_authorized = 1
        not_exist      = 2
        locked         = 3
        OTHERS         = 4.                "#EC SAST_CI_GEN_CHECK
    "(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
*Begin of Addition:HBHALLA(PN-17432)(30/01/26)
      MESSAGE s113(/psyng/sw)
        WITH 'Not Authorized to Delete Conflicts'(e22)
        'in version '(e00) i_vrsio.
*End of Addition:HBHALLA(PN-17432)(30/01/26)
    ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.
  ENDLOOP.
** Begin changes DDHIMAN 03.12.19
* Org Level Analysis for SOD
  SELECT SINGLE vrsio FROM /psyng/swsodorgo INTO i_vrsio
    WHERE conid IN it_conid
           AND vrsio  = i_vrsio.
  IF sy-subrc EQ 0.
    LOOP AT lt_conflict.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT'      FIELD '06'
             ID 'Y&SW_VRSIO' FIELD i_vrsio
             ID 'Y&SW_CONID' FIELD lt_conflict-conid.
      IF sy-subrc EQ 0.
        DELETE FROM /psyng/swsodorgo  WHERE conid = lt_conflict-conid
                                       AND  vrsio = i_vrsio.

      ELSE.
        MESSAGE s113(/psyng/sw)
        WITH 'Missing authorization to delete Org Level Anl.'(e20)
        'in version '(e00) i_vrsio.
      ENDIF.
    ENDLOOP.
  ENDIF.
** End changes DDHIMAN 03.12.19
* Critical authorization header
  SELECT * FROM /psyng/swaudhdr INTO TABLE lt_swaudhdr
  WHERE swaudid IN it_audid
  AND vrsio    = i_vrsio.

** Change as of SE 3.1 to enable change docs
  LOOP AT lt_swaudhdr.
    CALL FUNCTION '/PSYNG/SW_CR_DELETE_CRI_AUTHS'
      EXPORTING
        i_vrsio        = i_vrsio
        i_swaudid      = lt_swaudhdr-swaudid
      EXCEPTIONS
        not_authorized = 1
        not_exist      = 2
        locked         = 3
        OTHERS         = 4.
    IF sy-subrc <> 0.
*Begin of Addition:HBHALLA(PN-17432)(30/01/26)
      MESSAGE s113(/psyng/sw)
      WITH 'Missing authorization to delete Critical Auths '(e23)
      'in version '(e00) i_vrsio.
*End of Addition:HBHALLA(PN-17432)(30/01/26)
    ENDIF.

  ENDLOOP.

***Custom Conflicts
  SELECT * FROM /psyng/sw_cuscon INTO TABLE lt_sw_cuscon
  WHERE conid IN it_cuscon
  AND vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    LOOP AT lt_sw_cuscon.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                 ID 'ACTVT' FIELD '06'
                 ID 'Y&SW_CONID' FIELD lt_sw_cuscon-conid
                 ID 'Y&SW_VRSIO' FIELD i_vrsio.
      IF sy-subrc NE 0.
        lf_missing_auth = 'X'.
        DELETE lt_sw_cuscon.
      ENDIF.
    ENDLOOP.

    IF lf_missing_auth EQ 'X'.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing authorization to delete Custom Conflict '(e15)
      'in version '(e00) i_vrsio.
      CLEAR lf_missing_auth.
    ENDIF.
    DELETE /psyng/sw_cuscon FROM TABLE lt_sw_cuscon.
  ENDIF.

* Critical TCodes
  SELECT SINGLE vrsio FROM /psyng/critcodes INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
               ID 'ACTVT' FIELD '06'
               ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc EQ 0.
      DELETE FROM /psyng/critcodes WHERE tcode IN it_tcode
                                     AND vrsio  = i_vrsio.

      DELETE FROM /psyng/texts WHERE textname IN it_tcode
                                      AND vrsio    = i_vrsio
                                      AND object = 'X'.
    ELSE.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing authorization to delete Critical Tcode '(e16)
      'in version '(e00) i_vrsio.
    ENDIF.
  ENDIF.

* Critical roles
  SELECT SINGLE vrsio FROM /psyng/criroles INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
           ID 'ACTVT' FIELD '06'
           ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc EQ 0.
      DELETE FROM /psyng/criroles  WHERE agr_name IN it_agr
                                     AND vrsio     = i_vrsio.

      DELETE FROM /psyng/texts WHERE textname IN it_agr
                                     AND vrsio    = i_vrsio
                                     AND object = 'Q'.
    ELSE.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing authorization to delete Critical Roles '(e17)
      'in version '(e00) i_vrsio.
    ENDIF.
  ENDIF.

* Critical profiles
  SELECT SINGLE vrsio FROM /psyng/criprof INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
          ID 'ACTVT' FIELD '06'
          ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc EQ 0.
      DELETE FROM /psyng/criprof   WHERE profile IN it_profil
                                     AND vrsio = i_vrsio.

      DELETE FROM /psyng/texts WHERE textname IN it_profil
                                     AND vrsio    = i_vrsio
                                     AND object = 'P'.

    ELSE.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing authorization to delete Critical Profiles '(e18)
      'in version '(e00) i_vrsio.
    ENDIF.
  ENDIF.

*BOC UMITTAL PN-5186 : Control Mitigation Deletion
*--Delete everything fro mititgation as per selection
*--done on Selection Screen
** Mitigation assignment to users
  IF i_mitigation EQ 'X'.
    DATA: lt_mitdetails1  TYPE TABLE OF /psyng/mitigation_assignment
             WITH HEADER LINE.
    IF i_mitusr EQ 'X'.
      SELECT * FROM /psyng/mcuser
        INTO TABLE lt_mcuser
      WHERE vrsio EQ i_vrsio.
      LOOP AT lt_mcuser.
        ls_mchdr-contid = lt_mcuser-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcuser            = lt_mcuser
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.        "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcuser.
        "Delete Justifcations
        CLEAR : lt_mitdetails1.
        CLEAR : lt_mitdetails1[].
        MOVE-CORRESPONDING lt_mcuser TO lt_mitdetails1.
        lt_mitdetails1-type = '1'. "MC User"
        APPEND lt_mitdetails1.

        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment   = 'X'
            if_delete       = 'X'
            i_mcid          = lt_mcuser-contid
            is_assignment   = lt_mitdetails1
*                    TABLES
*           it_text         = lt_miti_text
          EXCEPTIONS
            invalid_input   = 1
            not_implemented = 2
            gos_failure     = 3
            OTHERS          = 4.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.
    ENDIF.
*** Mitigation assignments to user groups
    IF i_usrgrp EQ 'X'.
      SELECT * FROM /psyng/mcusrgrp
        INTO TABLE lt_mcusrgrp
      WHERE vrsio EQ i_vrsio.
      LOOP AT lt_mcusrgrp.
        ls_mchdr-contid = lt_mcusrgrp-contid.
        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcusrgrp          = lt_mcusrgrp
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.        "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcusrgrp.
        "Delete Justifcations
        CLEAR : lt_mitdetails1.
        CLEAR : lt_mitdetails1[].
        MOVE-CORRESPONDING lt_mcusrgrp TO lt_mitdetails1.
        lt_mitdetails1-type = '2'.
        APPEND lt_mitdetails1.

        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment   = 'X'
            if_delete       = 'X'
            i_mcid          = lt_mcusrgrp-contid
            is_assignment   = lt_mitdetails1
*                    TABLES
*           it_text         = lt_miti_text
          EXCEPTIONS
            invalid_input   = 1
            not_implemented = 2
            gos_failure     = 3
            OTHERS          = 4.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ENDLOOP.
    ENDIF.

*** Mitigation assignments to roles
    IF i_assrol EQ 'X'.
      SELECT * FROM /psyng/mcrole
        INTO TABLE lt_mcrole
      WHERE  vrsio EQ i_vrsio.

      LOOP AT lt_mcrole.
        ls_mchdr-contid = lt_mcrole-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcrole            = lt_mcrole
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.        "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcrole.
        CLEAR : lt_mitdetails1.
        CLEAR : lt_mitdetails1[].
        MOVE-CORRESPONDING lt_mcrole TO lt_mitdetails1.
        lt_mitdetails1-type = '4'.
        APPEND lt_mitdetails1.
        "Delete Justifcations
        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment   = 'X'
            if_delete       = 'X'
            i_mcid          = lt_mcrole-contid
            is_assignment   = lt_mitdetails1
*                    TABLES
*           it_text         = lt_miti_text
          EXCEPTIONS
            invalid_input   = 1
            not_implemented = 2
            gos_failure     = 3
            OTHERS          = 4.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.
    ENDIF.

*** Mitigation assignments to critical auths - users

    IF i_autusr EQ 'X'.
      SELECT * FROM /psyng/mccauser
        INTO TABLE lt_mccauser
       WHERE vrsio EQ i_vrsio.

      LOOP AT lt_mccauser.
        ls_mchdr-contid = lt_mccauser-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mccauser          = lt_mccauser
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.        "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mccauser.
        "Delete Justifcations
        CLEAR : lt_mitdetails1.
        CLEAR : lt_mitdetails1[].
        MOVE-CORRESPONDING lt_mccauser TO lt_mitdetails1.
        lt_mitdetails1-type = '3'.
        APPEND lt_mitdetails1.

        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment   = 'X'
            if_delete       = 'X'
            i_mcid          = lt_mccauser-contid
            is_assignment   = lt_mitdetails1
*                    TABLES
*           it_text         = lt_miti_text
          EXCEPTIONS
            invalid_input   = 1
            not_implemented = 2
            gos_failure     = 3
            OTHERS          = 4.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ENDLOOP.
    ENDIF.

*** Mitigation assignments to critical auths - roles
    IF i_autrol EQ 'X'.
      SELECT * FROM /psyng/mccarole
        INTO TABLE lt_mccarole
      WHERE vrsio EQ i_vrsio.
      LOOP AT lt_mccarole.
        ls_mchdr-contid = lt_mccarole-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mccarole          = lt_mccarole
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.        "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mccarole.
        "Delete Justifcations
        CLEAR : lt_mitdetails1.
        CLEAR : lt_mitdetails1[].
        MOVE-CORRESPONDING lt_mccarole TO lt_mitdetails1.
        lt_mitdetails1-type = '5'.
        APPEND lt_mitdetails1.

        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment   = 'X'
            if_delete       = 'X'
            i_mcid          = lt_mccarole-contid
            is_assignment   = lt_mitdetails1
*                    TABLES
*           it_text         = lt_miti_text
          EXCEPTIONS
            invalid_input   = 1
            not_implemented = 2
            gos_failure     = 3
            OTHERS          = 4.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion

** SOD Version Header in the end
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
          ID 'ACTVT' FIELD '06'
          ID 'Y&SW_VRSIO' FIELD i_vrsio.
  IF sy-subrc EQ 0.

    SELECT SINGLE * INTO ls_vrsio_o                  "#EC CI_SEL_NESTED
            FROM /psyng/swsodvers
                WHERE  vrsio = i_vrsio.
    l_objid = i_vrsio.
    DELETE FROM /psyng/swsodvers WHERE vrsio = i_vrsio.

    CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
      EXPORTING
        objectid                = l_objid
        tcode                   = sy-tcode
        utime                   = sy-uzeit
        udate                   = sy-datum
        username                = l_current_user "sy-uname C0700
        planned_change_number   = ' '
        object_change_indicator = 'D'
        planned_or_real_changes = 'R'
        no_change_pointers      = ' '
        n_psyng_swsodvers       = ls_vrsio_n
        o_psyng_swsodvers       = ls_vrsio_o
        upd_psyng_swsodvers     = 'D'
      TABLES
        icdtxt_vrsio            = lt_cdtxt.
    CLEAR ls_vrsio_o.
  ELSE.
    MESSAGE s113(/psyng/sw)
    WITH 'Missing authorization to delete version '(e19)
    i_vrsio.
  ENDIF.
*-- to delete all the texts for the conflicts, even if conflict does
*--not exists

  r_object-sign = 'I'.
  r_object-option = 'EQ'.

  r_object-low = 'C'.
  APPEND r_object.

  r_object-low = 'P'.
  APPEND r_object.

  r_object-low = 'Q'.
  APPEND r_object.

  r_object-low = 'X'.
  APPEND r_object.


  r_object-low = 'F'.
  APPEND r_object.

  r_object-low = 'M'.
  APPEND r_object.

  r_object-low = 'T'.
  APPEND r_object.

  DELETE FROM /psyng/texts WHERE vrsio = i_vrsio
                                 AND object IN r_object.


*  DELETE FROM /psyng/critcodes WHERE tcode IN it_tcode
*                                 AND vrsio  = i_vrsio.
*  DELETE FROM /psyng/swaudhdr  WHERE swaudid IN it_audid
*                                 AND vrsio    = i_vrsio.
*  DELETE FROM /psyng/swaudc2   WHERE vrsio    = i_vrsio
*                                 AND swaudid IN it_audid.
*  DELETE FROM /psyng/criroles  WHERE agr_name IN it_agr
*                                 AND vrsio     = i_vrsio.
*  DELETE FROM /psyng/criprof   WHERE profile IN it_profil
*                                 AND vrsio = i_vrsio.
*  DELETE FROM /psyng/sw_cuscon WHERE conid IN it_cuscon
*                                 AND vrsio = i_vrsio.

*  DELETE FROM /psyng/swsodvers WHERE vrsio = i_vrsio.


*  LOOP AT it_texts ASSIGNING <text>.
*    CASE <text>-object.
*** SE 3.1 Mitigations are version independent hence no need to delete
*** mitigation texts
**      WHEN 'M'.         "Mitigating controls
**        IF <text>-textname IN it_contid.
**          DELETE FROM /psyng/texts WHERE textname = <text>-textname
**                                     AND vrsio    = i_vrsio.
**        ENDIF.
**      WHEN 'T'.         "Critical auths
**        IF <text>-textname IN it_audid.
**          DELETE FROM /psyng/texts WHERE textname = <text>-textname
**                                     AND vrsio    = i_vrsio.
**        ENDIF.
*      WHEN 'Q'.         " Critical Roles
*        IF <text>-textname(30) IN it_agr.
*          DELETE FROM /psyng/texts WHERE textname = <text>-textname
*                                     AND vrsio    = i_vrsio.
*        ENDIF.
*      WHEN 'X'.           " Critical tcodes
*        IF <text>-textname(30) IN it_tcode.
*          DELETE FROM /psyng/texts WHERE textname = <text>-textname
*                                  AND vrsio    = i_vrsio.
*        ENDIF.
*      WHEN 'P' .          " Critical profiles
*        DELETE FROM /psyng/texts WHERE textname = <text>-textname
*                                AND vrsio    = i_vrsio.
*
*    ENDCASE.
*  ENDLOOP.
ENDFUNCTION.
