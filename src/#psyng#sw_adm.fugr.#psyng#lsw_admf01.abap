*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/LSW_ADMF01                                          *
*----------------------------------------------------------------------*


*---------------------------------------------------------------------*
*       FORM get_header_overview                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_HEADER                                                      *
*---------------------------------------------------------------------*
FORM get_header_overview
              CHANGING
               e_header TYPE /psyng/swadmovw.

  CALL FUNCTION '/PSYNG/SW_ADM_COCKPIT_OVERVIEW'
    IMPORTING
      e_header = e_header.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_detail_overview                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_DETAIL                                                     *
*---------------------------------------------------------------------*
FORM get_detail_overview
TABLES
  it_system  STRUCTURE /psyng/range_sysid
  et_detail  STRUCTURE /psyng/swadmovw
  et_return  STRUCTURE bapiret2.

 DATA: lt_swrfcdes      TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
       lt_output_tmp    TYPE TABLE OF /psyng/swadmovw WITH HEADER LINE,
       l_system_msg(72) TYPE c,
       ls_overview      TYPE /psyng/swadmovw,
       l_subrc          LIKE sy-subrc.

**---get rfc from SE system db table
  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
  WHERE systid IN it_system.

  LOOP AT lt_swrfcdes.
    lt_output_tmp-systid           =  lt_swrfcdes-systid.

    IF lt_swrfcdes-rfcdest IS INITIAL.
*-- get overview info from remote system
      CALL FUNCTION '/PSYNG/SW_ADM_COCKPIT_OVERVIEW'
        IMPORTING
          e_header = ls_overview.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING ls_overview TO lt_output_tmp.
        lt_output_tmp-rfc_valid        = 'X'.
        lt_output_tmp-last_check       = sy-datum.
      ENDIF.
    ELSE.
*-- get overview info from remote system
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
      CALL FUNCTION '/PSYNG/SW_ADM_COCKPIT_OVERVIEW'
        DESTINATION lt_swrfcdes-rfcdest
        IMPORTING
          e_header              = ls_overview
        EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3.             "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      IF sy-subrc = 0.
        MOVE-CORRESPONDING ls_overview TO lt_output_tmp.
        lt_output_tmp-rfc_valid = 'X'.
      ELSE.
        CASE sy-subrc.
          WHEN 1.
            log et_return 'E'
            '/PSYNG/SW_ADM_COCKPIT_OVERVIEW'
            'communication_failure'
            lt_swrfcdes-rfcdest
            l_system_msg
             ''.
            CLEAR lt_output_tmp-rfc_valid.
          WHEN 2.
            CLEAR lt_output_tmp-rfc_valid.
            log et_return 'E'
            '/PSYNG/SW_ADM_COCKPIT_OVERVIEW'
            'system_failure'
            lt_swrfcdes-rfcdest
            l_system_msg
             ''.
          WHEN 3.
            log et_return 'E'
            '/PSYNG/SW_ADM_COCKPIT_OVERVIEW'
            'unknown_failure'
            lt_swrfcdes-rfcdest '' ''.
        ENDCASE.
        APPEND et_return.
      ENDIF.
      lt_output_tmp-last_check         = sy-datum.
    ENDIF.
    APPEND lt_output_tmp.
    CLEAR: lt_output_tmp, ls_overview.
    APPEND LINES OF lt_output_tmp TO et_detail.
    FREE lt_output_tmp.
  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_proposed_mitigations                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_CONFLICTS                                                  *
*  -->  ET_CONPMIT                                                    *
*  -->  ET_MCHDR                                                      *
*  -->  ET_TEXTS                                                      *
*  -->  IF_TEXTS                                                      *
*---------------------------------------------------------------------*
FORM get_proposed_mitigations
  TABLES it_conflicts STRUCTURE /psyng/conflict
         et_conpmit   STRUCTURE /psyng/conpmit
         et_mchdr     STRUCTURE /psyng/mchdr
         et_texts     STRUCTURE /psyng/texts
  USING
    if_texts TYPE flag
    i_vrsio  TYPE /psyng/sodvrsio.
  RANGES : lr_mc FOR et_mchdr-contid,
            lr_conid FOR it_conflicts-conid.

  IF NOT it_conflicts[] IS INITIAL.
*--Get Proposed Mitigations
    SELECT * FROM /psyng/conpmit INTO TABLE et_conpmit
    FOR ALL ENTRIES IN it_conflicts WHERE vrsio = it_conflicts-vrsio AND
                                          conid = it_conflicts-conid.
*--Collect proposed mitigations
    lr_mc-sign   = 'I'.
    lr_mc-option = 'EQ'.
    LOOP AT it_conflicts.
      IF NOT it_conflicts-contid IS INITIAL.
        lr_mc-low = it_conflicts-contid.
        COLLECT lr_mc.
      ENDIF.
    ENDLOOP.
    LOOP AT et_conpmit.
      lr_mc-low =  et_conpmit-contid.
      COLLECT lr_mc.
    ENDLOOP.
*--Load Mitigation Headers
    IF NOT lr_mc[] IS INITIAL.
      SELECT * FROM /psyng/mchdr INTO TABLE et_mchdr
      WHERE contid IN lr_mc.
    ENDIF.
  ENDIF.
  IF if_texts  ='X'.
*--Load the long texts
    IF NOT lr_mc[] IS INITIAL.
*--Mitigation Texts
      SELECT * FROM /psyng/texts INTO TABLE et_texts
      WHERE object = 'M' AND textname IN lr_mc.
    ENDIF.
*--Conflict Texts
    lr_conid-sign   = 'I'.
    lr_conid-option = 'EQ'.
    LOOP AT it_conflicts.
      lr_conid-low = it_conflicts-conid.
      COLLECT lr_conid.
    ENDLOOP.
    SELECT * FROM /psyng/texts APPENDING TABLE et_texts
    WHERE object = 'C' AND
    textname IN lr_conid AND
    vrsio = i_vrsio.

  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM general_info                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_SERVER                                                      *
*---------------------------------------------------------------------*
FORM general_info USING e_server LIKE msxxlist-name.
  CALL FUNCTION 'FIND_DB_APPLICATION_SERVER'
    IMPORTING
      servername            = e_server
    EXCEPTIONS
      no_application_server = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM cpu_cal                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_VRSIO                                                       *
*  -->  E_CPU                                                         *
*---------------------------------------------------------------------*
FORM cpu_cal USING i_vrsio TYPE /psyng/swsodvers-vrsio
      CHANGING e_cpu TYPE /psyng/sw_cpu_calcu_info.
  DATA: BEGIN OF gt_usr_pro OCCURS 0,
          bname   TYPE ust04-bname,
          profile TYPE ust04-profile,
        END OF gt_usr_pro.

  DATA: l_ob_au_prof TYPE i.

  DATA: l_time1 TYPE i,
        l_time2 TYPE i,
        l_time3 TYPE i,
        l_time4 TYPE i,
        l_var2  TYPE i,
        l_time0 TYPE i,
        l_time5 TYPE i.
  DATA: l_cnt1 TYPE i,
        l_cnt2 TYPE i.

  DATA: BEGIN OF lt_fun_tcd_obj OCCURS 0,
          funid  TYPE /psyng/faobj2-funid,
          tcode  TYPE /psyng/faobj2-tcode,
          object TYPE /psyng/faobj2-object,
        END OF lt_fun_tcd_obj.
  DATA: l_text1 TYPE string,
        l_text2 TYPE string.


  GET RUN TIME FIELD l_time1.

  SELECT DISTINCT funid tcode object
  FROM /psyng/faobj2
  INTO TABLE lt_fun_tcd_obj
  WHERE vrsio =  i_vrsio.
  l_cnt1 = sy-dbcnt.

  GET RUN TIME FIELD l_time2.

  SELECT COUNT( DISTINCT p~profn ) INTO l_ob_au_prof
  FROM /psyng/faobj2 AS o  INNER JOIN ust10s AS p  ON
  o~object =  p~objct
  WHERE o~vrsio = i_vrsio.

  GET RUN TIME FIELD l_time3.

  SELECT COUNT( * )
  FROM /psyng/faobj2
  INTO l_var2
  WHERE vrsio =  i_vrsio.

  GET RUN TIME FIELD l_time4.

  SELECT bname profile
  FROM ust04
  INTO TABLE gt_usr_pro.
  l_cnt2 = sy-dbcnt.

  GET RUN TIME FIELD l_time5.

  l_time0 = l_time5 - l_time1.
  PERFORM time_conversion CHANGING l_time0 l_text1.
*  WRITE:/3 text-074,20 l_text1 COLOR 6.
  e_cpu-total_run_text =  text-074.
  e_cpu-total_run_time = l_text1.
  l_text1 = l_cnt1.

  CONCATENATE text-076 l_text1 text-077 INTO l_text1.
  PERFORM time_conversion CHANGING l_time2 l_text2.
  e_cpu-faobj2_exetext = l_text1.
  e_cpu-faobj2_exetime = l_text2.

  l_time0 = l_time3 - l_time2.
  l_text1 = l_ob_au_prof.
  CONCATENATE text-078 l_text1 INTO l_text1 SEPARATED BY space.
  CONCATENATE l_text1 text-077 INTO l_text1.
  PERFORM time_conversion CHANGING l_time0 l_text2.
  e_cpu-aggre_selecttext = l_text1.
  e_cpu-aggre_selecttime = l_text2.

  l_time0 = l_time4 - l_time3.
  l_text1 = l_var2.
  CONCATENATE  text-080 l_text1 text-077 INTO l_text1 .
  PERFORM time_conversion CHANGING l_time0 l_text2.
  e_cpu-faobj2_resulttext = l_text1.
  e_cpu-faobj2_resultcnt  = l_text2.

  l_time0 = l_time5 - l_time4.
*  SKIP.
  l_text1 = l_cnt2.
  CONCATENATE  text-081 l_text1 text-077 INTO l_text1.
  PERFORM time_conversion CHANGING l_time0 l_text2.
*  WRITE:/10 l_text1 ,94 l_text2 COLOR 7.

  e_cpu-ust04_seltext = l_text1.
  e_cpu-ust04_seltime = l_text2.

  DATA: i_text TYPE string,
        i_time TYPE string.
  PERFORM cpu_calcu CHANGING i_text
                             i_time.
  e_cpu-cpu_tot_runtimetext = i_text.
  e_cpu-cpu_tot_runtime     = i_time.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM cpu_calcu                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_TEXT                                                        *
*  -->  E_TIME                                                        *
*---------------------------------------------------------------------*
FORM cpu_calcu CHANGING e_text TYPE string
                        e_time TYPE string.
  DATA: l_text1 TYPE string.
  DATA: l_digit1   TYPE i VALUE 2,
        l_digit2   TYPE i VALUE 3,
        l_digit3   TYPE i,
        l_time     TYPE i,
        l_time1    TYPE i,
        l_char1(4),
        l_char2(4),
        l_random   TYPE i.

  DATA: BEGIN OF itab OCCURS 0,
          char(50),
          number1  TYPE i,
          number2  TYPE i,
        END OF itab.

  DATA     : l_loop1   TYPE i VALUE 500,
             l_loop2   TYPE i VALUE 50,
             l_loop3   TYPE i VALUE 500,
             l_add1num TYPE i VALUE 345,
             l_add2num TYPE i VALUE  8679.


  GET RUN TIME FIELD l_time.

  DO l_loop1 TIMES.                   "#EC PATHLOCK_CI_NO_DOS (HBHALLA)

    l_digit3 = l_digit1 * l_digit2.
    ADD 1 TO l_digit1.
    ADD 2 TO l_digit2.

    REFRESH itab.
    DO l_loop2 TIMES.                 "#EC PATHLOCK_CI_NO_DOS (HBHALLA)

      PERFORM get_random_number CHANGING l_random.
      itab-number1 = l_random + ( l_digit1 * 4 ) .
      itab-number2 = l_random * 3.
      MOVE itab-number1 TO l_char1.
      MOVE itab-number2 TO l_char2.
      CONCATENATE l_char1 l_char2 INTO itab-char.
      APPEND itab.

    ENDDO.

    DO l_loop3 TIMES.                 "#EC PATHLOCK_CI_NO_DOS (HBHALLA)
      SORT itab BY char.
      SORT itab BY number2.
      SORT itab BY number1.
    ENDDO.

  ENDDO.

  GET RUN TIME FIELD l_time1.
  l_time = l_time1 - l_time.
  PERFORM time_conversion CHANGING l_time l_text1.
  e_text = text-074.
  e_time = l_text1.
ENDFORM.                    " cpu_calcu

*---------------------------------------------------------------------*
*       FORM get_random_number                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_RANDAM                                                      *
*---------------------------------------------------------------------*
FORM get_random_number CHANGING p_randam TYPE i.
  CALL FUNCTION 'QF05_RANDOM_INTEGER'
    EXPORTING
      ran_int_max   = 100
      ran_int_min   = 1
    IMPORTING
      ran_int       = p_randam
    EXCEPTIONS
      invalid_input = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM matrix_cal                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_SODVRSIO                                                    *
*---------------------------------------------------------------------*
FORM matrix_cal USING i_sodvrsio
                    TYPE /psyng/swsodvers-vrsio
                    CHANGING
                    e_mat_cal TYPE /psyng/sw_cal_sodmatrix.

  DATA: BEGIN OF lt_fun_tcd_obj OCCURS 0,
          funid  TYPE /psyng/faobj2-funid,
          tcode  TYPE /psyng/faobj2-tcode,
          object TYPE /psyng/faobj2-object,
        END OF lt_fun_tcd_obj.

  DATA: BEGIN OF lt_object OCCURS 0,
          object TYPE /psyng/faobj2-object,
        END OF lt_object.
  DATA: BEGIN OF lt_auth OCCURS 0,
          auth TYPE usr12-auth,
        END OF lt_auth.
  DATA: BEGIN OF lt_prof OCCURS 0,
          profn TYPE ust10s-profn,
          auth  TYPE ust10s-auth,
        END OF lt_prof.


  DATA: l_conf_cnt    TYPE i,
        l_act_con     TYPE i,
        l_var1        TYPE i,
        l_var2        TYPE i,
        l_fun_con     TYPE p DECIMALS 2,
        l_fun_cnt     TYPE i,
        l_tcd_fun     TYPE p DECIMALS 2,
        l_tcd_no      TYPE i,
        l_tcd_fun_c   TYPE i,
        l_obj_tcd     TYPE p DECIMALS 2,
        l_rcd_obj     TYPE p DECIMALS 2,
        l_auth_obj    TYPE i,
        l_fun_tcd_ob  TYPE i,
        l_au_objct    TYPE i,
        l_ob_au_prof  TYPE i,
        l_rol_aut_obj TYPE i.

  DATA: ls_sodvers TYPE /psyng/swsodvers.

  SELECT SINGLE *
    FROM /psyng/swsodvers
    INTO ls_sodvers
   WHERE vrsio EQ i_sodvrsio.

  SELECT COUNT( DISTINCT conid )
  FROM /psyng/conflict
  INTO l_conf_cnt
  WHERE conid <> ' ' AND
  vrsio =  i_sodvrsio.

  SELECT COUNT( DISTINCT conid )
  FROM /psyng/conflict
  INTO l_act_con
  WHERE conid <> ' ' AND
  vrsio =  i_sodvrsio
  AND inactive = ' '.
