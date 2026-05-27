FUNCTION /psyng/sw_051.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"  EXPORTING
*"     VALUE(ES_SWSODVERS) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ET_USER_MIT_TEXT) TYPE  /PSYNG/MC_USERTEXT_TT
*"  TABLES
*"      IT_FUNID STRUCTURE  /PSYNG/RANGE_FUNID OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_CONTID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      IT_TCODE STRUCTURE  /PSYNG/RANGE_TCODE OPTIONAL
*"      IT_AUDID STRUCTURE  /PSYNG/RANGE_SWAUDID OPTIONAL
*"      IT_AGR STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_PROFIL STRUCTURE  /PSYNG/RANGE_PROFILE OPTIONAL
*"      IT_CUSCON STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_CON1 STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_USRID1 STRUCTURE  /PSYNG/SW_RANGE_USERID OPTIONAL
*"      IT_CON2 STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_USRGRP STRUCTURE  /PSYNG/SW_RANGE_USERGRP OPTIONAL
*"      IT_CON3 STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_ROL_NAM1 STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_CA_OBJID STRUCTURE  /PSYNG/SW_RANGE_CA_OBJID OPTIONAL
*"      IT_USRID2 STRUCTURE  /PSYNG/SW_RANGE_USERID OPTIONAL
*"      IT_CA_OBJID2 STRUCTURE  /PSYNG/SW_RANGE_CA_OBJID OPTIONAL
*"      IT_ROL_NAM STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      ET_FUNCTION STRUCTURE  /PSYNG/FUNCTION OPTIONAL
*"      ET_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      ET_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      ET_CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      ET_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      ET_MCHDR STRUCTURE  /PSYNG/MCHDR OPTIONAL
*"      ET_MCRVWHDR STRUCTURE  /PSYNG/MCRVWHDR OPTIONAL
*"      ET_MCTRAN STRUCTURE  /PSYNG/MCTRAN OPTIONAL
*"      ET_MCREPID STRUCTURE  /PSYNG/MCREPID OPTIONAL
*"      ET_MCAUDITOR STRUCTURE  /PSYNG/MCAUDITOR OPTIONAL
*"      ET_MCTEXT STRUCTURE  /PSYNG/MCRVWTXT OPTIONAL
*"      ET_MCUSER STRUCTURE  /PSYNG/MCUSER OPTIONAL
*"      ET_MCUSRGRP STRUCTURE  /PSYNG/MCUSRGRP OPTIONAL
*"      ET_MCROLE STRUCTURE  /PSYNG/MCROLE OPTIONAL
*"      ET_MCCAROLE STRUCTURE  /PSYNG/MCCAROLE OPTIONAL
*"      ET_MCCAUSER STRUCTURE  /PSYNG/MCCAUSER OPTIONAL
*"      ET_CRITCODES STRUCTURE  /PSYNG/CRITCODES OPTIONAL
*"      ET_SWAUDHDR STRUCTURE  /PSYNG/SWAUDHDR OPTIONAL
*"      ET_SWAUDC STRUCTURE  /PSYNG/SWAUDC2 OPTIONAL
*"      ET_CRIROLES STRUCTURE  /PSYNG/CRIROLES OPTIONAL
*"      ET_CRIPROF STRUCTURE  /PSYNG/CRIPROF OPTIONAL
*"      ET_TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      ET_CUSCON STRUCTURE  /PSYNG/SW_CUSCON OPTIONAL
*"      ET_CONOWNER STRUCTURE  /PSYNG/CONOWNER OPTIONAL
*"      ET_CONFIL STRUCTURE  /PSYNG/SW_SYSCON OPTIONAL
*"      ET_FUNFIL STRUCTURE  /PSYNG/SW_SYSFUN OPTIONAL
*"      ET_TCODEFIL STRUCTURE  /PSYNG/SW_SYSTCD OPTIONAL
*"      ET_AUTHFIL STRUCTURE  /PSYNG/SW_SYSCA OPTIONAL
*"      ET_SWSODORGO STRUCTURE  /PSYNG/SWSODORGO OPTIONAL
*"  EXCEPTIONS
*"      VERSION_NOT_EXIST
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_051'.
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

