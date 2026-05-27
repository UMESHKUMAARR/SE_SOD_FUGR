FUNCTION /psyng/sw_critauth_info.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_AUTH) TYPE  /PSYNG/SWAUDHDR-SWAUDID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SWAUDHDR-VRSIO
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CRITAUTH_INFO'.
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
  DATA:l_desc TYPE /psyng/texts-text.
  REFRESH: gt_text.
  CLEAR gt_critauths.

  SELECT SINGLE * FROM /psyng/swaudhdr INTO gt_critauths
  WHERE swaudid = i_auth AND vrsio = i_vrsio.

  SELECT line text INTO corresponding fields of TABLE gt_text
  FROM /psyng/texts WHERE vrsio = i_vrsio
                            AND textname = i_auth
                            AND object = 'T'
                            AND spras = sy-langu
                            order by line.



*  APPEND gt_critcodes.
*  gt_text-text = l_desc.
*  APPEND gt_text.
  g_vrsio = i_vrsio.
  CALL SCREEN 1201 STARTING AT 20 3.


ENDFUNCTION.
