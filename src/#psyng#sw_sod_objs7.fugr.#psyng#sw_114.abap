FUNCTION /psyng/sw_114.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(VRSIO) TYPE  /PSYNG/SODVRSIO
*"     REFERENCE(ENH_FM) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_COMPOSITE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(I_SINGLE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(I_SHOMIT) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(I_ASSIGNED_ROLES) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_BYSIMU) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_BYRSIMU) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_SHONOCA) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_REMOTE_ONLY) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_DETAILED) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_ADVANCED_ROLE_SIMU) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_SIMU_ROLE_REMOVAL STRUCTURE  /PSYNG/SW_ROLE_REMOVAL_SIMU
*"       OPTIONAL
*"      IT_ROLE_ADDITION_SIMU STRUCTURE  /PSYNG/SW_ROLE_ADDITION_SIMU
*"       OPTIONAL
*"      IT_SWAUDID STRUCTURE  /PSYNG/RANGE_SWAUDID OPTIONAL
*"      IT_ROLES STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME
*"      ET_SUMMARY STRUCTURE  /PSYNG/SW_CA_ROUTPUT OPTIONAL
*"      IT_RFCDEST STRUCTURE  /PSYNG/SW_SEL_OPTS_RFCDEST OPTIONAL
*"      ET_DETAILS STRUCTURE  /PSYNG/SW_CA_ROUTPUTDET OPTIONAL
*"      IT_ADVANCED_ROLE_SIMU STRUCTURE  AGR_1251 OPTIONAL
*"      ET_SUMMARY2 STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"----------------------------------------------------------------------
  DATA : lt_local_swaudhdr TYPE TABLE OF /psyng/swaudhdr,
         lt_local_swaudc   TYPE TABLE OF /psyng/swaudc2,
         lt_mitigations    TYPE TABLE of /PSYNG/MCCAROLE
         with header line,
         ls_mitigation    TYPE /PSYNG/MCCAROLE,
         lt_agr_define TYPE TABLE OF agr_define WITH HEADER LINE.

  DATA : lt_conflict   TYPE TABLE OF /psyng/conflict,
         lt_confdet    TYPE TABLE OF /psyng/confdet,
         lt_functtran  TYPE TABLE OF /psyng/functtran,
         lt_faobj      TYPE TABLE OF /psyng/faobj2,
         lt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output,
         gt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output,
         lt_routput_sum TYPE TABLE OF /psyng/sw_out_routput
         WITH HEADER LINE,
          lt_simu_roleauth TYPE TABLE OF /psyng/roleauth
         WITH HEADER LINE,
         lt_simu_roletcode TYPE TABLE OF /psyng/roletcode
         WITH HEADER LINE,
         lt_simu_tcdaut TYPE TABLE OF /psyng/psswtcdaut,
         l_nr_roles_analyzed TYPE i,
         lt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
         swaudhdr TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
         l_date(12) TYPE c,
         l_system_msg(100) TYPE c,
         l_rfcdes TYPE rfcdes,
         l_taskname TYPE string.
  FIELD-SYMBOLS : <o_det> TYPE /psyng/sw_ca_routputdet,
                  <sum> type /psyng/sw_out_routput.

  REFRESH : et_summary.
  WRITE sy-datum TO l_date.

*--Get RFC destinations for Cross system analysis
  PERFORM load_rfc
          TABLES it_rfcdest
                 lt_rfcdest.


  PERFORM load_local_swauds
    TABLES
           lt_conflict
           lt_functtran
           lt_faobj
           lt_confdet
           lt_local_swaudhdr
           lt_local_swaudc
           lt_enh_tcodes
           it_swaudid
    USING
           vrsio
           enh_fm.
  APPEND LINES OF lt_enh_tcodes TO gt_enh_tcodes.

* buffer ca descriptions
  SELECT * FROM /psyng/swaudhdr INTO TABLE swaudhdr
  WHERE vrsio =  vrsio AND swaudid IN it_swaudid.

  SORT swaudhdr BY swaudid.

*--Load the mitigations
  select * from /PSYNG/MCCAROLE into table lt_mitigations
  where
  vrsio      = VRSIO  AND
   from_date LE sy-datum AND
   to_date   GE sy-datum.
