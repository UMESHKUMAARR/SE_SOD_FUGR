FUNCTION /psyng/sw_ao_read.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_READ) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ANALYZE) TYPE  FLAG OPTIONAL
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_READ_TEXTS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_VALIDATE) TYPE  FLAG OPTIONAL
*"     VALUE(I_SKIP_VALIDATE) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_ORG_VALUES STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_TEXTS STRUCTURE  /PSYNG/SW_ORG_VALUES_TEXT OPTIONAL
*"      IT_ANALYZE_ELEMENTS STRUCTURE  /PSYNG/SW_AO_LIST OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_READ'.
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

data : ls_configset type /PSYNG/SWCFGSET.

EF_SUCCESS = 'X'.
*  --Validate the import parameters
   if IF_READ = IF_ANALYZE or ( IF_READ <> 'X' and IF_ANALYZE <> 'X' ).
        log et_return 'E' 'PARAMETERS' 'Exactly one of the parameters'
                                       'IF_READ and IF_ANALYZE'
                                       'Should have the value X' ''.
        clear EF_SUCCESS.
   endif.
*  --Validate the set exists
   if i_skip_validate is initial.
   select single * from /PSYNG/SWCFGSET into ls_configset
   where setid = I_SETID.
   if sy-subrc <> 0.
        log et_return 'E' 'INVALID_SET' 'Configuration Set' I_SETID
                                        'does not exist.'
                                        ''.
        clear EF_SUCCESS.
   else.
       if if_analyze = 'X' and ls_configset-published = 'X' and
          IF_VALIDATE = ''.
          log et_return 'E' 'ALREADY_PUBLISHED'
                            'Analysis not allowed for Published Set'
                            '' '' ''.
          clear EF_SUCCESS.
        endif.
   endif.
   ENDIF.

  check ef_success = 'X'.


    case 'X'.
      when if_analyze.
*  --Analyze the org elements for this configuration set
        perform analyze_org_elements
          tables
            et_org_values
            et_return
            et_texts
            it_analyze_elements
            IT_SYSTEMS
          using
            i_setid
          changing
            EF_SUCCESS.
     when if_read.
*  --read the stored org element values for this configuration set
        perform read_org_elements
          tables
            et_org_values
            et_return
            et_texts
            it_analyze_elements
            IT_SYSTEMS
          using
            i_setid
            IF_READ_TEXTS
          changing
            EF_SUCCESS.
    endcase.

  endfunction.
