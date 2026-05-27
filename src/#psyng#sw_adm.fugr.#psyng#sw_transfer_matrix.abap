FUNCTION /psyng/sw_transfer_matrix .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_SWSODVERS) TYPE  /PSYNG/SWSODVERS OPTIONAL
*"     VALUE(IF_TVHEAD) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TFUNCT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TCONID) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TTCODE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TAUDID) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TAGRNM) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TPROF) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TCSCON) TYPE  FLAG OPTIONAL
*"     VALUE(IF_FNFLTR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CNFLTR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CTFLTR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CAFLTR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TORGO) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TEST) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_APPEND) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_DELETE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_MATRIX) TYPE  FLAG OPTIONAL
*"     VALUE(IF_MITIGATION) TYPE  FLAG OPTIONAL
*"     VALUE(IF_MITUSR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_USRGRP) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ASSROL) TYPE  FLAG OPTIONAL
*"     VALUE(IF_AUTUSR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_AUTROL) TYPE  FLAG OPTIONAL
*"     VALUE(I_MIT_TEXT) TYPE  /PSYNG/MC_USERTEXT_TT OPTIONAL
*"  TABLES
*"      IT_FUNCTION STRUCTURE  /PSYNG/FUNCTION OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      IT_CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_CRITCODES STRUCTURE  /PSYNG/CRITCODES OPTIONAL
*"      IT_SWAUDHDR STRUCTURE  /PSYNG/SWAUDHDR OPTIONAL
*"      IT_SWAUDC STRUCTURE  /PSYNG/SWAUDC2 OPTIONAL
*"      IT_CRIROLES STRUCTURE  /PSYNG/CRIROLES OPTIONAL
*"      IT_CRIPROF STRUCTURE  /PSYNG/CRIPROF OPTIONAL
*"      IT_TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      IT_CUSCON STRUCTURE  /PSYNG/SW_CUSCON OPTIONAL
*"      IT_CONOWNER STRUCTURE  /PSYNG/CONOWNER OPTIONAL
*"      IT_CONFIL STRUCTURE  /PSYNG/SW_SYSCON OPTIONAL
*"      IT_FUNFIL STRUCTURE  /PSYNG/SW_SYSFUN OPTIONAL
*"      IT_TCODEFIL STRUCTURE  /PSYNG/SW_SYSTCD OPTIONAL
*"      IT_AUTHFIL STRUCTURE  /PSYNG/SW_SYSCA OPTIONAL
*"      IT_SWSODORGO STRUCTURE  /PSYNG/SWSODORGO OPTIONAL
*"      IT_MCHDR STRUCTURE  /PSYNG/MCHDR OPTIONAL
*"      IT_MCRVWHDR STRUCTURE  /PSYNG/MCRVWHDR OPTIONAL
*"      IT_MCUSER STRUCTURE  /PSYNG/MCUSER OPTIONAL
*"      IT_MCUSRGRP STRUCTURE  /PSYNG/MCUSRGRP OPTIONAL
*"      IT_MCROLE STRUCTURE  /PSYNG/MCROLE OPTIONAL
*"      IT_MCCAROLE STRUCTURE  /PSYNG/MCCAROLE OPTIONAL
*"      IT_MCCAUSER STRUCTURE  /PSYNG/MCCAUSER OPTIONAL
*"      IT_MCTRAN STRUCTURE  /PSYNG/MCTRAN OPTIONAL
*"      IT_MCREPID STRUCTURE  /PSYNG/MCREPID OPTIONAL
*"      IT_MCAUDITOR STRUCTURE  /PSYNG/MCAUDITOR OPTIONAL
*"      IT_MCTEXT STRUCTURE  /PSYNG/MCRVWTXT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_TRANSFER_MATRIX'.
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

  DATA: ls_function       TYPE /psyng/function,
        ls_functtran      TYPE /psyng/functtran,
        ls_faobj          TYPE /psyng/faobj2,
        ls_conflict       TYPE /psyng/conflict,
        ls_confdet        TYPE /psyng/confdet,
        ls_critcodes      TYPE /psyng/critcodes,
        ls_swaudhdr       TYPE /psyng/swaudhdr,
        ls_swaudc         TYPE /psyng/swaudc2,
        ls_criroles       TYPE /psyng/criroles,
        ls_criprof        TYPE /psyng/criprof,
        ls_texts          TYPE /psyng/texts,
        ls_cuscon         TYPE /psyng/sw_cuscon,
        ls_conowner       TYPE /psyng/conowner,
        ls_mchdr          TYPE /psyng/mchdr,
        ls_mcrvwhdr       TYPE /psyng/mcrvwhdr,
        lt_functtran      TYPE TABLE OF /psyng/functtran WITH HEADER
                                                                LINE,
        lt_faobj          TYPE TABLE OF /psyng/faobj2    WITH HEADER
                                                                LINE,
        lt_confdet        TYPE TABLE OF /psyng/confdet   WITH HEADER
                                                                LINE,
        lt_conowner       TYPE TABLE OF /psyng/conowner  WITH HEADER
                                                                LINE,
        lt_texts          TYPE TABLE OF /psyng/texts     WITH HEADER
                                                                LINE,
        lt_vrsio          TYPE TABLE OF /psyng/swsodvers WITH HEADER
                                                                LINE,

        lt_vrsio_new      TYPE TABLE OF /psyng/swsodvers WITH HEADER
                                                                LINE,
        lf_no_auth        TYPE /psyng/bapiflagx,
        l_temp_vdesc      TYPE /psyng/swsodvers-vdesc,
        l_corg_added      TYPE c,
        lt_critcode_count TYPE TABLE OF /psyng/critcodes,
        lt_crirole_count  TYPE TABLE OF /psyng/criroles,
        lt_criprofs_count TYPE TABLE OF /psyng/criprof,
        l_index           TYPE i,
        l_message_v1      TYPE symsgv,
        l_message_v2      TYPE symsgv,
        ls_vrsio_o        TYPE /psyng/swsodvers,
        ls_vrsio_n        TYPE /psyng/swsodvers,
        l_objid           TYPE cdhdr-objectid,
        lt_cdtxt          TYPE TABLE OF cdtxt.
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  DATA : lt_mcuser TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
        lt_mccauser TYPE TABLE OF /psyng/mccauser  WITH HEADER LINE,
        lt_mccarole TYPE TABLE OF /psyng/mccarole  WITH HEADER LINE,
        lt_mcusrgrp TYPE TABLE OF /psyng/mcusrgrp WITH HEADER LINE,
        lt_mcrole TYPE TABLE OF /psyng/mcrole WITH HEADER LINE,
        lt_mcuser_count TYPE TABLE OF /psyng/mituser,
        lt_mcusrgrp_count TYPE TABLE OF /psyng/mcusrgrp ,
        lt_mcrole_count TYPE TABLE OF /psyng/mcrole ,
        lt_mccarole_count TYPE TABLE OF /psyng/mccarole ,
        lt_mccauser_count TYPE TABLE OF /psyng/mccauser .




  DATA: lt_mitdetails1  TYPE TABLE OF /psyng/mitigation_assignment
         WITH HEADER LINE,
        lt_miti_text_t TYPE TABLE OF /psyng/mcrvwtxt,
        ls_miti_text_t TYPE  /psyng/mcrvwtxt,
        lt_miti_text   TYPE TABLE OF solisti1 WITH HEADER LINE,
        ls_user_text   TYPE solisti1,
        lt_get_details     TYPE STANDARD TABLE OF /psyng/mcrvwtxt
        WITH HEADER LINE,
        ls_user_mit_text   TYPE /psyng/mc_usertext,
        lv_flag TYPE flag.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion

* BOC by RGUPTA on 07.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  g_svrsio = i_vrsio.
  g_tvrsio = i_vrsio.

  gt_function[]  = it_function[].
  gt_functtran[] = it_functtran[].
  gt_faobj[]     = it_faobj[].
  gt_conflict[]  = it_conflict[].
  gt_confdet[]   = it_confdet[].
  gt_critcodes[] = it_critcodes[].
  gt_swaudhdr[]  = it_swaudhdr[].
  gt_swaudc[]    = it_swaudc[].
  gt_criroles[]  = it_criroles[].
  gt_criprof[]   = it_criprof[].
  gt_texts[]     = it_texts[].
  gt_cuscon[]    = it_cuscon[].
  gt_conowner[]  = it_conowner[].
  gt_confil[]    = it_confil[].
  gt_funfil[]    = it_funfil[].
  gt_tcodefil[]  = it_tcodefil[].
  gt_authfil[]   = it_authfil[].
  gt_swsodorgo[] = it_swsodorgo[].
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  gt_mchdr[]     =  it_mchdr[].     "Mitigating Controls Header
  gt_mcrvwhdr[]  =  it_mcrvwhdr[].  "Mitigating Controls Review Header
  gt_mcuser[]    =  it_mcuser[].    "Mitigating Users
  gt_mcusrgrp[]  =  it_mcusrgrp[].  "Mitigating User Groups
  gt_mcrole[]    =  it_mcrole[].    "Mitigating Roles
  gt_mccarole[]  =  it_mccarole[].  "Mitigating CA roles
  gt_mccauser[]  =  it_mccauser[].  "Mitigating CA users
  gt_mctran[]    =  it_mctran[].    "Mitigating Transactions
  gt_mcrepid[]   =  it_mcrepid[].   "Mitigating Programs
  gt_mcauditor[] =  it_mcauditor[]. "Mitigating Auditors
  gt_mctext[]    =  it_mctext[].    "Mitigating Texts

*EOC UMITTAL PN-5186 : Control Mitigation Deletion
  gs_swsodvers   = i_swsodvers.

*BOC:HBHALLA (PN-11817) (18/03/25)
*Correcting MANDT field value for function called in RFC Destination.
  gt_function-mandt = sy-mandt.
  gt_functtran-mandt = sy-mandt.
  gt_faobj-mandt = sy-mandt.
  gt_conflict-mandt = sy-mandt.
  gt_confdet-mandt = sy-mandt.
  gt_critcodes-mandt = sy-mandt.
  gt_swaudhdr-mandt = sy-mandt.
  gt_swaudc-mandt = sy-mandt.
  gt_criroles-mandt = sy-mandt.
  gt_criprof-mandt = sy-mandt.
  gt_texts-mandt = sy-mandt.
  gt_cuscon-mandt = sy-mandt.
  gt_conowner-mandt = sy-mandt.
  gt_confil-mandt = sy-mandt.
  gt_funfil-mandt = sy-mandt.
  gt_tcodefil-mandt = sy-mandt.
  gt_authfil-mandt = sy-mandt.
  gt_swsodorgo-mandt = sy-mandt.
  gs_swsodvers-mandt = sy-mandt.
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  gt_mchdr-mandt    = sy-mandt.
  gt_mcrvwhdr-mandt = sy-mandt.
  gt_mcuser-mandt   = sy-mandt.
  gt_mcusrgrp-mandt = sy-mandt.
  gt_mcrole-mandt   = sy-mandt.
  gt_mccarole-mandt = sy-mandt.
  gt_mccauser-mandt = sy-mandt.
  gt_mctran-mandt    = sy-mandt.
  gt_mcrepid-mandt   = sy-mandt.
  gt_mcauditor-mandt = sy-mandt.
  gt_mctext-mandt    = sy-mandt.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion


  MODIFY  gt_function  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_functtran TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_faobj     TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_conflict  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_confdet   TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_critcodes TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_swaudhdr  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_swaudc    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_criroles  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_criprof   TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_texts     TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_cuscon    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_conowner  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_confil    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_funfil    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_tcodefil  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_authfil   TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_swsodorgo TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  MODIFY  gt_mchdr     TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mcrvwhdr  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mcuser    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mcusrgrp  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mcrole    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mccarole  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mccauser  TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mctran    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mcrepid   TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mcauditor TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
  MODIFY  gt_mctext    TRANSPORTING mandt WHERE mandt IS NOT INITIAL.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion

*EOC:HBHALLA (PN-11817) (18/03/25)

  IF if_append EQ 'X'.
    g_append_flag    = 'X'.
  ELSE.
    g_overwrite_flag = 'X'.
  ENDIF.

*-- Check for create authority; Exit if not
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc <> 0.
    MESSAGE s108 WITH text-e01 INTO et_return-message.
    PERFORM fill_log
     TABLES et_return
      USING 'E' et_return-message
            '' '' '' ''.
    EXIT.
  ENDIF.

*--Check existence of target version
  CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
    EXPORTING
      iversio   = g_svrsio
    TABLES
      et_versio = lt_vrsio.
  READ TABLE lt_vrsio INDEX 1.
*--If target version to be deleted completely
*--before transfer new objects
  IF  if_delete EQ 'X'
  AND NOT lt_vrsio[] IS INITIAL.
*   Cannot delete versions 000 or 999; Exit in case
    IF g_tvrsio = '000' OR g_tvrsio = '999'.
      MESSAGE s153 WITH g_tvrsio INTO et_return-message.
      PERFORM fill_log
       TABLES et_return
        USING 'E' et_return-message
              '' '' '' ''.
      EXIT.
    ENDIF.
*--Check authority to delete; Raise error and exit if not
    AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
            ID 'ACTVT' FIELD '06'
            ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc <> 0.
      MESSAGE s108 WITH text-e02 INTO et_return-message.
      PERFORM fill_log
       TABLES et_return
        USING 'E' et_return-message
              '' '' '' ''.
      EXIT.
*--Delete the version completely before transfer
*--For Mitigations, Delete everything only that
*-- which are selected from Selection Screen
    ELSEIF sy-subrc EQ 0.
*--Check authority to delete different objects
*--And raise warning to users
      PERFORM authority_check
       TABLES et_return
        USING g_tvrsio
     CHANGING lf_no_auth.
      IF if_test IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_085'
          EXPORTING
            i_vrsio = g_tvrsio
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
            i_matrix     =  if_matrix     "Matrix checkbox
            i_mitigation =  if_mitigation "Mitigation checkbox
            i_mitusr     =  if_mitusr     "Mitigating Users Checkbox
            i_usrgrp     =  if_usrgrp     "Mitigating User Groups CB
            i_assrol     =  if_assrol     "Mitigating Roles CB
            i_autusr     =  if_autusr     "Mitigating CA roles CB
            i_autrol     =  if_autrol.    "Mitigating CA users CB
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
      ENDIF.
      IF lf_no_auth = 'X'.
        MESSAGE s002 WITH 'Version deleted successfully'(s17)
        'except unauthorized objects'(s14) INTO et_return-message.
      ELSE.
        MESSAGE s002 WITH 'Version completely deleted successfully'(s13)
                                       INTO et_return-message.
      ENDIF.
      PERFORM fill_log
       TABLES et_return
        USING 'S' et_return-message
              '' '' '' ''.
    ENDIF.
  ENDIF.

*--Check existence of target version after "Delete target object before
* Saving" is checked
  IF if_delete EQ 'X'.
    CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
      EXPORTING
        iversio   = g_svrsio
      TABLES
        et_versio = lt_vrsio_new.
    READ TABLE lt_vrsio_new INDEX 1.

    IF lt_vrsio_new[] IS INITIAL
      AND if_tvhead IS INITIAL.
      MOVE text-e31 TO et_return-message.
      PERFORM fill_log
       TABLES et_return
        USING 'E' et_return-message
              '' '' '' ''.
      EXIT.
    ENDIF.
  ENDIF.
*--If version does not exist; Make sure to transfer version header
  IF  lt_vrsio[] IS INITIAL
  AND if_tvhead IS INITIAL.
    MOVE text-e03 TO et_return-message.
    PERFORM fill_log
     TABLES et_return
      USING 'E' et_return-message
            '' '' '' ''.
    EXIT.
  ENDIF.

*--If version is marked as non-editable
  IF NOT lt_vrsio[] IS INITIAL
  AND lt_vrsio-noedit EQ 'X'.
    MOVE text-e04 TO et_return-message.
    PERFORM fill_log
     TABLES et_return
      USING 'W' et_return-message
            '' '' '' ''.
  ENDIF.

*Modify Version header

  IF NOT if_tvhead    IS INITIAL
  AND NOT gs_swsodvers IS INITIAL.
    IF  if_test IS INITIAL.
      l_objid = gs_swsodvers-vrsio.
      SELECT SINGLE * FROM /psyng/swsodvers INTO
        ls_vrsio_o WHERE vrsio = gs_swsodvers-vrsio.
      IF sy-subrc <> 0.
        INSERT /psyng/swsodvers FROM gs_swsodvers.
        ls_vrsio_n = gs_swsodvers.
*---add change document
        CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
          EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = l_current_user "C0700
            planned_change_number   = ' '
            object_change_indicator = 'I'
            planned_or_real_changes = 'R'
            no_change_pointers      = ' '
*           UPD_ICDTXT_VRSIO        = ' '
            n_psyng_swsodvers       = ls_vrsio_n
            o_psyng_swsodvers       = ls_vrsio_o
            upd_psyng_swsodvers     = 'I'
          TABLES
            icdtxt_vrsio            = lt_cdtxt.
      ELSE.
        MODIFY /psyng/swsodvers FROM gs_swsodvers.
        ls_vrsio_n = gs_swsodvers.
        CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
          EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = l_current_user "C0700
            planned_change_number   = ' '
            object_change_indicator = 'U'
            planned_or_real_changes = 'R'
            no_change_pointers      = ' '
*           UPD_ICDTXT_VRSIO        = ' '
            n_psyng_swsodvers       = ls_vrsio_n
            o_psyng_swsodvers       = ls_vrsio_o
            upd_psyng_swsodvers     = 'U'
          TABLES
            icdtxt_vrsio            = lt_cdtxt.
      ENDIF.
      CLEAR: ls_vrsio_n, ls_vrsio_o.
    ENDIF.
    IF g_append_flag EQ 'X'.
      et_return-message = 'Version header added successfully'(s43).
    ELSE.
      et_return-message = 'Version header modified successfully'(s12).
    ENDIF.
    PERFORM fill_log
     TABLES et_return
      USING 'S' et_return-message
            '' '' '' ''.
  ENDIF.

  SORT gt_texts BY textname object spras vrsio line.

**** Remove existing records in case of append.
  IF  g_append_flag EQ 'X'
  AND NOT lt_vrsio[] IS INITIAL.
    IF  if_delete EQ 'X'
    AND if_test   EQ 'X'.
      PERFORM append_only_test.
    ELSE.
      PERFORM append_only.
    ENDIF.
  ENDIF.

*BOC UMITTAL PN-5186 : Control Mitigation Deletion
*-- Transfer Mitigations (Append/Overwrite)
  IF if_mitigation EQ 'X'. "Mitigation Definitions