*--Also add derived roles as mitigated roles
    IF NOT lt_mitigations[] IS INITIAL.
      SELECT agr_name parent_agr            "#EC CI_IMUD_NESTED
        FROM agr_define
           INTO CORRESPONDING FIELDS OF TABLE lt_agr_define
           FOR ALL ENTRIES IN lt_mitigations
           WHERE parent_agr =  lt_mitigations-agr_name and
           agr_name in IT_ROLES.
      LOOP AT lt_agr_define.
        LOOP AT lt_mitigations WHERE
         agr_name = lt_agr_define-parent_agr.
          ls_mitigation = lt_mitigations.
          lt_mitigations-agr_name = lt_agr_define-agr_name.
          APPEND ls_mitigation TO lt_mitigations.
        ENDLOOP.
      ENDLOOP.
   endif.
  sort lt_mitigations by swaudid agr_name.


  IF i_bysimu = 'X'.
*--SE3.1 - Load all simulated roles from their source system
    DATA :
*  lt_simu_roleauth  type table of /psyng/userauth with header line,
*  lt_simu_roletcode type table of /psyng/usertcode with header line,
  lt_simu_roleauth_part  TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
    lt_simu_roletcode_part
    TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
    l_agr_name TYPE agr_name.
    RANGES : range_roles FOR l_agr_name.
    PERFORM load_simulated_role_content
     TABLES
       it_role_addition_simu
       lt_simu_roleauth
       lt_simu_roletcode
       lt_functtran
       lt_faobj
       lt_rfcdest.
  ENDIF.
  IF i_detailed IS INITIAL.
*--Summary Analysis
    IF NOT i_remote_only = 'X'.
      CALL FUNCTION '/PSYNG/SW_036'
           EXPORTING
                vrsio                 = vrsio
                org_check             = ''
                enh_fm                = enh_fm
                xstb_fm               = 'X'
                i_local_sod           = ' '
                i_shonosod            = i_shonoca
                i_composite_roles     = i_composite_roles
                i_single_roles        = i_single_roles
                i_assigned_roles      = i_assigned_roles
                I_ADVANCED_ROLE_SIMU  = I_ADVANCED_ROLE_SIMU
           IMPORTING
                o_totalroles          = l_nr_roles_analyzed
           TABLES
                it_roles              = it_roles
                it_conflict           = lt_conflict
                it_confdet            = lt_confdet
                it_functtran          = lt_functtran
                it_faobj              = lt_faobj
                it_tcodes             = lt_enh_tcodes
                it_simurole_auth      = lt_simu_roleauth
                it_simurole_tcode     = lt_simu_roletcode
                it_simurole_tcdaut    = lt_simu_tcdaut
                it_advanced_role_simu = it_advanced_role_simu
                ot_routput_sum        = lt_routput_sum.
      CONCATENATE sy-sysid sy-mandt INTO et_summary-rfcdest.
      LOOP AT lt_routput_sum assigning <sum>.
        et_summary-swaudid  = <sum>-conid.
        et_summary-agr_name = <sum>-agr_name.
        et_summary-agr_text = <sum>-agr_text.
        et_summary-simu     = <sum>-simu.
        et_summary-enhanced = <sum>-enhanced.
        READ TABLE swaudhdr WITH KEY swaudid = et_summary-swaudid
                                     BINARY SEARCH.
        IF sy-subrc = 0.
          et_summary-description = swaudhdr-description.
          <sum>-imp              = swaudhdr-imp.
*              ADD 1 TO g_nr_auths.
        ELSEIF et_summary-swaudid = '----'.
          CONCATENATE
          'No Critical authorizations based on SOD matrix'(n01)
          'defined in Security Weaver on'(n02)
          l_date
          INTO et_summary-description SEPARATED BY space.
        ENDIF.
*        if ET_SUMMARY2 is requested.
*            <sum>-description = et_summary-description.
*            <sum>-rfcdest     = et_summary-rfcdest.
*        endif.
*        APPEND et_summary.
*      ENDLOOP.
*      if ET_SUMMARY2 is requested.
*        et_summary2[] = lt_routput_sum[].
*      endif.
*--Mitigation Check
          clear et_summary-contid.
          read table lt_mitigations with key
            swaudid  = et_summary-swaudid
            agr_name = et_summary-agr_name
            binary search transporting contid.
          if sy-subrc = 0.