******** FUNC PER CONFLICT    **********
  SELECT COUNT( DISTINCT functionid )
  FROM /psyng/confdet
  INTO l_var1
  WHERE vrsio =  i_sodvrsio.

  SELECT COUNT( DISTINCT conid )
  FROM /psyng/confdet
  INTO l_var2
  WHERE vrsio =  i_sodvrsio.

  l_fun_con = (  l_var1 / l_var2 ).
*********** funid cnt ****************
  SELECT COUNT( DISTINCT function )
  FROM /psyng/function
  INTO l_fun_cnt
  WHERE vrsio =  i_sodvrsio.
********* tcode per fun **************

  SELECT COUNT( DISTINCT tcode )
  FROM /psyng/functtran
  INTO l_var1
  WHERE vrsio =  i_sodvrsio.

  SELECT COUNT( DISTINCT functionid )
  FROM /psyng/functtran
  INTO l_var2
  WHERE vrsio =  i_sodvrsio.

  l_tcd_fun = (  l_var1 / l_var2 ).
  l_tcd_no = l_var1.
***      TCD AND FUN COM ***********
  SELECT COUNT( * )
  FROM /psyng/functtran
  INTO l_tcd_fun_c
  WHERE vrsio =  i_sodvrsio.
**        OBJT / TCD   ********
  SELECT  COUNT( DISTINCT object )
  FROM /psyng/faobj2
  INTO l_var1
  WHERE vrsio =  i_sodvrsio.

  SELECT COUNT( DISTINCT tcode )
  FROM /psyng/faobj2
  INTO l_var2
  WHERE vrsio =  i_sodvrsio.

  l_obj_tcd = (  l_var1 / l_var2 ).

  CLEAR: l_var2.
  SELECT COUNT( * )
  FROM /psyng/faobj2
  INTO l_var2
  WHERE vrsio =  i_sodvrsio.
  l_rcd_obj = (  l_var2 / l_var1 ).
*** total auth obj          ***
  l_auth_obj = l_var1.
**  unique comb od fun-tcd-obj   ****
  SELECT DISTINCT funid tcode object
  FROM /psyng/faobj2
  INTO TABLE lt_fun_tcd_obj
  WHERE vrsio =  i_sodvrsio.
  l_fun_tcd_ob = sy-dbcnt.


  SELECT COUNT( DISTINCT u~auth ) INTO l_au_objct
  FROM /psyng/faobj2 AS o  INNER JOIN ust12 AS u  ON
  o~object = u~objct
  WHERE
  o~vrsio = i_sodvrsio.

  SELECT COUNT( DISTINCT p~profn ) INTO l_ob_au_prof
  FROM /psyng/faobj2 AS o  INNER JOIN ust10s AS p  ON
  o~object =  p~objct
  WHERE o~vrsio = i_sodvrsio.

  SELECT COUNT( DISTINCT a~agr_name ) INTO l_rol_aut_obj
  FROM   /psyng/faobj2 AS o INNER JOIN agr_1250 AS a ON
  o~object  = a~object
  WHERE o~vrsio = i_sodvrsio
  AND
  a~deleted <> 'X'.
*---------
  DATA l_count TYPE string.
  CONCATENATE text-038 ':' i_sodvrsio INTO e_mat_cal-sodversion.
  CONCATENATE e_mat_cal-sodversion ls_sodvers-vdesc
  INTO e_mat_cal-sodversion SEPARATED BY space.
  l_count = l_conf_cnt.
  CONCATENATE text-039 ':' l_count INTO e_mat_cal-totalconflicts.
  CLEAR l_count.
  l_count = l_act_con.
  CONCATENATE text-040 ':' l_count INTO e_mat_cal-activeconflicts.
  CLEAR l_count.
  l_count = l_fun_con.
  CONCATENATE text-041 ':' l_count INTO e_mat_cal-avgfunconflict.
  CLEAR l_count.
  l_count =  l_fun_cnt.
  CONCATENATE text-042 ':' l_count INTO e_mat_cal-functions.
  CLEAR l_count.
  l_count =  l_tcd_fun.
  CONCATENATE text-043 ':' l_count INTO e_mat_cal-avgtxnfunction.
  CLEAR l_count.
  l_count =  l_tcd_no.
  CONCATENATE text-044 ':' l_count INTO e_mat_cal-unique_txn.
  CLEAR l_count.
  l_count =  l_tcd_fun_c.
  CONCATENATE text-045 ':' l_count INTO e_mat_cal-funtxn_combi.
  CLEAR l_count.
  l_count =  l_obj_tcd.
  CONCATENATE text-046 ':' l_count INTO e_mat_cal-avgobjtxnfaobj2.
  CLEAR l_count.
  l_count =  l_rcd_obj.
  CONCATENATE text-047 ':' l_count INTO e_mat_cal-avgobjfaobj2.
  CLEAR l_count.
  l_count =  l_auth_obj.

  CONCATENATE text-048 ':' l_count INTO e_mat_cal-unique_auth.
  CLEAR l_count.
  l_count =  l_fun_tcd_ob.

  CONCATENATE text-049 ':' l_count INTO e_mat_cal-funtxnobj_combi.
  CLEAR l_count.
  l_count =  l_au_objct.
  CONCATENATE text-062 ':' l_count INTO e_mat_cal-sysauth_matrix.
  CLEAR l_count.
  l_count =  l_ob_au_prof.
  CONCATENATE text-063 ':' l_count INTO e_mat_cal-s_profiles.
  CLEAR l_count.
  l_count =  l_rol_aut_obj.
  CONCATENATE text-064 ':' l_count INTO e_mat_cal-roles.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM security_environment                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM security_environment
CHANGING e_sec_info TYPE /psyng/sw_security_info.

  DATA: l_usr_cnt      TYPE i,
        l_vlid_usr_cnt TYPE i,
        l_role_cnt     TYPE i,
        l_usr_role     TYPE i,
        l_usr_no_role  TYPE i,
        l_role_usr     TYPE i,
        l_role_no_usr  TYPE i,
        l_prof_cnt     TYPE i,
        l_pro_usr      TYPE i,
        l_pro_no_usr   TYPE i,
        l_usr_pro      TYPE i,
        l_usr_no_pro   TYPE i,
        l_auth         TYPE i,
        l_auth_no_usr  TYPE i,
        l_auth_usr     TYPE i,
        l_comp_rol     TYPE i,
        l_comp_rol1    TYPE i,
        l_corol_usr    TYPE i,
        l_corol_no_usr TYPE i,
        l_sinrol       TYPE i,
        l_sinrol_usr   TYPE i,
        l_sinrol_n_usr TYPE i,
        l_prnt_role    TYPE i,
        l_prnt_usr     TYPE i,
        l_prnt_n_usr   TYPE i,
        l_drv_rol      TYPE i,
        l_drvrol_usr   TYPE i,
        l_drvrol_n_usr TYPE i,
        l_avg_drv      TYPE p DECIMALS 2,
        l_comp         TYPE i,
        l_sing_rol     TYPE i,
        l_sing_rol1    TYPE i,
        l_avg_srol     TYPE p DECIMALS 2,
        l_tot_rol      TYPE i,
        l_tot_usr      TYPE i,
        l_avg_rol_usr  TYPE p DECIMALS 2,
        l_avg_pro_usr  TYPE p DECIMALS 2,
        l_avg_pro_rol  TYPE p DECIMALS 2,
        l_avg_tcd_rol  TYPE p DECIMALS 2,
        l_avg_auth_rol TYPE p DECIMALS 2,
        l_au_usr       TYPE i,
        l_avg_auth_usr TYPE p DECIMALS 2.
  DATA: BEGIN OF lt_usr_tab OCCURS 0,
          bname TYPE usr02-bname,
        END OF lt_usr_tab.
  DATA: BEGIN OF l_profile OCCURS 0,
          profn TYPE usr10-profn,
        END OF l_profile.
  DATA: BEGIN OF lt_usr_pro OCCURS 0,
          bname   TYPE ust04-bname,
          profile TYPE ust04-profile,
        END OF lt_usr_pro.
  DATA: BEGIN OF lt_auth OCCURS 0,
          auth TYPE usr12-auth,
        END OF lt_auth.
  DATA: BEGIN OF lt_auth_usr OCCURS 0,
          profile TYPE ust04-profile,
        END OF lt_auth_usr.
  DATA: lt_auth_usr_dum LIKE STANDARD TABLE OF  lt_auth_usr WITH HEADER
        LINE.

  SELECT bname
    FROM usr02
    INTO TABLE lt_usr_tab.
  l_usr_cnt = sy-dbcnt.

  SELECT COUNT( DISTINCT bname )
  INTO l_vlid_usr_cnt
  FROM usr02
  WHERE ustyp = 'A'
  AND uflag < 32.

*nr of role
  SELECT COUNT( DISTINCT agr_name )
   FROM agr_define
   INTO l_role_cnt
   WHERE agr_name NOT LIKE 'SAP#_%' ESCAPE '#'.

*nr of users with roles
  SELECT COUNT( DISTINCT u~bname ) INTO l_usr_role
  FROM usr02 AS u INNER JOIN  agr_users AS a
  ON u~bname = a~uname.
  l_usr_no_role = l_usr_cnt - l_usr_role.


*nr of role with usr
  SELECT COUNT( DISTINCT u~agr_name )
  INTO l_role_usr
  FROM agr_define AS u INNER JOIN  agr_users AS a
  ON u~agr_name = a~agr_name
  WHERE u~agr_name NOT LIKE 'SAP#_%' ESCAPE '#'.
*nr of role without usr
  l_role_no_usr = l_role_cnt - l_role_usr.


******************* profile ********************************
  SELECT profn
  FROM usr10
  INTO TABLE l_profile
  WHERE aktps = 'A'.
  l_prof_cnt = sy-dbcnt.
*
  SELECT bname profile
  FROM ust04
  INTO TABLE lt_usr_pro.
  SORT lt_usr_pro BY bname.
  LOOP AT lt_usr_tab.
    READ TABLE lt_usr_pro WITH KEY bname = lt_usr_tab-bname BINARY
    SEARCH.
    IF sy-subrc = 0.
      l_pro_usr = l_pro_usr + 1.
    ELSE.
      l_pro_no_usr = l_pro_no_usr + 1.
    ENDIF.
  ENDLOOP.
  SORT l_profile BY profn.
  SORT lt_usr_pro BY profile.
  LOOP AT l_profile.
    READ TABLE lt_usr_pro WITH KEY profile = l_profile-profn BINARY
    SEARCH.
    IF sy-subrc = 0.
      l_usr_pro = l_usr_pro + 1.
    ELSE.
      l_usr_no_pro = l_usr_no_pro + 1.
    ENDIF.
  ENDLOOP.
*
***************             AUTH       ***********************
  SELECT  auth
  FROM usr12
  INTO TABLE lt_auth
  WHERE aktps = 'A'.

  SORT lt_auth.
  DELETE ADJACENT DUPLICATES FROM lt_auth COMPARING ALL FIELDS.
  DESCRIBE TABLE lt_auth LINES l_auth.
  REFRESH : lt_auth.
  SELECT DISTINCT profile
  FROM ust04
  INTO TABLE lt_auth_usr.
  IF NOT lt_auth_usr[] IS INITIAL.
    SELECT subprof
    FROM ust10c
    INTO TABLE lt_auth_usr_dum
    FOR ALL ENTRIES IN lt_auth_usr
    WHERE profn = lt_auth_usr-profile.
    LOOP AT lt_auth_usr_dum.
      lt_auth_usr = lt_auth_usr_dum.
      APPEND lt_auth_usr.
    ENDLOOP.
    SELECT DISTINCT auth
    INTO TABLE lt_auth
    FROM ust10s
    FOR ALL ENTRIES IN lt_auth_usr
    WHERE profn = lt_auth_usr-profile
    AND aktps = 'A'.
    l_auth_usr = sy-dbcnt.

    l_auth_no_usr = l_auth - l_auth_usr.
  ENDIF.

**                 Comp role                **

  SELECT COUNT( DISTINCT agr_name ) FROM agr_flags
  INTO l_comp_rol
  WHERE flag_type = 'COLL_AGR'
  AND flag_value = 'X'.


  SELECT COUNT( DISTINCT a~agr_name )
  INTO l_corol_usr
  FROM agr_flags AS u INNER JOIN  agr_users AS a
  ON u~agr_name = a~agr_name
   WHERE u~flag_type = 'COLL_AGR'
    AND u~flag_value = 'X'.

  l_corol_no_usr = l_comp_rol - l_corol_usr.

***         Single Role    **
*  SELECT COUNT( DISTINCT agr_name )
*  FROM agr_flags
*  INTO l_sinrol
*  WHERE flag_type = 'COLL_AGR'
*  AND flag_value = ' '.
  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
    EXPORTING
      i_composite_roles = ''
      i_single_roles    = 'X'
    IMPORTING
      e_count           = l_sinrol.

  SELECT COUNT( DISTINCT a~agr_name )
  INTO l_sinrol_usr
  FROM agr_flags AS u INNER JOIN  agr_users AS a
  ON u~agr_name = a~agr_name
  WHERE flag_type = 'COLL_AGR'
  AND flag_value = ' '.

  l_sinrol_n_usr = l_sinrol - l_sinrol_usr.


**      Single Parent Roles                 **
  SELECT COUNT( DISTINCT parent_agr )
    FROM agr_define
    INTO l_prnt_role
    WHERE parent_agr <> ' '.

  SELECT COUNT( DISTINCT u~parent_agr )
  INTO l_prnt_usr
  FROM agr_define AS u INNER JOIN  agr_users AS a
  ON u~agr_name = a~agr_name
  WHERE u~parent_agr <> ' '.
  l_prnt_n_usr = l_prnt_role - l_prnt_usr.



**            Derived Roles                     **
  SELECT COUNT( DISTINCT agr_name )
  FROM agr_define
  INTO l_drv_rol
  WHERE parent_agr <> ' '.

  SELECT COUNT( DISTINCT u~agr_name )
  INTO l_drvrol_usr
  FROM agr_define AS u INNER JOIN  agr_users AS a
  ON u~agr_name = a~agr_name
  WHERE u~parent_agr <> ' '.
  l_drvrol_n_usr = l_drv_rol - l_drvrol_usr.


  l_avg_drv = ( l_drv_rol / l_prnt_role ) .

  SELECT COUNT( DISTINCT agr_name )
  FROM agr_agrs
  INTO l_comp_rol1
  WHERE agr_name <> ' '.

  SELECT COUNT( DISTINCT child_agr )
  FROM agr_agrs
  INTO l_sing_rol1
  WHERE agr_name <> ' '.
  l_avg_srol = ( l_sing_rol1 / l_comp_rol1 ) .

*******  avg role user **********************

  SELECT COUNT( DISTINCT agr_name )
  FROM agr_users
  INTO l_tot_rol
  WHERE agr_name <> ' '.

  SELECT COUNT( DISTINCT uname )
  FROM agr_users
  INTO l_tot_usr
  WHERE agr_name <> ' '.
  l_avg_rol_usr = ( l_tot_rol / l_tot_usr ) .

