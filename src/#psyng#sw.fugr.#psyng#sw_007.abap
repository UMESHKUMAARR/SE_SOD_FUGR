FUNCTION /psyng/sw_007.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_CONID) TYPE  /PSYNG/CONFLICT_ID
*"     REFERENCE(I_VRSIO) LIKE  /PSYNG/CONFLICT-VRSIO
*"  TABLES
*"      IT_TCODE STRUCTURE  /PSYNG/RANGE_TCODE OPTIONAL
*"----------------------------------------------------------------------

  /psyng/conflict-conid = i_conid.
  /psyng/conflict-vrsio = i_vrsio.

  SELECT SINGLE description INTO /psyng/conflict-description
                FROM /psyng/conflict
                WHERE conid = i_conid
                  AND vrsio = i_vrsio.

  REFRESH gt_text.

  SELECT text INTO TABLE gt_text FROM /psyng/texts
         WHERE textname = i_conid
           AND object   = 'C'
           AND vrsio    = i_vrsio
           AND SPRAS    = sy-langu.

  SELECT func~function func~description INTO TABLE gt_funct
    FROM /psyng/confdet AS confdet
   INNER JOIN /psyng/function AS func
      ON func~function = confdet~functionid
     AND func~vrsio    = confdet~vrsio
   WHERE confdet~conid = i_conid
     AND confdet~vrsio = i_vrsio.

  SORT it_tcode.
  DELETE ADJACENT DUPLICATES FROM it_tcode.

  gr_tcode[] = it_tcode[].
  REFRESH gt_tstct.  CLEAR gt_tstct.

  CALL SCREEN 1000 STARTING AT 20 3.

ENDFUNCTION.
