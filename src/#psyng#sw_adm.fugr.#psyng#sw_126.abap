FUNCTION /psyng/sw_126.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_FUNCTION) TYPE  FLAG OPTIONAL
*"     VALUE(I_PROPOSE_MITIGATION) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TEXTS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TCODES) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      ET_FUNCTION STRUCTURE  /PSYNG/DA_FUNCTION OPTIONAL
*"      IT_CONFLICTS STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      ET_CONPMIT STRUCTURE  /PSYNG/CONPMIT OPTIONAL
*"      ET_TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      ET_MCHDR STRUCTURE  /PSYNG/MCHDR OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      ET_TSTCT STRUCTURE  TSTCT OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_126'.
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
*-- function details
  IF i_function = 'X'.
    CHECK NOT it_confdet[] IS INITIAL.
    SELECT * FROM /psyng/function INTO TABLE et_function
      FOR ALL ENTRIES IN it_confdet
      WHERE vrsio = i_vrsio
        AND function = it_confdet-functionid.
  ENDIF.

*-- get proposed mitigations
  IF i_propose_mitigation = 'X'.
    PERFORM get_proposed_mitigations TABLES     it_conflicts
                                                et_conpmit
                                                et_mchdr
                                                et_texts
                                         USING if_texts
                                               i_vrsio.
  ENDIF.

*--- get tcode texts
  IF if_tcodes = 'X'.
    if not it_functtran[] is initial.
    SELECT tcode ttext
          FROM tstct
          INTO CORRESPONDING FIELDS OF TABLE et_tstct
          FOR ALL ENTRIES IN it_functtran WHERE
          sprsl = sy-langu AND
          tcode = it_functtran-tcode.
    endif.
  ENDIF.
ENDFUNCTION.