*    IF if_test IS INITIAL.
    "Mitigation Definitions
    IF NOT gt_mchdr[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      SORT gt_mchdr[].
      LOOP AT gt_mchdr.
        "Mitigation Control Review Header
        READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
          WITH KEY contid = gt_mchdr-contid.
        IF sy-subrc EQ 0.
          "Passing header details
        ENDIF.
        LOOP AT gt_texts INTO lt_texts
          WHERE textname = gt_mchdr-contid
          AND object  = 'M'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.
        IF if_test IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
              EXPORTING
                   is_mchdr             = gt_mchdr
                   if_add_assgn_only    = 'X'
                   is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                    it_texts             = lt_texts
              EXCEPTIONS
                   target_not_specified = 1
                   not_authorized       = 2
                   locked               = 3
                  OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

        ENDIF.
        IF sy-subrc EQ 0
          OR if_test EQ 'X'.

          IF g_append_flag EQ 'X'.
            MOVE 'Mitigating Definitions added successfully'(p11)
                 TO et_return-message.
          ELSE.
            MOVE 'Mitigating Definitions modified successfully'(p12)
                 TO et_return-message.
          ENDIF.
          CLEAR l_message_v1.
          l_message_v1 = gt_mchdr-contid.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o34 l_message_v1 '' ''.
        ENDIF.
      ENDLOOP.
    ENDIF.
    "Mitigating Auditors
    IF NOT gt_mcauditor[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      SORT gt_mcauditor[].
      LOOP AT gt_mcauditor.
        "Mitigation Control Header
        READ TABLE gt_mchdr INTO ls_mchdr
          WITH KEY contid = gt_mcauditor-contid.
        IF sy-subrc EQ 0.
          "Passing header details
        ENDIF.
        "Mitigation Control Review Header
        READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
          WITH KEY contid = gt_mcauditor-contid.
        IF sy-subrc EQ 0.
          "Passing header details
        ENDIF.
        LOOP AT gt_texts INTO lt_texts
          WHERE textname = gt_mcauditor-contid
          AND object  = 'M'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.
        ls_mchdr-contid = gt_mcauditor-contid.
        IF if_test IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
              EXPORTING
                   is_mchdr             = ls_mchdr
                   if_add_assgn_only    = 'X'
                   is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                   it_mcauditor         = gt_mcauditor
*                    it_texts             = lt_texts
              EXCEPTIONS
                   target_not_specified = 1
                   not_authorized       = 2
                   locked               = 3
                  OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

        ENDIF.

        IF sy-subrc EQ 0
        OR if_test  EQ 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Mitigating Auditors added successfully'(s85)
                 TO et_return-message.
          ELSE.
            MOVE 'Mitigating Auditors modified successfully'(s86)
                 TO et_return-message.
          ENDIF.
          CLEAR :l_message_v1.
          l_message_v1 = gt_mcauditor-contid.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o30 l_message_v1 '' ''.
        ENDIF.
      ENDLOOP.
    ENDIF.

    "Mitigating Transactions
    IF NOT gt_mctran[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      SORT gt_mctran[].
      LOOP AT gt_mctran.
        "Mitigation Control Header
        READ TABLE gt_mchdr INTO ls_mchdr
          WITH KEY contid = gt_mctran-contid.
        IF sy-subrc EQ 0.
          "Passing header details
        ENDIF.
        "Mitigation Control Review Header
        READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
          WITH KEY contid = gt_mctran-contid.
        IF sy-subrc EQ 0.
          "Passing header details
        ENDIF.
        LOOP AT gt_texts INTO lt_texts
          WHERE textname = gt_mcauditor-contid
          AND object  = 'M'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.
        ls_mchdr-contid = gt_mctran-contid.
        IF if_test IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
              EXPORTING
                   is_mchdr             = ls_mchdr
                   if_add_assgn_only    = 'X'
                   is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                   it_mctran         = gt_mctran
*                    it_texts             = lt_texts
              EXCEPTIONS
                   target_not_specified = 1
                   not_authorized       = 2
                   locked               = 3
                  OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

        ENDIF.
        IF sy-subrc EQ 0
      OR if_test  EQ 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Mitigating Transactions added successfully'(s87)
                 TO et_return-message.
          ELSE.
            MOVE 'Mitigating Transactions modified successfully'(s88)
                 TO et_return-message.
          ENDIF.
          CLEAR : l_message_v1.
          l_message_v1 = gt_mctran-contid.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o31 l_message_v1 '' ''.
        ENDIF.
      ENDLOOP.

    ENDIF.

    "Mitigating Programs
    IF NOT gt_mcrepid[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      SORT gt_mcrepid[].
      LOOP AT gt_mcrepid.
        "Mitigation Control Header
        READ TABLE gt_mchdr INTO ls_mchdr
          WITH KEY contid = gt_mcrepid-contid.
        IF sy-subrc EQ 0.
          "Passing header details
        ENDIF.
        "Mitigation Control Review Header
        READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
          WITH KEY contid = gt_mcrepid-contid.
        IF sy-subrc EQ 0.
          "Passing header details
        ENDIF.
        LOOP AT gt_texts INTO lt_texts
          WHERE textname = gt_mcrepid-contid
          AND object  = 'M'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.
        ls_mchdr-contid = gt_mcrepid-contid.
        IF if_test IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
              EXPORTING
                   is_mchdr             = ls_mchdr
                   if_add_assgn_only    = 'X'
                   is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                   it_mcrepid         = gt_mcrepid
*                    it_texts          = lt_texts
              EXCEPTIONS
                   target_not_specified = 1
                   not_authorized       = 2
                   locked               = 3
                  OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

        ENDIF.
        IF sy-subrc EQ 0
        OR if_test  EQ 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Mitigating Reports added successfully'(s89)
                 TO et_return-message.
          ELSE.
            MOVE 'Mitigating Reports modified successfully'(s90)
                 TO et_return-message.
          ENDIF.
          CLEAR : l_message_v1.
          l_message_v1 = gt_mcrepid-contid.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o32 l_message_v1 '' ''.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

*--Mitigation User
  IF if_mitusr EQ 'X'.


    IF if_test IS INITIAL.
      TYPES : BEGIN OF ty_mcuser,
                contid TYPE /psyng/contid,
                conid  TYPE /psyng/conflict_id,
                userid TYPE xubname,
                vrsio  TYPE /psyng/sodvrsio,
                org_abb TYPE /psyng/dorg_abb,
              END OF ty_mcuser.
      DATA : lt_mcuser1 TYPE STANDARD TABLE OF ty_mcuser,
             ls_mcuser1 TYPE ty_mcuser.
      RANGES : r_mituser FOR /psyng/mcuser-contid.
*      RANGES : r_mituser1 FOR /psyng/mcuser-conid.
*      RANGES : r_mituser2 FOR /psyng/mcuser-userid.

      IF g_overwrite_flag = 'X'.
        CLEAR : ls_mcuser1,lt_mcuser1[].
        LOOP AT gt_mcuser.
          ls_mcuser1-contid = gt_mcuser-contid.
          ls_mcuser1-conid  = gt_mcuser-conid.
          ls_mcuser1-userid = gt_mcuser-userid.
          ls_mcuser1-vrsio  = gt_mcuser-vrsio.
          ls_mcuser1-org_abb = gt_mcuser-org_abb.
          APPEND ls_mcuser1 TO lt_mcuser1.
        ENDLOOP.

        IF NOT lt_mcuser1 IS INITIAL.
          LOOP AT lt_mcuser1 INTO ls_mcuser1.
            DELETE FROM /psyng/mcuser WHERE contid = ls_mcuser1-contid
                              AND conid  = ls_mcuser1-conid
                              AND userid = ls_mcuser1-userid
                              AND vrsio  = ls_mcuser1-vrsio
                              AND org_abb = ls_mcuser1-org_abb.
            IF sy-subrc EQ 0.
              COMMIT WORK.
            ELSE.
              ROLLBACK WORK.
            ENDIF.
          ENDLOOP.
        ENDIF  .
        IF NOT gt_mcuser[] IS INITIAL.
          r_mituser-sign   = 'I'.
          r_mituser-option = 'EQ'.
          LOOP AT gt_mcuser.
            "Mitigation ID
            r_mituser-low =   gt_mcuser-contid.
            APPEND r_mituser.
          ENDLOOP.
          SORT r_mituser.
          DELETE ADJACENT DUPLICATES FROM r_mituser  COMPARING low.

*BOC UMITTAL PN18732 06/04/2026
*          DELETE FROM /psyng/texts
*          WHERE object = 'M' AND
*                textname IN r_mituser.
*          COMMIT WORK.
*EOC UMITTAL PN18732 06/04/2026
        ENDIF.
      ENDIF.
    ENDIF.
* Mitigation Users
    IF NOT gt_mcuser[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD g_tvrsio
               ID 'Y&SW_CNTID' FIELD ''
               ID 'Y&SW_CONID' FIELD ''
               ID 'Y&SW_BNAME' FIELD ''
               ID 'Y&SW_COMP'  FIELD ''.
      IF sy-subrc = 0.
        lt_mcuser_count[] = gt_mcuser[].
        LOOP AT gt_mcuser.
          "Mitigation Control Header
          READ TABLE gt_mchdr INTO ls_mchdr
            WITH KEY contid = gt_mcuser-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          "Mitigation Control Review Header
          READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
            WITH KEY contid = gt_mcuser-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          LOOP AT gt_texts INTO lt_texts
            WHERE textname = gt_mcuser-contid
            AND object  = 'M'.
            APPEND lt_texts.
            DELETE gt_texts.
          ENDLOOP.
          ls_mchdr-contid = gt_mcuser-contid.
          IF if_test IS INITIAL.
            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr
*                        if_del_assgn_only    = 'X'
                    if_add_assgn_only    = 'X'
                    is_mcrvwhdr          = ls_mcrvwhdr
                TABLES
                    it_mcuser            = gt_mcuser
*                    it_texts             = lt_texts
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                   OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

          ENDIF.
          IF sy-subrc EQ 0
            OR if_test EQ 'X'.

            IF g_append_flag EQ 'X'.
              MOVE 'Mitigation Users added successfully'(s75)
                   TO et_return-message.

            ELSE.
              MOVE 'Mitigation Users modified successfully'(s76)
                   TO et_return-message.

            ENDIF.
            CLEAR : l_message_v1.
            l_message_v1 = gt_mcuser-contid.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                    text-o29 l_message_v1 '' ''.
          ENDIF.


*---->>>> Adjusting Justifications
          CLEAR : lt_mitdetails1.
          CLEAR : lt_mitdetails1[].
          CLEAR : lt_miti_text[].
          MOVE-CORRESPONDING gt_mcuser TO lt_mitdetails1.
          lt_mitdetails1-type = '1'. "MC User"
          APPEND lt_mitdetails1.
*            In case of PULL, read from target and create in local.
          CLEAR : ls_user_mit_text,
                  lt_miti_text_t[].
          READ TABLE i_mit_text
            INTO ls_user_mit_text
           WITH KEY contid    = gt_mcuser-contid
                    conid     = gt_mcuser-conid
                    userid    = gt_mcuser-userid
                    vrsio     = gt_mcuser-vrsio
                    auditor   = gt_mcuser-auditor
                    from_date = gt_mcuser-from_date
                    to_date   = gt_mcuser-to_date
                    org_abb   = gt_mcuser-org_abb.

          IF sy-subrc EQ 0.
            CLEAR : ls_miti_text_t,
                    lt_miti_text_t[],
                    lt_miti_text[].
            lt_miti_text_t = ls_user_mit_text-mctext.
            IF NOT lt_miti_text_t IS INITIAL.
              LOOP AT lt_miti_text_t INTO  ls_miti_text_t.
                lt_miti_text-line = ls_miti_text_t-text.
                APPEND lt_miti_text.
              ENDLOOP.

              IF g_append_flag EQ 'X'.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mcuser-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                OR if_test EQ 'X'.
                  MOVE
              'Mitigation Users Justification added successfully'(s91)
                  TO et_return-message.

                  CLEAR l_message_v1.
                  l_message_v1 = gt_mcuser-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.
                ENDIF.
              ELSE. "Justification Overwrite Case
                "First Delete Jutification.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_delete       = 'X'
                      i_mcid          = gt_mcuser-contid
                      is_assignment   = lt_mitdetails1
*                      TABLES
*                        it_text         = lt_new_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
                  IF sy-subrc <> 0.
                    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                  ENDIF.

*            "Add Justification.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mcuser-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                  OR if_test EQ 'X'.
                  MOVE
           'Mitigation Users Justification modified successfully'(s92)
                 TO et_return-message.
                  CLEAR l_message_v1.
                  l_message_v1 = gt_mcuser-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.
                ENDIF.

              ENDIF. "End of Justification Append/Overwrite Case
            ENDIF.
          ENDIF.
        ENDLOOP.
        gt_mcuser[] = lt_mcuser_count[].
      ELSE.
        MOVE 'Missing authorization to add Mitigating Users'(e26)
        TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.

* Mitigation User Group
  IF if_usrgrp EQ 'X'.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      TYPES : BEGIN OF ty_mcusrgrp,
               contid TYPE /psyng/contid,
               conid  TYPE /psyng/conflict_id,
               class  TYPE xuclass,
               vrsio  TYPE /psyng/sodvrsio,
              END OF ty_mcusrgrp.
      DATA : lt_mcusrgrp1   TYPE STANDARD TABLE OF ty_mcusrgrp,
              ls_mcusrgrp1  TYPE ty_mcusrgrp.
      RANGES : r_mitusrgrp  FOR /psyng/mcusrgrp-contid.

      IF g_overwrite_flag = 'X'.
        CLEAR : ls_mcusrgrp1,lt_mcusrgrp1[].
        LOOP AT gt_mcusrgrp.
          ls_mcusrgrp1-contid = gt_mcusrgrp-contid.
          ls_mcusrgrp1-conid  = gt_mcusrgrp-conid.
          ls_mcusrgrp1-class  = gt_mcusrgrp-class.
          ls_mcusrgrp1-vrsio  = gt_mcusrgrp-vrsio.
          APPEND ls_mcusrgrp1 TO lt_mcusrgrp1.
        ENDLOOP.

        IF NOT lt_mcusrgrp1 IS INITIAL.
          LOOP AT lt_mcusrgrp1 INTO ls_mcusrgrp1.
            DELETE FROM /psyng/mcusrgrp
             WHERE contid = ls_mcusrgrp1-contid
             AND   conid  = ls_mcusrgrp1-conid
             AND   class  = ls_mcusrgrp1-class
             AND   vrsio  = ls_mcusrgrp1-vrsio.
            IF sy-subrc EQ 0.
              COMMIT WORK.
            ELSE.
              ROLLBACK WORK.
            ENDIF.
          ENDLOOP.
        ENDIF  .

        IF NOT gt_mcusrgrp[] IS INITIAL.
          r_mitusrgrp-sign   = 'I'.
          r_mitusrgrp-option = 'EQ'.
          LOOP AT gt_mcusrgrp.
            r_mitusrgrp-low =   gt_mcusrgrp-contid.
            APPEND r_mitusrgrp.
          ENDLOOP.

          SORT r_mitusrgrp.
          DELETE ADJACENT DUPLICATES FROM r_mitusrgrp  COMPARING low.
*BOC UMITTAL PN18732 06/04/2026
*          DELETE FROM /psyng/texts
*          WHERE object = 'M' AND
*                textname IN r_mitusrgrp.
*          COMMIT WORK.
*EOC UMITTAL PN18732 06/04/2026
        ENDIF.
      ENDIF.
    ENDIF.
    IF NOT gt_mcusrgrp[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD g_tvrsio
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
               ID 'Y&SW_CNTID' FIELD ''
               ID 'Y&SW_CONID' FIELD ''
               ID 'Y&SW_CLASS' FIELD ''.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc = 0.

*        IF if_test IS INITIAL.
        lt_mcusrgrp_count[] = gt_mcusrgrp[].
        LOOP AT gt_mcusrgrp.
          "Long Texts
          LOOP AT gt_texts INTO lt_texts
             WHERE textname = gt_mcusrgrp-contid
             AND object  = 'M'.
            APPEND lt_texts.
            DELETE gt_texts.
          ENDLOOP.
          "Header
          READ TABLE gt_mchdr INTO ls_mchdr
            WITH KEY contid = gt_mcusrgrp-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          "Review Header
          READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
            WITH KEY contid = gt_mcusrgrp-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          ls_mchdr-contid = gt_mcusrgrp-contid.
          IF if_test IS INITIAL.
            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr
*                        if_del_assgn_only    = 'X'
                    if_add_assgn_only    = 'X'
                    is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                    it_mcusrgrp             = gt_mcusrgrp
*                    it_texts                = lt_texts
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                   OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

          ENDIF.
          IF sy-subrc EQ 0
            OR if_test EQ 'X'.
            IF g_append_flag EQ 'X'.
              MOVE 'Mitigation User Group added successfully'(s77)
                   TO et_return-message.
            ELSE.
              MOVE 'Mitigation User Group modified successfully'(s78)
                   TO et_return-message.
            ENDIF.
            CLEAR l_message_v1.
            l_message_v1 = gt_mcusrgrp-contid.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                    text-o29 l_message_v1 '' ''.
          ENDIF.



*--->>> Adjusting Jutifications for MC user group
          CLEAR : lt_mitdetails1.
          CLEAR : lt_mitdetails1[].
          CLEAR : lt_miti_text[].
          MOVE-CORRESPONDING gt_mcusrgrp TO lt_mitdetails1.
          lt_mitdetails1-type = '2'. "MC User Group"
          APPEND lt_mitdetails1.
*            In case of PULL, read from target and create in local.
          CLEAR : ls_user_mit_text,
                  lt_miti_text_t[].
          READ TABLE i_mit_text
            INTO ls_user_mit_text
           WITH KEY contid    = gt_mcusrgrp-contid
                    conid     = gt_mcusrgrp-conid
                    class     = gt_mcusrgrp-class
                    vrsio     = gt_mcusrgrp-vrsio
                    auditor   = gt_mcusrgrp-auditor
                    from_date = gt_mcusrgrp-from_date
                    to_date   = gt_mcusrgrp-to_date.

          IF sy-subrc EQ 0.
            CLEAR : ls_miti_text_t,
                    lt_miti_text_t[],
                    lt_miti_text[].
            lt_miti_text_t = ls_user_mit_text-mctext.
            IF NOT lt_miti_text_t IS INITIAL.
              LOOP AT lt_miti_text_t INTO  ls_miti_text_t.
                lt_miti_text-line = ls_miti_text_t-text.
                APPEND lt_miti_text.
              ENDLOOP.

              IF g_append_flag EQ 'X'.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mcusrgrp-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                    OR if_test EQ 'X'.
                  MOVE
         'Mitigation User Group Justification added successfully'(s93)
                   TO et_return-message.
                  CLEAR l_message_v1.
                  l_message_v1 = gt_mcusrgrp-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.

                ENDIF.
              ELSE. "Justification Overwrite Case
                "First Delete Jutification.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_delete       = 'X'
                      i_mcid          = gt_mcusrgrp-contid
                      is_assignment   = lt_mitdetails1
*                      TABLES
*                        it_text         = lt_new_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
                  IF sy-subrc <> 0.
                    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                  ENDIF.

                  "Add Justification.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mcusrgrp-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                  OR if_test EQ 'X'.
                  MOVE
      'Mitigation User Group Justification modified successfully'(s94)
            TO et_return-message.
                  CLEAR l_message_v1.
                  l_message_v1 = gt_mcusrgrp-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.
                ENDIF.
              ENDIF. "End of Justification Append/Overwrite Case
            ENDIF.
          ENDIF.
        ENDLOOP.
        gt_mcusrgrp[] = lt_mcusrgrp_count[].
      ELSE.
        MOVE 'Missing authorization to add Mitigating User Groups'(e27)
        TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.

** Mitigation Roles
  IF if_assrol EQ 'X'.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded

      TYPES : BEGIN OF ty_mcrole,
               contid  TYPE /psyng/contid,
               conid   TYPE /psyng/conflict_id,
               agrname TYPE agrname,
               vrsio   TYPE /psyng/sodvrsio,
             END OF ty_mcrole.
      DATA : lt_mcrole1 TYPE STANDARD TABLE OF ty_mcrole,
             ls_mcrole1 TYPE ty_mcrole.
      RANGES : r_mitrole FOR /psyng/mcrole-contid.
      IF g_overwrite_flag = 'X'.

        LOOP AT gt_mcrole.
          ls_mcrole1-contid      = gt_mcrole-contid.
          ls_mcrole1-conid       = gt_mcrole-conid.
          ls_mcrole1-agrname     = gt_mcrole-agr_name.
          ls_mcrole1-vrsio       = gt_mcrole-vrsio.
          APPEND ls_mcrole1 TO lt_mcrole1.
        ENDLOOP.

        IF NOT lt_mcrole1 IS INITIAL.
          LOOP AT lt_mcrole1 INTO ls_mcrole1.
            DELETE FROM /psyng/mcrole
            WHERE contid   = ls_mcrole1-contid
            AND   conid    = ls_mcrole1-conid
            AND   agr_name = ls_mcrole1-agrname
            AND   vrsio    = ls_mcrole1-vrsio.
            IF sy-subrc EQ 0.
              COMMIT WORK.
            ELSE.
              ROLLBACK WORK.
            ENDIF.
          ENDLOOP.
        ENDIF  .


        IF NOT gt_mcrole[] IS INITIAL.
          r_mitrole-sign   = 'I'.
          r_mitrole-option = 'EQ'.
          LOOP AT gt_mcrole.
            r_mitrole-low =   gt_mcrole-contid.
            APPEND r_mitrole.
          ENDLOOP.

          SORT r_mitrole .
          DELETE ADJACENT DUPLICATES FROM r_mitrole  COMPARING low.
*BOC UMITTAL PN18732 06/04/2026
*          DELETE FROM /psyng/texts
*          WHERE object = 'M' AND
*                textname IN r_mitrole.
*          COMMIT WORK.
*EOC UMITTAL PN18732 06/04/2026
        ENDIF.
      ENDIF.
    ENDIF.
    IF NOT gt_mcrole[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD g_tvrsio
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
               ID 'Y&SW_CNTID' FIELD ''
               ID 'Y&SW_CONID' FIELD ''
               ID 'ACT_GROUP'  FIELD ''.
*--> EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

      IF sy-subrc = 0.

        lt_mcrole_count[] = gt_mcrole[].
        LOOP AT gt_mcrole.
          "Long Text
          LOOP AT gt_texts INTO lt_texts
             WHERE textname = gt_mcrole-contid
             AND object  = 'M'.
            APPEND lt_texts.
            DELETE gt_texts.
          ENDLOOP.
          "Mitigation Header
          READ TABLE gt_mchdr INTO ls_mchdr
            WITH KEY contid = gt_mcrole-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          "Mitigation Review Header
          READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
            WITH KEY contid = gt_mcrole-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          ls_mchdr-contid = gt_mcrole-contid.
          IF if_test IS INITIAL.
            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr
*                        if_del_assgn_only    = 'X'
                    if_add_assgn_only    = 'X'
                    is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                    it_mcrole             = gt_mcrole
*                    it_texts              = lt_texts
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                   OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

          ENDIF.
          IF sy-subrc EQ 0
            OR if_test EQ 'X'.
            IF g_append_flag EQ 'X'.
              MOVE 'Mitigation Roles added successfully'(s79)
                   TO et_return-message.
            ELSE.
              MOVE 'Mitigation Roles modified successfully'(s80)
                   TO et_return-message.
            ENDIF.
            CLEAR l_message_v1.
            l_message_v1 = gt_mcrole-contid.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                    text-o29 l_message_v1 '' ''.
          ENDIF.

*--->>> Adjusting Jutifications for MC Roles
          CLEAR : lt_mitdetails1.
          CLEAR : lt_mitdetails1[].
          CLEAR : lt_miti_text[].
          MOVE-CORRESPONDING gt_mcrole TO lt_mitdetails1.
          lt_mitdetails1-type = '4'. "MC Role"
          APPEND lt_mitdetails1.
*            In case of PULL, read from target and create in local.
          CLEAR : ls_user_mit_text,
                  lt_miti_text_t[].
          READ TABLE i_mit_text
            INTO ls_user_mit_text
           WITH KEY contid    = gt_mcrole-contid
                    conid     = gt_mcrole-conid
                    agr_name  = gt_mcrole-agr_name
                    vrsio     = gt_mcrole-vrsio
                    auditor   = gt_mcrole-auditor
                    from_date = gt_mcrole-from_date
                    to_date   = gt_mcrole-to_date.

          IF sy-subrc EQ 0.
            CLEAR : ls_miti_text_t,
                    lt_miti_text_t[],
                    lt_miti_text[].
            lt_miti_text_t = ls_user_mit_text-mctext.
            IF NOT lt_miti_text_t IS INITIAL.
              LOOP AT lt_miti_text_t INTO  ls_miti_text_t.
                lt_miti_text-line = ls_miti_text_t-text.
                APPEND lt_miti_text.
              ENDLOOP.

              IF g_append_flag EQ 'X'.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mcrole-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                  OR if_test EQ 'X'.
                  MOVE
             'Mitigation Role Justification added successfully'(s95)
                       TO et_return-message.
                  CLEAR l_message_v1.
                  l_message_v1 = gt_mcrole-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.
                ENDIF.
              ELSE. "Justification Overwrite Case
                "First Delete Jutification.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_delete       = 'X'
                      i_mcid          = gt_mcrole-contid
                      is_assignment   = lt_mitdetails1
*                      TABLES
*                        it_text         = lt_new_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
                  IF sy-subrc <> 0.
                    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                  ENDIF.

                  "Add Justification.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mcrole-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                      OR if_test EQ 'X'.
                  MOVE
            'Mitigation Role Justification modified successfully'(s96)
                  TO et_return-message.
                  CLEAR : l_message_v1.
                  l_message_v1 = gt_mcrole-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.

                ENDIF.
              ENDIF. "End of Justification Append/Overwrite Case
            ENDIF.
          ENDIF.
        ENDLOOP.
        gt_mcrole[] = lt_mcrole_count[].
*
      ELSE.
        MOVE 'Missing authorization to add Mitigating Roles'(e28)
        TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.

* Mitigation Critical Auth User
  IF if_autusr EQ 'X'.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      TYPES : BEGIN OF ty_mccauser,
                contid   TYPE /psyng/contid,
                swaudid  TYPE /psyng/swaudid,
                userid   TYPE xubname,
                vrsio    TYPE /psyng/sodvrsio,
              END OF ty_mccauser.
      DATA : lt_mccauser1 TYPE STANDARD TABLE OF ty_mccauser,
             ls_mccauser1 TYPE ty_mccauser.
      RANGES : r_mitcauser  FOR /psyng/mccauser-contid.
      IF g_overwrite_flag = 'X'.
        CLEAR : ls_mccauser1,lt_mccauser1[].
        LOOP AT gt_mccauser.
          ls_mccauser1-contid   = gt_mccauser-contid.
          ls_mccauser1-swaudid  = gt_mccauser-swaudid.
          ls_mccauser1-userid   = gt_mccauser-userid.
          ls_mccauser1-vrsio    = gt_mccauser-vrsio.
          APPEND ls_mccauser1 TO lt_mccauser1.
        ENDLOOP.

        IF NOT lt_mccauser1 IS INITIAL.
          LOOP AT lt_mccauser1 INTO ls_mccauser1.
            DELETE FROM /psyng/mccauser
             WHERE contid = ls_mccauser1-contid
             AND   swaudid  = ls_mccauser1-swaudid
             AND   userid = ls_mccauser1-userid
             AND   vrsio  = ls_mccauser1-vrsio.
            IF sy-subrc EQ 0.
              COMMIT WORK.
            ELSE.
              ROLLBACK WORK.
            ENDIF.
          ENDLOOP.
        ENDIF  .

        IF NOT gt_mccauser[] IS INITIAL.
          r_mitcauser-sign   = 'I'.
          r_mitcauser-option = 'EQ'.
          LOOP AT gt_mccauser.
            r_mitcauser-low =   gt_mccauser-contid.
            APPEND r_mitcauser.
          ENDLOOP.

          SORT r_mitcauser.

          DELETE ADJACENT DUPLICATES FROM r_mitcauser  COMPARING low.
*BOC UMITTAL PN18732 06/04/2026
*          DELETE FROM /psyng/texts
*          WHERE object = 'M' AND
*                textname IN r_mitcauser.
*          COMMIT WORK.
*EOC UMITTAL PN18732 06/04/2026
        ENDIF.
      ENDIF.
    ENDIF.
    IF NOT gt_mccauser[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD g_tvrsio
               ID 'Y&SW_SWAUD' FIELD ''
               ID 'Y&SW_CNTID' FIELD ''
               ID 'Y&SW_BNAME' FIELD ''.

      IF sy-subrc = 0.

        lt_mccauser_count[] = gt_mccauser[].
        LOOP AT gt_mccauser.
          LOOP AT gt_texts INTO lt_texts
             WHERE textname = gt_mccauser-contid
             AND object  = 'M'.
            APPEND lt_texts.
            DELETE gt_texts.
          ENDLOOP.
          READ TABLE gt_mchdr INTO ls_mchdr
            WITH KEY contid = gt_mccauser-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
            WITH KEY contid = gt_mccauser-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          ls_mchdr-contid = gt_mccauser-contid.
          IF if_test IS INITIAL.
            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr
*                        if_del_assgn_only    = 'X'
                    if_add_assgn_only    = 'X'
                    is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                    it_mccauser             = gt_mccauser
*                    it_texts                = lt_texts
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                   OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

          ENDIF.
          IF sy-subrc EQ 0
          OR if_test EQ 'X'.
            IF g_append_flag EQ 'X'.
           MOVE 'Mitigation Critical Auth Users added successfully'(s81)
                     TO et_return-message.
            ELSE.
        MOVE 'Mitigation Critical Auth Users modified successfully'(s82)
                  TO et_return-message.
            ENDIF.
            CLEAR l_message_v1.
            l_message_v1 = gt_mccauser-contid.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                    text-o29 l_message_v1 '' ''.
          ENDIF.

*--->>> Adjusting Jutifications for Critical Users
          CLEAR : lt_mitdetails1.
          CLEAR : lt_mitdetails1[].
          CLEAR : lt_miti_text[].
          MOVE-CORRESPONDING gt_mccauser TO lt_mitdetails1.
          lt_mitdetails1-type = '3'. "MC Cri Auth Users"
          APPEND lt_mitdetails1.
*            In case of PULL, read from target and create in local.
          CLEAR : ls_user_mit_text,
                  lt_miti_text_t[].
          READ TABLE i_mit_text
            INTO ls_user_mit_text
           WITH KEY contid    = gt_mccauser-contid
                    swaudid   = gt_mccauser-swaudid
                    userid    = gt_mccauser-userid
                    vrsio     = gt_mccauser-vrsio
                    auditor   = gt_mccauser-auditor
                    from_date = gt_mccauser-from_date
                    to_date   = gt_mccauser-to_date.

          IF sy-subrc EQ 0.
            CLEAR : ls_miti_text_t,
                    lt_miti_text_t[],
                    lt_miti_text[].
            lt_miti_text_t = ls_user_mit_text-mctext.
            IF lt_miti_text_t IS NOT INITIAL.
              LOOP AT lt_miti_text_t INTO  ls_miti_text_t.
                lt_miti_text-line = ls_miti_text_t-text.
                APPEND lt_miti_text.
              ENDLOOP.

              IF g_append_flag EQ 'X'.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mccauser-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                OR if_test EQ 'X'.
                  MOVE
      'Mitigation Cri Auth User Justification added successfully'(s97)
                        TO et_return-message.
                  CLEAR l_message_v1.
                  l_message_v1 = gt_mccauser-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.

                ENDIF.
              ELSE. "Justification Overwrite Case
                "First Delete Jutification.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_delete       = 'X'
                      i_mcid          = gt_mccauser-contid
                      is_assignment   = lt_mitdetails1
*                      TABLES
*                        it_text         = lt_new_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
                  IF sy-subrc <> 0.
                    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                  ENDIF.

                  "Add Justification.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mccauser-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                 OR if_test EQ 'X'.
                  MOVE
  'Mitigation Cri Auth User  Justification modified successfully'(s98)
            TO et_return-message.
                  CLEAR l_message_v1.
                  l_message_v1 = gt_mccauser-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.

                ENDIF.
              ENDIF. "End of Justification Append/Overwrite Case
            ENDIF.
          ENDIF.
        ENDLOOP.
        gt_mccauser[] = lt_mccauser_count[].

      ELSE.
        MOVE
       'Missing authorization to Mitigating Critical Auth User'(e29)
       TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.
* Mitigation Critical Auth Roles
  IF if_autrol EQ 'X'.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      TYPES : BEGIN OF ty_mccarole,
                contid     TYPE /psyng/contid,
                swaudid    TYPE /psyng/swaudid,
                agr_name   TYPE agr_name,
                vrsio      TYPE /psyng/sodvrsio,
              END OF ty_mccarole.
      DATA : lt_mccarole1 TYPE STANDARD TABLE OF ty_mccarole,
             ls_mccarole1 TYPE ty_mccarole.

      RANGES : r_mitcarole  FOR /psyng/mccarole-contid.
      IF g_overwrite_flag = 'X'.

        CLEAR : ls_mccarole1,lt_mccarole1[].
        LOOP AT gt_mccarole.
          ls_mccarole1-contid   = gt_mccarole-contid.
          ls_mccarole1-swaudid  = gt_mccarole-swaudid.
          ls_mccarole1-agr_name = gt_mccarole-agr_name.
          ls_mccarole1-vrsio    = gt_mccarole-vrsio.
          APPEND ls_mccarole1 TO lt_mccarole1.
        ENDLOOP.

        IF NOT lt_mccarole1 IS INITIAL.
          LOOP AT lt_mccarole1 INTO ls_mccarole1.
            DELETE FROM /psyng/mccarole
              WHERE contid = ls_mccarole1-contid
              AND swaudid  = ls_mccarole1-swaudid
              AND agr_name = ls_mccarole1-agr_name
              AND vrsio    = ls_mccarole1-vrsio.
            IF sy-subrc EQ 0.
              COMMIT WORK.
            ELSE.
              ROLLBACK WORK.
            ENDIF.
          ENDLOOP.
        ENDIF  .



        IF NOT gt_mccarole[] IS INITIAL.
          r_mitcarole-sign   = 'I'.
          r_mitcarole-option = 'EQ'.
          LOOP AT gt_mccarole.
            r_mitcarole-low =   gt_mccarole-contid.
            APPEND r_mitcarole.
          ENDLOOP.

          SORT r_mitcarole.

          DELETE ADJACENT DUPLICATES FROM r_mitcarole  COMPARING low.
*BOC UMITTAL PN18732 06/04/2026
*          DELETE FROM /psyng/texts
*          WHERE object = 'M' AND
*                textname IN r_mitcarole.
*          COMMIT WORK.
*EOC UMITTAL PN18732 06/04/2026
        ENDIF.
      ENDIF.
    ENDIF.
    IF NOT gt_mccarole[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD g_tvrsio
               ID 'Y&SW_SWAUD' FIELD ''
               ID 'Y&SW_CNTID' FIELD ''
               ID 'ACT_GROUP'  FIELD ''.
      IF sy-subrc = 0.

        lt_mccarole_count[] = gt_mccarole[].
        LOOP AT gt_mccarole.

          LOOP AT gt_texts INTO lt_texts
             WHERE textname = gt_mccarole-contid
             AND object  = 'M'.
            APPEND lt_texts.
            DELETE gt_texts.
          ENDLOOP.
          READ TABLE gt_mchdr INTO ls_mchdr
            WITH KEY contid = gt_mccarole-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          READ TABLE gt_mcrvwhdr INTO ls_mcrvwhdr
            WITH KEY contid = gt_mccarole-contid.
          IF sy-subrc EQ 0.
            "Passing header details
          ENDIF.
          ls_mchdr-contid = gt_mccarole-contid.
          IF if_test IS INITIAL.
            CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
               EXPORTING
                    is_mchdr             = ls_mchdr
*                        if_del_assgn_only    = 'X'
                    if_add_assgn_only    = 'X'
                    is_mcrvwhdr          = ls_mcrvwhdr
               TABLES
                    it_mccarole             = gt_mccarole
*                    it_texts                = lt_texts
               EXCEPTIONS
                    target_not_specified = 1
                    not_authorized       = 2
                    locked               = 3
                   OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
          ENDIF.
          IF sy-subrc EQ 0
          OR if_test EQ 'X'.

            IF g_append_flag EQ 'X'.
            MOVE 'Mitigation Critical Auth Role added successfully'(s83)
                 TO et_return-message.
            ELSE.
         MOVE 'Mitigation Critical Auth Role modified successfully'(s84)
                 TO et_return-message.
            ENDIF.
            CLEAR : l_message_v1.
            l_message_v1 = gt_mccarole-contid.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                    text-o29 l_message_v1 '' ''.
          ENDIF.


*--->>> Adjusting Jutifications for Critical Auth Roles
          CLEAR : lt_mitdetails1.
          CLEAR : lt_mitdetails1[].
          CLEAR : lt_miti_text[].
          MOVE-CORRESPONDING gt_mccarole TO lt_mitdetails1.
          lt_mitdetails1-type = '5'. "MC Cri Auth Role"
          APPEND lt_mitdetails1.
*            In case of PULL, read from target and create in local.
          CLEAR : ls_user_mit_text,
                  lt_miti_text_t[].
          READ TABLE i_mit_text
            INTO ls_user_mit_text
           WITH KEY contid    = gt_mccarole-contid
                    swaudid   = gt_mccarole-swaudid
                    agr_name  = gt_mccarole-agr_name
                    vrsio     = gt_mccarole-vrsio
                    auditor   = gt_mccarole-auditor
                    from_date = gt_mccarole-from_date
                    to_date   = gt_mccarole-to_date.

          IF sy-subrc EQ 0.
            CLEAR : ls_miti_text_t,
                    lt_miti_text_t[],
                    lt_miti_text[].
            lt_miti_text_t = ls_user_mit_text-mctext.
            IF NOT lt_miti_text_t IS INITIAL.
              LOOP AT lt_miti_text_t INTO  ls_miti_text_t.
                lt_miti_text-line = ls_miti_text_t-text.
                APPEND lt_miti_text.
              ENDLOOP.
              IF g_append_flag EQ 'X'.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mccarole-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                    OR if_test EQ 'X'.
                  MOVE
      'Mitigation Cri Auth Role Justification added successfully'(s99)
                     TO et_return-message.

                  CLEAR : l_message_v1.
                  l_message_v1 = gt_mccarole-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.
                ENDIF.
              ELSE. "Justification Overwrite Case
                "First Delete Jutification.
                IF if_test IS INITIAL.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_delete       = 'X'
                      i_mcid          = gt_mccarole-contid
                      is_assignment   = lt_mitdetails1
*                      TABLES
*                        it_text         = lt_new_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
                  IF sy-subrc <> 0.
                    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                  ENDIF.

                  "Add Justification.
                  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
                    EXPORTING
                      if_assignment   = 'X'
                      if_add          = 'X'
                      i_mcid          = gt_mccarole-contid
                      is_assignment   = lt_mitdetails1
                    TABLES
                      it_text         = lt_miti_text
                    EXCEPTIONS
                      invalid_input   = 1
                      not_implemented = 2
                      gos_failure     = 3
                      OTHERS          = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty
  NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

                ENDIF.
                IF sy-subrc EQ 0
                    OR if_test EQ 'X'.
                  MOVE
   'Mitigation Cri Auth Role Justification modified successfully'(p10)
             TO et_return-message.
                  CLEAR l_message_v1.
                  l_message_v1 = gt_mccarole-contid.
                  PERFORM fill_log
                   TABLES et_return
                    USING 'S' et_return-message
                          text-o33 l_message_v1 '' ''.

                ENDIF.
              ENDIF. "End of Justification Append/Overwrite Case
            ENDIF.
          ENDIF.
        ENDLOOP.
        gt_mccarole[] = lt_mccarole_count[].

      ELSE.
        MOVE
  'Missing authorization to add Mitigation Critical Auth Roles'(e30)
      TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
*-- Transfer functions
*-- Function header
  IF if_tfunct EQ 'X'.

    ls_function-vrsio      = g_tvrsio.
    ls_function-create_dat = sy-datum.
    ls_function-create_tim = sy-uzeit.
    ls_function-create_usr = l_current_user. "C0700

    CLEAR: ls_function-change_dat, ls_function-change_tim,
           ls_function-change_usr.
    IF g_overwrite_flag = 'X'.
      MODIFY gt_function FROM ls_function
      TRANSPORTING vrsio create_dat create_tim create_usr change_dat
                         change_tim change_usr
            WHERE vrsio = g_tvrsio.
    ENDIF.

* Function objects
    ls_faobj-vrsio      = g_tvrsio.
    ls_faobj-create_dat = sy-datum.
    ls_faobj-create_tim = sy-uzeit.
    ls_faobj-create_usr = l_current_user. "C0700

    CLEAR: ls_faobj-change_dat, ls_faobj-change_tim, ls_faobj-change_usr
    .
    IF g_overwrite_flag = 'X'.
      MODIFY gt_faobj FROM ls_faobj
      TRANSPORTING vrsio create_dat create_tim create_usr change_dat
                         change_tim change_usr
            WHERE vrsio = g_tvrsio.
    ENDIF.
  ENDIF.

  RANGES : r_funid FOR /psyng/function-function.
  IF if_tfunct EQ 'X'.
** Actual Upload not test
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      IF g_overwrite_flag = 'X'.
        IF NOT gt_function[] IS INITIAL.
          REFRESH : r_funid.
          r_funid-sign   = 'I'.
          r_funid-option = 'EQ'.
          LOOP AT gt_function.
            r_funid-low = gt_function-function.
            APPEND r_funid.
          ENDLOOP.
          DELETE FROM /psyng/function
          WHERE vrsio = g_tvrsio AND
                function IN r_funid.
          DELETE FROM /psyng/functtran
          WHERE vrsio = g_tvrsio AND
                functionid IN r_funid.
          DELETE FROM /psyng/faobj2
          WHERE vrsio = g_tvrsio AND
                funid IN r_funid.
          DELETE FROM /psyng/texts
          WHERE vrsio  = g_tvrsio AND
                object = 'O' AND
                textname IN r_funid.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.
*--
    LOOP AT gt_function INTO ls_function.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
            ID 'ACTVT' FIELD '01'
            ID 'Y&SW_VRSIO' FIELD g_tvrsio
            ID 'Y&SW_FUNCT' FIELD ls_function-function.
      IF sy-subrc NE 0.
        MOVE 'Missing authorization to add Function Objects'(e12)
              TO et_return-message.
        l_message_v1 = ls_function-function.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                text-o02 l_message_v1 '' ''.

        DELETE gt_function INDEX l_index.
        CLEAR l_index.
      ELSE.
        LOOP AT gt_functtran INTO lt_functtran
                WHERE functionid = ls_function-function.
          APPEND lt_functtran.
        ENDLOOP.

        LOOP AT gt_faobj INTO lt_faobj WHERE funid =
        ls_function-function.
          APPEND lt_faobj.
        ENDLOOP.

        LOOP AT gt_texts INTO lt_texts
                WHERE textname = ls_function-function AND
                      object   = 'F'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

** Actual Upload not test
        IF if_test IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = ls_function
              i_vrsio                 = g_tvrsio
              flag                    = g_append_flag
            TABLES
              texts                   = lt_texts
              functtran               = lt_functtran
              faobj                   = lt_faobj
            EXCEPTIONS
              target_not_specified    = 1
              not_authorized          = 2
              function_already_exists = 3
              locked                  = 4
              OTHERS                  = 5.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'User did not specify target mitigation control'.
              WHEN 2.
                MESSAGE s002(/psyng/sw)
        WITH 'User not authorized to create new mitigation control'.
              WHEN 3.
                MESSAGE s002(/psyng/sw)
             WITH 'Mitigation control is locked'.
              WHEN 4.
                MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
              WHEN 5.
                MESSAGE s002(/psyng/sw) WITH 'System failure'.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)
        ENDIF.
        IF sy-subrc EQ 0
        OR if_test  EQ 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Function Objects added successfully'(s01)
            TO et_return-message.
          ELSE.
            MOVE 'Function Objects modified successfully'(s44)
            TO et_return-message.
          ENDIF.
          l_message_v1 = ls_function-function.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o02 l_message_v1 '' ''.
        ENDIF.
      ENDIF.
      REFRESH: lt_functtran, lt_faobj, lt_texts.
    ENDLOOP.
  ENDIF.

  IF if_tconid EQ 'X'.
** Actual Upload not test
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      RANGES : r_conid FOR /psyng/conflict-conid.
      IF g_overwrite_flag = 'X'.
        IF NOT gt_conflict[] IS INITIAL.
          REFRESH : r_conid.
          r_conid-sign   = 'I'.
          r_conid-option = 'EQ'.
          LOOP AT gt_conflict.
            r_conid-low = gt_conflict-conid.
            APPEND r_conid.
          ENDLOOP.
          DELETE FROM /psyng/conflict
          WHERE vrsio = g_tvrsio AND
                conid IN r_conid.
          DELETE FROM /psyng/confdet
          WHERE vrsio = g_tvrsio AND
                conid IN r_conid.
          DELETE FROM /psyng/conowner
          WHERE vrsio = g_tvrsio AND
                conid IN r_conid.
          DELETE FROM /psyng/texts
          WHERE vrsio  = g_tvrsio AND
                object = 'C' AND
                textname IN r_conid.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.
*--
    LOOP AT gt_conflict INTO ls_conflict.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_CONID' FIELD ls_conflict-conid
               ID 'Y&SW_VRSIO' FIELD g_tvrsio.
      IF sy-subrc NE 0.
        MOVE 'Missing authorization to add Conflict Objects'(e13)
               TO et_return-message.
        l_message_v1 = ls_conflict-conid.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                text-o03 l_message_v1 '' ''.
        DELETE gt_conflict INDEX l_index.
        CLEAR l_index.
      ELSE.
        LOOP AT gt_confdet INTO lt_confdet
                WHERE conid = ls_conflict-conid.
          APPEND lt_confdet.
        ENDLOOP.

        LOOP AT gt_conowner INTO lt_conowner
                WHERE conid = ls_conflict-conid.
          APPEND lt_conowner.
        ENDLOOP.

        LOOP AT gt_texts INTO lt_texts WHERE
          textname = ls_conflict-conid
          AND   object   = 'C'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

** Actual Upload not test
        IF if_test IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
            EXPORTING
              wa_conflict           = ls_conflict
              i_vrsio               = g_tvrsio
              flag                  = g_append_flag
            TABLES
              texts                 = lt_texts
              confdet               = lt_confdet
              conowner              = lt_conowner
            EXCEPTIONS
              target_not_specified  = 1
              target_already_exists = 2
              not_authorized        = 3
              locked                = 4
              OTHERS                = 5.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'User did not specify target mitigation control'.
              WHEN 2.
                MESSAGE s002(/psyng/sw)
        WITH 'User not authorized to create new mitigation control'.
              WHEN 3.
                MESSAGE s002(/psyng/sw)
             WITH 'Mitigation control is locked'.
              WHEN 4.
                MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
              WHEN 5.
                MESSAGE s002(/psyng/sw) WITH 'System failure'.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)
        ENDIF.
        IF sy-subrc = 0
        OR if_test = 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Conflict Objects added successfully'(s02)
            TO et_return-message.
          ELSE.
            MOVE 'Conflict Objects modified successfully'(s45)
            TO et_return-message.
          ENDIF.
          l_message_v1 = ls_conflict-conid.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o03 l_message_v1 '' ''.
        ENDIF.
      ENDIF.
      REFRESH: lt_confdet, lt_conowner, lt_texts.
    ENDLOOP.
  ENDIF.


  IF if_ttcode EQ 'X'.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      RANGES : r_tcode FOR /psyng/critcodes-tcode.
      IF g_overwrite_flag = 'X'.
        IF NOT gt_critcodes[] IS INITIAL.
          r_tcode-sign   = 'I'.
          r_tcode-option = 'EQ'.
          LOOP AT gt_critcodes.
            r_tcode-low =   gt_critcodes-tcode.
            APPEND r_tcode.
          ENDLOOP.
          DELETE FROM /psyng/critcodes
          WHERE vrsio = g_tvrsio AND tcode IN r_tcode.
          DELETE FROM /psyng/texts
          WHERE object = 'X' AND
                textname IN r_tcode.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.
* Critical TCodes
    IF NOT gt_critcodes[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD g_tvrsio.
      IF sy-subrc = 0.
        LOOP AT gt_texts INTO lt_texts WHERE object  = 'X'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.
        IF if_test IS INITIAL.
          lt_critcode_count[] = gt_critcodes[].
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_TCODES'
            EXPORTING
              i_vrsio                  = g_tvrsio
              append_flag              = g_append_flag
            TABLES
              critcodes                = gt_critcodes
              texts                    = lt_texts
            EXCEPTIONS
              not_authorized_to_import = 1
              empty_list_provided      = 2
OTHERS                   = 3.                    "#EC SAST_CI_GEN_CHECK
          "(++)BOC UMITTAL SE VF scan-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          "(++)EOC UMITTAL SE VF scan-25/11/2024.
          gt_critcodes[] = lt_critcode_count[].
        ENDIF.
        IF sy-subrc EQ 0
        OR if_test  EQ 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Critical Transaction added successfully'(s03)
                 TO et_return-message.
          ELSE.
            MOVE 'Critical Transaction modified successfully'(s46)
                 TO et_return-message.
          ENDIF.
          SORT gt_critcodes[].
          LOOP AT gt_critcodes.
            l_message_v1 = gt_critcodes-tcode.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                    text-o01 l_message_v1 '' ''.
          ENDLOOP.
        ENDIF.
      ELSE.
        MOVE 'Missing authorization to add Critical Transactions'(e14)
        TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.

*---Critical authorization header
  IF if_taudid EQ 'X'.
    DATA :
      lt_swaudc LIKE TABLE OF gt_swaudc.
*-- Delete the previous versions of the records that are currently
*   being uploaded
    RANGES : r_swaudid FOR gt_swaudc-swaudid.
    IF if_test IS INITIAL.
      IF g_overwrite_flag = 'X'.
        IF NOT gt_swaudc[] IS INITIAL.
          r_swaudid-sign   = 'I'.
          r_swaudid-option = 'EQ'.
          LOOP AT gt_swaudc.
            r_swaudid-low = gt_swaudc-swaudid.
            APPEND  r_swaudid.
          ENDLOOP.
          DELETE FROM /psyng/swaudhdr
          WHERE vrsio = g_tvrsio AND swaudid IN r_swaudid.
          DELETE FROM /psyng/swaudc2
          WHERE vrsio = g_tvrsio AND swaudid IN r_swaudid.
          DELETE FROM /psyng/texts
          WHERE object = 'T' AND
                textname IN r_swaudid.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.

    LOOP AT gt_swaudhdr.
      l_index = sy-tabix.
      FREE : lt_swaudc, lt_texts.
      gt_swaudhdr-vrsio = g_tvrsio.
      AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
          ID 'ACTVT' FIELD '01'
          ID 'Y&SW_VRSIO' FIELD g_tvrsio
          ID 'Y&SW_AUTID' FIELD gt_swaudhdr-swaudid.
      IF sy-subrc NE 0.
        MOVE 'Missing authorization to add Critical Authorization'(e15)
            TO et_return-message.
        l_message_v1 = gt_swaudhdr-swaudid.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                text-o04 l_message_v1 '' ''.

        DELETE gt_swaudhdr INDEX l_index.
        CLEAR l_index.
      ELSE.

        LOOP AT gt_swaudc WHERE swaudid = gt_swaudhdr-swaudid.
          gt_swaudc-vrsio = g_tvrsio.
          APPEND gt_swaudc TO lt_swaudc.
        ENDLOOP.
        LOOP AT gt_texts INTO lt_texts
                  WHERE textname = gt_swaudhdr-swaudid AND
                        object   = 'T'.
          lt_texts-vrsio = g_tvrsio.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.


        IF if_test IS INITIAL.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
            EXPORTING
              wa_swaudid            = gt_swaudhdr
              i_vrsio               = g_tvrsio
              flag                  = g_append_flag
            TABLES
              texts                 = lt_texts
              swaudc2               = lt_swaudc
            EXCEPTIONS
              target_not_specified  = 1
              not_authorized        = 2
              authid_already_exists = 3
OTHERS                = 4.                       "#EC SAST_CI_GEN_CHECK
          "(++)BOC UMITTAL SE VF scan-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          "(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
        IF sy-subrc = 0
        OR if_test  = 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Critical Authorization added successfully'(s04)
            TO et_return-message.
          ELSE.
            MOVE 'Critical Authorization modified successfully'(s47)
            TO et_return-message.
          ENDIF.
          l_message_v1 = gt_swaudhdr-swaudid.
          PERFORM fill_log
           TABLES et_return
            USING 'S' et_return-message
                  text-o04 l_message_v1 '' ''.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF if_tagrnm EQ 'X'.
* Critical roles
    CLEAR lt_texts.
    REFRESH lt_texts.

    IF NOT gt_criroles[] IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      RANGES: r_role FOR /psyng/criroles-agr_name.
      IF if_test IS INITIAL.
        IF g_overwrite_flag = 'X'.
          IF NOT gt_criroles[] IS INITIAL.
            r_role-sign   = 'I'.
            r_role-option = 'EQ'.
            LOOP AT gt_criroles.
              r_role-low = gt_criroles-agr_name.
              APPEND r_role.
            ENDLOOP.
            DELETE FROM /psyng/criroles
            WHERE vrsio = g_tvrsio AND agr_name IN r_role.
            DELETE FROM /psyng/texts
            WHERE object = 'Q' AND
                  textname IN r_role.
            COMMIT WORK.
          ENDIF.
        ENDIF.
      ENDIF.

      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD g_tvrsio.
      IF sy-subrc = 0.
        LOOP AT gt_texts INTO lt_texts WHERE object  = 'Q'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

        IF if_test IS INITIAL.
          lt_crirole_count[] = gt_criroles[].
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_ROLES'
            EXPORTING
              i_vrsio             = g_tvrsio
              append_flag         = g_append_flag
            TABLES
              criroles            = gt_criroles
              texts               = lt_texts
            EXCEPTIONS
              empty_list_provided = 1
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
          "(++)BOC UMITTAL SE VF scan-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          "(++)EOC UMITTAL SE VF scan-25/11/2024.
          gt_criroles[] = lt_crirole_count[].
        ENDIF.
        IF sy-subrc EQ 0
        OR if_test  EQ 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Critical Role added successfully'(s05)
                TO et_return-message.
          ELSE.
            MOVE 'Critical Role modified successfully'(s48)
                TO et_return-message.
          ENDIF.
          SORT gt_criroles[].
          LOOP AT gt_criroles.
            l_message_v1 = gt_criroles-agr_name.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                   text-o16 l_message_v1 '' ''.
          ENDLOOP.
        ENDIF.
      ELSE.
        MOVE 'Missing authorization to add Critical Roles'(e16)
                TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.
*----Critical profiles
  IF if_tprof EQ 'X'.
*-- Delete the previous versions of the records that are currently
*   being uploaded
    RANGES : r_profile FOR /psyng/criprof-profile.

    IF if_test IS INITIAL.
      IF g_overwrite_flag = 'X'.
        IF NOT gt_criprof[] IS INITIAL.
          r_profile-sign   = 'I'.
          r_profile-option = 'EQ'.
          LOOP AT gt_criprof.
            r_profile-low = gt_criprof-profile.
            APPEND r_profile.
          ENDLOOP.
          DELETE FROM /psyng/criprof
          WHERE vrsio = g_tvrsio AND profile IN r_profile.
          DELETE FROM /psyng/texts
          WHERE object = 'P' AND
                textname IN r_profile.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT gt_criprof[] IS INITIAL.
      CLEAR lt_texts.
      REFRESH lt_texts.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
              ID 'ACTVT' FIELD '01'
              ID 'Y&SW_VRSIO' FIELD g_tvrsio.
      IF sy-subrc = 0.
        LOOP AT gt_texts INTO lt_texts WHERE object  = 'P'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

        IF if_test IS INITIAL.
          lt_criprofs_count[] = gt_criprof[].
*- Make Actual DB changes
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_PROFILES'
            EXPORTING
              i_vrsio             = g_tvrsio
              append_flag         = g_append_flag
            TABLES
              criprof             = gt_criprof
              texts               = lt_texts
            EXCEPTIONS
              empty_list_provided = 1
              OTHERS              = 2.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Empty List Provided'.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)
          gt_criprof[] = lt_criprofs_count[].
        ENDIF.
        IF sy-subrc EQ 0
        OR if_test  EQ 'X'.
          IF g_append_flag EQ 'X'.
            MOVE 'Critical Profile added successfully'(s06)
                TO et_return-message.
          ELSE.
            MOVE 'Critical Profile modified successfully'(s49)
                TO et_return-message.
          ENDIF.
          SORT gt_criprof[].
          LOOP AT gt_criprof.
            l_message_v1 = gt_criprof-profile.
            PERFORM fill_log
             TABLES et_return
              USING 'S' et_return-message
                    text-o17 l_message_v1 '' ''.
          ENDLOOP.
        ENDIF.
      ELSE.
        MOVE 'Missing authorization to add Critical Profiles'(e17)
            TO et_return-message.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                '' '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.
* All Texts
********************************************************
  DATA : lt_text_keys LIKE TABLE OF gt_texts WITH HEADER LINE.
  IF if_test IS INITIAL.
    IF NOT gt_texts[] IS INITIAL.
*--We'll delete all lines of texts for the keys for which
*  we have new texts.  This is to avoid if you copy a text of 5 lines to
*  a target with a text of 10 lines, lines 5 to 10 of the target remain

      lt_text_keys[] = gt_texts[].
      SORT lt_text_keys BY textname object vrsio.
      DELETE ADJACENT DUPLICATES FROM lt_text_keys
      COMPARING textname object vrsio.
      LOOP AT lt_text_keys.
        DELETE FROM /psyng/texts  WHERE             "#EC CI_IMUD_NESTED
              textname = lt_text_keys-textname AND
              object = lt_text_keys-object AND
              vrsio = lt_text_keys-vrsio.
      ENDLOOP.
      COMMIT WORK.
      MODIFY /psyng/texts FROM TABLE gt_texts.
    ENDIF.
  ENDIF.

  IF if_tcscon EQ 'X'.
* Custom conflicts
    ls_cuscon-vrsio = g_tvrsio.
    ls_cuscon-create_usr = l_current_user. "C0700
    ls_cuscon-create_dat = sy-datum.
    ls_cuscon-create_tim = sy-uzeit.
    IF g_overwrite_flag = 'X'.
      MODIFY gt_cuscon FROM ls_cuscon
      TRANSPORTING vrsio create_usr create_dat create_tim
             WHERE vrsio = g_tvrsio.
    ENDIF.
    LOOP AT gt_cuscon.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                 ID 'ACTVT' FIELD '01'
                 ID 'Y&SW_CONID' FIELD gt_cuscon-conid
                 ID 'Y&SW_VRSIO' FIELD g_tvrsio.
      IF sy-subrc NE 0.
        MOVE 'Missing authorization to add Custom Conflict'(e18)
        TO et_return-message.
        l_message_v1 = gt_cuscon-conid.
        PERFORM fill_log
         TABLES et_return
          USING 'E' et_return-message
                text-o05 l_message_v1 '' ''.
        DELETE gt_cuscon.
      ENDIF.
    ENDLOOP.

    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      IF g_overwrite_flag = 'X'.
        IF NOT r_conid[] IS INITIAL.
          DELETE FROM /psyng/sw_cuscon
          WHERE vrsio = g_tvrsio AND
                conid IN r_conid.
          COMMIT WORK.
        ENDIF.
      ENDIF.
      MODIFY /psyng/sw_cuscon FROM TABLE gt_cuscon.
      COMMIT WORK.
    ENDIF.
    LOOP AT gt_cuscon.
      IF g_append_flag EQ 'X'.
        MOVE 'Custom Conflict added successfully'(s07)
             TO et_return-message.
      ELSE.
        MOVE 'Custom Conflict modified successfully'(s50)
             TO et_return-message.
      ENDIF.
      l_message_v1 = gt_cuscon-conid.
      PERFORM fill_log
       TABLES et_return
        USING 'S' et_return-message
              text-o05 l_message_v1 '' ''.
    ENDLOOP.
  ENDIF.

*-- Transfer conflict filters
  IF  if_cnfltr EQ 'X'
  AND NOT gt_confil[] IS INITIAL.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      REFRESH r_conid.
      IF g_overwrite_flag = 'X'.
        REFRESH : r_conid.
        r_conid-sign   = 'I'.
        r_conid-option = 'EQ'.
        LOOP AT gt_confil.
          r_conid-low = gt_confil-conid.
          APPEND r_conid.
        ENDLOOP.
        DELETE FROM /psyng/sw_syscon
        WHERE vrsio = g_tvrsio AND
              conid IN r_conid.
        COMMIT WORK.
      ENDIF.
      MODIFY /psyng/sw_syscon FROM TABLE gt_confil[].
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test  EQ 'X'.
      COMMIT WORK.
      IF g_append_flag EQ 'X'.
        MOVE 'Conflict system filters added successfully'(s08)
            TO et_return-message.
      ELSE.
        MOVE 'Conflict system filters modified successfully'(s51)
            TO et_return-message.
      ENDIF.
      SORT gt_confil[].
      LOOP AT gt_confil.
        l_message_v1 = gt_confil-conid.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o18 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
  ENDIF.

*-- Transfer function filters
  IF  if_fnfltr EQ 'X'
  AND NOT gt_funfil[] IS INITIAL.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      IF g_overwrite_flag = 'X'.
        REFRESH : r_funid.
        r_funid-sign   = 'I'.
        r_funid-option = 'EQ'.
        LOOP AT gt_funfil.
          r_funid-low = gt_funfil-function.
          APPEND r_funid.
        ENDLOOP.
        DELETE FROM /psyng/sw_sysfun
        WHERE vrsio = g_tvrsio AND
              function IN r_funid.
        COMMIT WORK.
      ENDIF.
      MODIFY /psyng/sw_sysfun FROM TABLE gt_funfil[].
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test  EQ 'X'.
      COMMIT WORK.
      IF g_append_flag EQ 'X'.
        MOVE 'Function system filters added successfully'(s09)
            TO et_return-message.
      ELSE.
        MOVE 'Function system filters modified successfully'(s52)
            TO et_return-message.
      ENDIF.
      SORT gt_funfil[].
      LOOP AT gt_funfil.
        l_message_v1 = gt_funfil-function.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o19 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
  ENDIF.

*-- Transfer critical tcode filters
  IF  if_ctfltr EQ 'X'
  AND NOT gt_tcodefil[] IS INITIAL.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      IF g_overwrite_flag = 'X'.
        REFRESH : r_tcode.
        r_tcode-sign   = 'I'.
        r_tcode-option = 'EQ'.
        LOOP AT gt_tcodefil.
          r_tcode-low =   gt_tcodefil-tcode.
          APPEND r_tcode.
        ENDLOOP.
        DELETE FROM /psyng/sw_systcd
        WHERE vrsio = g_tvrsio AND
              tcode IN r_tcode.
        COMMIT WORK.
      ENDIF.
      MODIFY /psyng/sw_systcd FROM TABLE gt_tcodefil[].
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test  EQ 'X'.
      COMMIT WORK.
      IF g_append_flag EQ 'X'.
        MOVE 'Critical Tcode system filters added successfully'(s10)
            TO et_return-message.
      ELSE.
        MOVE 'Critical Tcode system filters modified successfully'(s53)
            TO et_return-message.
      ENDIF.
      SORT gt_tcodefil[].
      LOOP AT gt_tcodefil.
        l_message_v1 = gt_tcodefil-tcode.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o20 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
  ENDIF.

*-- Transfer authorization filters
  IF  if_cafltr EQ 'X'
  AND NOT gt_authfil[] IS INITIAL.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      IF g_overwrite_flag = 'X'.
        REFRESH : r_swaudid.
        r_swaudid-sign   = 'I'.
        r_swaudid-option = 'EQ'.
        LOOP AT gt_authfil.
          r_swaudid-low = gt_authfil-swaudid.
          APPEND  r_swaudid.
        ENDLOOP.
        DELETE FROM /psyng/sw_sysca
        WHERE vrsio = g_tvrsio AND
              swaudid IN r_swaudid.
        COMMIT WORK.
      ENDIF.
      MODIFY /psyng/sw_sysca FROM TABLE gt_authfil[].
    ENDIF.
    IF sy-dbcnt GT 0
    OR if_test  EQ 'X'.
      COMMIT WORK.
      IF g_append_flag EQ 'X'.
        MOVE
     'Critical Authorization system filters added successfully'(s11)
                                                     TO
  et_return-message.
      ELSE.
        MOVE
  'Critical Authorization system filters modified successfully'(s54)
                                                         TO
  et_return-message.
      ENDIF.
      SORT gt_authfil[].
      LOOP AT gt_authfil.
        l_message_v1 = gt_authfil-swaudid.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o21 l_message_v1 '' ''.
      ENDLOOP.
    ENDIF.
  ENDIF.

*-- Transfer Custom org logic
  IF  if_torgo EQ 'X'
  AND NOT gt_swsodorgo[] IS INITIAL.
    IF if_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      REFRESH r_conid.
      IF g_overwrite_flag = 'X'.
        REFRESH : r_conid.
        r_conid-sign   = 'I'.
        r_conid-option = 'EQ'.
        LOOP AT gt_swsodorgo.
          r_conid-low = gt_swsodorgo-conid.
          APPEND r_conid.
        ENDLOOP.
        DELETE FROM /psyng/swsodorgo
        WHERE vrsio = g_tvrsio AND
              conid IN r_conid.
        COMMIT WORK.
      ENDIF.
    ENDIF.
    LOOP AT gt_swsodorgo.
** Actual Upload not test
      IF if_test IS INITIAL.
        CLEAR l_corg_added.
        CALL FUNCTION '/PSYNG/SW_ADD_CUSTOM_ORG'
          EXPORTING
            ls_corg     = gt_swsodorgo
            i_vrsio     = gt_swsodorgo-vrsio
            f_corg      = if_torgo
          IMPORTING
            fcorg_added = l_corg_added.
      ENDIF.
      IF l_corg_added EQ 'Y'
      OR if_test  EQ 'X'.
        IF g_append_flag EQ 'X'.
          MOVE 'Custom Org Logic added successfully'(s57)
          TO et_return-message.
        ELSE.
          MOVE 'Custom Org Logic modified successfully'(s58)
          TO et_return-message.
        ENDIF.
        l_message_v1 = gt_swsodorgo-conid.
        CLEAR l_message_v2.
        CONCATENATE gt_swsodorgo-field gt_swsodorgo-type
        INTO l_message_v2 SEPARATED BY ' / '.
        PERFORM fill_log
         TABLES et_return
          USING 'S' et_return-message
                text-o03 l_message_v1 text-o22 l_message_v2.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