*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  DATA : lt_miti_text     TYPE TABLE OF /psyng/mc_usertext,
         ls_miti_text     TYPE /psyng/mc_usertext,
         ls_miti_text_dtl TYPE /psyng/mcrvwtxt_tt,
         lt_mcuser        TYPE TABLE OF /psyng/mcuser
          WITH HEADER LINE,
         lt_mcusrgrp        TYPE TABLE OF /psyng/mcusrgrp
          WITH HEADER LINE,
         lt_mcrole        TYPE TABLE OF /psyng/mcrole
          WITH HEADER LINE,
         lt_mccarole        TYPE TABLE OF /psyng/mccarole
          WITH HEADER LINE,
         lt_mccauser        TYPE TABLE OF /psyng/mccauser
          WITH HEADER LINE,
         lt_mitdetails1  TYPE TABLE OF /psyng/mitigation_assignment
             WITH HEADER LINE,
         lt_get_miti_text TYPE STANDARD TABLE OF /psyng/mcrvwtxt
           WITH HEADER LINE.


*EOC UMITTAL PN-5186 : Control Mitigation Deletion
  FIELD-SYMBOLS: <text> TYPE /psyng/texts.

  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = i_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e156(/psyng/sw) WITH i_vrsio RAISING version_not_exist.
  ENDIF.

  SELECT * INTO TABLE et_function FROM /psyng/function
         WHERE function IN it_funid
           AND vrsio     = i_vrsio.

  SELECT * INTO TABLE et_functtran FROM /psyng/functtran
         WHERE functionid IN it_funid
           AND vrsio       = i_vrsio.

  SELECT * INTO TABLE et_faobj FROM /psyng/faobj2
         WHERE vrsio  = i_vrsio
           AND funid IN it_funid.

  SELECT * INTO TABLE et_conflict FROM /psyng/conflict
         WHERE conid IN it_conid
           AND vrsio  = i_vrsio.
  SELECT * INTO TABLE et_conowner FROM /psyng/conowner
         WHERE conid IN it_conid
           AND vrsio  = i_vrsio.

  SELECT * INTO TABLE et_confdet FROM /psyng/confdet
         WHERE conid IN it_conid
           AND vrsio  = i_vrsio.

  SELECT * INTO TABLE et_mchdr FROM /psyng/mchdr
         WHERE contid IN it_contid.

  SELECT * INTO TABLE et_mctran FROM /psyng/mctran
         WHERE contid IN it_contid.

  SELECT * INTO TABLE et_mcrepid FROM /psyng/mcrepid
         WHERE contid IN it_contid.

  SELECT * INTO TABLE et_mcauditor FROM /psyng/mcauditor
         WHERE contid IN it_contid.

  SELECT * INTO TABLE et_mcuser FROM /psyng/mcuser
         WHERE contid IN it_contid
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
           AND    conid  IN it_con1
           AND    userid IN it_usrid1
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
           AND vrsio   = i_vrsio.

  SELECT * INTO TABLE et_mcusrgrp FROM /psyng/mcusrgrp
         WHERE contid IN it_contid
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
           AND conid IN it_con2
           AND class IN it_usrgrp
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
           AND vrsio   = i_vrsio.

  SELECT * INTO TABLE et_mccarole FROM /psyng/mccarole
         WHERE contid IN it_contid
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
           AND swaudid IN it_ca_objid2
           AND agr_name IN it_rol_nam
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
           AND vrsio   = i_vrsio.

*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  SELECT * INTO TABLE et_mcrole FROM /psyng/mcrole
       WHERE contid IN it_contid
         AND conid IN it_con3
         AND agr_name IN it_rol_nam1
         AND vrsio   = i_vrsio.

  SELECT * INTO TABLE et_mcrvwhdr FROM /psyng/mcrvwhdr
       WHERE contid IN it_contid.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion


  SELECT * INTO TABLE et_mccauser FROM /psyng/mccauser
         WHERE contid IN it_contid
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
         AND swaudid IN it_ca_objid
         AND userid  IN it_usrid2
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
         AND vrsio   = i_vrsio.



