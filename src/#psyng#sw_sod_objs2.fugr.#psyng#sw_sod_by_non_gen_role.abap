*----------------------------------------------------------------------*
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

FUNCTION /psyng/sw_sod_by_non_gen_role.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(AGR_NAME_FM) TYPE  AGR_DEFINE-AGR_NAME
*"     VALUE(MATRIX_RFC) LIKE  RFCDES-RFCDEST OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      R1STOUTPUT STRUCTURE  /PSYNG/SW_SOD_R1STOUTPUT OPTIONAL
*"  EXCEPTIONS
*"      INVALID_MATRIX_RFC
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_BY_NON_GEN_ROLE'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026


  DATA: sap_all(1),  "Flag for user who has SAP_ALL profile
        subrc LIKE sy-subrc.  "return code

  DATA: objectcount_fm TYPE i,
        concount_fm    TYPE i,
        byobject  TYPE  char10.

  REFRESH: usertcode_fm, userprof, userauth_fm, susertcode,
           functtran, faobj, confdet, confs2.

  PERFORM fill_internal_tables USING matrix_rfc vrsio.

  REFRESH iagr_define.
  SELECT agr_name create_dat change_dat
             INTO CORRESPONDING FIELDS OF wa_iagr_define
             FROM agr_define
             WHERE agr_name = agr_name_fm.
    INSERT wa_iagr_define INTO TABLE iagr_define.
  ENDSELECT.

  DESCRIBE TABLE iagr_define LINES objectcount_fm.
  SELECT COUNT( * ) FROM /psyng/conflict
         INTO concount_fm.
*         WHERE conid IN spconfs.
  byobject = 'ROLE'.

  CALL FUNCTION '/PSYNG/SW_SOD_UPDATE_STAT'
    IN BACKGROUND TASK
    EXPORTING
      objectcount_fm       = objectcount_fm
      concount_fm          = concount_fm
      byobject             = byobject.
  COMMIT WORK.

  DESCRIBE TABLE iagr_define LINES trolecount.
  SORT iagr_define.
  LOOP AT iagr_define.
    SELECT * FROM agr_agrs WHERE agr_name = iagr_define-agr_name
                           AND   attributes <> 'X'.
      CLEAR: roleauth_fm, roletcode_fm, roleprof_fm.
      REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.

*      CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*           EXPORTING
*                agr_name  = agr_agrs-child_agr
*                bname     = ''
*           TABLES
*                roleauth  = roleauth_fm
*                roletcode = roletcode_fm
*                roleprof  = roleprof_fm
*                functtran = functtran
*                faobj     = faobj.

      CALL FUNCTION '/PSYNG/SW_GET_NG_ROLE_DATA'
           EXPORTING
                agr_name  = agr_agrs-child_agr
           TABLES
                roletcode = roletcode_fm
                roleprof  = roleprof_fm
                roleauth  = roleauth_fm
                functtran = functtran
                faobj     = faobj.


      CLEAR: wa_roletcode, wa_roleauth.
      LOOP AT roletcode_fm.
        wa_roletcode-agr_name = iagr_define-agr_name.
        wa_roletcode-tcode    = roletcode_fm-tcode.
        wa_roletcode-child_agr = roletcode_fm-agr_name.
        wa_roletcode-rfcdest   = roletcode_fm-rfcdest.
        INSERT wa_roletcode INTO TABLE roletcode.
      ENDLOOP.
*--Begin of placeholder tcodes
      CONCATENATE sy-sysid sy-mandt INTO rfcdest.
      LOOP AT functtran WHERE tcode CP
        /psyng/sw_cl_constants=>placeholder_tcode_prefix.
          wa_roletcode-agr_name  = iagr_define-agr_name.
          wa_roletcode-tcode     = functtran-tcode.
          wa_roletcode-rfcdest   = rfcdest.
          INSERT wa_roletcode INTO TABLE roletcode.
      ENDLOOP.
