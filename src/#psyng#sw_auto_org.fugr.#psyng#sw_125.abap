FUNCTION /psyng/sw_125.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IS_OUTPUTDET) TYPE  /PSYNG/SW_SOD_OUTPUT_ORG OPTIONAL
*"     VALUE(IF_SUMMARY) TYPE  FLAG OPTIONAL
*"     REFERENCE(IT_SWSODORGM) TYPE  /PSYNG/SW_TAB_SYS_AO OPTIONAL
*"     VALUE(I_SODVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(I_CFGSET) TYPE  /PSYNG/SECONFID OPTIONAL
*"  EXPORTING
*"     VALUE(EF_VALID) TYPE  FLAG
*"  TABLES
*"      IT_RFCDES STRUCTURE  RFCDES OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_OUTPUTDET STRUCTURE  /PSYNG/SW_SOD_OUTPUT_ORG OPTIONAL
*"      ET_INVALID STRUCTURE  /PSYNG/SW_SOD_OUTPUT_ORG OPTIONAL
*"      IT_SIMU_ROLE_REMOVAL STRUCTURE  /PSYNG/SW_ROLE_REMOVAL_SIMU
*"       OPTIONAL
*"      IT_SIMU_ROLE_ADDITION STRUCTURE  /PSYNG/SW_ROLE_ADDITION_SIMU
*"       OPTIONAL
*"      IT_ADVANCED_ROLE_SIMU STRUCTURE  AGR_1251 OPTIONAL
*"      IT_SIMU_ADD_ROLEAUTH STRUCTURE  /PSYNG/USERAUTH OPTIONAL
*"      IT_SIMU_ADD_ROLETCODE STRUCTURE  /PSYNG/USERTCODE OPTIONAL
*"      IT_FAOBJ_SYS TYPE  /PSYNG/SW_TAB_SYS_FAOBJ OPTIONAL
*"----------------------------------------------------------------------
  DATA :
    lt_orgm        TYPE TABLE OF /psyng/swsodorgm,
    lt_sum         TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
    lt_sum_part    TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
    lt_sum_usr     TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
    lt_confdet     TYPE TABLE OF /psyng/confdet  WITH HEADER LINE,
    lt_functtran   TYPE TABLE OF /psyng/functtran  WITH HEADER LINE,
    lt_faobj       TYPE TABLE OF /psyng/faobj2  WITH HEADER LINE,
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
    l_system_msg(72)  type c.
  RANGES :
    lr_bname        FOR sy-uname.

  STATICS :
    lf_active         TYPE flag,
    lf_status_checked TYPE flag,
    st_config         TYPE SORTED TABLE OF /psyng/swsodorgo
                      WITH HEADER LINE WITH NON-UNIQUE KEY vrsio conid.
  data ls_faobj_sys like line of it_faobj_sys .
  ef_valid = 'X'.
  REFRESH : et_invalid.
*--Only do anything if this analysis has org check enabled
  CHECK i_org_check = 'X'.

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
        REFRESH : lr_bname.
        IF NOT it_outputdet[] IS INITIAL.
          LOOP AT it_outputdet.
            READ TABLE et_invalid WITH KEY bname = it_outputdet-bname
                                           conid = it_outputdet-conid.
            IF sy-subrc <> 0.
              IF is_outputdet-conid IS INITIAL.
                is_outputdet-conid = it_outputdet-conid.
              ENDIF.
              IF it_outputdet-conid <> is_outputdet-conid.
                MESSAGE e002(/psyng/sw) WITH
            'Custom Org Logic can only be called for a single conflict'.
              ENDIF.
              lr_bname-sign   = 'I'.
              lr_bname-option = 'EQ'.
              lr_bname-low    = it_outputdet-bname.
              APPEND lr_bname.
            ENDIF.
          ENDLOOP.
        ELSE.
          lr_bname-sign   = 'I'.
          lr_bname-option = 'EQ'.
          lr_bname-low    = is_outputdet-bname.
          APPEND lr_bname.
        ENDIF.
        IF NOT lr_bname[] IS INITIAL.
          REFRESH : lt_sum.
          MESSAGE s113(/psyng/sw) WITH
        'Applying Custom Org Logic'
              is_outputdet-bname
              is_outputdet-conid
              l_rewrite_type.

          LOOP AT it_rfcdes.