*BOC UMITTAL PN-5186 : Control Mitigation Deletion
*Get Mitigation Justifcations for all.
  CLEAR : lt_mcuser[],lt_miti_text[],lt_get_miti_text[].
  lt_mcuser[] = et_mcuser[].
  LOOP AT lt_mcuser.
    CLEAR : lt_mitdetails1,lt_mitdetails1[].
    MOVE-CORRESPONDING lt_mcuser TO lt_mitdetails1.
    lt_mitdetails1-type = '1'. "MC User"
    APPEND lt_mitdetails1.
    CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                   EXPORTING
                     if_assignment    = 'X'
                     if_list          = 'X'
                     i_mcid           = lt_mcuser-contid
                     is_assignment    = lt_mitdetails1
                   TABLES
                     et_details      = lt_get_miti_text
                   EXCEPTIONS
                     invalid_input   = 1
                     not_implemented = 2
                     gos_failure     = 3
                     OTHERS          = 4.
    IF sy-subrc EQ 0.
      "Justificatio Text for Mitigation User
      CLEAR ls_miti_text.
      ls_miti_text-contid     = lt_mcuser-contid.
      ls_miti_text-conid      = lt_mcuser-conid.
      ls_miti_text-vrsio      = lt_mcuser-vrsio.
      ls_miti_text-userid     = lt_mcuser-userid.
      ls_miti_text-auditor    = lt_mcuser-auditor.
      ls_miti_text-from_date  = lt_mcuser-from_date.
      ls_miti_text-to_date    = lt_mcuser-to_date.
      ls_miti_text-org_abb    = lt_mcuser-org_abb.
      ls_miti_text_dtl        = lt_get_miti_text[].
      ls_miti_text-mctext     = ls_miti_text_dtl.

      APPEND ls_miti_text TO lt_miti_text.
    ENDIF.
  ENDLOOP.


"Usergroup Assignment
CLEAR : lt_mcusrgrp[],lt_get_miti_text[].
  lt_mcusrgrp[] = et_mcusrgrp[].
  LOOP AT lt_mcusrgrp.

    CLEAR : lt_mitdetails1,lt_mitdetails1[].
    MOVE-CORRESPONDING lt_mcusrgrp TO lt_mitdetails1.
    lt_mitdetails1-type = '2'. "MC User Group"
    APPEND lt_mitdetails1.
    CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                   EXPORTING
                     if_assignment    = 'X'
                     if_list          = 'X'
                     i_mcid           = lt_mcusrgrp-contid
                     is_assignment    = lt_mitdetails1
                   TABLES
                     et_details      = lt_get_miti_text
                   EXCEPTIONS
                     invalid_input   = 1
                     not_implemented = 2
                     gos_failure     = 3
                     OTHERS          = 4.
    IF sy-subrc EQ 0.
      "Justificatio Text for Mitigation User
      CLEAR ls_miti_text.
      ls_miti_text-contid     = lt_mcusrgrp-contid.
      ls_miti_text-conid      = lt_mcusrgrp-conid.
      ls_miti_text-vrsio      = lt_mcusrgrp-vrsio.
      ls_miti_text-class      = lt_mcusrgrp-class.
      ls_miti_text-auditor    = lt_mcusrgrp-auditor.
      ls_miti_text-from_date  = lt_mcusrgrp-from_date.
      ls_miti_text-to_date    = lt_mcusrgrp-to_date.
      ls_miti_text_dtl        = lt_get_miti_text[].
      ls_miti_text-mctext     = ls_miti_text_dtl.

      APPEND ls_miti_text TO lt_miti_text.
    ENDIF.
  ENDLOOP.

"Critical Auth User Assignment
  CLEAR : lt_mccauser[],lt_get_miti_text[].
  lt_mccauser[] = et_mccauser[].
  LOOP AT lt_mccauser.
    CLEAR : lt_mitdetails1,lt_mitdetails1[].
    MOVE-CORRESPONDING lt_mccauser TO lt_mitdetails1.
    lt_mitdetails1-type = '3'. "MC CA User"
    APPEND lt_mitdetails1.
    CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                   EXPORTING
                     if_assignment    = 'X'
                     if_list          = 'X'
                     i_mcid           = lt_mccauser-contid
                     is_assignment    = lt_mitdetails1
                   TABLES
                     et_details      = lt_get_miti_text
                   EXCEPTIONS
                     invalid_input   = 1
                     not_implemented = 2
                     gos_failure     = 3
                     OTHERS          = 4.
    IF sy-subrc EQ 0.
      "Justificatio Text for Mitigation User
      CLEAR ls_miti_text.
      ls_miti_text-contid     = lt_mccauser-contid.
      ls_miti_text-swaudid    = lt_mccauser-swaudid.
      ls_miti_text-vrsio      = lt_mccauser-vrsio.
      ls_miti_text-userid     = lt_mccauser-userid.
      ls_miti_text-auditor    = lt_mccauser-auditor.
      ls_miti_text-from_date  = lt_mccauser-from_date.
      ls_miti_text-to_date    = lt_mccauser-to_date.
      ls_miti_text_dtl        = lt_get_miti_text[].
      ls_miti_text-mctext     = ls_miti_text_dtl.

      APPEND ls_miti_text TO lt_miti_text.
    ENDIF.
  ENDLOOP.