*--End of placeholder tcodes

      LOOP AT roleauth_fm.
        MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
        wa_roleauth-agr_name  = iagr_define-agr_name.
        wa_roleauth-child_agr = roleauth_fm-agr_name.
        INSERT wa_roleauth INTO TABLE roleauth.
      ENDLOOP.
    ENDSELECT.   "agr_agrs
    subrc = sy-subrc.

    CHECK subrc <> 0.  "next role if role is single

    CLEAR: roleauth_fm, roletcode_fm, roleprof_fm.
    REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.

*    CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*         EXPORTING
*              agr_name  = iagr_define-agr_name
*              bname     = ''
*         TABLES
*              roleauth  = roleauth_fm
*              roletcode = roletcode_fm
*              roleprof  = roleprof_fm
*              functtran = functtran
*              faobj     = faobj.

    CALL FUNCTION '/PSYNG/SW_GET_NG_ROLE_DATA'
         EXPORTING
              agr_name  = iagr_define-agr_name
         TABLES
              roletcode = roletcode_fm
              roleprof  = roleprof_fm
              roleauth  = roleauth_fm
              functtran = functtran
              faobj     = faobj.

    CLEAR: wa_roletcode, wa_roleauth.
    LOOP AT roletcode_fm.
      MOVE-CORRESPONDING roletcode_fm TO wa_roletcode.
      INSERT wa_roletcode INTO TABLE roletcode.
    ENDLOOP.
*--Begin of placeholder tcodes
      CONCATENATE sy-sysid sy-mandt INTO rfcdest.
      LOOP AT functtran WHERE tcode CP
        /psyng/sw_cl_constants=>placeholder_tcode_prefix.
          wa_roletcode-agr_name  = iagr_define-agr_name.
          wa_roletcode-tcode     = functtran-tcode.
          wa_roletcode-rfcdest   = rfcdest.
          INSERT wa_roletcode INTO TABLE roletcode.
      ENDLOOP.
*--End of placeholder tcodes

    LOOP AT roleauth_fm.
      MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
      INSERT wa_roleauth INTO TABLE roleauth.
    ENDLOOP.

  ENDLOOP.    "IAGR_DEFINE
  CLEAR: roleauth_fm, roletcode_fm, roleprof_fm.
  REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.

  CONCATENATE sy-sysid sy-mandt INTO rfcdest.
  LOOP AT roleauth.
    uniqueauths-rfcdest = rfcdest.
    uniqueauths-objct   = roleauth-objct.
    uniqueauths-auth    = roleauth-auth.
    APPEND uniqueauths.
  ENDLOOP.
  SORT uniqueauths.
  DELETE ADJACENT DUPLICATES FROM uniqueauths COMPARING ALL FIELDS.

  LOOP AT roletcode.
    wa_itcd-tcode = roletcode-tcode.
    wa_itcd-rfcdest = roletcode-rfcdest.
    INSERT wa_itcd INTO TABLE itcd.
  ENDLOOP.
  itcd2[] = itcd[].

  LOOP AT faobj.
    READ TABLE itcd WITH KEY tcode = faobj-tcode
                                     BINARY SEARCH
                                     TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    DELETE faobj.
  ENDLOOP.

  LOOP AT faobj.
    MOVE-CORRESPONDING faobj TO wa_tobjs1.
    INSERT wa_tobjs1 INTO TABLE tobjs3.
  ENDLOOP.
  tobjs1[] = tobjs3[].
  tobjs2[] = tobjs3[].

  LOOP AT functtran.
    READ TABLE itcd WITH KEY tcode = functtran-tcode
                                     BINARY SEARCH
                                     TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      DELETE functtran WHERE tcode = functtran-tcode.
    ENDIF.
  ENDLOOP.

  SORT: functtran, faobj.