*--Mitigated
            if i_shomit = 'X'.
              et_summary-contid = lt_mitigations-contid.
            endif.
          else.
          endif.

        if ( i_shomit = 'X' and et_summary-contid <> '' )
        or
        et_summary-contid is initial.
        append et_summary.
        if ET_SUMMARY2 is requested.
            move-corresponding et_summary to et_summary2.
            et_summary2-imp         = swaudhdr-imp.
            et_summary2-conid       = et_summary-swaudid.
            append et_summary2.
        endif.
        endif.
      ENDLOOP.

      FREE : lt_routput_sum.
    ENDIF.
*  --Remote analysis
    IF NOT lt_rfcdest[] IS INITIAL.

      LOOP AT lt_rfcdest INTO l_rfcdes.
        l_taskname = l_rfcdes-rfcoptions.
        ADD 1 TO g_running_tasks.
        CALL FUNCTION '/PSYNG/SW_036'
           STARTING NEW TASK l_taskname
           DESTINATION l_rfcdes-rfcdest
           PERFORMING get_remote_results ON END OF TASK
         EXPORTING
              vrsio          = vrsio
              org_check      = ''
              enh_fm         = enh_fm
              xstb_fm        = 'X'
              i_local_sod    = ' '
              i_shonosod     = i_shonoca
              i_composite_roles    = i_composite_roles
              i_single_roles       = i_single_roles
              i_assigned_roles = i_assigned_roles
              I_ADVANCED_ROLE_SIMU = I_ADVANCED_ROLE_SIMU
*             IMPORTING
*                  o_totalroles   = l_nr_roles_analyzed
         TABLES
              it_roles       = it_roles
              it_conflict    = lt_conflict
              it_confdet     = lt_confdet
              it_functtran   = lt_functtran
              it_faobj       = lt_faobj
              it_tcodes      = lt_enh_tcodes
              it_simurole_auth   = lt_simu_roleauth
              it_simurole_tcode  = lt_simu_roletcode
              it_simurole_tcdaut = lt_simu_tcdaut
              it_advanced_role_simu = it_advanced_role_simu
              ot_routput_sum = lt_routput_sum
            EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e01
              l_rfcdes-rfcdest
              l_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e01
              l_rfcdes-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.

      ENDLOOP.
      WAIT UNTIL g_running_tasks = 0.
      LOOP AT gt_fm_output.
        et_summary-swaudid  = gt_fm_output-swaudid.
        et_summary-agr_name = gt_fm_output-agr_name.
        et_summary-agr_text = gt_fm_output-agr_text.
        et_summary-simu     = gt_fm_output-simu.
        et_summary-enhanced = gt_fm_output-enhanced.
        et_summary-rfcdest  = gt_fm_output-rfcdest.




        READ TABLE swaudhdr WITH KEY swaudid = et_summary-swaudid
                                     BINARY SEARCH.
        IF sy-subrc = 0.
          et_summary-description = swaudhdr-description.
*                    ADD 1 TO g_nr_auths.
        ELSEIF et_summary-swaudid = '----'.
          CONCATENATE
          'No Critical authorizations based on SOD matrix'(n01)
          'defined in Security Weaver on'(n02)
          l_date
          INTO et_summary-description SEPARATED BY space.
        ENDIF.


*--Mitigation Check
          clear et_summary-contid.
          read table lt_mitigations with key
            swaudid  = et_summary-swaudid
            agr_name = et_summary-agr_name
            binary search transporting contid.
          if sy-subrc = 0.
*--Mitigated
            if i_shomit = 'X'.
              et_summary-contid = lt_mitigations-contid.
            endif.
          else.
          endif.

        if ( i_shomit = 'X' and et_summary-contid <> '' )
        or
        et_summary-contid is initial.
        append et_summary.
        if ET_SUMMARY2 is requested.
            move-corresponding et_summary to et_summary2.
            et_summary2-imp         = swaudhdr-imp.
            et_summary2-conid       = et_summary-swaudid.
            append et_summary2.
        endif.
        endif.
      ENDLOOP.

      FREE : gt_fm_output.
    ENDIF.
  ELSE.
