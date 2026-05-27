FUNCTION /psyng/sw_enh_get.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_FORCE) TYPE  FLAG OPTIONAL
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(EF_UPDATE) TYPE  FLAG
*"  TABLES
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      ET_TCODES STRUCTURE  /PSYNG/SW_PAR_TCODE_OUTPUT OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_ENH_GET'.
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

  DATA: l_enh_buffer  TYPE /psyng/param.
  se_config_param 'SW_ENH_BUFFER' l_enh_buffer.
  IF l_enh_buffer NE 'X' AND l_enh_buffer NE 'Y'.
*--Do Dynamic Enhancement on the fly
    CALL FUNCTION '/PSYNG/SW_029'
         TABLES
              functtran = it_functtran
              tcodes    = et_tcodes.
  ELSE.
*--Read buffered SOD Enhancement
*--This FM will also update the buffer if the information in it
*  is too old based on SW_ENH_BUFFER_DAYS
*
    CALL FUNCTION '/PSYNG/SW_ENH_READ'
         EXPORTING
              i_vrsio      = i_vrsio
         TABLES
              it_functtran = it_functtran
              et_tcodes    = et_tcodes.

  ENDIF.
ENDFUNCTION.