*  CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_DATA'
*       TABLES
*            tcd         = itcd2
*            faobj       = faobj
*            functtran   = functtran
*            tcdaut      = itcdaut
*            uniqueauths = uniqueauths.
  LOOP AT iagr_define.
    SELECT * FROM agr_agrs WHERE agr_name = iagr_define-agr_name
                           AND   attributes <> 'X'.
      CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_NG'
           EXPORTING
                agr_name    = agr_agrs-child_agr
           TABLES
                tcd         = itcd2
                faobj       = faobj
                functtran   = functtran
                tcdaut      = itcdaut
                uniqueauths = uniqueauths.
    ENDSELECT.
    CHECK sy-subrc NE 0.  "check if role is single.
    CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_NG'
         EXPORTING
              agr_name    = iagr_define-agr_name
         TABLES
              tcd         = itcd2
              faobj       = faobj
              functtran   = functtran
              tcdaut      = itcdaut
              uniqueauths = uniqueauths.
  ENDLOOP.
  SORT: faobj.

  SORT itcdaut.
  DELETE ADJACENT DUPLICATES FROM itcdaut.
  PERFORM compare_soddef_with_auth_role.

  SORT routdet3.
  LOOP AT routdet3.
    r1stoutput-agr_name = routdet3-agr_name.
    r1stoutput-conid = routdet3-conid.
    r1stoutput-description = routdet3-description.
    APPEND r1stoutput.
  ENDLOOP.
  SORT r1stoutput.
  DELETE ADJACENT DUPLICATES FROM r1stoutput COMPARING ALL FIELDS.
  MESSAGE s208(00) WITH text-001.
ENDFUNCTION.

*---------------------------------------------------------------------*
*       FORM compare_soddef_with_auth_role                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM compare_soddef_with_auth_role.

  DATA: roletcode_idx   TYPE i,
        sodtab1_idx     TYPE i,
        roleauth_idx    TYPE i,
        tobjs1_idx      TYPE i,
        roletcode2_idx  TYPE i,
        sodtab2_idx     TYPE i,
        roleauth2_idx   TYPE i,
        tobjs2_idx      TYPE i,
        routdet_idx     TYPE i,
        routdet2_idx    TYPE i,
        tmp_functionid  LIKE confdet-functionid.

  roletcode_idx = 1.  sodtab1_idx = 1. roleauth_idx = 1.
  roletcode2_idx = 1. sodtab2_idx = 1. roleauth2_idx = 1.
  tobjs2_idx = 1.     tobjs1_idx = 1.
  routdet_idx = 1.  routdet2_idx = 1.

  roleauth2[]  = roleauth[].
  roletcode2[] = roletcode[].
  functtran2[] = functtran[].
  itcdaut2[]   = itcdaut[].

  CLEAR: start, finish.
  wa_tobjs1-userhas = 'Y'.
  GET RUN TIME FIELD start.
  LOOP AT iagr_define.
*    PERFORM refresh_internal_tables.

    READ TABLE roletcode WITH KEY agr_name = iagr_define-agr_name
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
    roletcode_idx = sy-tabix.
    LOOP AT roletcode FROM roletcode_idx WHERE
                                  agr_name = iagr_define-agr_name.
      roletcode_idx = sy-tabix.
      LOOP AT functtran WHERE tcode = roletcode-tcode.
        LOOP AT confdet WHERE functionid = functtran-functionid.
          READ TABLE faobj WITH KEY funid = functtran-functionid
                                    tcode = roletcode-tcode
                                    BINARY SEARCH
                                    TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            wa_routdet-agr_name    = roletcode-agr_name.
            wa_routdet-conid       = confdet-conid.
            wa_routdet-functionid  = functtran-functionid.