" Role Assignment
  CLEAR : lt_mcrole[],lt_get_miti_text[].
  lt_mcrole[] = et_mcrole[].
  LOOP AT lt_mcrole.
    CLEAR : lt_mitdetails1,lt_mitdetails1[].
    MOVE-CORRESPONDING lt_mcrole TO lt_mitdetails1.
    lt_mitdetails1-type = '4'. "MC Role"
    APPEND lt_mitdetails1.
    CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                   EXPORTING
                     if_assignment    = 'X'
                     if_list          = 'X'
                     i_mcid           = lt_mcrole-contid
                     is_assignment    = lt_mitdetails1
                   TABLES
                     et_details      = lt_get_miti_text
                   EXCEPTIONS
                     invalid_input   = 1
                     not_implemented = 2
                     gos_failure     = 3
                     OTHERS          = 4.
    IF sy-subrc EQ 0.
      "Justificatio Text for Mitigation User
      CLEAR ls_miti_text.
      ls_miti_text-contid     = lt_mcrole-contid.
      ls_miti_text-conid      = lt_mcrole-conid.
      ls_miti_text-vrsio      = lt_mcrole-vrsio.
      ls_miti_text-agr_name   = lt_mcrole-agr_name.
      ls_miti_text-auditor    = lt_mcrole-auditor.
      ls_miti_text-from_date  = lt_mcrole-from_date.
      ls_miti_text-to_date    = lt_mcrole-to_date.
      ls_miti_text_dtl        = lt_get_miti_text[].
      ls_miti_text-mctext     = ls_miti_text_dtl.

      APPEND ls_miti_text TO lt_miti_text.
    ENDIF.
  ENDLOOP.



"Critical Auth Role Assignment
  CLEAR : lt_mccarole[],lt_get_miti_text[].
  lt_mccarole[] = et_mccarole[].
  LOOP AT lt_mccarole.
    CLEAR : lt_mitdetails1,lt_mitdetails1[].
    MOVE-CORRESPONDING lt_mccarole TO lt_mitdetails1.
    lt_mitdetails1-type = '5'. "MC CA Role"
    APPEND lt_mitdetails1.
    CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                   EXPORTING
                     if_assignment    = 'X'
                     if_list          = 'X'
                     i_mcid           = lt_mccarole-contid
                     is_assignment    = lt_mitdetails1
                   TABLES
                     et_details      = lt_get_miti_text
                   EXCEPTIONS
                     invalid_input   = 1
                     not_implemented = 2
                     gos_failure     = 3
                     OTHERS          = 4.
    IF sy-subrc EQ 0.
      "Justificatio Text for Mitigation User
      CLEAR ls_miti_text.
      ls_miti_text-contid     = lt_mccarole-contid.
      ls_miti_text-swaudid    = lt_mccarole-swaudid.
      ls_miti_text-vrsio      = lt_mccarole-vrsio.
      ls_miti_text-agr_name   = lt_mccarole-agr_name.
      ls_miti_text-auditor    = lt_mccarole-auditor.
      ls_miti_text-from_date  = lt_mccarole-from_date.
      ls_miti_text-to_date    = lt_mccarole-to_date.
      ls_miti_text_dtl        = lt_get_miti_text[].
      ls_miti_text-mctext     = ls_miti_text_dtl.

      APPEND ls_miti_text TO lt_miti_text.
    ENDIF.
  ENDLOOP.




  et_user_mit_text = lt_miti_text.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion


  SELECT * INTO TABLE et_critcodes FROM /psyng/critcodes
         WHERE tcode IN it_tcode
           AND vrsio  = i_vrsio.

  SELECT * INTO TABLE et_swaudhdr FROM /psyng/swaudhdr
         WHERE swaudid IN it_audid
           AND vrsio    = i_vrsio.

  SELECT * INTO TABLE et_swaudc FROM /psyng/swaudc2
         WHERE vrsio    = i_vrsio
           AND swaudid IN it_audid.

  SELECT * INTO TABLE et_criroles FROM /psyng/criroles
         WHERE agr_name IN it_agr
           AND vrsio     = i_vrsio.

  SELECT * INTO TABLE et_criprof FROM /psyng/criprof
         WHERE profile IN it_profil
           AND vrsio    = i_vrsio.

  SELECT * INTO TABLE et_cuscon FROM /psyng/sw_cuscon
         WHERE conid IN it_cuscon
           AND vrsio  = i_vrsio.

  SELECT * INTO TABLE et_texts FROM /psyng/texts        "#EC CI_NOFIRST
         WHERE vrsio = i_vrsio
            OR object = 'M'
            ORDER BY line.