************ avg profile per user ****************

  SELECT COUNT( DISTINCT profile )
  FROM ust04
  INTO l_tot_rol
  WHERE profile <> ' '.

  SELECT COUNT( DISTINCT bname )                 "#EC SAST_CI_GEN_CHECK
  FROM ust04
  INTO l_tot_usr
  WHERE bname <> ' '.
  l_avg_pro_usr = ( l_tot_rol / l_tot_usr ) .

**              AVG AUTH PER USR **************

  SELECT COUNT( DISTINCT bname )                 "#EC SAST_CI_GEN_CHECK
  FROM ust04
  INTO l_au_usr
  WHERE bname <> ' '.

  l_avg_auth_usr = ( l_auth_usr / l_au_usr ).


**             AVG PROFILE PER ROLE                 **

  SELECT COUNT( DISTINCT profile )
  FROM agr_1016
  INTO l_tot_rol
  WHERE profile <> ' '.

  SELECT COUNT( DISTINCT agr_name )
  FROM agr_1016
  INTO l_tot_usr
  WHERE agr_name <> ' '.
  l_avg_pro_rol = ( l_tot_rol / l_tot_usr ) .

**       transaction to role         **

  SELECT COUNT( DISTINCT tcode )
  FROM agr_tcodes
  INTO l_tot_rol
  WHERE tcode <> ' '.

  SELECT COUNT( DISTINCT agr_name )
  FROM agr_tcodes
  INTO l_tot_usr
  WHERE agr_name <> ' '.

  l_avg_tcd_rol = ( l_tot_rol / l_tot_usr ) .


****      Authorizations per Role     ************

  SELECT COUNT( DISTINCT auth )
  FROM agr_1251
  INTO l_tot_rol
  WHERE auth <> ' ' AND
  deleted = ' '.

  SELECT COUNT( DISTINCT agr_name )
  FROM agr_1251
  INTO l_tot_usr
  WHERE agr_name <> ' ' AND
  deleted = ' '.
  l_avg_auth_rol = ( l_tot_rol / l_tot_usr ) .

****************** OUTPUT SECTION ***************************
  DATA l_count TYPE string.
  CLEAR l_count.
  l_count = l_usr_cnt.
  CONCATENATE text-002 ':' l_count INTO e_sec_info-usr_count.
  CLEAR l_count.
  l_count = l_vlid_usr_cnt.
  CONCATENATE text-003 ':' l_count INTO e_sec_info-vusr_count.
  CLEAR l_count.
  l_count = l_role_cnt.
  CONCATENATE text-004 ':' l_count INTO e_sec_info-role_count.
  CLEAR l_count.
  l_count = l_usr_role.
  CONCATENATE text-005 ':' l_count INTO e_sec_info-usr_role.
  CLEAR l_count.
  l_count = l_usr_no_role.
  CONCATENATE text-006 ':' l_count INTO e_sec_info-usr_no_role.
  CLEAR l_count.
  l_count = l_role_usr.
  CONCATENATE text-007 ':' l_count INTO e_sec_info-role_usr.
  CLEAR l_count.
  l_count = l_role_no_usr.
  CONCATENATE text-008 ':' l_count INTO e_sec_info-role_no_usr.
  CLEAR l_count.
  l_count = l_prof_cnt.
  CONCATENATE text-009 ':' l_count INTO e_sec_info-prof_count.
  CLEAR l_count.
  l_count = l_pro_usr.
  CONCATENATE text-010 ':' l_count INTO e_sec_info-prof_usr.
  CLEAR l_count.
  l_count = l_pro_no_usr.
  CONCATENATE text-011 ':' l_count INTO e_sec_info-prof_no_usr.
  CLEAR l_count.
  l_count = l_usr_pro.
  CONCATENATE text-012 ':' l_count INTO e_sec_info-usr_prof.
  CLEAR l_count.
  l_count = l_usr_no_pro.
  CONCATENATE text-013 ':' l_count INTO e_sec_info-usr_no_prof.
  CLEAR l_count.
  l_count = l_auth.
  CONCATENATE text-014 ':' l_count INTO e_sec_info-auth_count.
  CLEAR l_count.
  l_count = l_auth_usr.
  CONCATENATE text-015 ':' l_count INTO e_sec_info-auth_usr.
  CLEAR l_count.
  l_count = l_auth_no_usr.
  CONCATENATE text-016 ':' l_count INTO e_sec_info-auth_no_usr.
  CLEAR l_count.
  l_count = l_comp_rol.
  CONCATENATE text-017 ':' l_count INTO e_sec_info-comp_role.
  CLEAR l_count.
  l_count = l_corol_usr.
  CONCATENATE text-018 ':' l_count INTO e_sec_info-comprole_usr.
  CLEAR l_count.
  l_count = l_corol_no_usr.
  CONCATENATE text-019 ':' l_count INTO e_sec_info-comprole_no_usr.
  CLEAR l_count.
  l_count = l_sinrol.
  CONCATENATE text-020 ':' l_count INTO e_sec_info-sinrole.
  CLEAR l_count.
  l_count = l_sinrol_usr.
  CONCATENATE text-021 ':' l_count INTO e_sec_info-sinrole_usr.
  CLEAR l_count.
  l_count = l_sinrol_n_usr.
  CONCATENATE text-022 ':' l_count INTO e_sec_info-sinrol_n_usr.
  CLEAR l_count.
  l_count = l_prnt_role.
  CONCATENATE text-023 ':' l_count INTO e_sec_info-prnt_role.
  CLEAR l_count.
  l_count = l_prnt_usr.
  CONCATENATE text-024 ':' l_count INTO e_sec_info-prnt_usr.
  CLEAR l_count.
  l_count = l_prnt_n_usr.
  CONCATENATE text-025 ':' l_count INTO e_sec_info-prnt_n_usr.
  CLEAR l_count.
  l_count = l_drv_rol.
  CONCATENATE text-026 ':' l_count INTO e_sec_info-drv_role.
  CLEAR l_count.
  l_count = l_drvrol_usr.
  CONCATENATE text-027 ':' l_count INTO e_sec_info-drvrol_usr.
  CLEAR l_count.
  l_count = l_drvrol_n_usr.
  CONCATENATE text-028 ':' l_count INTO e_sec_info-drvrol_n_usr.
  CLEAR l_count.
  l_count = l_avg_drv.
  CONCATENATE text-030 ':' l_count INTO e_sec_info-avg_drv.
  CLEAR l_count.
  l_count = l_avg_srol.
  CONCATENATE text-031 ':' l_count INTO e_sec_info-avg_srole.
  CLEAR l_count.
  l_count = l_avg_rol_usr.
  CONCATENATE text-032 ':' l_count INTO e_sec_info-avg_role_usr.
  CLEAR l_count.
  l_count = l_avg_pro_usr.
  CONCATENATE text-033 ':' l_count INTO e_sec_info-avg_prof_usr.
  CLEAR l_count.
  l_count = l_avg_auth_usr.
  CONCATENATE text-034 ':' l_count INTO e_sec_info-avg_auth_usr.
  CLEAR l_count.
  l_count = l_avg_pro_rol.
  CONCATENATE text-035 ':' l_count INTO e_sec_info-avg_prof_role.
  CLEAR l_count.
  l_count = l_avg_tcd_rol.
  CONCATENATE text-036 ':' l_count INTO e_sec_info-avg_tcd_role.
  CLEAR l_count.
  l_count = l_avg_auth_rol.
  CONCATENATE text-037 ':' l_count INTO e_sec_info-avg_auth_role.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM table_cal                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM table_cal
TABLES
      et_agrtab  STRUCTURE /psyng/sw_table_text
      et_usrtab  STRUCTURE /psyng/sw_table_text
      et_psyngtab  STRUCTURE /psyng/sw_table_text
      et_configtab  STRUCTURE /psyng/sw_table_text
      et_mittab  STRUCTURE /psyng/sw_table_text
      et_restab  STRUCTURE /psyng/sw_table_text
USING i_se_tables_size TYPE flag
CHANGING
      e_agr_count TYPE /psyng/longtextfield
      e_usr_count TYPE /psyng/longtextfield
      e_psyng_count TYPE /psyng/longtextfield
      e_config_count TYPE /psyng/longtextfield
      e_mit_count TYPE /psyng/longtextfield
      e_res_count TYPE /psyng/longtextfield
      ef_not_auth TYPE flag
      ef_oracle   TYPE flag.

  DATA: BEGIN OF it_tabnam OCCURS 0,
          tabname TYPE dd02t-tabname,
          ddtext  TYPE dd02t-ddtext,
          rcd_cnt TYPE i,
        END OF it_tabnam.

  DATA: BEGIN OF it_tabtext OCCURS 0,
          tabname TYPE dd02t-tabname,
          ddtext  TYPE dd02t-ddtext,
        END OF it_tabtext.
  DATA: l_agr_cnt TYPE i.
  DATA: l_count     TYPE string,
        ef_hana     TYPE c, "Changes by RGUPTA on 18th Nov, 2021
        l_hana_size TYPE sy-ccurs.
*lf_funcname TYPE rs38l_fnam. "Changes by RGUPTA on 18th Nov, 2021

  DATA:lt_bdlsystinf TYPE TABLE OF bdlsystinf WITH HEADER LINE.
  DATA:l_tabname TYPE segments_f-sn.
  DATA:lt_segments TYPE TABLE OF segments_f WITH HEADER LINE,
       lt_table    TYPE TABLE OF /psyng/sw_table_text.
*lt_tables_hana TYPE TABLE OF /psyng/table WITH HEADER LINE,
*"Changes by RGUPTA on 18th Nov, 2021
*lt_hana_info   TYPE TABLE OF /psyng/bc_hdb_table_info WITH HEADER LINE.
*"Changes by RGUPTA on 18th Nov, 2021
  DATA: list LIKE abaplist OCCURS 0 WITH HEADER LINE.
  CONSTANTS: lc_funcname TYPE rs38l_fnam VALUE 'GET_TABLE_SIZE_ALL'.
  "Changes by RGUPTA on 18th Nov, 2021
  DATA: lv_tab_typ TYPE c. "Changes by RGUPTA on 20th Jan 22
  DEFINE add_hana_dbinfo.
    CLEAR l_hana_size.
    CALL FUNCTION lc_funcname                "#EC PATHLOCK_CI_DYN_ACCES
          EXPORTING
            tabname                 = &1
*             DATA_SPACE_ONLY         =
         IMPORTING
           tabsize                 = l_hana_size
         EXCEPTIONS
           no_database_table       = 1
           OTHERS                  = 2.          "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
              &2-s_type  = 'TABLE'.
              l_hana_size = l_hana_size * 1000 / 1024 ."RGUPTA 17/01/22
              &2-kbytes  = l_hana_size.
              case lv_tab_typ.
                when '1'.
                  &2-tabname = et_agrtab-tabname.
                when '2'.
                  &2-tabname = et_usrtab-tabname.
                when '3'.
                  &2-tabname = et_psyngtab-tabname.
                when '4'.
                  &2-tabname = et_configtab-tabname.
                when '5'.
                  &2-tabname = et_mittab-tabname.
                when '6'.
                  &2-tabname = et_restab-tabname.
             ENDCASE.
              APPEND &2 TO lt_table.
     ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.

  END-OF-DEFINITION.

*--In ECC6EHP7, new authorization objects are introduced.
*--Users that don't have access to them, can't read system info.
*--See SAP note 1688226
*--Add flag for ORACLE DATABASE.

  CALL FUNCTION 'BDL_SYSTEM_INFO'
    TABLES
      system_info      = lt_bdlsystinf
    EXCEPTIONS
      no_authorization = 1
      OTHERS           = 2.
  IF sy-subrc <> 0.
    ef_not_auth = 'X'.
*   You are not authorized to read System info.
  ELSE.
    READ TABLE lt_bdlsystinf WITH KEY key = 'DBSYS'
    TRANSPORTING value.
    IF lt_bdlsystinf-value EQ 'ORACLE'.
      ef_oracle = 'X'.
* BOC by RGUPTA on 18th Nov, 2021
    ELSEIF lt_bdlsystinf-value EQ 'HDB'.
      ef_hana = 'X'.
* EOC by RGUPTA on 18th Nov, 2021
    ENDIF.
  ENDIF.

* new AGR* Table to be added here
  IF i_se_tables_size IS INITIAL.
    et_agrtab-tabname ='AGR_1016'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_1250'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_1251'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_1252'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_1253'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_AGRS'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_DEFINE'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_HIER'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_USERT'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_PROF'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_TCODES'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_TEXTS'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_TIME'.
    APPEND et_agrtab.
    et_agrtab-tabname ='AGR_USERS'.
    APPEND et_agrtab.

    DESCRIBE TABLE et_agrtab LINES l_agr_cnt.

    SELECT DISTINCT tabname ddtext
    FROM dd02t
    INTO TABLE it_tabtext
    WHERE tabname LIKE 'AGR%'
    AND ddlanguage = sy-langu.                   "#EC SAST_CI_GEN_CHECK

    LOOP AT et_agrtab.
      CLEAR: et_agrtab-rcd_cnt,et_agrtab-ddtext,
             l_tabname.
      REFRESH lt_segments.

      CASE et_agrtab-tabname.
        WHEN'AGR_1016'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_1016
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_1250'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_1250
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_1251'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_1251
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_1252'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_1252
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_1253'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_1253
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_AGRS'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_agrs
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_DEFINE'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_define
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_HIER'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_hier
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_USERT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_usert
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_PROF'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_prof
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_TCODES'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_tcodes
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_TEXTS'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_texts
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_TIME'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_time
             INTO et_agrtab-rcd_cnt .
        WHEN'AGR_USERS'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
             FROM agr_users
             INTO et_agrtab-rcd_cnt .
      ENDCASE.


*      SELECT COUNT( * )                              "#EC CI_SEL_NESTED
*       FROM (et_agrtab-tabname)
*       INTO et_agrtab-rcd_cnt .
      READ TABLE it_tabtext WITH KEY tabname = et_agrtab-tabname.
      IF sy-subrc = 0.
        et_agrtab-ddtext = it_tabtext-ddtext.
      ENDIF.
      MODIFY et_agrtab TRANSPORTING rcd_cnt ddtext.

