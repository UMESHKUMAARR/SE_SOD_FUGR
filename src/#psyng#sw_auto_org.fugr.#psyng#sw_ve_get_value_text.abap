FUNCTION /psyng/sw_ve_get_value_text.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_LANGU) TYPE  SYLANGU DEFAULT SY-LANGU
*"     VALUE(I_VAREL_VRSIO) TYPE  /PSYNG/VE_VRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(E_TEXT) TYPE  XUTEXT
*"  TABLES
*"      ET_TEXTS STRUCTURE  /PSYNG/SW_VE_VALUES_TEXT OPTIONAL
*"      IT_VALUES STRUCTURE  /PSYNG/SWCFGVE
*"      IT_VAREL STRUCTURE  /PSYNG/SW_VAREL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VE_GET_VALUE_TEXT'.
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

  DATA : lt_texts  TYPE TABLE OF /psyng/sw_ve_values_text
                   WITH HEADER LINE,
         lt_values TYPE TABLE OF /psyng/swcfgve,
         l_fieldname(100) type c,
         lt_fieldnames like table of l_fieldname,
         l_filt(100) type c ,
         lt_filt like table of l_filt.
*--Macro get_text----------------------------------------
* &1 - table that contains the texts
* &2 - fielld that contains the text
* &3 - field that contains the org value
* &4 - field that contains the language
*     ( use mandt if no language field exists in &1)
* &5 - language value
*     ( use sy-mandt if no language field exists in &1)
*---------------------------------------------------------
  DEFINE get_ve_text.
    call function 'DDIF_FIELDINFO_GET'
         exporting
              tabname        = &1
         exceptions
              not_found      = 1
              internal_error = 2
              others         = 3. "#EC SAST_CI_GEN_CHECK
    if sy-subrc = 0.
      refresh : lt_fieldnames, lt_filt.
*--Select clause
      concatenate
      &2 'as value '  into l_fieldname
       separated by space. "#EC SAST_CI_GEN_CHECK
      append l_fieldname to lt_fieldnames. "#EC SAST_CI_GEN_CHECK
      concatenate
      &3 'as vtext' into l_fieldname
       separated by space. "#EC SAST_CI_GEN_CHECK
      append l_fieldname to lt_fieldnames. "#EC SAST_CI_GEN_CHECK
*--Where clause
      concatenate &4 ' = ''' &5 '''' into l_filt. "#EC SAST_CI_GEN_CHECK
      append l_filt to lt_filt. "#EC SAST_CI_GEN_CHECK

      if &2 = 'KSCHL'. "#EC SAST_CI_GEN_CHECK
      CONCATENATE 'AND'  'KAPPL' 'IN'  &6  into l_filt SEPARATED BY
         space. "#EC SAST_CI_GEN_CHECK
      append l_filt to lt_filt. "#EC SAST_CI_GEN_CHECK
     endif.
*--   select all texts from table &1
      select
*      &2 as value ,
*      &3 as vtext
      (lt_fieldnames)
      from (&1)
      into corresponding fields of table lt_texts
      where (lt_filt). "#EC SAST_CI_GEN_CHECK
      sort lt_values by value.
      loop at lt_texts.
        read table lt_values with key value = lt_texts-value
        binary search transporting no fields. "#EC SAST_CI_GEN_CHECK
        if sy-subrc = 0.
            CONCATENATE sy-sysid sy-mandt INTO lt_texts-sysid.
lt_texts-var_element = it_values-var_element. "#EC SAST_CI_GEN_CHECK
            append lt_texts to et_texts. "#EC SAST_CI_GEN_CHECK
        endif.
      endloop.
    endif.
  END-OF-DEFINITION.
  data: lt_varel type table of /psyng/sw_varel WITH HEADER LINE.
  ranges lr_kappl for /PSYNG/SW_VAREL-VAL_FROM.

*--- om 20221226 read and pass rules to read texts
select * from /psyng/sw_varel into table lt_varel where
VAREL_VRSIO = i_varel_vrsio.

*--- End

  SORT it_values BY var_element.
  SORT it_varel BY var_element.
  LOOP AT it_values.
    AT NEW var_element.
      REFRESH : lt_values.
    ENDAT.
    APPEND it_values TO lt_values.
    AT END OF var_element.
      READ TABLE it_varel WITH KEY var_element = it_values-var_element
      binary search.
      CHECK sy-subrc = 0.
*--Use macro to select text from appropriate table for field
      CASE it_varel-element.
        WHEN 'AUART'.
          get_ve_text  'TVAKT'  'AUART' 'BEZEI' 'SPRAS' i_langu ''.
        WHEN 'BWART'.
          get_ve_text  'T156HT' 'BWART' 'BTEXT' 'SPRAS' i_langu ''.
        WHEN 'FKART'.
          get_ve_text  'TVFKT'  'FKART' 'VTEXT' 'SPRAS' i_langu ''.
        WHEN 'BSART'.
          get_ve_text  'T161T'  'BSART' 'BATXT' 'SPRAS' i_langu '' .
        WHEN 'KSCHL'.
          loop at lt_varel where element = 'KSCHL' and
                                 field = 'KAPPL'.
            lr_kappl-sign = lt_varel-V_SIGN.
            lr_kappl-option = lt_varel-V_OPTION.
            lr_kappl-low = lt_varel-VAL_FROM.
            lr_kappl-high = lt_varel-VAL_TO.
            collect lr_kappl.
          endloop.

        get_ve_text 'T685T' 'KSCHL' 'VTEXT' 'SPRAS' i_langu 'LR_KAPPL'.

        WHEN 'FAKE'.
*--Include a fake table here, to ensure macro code compiles and
*  can run on systems that don't have 1 or more of the above tables
*        get_ve_text 'INVALID' 'INVALID' invalid invalid i_langu.
        WHEN OTHERS.
*--This is a field for which we can't handle reading text/labels
      ENDCASE.
*      MODIFY table lt_texts TRANSPORTING sysid.
*      APPEND LINES OF lt_texts TO et_texts.
      REFRESH lt_texts.
    ENDAT.
  ENDLOOP.


ENDFUNCTION.
