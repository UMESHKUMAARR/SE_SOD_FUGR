FUNCTION /psyng/sw_critcode_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_TCODE) TYPE  TSTCT-TCODE
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SWAUDHDR-VRSIO
*"----------------------------------------------------------------------

  DATA: BEGIN OF s_text OCCURS 0 ,
        text LIKE agr_texts-text,
        END OF s_text.
*  DATA:l_desc TYPE /psyng/critcodes-description.
  REFRESH: gt_critcodes,gt_text.
  SELECT SINGLE tcode imp owner
  INTO (gt_critcodes-tcode, gt_critcodes-imp,
  gt_critcodes-owner)
         FROM /psyng/critcodes
         WHERE vrsio = i_vrsio AND
               tcode  = i_tcode.
  SELECT SINGLE ttext INTO gt_critcodes-ttext FROM tstct
  WHERE sprsl = sy-langu
  AND   tcode = i_tcode.

  IF sy-subrc = 0.
    SELECT line
           text FROM /psyng/texts
            INTO corresponding fields of  TABLE s_text
            WHERE textname = i_tcode
            AND   object   = 'X'
            AND   vrsio    = i_vrsio
            AND   spras    = sy-langu
            order by line.
    IF sy-subrc = 0.
      gt_text[] = s_text[].
    ENDIF.
    APPEND gt_critcodes.
  ENDIF.
  g_vrsio = i_vrsio.
  CALL SCREEN 1200 STARTING AT 20 3.


ENDFUNCTION.