*--Add size details of table; if DB is Oracle
      IF ef_not_auth IS INITIAL
      AND NOT ef_oracle IS INITIAL.
        CLEAR l_tabname.
        CONCATENATE  et_agrtab-tabname '*' INTO  l_tabname.
        CALL FUNCTION 'DB02_ORA_SELECT_SEGMENTS'
          EXPORTING
            seg_name     = l_tabname
          TABLES
            dba_segments = lt_segments.
        SORT lt_segments BY sn.
        READ TABLE lt_segments
          WITH KEY sn = et_agrtab-tabname
          BINARY SEARCH.
        IF sy-subrc EQ 0.
          et_agrtab-s_type  = lt_segments-s_type.
          et_agrtab-kbytes  = lt_segments-kbytes.
          et_agrtab-blocks  = lt_segments-blocks.
          et_agrtab-extents = lt_segments-extents.
          MODIFY et_agrtab TRANSPORTING s_type kbytes blocks extents.
        ELSE.
          et_agrtab-s_type = 'TABLE'.
          MODIFY et_agrtab TRANSPORTING s_type.
        ENDIF.
        LOOP AT lt_segments WHERE s_type EQ 'INDEX'.
          CLEAR et_agrtab.
          et_agrtab-s_type  = lt_segments-s_type.
          et_agrtab-kbytes  = lt_segments-kbytes.
          et_agrtab-blocks  = lt_segments-blocks.
          et_agrtab-extents = lt_segments-extents.
          et_agrtab-tabname = lt_segments-sn.
          APPEND et_agrtab TO lt_table.
        ENDLOOP.
      ELSEIF ef_not_auth IS INITIAL AND ef_hana IS NOT INITIAL.
        lv_tab_typ = '1'. "RGUPTA on 20-01-22
        add_hana_dbinfo et_agrtab-tabname et_agrtab.
                                             "#EC PATHLOCK_CI_DYN_ACCES
      ELSE.
        et_agrtab-s_type = 'TABLE'.
        MODIFY et_agrtab TRANSPORTING s_type.
      ENDIF.
    ENDLOOP.
    IF ef_hana IS NOT INITIAL AND lt_table[] IS NOT INITIAL.
      REFRESH et_agrtab.
    ELSEIF ef_hana IS NOT INITIAL AND lt_table[] IS INITIAL.
      et_agrtab-s_type = 'TABLE'.
      MODIFY et_agrtab TRANSPORTING s_type.
    ENDIF.
    APPEND LINES OF lt_table TO et_agrtab.
    REFRESH lt_table.
    SORT et_agrtab BY tabname.

    l_count = l_agr_cnt .
    CONCATENATE text-055 ':' l_count INTO e_agr_count.
    CLEAR l_count.

*** for all us* table ********

*  REFRESH : it_tabnam,it_tabtext.
* new US* Table to be added here
    et_usrtab-tabname ='USR02'.
    APPEND et_usrtab.
    et_usrtab-tabname ='UST10S'.
    APPEND et_usrtab.
    et_usrtab-tabname ='UST12'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USCOMPANY'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USGRP'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USGRPT'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USGRP_USER'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USOBT_C'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USR05'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USR10'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USR11'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USR21'.
    APPEND et_usrtab.
    et_usrtab-tabname ='USREFUS'.
    APPEND et_usrtab.
    et_usrtab-tabname ='UST04'.
    APPEND et_usrtab.
    et_usrtab-tabname ='UST10C'.
    APPEND et_usrtab.

    DESCRIBE TABLE et_usrtab LINES l_agr_cnt.
    SELECT DISTINCT tabname ddtext
    FROM dd02t
    INTO TABLE it_tabtext
    WHERE tabname LIKE 'US%'
    AND ddlanguage = sy-langu.                   "#EC SAST_CI_GEN_CHECK

    LOOP AT et_usrtab.
      CASE et_usrtab-tabname.
        WHEN'USR02'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usr02
              INTO et_usrtab-rcd_cnt .
        WHEN'UST10S'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM ust10s
              INTO et_usrtab-rcd_cnt .
        WHEN'UST12'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM ust12
              INTO et_usrtab-rcd_cnt .
        WHEN'USCOMPANY'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM uscompany
              INTO et_usrtab-rcd_cnt .
        WHEN'USGRP'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usgrp
              INTO et_usrtab-rcd_cnt .
        WHEN'USGRPT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usgrpt
              INTO et_usrtab-rcd_cnt .
        WHEN'USGRP_USER'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usgrp_user
              INTO et_usrtab-rcd_cnt .
        WHEN'USOBT_C'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usobt_c
              INTO et_usrtab-rcd_cnt .
        WHEN'USR05'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usr05
              INTO et_usrtab-rcd_cnt .
        WHEN'USR10'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usr10
              INTO et_usrtab-rcd_cnt .
        WHEN'USR11'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usr11
              INTO et_usrtab-rcd_cnt .
        WHEN'USR21'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usr21
              INTO et_usrtab-rcd_cnt .
        WHEN'USREFUS'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM usrefus
              INTO et_usrtab-rcd_cnt .
        WHEN'UST04'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM ust04
              INTO et_usrtab-rcd_cnt .
        WHEN'UST10C'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
              FROM ust10c
              INTO et_usrtab-rcd_cnt .
      ENDCASE.

*      SELECT COUNT( * )                              "#EC CI_SEL_NESTED
*        FROM (et_usrtab-tabname)
*        INTO et_usrtab-rcd_cnt .
      READ TABLE it_tabtext WITH KEY tabname = et_usrtab-tabname.
      IF sy-subrc = 0.
        et_usrtab-ddtext = it_tabtext-ddtext.
      ENDIF.
      MODIFY et_usrtab TRANSPORTING rcd_cnt ddtext.
*      CLEAR: et_usrtab-rcd_cnt,et_usrtab-ddtext.

*--Add size details of table; if DB is Oracle
      IF ef_not_auth IS INITIAL
      AND NOT ef_oracle IS INITIAL.
        CLEAR l_tabname.
        REFRESH lt_segments.
        CONCATENATE  et_usrtab-tabname '*' INTO l_tabname.
        CALL FUNCTION 'DB02_ORA_SELECT_SEGMENTS'
          EXPORTING
            seg_name     = l_tabname
          TABLES
            dba_segments = lt_segments.
        SORT lt_segments BY sn.
        READ TABLE lt_segments
          WITH KEY sn = et_usrtab-tabname
          BINARY SEARCH.
        IF sy-subrc EQ 0.
          et_usrtab-s_type  = lt_segments-s_type.
          et_usrtab-kbytes  = lt_segments-kbytes.
          et_usrtab-blocks  = lt_segments-blocks.
          et_usrtab-extents = lt_segments-extents.
          MODIFY et_usrtab TRANSPORTING s_type kbytes blocks extents.
        ELSE.
          et_usrtab-s_type = 'TABLE'.
          MODIFY et_usrtab TRANSPORTING s_type.
        ENDIF.
        LOOP AT lt_segments WHERE s_type EQ 'INDEX'.
          CLEAR et_usrtab.
          et_usrtab-s_type  = lt_segments-s_type.
          et_usrtab-kbytes  = lt_segments-kbytes.
          et_usrtab-blocks  = lt_segments-blocks.
          et_usrtab-extents = lt_segments-extents.
          et_usrtab-tabname = lt_segments-sn.
          APPEND et_usrtab TO lt_table.
        ENDLOOP.
      ELSEIF ef_not_auth IS INITIAL AND ef_hana IS NOT INITIAL.
        lv_tab_typ = '2'. "RGUPTA on 20-01-22
        add_hana_dbinfo et_usrtab-tabname et_usrtab.
                                             "#EC PATHLOCK_CI_DYN_ACCES
      ELSE.
        et_usrtab-s_type = 'TABLE'.
        MODIFY et_usrtab TRANSPORTING s_type.
      ENDIF.
    ENDLOOP.
    IF ef_hana IS NOT INITIAL AND lt_table[] IS NOT INITIAL.
      REFRESH et_usrtab.
    ELSEIF ef_hana IS NOT INITIAL AND lt_table[] IS INITIAL.
      et_usrtab-s_type = 'TABLE'.
      MODIFY et_usrtab TRANSPORTING s_type.
    ENDIF.
    APPEND LINES OF lt_table TO et_usrtab.
    REFRESH lt_table.
    SORT et_usrtab BY tabname.

    l_count = l_agr_cnt .
    CONCATENATE text-058 ':' l_count INTO e_usr_count.
    CLEAR l_count.
  ELSE.
* For all /psyng* Table
*----------------------------------------------------------
**Case:2059:Short Dump in Performance Diagnostic Report
**Excluded tabclass 'VIEW' from the table list
*----------------------------------------------------------
*  REFRESH : it_tabnam,it_tabtext.

*--SOD matrix Tables
    et_psyngtab-tabname ='/PSYNG/CONFLICT'.
    APPEND et_psyngtab.
    et_psyngtab-tabname ='/PSYNG/CONFDET'.
    APPEND et_psyngtab.
    et_psyngtab-tabname ='/PSYNG/FUNCTTRAN'.
    APPEND et_psyngtab.
    et_psyngtab-tabname ='/PSYNG/FAOBJ2'.
    APPEND et_psyngtab.
    et_psyngtab-tabname ='/PSYNG/SWAUDHDR'.
    APPEND et_psyngtab.
    et_psyngtab-tabname ='/PSYNG/SWAUDC2'.
    APPEND et_psyngtab.
    et_psyngtab-tabname ='/PSYNG/SWSODORGO'.
    APPEND et_psyngtab.
    et_psyngtab-tabname ='/PSYNG/CRITCODES'.
    APPEND et_psyngtab.

    DESCRIBE TABLE et_psyngtab LINES l_agr_cnt.

    LOOP AT et_psyngtab.

      CASE et_psyngtab-tabname.
        WHEN '/PSYNG/CONFLICT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/conflict
          INTO et_psyngtab-rcd_cnt .
        WHEN '/PSYNG/CONFDET'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/confdet
          INTO et_psyngtab-rcd_cnt .
        WHEN '/PSYNG/FUNCTTRAN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/functtran
          INTO et_psyngtab-rcd_cnt .
        WHEN '/PSYNG/FAOBJ2'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/faobj2
          INTO et_psyngtab-rcd_cnt .
        WHEN '/PSYNG/SWAUDHDR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/swaudhdr
          INTO et_psyngtab-rcd_cnt .
        WHEN '/PSYNG/SWAUDC2'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/swaudc2
          INTO et_psyngtab-rcd_cnt .
        WHEN '/PSYNG/SWSODORGO'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/swsodorgo
          INTO et_psyngtab-rcd_cnt .
        WHEN '/PSYNG/CRITCODES'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
          FROM /psyng/critcodes
          INTO et_psyngtab-rcd_cnt .
      ENDCASE.
*      SELECT COUNT( * )                             "#EC CI_SEL_NESTED
*        FROM (et_psyngtab-tabname)
*        INTO et_psyngtab-rcd_cnt .

      SELECT SINGLE ddtext
      FROM dd02t
      INTO (et_psyngtab-ddtext)
      WHERE tabname EQ et_psyngtab-tabname
      AND ddlanguage = sy-langu.                 "#EC SAST_CI_GEN_CHECK

      MODIFY et_psyngtab TRANSPORTING rcd_cnt ddtext.
*      CLEAR: et_psyngtab-rcd_cnt,et_psyngtab-ddtext.

*--Add size details of table; if DB is Oracle
      IF ef_not_auth IS INITIAL
      AND NOT ef_oracle IS INITIAL.
        CLEAR l_tabname.
        REFRESH lt_segments.
        CONCATENATE  et_psyngtab-tabname '*' INTO l_tabname.
        CALL FUNCTION 'DB02_ORA_SELECT_SEGMENTS'
          EXPORTING
            seg_name     = l_tabname
          TABLES
            dba_segments = lt_segments.
        SORT lt_segments BY sn.
        READ TABLE lt_segments
          WITH KEY sn = et_psyngtab-tabname
          BINARY SEARCH.
        IF sy-subrc EQ 0.
          et_psyngtab-s_type  = lt_segments-s_type.
          et_psyngtab-kbytes  = lt_segments-kbytes.
          et_psyngtab-blocks  = lt_segments-blocks.
          et_psyngtab-extents = lt_segments-extents.
          MODIFY et_psyngtab TRANSPORTING s_type kbytes blocks extents.
        ELSE.
          et_psyngtab-s_type = 'TABLE'.
          MODIFY et_psyngtab TRANSPORTING s_type.
        ENDIF.
        LOOP AT lt_segments WHERE s_type EQ 'INDEX'.
          CLEAR et_psyngtab.
          et_psyngtab-s_type  = lt_segments-s_type.
          et_psyngtab-kbytes  = lt_segments-kbytes.
          et_psyngtab-blocks  = lt_segments-blocks.
          et_psyngtab-extents = lt_segments-extents.
          et_psyngtab-tabname = lt_segments-sn.
          APPEND et_psyngtab TO lt_table.
        ENDLOOP.
      ELSEIF ef_not_auth IS INITIAL AND ef_hana IS NOT INITIAL.
        lv_tab_typ = '3'. "RGUPTA on 20-01-22
        add_hana_dbinfo et_psyngtab-tabname et_psyngtab.
                                             "#EC PATHLOCK_CI_DYN_ACCES
      ELSE.
        et_psyngtab-s_type = 'TABLE'.
        MODIFY et_psyngtab TRANSPORTING s_type.
      ENDIF.
    ENDLOOP.
    IF ef_hana IS NOT INITIAL AND lt_table[] IS NOT INITIAL.
      REFRESH et_psyngtab.
    ELSEIF ef_hana IS NOT INITIAL AND lt_table[] IS INITIAL.
      et_psyngtab-s_type = 'TABLE'.
      MODIFY et_psyngtab TRANSPORTING s_type.
    ENDIF.
    APPEND LINES OF lt_table TO et_psyngtab.
    REFRESH lt_table.
    SORT et_psyngtab BY tabname.

    l_count = l_agr_cnt .
    CONCATENATE text-060 ':' l_count INTO e_psyng_count.
    CLEAR l_count.

*--Configuration Set Tables
    et_configtab-tabname ='/PSYNG/SWCFGCMP'.
    APPEND et_configtab.
    et_configtab-tabname ='/PSYNG/SWCFGID'.
    APPEND et_configtab.
    et_configtab-tabname ='/PSYNG/SWCFGOE'.
    APPEND et_configtab.
    et_configtab-tabname ='/PSYNG/SWCFGSET'.
    APPEND et_configtab.
    et_configtab-tabname ='/PSYNG/SWCFGSYS'.
    APPEND et_configtab.
    et_configtab-tabname ='/PSYNG/SWCFGVE'.
    APPEND et_configtab.
    et_configtab-tabname ='/PSYNG/SW_VAREL'.
    APPEND et_configtab.
    et_configtab-tabname ='/PSYNG/SW_VARVR'.
    APPEND et_configtab.

    DESCRIBE TABLE et_configtab LINES l_agr_cnt.

    LOOP AT et_configtab.

      CASE et_configtab-tabname.
        WHEN'/PSYNG/SWCFGCMP'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swcfgcmp
                INTO et_configtab-rcd_cnt .
        WHEN'/PSYNG/SWCFGID'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swcfgid
                INTO et_configtab-rcd_cnt .
        WHEN'/PSYNG/SWCFGOE'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swcfgoe
                INTO et_configtab-rcd_cnt .
        WHEN'/PSYNG/SWCFGSET'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swcfgset
                INTO et_configtab-rcd_cnt .
        WHEN'/PSYNG/SWCFGSYS'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swcfgsys
                INTO et_configtab-rcd_cnt .
        WHEN'/PSYNG/SWCFGVE'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swcfgve
                INTO et_configtab-rcd_cnt .
        WHEN'/PSYNG/SW_VAREL'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/sw_varel
                INTO et_configtab-rcd_cnt .
        WHEN'/PSYNG/SW_VARVR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/sw_varvr
                INTO et_configtab-rcd_cnt .
      ENDCASE.
