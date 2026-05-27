*----------------------------------------------------------------------*
* FUNCTION              : /PSYNG/SW_010
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
*SW: SOD analysis by role (with simulation) for system-wide
*&---------------------------------------------------------------------*
FUNCTION /PSYNG/SW_010.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(FM_BYSIMU) TYPE  CHAR1 OPTIONAL
*"     VALUE(FM_SHO_CON_ROL_DET) TYPE  CHAR1 DEFAULT 'X'
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      FM_ROLE STRUCTURE  /PSYNG/RANGE_AGR_NAME
*"      FM_SIMULATION_ROLE STRUCTURE  /PSYNG/RANGE_AGR_NAME OPTIONAL
*"      FM_SPCONFS STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      FM_R1STOUTPUT STRUCTURE  /PSYNG/SW_OUT_R1STOUTPUT OPTIONAL
*"      FM_ROUTDET3 STRUCTURE  /PSYNG/SW_OUT_ROUTDET OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_010'.
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

  DATA: subrc LIKE sy-subrc.  "return code

  bysimu = fm_bysimu.
  role[] = fm_role[].
  simurols[] = fm_simulation_role[].
  spconfs[] = fm_spconfs[].

  DATA: objectcount_fm TYPE i,
        concount_fm    TYPE i,
        byobject  TYPE  char10.

  REFRESH: usertcode_fm, userprof, userauth_fm, susertcode,
           functtran, faobj, confdet, confs2, SIMUAGRS[],SIMUAGRS.

  PERFORM fill_internal_tables using vrsio.
  IF bysimu = 'X'.
    PERFORM get_simulation_roles_for_role.
  ENDIF.

  REFRESH iagr_define.
  SELECT agr_name create_dat change_dat
             INTO CORRESPONDING FIELDS OF wa_iagr_define
             FROM agr_define
             WHERE agr_name IN role.
    INSERT wa_iagr_define INTO TABLE iagr_define.
  ENDSELECT.

*remove single roles if performing simulation
*  IF bysimu = 'X'.
*    LOOP AT iagr_define.
*      SELECT SINGLE * FROM agr_agrs WHERE
*                     agr_name = iagr_define-agr_name.
*      CHECK sy-subrc = 0.
*      DELETE TABLE iagr_define.
*    ENDLOOP.
*  ENDIF.

  DESCRIBE TABLE iagr_define LINES objectcount_fm.
  SELECT COUNT( * ) FROM /psyng/conflict
         INTO concount_fm
         WHERE conid IN spconfs
         and vrsio   =  vrsio.
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
                           AND ATTRIBUTES <> 'X'.
      CLEAR: roleauth_fm, roletcode_fm, roleprof_fm.
      REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.
      CALL FUNCTION '/PSYNG/SW_GET_ROLE_SUM_DATA'
           EXPORTING
                agr_name  = agr_agrs-child_agr
                bname     = ''
           TABLES
                roleauth  = roleauth_fm
                roletcode = roletcode_fm
                roleprof  = roleprof_fm
                functtran = functtran
                faobj     = faobj.
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
      CLEAR: wa_roletcode, wa_roleauth.
      LOOP AT roletcode_fm.
        wa_roletcode-agr_name = iagr_define-agr_name.
        wa_roletcode-tcode    = roletcode_fm-tcode.
        wa_roletcode-child_agr = roletcode_fm-agr_name.
        wa_roletcode-rfcdest   = roletcode_fm-rfcdest.
        INSERT wa_roletcode INTO TABLE roletcode.
      ENDLOOP.
      LOOP AT roleauth_fm.
        MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
        wa_roleauth-agr_name  = iagr_define-agr_name.
        wa_roleauth-child_agr = roleauth_fm-agr_name.
        INSERT wa_roleauth INTO TABLE roleauth.
      ENDLOOP.
    ENDSELECT.   "agr_agrs
    subrc = sy-subrc.

    IF bysimu = 'X'.
      PERFORM get_simulation_roles_data.
    ENDIF.

    CHECK subrc <> 0.  "next role if role is composite

    CLEAR: roleauth_fm, roletcode_fm, roleprof_fm.
    REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.
    CALL FUNCTION '/PSYNG/SW_GET_ROLE_SUM_DATA'
         EXPORTING
              agr_name  = iagr_define-agr_name
              bname     = ''
         TABLES
              roleauth  = roleauth_fm
              roletcode = roletcode_fm
              roleprof  = roleprof_fm
              functtran = functtran
              faobj     = faobj.
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

    CLEAR: wa_roletcode, wa_roleauth.
    LOOP AT roletcode_fm.
      MOVE-CORRESPONDING roletcode_fm TO wa_roletcode.
      INSERT wa_roletcode INTO TABLE roletcode.
    ENDLOOP.
    LOOP AT roleauth_fm.
      MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
      INSERT wa_roleauth INTO TABLE roleauth.
    ENDLOOP.

    counter = counter + 1.
    COMPUTE percent = counter / trolecount .
    percent = percent * 100.
    MOVE percent TO percenti.
    MOVE percenti TO percentxt.
    prtext = percentxt.