*--Detailed analysis
    IF  NOT i_remote_only = 'X'.
      DATA : lt_outputdet TYPE TABLE OF /psyng/sw_out_routdet3
              WITH HEADER LINE.

      CALL FUNCTION '/PSYNG/SW_083'
           EXPORTING
                i_sodvrsio            = vrsio
                i_enhanc              = enh_fm
                i_xmc                 = ''
                i_shonosod            = i_shonoca
                i_composite_roles     = i_composite_roles
                i_single_roles        = i_single_roles
                i_assigned_roles      = i_assigned_roles
           TABLES
                it_roles              = it_roles
                et_outputdet          = lt_outputdet
                et_enh_tcodes         = gt_enh_tcodes
                it_conflict           = lt_conflict
                it_confdet            = lt_confdet
                it_functtran          = lt_functtran
                it_faobj              = lt_faobj
                it_simu_role_removal  = it_simu_role_removal
                it_simu_role_addition = it_role_addition_simu.
      CONCATENATE sy-sysid sy-mandt INTO et_details-rfcdest.
      LOOP AT  lt_outputdet.
        et_details-swaudid = lt_outputdet-conid.
        MOVE-CORRESPONDING lt_outputdet TO et_details.
        APPEND et_details.
      ENDLOOP.
    ENDIF.
    IF NOT lt_rfcdest[] IS INITIAL.
      LOOP AT lt_rfcdest INTO l_rfcdes.
        l_taskname = l_rfcdes-rfcoptions.
        ADD 1 TO g_running_tasks.
        CALL FUNCTION '/PSYNG/SW_083'
             STARTING NEW TASK l_taskname
             DESTINATION l_rfcdes-rfcdest
             PERFORMING get_remote_results_det ON END OF TASK
       EXPORTING
         i_sodvrsio                  = vrsio
         i_enhanc                    = enh_fm
         i_xmc                       = ''
         i_shonosod                  = i_shonoca
         i_composite_roles           = i_composite_roles
         i_single_roles              = i_single_roles
         i_assigned_roles            = i_assigned_roles
       TABLES
         it_roles                    = it_roles
         et_outputdet                = lt_outputdet
         et_enh_tcodes               = gt_enh_tcodes
          it_conflict    = lt_conflict
          it_confdet     = lt_confdet
          it_functtran   = lt_functtran
          it_faobj       = lt_faobj
it_simu_role_removal        = it_simu_role_removal
it_simu_role_addition       = it_role_addition_simu

        EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e01
              l_rfcdes-rfcdest
              l_system_msg..
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e01
              l_rfcdes-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.
      ENDLOOP.
      WAIT UNTIL g_running_tasks = 0.

*-process detailed fm output
      LOOP AT gt_fm_outputdet ASSIGNING <o_det>.

*--SF 2735 - Don't display /PSYNG/-SWAUDxxxx for tcode *
        CHECK NOT
          ( <o_det>-objct  EQ 'S_TCODE' AND
            <o_det>-von    CS '/PSYNG/-SWAUD' AND
            <o_det>-field  EQ 'TCD'
          ).
        IF <o_det>-tcode CS '/PSYNG/-SWAUD'.
          <o_det>-tcode = '*'.
        ENDIF.

        et_details-swaudid     = <o_det>-swaudid.
        et_details-agr_name    = <o_det>-agr_name.
        et_details-tcode      = <o_det>-tcode.
        et_details-objct      = <o_det>-objct.
        et_details-auth       = <o_det>-auth.
        et_details-field      = <o_det>-field.
        et_details-von        = <o_det>-von.
        et_details-bis        = <o_det>-bis.
        et_details-simu       = <o_det>-simu.
        et_details-enhanced = <o_det>-enhanced.


        IF <o_det>-child_agr <> <o_det>-agr_name.
          et_details-child_agr  = <o_det>-child_agr.
        ELSE.
          CLEAR et_details-child_agr.
        ENDIF.
        et_details-rfcdest    = <o_det>-rfcdest.
        APPEND et_details.
      ENDLOOP.



    ENDIF.

  ENDIF.



ENDFUNCTION.