*            wa_routdet-tcode       = roletcode-tcode.
*            wa_routdet-objct       = 'S_TCODE'.
**            wa_routdet-auth        = roletcode-auth.
*            wa_routdet-field       = 'TCD'.
*            wa_routdet-von         = roletcode-tcode.
*            wa_routdet-bis         = ''.
*            wa_routdet-description = ''. "not for performance
*            wa_routdet-child_agr   = roletcode-child_agr.
            INSERT wa_routdet INTO TABLE routdet5.
            CLEAR wa_routdet.
          ENDIF.
          READ TABLE itcdaut WITH KEY rfcdest = roletcode-rfcdest
                                       funid  = functtran-functionid
                                       tcode  = roletcode-tcode
                                       BINARY SEARCH
                                       TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
          itcdaut_idx = sy-tabix.
          LOOP AT itcdaut FROM itcdaut_idx WHERE
                                      rfcdest = roletcode-rfcdest AND
                                       funid  = functtran-functionid AND
                                        tcode = roletcode-tcode.
            READ TABLE roleauth WITH KEY agr_name = roletcode-agr_name
                                         rfcdest  = roletcode-rfcdest
                                         objct    = itcdaut-objct
                                         auth     = itcdaut-auth
                                         BINARY SEARCH
                                         TRANSPORTING NO FIELDS.
            roleauth_idx = sy-tabix.
            LOOP AT roleauth FROM roleauth_idx WHERE
                                   agr_name = roletcode-agr_name AND
                                   rfcdest  = roletcode-rfcdest  AND
                                   objct    = itcdaut-objct      AND
                                   auth     = itcdaut-auth.
              roleauth_idx = sy-tabix.
              wa_routdet-agr_name    = roletcode-agr_name.
              wa_routdet-conid       = confdet-conid.
              wa_routdet-functionid  = functtran-functionid.
              wa_routdet-rfcdest     = roletcode-rfcdest.
*              wa_routdet-tcode       = roletcode-tcode.
*              wa_routdet-objct       = 'S_TCODE'.
*              wa_routdet-field       = 'TCD'.
*              wa_routdet-von         = roletcode-tcode.
*              wa_routdet-bis         = ''.
*              wa_routdet-description = ''.  "not for performance
*              wa_routdet-child_agr   = roletcode-child_agr.
              INSERT wa_routdet INTO TABLE routdet5.
              CLEAR wa_routdet.

              wa_routdet-agr_name    = roleauth-agr_name.
              wa_routdet-conid       = confdet-conid.
              wa_routdet-functionid  = functtran-functionid.
              wa_routdet-rfcdest     = roleauth-rfcdest.
*              wa_routdet-tcode       = roletcode-tcode.
*              wa_routdet-objct       = itcdaut-objct.
*              wa_routdet-auth        = itcdaut-auth.
*              wa_routdet-field       = itcdaut-field.
*              wa_routdet-von         = itcdaut-von.
*              wa_routdet-bis         = itcdaut-bis.
*              wa_routdet-description = ''.  "not for performance
*              wa_routdet-child_agr   = roleauth-child_agr.
              INSERT wa_routdet INTO TABLE routdet5.
              CLEAR wa_routdet.
              MODIFY tobjs1 FROM wa_tobjs1 TRANSPORTING
                     userhas WHERE
                                  funid = functtran-functionid AND
                                  tcode  = roletcode-tcode AND
                                  object = roleauth-objct.
            ENDLOOP.  "roleauth
          ENDLOOP.   "ITCDAUT
        ENDLOOP.  "CONFDET
        AT END OF tcode.
          LOOP AT tobjs1 WHERE funid = functtran-functionid AND
                               tcode = roletcode-tcode AND
                               userhas <> 'Y'."#EC SAST_CI_GEN_CHECK
            REFRESH routdet5.
          ENDLOOP.
         CHECK sy-subrc <> 0.  "if role has at least 1 auth for all objs
          LOOP AT routdet5.
            INSERT routdet5 INTO TABLE routdet.
          ENDLOOP.
          REFRESH routdet5.
          tobjs1[] = tobjs3[].
        ENDAT.
      ENDLOOP.  "FUNCTTRAN
    ENDLOOP.  "roletcode

    counter = counter + 1.
    COMPUTE percent = counter / trolecount .
    percent = percent * 100.
    MOVE percent TO percenti.
    MOVE percenti TO percentxt.
    prtext = percentxt.

    CONCATENATE text-002 prtext text-003 INTO
                pertext SEPARATED BY space.
  ENDLOOP.    "iagr_define.

  routdet2[] = routdet[].

  LOOP AT routdet.
    AT NEW agr_name.
      confs1[] = confs2[].
    ENDAT.
    LOOP AT confs1 WHERE conid = routdet-conid.
      IF confs1-functionid = routdet-functionid.
        confs1-userhas = 'Y'.
        MODIFY confs1.
      ENDIF.
    ENDLOOP.

    IF sy-subrc = 0. ENDIF.

    AT END OF agr_name.
      LOOP AT confs1 WHERE userhas NE 'Y'. "#EC SAST_CI_GEN_CHECK
        DELETE routdet2 WHERE agr_name = routdet-agr_name AND
                                 conid = confs1-conid.
      ENDLOOP.
      REFRESH confs1.
      confs1[] = confs2[].
    ENDAT.
  ENDLOOP.
  DELETE routdet2 WHERE agr_name = space.
  REFRESH routdet.

  LOOP AT routdet2.
    SELECT SINGLE *           "#EC CI_SEL_NESTED  "#EC CI_NOWHERE
       FROM /psyng/conflict
          WHERE conid = routdet2-conid.
    CHECK sy-subrc = 0.
    wa_routdet-description = /psyng/conflict-description.
    MODIFY routdet2 FROM wa_routdet TRANSPORTING description WHERE
                                    agr_name = routdet2-agr_name AND
                                    conid    = routdet2-conid.
  ENDLOOP.
  APPEND LINES OF routdet2 TO routdet3.
  REFRESH routdet2.