*    CONCATENATE 'Step 1 of 4:' prtext
*                'percent complete.'
*                                    INTO
*                pertext SEPARATED BY space.
*    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*         EXPORTING
*              percentage = percent
*              text       = pertext.

  ENDLOOP.    "IAGR_DEFINE
  CLEAR: roleauth_fm, roletcode_fm, roleprof_fm.
  REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.

*  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*       EXPORTING
*            percentage = '75'
*            text       = 'Step 2 of 4'.

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
  CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_DATA'
       TABLES
            tcd         = itcd2
            faobj       = faobj
            functtran   = functtran
            tcdaut      = itcdaut
            uniqueauths = uniqueauths.

  SORT: faobj.

  IF bysimu = 'X'.
*  concatenate sy-sysid sy-mandt into rfcdest.
*    loop at itcdaut.
*      itcdaut-rfcdest = rfcdest.
*      modify itcdaut.
*    endloop.
*    LOOP AT roleauth.
*      roleauth-auth = rfcdest.  "table does not have rfcdest
*      modify roleauth.
*    ENDLOOP.
  ENDIF.

  PERFORM compare_soddef_with_auth_role using vrsio.

  APPEND LINES OF routdet2 TO fm_routdet3.
  REFRESH routdet2.

  SORT fm_routdet3.
  LOOP AT fm_routdet3.
    fm_r1stoutput-agr_name = fm_routdet3-agr_name.
    fm_r1stoutput-conid = fm_routdet3-conid.
    fm_r1stoutput-description = fm_routdet3-description.
    APPEND fm_r1stoutput.
    CHECK fm_sho_con_rol_det = 'X'.
    CLEAR: fm_routdet3-rfcdest, fm_routdet3-tcode, fm_routdet3-objct,
           fm_routdet3-auth, fm_routdet3-field, fm_routdet3-von,
           fm_routdet3-bis.
    MODIFY fm_routdet3.
  ENDLOOP.

  IF fm_sho_con_rol_det = 'X'.
    SORT fm_routdet3.
    DELETE ADJACENT DUPLICATES FROM fm_routdet3 COMPARING ALL FIELDS.
  ENDIF.

  SORT fm_r1stoutput.
  DELETE ADJACENT DUPLICATES FROM fm_r1stoutput COMPARING ALL FIELDS.
  MESSAGE s208(00) WITH 'Analysis Complete'.

ENDFUNCTION.


*---------------------------------------------------------------------*
*       FORM fill_internal_tables                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_internal_tables using vrsio type /psyng/sodvrsio.

  DATA: conflict_fm TYPE STANDARD TABLE OF /psyng/conflict,
        confdet_fm TYPE STANDARD TABLE OF /psyng/confdet,
        functtran_fm TYPE STANDARD TABLE OF /psyng/functtran,
        faobj_fm TYPE STANDARD TABLE OF /psyng/faobj2.

  CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
       EXPORTING
            vrsio        = vrsio
       TABLES
            conflict_fm  = conflict_fm
            confdet_fm   = confdet_fm
            functtran_fm = functtran_fm
            faobj_fm     = faobj_fm
            spconfs_fm   = spconfs.

  conflict[] = conflict_fm[].
  confdet[] =  confdet_fm[].
  functtran[] = functtran_fm[].
  faobj[] = faobj_fm[].
  confs2[] = confdet[].

  FREE: conflict_fm, confdet_fm, functtran_fm, faobj_fm.

ENDFORM.                    " FILL_INTERNAL_TABLES

*---------------------------------------------------------------------*
*       FORM get_simulation_roles_for_role                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_simulation_roles_for_role.
  SELECT agr_name INTO wa_iagr_define-agr_name FROM agr_define WHERE
                                              agr_name IN simurols.
    agrs-agr_name = wa_iagr_define-agr_name.
    INSERT wa_iagr_define INTO TABLE simuagrs.
  ENDSELECT.
ENDFORM.                    " get_simulation_roles_for_role


*---------------------------------------------------------------------*
*       FORM get_simulation_roles_data                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_simulation_roles_data.
  LOOP AT simuagrs.
    REFRESH: roletcode_fm, roleprof_fm, roleauth_fm.
    CLEAR: roletcode_fm, roleprof_fm, roleauth_fm.
    CALL FUNCTION '/PSYNG/SW_GET_ROLE_SUM_DATA'
         EXPORTING
              agr_name  = simuagrs-agr_name
              bname     = ''
         TABLES
              roleauth  = roleauth_fm
              roletcode = roletcode_fm
              roleprof  = roleprof_fm
              functtran = functtran
              faobj     = faobj.

    CLEAR: wa_roletcode, wa_roleauth.
    LOOP AT roletcode_fm.
      wa_roletcode-agr_name = iagr_define-agr_name.
      wa_roletcode-tcode    = roletcode_fm-tcode.
      wa_roletcode-child_agr = roletcode_fm-agr_name.
      wa_roletcode-rfcdest = roletcode_fm-rfcdest.
      INSERT wa_roletcode INTO TABLE roletcode.
    ENDLOOP.
    LOOP AT roleauth_fm.
      MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
      wa_roleauth-agr_name  = iagr_define-agr_name.
      wa_roleauth-child_agr = roleauth_fm-agr_name.
      wa_roleauth-rfcdest = roleauth_fm-rfcdest.
      INSERT wa_roleauth INTO TABLE roleauth.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " get_simulation_roles_data


