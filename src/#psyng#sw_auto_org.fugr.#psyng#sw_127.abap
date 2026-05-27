FUNCTION /PSYNG/SW_127.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_SUMMARY) TYPE  FLAG OPTIONAL
*"     REFERENCE(IT_SWSODORGM) TYPE  /PSYNG/SW_TAB_SYS_AO OPTIONAL
*"     VALUE(I_SODVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(I_CFGSET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IS_OUTPUTDET) TYPE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"  EXPORTING
*"     VALUE(EF_VALID) TYPE  FLAG
*"  TABLES
*"      IT_RFCDES STRUCTURE  RFCDES OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_OUTPUTDET STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_INVALID STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      IT_ADVANCED_ROLE_SIMU STRUCTURE  AGR_1251 OPTIONAL
*"      IT_SIMU_ROLE_REMOVAL STRUCTURE  /PSYNG/SW_ROLE_REMOVAL_SIMU
*"       OPTIONAL
*"      IT_SIMUROLE_AUTH STRUCTURE  /PSYNG/ROLEAUTH OPTIONAL
*"      IT_SIMUROLE_TCODE STRUCTURE  /PSYNG/ROLETCODE OPTIONAL
*"----------------------------------------------------------------------
  DATA :
    lt_orgm        TYPE TABLE OF /psyng/swsodorgm,
    lt_sum_role    TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
    lt_confdet     TYPE TABLE OF /psyng/confdet  WITH HEADER LINE,
    lt_functtran   TYPE TABLE OF /psyng/functtran  WITH HEADER LINE,
    lt_faobj       TYPE TABLE OF /psyng/faobj2  WITH HEADER LINE,
    lt_simu_roleauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
    lt_simu_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
    lt_faobj_system  TYPE /psyng/sw_tab_sys_faobj,
    l_numfun       TYPE i,
    l_rewrite_type TYPE string,
    l_fp_cnt       TYPE i,
    lf_custom      TYPE flag,
    l_field        TYPE xufield,
    lf_check_done  TYPE flag,
    l_numfun_usr   type i,
    BEGIN OF lt_cnt OCCURS 0,
      abb          TYPE string,
      cnt          TYPE i,
    END OF lt_cnt,
    l_cnt_star    type i,
    l_agr_name    type agr_name.
  RANGES :
    lr_agr_name   FOR l_agr_name,
    lr_bname      for sy-uname.

  STATICS :
    lf_active         TYPE flag,
    lf_status_checked TYPE flag,
    st_config         TYPE SORTED TABLE OF /psyng/swsodorgo
                      WITH HEADER LINE WITH NON-UNIQUE KEY vrsio conid.

  ef_valid = 'X'.
  REFRESH : et_invalid.

*--Only do anything if this analysis has org check enabled
  CHECK i_org_check = 'X'.

*--Prepare user range for fake user
  lr_bname-sign   = 'I'.
  lr_bname-option = 'EQ'.
  lr_bname-low    = '000000000000'.
  append lr_bname.
*--Check if the Org Level Override functionality is enabled
  IF lf_status_checked IS INITIAL.
    se_config_param 'ORG_LVL_OVERRIDE' lf_active.
    IF lf_active = 'Y'.
      lf_active = 'X'.
    ENDIF.
    SELECT * FROM /psyng/swsodorgo INTO TABLE st_config
    ORDER BY vrsio conid.
    lf_status_checked = 'X'.
  ENDIF.



  IF lf_active <> 'X'.
*--Override functionality is disabled, exit now.
  ELSE.
    READ TABLE st_config WITH TABLE KEY
      vrsio = i_sodvrsio
      conid = is_outputdet-conid.
    IF sy-subrc = 0.
      lf_custom      = 'X'.
    ENDIF.
    IF lf_custom = 'X'.
      LOOP AT st_config WHERE vrsio = i_sodvrsio AND
                              conid = is_outputdet-conid.
        l_field        = st_config-field.
        l_rewrite_type = st_config-type.
        lf_check_done  = 'X'.

*    --This FM only supports records for the same conflict
        REFRESH : lr_agr_name.
        IF NOT it_outputdet[] IS INITIAL.
          LOOP AT it_outputdet.
            READ TABLE et_invalid WITH KEY
                agr_name = it_outputdet-agr_name
                conid    = it_outputdet-conid
.
            IF sy-subrc <> 0.
              IF is_outputdet-conid IS INITIAL.
                is_outputdet-conid = it_outputdet-conid.
              ENDIF.
              IF it_outputdet-conid <> is_outputdet-conid.
                MESSAGE e002(/psyng/sw) WITH
            'Custom Org Logic can only be called for a single conflict'.
              ENDIF.
              lr_agr_name-sign   = 'I'.
              lr_agr_name-option = 'EQ'.
              lr_agr_name-low    = it_outputdet-agr_name.
              APPEND lr_agr_name.
            ENDIF.
          ENDLOOP.
        ELSE.
          lr_agr_name-sign   = 'I'.
          lr_agr_name-option = 'EQ'.
          lr_agr_name-low    = is_outputdet-agr_name.
          APPEND lr_agr_name.
        ENDIF.
        IF NOT lr_agr_name[] IS INITIAL.
          MESSAGE s113(/psyng/sw) WITH
        'Applying Custom Org Logic'
              is_outputdet-agr_name
              is_outputdet-conid
              l_rewrite_type.

