FUNCTION /psyng/sw_vrsio_count.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_HEADER_INFO) TYPE  FLAG OPTIONAL
*"     VALUE(I_DETAIL_INFO) TYPE  FLAG OPTIONAL
*"     VALUE(I_REFRESH_CHECK) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_OVERVIEW) TYPE  /PSYNG/SWADMOVW
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_DETAIL STRUCTURE  /PSYNG/SWADMOVW OPTIONAL
*"      IT_SYSTEM STRUCTURE  /PSYNG/RANGE_SYSID OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VRSIO_COUNT'.
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

  ef_success = 'X'.

*--Validate the import parameters
  IF i_header_info = i_detail_info OR
          ( i_header_info <> 'X' AND i_detail_info <> 'X' ).
    log et_return 'E' 'PARAMETERS' 'Exactly one of the parameters'
                                   'I_HEADER_INFO and I_DETAIL_INFO'
                                   'Should have the value X' ''.
    CLEAR ef_success.
  ENDIF.

  CHECK ef_success = 'X'.

  CASE 'X'.
    WHEN i_header_info.
      PERFORM get_header_overview
      CHANGING
        e_overview.
    WHEN i_detail_info.
      PERFORM get_detail_overview
      TABLES
        it_system
        et_detail
        ET_RETURN.
  ENDCASE.
ENDFUNCTION.