*      SELECT COUNT( * )                              "#EC CI_SEL_NESTED
*        FROM (et_configtab-tabname)
*        INTO et_configtab-rcd_cnt .

      SELECT SINGLE ddtext
      FROM dd02t
      INTO (et_configtab-ddtext)
      WHERE tabname EQ et_configtab-tabname
      AND ddlanguage = sy-langu.                 "#EC SAST_CI_GEN_CHECK

      MODIFY et_configtab TRANSPORTING rcd_cnt ddtext.
*      CLEAR: et_configtab-rcd_cnt,et_configtab-ddtext.

*--Add size details of table; if DB is Oracle
      IF ef_not_auth IS INITIAL
      AND NOT ef_oracle IS INITIAL.
        CLEAR l_tabname.
        REFRESH lt_segments.
        CONCATENATE  et_configtab-tabname '*' INTO l_tabname.
        CALL FUNCTION 'DB02_ORA_SELECT_SEGMENTS'
          EXPORTING
            seg_name     = l_tabname
          TABLES
            dba_segments = lt_segments.
        SORT lt_segments BY sn.
        READ TABLE lt_segments
          WITH KEY sn = et_configtab-tabname
          BINARY SEARCH.
        IF sy-subrc EQ 0.
          et_configtab-s_type  = lt_segments-s_type.
          et_configtab-kbytes  = lt_segments-kbytes.
          et_configtab-blocks  = lt_segments-blocks.
          et_configtab-extents = lt_segments-extents.
          MODIFY et_configtab TRANSPORTING s_type kbytes blocks extents.
        ELSE.
          et_configtab-s_type = 'TABLE'.
          MODIFY et_configtab TRANSPORTING s_type.
        ENDIF.
        LOOP AT lt_segments WHERE s_type EQ 'INDEX'.
          CLEAR et_configtab.
          et_configtab-s_type  = lt_segments-s_type.
          et_configtab-kbytes  = lt_segments-kbytes.
          et_configtab-blocks  = lt_segments-blocks.
          et_configtab-extents = lt_segments-extents.
          et_configtab-tabname = lt_segments-sn.
          APPEND et_configtab TO lt_table.
        ENDLOOP.
      ELSEIF ef_not_auth IS INITIAL AND ef_hana IS NOT INITIAL.
        lv_tab_typ = '4'. "RGUPTA on 20-01-22
        add_hana_dbinfo et_configtab-tabname et_configtab.
                                             "#EC PATHLOCK_CI_DYN_ACCES
      ELSE.
        et_configtab-s_type = 'TABLE'.
        MODIFY et_configtab TRANSPORTING s_type.
      ENDIF.
    ENDLOOP.
    IF ef_hana IS NOT INITIAL AND lt_table[] IS NOT INITIAL.
      REFRESH et_configtab.
    ELSEIF ef_hana IS NOT INITIAL AND lt_table[] IS INITIAL.
      et_configtab-s_type = 'TABLE'.
      MODIFY et_configtab TRANSPORTING s_type.
    ENDIF.
    APPEND LINES OF lt_table TO et_configtab.
    REFRESH lt_table.
    SORT et_configtab BY tabname.

    l_count = l_agr_cnt .
    CONCATENATE text-101 ':' l_count INTO e_config_count.
    CLEAR l_count.

*--Mitigations Tables
    et_mittab-tabname ='/PSYNG/MCAUDITOR'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCCAROLE'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCCAUSER'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCHDR'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCHISRPT'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCHISTMON'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCHISTXN'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCREPID'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCROLE'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCRVWHDR'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCRVWSGN'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCRVWTXT'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCTRAN'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCUGROUP'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCUGRPAUD'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCUSER'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCUSERAUD'.
    APPEND et_mittab.
    et_mittab-tabname ='/PSYNG/MCUSRGRP'.
    APPEND et_mittab.

    DESCRIBE TABLE et_mittab LINES l_agr_cnt.

    LOOP AT et_mittab.

      CASE et_mittab-tabname.
        WHEN '/PSYNG/MCAUDITOR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcauditor
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCCAROLE'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mccarole
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCCAUSER'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mccauser
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCHDR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mchdr
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCHISRPT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mchisrpt
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCHISTMON'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mchistmon
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCHISTXN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mchistxn
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCREPID'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcrepid
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCROLE'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcrole
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCRVWHDR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcrvwhdr
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCRVWSGN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcrvwsgn
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCRVWTXT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcrvwtxt
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCTRAN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mctran
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCUGROUP'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcugroup
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCUGRPAUD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcugrpaud
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCUSER'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcuser
            INTO et_mittab-rcd_cnt .
        WHEN '/PSYNG/MCUSERAUD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
            FROM /psyng/mcuseraud
            INTO et_mittab-rcd_cnt .
        WHEN'/PSYNG/MCUSRGRP'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                  FROM /psyng/mcusrgrp
                  INTO et_mittab-rcd_cnt.
      ENDCASE.


*      SELECT COUNT( * )
*        FROM (et_mittab-tabname)
*        INTO et_mittab-rcd_cnt .

      SELECT SINGLE ddtext
      FROM dd02t
      INTO (et_mittab-ddtext)
      WHERE tabname EQ et_mittab-tabname
      AND ddlanguage = sy-langu.                 "#EC SAST_CI_GEN_CHECK

      MODIFY et_mittab TRANSPORTING rcd_cnt ddtext.
*      CLEAR: et_mittab-rcd_cnt,et_mittab-ddtext.

*--Add size details of table; if DB is Oracle
      IF ef_not_auth IS INITIAL
      AND NOT ef_oracle IS INITIAL.
        CLEAR l_tabname.
        REFRESH lt_segments.
        CONCATENATE  et_mittab-tabname '*' INTO l_tabname.
        CALL FUNCTION 'DB02_ORA_SELECT_SEGMENTS'
          EXPORTING
            seg_name     = l_tabname
          TABLES
            dba_segments = lt_segments.
        SORT lt_segments BY sn.
        READ TABLE lt_segments
          WITH KEY sn = et_mittab-tabname
          BINARY SEARCH.
        IF sy-subrc EQ 0.
          et_mittab-s_type  = lt_segments-s_type.
          et_mittab-kbytes  = lt_segments-kbytes.
          et_mittab-blocks  = lt_segments-blocks.
          et_mittab-extents = lt_segments-extents.
          MODIFY et_mittab TRANSPORTING s_type kbytes blocks extents.
        ELSE.
          et_mittab-s_type = 'TABLE'.
          MODIFY et_mittab TRANSPORTING s_type.
        ENDIF.
        LOOP AT lt_segments WHERE s_type EQ 'INDEX'.
          CLEAR et_mittab.
          et_mittab-s_type  = lt_segments-s_type.
          et_mittab-kbytes  = lt_segments-kbytes.
          et_mittab-blocks  = lt_segments-blocks.
          et_mittab-extents = lt_segments-extents.
          et_mittab-tabname = lt_segments-sn.
          APPEND et_mittab TO lt_table.
        ENDLOOP.
      ELSEIF ef_not_auth IS INITIAL AND ef_hana IS NOT INITIAL.
        lv_tab_typ = '5'. "RGUPTA on 20-01-22
        add_hana_dbinfo et_mittab-tabname et_mittab.
                                             "#EC PATHLOCK_CI_DYN_ACCES
      ELSE.
        et_mittab-s_type = 'TABLE'.
        MODIFY et_mittab TRANSPORTING s_type.
      ENDIF.
    ENDLOOP.
    IF ef_hana IS NOT INITIAL AND lt_table[] IS NOT INITIAL.
      REFRESH et_mittab.
    ELSEIF ef_hana IS NOT INITIAL AND lt_table[] IS INITIAL.
      et_mittab-s_type = 'TABLE'.
      MODIFY et_mittab TRANSPORTING s_type.
    ENDIF.
    APPEND LINES OF lt_table TO et_mittab.
    REFRESH lt_table.
    SORT et_mittab BY tabname.

    l_count = l_agr_cnt .
    CONCATENATE text-102 ':' l_count INTO e_mit_count.
    CLEAR l_count.

*--Stored results Tables
    et_restab-tabname ='/PSYNG/SWRESAUTH'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESCAUT'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESCFUN'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESCON'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESFPR'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESHDR'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESIABB'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESIAUT'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESICON'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESID'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESIFLD'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESIFUN'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESIOBJ'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESIPRO'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESIROL'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESISYS'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESITCD'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESPROL'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESUABB'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESUCOM'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESUPR'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESUSR'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESVBA'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRESVBAI'.
    APPEND et_restab.
*    Stored roles table
    et_restab-tabname ='/PSYNG/SWRRSCAUT'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSCFUN'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSCON'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSHDR'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSIABB'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSIAUT'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSICHD'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSICON'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSID'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSIFLD'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSIFUN'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSIOBJ'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSITCD'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSRABB'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSRCHD'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SWRRSROL'.
    APPEND et_restab.

    et_restab-tabname ='/PSYNG/SYSCANDT'.
    APPEND et_restab.
    et_restab-tabname ='/PSYNG/SYSCANDT2'.
    APPEND et_restab.

    DESCRIBE TABLE et_restab LINES l_agr_cnt.

    LOOP AT et_restab.
      CASE et_restab-tabname .
        WHEN'/PSYNG/SWRESAUTH'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresauth
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESCAUT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrescaut
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESCFUN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrescfun
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESCON'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrescon
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESFPR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresfpr
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESHDR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swreshdr
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESIABB'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresiabb
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESIAUT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresiaut
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESICON'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresicon
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESID'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresid
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESIFLD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresifld
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESIFUN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresifun
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESIOBJ'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresiobj
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESIPRO'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresipro
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESIROL'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresirol
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESISYS'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresisys
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESITCD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresitcd
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESPROL'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresprol
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESUABB'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresuabb
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESUCOM'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresucom
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESUPR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresupr
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESUSR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresusr
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESVBA'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresvba
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRESVBAI'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swresvbai
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSCAUT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrscaut
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSCFUN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrscfun
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSCON'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrscon
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSHDR'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrshdr
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSIABB'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsiabb
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSIAUT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsiaut
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSICHD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsichd
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSICON'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsicon
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSID'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsid
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSIFLD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsifld
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSIFUN'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsifun
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSIOBJ'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsiobj
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSITCD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsitcd
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSRABB'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsrabb
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSRCHD'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsrchd
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SWRRSROL'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/swrrsrol
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SYSCANDT'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/syscandt
                INTO et_restab-rcd_cnt .
        WHEN'/PSYNG/SYSCANDT2'.
          SELECT COUNT( * )                          "#EC CI_SEL_NESTED
                FROM /psyng/syscandt2
                INTO et_restab-rcd_cnt .
      ENDCASE.
*      SELECT COUNT( * )                              "#EC CI_SEL_NESTED
*        FROM (et_restab-tabname)
*        INTO et_restab-rcd_cnt .

      SELECT SINGLE ddtext
      FROM dd02t
      INTO (et_restab-ddtext)
      WHERE tabname EQ et_restab-tabname
      AND ddlanguage = sy-langu.                 "#EC SAST_CI_GEN_CHECK

      MODIFY et_restab TRANSPORTING rcd_cnt ddtext.
*      CLEAR: et_restab-rcd_cnt,et_restab-ddtext.

*--Add size details of table; if DB is Oracle
      IF ef_not_auth IS INITIAL
      AND NOT ef_oracle IS INITIAL.
        CLEAR l_tabname.
        REFRESH lt_segments.
        CONCATENATE  et_restab-tabname '*' INTO l_tabname.
        CALL FUNCTION 'DB02_ORA_SELECT_SEGMENTS'
          EXPORTING
            seg_name     = l_tabname
          TABLES
            dba_segments = lt_segments.
        SORT lt_segments BY sn.
        READ TABLE lt_segments
          WITH KEY sn = et_restab-tabname
          BINARY SEARCH.
        IF sy-subrc EQ 0.
          et_restab-s_type  = lt_segments-s_type.
          et_restab-kbytes  = lt_segments-kbytes.
          et_restab-blocks  = lt_segments-blocks.
          et_restab-extents = lt_segments-extents.
          MODIFY et_restab TRANSPORTING s_type kbytes blocks extents.
        ELSE.
          et_restab-s_type = 'TABLE'.
          MODIFY et_restab TRANSPORTING s_type.
        ENDIF.
        LOOP AT lt_segments WHERE s_type EQ 'INDEX'.
          CLEAR et_restab.
          et_restab-s_type  = lt_segments-s_type.
          et_restab-kbytes  = lt_segments-kbytes.
          et_restab-blocks  = lt_segments-blocks.
          et_restab-extents = lt_segments-extents.
          et_restab-tabname = lt_segments-sn.
          APPEND et_restab TO lt_table.
        ENDLOOP.
      ELSEIF ef_not_auth IS INITIAL AND ef_hana IS NOT INITIAL.
        lv_tab_typ = '6'. "RGUPTA on 20-01-22
        add_hana_dbinfo et_restab-tabname et_restab.
      ELSE.
        et_restab-s_type = 'TABLE'.
        MODIFY et_restab TRANSPORTING s_type.
      ENDIF.
    ENDLOOP.
    IF ef_hana IS NOT INITIAL AND lt_table[] IS NOT INITIAL.
      REFRESH et_restab.
    ELSEIF ef_hana IS NOT INITIAL AND lt_table[] IS INITIAL.
      et_restab-s_type = 'TABLE'.
      MODIFY et_restab TRANSPORTING s_type.
    ENDIF.
    APPEND LINES OF lt_table TO et_restab.
    REFRESH lt_table.
    SORT et_restab BY tabname.

    l_count = l_agr_cnt .
    CONCATENATE text-103 ':' l_count INTO e_res_count.
    CLEAR l_count.

  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_sw_tps                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_sw_tps
  TABLES
    et_trans   STRUCTURE e07t.
  DATA: l_trkorr  TYPE e070-trkorr,
        l_as4text TYPE e07t-as4text.

  SELECT e070~trkorr e07t~as4text
*           INTO (l_trkorr, l_as4text)
           INTO CORRESPONDING FIELDS OF TABLE
           et_trans
           FROM e070
     INNER JOIN e07t
             ON e070~trkorr = e07t~trkorr
          WHERE e070~strkorr = space
                AND e07t~langu = sy-langu
                AND (
                       e070~trkorr LIKE 'P33%' OR
                       e070~trkorr LIKE 'P7Q%' OR
                       e070~trkorr LIKE 'P7C%' OR

                       e070~trkorr LIKE 'Y41%' OR
                       e070~trkorr LIKE 'Y42%' OR
                       e070~trkorr LIKE 'Y43%' OR
                       e070~trkorr LIKE 'Y44%' OR
                       e070~trkorr LIKE 'Y61%' OR
                       e070~trkorr LIKE 'Y62%' OR

                       e070~trkorr LIKE 'P37%' OR
                       e070~trkorr LIKE 'SE7%'
                     )
          ORDER BY e070~trkorr DESCENDING.

