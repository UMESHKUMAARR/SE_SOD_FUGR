FUNCTION /PSYNG/SW_VALIDATE_CONFIG.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      IT_CONFIG STRUCTURE  /PSYNG/SE_CONFIG_PARAM OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VALIDATE_CONFIG'.
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

*--Get the possible values where possible
  data : lt_config   type table of /PSYNG/SE_CONFIG_PARAM,
         lt_config_s type hashed table of /PSYNG/SE_CONFIG_PARAM with unique key param,
         lt_values   type table of /PSYNG/SE_CONFIG_PARAM_LIST,
         lt_values_s type sorted table of /PSYNG/SE_CONFIG_PARAM_LIST
                     with non-unique key param,
         lt_param    type table of /PSYNG/RANGE_PARAM with header line,
         l_test      type string,
         lf_exists   type flag,
         ls_cfg      type /PSYNG/SE_CONFIG_PARAM,
         l_cnt       type i,
         l_rfcdest   type rfcdest.
  lt_param-sign   = 'I'.
  lt_param-option = 'EQ'.
  loop at it_config.
    lt_param-low = it_config-param.
  endloop.
  CALL FUNCTION '/PSYNG/SW_PARAMETERS_INFO'
   TABLES
     IT_PARAM           = lt_param
     ET_CONFIG          = lt_config
     ET_VALUELIST       = lt_values.

  sort lt_values by param value.
  lt_values_s[] = lt_values[].
  insert lines of lt_config into table lt_config_s.
  free : lt_values, lt_config.
  loop at IT_CONFIG where value <> ''.
    ET_RETURN-field     = IT_CONFIG-param.
    ET_RETURN-parameter = IT_CONFIG-param.
    read table lt_config_s with table key param = IT_CONFIG-param transporting no fields.
    if sy-subrc = 0.
*--The parameter is a Security Weaver defined parameter and can be validated.
      read table lt_values_s with table key param =   IT_CONFIG-param transporting no fields.
      if sy-subrc = 0.
*--A list of values exists for this parameter, only allow values that fit that list
        read table lt_values_s with  key
          param =   IT_CONFIG-param
          value =   IT_CONFIG-value
          transporting no fields.
        if sy-subrc <> 0.
          ET_RETURN-type    = 'E'.
          ET_RETURN-message = 'Parameter value is not permitted'(p01).
          append et_return.
        endif.
      endif.
    endif.
*--Additional Specific checks for parameters
    case IT_CONFIG-param.
*--Numeric values
      when 'DFLT_MAX_USER_SCAN'  or
           'DFLT_STORE_RET_DAYS' or
           'DFLT_STORE_R_DAYS_S' or
           'DFLT_STORE_R_DAYS_D' or
           'DFLT_STOR_DET_BTCH' or
           'DFLT_STOR_SUM_BTCH' or
           'DFLT_STOR_SUM_PAR' or
           'DFLT_ST_ROL_DET_BTCH' or
           'DFLT_ST_ROL_RET_DAYS' or
           'DFLT_ST_RORET_DAYS_S' or
           'DFLT_ST_RORET_DAYS_D' or
           'DFLT_ST_ROL_SUM_BTCH' or
           'DET_SOD_BATCH_SIZE' or
           'SOD_EXPORT_ALV_LIMIT' or
           'SW_ENH_BUFFER_DAYS' or
           'AUTHCOMP_BUFFERSIZE' or
           'SW_MGMT_NUM_WEEKS'.
       l_test = it_config-value.
       SHIFT l_test RIGHT DELETING TRAILING SPACE.
       if l_test CO '0123456789'.
*--Valid, value only contains numbers or spaces after a number
       else.
*--Invalid, value contains non-numbers or spaces before a number
          ET_RETURN-type    = 'E'.
          ET_RETURN-message = 'Parameter value should be numeric'(p02).
          append et_return.
       endif.
*--Text Templates (defined in SO10)
     when 'CFGGSET_COMP_EMAIL' or
          'SW_MIT_ASG_NOTIF_OID' or
          'SW_MIT_REMIND_EMAIL' or
          'SW_MIT_SIGNOFF_EMAIL' or
          'SW_USR_INACTIV_EMAIL' or
          'MIT_DFLT_REV_TEXT' or
          'SW_MIT_SIGNOFF_TEXT'.       .
       perform check_text_exists
        using it_config-value
        changing
              lf_exists.
       if lf_exists <> 'X'.
*--Invalid, no standard text with this name is defined in SO10
          ET_RETURN-type    = 'E'.
          ET_RETURN-message = 'No text with name maintained in parameters'(p03) .
          et_return-message_v3 = 'current value is defined in S010'(p07).
          append et_return.
          clear et_return-message_v3.
       endif.
*--Documents (defined in SE61)
     when 'SW_CSS_EMAIL'.
       perform check_document_exists
        using it_config-value
        changing
              lf_exists.
       if lf_exists <> 'X'.
*--Invalid, no document with this name is defined in SE61
          ET_RETURN-type    = 'E'.
          ET_RETURN-message = 'No document with name maintained in parameters'(p06).
          et_return-message_v3 = 'current value is defined in SE61'(p08).
          append et_return.
          clear et_return-message_v3.
       endif.
*--Function modules, they should fit specific signatures, all valid FM's are returned as values
       when 'FM_MAP_USER'   or
            'SW_CENTRAL_USR_FM'    or
            'SW_COMPANY_SHLP_FM'   or
            'SW_DEPART_SHLP_FM'    or
            'SW_MGMT_COMP_NAME_FM' or
            'SW_MGMT_COMPANY_FM'   or
            'SW_MGMT_DEPARTMENT_F'.
         read table et_return with key parameter = ET_RETURN-parameter.
         if sy-subrc = 0.
           delete et_return where parameter = ET_RETURN-parameter.
           ET_RETURN-type    = 'E'.
           ET_RETURN-message = 'Function module does not exist or does not have correct signature.'(p04).
           append et_return.
         endif.
*--Default global SOD Matrix - if Config Set functionality is enabled, there needs to be a
      when 'DFLT_GLOBAL_VERSION'.
        CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
         EXPORTING
           I_PARAMETER        = 'CFG_SET_ENABLED'
         IMPORTING
           E_VALUE            = ls_cfg-value.
        if ls_cfg-value = 'Y'.
          select count(*) from /PSYNG/SWCFGSET into l_cnt where SODVRSIO = it_config-value and published = 'X'.
          if l_cnt < 1.
             ET_RETURN-type    = 'E'.
             ET_RETURN-message = 'No Published Config Set exists for this SOD Matrix Version.'(p05).
             append et_return.
          endif.

        endif.
*--Validate RFC Destination exists (we don't test if it works)
     when 'SW_056_RFC_DEST'     or
          'SW_DFLT_RFC_DEST'    or
          'APPROVAL_CENTRAL_SYS'.
       l_rfcdest = IT_CONFIG-VALUE.
       select single rfcdest into l_rfcdest from rfcdes where rfcdest = l_rfcdest and RFCTYPE = 3.
       if sy-subrc <> 0.
             ET_RETURN-type    = 'E'.
             ET_RETURN-message = 'RFC destination does not exist.'(p09).
             append et_return.
       endif.
    endcase.
  endloop.

ENDFUNCTION.