ENDFORM.                    " COMPARE_SODDEF_WITH_AUTH_FOR_R

*---------------------------------------------------------------------*
*       FORM fill_internal_tables                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_internal_tables USING matrix_rfc LIKE rfcdes-rfcdest
                                vrsio      type /psyng/sodvrsio.

  DATA: conflict_fm TYPE STANDARD TABLE OF /psyng/conflict,
        confdet_fm TYPE STANDARD TABLE OF /psyng/confdet,
        functtran_fm TYPE STANDARD TABLE OF /psyng/functtran,
        faobj_fm TYPE STANDARD TABLE OF /psyng/faobj2.

  IF matrix_rfc IS INITIAL.  "get local matrix

    CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
         EXPORTING
              vrsio        = vrsio
         TABLES
              conflict_fm  = conflict_fm
              confdet_fm   = confdet_fm
              functtran_fm = functtran_fm
              faobj_fm     = faobj_fm.

    conflict[] = conflict_fm[].
    confdet[] =  confdet_fm[].
    functtran[] = functtran_fm[].
    faobj[] = faobj_fm[].
    confs2[] = confdet[].

    FREE: conflict_fm, confdet_fm, functtran_fm, faobj_fm.

  ELSE.   "get remote matrix

    SELECT SINGLE rfcdest FROM rfcdes INTO rfcdes
           WHERE rfcdest = matrix_rfc AND rfctype = '3'.
    IF sy-subrc NE 0.
      RAISE invalid_matrix_rfc.
    ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
    CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
      DESTINATION matrix_rfc
      EXPORTING
        vrsio              = vrsio
      TABLES
        conflict_fm        = conflict_fm
        confdet_fm         = confdet_fm
        functtran_fm       = functtran_fm
        faobj_fm           = faobj_fm
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
 IF sy-subrc <> 0.
    CASE sy-subrc.
       WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
       WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
       WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
     ENDCASE.
  ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025

*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


    conflict[] = conflict_fm[].
    confdet[] =  confdet_fm[].
    functtran[] = functtran_fm[].
    faobj[] = faobj_fm[].
    confs2[] = confdet[].

    FREE: conflict_fm, confdet_fm, functtran_fm, faobj_fm.

  ENDIF.
ENDFORM.                    " FILL_INTERNAL_TABLES
