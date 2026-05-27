FUNCTION /psyng/sw_015.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_BNAME) TYPE  XUBNAME
*"  EXPORTING
*"     VALUE(EF_HAS_CONFLICT) TYPE  /PSYNG/BAPIFLAGX
*"----------------------------------------------------------------------
DATA: l_gltgb TYPE usr02-gltgb,
      l_erdat TYPE usr02-erdat,
      l_trdat TYPE usr02-trdat,
      l_days  TYPE i.


  SELECT SINGLE gltgb erdat trdat INTO (l_gltgb, l_erdat, l_trdat)
           FROM usr02
          WHERE bname = i_bname.

  IF NOT l_trdat IS INITIAL.
    l_days = sy-datum - l_trdat.
  ELSE.
    l_days = sy-datum - l_erdat.
  ENDIF.

  IF ( l_gltgb > sy-datum OR l_gltgb IS INITIAL )
  AND l_days > 120.
    ef_has_conflict = 'X'.
  ENDIF.
ENDFUNCTION.