*    WRITE:/ l_trkorr, 23 l_as4text.

*  ENDSELECT.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM sod_matrix                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_SODVRSIO                                                    *
*  -->  P_MAXUS                                                       *
*---------------------------------------------------------------------*
FORM sod_matrix USING i_sodvrsio
                    TYPE /psyng/swsodvers-vrsio
                   p_maxus TYPE i
             CHANGING
               e_sod_per TYPE /psyng/sw_sod_performance_cal.
  DATA:lf_return TYPE bapireturn.
  DATA: usr_cnt TYPE i .
  DATA: BEGIN OF gt_usr_tab OCCURS 0,
          bname TYPE usr02-bname,
        END OF gt_usr_tab.

  DATA: lf_totusers   TYPE i,  "total users in USR02
        lf_maxuss     TYPE i,    "max users selected <= P_MAXUS
        lf_maxusa     TYPE i,    "max users actually analyzed
        lf_maxusac(4) TYPE c,   "max users actually analyzed in CHAR
        lf_splitter   TYPE i,  "splitter
        lf_counter    TYPE i,   "counter for splitter
        lf_batch_size TYPE i. "batch size for memory mode
  DATA: it_usr LIKE STANDARD TABLE OF /psyng/sw_sel_opts_xubname INITIAL
                                                SIZE 0 WITH HEADER LINE.
  DATA:it_usrlist LIKE STANDARD TABLE OF /psyng/sw_sel_opts_xubname
  INITIAL SIZE 0 WITH HEADER LINE..
 DATA: it_1stout LIKE STANDARD TABLE OF /psyng/sw_sod_output_org INITIAL
 SIZE 0 WITH HEADER LINE.
  REFRESH : gt_usr_tab.
  DATA: l_to_rcd   TYPE i,
        l_to_usr   TYPE i,
        l_all_rcd  TYPE i,
        l_str_time TYPE i,
        l_end_tm   TYPE i,
        l_tot_tm   TYPE i,
        l_lp_cnt   TYPE i.
  DATA: l_text1   TYPE string,
        l_text2   TYPE string,
        l_text3   TYPE string,
        l_usr_idx LIKE sy-tabix.

  SELECT COUNT( DISTINCT bname ) INTO lf_totusers FROM usr02.

  lf_maxuss = p_maxus.
  lf_splitter = lf_totusers / lf_maxuss.

  SELECT bname
         INTO gt_usr_tab-bname
         FROM usr02.

    lf_counter = lf_counter + 1.
    IF lf_counter = 1.
      APPEND gt_usr_tab.
    ENDIF.
*    Exception handeling when lf_totusers<lf_maxuss.
    CHECK lf_splitter NE 0.
************************************************
    lf_counter = lf_counter MOD lf_splitter .

  ENDSELECT.

  SORT gt_usr_tab.
  DELETE ADJACENT DUPLICATES FROM gt_usr_tab.
  DESCRIBE TABLE gt_usr_tab LINES lf_maxusa.
  MOVE lf_maxusa TO lf_maxusac.

  LOOP AT gt_usr_tab.
    it_usr-sign = 'I'.
    it_usr-option = 'EQ'.
    it_usr-low = gt_usr_tab-bname.
    APPEND it_usr.
  ENDLOOP.
  it_usrlist[] = it_usr[].


  GET RUN TIME FIELD l_str_time.

  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
    EXPORTING
      i_validuser  = ' '
      i_vrsio      = i_sodvrsio
    IMPORTING
      e_usercount  = usr_cnt
    TABLES
      it_users     = it_usrlist[]
      et_outputdet = it_1stout[].
  .

  GET RUN TIME FIELD l_end_tm.
  DESCRIBE TABLE it_1stout LINES l_to_rcd.

  l_text1 = l_to_rcd.
  l_text2 = usr_cnt.
  l_tot_tm = l_end_tm - l_str_time.
  CONCATENATE text-085 lf_maxusac text-100 l_text1 text-089 INTO l_text1
                                                                       .
  CONCATENATE l_text1 l_text2 text-086  INTO l_text1 SEPARATED BY space.
  PERFORM time_conversion CHANGING l_tot_tm l_text3.

  e_sod_per-no_drvd_text = l_text1.
  e_sod_per-no_drvd_performance =  l_text3.

  REFRESH : it_usrlist,it_1stout.
  CLEAR: lf_return,it_usr,it_usrlist,l_to_rcd,l_str_time,l_end_tm,
l_text1,l_text2,
        l_text3.
  it_usrlist[] = it_usr[].
  GET RUN TIME FIELD l_str_time.
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
    EXPORTING
      i_validuser  = ' '
      i_vrsio      = i_sodvrsio
    IMPORTING
      e_usercount  = usr_cnt
    TABLES
      it_users     = it_usrlist[]
      et_outputdet = it_1stout[].

  GET RUN TIME FIELD l_end_tm.
  DESCRIBE TABLE it_1stout LINES l_to_rcd.

  l_text1 = l_to_rcd.
  l_text2 = usr_cnt.
  l_tot_tm = l_end_tm - l_str_time.
  CONCATENATE text-085 lf_maxusac text-100 l_text1 text-089 INTO l_text1
                                                                       .
  CONCATENATE l_text1 l_text2 text-086  INTO l_text1 SEPARATED BY space.
  PERFORM time_conversion CHANGING l_tot_tm l_text3.
  e_sod_per-drvd_text = l_text1.
  e_sod_per-drvd_perfomance =  l_text3.

  lf_batch_size = lf_maxusa / 4.  "4 serial scans
  DATA : l_users_analyzed TYPE i.

  l_users_analyzed = lf_batch_size * 4.
  WHILE l_users_analyzed < lf_maxusa.
    ADD 1 TO lf_batch_size.
    l_users_analyzed = lf_batch_size * 4.
  ENDWHILE.

  REFRESH : it_usrlist,it_1stout.
  CLEAR: lf_return,it_usr,it_usrlist,l_to_rcd,l_str_time,l_end_tm,
l_text1,l_text2,
        l_text3.
  GET RUN TIME FIELD l_str_time.
  LOOP AT it_usr.
    l_usr_idx = sy-tabix.
    it_usrlist = it_usr.
    APPEND it_usrlist.
    l_lp_cnt = l_lp_cnt + 1.
    IF l_lp_cnt = lf_batch_size OR l_usr_idx = lf_maxusa.
      CLEAR l_lp_cnt.
      CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
        EXPORTING
          i_validuser  = ' '
          i_vrsio      = i_sodvrsio
        IMPORTING
          e_usercount  = usr_cnt
        TABLES
          it_users     = it_usrlist[]
          et_outputdet = it_1stout[].
      .

      DESCRIBE TABLE it_1stout LINES l_to_rcd.
      l_to_usr = l_to_usr + usr_cnt.
      l_all_rcd = l_all_rcd + l_to_rcd.
      REFRESH : it_1stout,it_usrlist.
      CLEAR : usr_cnt,l_to_rcd,l_lp_cnt,it_1stout.
    ENDIF.
  ENDLOOP.
  GET RUN TIME FIELD l_end_tm.

  l_text1 = l_all_rcd.
  l_text2 = l_to_usr.
  l_tot_tm = l_end_tm - l_str_time.
  CONCATENATE text-085 lf_maxusac text-091 l_text1 text-089 INTO l_text1
                                                                       .
  CONCATENATE l_text1 l_text2 text-086  INTO l_text1 SEPARATED BY space.
  PERFORM time_conversion CHANGING l_tot_tm l_text3.
  e_sod_per-no_drvd_mmry_text = l_text1.
  e_sod_per-no_drvd_mmry_mode =  l_text3.


  REFRESH : it_usrlist,it_1stout.
  CLEAR: lf_return,it_usr,it_usrlist,l_to_rcd,l_str_time,l_end_tm,
l_text1,l_text2,
        l_text3,l_to_usr,l_all_rcd, usr_cnt,l_to_rcd, l_lp_cnt.
  GET RUN TIME FIELD l_str_time.

  LOOP AT it_usr.
    l_usr_idx = sy-tabix.
    it_usrlist = it_usr.
    APPEND it_usrlist.
    l_lp_cnt = l_lp_cnt + 1.

    IF l_lp_cnt = lf_batch_size OR  l_usr_idx = lf_maxusa.
      CLEAR l_lp_cnt.
      CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
        EXPORTING
          i_validuser  = ' '
          i_vrsio      = i_sodvrsio
        IMPORTING
          e_usercount  = usr_cnt
        TABLES
          it_users     = it_usrlist[]
          et_outputdet = it_1stout[].

      DESCRIBE TABLE it_1stout LINES l_to_rcd.
      l_to_usr = l_to_usr + usr_cnt.
      l_all_rcd = l_all_rcd + l_to_rcd.
      REFRESH : it_1stout,it_usrlist.
      CLEAR : usr_cnt,l_to_rcd,l_lp_cnt,it_1stout.
    ENDIF.
  ENDLOOP.
  GET RUN TIME FIELD l_end_tm.

  l_text1 = l_all_rcd.
  l_text2 = l_to_usr.
  l_tot_tm = l_end_tm - l_str_time.
  CONCATENATE text-085 lf_maxusac text-091 l_text1 text-089 INTO l_text1
                                                                       .
  CONCATENATE l_text1 l_text2 text-086  INTO l_text1 SEPARATED BY space.
*  SKIP 2.
*  WRITE:/3 text-094 COLOR 2.
  PERFORM time_conversion CHANGING l_tot_tm l_text3.
*  WRITE:/3 l_text1,99 l_text3 COLOR 6.
  e_sod_per-drvd_mmry_text = l_text1.
  e_sod_per-drvd_mmry_mode = l_text3.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM time_conversion                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  MICOSEC                                                       *
*  -->  P_TEXT1                                                       *
*---------------------------------------------------------------------*
FORM time_conversion CHANGING micosec TYPE i
                              p_text1 TYPE string.
  DATA: l_v_sec  TYPE f,
        l_v_msec TYPE f,
        l_v_hrs  TYPE f,
        l_v_min  TYPE f.

  DATA: l_v_msec1 TYPE i,
        l_v_sec1  TYPE i,
        l_v_min1  TYPE i,
        l_v_hrs1  TYPE i.

  DATA :c_hr(2)  TYPE c,
        c_min(2) TYPE c,
        c_sec(2) TYPE c.


  l_v_sec = micosec / 1000000.
  l_v_msec = micosec MOD 1000000.

  l_v_min = l_v_sec MOD 3600.
  l_v_hrs = l_v_sec / 3600.

  IF l_v_min > 60.
    l_v_sec = l_v_min MOD 60.
    l_v_min = l_v_min / 60.
  ELSE.
    l_v_sec = l_v_min.
    l_v_min = 0.
  ENDIF.
  l_v_msec1 = trunc( l_v_msec ).
  l_v_sec1 = trunc( l_v_sec ).
  l_v_min1 = trunc( l_v_min ).
  l_v_hrs1 = trunc( l_v_hrs ).

  p_text1 = l_v_msec1.
  c_sec = l_v_sec1.
  c_min = l_v_min1.
  c_hr = l_v_hrs1.
  CONCATENATE  p_text1 text-075 INTO p_text1 SEPARATED BY space.
  IF NOT l_v_sec1 IS INITIAL.
    CONCATENATE  c_sec text-095 p_text1 INTO p_text1 SEPARATED BY
 space.
  ENDIF.
  IF NOT l_v_min1 IS INITIAL.
    CONCATENATE c_min text-096 p_text1 INTO p_text1 SEPARATED BY
space.
  ENDIF.
  IF NOT l_v_hrs1 IS INITIAL.
    CONCATENATE c_hr text-097 p_text1 INTO p_text1 SEPARATED BY