*--This conflict should be re-checked by custom Org Logic
          PERFORM sw125_filter_matrix
            TABLES
              it_confdet
              it_functtran
              it_faobj
              lt_confdet
              lt_functtran
              lt_faobj
            USING
              is_outputdet-conid
              i_sodvrsio
              if_summary
              l_rewrite_type
              l_field.
*--Determine nr of functions in conflict
          DESCRIBE TABLE lt_functtran LINES l_numfun.

          LOOP AT it_rfcdes.
            PERFORM sw125_rewrite_orgs
            TABLES
              lt_orgm
              lt_faobj
            USING
              it_rfcdes
              it_swsodorgm[]
              l_rewrite_type
              l_field
              i_sodvrsio
              i_cfgset
              is_outputdet-conid
              .
            refresh :
            lt_sum_role,
            lt_simu_roleauth,
            lt_simu_roletcode.
*--Load the role content
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
             EXPORTING
                  agr_name       = lr_agr_name-low
                  bname          = '000000000000'
*                  i_enhanced     = 'X'
             TABLES
                  roleauth       = lt_simu_roleauth
                  roletcode      = lt_simu_roletcode
                  functtran      = lt_functtran
                  faobj          = lt_faobj
             EXCEPTIONS
                  role_not_found = 1
                  OTHERS         = 2. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
             loop at IT_SIMUROLE_AUTH.
               move-corresponding IT_SIMUROLE_AUTH to lt_simu_roleauth.
               lt_simu_roleauth-bname = '000000000000'.
               append lt_simu_roleauth.
             endloop.
             loop at it_simurole_tcode.
              move-corresponding it_simurole_tcode to lt_simu_roletcode.
              lt_simu_roletcode-bname = '000000000000'.
              append it_simurole_tcode.
             endloop.
*--if an advanced simulation is being done, replace the IT_SIMU_ADD_ROLEAUTH records that are also in the
*  advanced simulation
            if not IT_ADVANCED_ROLE_SIMU[] is initial ."and not lT_SIMU_ROLEAUTH[] is initial .
              sort IT_ADVANCED_ROLE_SIMU by auth.
              loop at IT_ADVANCED_ROLE_SIMU.
                at new auth.
                  delete lT_SIMU_ROLEAUTH where auth = IT_ADVANCED_ROLE_SIMU-auth.
                endat.
              endloop.
              loop at IT_ADVANCED_ROLE_SIMU.
                move-corresponding  IT_ADVANCED_ROLE_SIMU to lT_SIMU_ROLEAUTH.
                lT_SIMU_ROLEAUTH-rfcdest = it_rfcdes-rfcoptions.
                lT_SIMU_ROLEAUTH-objct = IT_ADVANCED_ROLE_SIMU-object.
                lT_SIMU_ROLEAUTH-von   = IT_ADVANCED_ROLE_SIMU-low.
                lT_SIMU_ROLEAUTH-bis   = IT_ADVANCED_ROLE_SIMU-high.
                append lT_SIMU_ROLEAUTH.
              endloop.
              sort lT_SIMU_ROLEAUTH.
            endif.

*--SOD Analysis
            CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
                     EXPORTING
                          i_org_check  = 'X'
                     TABLES
                          it_users     = lr_bname
                          it_confdet   = lt_confdet
                          it_functtran = lt_functtran
                          it_faobj     = lt_faobj
                          it_swsodorgm = lt_orgm
                          et_output    = lt_sum_role
                          IT_SIMU_ADD_ROLETCODE = lt_simu_roletcode
                          IT_SIMU_ADD_ROLEAUTH  = lt_simu_roleauth
                          IT_SIMU_ROLE_REMOVAL  = IT_SIMU_ROLE_REMOVAL
                          IT_ADVANCED_ROLE_SIMU	= IT_ADVANCED_ROLE_SIMU.
            SORT lt_sum_role BY funid org_abb.
            DELETE ADJACENT DUPLICATES FROM lt_sum_role
                   COMPARING funid org_abb.
            clear l_cnt_star.
             refresh lt_cnt[].
            LOOP AT lt_sum_role.
              lt_cnt-abb = lt_sum_role-org_abb.
              lt_cnt-cnt = 1.
              COLLECT lt_cnt.
              if lt_cnt-abb = '*'.
*--count the functions for which user isn't restricted by orgs
                add 1 to l_cnt_star.
              endif.
            ENDLOOP.
            l_numfun_usr = l_numfun.
            if l_cnt_star > 0.
              subtract l_cnt_star from l_numfun_usr.
*             the * results arent relevant, and shouldn't affect results
              delete lt_cnt where abb = '*'.
            endif.
            SORT lt_cnt BY cnt .
            READ TABLE lt_cnt WITH KEY cnt = l_numfun_usr
            BINARY SEARCH TRANSPORTING NO FIELDS.
            IF sy-subrc <> 0.
*  --According to the modified org structure,
*    the user doesn't have the conflict
              IF it_outputdet[] IS INITIAL.
                CLEAR ef_valid.
              ELSE.
                et_invalid-agr_name = lr_agr_name-low.
                et_invalid-conid    = is_outputdet-conid.
                APPEND et_invalid.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.
        SORT et_invalid BY agr_name conid.
      ENDLOOP.
    ENDIF.
  ENDIF.
  IF lf_check_done = 'X'.
    DESCRIBE TABLE et_invalid LINES l_fp_cnt.
    MESSAGE s113(/psyng/sw) WITH
      'Custom Org Logic - False Positives Identified :'
      is_outputdet-conid ' - ' l_fp_cnt .
  ENDIF.
ENDFUNCTION.