*---------------------------------------------------------------------*
*       FORM compare_soddef_with_auth_role                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM compare_soddef_with_auth_role using vrsio type /psyng/sodvrsio.

  DATA: roletcode_idx   TYPE i,
        roleauth_idx    TYPE i.

  roletcode_idx = 1.  roleauth_idx = 1.

  functtran2[] = functtran[].
  itcdaut2[]   = itcdaut[].

  wa_tobjs1-userhas = 'Y'.
  LOOP AT iagr_define.
    PERFORM refresh_internal_tables.

    READ TABLE roletcode WITH KEY agr_name = iagr_define-agr_name
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
    roletcode_idx = sy-tabix.
    LOOP AT roletcode FROM roletcode_idx WHERE
                                  agr_name = iagr_define-agr_name.
      roletcode_idx = sy-tabix.
      LOOP AT functtran WHERE tcode = roletcode-tcode.
        LOOP AT confdet WHERE functionid = functtran-functionid. "#EC CI_SORTSEQ
          READ TABLE faobj WITH KEY funid = functtran-functionid
                                    tcode = roletcode-tcode
                                    BINARY SEARCH
                                    TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            wa_routdet-agr_name    = roletcode-agr_name.
            wa_routdet-conid       = confdet-conid.
            wa_routdet-functionid  = functtran-functionid.
            wa_routdet-tcode       = roletcode-tcode.
            wa_routdet-objct       = 'S_TCODE'.
*            wa_routdet-auth        = roletcode-auth.
            wa_routdet-field       = 'TCD'.
            wa_routdet-von         = roletcode-tcode.
            wa_routdet-bis         = ''.
            wa_routdet-description = ''. "not for performance
            wa_routdet-child_agr   = roletcode-child_agr.
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
              wa_routdet-tcode       = roletcode-tcode.
              wa_routdet-objct       = 'S_TCODE'.
              wa_routdet-field       = 'TCD'.
              wa_routdet-von         = roletcode-tcode.
              wa_routdet-bis         = ''.
              wa_routdet-description = ''.  "not for performance
              wa_routdet-child_agr   = roletcode-child_agr.
              INSERT wa_routdet INTO TABLE routdet5.
              CLEAR wa_routdet.

              wa_routdet-agr_name    = roleauth-agr_name.
              wa_routdet-conid       = confdet-conid.
              wa_routdet-functionid  = functtran-functionid.
              wa_routdet-rfcdest     = roleauth-rfcdest.
              wa_routdet-tcode       = roletcode-tcode.
              wa_routdet-objct       = itcdaut-objct.
              wa_routdet-auth        = itcdaut-auth.
              wa_routdet-field       = itcdaut-field.
              wa_routdet-von         = itcdaut-von.
              wa_routdet-bis         = itcdaut-bis.
              wa_routdet-description = ''.  "not for performance
              wa_routdet-child_agr   = roleauth-child_agr.
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
                               userhas <> 'Y'. "#EC SAST_CI_GEN_CHECK
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
*    COMPUTE percent = counter / trolecount .
*    percent = percent * 100.
*    MOVE percent TO percenti.
*    MOVE percenti TO percentxt.
*    prtext = percentxt.
*
*    CONCATENATE 'Step 3 of 4:' prtext
*                'percent complete.' INTO
*                pertext SEPARATED BY space.
*    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*         EXPORTING
*              percentage = percent
*              text       = pertext.

  ENDLOOP.    "iagr_define.

*  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*       EXPORTING
*            percentage = 100
*            text       = 'Step 4 of 4 -Formatting data for output.'.

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
    SELECT SINGLE *                   "#EC CI_SEL_NESTED "#EC CI_NOWHERE
    FROM /psyng/conflict
      WHERE conid = routdet2-conid
        and vrsio = vrsio.
    CHECK sy-subrc = 0.
    wa_routdet-description = /psyng/conflict-description.
    MODIFY routdet2 FROM wa_routdet TRANSPORTING description WHERE
                                    agr_name = routdet2-agr_name AND
                                    conid    = routdet2-conid.
  ENDLOOP.

ENDFORM.                    " COMPARE_SODDEF_WITH_AUTH_FOR_R

*---------------------------------------------------------------------*
*       FORM refresh_internal_tables                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM refresh_internal_tables.
  REFRESH: 	itcd,
              auths_fm,
              values_fm,
*              sodobject1,
              profinfo,
              profinfo2,
              userprof.
*              routdet,
*              routdet2,
*              sodtab1,
*              sodtab2.
ENDFORM.                    " REFRESH_INTERNAL_TABLES