space.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  append_only
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM append_only.

  DATA:lt_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE.
  DATA:lt_function  TYPE TABLE OF /psyng/function WITH HEADER LINE.
  DATA:lt_conflict  TYPE TABLE OF /psyng/conflict WITH HEADER LINE.
  DATA:lt_swaudhdr  TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE.
  DATA:lt_cuscon    TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE.
  DATA:lt_criroles  TYPE TABLE OF /psyng/criroles WITH HEADER LINE.
  DATA:lt_criprof   TYPE TABLE OF /psyng/criprof WITH HEADER LINE,
       lt_confil    TYPE TABLE OF /psyng/sw_syscon WITH HEADER LINE,
       lt_funfil    TYPE TABLE OF /psyng/sw_sysfun WITH HEADER LINE,
       lt_tcodefil  TYPE TABLE OF /psyng/sw_systcd WITH HEADER LINE,
       lt_authfil   TYPE TABLE OF /psyng/sw_sysca  WITH HEADER LINE,
       lt_swsodorgo TYPE TABLE OF /psyng/swsodorgo WITH HEADER LINE,
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
       lt_mcuser    TYPE TABLE OF /psyng/mcuser   WITH HEADER LINE,
       lt_mcusrgrp  TYPE TABLE OF /psyng/mcusrgrp WITH HEADER LINE,
       lt_mcrole    TYPE TABLE OF /psyng/mcrole   WITH HEADER LINE,
       lt_mccarole  TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
       lt_mccauser  TYPE TABLE OF /psyng/mccauser WITH HEADER LINE.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion

  IF NOT gt_critcodes[] IS INITIAL.
    SELECT tcode FROM /psyng/critcodes
      INTO CORRESPONDING FIELDS OF TABLE lt_critcodes
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_critcodes.
        READ TABLE lt_critcodes WITH KEY tcode = gt_critcodes-tcode.
        IF sy-subrc EQ 0.
          DELETE gt_critcodes.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_function[] IS INITIAL.
    SELECT function FROM /psyng/function
    INTO CORRESPONDING FIELDS OF TABLE lt_function
    WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_function.
        READ TABLE lt_function
        WITH KEY function = gt_function-function.
        IF sy-subrc EQ 0.
          DELETE gt_function.
          DELETE gt_faobj WHERE funid EQ gt_function-function.
          DELETE gt_texts WHERE textname = gt_function-function AND
                                object   = 'F'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_conflict[] IS INITIAL.

    SELECT conid FROM /psyng/conflict
    INTO CORRESPONDING FIELDS OF TABLE lt_conflict
    WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_conflict.
        READ TABLE lt_conflict WITH KEY conid =  gt_conflict-conid.
        IF sy-subrc EQ 0.
          DELETE gt_conflict.
          DELETE gt_confdet WHERE conid EQ gt_conflict-conid.
          DELETE gt_conowner WHERE conid EQ gt_conflict-conid.
          DELETE gt_texts WHERE textname = gt_conflict-conid AND
                                object   = 'C'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_swaudhdr[] IS INITIAL.
    SELECT swaudid FROM /psyng/swaudhdr
    INTO CORRESPONDING FIELDS OF TABLE lt_swaudhdr
    WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_swaudhdr.
        READ TABLE lt_swaudhdr WITH KEY swaudid = gt_swaudhdr-swaudid.
        IF sy-subrc EQ 0.
          DELETE gt_swaudhdr.
          DELETE gt_swaudc WHERE swaudid = gt_swaudhdr-swaudid.
          DELETE gt_texts WHERE textname = gt_swaudhdr-swaudid AND
                                  object   = 'T'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_cuscon[] IS INITIAL.
    SELECT conid FROM  /psyng/sw_cuscon
    INTO CORRESPONDING FIELDS OF TABLE lt_cuscon
    WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_cuscon.
        READ TABLE lt_cuscon WITH KEY conid = gt_cuscon-conid.
        IF sy-subrc EQ 0.
          DELETE gt_cuscon.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_criroles[] IS INITIAL.
    SELECT agr_name FROM /psyng/criroles
     INTO CORRESPONDING FIELDS OF TABLE lt_criroles
        WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_criroles.
        READ TABLE lt_criroles WITH KEY agr_name = gt_criroles-agr_name.
        IF sy-subrc EQ 0.
          DELETE gt_criroles.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_criprof[] IS INITIAL.
    SELECT profile FROM /psyng/criprof
    INTO CORRESPONDING FIELDS OF TABLE lt_criprof
        WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_criprof.
        READ TABLE lt_criprof  WITH KEY profile = gt_criprof-profile.
        IF sy-subrc EQ 0.
          DELETE gt_criprof .
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_confil[] IS INITIAL.
    SELECT * FROM /psyng/sw_syscon
      INTO TABLE lt_confil
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_confil.
        READ TABLE lt_confil WITH KEY conid = gt_confil-conid
                                    application = gt_confil-application
                                      sign = gt_confil-sign
                                      type = gt_confil-type
                                      low  = gt_confil-low
                                      high = gt_confil-high.
        IF sy-subrc EQ 0.
          DELETE gt_confil.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_funfil[] IS INITIAL.
    SELECT * FROM /psyng/sw_sysfun
      INTO TABLE lt_funfil
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_funfil.
        READ TABLE lt_funfil WITH KEY function = gt_funfil-function
                                    application = gt_funfil-application
                                      sign = gt_funfil-sign
                                      type = gt_funfil-type
                                      low  = gt_funfil-low
                                      high = gt_funfil-high.

        IF sy-subrc EQ 0.
          DELETE gt_funfil.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_tcodefil[] IS INITIAL.
    SELECT * FROM /psyng/sw_systcd
      INTO TABLE lt_tcodefil
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_tcodefil.
        READ TABLE lt_tcodefil WITH KEY tcode = gt_tcodefil-tcode
                                        sign = gt_tcodefil-sign
                                        type = gt_tcodefil-type
                                        low = gt_tcodefil-low
                                        high = gt_tcodefil-high.
        IF sy-subrc EQ 0.
          DELETE gt_tcodefil.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_authfil[] IS INITIAL.
    SELECT * FROM /psyng/sw_sysca
      INTO TABLE lt_authfil
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_authfil.
        READ TABLE lt_authfil WITH KEY swaudid = gt_authfil-swaudid
                                   application = gt_authfil-application
                                      sign = gt_authfil-sign
                                      type = gt_authfil-type
                                      low  = gt_authfil-low
                                      high = gt_authfil-high.
        IF sy-subrc EQ 0.
          DELETE gt_authfil.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_swsodorgo[] IS INITIAL.
    SELECT * FROM /psyng/swsodorgo
      INTO TABLE lt_swsodorgo
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_swsodorgo.
        READ TABLE lt_swsodorgo WITH KEY conid = gt_swsodorgo-conid.
        IF sy-subrc EQ 0.
          DELETE gt_swsodorgo.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  IF NOT gt_mcuser[] IS INITIAL.
    SELECT * FROM /psyng/mcuser
      INTO CORRESPONDING FIELDS OF TABLE lt_mcuser
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_mcuser.
        READ TABLE lt_mcuser WITH KEY contid    = gt_mcuser-contid
                                      conid     = gt_mcuser-conid
                                      userid    = gt_mcuser-userid
                                      vrsio     = gt_mcuser-vrsio
                                      auditor   = gt_mcuser-auditor
                                      from_date = gt_mcuser-from_date
                                      to_date   = gt_mcuser-to_date
                                      approved  = gt_mcuser-approved
                                      org_abb   = gt_mcuser-org_abb.
        IF sy-subrc EQ 0.
          DELETE gt_mcuser.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_mcusrgrp[] IS INITIAL.
    SELECT * FROM /psyng/mcusrgrp
      INTO CORRESPONDING FIELDS OF TABLE lt_mcusrgrp
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_mcusrgrp.
        READ TABLE lt_mcusrgrp WITH KEY contid    = gt_mcusrgrp-contid
                                   conid       = gt_mcusrgrp-conid
                                   class       = gt_mcusrgrp-class
                                   vrsio       = gt_mcusrgrp-vrsio
                                   auditor     = gt_mcusrgrp-auditor
                                   from_date   = gt_mcusrgrp-from_date
                                   to_date     = gt_mcusrgrp-to_date
                                   approved    = gt_mcusrgrp-approved.
        IF sy-subrc EQ 0.
          DELETE gt_mcusrgrp.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_mcrole[] IS INITIAL.
    SELECT * FROM /psyng/mcrole
      INTO CORRESPONDING FIELDS OF TABLE lt_mcrole
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_mcrole.
        READ TABLE lt_mcrole WITH KEY contid      = gt_mcrole-contid
                                      conid       = gt_mcrole-conid
                                      agr_name    = gt_mcrole-agr_name
                                      vrsio       = gt_mcrole-vrsio
                                      auditor     = gt_mcrole-auditor
                                    from_date   = gt_mcrole-from_date
                                      to_date     = gt_mcrole-to_date
                                    approved     = gt_mcrole-approved.


        IF sy-subrc EQ 0.
          DELETE gt_mcrole.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_mccarole[] IS INITIAL.
    SELECT * FROM /psyng/mccarole
      INTO CORRESPONDING FIELDS OF TABLE lt_mccarole
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_mccarole.
        READ TABLE lt_mccarole WITH KEY contid = gt_mccarole-contid
                        swaudid = gt_mccarole-swaudid
                        agr_name = gt_mccarole-agr_name
                        vrsio       = gt_mccarole-vrsio
                        auditor     = gt_mccarole-auditor
                        from_date   = gt_mccarole-from_date
                        to_date     = gt_mccarole-to_date
                        approved     = gt_mccarole-approved.
        IF sy-subrc EQ 0.
          DELETE gt_mccarole.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_mccauser[] IS INITIAL.
    SELECT * FROM /psyng/mccauser
      INTO CORRESPONDING FIELDS OF TABLE lt_mccauser
     WHERE vrsio EQ g_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_mccauser.
        READ TABLE lt_mccauser WITH KEY contid = gt_mccauser-contid
                        swaudid   = gt_mccauser-swaudid
                        userid   = gt_mccauser-userid
                        vrsio       = gt_mccauser-vrsio
                        auditor     = gt_mccauser-auditor
                        from_date   = gt_mccauser-from_date
                        to_date     = gt_mccauser-to_date
                        approved     = gt_mccauser-approved.

        IF sy-subrc EQ 0.
          DELETE gt_mccauser.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion

ENDFORM.                    " append_only
*&---------------------------------------------------------------------*
*&      Form  authority_check
*&---------------------------------------------------------------------*
*-   Authority check for delete target in test mode
*----------------------------------------------------------------------*
*      -->P_I_VRSIO  text
*----------------------------------------------------------------------*
FORM authority_check
TABLES et_return         STRUCTURE bapiret2
USING i_vrsio            TYPE /psyng/sodvrsio
CHANGING ef_missing_auth TYPE flag.

  DATA: BEGIN OF lt_function OCCURS 0,
          funid TYPE /psyng/function-function,
        END OF lt_function.

  DATA: BEGIN OF lt_conflict OCCURS 0,
          conid TYPE /psyng/conflict-conid,
        END OF lt_conflict.
  DATA:lt_swaudhdr  TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
       lt_swaudc2   TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
       lt_sw_cuscon TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
       l_message_v1 TYPE symsgv.

  SELECT function INTO TABLE lt_function FROM /psyng/function
         WHERE vrsio     = i_vrsio.
*--Function IDs
  LOOP AT lt_function.
    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
             ID 'ACTVT'      FIELD '06'
             ID 'Y&SW_VRSIO' FIELD i_vrsio
             ID 'Y&SW_FUNCT' FIELD lt_function-funid.
    IF sy-subrc NE 0.
      ef_missing_auth = 'X'.
      APPEND lt_function TO gt_test_function.
      l_message_v1 = lt_function-funid.
      et_return-message =
      'Missing authorization to delete Function'(e06).
      PERFORM fill_log
       TABLES et_return
        USING 'W' et_return-message
              text-o02 l_message_v1 '' ''.
    ENDIF.
  ENDLOOP.

* Conflict IDs
  SELECT conid INTO TABLE lt_conflict FROM /psyng/conflict
         WHERE vrsio  = i_vrsio.
  LOOP AT lt_conflict.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
    ID 'ACTVT'      FIELD '06'
    ID 'Y&SW_VRSIO' FIELD i_vrsio
    ID 'Y&SW_CONID' FIELD lt_conflict-conid.
    IF sy-subrc NE 0.
      ef_missing_auth = 'X'.
      APPEND lt_conflict TO gt_test_conflict.
      l_message_v1 = lt_conflict-conid.
      et_return-message =
   'Missing authorization to delete Conflict'(e07).
      PERFORM fill_log
       TABLES et_return
        USING 'W' et_return-message
              text-o03 l_message_v1 '' ''.
    ENDIF.
  ENDLOOP.

* Critical authorization header
  SELECT * FROM /psyng/swaudhdr INTO TABLE lt_swaudhdr
  WHERE vrsio    = i_vrsio.
  IF sy-subrc EQ 0.
    LOOP AT lt_swaudhdr.
      AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                 ID 'ACTVT' FIELD '06'
                 ID 'Y&SW_AUTID' FIELD lt_swaudhdr-swaudid
                 ID 'Y&SW_VRSIO' FIELD i_vrsio.
      IF sy-subrc NE 0.
        ef_missing_auth = 'X'.
        APPEND lt_swaudhdr TO gt_test_swaudhdr.
        l_message_v1 = lt_swaudhdr-swaudid.
        et_return-message =
     'Missing authorization to delete Critical Authorization'(e08).
        PERFORM fill_log
         TABLES et_return
          USING 'W' et_return-message
          text-o04 l_message_v1 '' ''.
      ENDIF.
    ENDLOOP.
  ENDIF.

***Custom Conflicts
  SELECT * FROM /psyng/sw_cuscon INTO TABLE lt_sw_cuscon
  WHERE vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    LOOP AT lt_sw_cuscon.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                 ID 'ACTVT' FIELD '06'
                 ID 'Y&SW_CONID' FIELD lt_sw_cuscon-conid
                 ID 'Y&SW_VRSIO' FIELD i_vrsio.
      IF sy-subrc NE 0.
        ef_missing_auth = 'X'.
        APPEND lt_sw_cuscon TO gt_test_sw_cuscon.
        l_message_v1 = lt_sw_cuscon-conid.
        et_return-message =
      'Missing authorization to delete Custom Conflict'(e09).
        PERFORM fill_log
         TABLES et_return
          USING 'W' et_return-message
          text-o05 l_message_v1 '' ''.
      ENDIF.
    ENDLOOP.
  ENDIF.

* Critical TCodes
  SELECT SINGLE vrsio FROM /psyng/critcodes INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
               ID 'ACTVT' FIELD '06'
               ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc NE 0.
      ef_missing_auth = 'X'.
      et_return-message =
   'Missing authorization to delete Critical Transactions'(e05).
      PERFORM fill_log
       TABLES et_return
        USING 'W' et_return-message
              '' '' '' ''.
      SELECT * FROM /psyng/critcodes INTO TABLE gt_test_critcodes.
    ENDIF.
  ENDIF.
* Critical roles
  SELECT SINGLE vrsio FROM /psyng/criroles INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
           ID 'ACTVT' FIELD '06'
           ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc NE 0.
      ef_missing_auth = 'X'.
      et_return-message =
      'Missing authorization to delete Critical Roles '(e10).
      PERFORM fill_log
       TABLES et_return
        USING 'W' et_return-message
              '' '' '' ''.
      SELECT * FROM /psyng/criroles INTO TABLE gt_test_criroles.
    ENDIF.
  ENDIF.

* Critical profiles
  SELECT SINGLE vrsio FROM /psyng/criprof INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
          ID 'ACTVT' FIELD '06'
          ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc NE 0.
      ef_missing_auth = 'X'.
      et_return-message =
        'Missing authorization to delete Critical Profiles'(e11).
      PERFORM fill_log
       TABLES et_return
        USING 'W' et_return-message
              '' '' '' ''.
      SELECT * FROM /psyng/criprof INTO TABLE gt_test_criprof.
    ENDIF.
  ENDIF.

  FREE: lt_function, lt_conflict,lt_swaudhdr,
        lt_swaudc2 ,lt_sw_cuscon.


ENDFORM.                    " authority_check
*&---------------------------------------------------------------------
*
*&      Form  append_only_test
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------
*
FORM append_only_test.

  IF NOT gt_critcodes[] IS INITIAL.
    IF NOT gt_test_critcodes[] IS INITIAL.
      LOOP AT gt_critcodes.
       READ TABLE gt_test_critcodes WITH KEY tcode = gt_critcodes-tcode.
        IF sy-subrc EQ 0.
          DELETE gt_critcodes.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_function[] IS INITIAL.
    IF NOT gt_test_function[] IS INITIAL.
      LOOP AT gt_function.
        READ TABLE gt_test_function
        WITH KEY funid = gt_function-function.
        IF sy-subrc EQ 0.
          DELETE gt_function.
          DELETE gt_faobj WHERE funid EQ gt_function-function.
          DELETE gt_texts WHERE textname = gt_function-function AND
                                object   = 'F'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_conflict[] IS INITIAL.
    IF NOT gt_test_conflict[] IS INITIAL.
      LOOP AT gt_conflict.
        READ TABLE gt_test_conflict WITH KEY conid =  gt_conflict-conid.
        IF sy-subrc EQ 0.
          DELETE gt_conflict.
          DELETE gt_confdet WHERE conid EQ gt_conflict-conid.
          DELETE gt_conowner WHERE conid EQ gt_conflict-conid.
          DELETE gt_texts WHERE textname = gt_conflict-conid AND
                                object   = 'C'.

        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_swaudhdr[] IS INITIAL.
    IF NOT gt_test_swaudhdr[] IS INITIAL.
      LOOP AT gt_swaudhdr.
        READ TABLE gt_test_swaudhdr
        WITH KEY swaudid = gt_swaudhdr-swaudid.
        IF sy-subrc EQ 0.
          DELETE gt_swaudhdr.
          DELETE gt_swaudc WHERE swaudid = gt_swaudhdr-swaudid.
          DELETE gt_texts WHERE textname = gt_swaudhdr-swaudid AND
                                  object   = 'T'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_cuscon[] IS INITIAL.
    IF NOT gt_test_sw_cuscon[] IS INITIAL.
      LOOP AT gt_cuscon.
        READ TABLE gt_test_sw_cuscon WITH KEY conid = gt_cuscon-conid.
        IF sy-subrc EQ 0.
          DELETE gt_cuscon.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_criroles[] IS INITIAL.
    IF NOT gt_test_criroles[] IS INITIAL.
      LOOP AT gt_criroles.
        READ TABLE gt_test_criroles
        WITH KEY agr_name = gt_criroles-agr_name.
        IF sy-subrc EQ 0.
          DELETE gt_criroles.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_criprof[] IS INITIAL.
    IF NOT gt_test_criprof[] IS INITIAL.
      LOOP AT gt_criroles.
      READ TABLE gt_test_criprof  WITH KEY profile = gt_criprof-profile.
        IF sy-subrc EQ 0.
          DELETE gt_criroles .
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  REFRESH:gt_test_function,
          gt_test_conflict,
          gt_test_swaudhdr,
          gt_test_sw_cuscon,
          gt_test_critcodes,
          gt_test_criroles,
          gt_test_criprof.