* Begin changes by DDHIMAN 03.12.19
  SELECT * INTO TABLE et_swsodorgo FROM /psyng/swsodorgo
          WHERE vrsio = i_vrsio
            AND conid IN it_conid.
* End changes by DDHIMAN 03.12.19

*  LOOP AT et_texts ASSIGNING <text>.
*    CASE <text>-object.
*      WHEN 'F'.         "Functions
*        IF NOT <text>-textname IN it_funid.
*          DELETE et_texts.
*        ENDIF.
*      WHEN 'C'.         "Conflicts
*        IF NOT <text>-textname IN it_conid.
*          DELETE et_texts.
*        ENDIF.
*      WHEN 'M'.         "Mitigating controls
*        IF NOT <text>-textname IN it_contid.
*          DELETE et_texts.
*        ENDIF.
*      WHEN 'T'.         "Critical auths
*        IF NOT <text>-textname IN it_audid.
*          DELETE et_texts.
*        ENDIF.
*      WHEN 'R'.         "Roles
*        IF NOT <text>-textname(4) IN it_agr.
*          DELETE et_texts.
*        ENDIF.
*    ENDCASE.



  LOOP AT et_texts ASSIGNING <text>.
    CASE <text>-object.
      WHEN 'F'.         "Functions
        READ TABLE et_function WITH KEY function = <text>-textname.
        IF sy-subrc <> 0.
          DELETE et_texts WHERE textname = <text>-textname
                                 AND object = 'F'.
        ENDIF.
      WHEN 'C'.         "Conflicts
        READ TABLE et_conflict WITH KEY conid = <text>-textname.
        IF sy-subrc <> 0.
          DELETE et_texts WHERE textname = <text>-textname
                                 AND object = 'C'.
        ENDIF.
      WHEN 'M'.         "Mitigating controls
        READ TABLE et_mchdr WITH KEY contid = <text>-textname.
        IF sy-subrc <> 0.
          DELETE et_texts WHERE textname = <text>-textname
                                 AND object = 'M'.
        ENDIF.
      WHEN 'T'.         "Critical auths
        READ TABLE et_swaudhdr WITH KEY swaudid = <text>-textname.
        IF sy-subrc <> 0.
          DELETE et_texts WHERE textname = <text>-textname
                                 AND object = 'T'.
        ENDIF.
      WHEN 'Q'.         "Critical Roles

        READ TABLE et_criroles WITH KEY agr_name = <text>-textname.
        IF sy-subrc <> 0.
          DELETE et_texts WHERE textname = <text>-textname
                                AND object = 'Q'.
        ENDIF.

      WHEN 'X'.         "Critical Tcodes

        READ TABLE et_critcodes WITH KEY tcode = <text>-textname.
        IF sy-subrc <> 0.
          DELETE et_texts WHERE textname = <text>-textname
                                AND object = 'X'.
        ENDIF.
      WHEN 'P'.         "Critical profiles

        READ TABLE et_criprof WITH KEY profile = <text>-textname.
        IF sy-subrc <> 0.
          DELETE et_texts WHERE textname = <text>-textname
                                AND object = 'P'.
        ENDIF.
    ENDCASE.
  ENDLOOP.

  SELECT * FROM /psyng/sw_syscon
     INTO TABLE et_confil
          WHERE vrsio = i_vrsio
            AND conid IN it_conid.

  SELECT * FROM /psyng/sw_sysfun
     INTO TABLE et_funfil
     WHERE vrsio    = i_vrsio
       AND function IN it_funid.

  SELECT * FROM /psyng/sw_systcd
     INTO TABLE et_tcodefil
          WHERE vrsio = i_vrsio
            AND tcode IN it_tcode.

  SELECT * FROM /psyng/sw_sysca
     INTO TABLE et_authfil
          WHERE vrsio = i_vrsio
            AND swaudid IN it_audid.

  SELECT SINGLE * INTO es_swsodvers FROM /psyng/swsodvers
                WHERE vrsio = i_vrsio.

ENDFUNCTION.