*--Begin Of change : Umittal 05/02/2024 C1243 : PN-2272 D67K929754
*--This conflict should be re-checked by custom Org Logic
          READ TABLE it_faobj_sys INTO ls_faobj_sys
           WITH KEY rfcdest =  it_rfcdes-rfcoptions.
          IF sy-subrc EQ 0.
            it_faobj[] = ls_faobj_sys-faobj[].
          ENDIF.

          CLEAR : lt_faobj[].
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
          DESCRIBE TABLE lt_confdet LINES l_numfun.

*-- End of change : Umittal 05/02/2024 C1243 : PN-2272 D67K929754

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
*--Do a detailed analysis for this conflict for this user
            IF  it_rfcdes-rfcdest = 'LOCAL'.
              CLEAR  it_rfcdes-rfcdest.
            ENDIF.

*--if an advanced simulation is being done, replace the IT_SIMU_ADD_ROLEAUTH records that are also in the
*  advanced simulation
            if not IT_ADVANCED_ROLE_SIMU[] is initial and not IT_SIMU_ADD_ROLEAUTH[] is initial .
              sort IT_ADVANCED_ROLE_SIMU by auth.
              loop at IT_ADVANCED_ROLE_SIMU.
                at new auth.
                  delete IT_SIMU_ADD_ROLEAUTH where auth = IT_ADVANCED_ROLE_SIMU-auth.
                endat.
              endloop.
              loop at IT_ADVANCED_ROLE_SIMU.
                move-corresponding  IT_ADVANCED_ROLE_SIMU to IT_SIMU_ADD_ROLEAUTH.
                IT_SIMU_ADD_ROLEAUTH-objct = IT_ADVANCED_ROLE_SIMU-object.
                IT_SIMU_ADD_ROLEAUTH-von = IT_ADVANCED_ROLE_SIMU-low.
                IT_SIMU_ADD_ROLEAUTH-bis = IT_ADVANCED_ROLE_SIMU-high.
                append IT_SIMU_ADD_ROLEAUTH.
              endloop.
              sort IT_SIMU_ADD_ROLEAUTH.
            endif.

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
            CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
                 DESTINATION it_rfcdes-rfcdest
                     EXPORTING
                          i_org_check  = 'X'
                     TABLES
                          it_users     = lr_bname
                          it_confdet   = lt_confdet
                          it_functtran = lt_functtran
                          it_faobj     = lt_faobj
                          it_swsodorgm = lt_orgm
                          et_output    = lt_sum_part
                          IT_SIMU_ROLE_REMOVAL  = IT_SIMU_ROLE_REMOVAL
                IT_SIMU_ADD_ROLEAUTH  = IT_SIMU_ADD_ROLEAUTH
                          IT_SIMU_ADD_ROLETCODE = IT_SIMU_ADD_ROLETCODE
                IT_ADVANCED_ROLE_SIMU = IT_ADVANCED_ROLE_SIMU
                    EXCEPTIONS
                          communication_failure = 1 MESSAGE l_system_msg
                          system_failure        = 2 MESSAGE l_system_msg
                          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
            if sy-subrc = 0.
              APPEND LINES OF lt_sum_part TO lt_sum.
              REFRESH : lt_sum_part, lt_orgm.
            else.
            MESSAGE s002(/psyng/sw) WITH
            'Org Override failed on RFC'(f01)
            it_rfcdes-rfcdest l_system_msg.
*   & & & &

            endif.
          ENDLOOP.
*--Now check if all functions have an overlapping org
          SORT lt_sum BY bname.
          LOOP AT lr_bname.
            REFRESH : lt_sum_usr.
            REFRESH : lt_cnt.
            READ TABLE lt_sum WITH KEY bname = lr_bname-low.
            LOOP AT lt_sum FROM sy-tabix.
              IF lt_sum-bname <> lr_bname-low.
                EXIT.
              ENDIF.
              APPEND lt_sum TO lt_sum_usr.
            ENDLOOP.
            SORT lt_sum_usr BY funid org_abb.
            DELETE ADJACENT DUPLICATES FROM lt_sum_usr
                   COMPARING funid org_abb.
            clear l_cnt_star.
            LOOP AT lt_sum_usr.
              lt_cnt-abb = lt_sum_usr-org_abb.
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
                et_invalid-bname = lr_bname-low.
                et_invalid-conid = is_outputdet-conid.
                APPEND et_invalid.
              ENDIF.
            ENDIF.
          ENDLOOP.
        ENDIF.
        SORT et_invalid BY bname conid.
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