ENDFORM.                    " append_only_test
*&---------------------------------------------------------------------*
*&      Form  fill_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_RETURN  text
*      -->P_0360   text
*      -->P_ET_RETURN_MESSAGE  text
*      -->P_0362   text
*      -->P_0363   text
*      -->P_0364   text
*      -->P_0365   text
*----------------------------------------------------------------------*
FORM fill_log
TABLES et_return STRUCTURE bapiret2
USING  i_type    TYPE      bapi_mtype
       i_message TYPE      bapi_msg
       i_msgv1   TYPE      symsgv
       i_msgv2   TYPE      symsgv
       i_msgv3   TYPE      symsgv
       i_msgv4   TYPE      symsgv.

  et_return-type       = i_type.
  et_return-message    = i_message.
  et_return-message_v1 = i_msgv1.
  et_return-message_v2 = i_msgv2.
  et_return-message_v3 = i_msgv3.
  et_return-message_v4 = i_msgv4.
  APPEND et_return.

ENDFORM.                    " fill_log
*&---------------------------------------------------------------------*
*&      Form  db_changes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_VE_RULES  text
*      -->P_ET_RETURN  text
*      -->P_IT_VE_RULE_VER  text
*      -->P_IF_DELETE  text
*      -->P_IF_TEST  text
*----------------------------------------------------------------------*
FORM db_changes
TABLES it_ve_rules     STRUCTURE /psyng/sw_varel
       et_return       STRUCTURE bapiret2
USING  is_ve_rule_ver  TYPE /psyng/sw_varvr
       if_delete       TYPE flag
       if_test         TYPE flag.

  DATA: l_message_v1   TYPE symsgv,
        l_message_v2   TYPE symsgv,
        lt_ve_rules    TYPE TABLE OF /psyng/sw_varel,
        ls_ve_rules    TYPE /psyng/sw_varel,
        ls_ve_rule_ver TYPE /psyng/sw_varvr.

  IF if_delete EQ 'X'.
*-- Delete variable element rules
    IF NOT it_ve_rules[] IS INITIAL.
      READ TABLE it_ve_rules INDEX 1.
      SELECT *
        FROM /psyng/sw_varel
        INTO TABLE lt_ve_rules
       WHERE varel_vrsio EQ it_ve_rules-varel_vrsio.
      IF sy-subrc EQ 0.
        SORT lt_ve_rules BY varel_vrsio var_element.
        DELETE ADJACENT DUPLICATES FROM lt_ve_rules
        COMPARING varel_vrsio var_element.
      ENDIF.
      IF if_test IS INITIAL.
        DELETE FROM /psyng/sw_varel
        WHERE varel_vrsio = it_ve_rules-varel_vrsio.
        COMMIT WORK.
      ENDIF.
      IF sy-subrc EQ 0
      OR if_test  EQ 'X'.
        MOVE 'Variable element rules deleted successfully'(s19)
        TO et_return-message.
        l_message_v1 = it_ve_rules-varel_vrsio.
        LOOP AT lt_ve_rules INTO ls_ve_rules.
          l_message_v2 = ls_ve_rules-var_element.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o06 l_message_v1 text-o07 l_message_v2.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.

*--Modify variable version header
  IF NOT is_ve_rule_ver IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/sw_varvr FROM is_ve_rule_ver.
      COMMIT WORK.
    ENDIF.
    IF sy-subrc EQ 0
    OR if_test  EQ 'X'.
      MOVE 'Variable element rules header modified successfully'(s20)
      TO et_return-message.
      l_message_v1 = is_ve_rule_ver-varel_vrsio.
      PERFORM fill_log
       TABLES et_return
        USING 'S' et_return-message
              text-o06 l_message_v1 '' ''.
    ENDIF.
  ELSE.
    READ TABLE it_ve_rules INDEX 1.
    SELECT SINGLE *
      FROM /psyng/sw_varvr
      INTO ls_ve_rule_ver
     WHERE varel_vrsio EQ it_ve_rules-varel_vrsio.
    IF sy-subrc NE 0.
*--IF version header from source is not fetched and VE rule version
*--not exist in target system; raise an error message
      MOVE text-e23
      TO et_return-message.
      l_message_v1 = it_ve_rules-varel_vrsio.
      PERFORM fill_log
       TABLES et_return
        USING 'E' et_return-message
              text-o06 l_message_v1 '' ''.
*      IF if_test IS INITIAL.
      EXIT.
*      ENDIF.
    ENDIF.
  ENDIF.
*-- Modify variable element rules
  IF NOT it_ve_rules[] IS INITIAL.
    READ TABLE it_ve_rules INDEX 1.
    IF if_test IS INITIAL.
      MODIFY /psyng/sw_varel FROM TABLE it_ve_rules.
      COMMIT WORK.
    ENDIF.
    IF sy-subrc EQ 0
    OR if_test  EQ 'X'.
      IF if_delete IS INITIAL.
        MOVE 'Variable element rules modified successfully'(s22)
        TO et_return-message.
      ELSE.
        MOVE 'Variable element rules added successfully'(s21)
        TO et_return-message.
      ENDIF.
      l_message_v1 = it_ve_rules-varel_vrsio.
      lt_ve_rules = it_ve_rules[].
      SORT lt_ve_rules BY varel_vrsio var_element.
      DELETE ADJACENT DUPLICATES FROM lt_ve_rules
      COMPARING varel_vrsio var_element.
      LOOP AT lt_ve_rules INTO ls_ve_rules.
        l_message_v2 = ls_ve_rules-var_element.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o06 l_message_v1 text-o07 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFORM.                    " db_changes
*&---------------------------------------------------------------------*
*&      Form  db_changes_config_set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_VAREL  text
*      -->P_LT_SYSTEMS  text
*      -->P_LT_ORG  text
*      -->P_LT_ELEMENTS  text
*      -->P_ET_RETURN  text
*      -->P_IT_CONFIG_HEADER  text
*      -->P_IF_DELETE  text
*      -->P_IF_TEST  text
*----------------------------------------------------------------------*
FORM db_changes_config_set
TABLES it_varel         STRUCTURE /psyng/swcfgve
       it_systems       STRUCTURE /psyng/swcfgsys
       it_org           STRUCTURE /psyng/swcfgoe
       it_elements      STRUCTURE /psyng/swcfsel
       et_return        STRUCTURE bapiret2
USING  it_config_header TYPE /psyng/swcfgset
       if_delete        TYPE flag
       if_test          TYPE flag.

  DATA:
    l_message_v1   TYPE symsgv,
    l_message_v2   TYPE symsgv,
    lt_varel       TYPE TABLE OF /psyng/swcfgve,
    lt_systems     TYPE TABLE OF /psyng/swcfgsys,
    lt_org         TYPE TABLE OF /psyng/swcfgoe,
    lt_elements    TYPE TABLE OF /psyng/swcfsel,
    ls_varel       TYPE /psyng/swcfgve,
    ls_systems     TYPE /psyng/swcfgsys,
    ls_org         TYPE /psyng/swcfgoe,
    ls_elements    TYPE /psyng/swcfsel,
    ls_sod_version TYPE /psyng/swsodvers,
    l_old_set_id   TYPE /psyng/seconfid,
    ls_cfgid       TYPE /psyng/swcfgid.
* BOC by RGUPTA on 07.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  it_config_header-create_user = l_current_user. "C0700
  it_config_header-create_date = sy-datum.
  it_config_header-create_time = sy-uzeit.
  CLEAR: it_config_header-change_user,
         it_config_header-change_date,
         it_config_header-change_time.
  IF if_test IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_CFG_GET_NEW_SETID'
      IMPORTING
        setid = g_set_id.
  ELSE.
    IF g_set_id IS INITIAL.
      SELECT SINGLE * FROM /psyng/swcfgid INTO ls_cfgid.
      g_set_id = ls_cfgid-setid.
    ENDIF.
    ADD 1 TO g_set_id.
  ENDIF.
  ls_varel-setid = g_set_id.
  MODIFY it_varel FROM ls_varel TRANSPORTING setid
  WHERE setid = it_config_header-setid.
  ls_systems-setid = g_set_id.
  MODIFY it_systems[] FROM ls_systems TRANSPORTING setid
  WHERE setid = it_config_header-setid.
  ls_org-setid = g_set_id.
  MODIFY it_org[] FROM ls_org TRANSPORTING setid
  WHERE setid = it_config_header-setid.
  ls_elements-setid = g_set_id.
  MODIFY it_elements[] FROM ls_elements TRANSPORTING setid
  WHERE setid = it_config_header-setid.
  l_old_set_id = it_config_header-setid.
  it_config_header-setid = g_set_id.
*--Check if SOD Version used in configuration set exist in target system
  SELECT SINGLE * FROM /psyng/swsodvers
    INTO ls_sod_version
   WHERE vrsio EQ it_config_header-sodvrsio.
  IF sy-subrc NE 0.
    MOVE
 'SOD version used in config. set do not exist in target system'(e22)
    TO et_return-message.
    l_message_v1 = it_config_header-sodvrsio.
    PERFORM fill_log
     TABLES et_return
      USING 'E' et_return-message
            text-o15 l_message_v1 '' ''.
*    IF if_test = 'X'.
    EXIT.
*    ENDIF.
  ENDIF.

  IF if_test IS INITIAL.
    MODIFY /psyng/swcfgset FROM it_config_header.
    COMMIT WORK.
  ENDIF.
  IF sy-dbcnt GT 0
  OR if_test  EQ 'X'.
    MOVE
'Source config. set &1 moved to target with new config. set &2'(s56)
      TO et_return-message.
    REPLACE '&1' INTO et_return-message WITH l_old_set_id.
    REPLACE '&2' INTO et_return-message WITH g_set_id.
    PERFORM fill_log
     TABLES et_return
      USING 'S' et_return-message
            '' '' '' ''.
    MOVE 'Configuration Set Header added successfully'(s34)
    TO et_return-message.
    l_message_v1 = it_config_header-setid.
    PERFORM fill_log
     TABLES et_return
      USING 'S' et_return-message
            text-o10 l_message_v1 '' ''.
  ENDIF.

*-- Modify Configuration Set - Systems
  IF NOT it_systems[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/swcfgsys FROM TABLE it_systems.
      COMMIT WORK.
    ENDIF.
    IF sy-subrc EQ 0
    OR if_test  EQ 'X'.
      MOVE 'Configuration Set Systems added successfully'(s38)
      TO et_return-message.
      l_message_v1 = it_config_header-setid.
      lt_systems = it_systems[].
      LOOP AT lt_systems INTO ls_systems.
        l_message_v2 = ls_systems-sysid.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o10 l_message_v1 text-o12 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

*-- Modify variable element values
  IF NOT it_varel[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/swcfgve FROM TABLE it_varel.
      COMMIT WORK.
    ENDIF.
    IF sy-subrc EQ 0
    OR if_test  EQ 'X'.
      MOVE 'Variable element values added successfully'(s36)
      TO et_return-message.
      l_message_v1 = it_config_header-setid.
      lt_varel = it_varel[].
      SORT lt_varel BY setid var_element sysid value.
      DELETE ADJACENT DUPLICATES FROM lt_varel
      COMPARING setid var_element sysid value.
      LOOP AT lt_varel INTO ls_varel.
        CLEAR l_message_v2.
        CONCATENATE ls_varel-var_element ls_varel-sysid ls_varel-value
             INTO l_message_v2 SEPARATED BY ' / '.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o10 l_message_v1 text-o11 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

*-- Modify org element values
  IF NOT it_org[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/swcfgoe FROM TABLE it_org.
      COMMIT WORK.
    ENDIF.
    IF sy-subrc EQ 0
    OR if_test  EQ 'X'.
      MOVE 'Org element values added successfully'(s40)
      TO et_return-message.
      l_message_v1 = it_config_header-setid.
      lt_org = it_org[].
      SORT lt_org BY setid abb varbl sysid value.
      DELETE ADJACENT DUPLICATES FROM lt_org
      COMPARING setid abb varbl sysid value.
      LOOP AT lt_org INTO ls_org.
        CLEAR l_message_v2.
        CONCATENATE ls_org-abb ls_org-varbl ls_org-sysid ls_org-value
        INTO l_message_v2 SEPARATED BY ' / '.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o10 l_message_v1 text-o13 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

*-- Modify  element selection table
  IF NOT it_elements[] IS INITIAL.
    IF if_test IS INITIAL.
      MODIFY /psyng/swcfsel FROM TABLE it_elements.
      COMMIT WORK.
    ENDIF.
    IF sy-subrc EQ 0
    OR if_test  EQ 'X'.
      MOVE 'Element Selection added successfully'(s42)
      TO et_return-message.
      l_message_v1 = it_config_header-setid.
      lt_elements = it_elements[].
      SORT lt_elements BY setid type varbl.
      DELETE ADJACENT DUPLICATES FROM lt_elements
      COMPARING setid type varbl.
      LOOP AT lt_elements INTO ls_elements.
        CLEAR l_message_v2.
        CONCATENATE ls_elements-type ls_elements-varbl ls_elements-sel
             INTO l_message_v2 SEPARATED BY ' / '.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o10 l_message_v1 text-o14 l_message_v2.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFORM.                    " db_changes_config_set
*&---------------------------------------------------------------------*
*&      Form  CHECK_TEXT_EXISTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_CONFIG_VALUE  text
*      <--P_LF_EXISTS  text
*----------------------------------------------------------------------*
FORM check_text_exists  USING    i_config_value
                        CHANGING ef_exists.

  DATA : l_cnt TYPE i.
  SELECT COUNT(*) FROM stxh
         INTO l_cnt
         WHERE tdname   = i_config_value
           AND tdid     = 'ST'
           AND tdobject = 'TEXT'.
  IF l_cnt > 0.
    ef_exists = 'X'.
  ELSE.
    CLEAR ef_exists.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHECK_DOCUMENT_EXISTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_CONFIG_VALUE  text
*      <--P_LF_EXISTS  text
*----------------------------------------------------------------------*
FORM check_document_exists  USING    i_config_value
                            CHANGING ef_exists.
  DATA : l_cnt TYPE i.
  SELECT COUNT(*) FROM dokhl
         INTO l_cnt
         WHERE id = 'TX'
           AND object   = i_config_value.
  IF l_cnt > 0.
    ef_exists = 'X'.
  ELSE.
    CLEAR ef_exists.
  ENDIF.
ENDFORM.
