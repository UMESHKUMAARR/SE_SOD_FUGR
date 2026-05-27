*----------------------------------------------------------------------*
* Report  /PSYNG/SW_080                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_080 MESSAGE-ID /psyng/sw.
CONSTANTS: lc_fname TYPE rs38l_fnam
    VALUE '/PSYNG/SW_COPY_VER_DESC'.
TABLES: /psyng/function,          "SW: Function Definition
        /psyng/conflict,          "SW: Conflict Header
        /psyng/critcodes,         "SW: Critical Tcodes
        /psyng/swaudhdr,          "SW: Critical Auths Header
        /psyng/criroles,          "SW: Critical Roles
        /psyng/criprof,           "SW: Critical Profiles
        /psyng/sw_cuscon.         "SW: Custom Conflicts



DATA: gt_function  TYPE TABLE OF /psyng/function WITH HEADER LINE,
      gt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
      gt_faobj     TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
      gt_conflict  TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
      gt_confdet   TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
      gt_mchdr     TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
      gt_mctran    TYPE TABLE OF /psyng/mctran WITH HEADER LINE,
      gt_mcrepid   TYPE TABLE OF /psyng/mcrepid WITH HEADER LINE,
      gt_mcauditor TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
      gt_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
      gt_swaudhdr  TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
      gt_swaudc    TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
      gt_criroles  TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
      gt_criprof   TYPE TABLE OF /psyng/criprof WITH HEADER LINE,
      gt_texts     TYPE TABLE OF /psyng/texts WITH HEADER LINE,
      gt_cuscon    TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
      gt_conowner  TYPE TABLE OF /psyng/conowner WITH HEADER LINE,
      gs_swsodvers TYPE /psyng/swsodvers,
      gt_swsodorgo TYPE TABLE OF /psyng/swsodorgo WITH HEADER LINE.

DATA: gt_function_t  TYPE TABLE OF /psyng/function WITH HEADER LINE,
      gt_functtran_t TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
      gt_faobj_t     TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
      gt_conflict_t  TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
      gt_confdet_t   TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
      gt_mchdr_t     TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
      gt_mctran_t    TYPE TABLE OF /psyng/mctran WITH HEADER LINE,
      gt_mcrepid_t   TYPE TABLE OF /psyng/mcrepid WITH HEADER LINE,
      gt_mcauditor_t TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
      gt_critcodes_t TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
      gt_swaudhdr_t  TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
      gt_swaudc_t    TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
      gt_criroles_t  TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
      gt_criprof_t   TYPE TABLE OF /psyng/criprof WITH HEADER LINE,
      gt_texts_t     TYPE TABLE OF /psyng/texts WITH HEADER LINE,
      gt_cuscon_t    TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
      gt_conowner_t  TYPE TABLE OF /psyng/conowner WITH HEADER LINE,
      gs_swsodvers_t TYPE /psyng/swsodvers,
      gt_swsodorgo_t TYPE TABLE OF /psyng/swsodorgo WITH HEADER LINE.
DATA : gf_pageload TYPE c.

DATA: BEGIN OF gt_output OCCURS 0,
        desc(50) TYPE c,
        count    TYPE i,
      END OF gt_output.

DATA: g_ucomm TYPE sy-ucomm.
DATA : g_desc   TYPE /psyng/swsodvers-vdesc,
       l_vrsio  TYPE /psyng/swsodvers-vrsio,
       l_svrsio TYPE /psyng/swsodvers-vrsio,
       l_tvrsio TYPE /psyng/swsodvers-vrsio.

DATA : g_append_flag    TYPE c,
       g_overwrite_flag TYPE c.
DATA:gf_only_mchdr   TYPE c,
     gf_target_exits.
DATA: msg_text TYPE sy-lisel . "Message text

*^^^ ============================================================ ^^^^^^
*    Test Mode: Delete Target
*^^^ ============================================================^^^^^^
DATA: BEGIN OF gt_test_function OCCURS 0,
        funid TYPE /psyng/function-function,
      END OF gt_test_function.
DATA: BEGIN OF gt_test_conflict OCCURS 0,
        conid TYPE /psyng/conflict-conid,
      END OF gt_test_conflict.
DATA:gt_test_swaudhdr  TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
     gt_test_sw_cuscon TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
     gt_test_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
     gt_test_criroles  TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
     gt_test_criprof   TYPE TABLE OF /psyng/criprof WITH HEADER LINE,
     g_current_user TYPE sy-uname. "C0700
*^^^ ============================================================ ^^^^^^
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
PARAMETERS: p_rfcdst    LIKE rfcdes-rfcdest MATCHCODE OBJECT
 /psyng/sw_rfcsh_coll DEFAULT 'NONE',
            p_svrsio(3) TYPE c MEMORY ID /psyng/vrsio.
.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN COMMENT 1(79) g_svdesc.
SELECTION-SCREEN SKIP.
PARAMETERS: p_tvrsio(3) TYPE c,
            p_tvdesc    TYPE /psyng/swsodvers-vdesc.

PARAMETERS: p_dessrc AS CHECKBOX DEFAULT space USER-COMMAND dessrc.
*^^^ ============================================================ ^^^^^^
*    Actions: Before and after copy
*^^^ ============================================================ ^^^^^^

SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF BLOCK hblk WITH FRAME.
PARAMETERS:p_delsrc AS CHECKBOX DEFAULT space MODIF ID mcm,
           p_deltar AS CHECKBOX DEFAULT space MODIF ID mcm
                                USER-COMMAND exp.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_ins RADIOBUTTON GROUP i USER-COMMAND exp MODIF ID wrt.
SELECTION-SCREEN COMMENT 3(60) p_cmi MODIF ID wrt FOR FIELD p_ins.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_fowrt RADIOBUTTON GROUP i MODIF ID wrt.
SELECTION-SCREEN COMMENT 3(60) p_cmo MODIF ID wrt FOR FIELD p_fowrt.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN END OF BLOCK hblk .
*^^^ ============================================================ ^^^^^^

SELECTION-SCREEN SKIP.
PARAMETERS: p_test AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK blk1.


SELECTION-SCREEN COMMENT 1(82) text-c01.
SELECTION-SCREEN BEGIN OF BLOCK conrep WITH FRAME TITLE text-t03.
SELECTION-SCREEN BEGIN OF BLOCK function WITH FRAME TITLE text-t04.
PARAMETERS: p_tfunct AS CHECKBOX DEFAULT 'X' USER-COMMAND exp.
SELECT-OPTIONS: s_funid FOR /psyng/function-function  ."MODIF ID hd1.
SELECTION-SCREEN END OF BLOCK function.

SELECTION-SCREEN BEGIN OF BLOCK conflict WITH FRAME TITLE text-t05.
PARAMETERS: p_tconid AS CHECKBOX DEFAULT 'X' USER-COMMAND exp.
SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid  ."MODIF ID hd1.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_tcscon AS CHECKBOX USER-COMMAND exp.
SELECTION-SCREEN COMMENT 3(60) text-m04 FOR FIELD p_tcscon.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS: s_cuscon FOR /psyng/sw_cuscon-conid MODIF ID hd1.
*Begin changes DDHIMAN 03.12.19
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_torgo AS CHECKBOX DEFAULT 'X' USER-COMMAND org.
SELECTION-SCREEN COMMENT 3(60) text-m05 FOR FIELD p_torgo.

SELECTION-SCREEN: END OF LINE.
*End changes DDHIMAN 03.12.19
SELECTION-SCREEN END OF BLOCK conflict.

SELECTION-SCREEN BEGIN OF BLOCK mc WITH FRAME TITLE text-t06.

SELECTION-SCREEN BEGIN OF BLOCK crittran WITH FRAME TITLE text-t07.
PARAMETERS: p_ttcode AS CHECKBOX DEFAULT 'X' USER-COMMAND exp.
SELECT-OPTIONS: s_tcode FOR /psyng/critcodes-tcode ."MODIF ID hd1.
SELECTION-SCREEN END OF BLOCK crittran.

SELECTION-SCREEN BEGIN OF BLOCK critauth WITH FRAME TITLE text-t08.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_taudid AS CHECKBOX DEFAULT 'X' USER-COMMAND exp.
SELECTION-SCREEN COMMENT 3(60) text-m03 FOR FIELD p_taudid.
SELECTION-SCREEN: END OF LINE.
SELECT-OPTIONS: s_audid FOR /psyng/swaudhdr-swaudid ."MODIF ID hd1.
SELECTION-SCREEN END OF BLOCK critauth.

SELECTION-SCREEN BEGIN OF BLOCK critrole WITH FRAME TITLE text-t09.
PARAMETERS: p_tagrnm AS CHECKBOX USER-COMMAND exp.
SELECT-OPTIONS: s_agr FOR /psyng/criroles-agr_name.
SELECTION-SCREEN END OF BLOCK critrole.

SELECTION-SCREEN BEGIN OF BLOCK critprof WITH FRAME TITLE text-t10.
PARAMETERS: p_tprof AS CHECKBOX USER-COMMAND exp.
SELECT-OPTIONS: s_profil FOR /psyng/criprof-profile.
SELECTION-SCREEN END OF BLOCK critprof.

SELECTION-SCREEN END OF BLOCK mc.
SELECTION-SCREEN END OF BLOCK conrep.

SELECTION-SCREEN BEGIN OF BLOCK mch WITH FRAME TITLE text-t11.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_tcont AS CHECKBOX USER-COMMAND mcnt.
SELECTION-SCREEN COMMENT 3(60) text-m01 FOR FIELD p_tcont.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS: s_contid FOR /psyng/conflict-contid.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_fowrte AS CHECKBOX USER-COMMAND exp MODIF ID mch.
SELECTION-SCREEN COMMENT 3(60) p_cmt MODIF ID mch FOR FIELD p_fowrte.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN END OF BLOCK mch.



*--------------------------- INITIALIZATION ---------------------------*
INITIALIZATION.
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
* Check for create authority
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc <> 0.
    MESSAGE w108 WITH 'Create SOD Versions'(014).
    LEAVE LIST-PROCESSING.
  ENDIF.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
  g_ucomm = sy-ucomm.

  l_svrsio = p_svrsio.
  l_tvrsio = p_tvrsio.

** Making the fields Obligatory when other then mitigation checkbx are
** checked SE 3.1 Sys testing Bug 2699
  IF p_tfunct = 'X' OR
    p_tconid  = 'X' OR
    p_tcscon  = 'X' OR
    p_ttcode  = 'X' OR
    p_taudid  = 'X' OR
    p_tagrnm  = 'X' OR
    p_tprof   = 'X'.
** P_svrsio is chnged form NUMC to C as we cant check for Space or
** initial.
    CONDENSE p_svrsio NO-GAPS.
    CONDENSE p_tvrsio NO-GAPS.
    SHIFT p_svrsio RIGHT DELETING TRAILING space.
    SHIFT p_tvrsio RIGHT DELETING TRAILING space.
    IF p_svrsio = space.
      SET CURSOR FIELD p_svrsio.
      CLEAR : p_tvdesc.
      MESSAGE s002(/psyng/sw) WITH
      'Please Enter Source SOD version'(028).
      LEAVE LIST-PROCESSING.
      STOP.
    ELSE.
      IF NOT p_svrsio CO '1234567890 '.
        SET CURSOR FIELD p_svrsio.
        CLEAR : p_tvdesc.
        MESSAGE s002(/psyng/sw) WITH
        'Please Enter Valid Source SOD version'(029).
        LEAVE LIST-PROCESSING.
        STOP.
      ENDIF.
    ENDIF.

    IF p_tvrsio = space.
      SET CURSOR FIELD p_tvrsio.
      MESSAGE s002(/psyng/sw) WITH
      'Please Enter target SOD version'(030).
      LEAVE LIST-PROCESSING.
      STOP.
    ELSE.
      IF NOT p_tvrsio CO '1234567890 '.
        SET CURSOR FIELD p_tvrsio.
        MESSAGE s002(/psyng/sw) WITH
        'Please Enter Valid target SOD version'(031).
        LEAVE LIST-PROCESSING.
        STOP.
      ENDIF.
    ENDIF.

  ENDIF.

*--Always update description when   p_dessrc = 'X'
*--These checks are only relevant for version dependant copy operations
* so NOT when only mitigating controls are copied

  IF p_tfunct = 'X' OR
    p_tconid  = 'X' OR
    p_tcscon  = 'X' OR
    p_ttcode  = 'X' OR
    p_taudid  = 'X' OR
    p_tagrnm  = 'X' OR
    p_tprof   = 'X'.

    PERFORM get_vers_description.
  ENDIF.


AT SELECTION-SCREEN OUTPUT.

  l_svrsio = p_svrsio.
  l_tvrsio = p_tvrsio.

  l_vrsio  = p_svrsio.
  p_cmt = 'Force Overwrite'(022).
  p_cmo = 'Overwrite'(027).
  p_cmi = 'Append'(026).
  PERFORM show_select_opt.
  gf_pageload = 'X'.
  IF p_dessrc = 'X'.
    LOOP AT SCREEN.
      CHECK screen-name = 'P_TVDESC'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      CHECK screen-name = 'P_TVDESC'.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.

  LOOP AT SCREEN.
    IF screen-group1 EQ 'MCH'.
      IF p_tcont EQ 'X'.
        screen-active = 1.
        screen-input = 1.
        screen-invisible = 0.
        screen-output = 1.
        MODIFY SCREEN.
      ELSE.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
    IF screen-group1 EQ 'MCM'.
      IF gf_only_mchdr IS INITIAL.
        screen-active = 1.
        screen-input = 1.
        screen-invisible = 0.
        screen-output = 1.
        MODIFY SCREEN.
      ELSE.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF screen-group1 EQ 'WRT'.
      IF gf_only_mchdr IS INITIAL.
        IF p_deltar = 'X'.
          screen-input = 0.
        ELSE.
          screen-active = 1.
          screen-input = 1.
          screen-invisible = 0.
          screen-output = 1.
        ENDIF.
      ELSE.
        screen-active = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_svrsio.
  PERFORM f4_vrsio CHANGING p_svrsio.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_tvrsio.
  PERFORM f4_vrsio CHANGING p_tvrsio.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-low.
  PERFORM f4_ctcode CHANGING s_tcode-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-high.
  PERFORM f4_ctcode CHANGING s_tcode-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_agr-low.
  PERFORM f4_ctrole CHANGING s_agr-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_agr-high.
  PERFORM f4_ctrole CHANGING s_agr-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_profil-low.
  PERFORM f4_ctprof CHANGING s_profil-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_profil-high.
  PERFORM f4_ctprof CHANGING s_profil-high.

*------------------------- START-OF-SELECTION -------------------------*
START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  l_svrsio = p_svrsio.
  l_tvrsio = p_tvrsio.

  DATA : dynpread  TYPE TABLE OF dynpread WITH HEADER LINE,
         rsselread TYPE TABLE OF rsselread WITH HEADER LINE.

  IF NOT p_rfcdst = 'NONE' AND
  NOT p_rfcdst IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.


  IF g_ucomm <> 'EXP'.
    PERFORM validations.
  ENDIF.

  PERFORM select_data.

  IF p_deltar = 'X'.
    PERFORM delete_version USING l_tvrsio 'NONE'.
  ENDIF.

  IF p_delsrc = 'X'.
    PERFORM delete_version USING l_svrsio p_rfcdst.
  ENDIF.

  PERFORM copy_version.

  PERFORM output_results.
*&---------------------------------------------------------------------*
*&      Form  show_select_opt
*&---------------------------------------------------------------------*
*       Select Options behaviour
*----------------------------------------------------------------------*

FORM show_select_opt.
  IF p_tfunct <> 'X' AND
  p_tconid  <> 'X' AND
  p_tcscon  <> 'X' AND
  p_ttcode  <> 'X' AND
  p_taudid  <> 'X' AND
  p_tagrnm  <> 'X' AND
  p_tprof   <> 'X' AND
  p_tcont = 'X'.
    gf_only_mchdr = 'X'.
  ELSE.
    CLEAR gf_only_mchdr.
  ENDIF.
  LOOP AT SCREEN.
*Disable version fields if not relevant
    IF p_tfunct <> 'X' AND
      p_tconid  <> 'X' AND
      p_tcscon  <> 'X' AND
      p_ttcode  <> 'X' AND
      p_taudid  <> 'X' AND
      p_tagrnm  <> 'X' AND
      p_tprof   <> 'X'.

      IF p_tcont = 'X'.
        IF screen-name CS 'P_SVRSIO' OR
           screen-name CS 'P_TVRSIO' OR
           screen-name CS 'P_DESSRC' OR
           screen-name CS 'P_DELSRC' OR
           screen-name CS 'P_TVDESC' OR
           screen-name CS 'P_FOWRTE'.
          screen-input = '0'.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

    ENDIF.

    IF screen-name CS 'S_FUNID'.
      IF p_tfunct = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CONID'.
      IF p_tconid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CUSCON'.
      IF p_tcscon = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CONTID'.
      IF p_tcont = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TCODE'.
      IF p_ttcode = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_AUDID'.
      IF p_taudid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_AGR'.
      IF p_tagrnm = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_PROFIL'.
      IF p_tprof = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'P_TORGO'.
      IF p_tconid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ENDIF.
    IF screen-group1 CS 'HD1'.
      IF gf_pageload IS INITIAL.
        screen-active = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.


ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  validations
*&---------------------------------------------------------------------*
*       Validate selection screen
*----------------------------------------------------------------------*
FORM validations.
  DATA: l_noedit    TYPE /psyng/swsodvers-noedit,
        l_svrsio    TYPE /psyng/swsodvers-vrsio,
        l_tvrsio    TYPE /psyng/swsodvers-vrsio,
        l_vdesc     TYPE /psyng/swsodvers-vdesc,
        l_question  TYPE string,
        l_answer(1) TYPE c,
        it_versio   TYPE TABLE OF /psyng/swsodvers WITH HEADER LINE.
  DATA:lf_current_rfc.            "Current system RFC flag
  DATA:l_message_id(3) TYPE c.
  CLEAR: l_message_id,l_question.

  l_svrsio = p_svrsio.
  l_tvrsio = p_tvrsio.

*--These checks are only relevant for version dependant copy operations
* so NOT when only mitigating controls are copied

  IF p_tfunct = 'X' OR
    p_tconid  = 'X' OR
    p_tcscon  = 'X' OR
    p_ttcode  = 'X' OR
    p_taudid  = 'X' OR
    p_tagrnm  = 'X' OR
    p_tprof   = 'X'.
*** Check processing for same version of same RFC

    PERFORM verify_current_sys_rfc USING p_rfcdst
                                         lf_current_rfc.

    IF p_rfcdst EQ 'NONE' OR lf_current_rfc EQ 'X'.
      IF l_svrsio = l_tvrsio.
        MESSAGE s002(/psyng/sw) WITH text-e09 text-e10.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.

* Check versions
*--Validate Source version
    IF p_rfcdst EQ 'NONE' OR p_rfcdst IS INITIAL.

      CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
        EXPORTING
          iversio   = l_svrsio
        TABLES
          et_versio = it_versio.
    ELSE.
*BOC UMITTAL SE VF scan changes-25/11/2024
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
           EXCEPTIONS
             invalid_reject_option        = 1
             invalid_reject_state         = 2
             function_not_supported       = 3
             internal_error               = 4
             OTHERS                       = 5
                    .
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
        DESTINATION p_rfcdst
        EXPORTING
          iversio   = l_svrsio
        TABLES
          et_versio = it_versio
        EXCEPTIONS
          system_failure = 1
          communication_failure = 2
          OTHERS = 3.                            "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        MESSAGE e090(/psyng/sw) WITH lc_fname.
        EXIT.
      ENDIF.
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*      ENDIF.
    ENDIF.

    IF it_versio[] IS INITIAL.
      MESSAGE s106 WITH text-e06 l_svrsio.
      LEAVE LIST-PROCESSING.
    ENDIF.


    g_svdesc = gs_swsodvers-vdesc.
    SELECT SINGLE vdesc noedit INTO (l_vdesc, l_noedit)
                 FROM /psyng/swsodvers
                WHERE vrsio = l_tvrsio.
    IF sy-subrc EQ 0.
      g_desc = l_vdesc.
    ELSE.
      g_desc = p_tvdesc.

    ENDIF.


* Copy description from source version
    IF p_dessrc = 'X'.

      IF p_rfcdst EQ 'NONE'.

        CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
          EXPORTING
            iversio   = l_svrsio
          TABLES
            et_versio = it_versio.
      ELSE.

*BOC UMITTAL SE VF scan changes-25/11/2024
        CALL FUNCTION 'RFC_CALLBACK_REJECTED'
             EXCEPTIONS
               invalid_reject_option        = 1
               invalid_reject_state         = 2
               function_not_supported       = 3
               internal_error               = 4
               OTHERS                       = 5
                      .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
          DESTINATION p_rfcdst
          EXPORTING
            iversio   = l_svrsio
          TABLES
            et_versio = it_versio                "#EC SAST_CI_GEN_CHECK
          EXCEPTIONS
          system_failure = 1
          communication_failure = 2
          OTHERS = 3.                            "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          MESSAGE e090(/psyng/sw) WITH lc_fname.
          EXIT.
        ENDIF.
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


      ENDIF.


      IF NOT it_versio[] IS INITIAL.
        READ TABLE it_versio WITH KEY vrsio = l_svrsio.
        IF sy-subrc = 0.
          p_tvdesc = it_versio-vdesc.
        ENDIF.
      ELSE.
        LOOP AT SCREEN.
          CHECK screen-name = 'P_SVRSIO'.
          screen-input = 1.
          MODIFY SCREEN.
        ENDLOOP.

        SET CURSOR FIELD 'P_SVRSIO'.
        MESSAGE s000 WITH l_svrsio.
        LEAVE LIST-PROCESSING.
      ENDIF.

    ELSEIF p_dessrc IS INITIAL.

      p_tvdesc = g_desc.
      IF  p_tvdesc IS INITIAL.
        MESSAGE s106 WITH text-e01 l_tvrsio.
        LEAVE LIST-PROCESSING.
      ENDIF.

    ENDIF.



** Bug 2686 : No pop message on test run
    IF p_test IS INITIAL.
      IF p_delsrc = 'X'.
*   Cannot delete versions 000 or 999
        IF l_svrsio = '000' OR l_svrsio = '999'.
          MESSAGE s153 WITH l_svrsio.
          LEAVE LIST-PROCESSING.
        ENDIF.
      ENDIF.


      IF l_noedit = 'X'.
*   Version is marked as "No Edit" - popup to confirm
        l_question = text-q01.
        PERFORM pop_up_to_confirm USING l_question.

      ELSE.

        IF p_delsrc EQ 'X'.
          CONCATENATE l_message_id 'A' INTO l_message_id.
        ENDIF.
        IF p_deltar EQ 'X'.
          CONCATENATE l_message_id 'B' INTO l_message_id.
        ENDIF.
        IF p_ins EQ 'X'.
          CONCATENATE l_message_id 'C' INTO l_message_id.
        ENDIF.
        IF p_fowrt EQ 'X'.
          CONCATENATE l_message_id 'D' INTO l_message_id.
        ENDIF.

        SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                      WHERE vrsio = l_tvrsio.

        IF sy-subrc = 0.
          gf_target_exits = 'X'.
        ELSE.
          IF p_deltar EQ 'X'.
            MESSAGE s002  WITH 'Cannot delete a target version'(s02)
            'that does not exist'(s03).
            LEAVE LIST-PROCESSING.
          ENDIF.
        ENDIF.

        CASE l_message_id.
          WHEN 'ABC' OR 'ABD'.
            l_question = text-w01.
          WHEN 'AC'.
            l_question = text-w03.
          WHEN 'AD'.
            IF gf_target_exits = 'X'.
              l_question = text-w05.
            ELSE.
              l_question = text-w03.
            ENDIF.
          WHEN 'BC' OR 'BD'.
            l_question = text-w04.
          WHEN 'C'.
            IF gf_target_exits = 'X'.
              l_question = text-w06.
            ELSE.
              EXIT.
            ENDIF.
          WHEN 'D'.
            IF gf_target_exits = 'X'.
              l_question = text-w07.
            ELSE.
              EXIT.
            ENDIF.
        ENDCASE.
        PERFORM pop_up_to_confirm USING l_question.

      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " validations

*&---------------------------------------------------------------------*
*&      Form  select_data
*&---------------------------------------------------------------------*
*       Select all data from source version
*----------------------------------------------------------------------*
FORM select_data.
  DATA: msg_text TYPE sy-lisel.   "Message text
  DATA:lf_current_rfc.            "Current system RFC flag
  CLEAR gf_only_mchdr.

  IF p_rfcdst IS INITIAL.
    p_rfcdst = 'NONE'.
  ELSE.

  ENDIF.
*^^^ ============================================================ ^^^^^^
*   If Only Mitigation Header selected then check whether RFC belongs to
*   current system or not.
*^^^ ============================================================ ^^^^^^

  IF p_tfunct <> 'X' AND
  p_tconid  <> 'X' AND
  p_tcscon  <> 'X' AND
  p_ttcode  <> 'X' AND
  p_taudid  <> 'X' AND
  p_tagrnm  <> 'X' AND
  p_tprof   <> 'X' AND
  p_tcont = 'X'.
    gf_only_mchdr = 'X'.
    IF p_rfcdst = 'NONE'.
      MESSAGE s113 WITH 'Please specify RFC Destination'(e08).
      LEAVE LIST-PROCESSING.
    ELSE.
      PERFORM verify_current_sys_rfc USING p_rfcdst
                                           lf_current_rfc.
      IF lf_current_rfc EQ 'X'.
        MESSAGE s113
        WITH 'RFC Destination belongs to same system.'(e00)
        'Please change it'(e07).
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
  ENDIF.

*---User should have 03 auth for shource version
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
            ID 'ACTVT' FIELD '03'
            ID 'Y&SW_VRSIO' FIELD l_svrsio.

  IF sy-subrc <> 0.
    MESSAGE w108 WITH text-e23 l_svrsio.
    LEAVE LIST-PROCESSING.
    EXIT.
  ENDIF.

*^^^ ============================================================ ^^^^^^
*   Prevent fetching all data when particular checkbox is not selected
*^^^ ============================================================ ^^^^^^
  IF p_taudid <> 'X'.
    REFRESH s_audid.
    s_audid-sign = 'I'.
    s_audid-option = 'EQ'.
    s_audid-low = ' '.
    APPEND s_audid.
  ENDIF.

  IF p_tcscon <> 'X'.
    s_cuscon-sign = 'I'.
    s_cuscon-option = 'EQ'.
    s_cuscon-low = ' '.
    APPEND s_cuscon.
  ENDIF.
  IF p_tprof <> 'X'.
    s_profil-sign = 'I'.
    s_profil-option = 'EQ'.
    s_profil-low = ' '.
    APPEND s_profil.
  ENDIF.
  IF p_tagrnm <> 'X'.
    s_agr-sign = 'I'.
    s_agr-option = 'EQ'.
    s_agr-low = ' '.
    APPEND s_agr.
  ENDIF.
  IF p_ttcode <> 'X'.
    s_tcode-sign = 'I'.
    s_tcode-option = 'EQ'.
    s_tcode-low = ' '.
    APPEND s_tcode.
  ENDIF.

  IF p_tcont <> 'X'.
    s_contid-sign = 'I'.
    s_contid-option = 'EQ'.
    s_contid-low = ' '.
    APPEND s_contid.
  ENDIF.
  IF p_tconid <> 'X'.
    s_conid-sign = 'I'.
    s_conid-option = 'EQ'.
    s_conid-low = ' '.
    APPEND s_conid.
  ENDIF.
  IF p_tfunct <> 'X'.
    s_funid-sign = 'I'.
    s_funid-option = 'EQ'.
    s_funid-low = ' '.
    APPEND s_funid.
  ENDIF.
*^^^ ============================================================ ^^^^^^
  IF  gf_only_mchdr = 'X'.
    l_svrsio = '000'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
       EXCEPTIONS
         invalid_reject_option        = 1
         invalid_reject_state         = 2
         function_not_supported       = 3
         internal_error               = 4
         OTHERS                       = 5
                .
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_051'
    DESTINATION p_rfcdst
    EXPORTING
      i_vrsio           = l_svrsio
    TABLES
      it_funid          = s_funid
      it_conid          = s_conid
      it_contid         = s_contid
      it_tcode          = s_tcode
      it_audid          = s_audid
      it_agr            = s_agr
      it_profil         = s_profil
      it_cuscon         = s_cuscon
      et_function       = gt_function
      et_functtran      = gt_functtran
      et_faobj          = gt_faobj
      et_conflict       = gt_conflict
      et_confdet        = gt_confdet
      et_mchdr          = gt_mchdr
      et_mctran         = gt_mctran
      et_mcrepid        = gt_mcrepid
      et_critcodes      = gt_critcodes
      et_swaudhdr       = gt_swaudhdr
      et_swaudc         = gt_swaudc
      et_criroles       = gt_criroles
      et_criprof        = gt_criprof
      et_texts          = gt_texts
      et_cuscon         = gt_cuscon
      et_conowner       = gt_conowner
      et_mcauditor      = gt_mcauditor
      et_swsodorgo      = gt_swsodorgo
    EXCEPTIONS
      version_not_exist = 1
      OTHERS            = 2.                     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " select_data

*&---------------------------------------------------------------------*
*&      Form  copy_version
*&---------------------------------------------------------------------*
*       Copy all records from source version to target
*----------------------------------------------------------------------*
FORM copy_version.


  TYPES: BEGIN OF t_mchdr,
           contid TYPE /psyng/mchdr-contid,
         END OF t_mchdr.

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
        lt_functtran      TYPE TABLE OF /psyng/functtran WITH HEADER
        LINE,
        lt_faobj          TYPE TABLE OF /psyng/faobj2    WITH HEADER
        LINE,
        lt_confdet        TYPE TABLE OF /psyng/confdet   WITH HEADER
        LINE,
        lt_conowner       TYPE TABLE OF /psyng/conowner  WITH HEADER
        LINE,
        lt_mcauditor      TYPE TABLE OF /psyng/mcauditor WITH HEADER
        LINE,
        lt_mctran         TYPE TABLE OF /psyng/mctran    WITH HEADER
        LINE,
        lt_mcrepid        TYPE TABLE OF /psyng/mcrepid   WITH HEADER
        LINE,
        lt_texts          TYPE TABLE OF /psyng/texts     WITH HEADER
        LINE,
        lf_no_auth        TYPE /psyng/bapiflagx,
        l_temp_vdesc      TYPE /psyng/swsodvers-vdesc,
        lt_critcode_count TYPE TABLE OF /psyng/critcodes,
        lt_crirole_count  TYPE TABLE OF /psyng/criroles,
        lt_criprofs_count TYPE TABLE OF /psyng/criprof,
        l_index           TYPE i,
        lf_missing_auth,
        lt_temp_function  TYPE TABLE OF /psyng/function WITH HEADER LINE
        ,
        lt_temp_conflict  TYPE TABLE OF /psyng/conflict WITH HEADER LINE
        ,
        lt_temp_confdet   TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
        lt_temp_functtran TYPE TABLE OF /psyng/functtran,
        lt_temp_faobj     TYPE TABLE OF /psyng/faobj,
        lt_temp_texts     TYPE TABLE OF /psyng/texts,
        lt_temp_conowner  TYPE TABLE OF /psyng/conowner,
        lt_temp_mchdr     TYPE TABLE OF /psyng/mchdr,
        lt_temp_mcauditor TYPE TABLE OF /psyng/mcauditor,
        lt_temp_mctran    TYPE TABLE OF /psyng/mctran,
        lt_temp_mcrepid   TYPE TABLE OF /psyng/mcrepid,
        lt_temp_swaudhdr  TYPE TABLE OF /psyng/swaudhdr,
        lt_temp_swaudc    TYPE TABLE OF /psyng/swaudc2,
        lt_temp_criroles  TYPE TABLE OF /psyng/criroles,
        lt_temp_critcodes TYPE TABLE OF /psyng/critcodes,
        lt_temp_criprof   TYPE TABLE OF /psyng/criprof,
        lt_temp_cuscon    TYPE TABLE OF /psyng/sw_cuscon,
        lt_swsodorgo      TYPE TABLE OF /psyng/swsodorgo,
        ls_swsodorgo      LIKE LINE OF lt_swsodorgo,
        l_corg_added      TYPE c,
        l_valid TYPE flag,
        ls_vrsio_o TYPE /psyng/swsodvers,
        ls_vrsio_n TYPE /psyng/swsodvers,
        l_objid        TYPE cdhdr-objectid,
        lt_cdtxt       TYPE TABLE OF cdtxt.
* Version header
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_VRSIO' FIELD l_tvrsio.
  IF sy-subrc <> 0.
    MESSAGE w108 WITH text-e02 l_tvrsio.
    LEAVE LIST-PROCESSING.
    EXIT.
  ENDIF.

  gs_swsodvers-vrsio  = l_tvrsio.
  gs_swsodvers-vdesc  = p_tvdesc.
  gs_swsodvers-noedit = space.


  IF p_test IS INITIAL.
*  Do not modify version when only mitigation headers are being copied
    IF NOT gf_only_mchdr EQ 'X'.
      l_objid = gs_swsodvers-vrsio.
      SELECT SINGLE * FROM /psyng/swsodvers INTO
        ls_vrsio_o WHERE vrsio = gs_swsodvers-vrsio.
      IF sy-subrc <> 0.
        ls_vrsio_n = gs_swsodvers.
        INSERT /psyng/swsodvers FROM gs_swsodvers.
*----insert change document
        CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
          EXPORTING
            objectid                      = l_objid
            tcode                         = sy-tcode
            utime                         = sy-uzeit
            udate                         = sy-datum
            username                      = g_current_user"sy-unameC0700
           planned_change_number          = ' '
           object_change_indicator        = 'I'
           planned_or_real_changes        = 'R'
           no_change_pointers             = ' '
*           UPD_ICDTXT_VRSIO              = ' '
           n_psyng_swsodvers              = ls_vrsio_n
           o_psyng_swsodvers              = ls_vrsio_o
           upd_psyng_swsodvers            = 'I'
          TABLES
            icdtxt_vrsio                  = lt_cdtxt.
      ELSE.
        ls_vrsio_n = gs_swsodvers.
        MODIFY /psyng/swsodvers FROM gs_swsodvers.
*----update change document
        CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
          EXPORTING
            objectid                      = l_objid
            tcode                         = sy-tcode
            utime                         = sy-uzeit
            udate                         = sy-datum
            username                      = g_current_user"sy-unameC0700
           planned_change_number          = ' '
           object_change_indicator        = 'U'
           planned_or_real_changes        = 'R'
           no_change_pointers             = ' '
*           UPD_ICDTXT_VRSIO              = ' '
           n_psyng_swsodvers              = ls_vrsio_n
           o_psyng_swsodvers              = ls_vrsio_o
           upd_psyng_swsodvers            = 'U'
          TABLES
            icdtxt_vrsio                  = lt_cdtxt.
      ENDIF.
      CLEAR : ls_vrsio_n, ls_vrsio_o.
    ENDIF.
  ENDIF.

* All Texts
  ls_texts-vrsio = l_tvrsio.
  MODIFY gt_texts FROM ls_texts TRANSPORTING vrsio
         WHERE vrsio = l_svrsio.
  SORT gt_texts BY textname object spras vrsio line.


**** Remove existing records in case of append.
  IF g_append_flag EQ 'X'.
    IF p_test NE 'X'.
      PERFORM append_only.
    ELSE.
      PERFORM append_only_test.
    ENDIF.
  ENDIF.
* Function header
  IF p_tfunct EQ 'X'.

    ls_function-vrsio = l_tvrsio.
    ls_function-create_dat = sy-datum.
    ls_function-create_tim = sy-uzeit.
    ls_function-create_usr = g_current_user."sy-uname. C0700

    CLEAR: ls_function-change_dat, ls_function-change_tim,
           ls_function-change_usr.
    IF g_overwrite_flag = 'X'.
      MODIFY gt_function FROM ls_function
       TRANSPORTING vrsio create_dat create_tim create_usr change_dat
                          change_tim change_usr
             WHERE vrsio = l_svrsio.
    ELSE.

      MODIFY gt_function FROM ls_function
          TRANSPORTING vrsio WHERE vrsio = l_svrsio.
    ENDIF.

* Function details
    ls_functtran-vrsio = l_tvrsio.
    MODIFY gt_functtran FROM ls_functtran TRANSPORTING vrsio
           WHERE vrsio = l_svrsio.

* Function objects
    ls_faobj-vrsio = l_tvrsio.
    ls_faobj-create_dat = sy-datum.
    ls_faobj-create_tim = sy-uzeit.
    ls_faobj-create_usr = g_current_user."sy-uname. C0700

    CLEAR: ls_faobj-change_dat, ls_faobj-change_tim, ls_faobj-change_usr
    .
    IF g_overwrite_flag = 'X'.
      MODIFY gt_faobj FROM ls_faobj
       TRANSPORTING vrsio create_dat create_tim create_usr change_dat
                          change_tim change_usr
             WHERE vrsio = l_svrsio.
    ELSE.
      MODIFY gt_faobj FROM ls_faobj TRANSPORTING vrsio
           WHERE vrsio = l_svrsio.
    ENDIF.
  ENDIF.
  IF p_tconid EQ 'X'.
    ls_conflict-vrsio = l_tvrsio.
    ls_conflict-create_dat = sy-datum.
    ls_conflict-create_tim = sy-uzeit.
    ls_conflict-create_usr = g_current_user."sy-uname. C0700
    CLEAR: ls_conflict-change_dat, ls_conflict-change_tim,
           ls_conflict-change_usr.
    MODIFY gt_conflict FROM ls_conflict TRANSPORTING vrsio
           WHERE vrsio = l_svrsio.

* Conflict owner.
    ls_conowner-vrsio = l_tvrsio.
    MODIFY gt_conowner FROM ls_conowner TRANSPORTING vrsio
           WHERE vrsio = l_svrsio.

* Conflict details
    ls_confdet-vrsio = l_tvrsio.
    MODIFY gt_confdet FROM ls_confdet TRANSPORTING vrsio
           WHERE vrsio = l_svrsio.
  ENDIF.




* Mitigation details
  IF p_tcont EQ 'X'.
    DATA : lt_mchdr_new TYPE TABLE OF /psyng/mchdr,
           lt_mchdr_old TYPE TABLE OF /psyng/mchdr.
    SELECT * FROM /psyng/mchdr
    INTO TABLE lt_mchdr_old WHERE contid IN s_contid
    ORDER BY contid.
*    SORT lt_mchdr_old BY contid.

    LOOP AT gt_mchdr.
      gt_output-count = 0.
      READ TABLE lt_mchdr_old WITH KEY contid = gt_mchdr-contid
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND gt_mchdr TO lt_mchdr_new.
      ELSE.
*also delete the details and texts
        IF p_fowrte EQ 'X'.
          CONCATENATE text-018 gt_mchdr-contid 'Overwritten.'(025)
          INTO gt_output-desc SEPARATED BY space.
          gt_output-count = 1.
          APPEND gt_output.
          CLEAR gt_output.
          APPEND gt_mchdr TO lt_mchdr_new.
        ELSE.
          CONCATENATE text-018 gt_mchdr-contid 'already exists.'(019)
          INTO gt_output-desc SEPARATED BY space.
          APPEND gt_output.

          DELETE gt_mcrepid   WHERE contid = gt_mchdr-contid.
          DELETE gt_mctran    WHERE contid = gt_mchdr-contid.
          DELETE gt_mcauditor WHERE contid = gt_mchdr-contid.
          DELETE gt_texts     WHERE textname =  gt_mchdr-contid
                              AND  object = 'M'.
        ENDIF.
      ENDIF.

    ENDLOOP.
    gt_mchdr[] = lt_mchdr_new[].

    FREE : lt_mchdr_new,lt_mchdr_old.
  ENDIF.
  RANGES : r_funid FOR /psyng/function-function.
** Actual Upload not test
  IF p_test IS INITIAL.

    IF p_tfunct EQ 'X'.
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
          WHERE vrsio = l_tvrsio AND
                function IN r_funid.
          DELETE FROM /psyng/functtran
          WHERE vrsio = l_tvrsio AND
                functionid IN r_funid.
          DELETE FROM /psyng/faobj2
          WHERE vrsio = l_tvrsio AND
                funid IN r_funid.
          DELETE FROM /psyng/texts
          WHERE vrsio  = l_tvrsio AND
                object = 'O' AND
                textname IN r_funid.
          COMMIT WORK.
        ENDIF.
      ENDIF.

      REFRESH lt_temp_texts.
*--
      LOOP AT gt_function INTO ls_function.
        l_index = sy-tabix.
        l_valid = 'Y'.
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

**** Code fix by Shekhar 27/08/2013 SE 3.1 ITEM C4
**** Start
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
              ID 'ACTVT' FIELD '01'
              ID 'Y&SW_VRSIO' FIELD l_tvrsio
              ID 'Y&SW_FUNCT' FIELD ls_function-function.
        IF sy-subrc NE 0.
          MESSAGE s113 WITH text-e14 text-005.
          DELETE gt_function INDEX l_index.
          CLEAR l_index.
          lf_no_auth = 'X'.
          CLEAR l_valid.
        ENDIF.

**** End Fix
        IF l_valid = 'Y'.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = ls_function
              i_vrsio                 = l_tvrsio
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

          IF sy-subrc = 2.
            lf_no_auth = 'X'.
            DELETE gt_function INDEX l_index.
          ENDIF.
        ENDIF.

        REFRESH: lt_functtran, lt_faobj, lt_texts.
        CLEAR l_valid.
      ENDLOOP.
    ENDIF.

    IF p_tconid EQ 'X'.
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
          WHERE vrsio = l_tvrsio AND
                conid IN r_conid.
          DELETE FROM /psyng/confdet
          WHERE vrsio = l_tvrsio AND
                conid IN r_conid.
          DELETE FROM /psyng/conowner
          WHERE vrsio = l_tvrsio AND
                conid IN r_conid.
          DELETE FROM /psyng/texts
          WHERE vrsio  = l_tvrsio AND
                object = 'C' AND
                textname IN r_conid.

          COMMIT WORK.
        ENDIF.
      ENDIF.
      REFRESH lt_temp_texts.
*--
      LOOP AT gt_conflict INTO ls_conflict.
        l_index = sy-tabix.
        l_valid = 'Y'.
        LOOP AT gt_confdet INTO lt_confdet
                WHERE conid = ls_conflict-conid.
          APPEND lt_confdet.
        ENDLOOP.

        LOOP AT gt_conowner INTO lt_conowner
                WHERE conid = ls_conflict-conid.
          APPEND lt_conowner.
        ENDLOOP.

        LOOP AT gt_texts INTO lt_texts WHERE textname =
                                          ls_conflict-conid
                                        AND   object   = 'C'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                 ID 'ACTVT' FIELD '01'
                 ID 'Y&SW_CONID' FIELD ls_conflict-conid
                 ID 'Y&SW_VRSIO' FIELD l_tvrsio.
        IF sy-subrc NE 0.
          MESSAGE s113 WITH text-e14 text-006.
*BOC UMITTAL PN17430 28/01/2026
          IF NOT gt_conflict[] IS INITIAL.
            DELETE gt_conflict INDEX l_index.
          ENDIF.
*EOC UMITTAL PN17430 28/01/2026
          CLEAR l_index.
          lf_no_auth = 'X'.
          CLEAR l_valid.
        ENDIF.

        IF l_valid = 'Y'.
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
            EXPORTING
              wa_conflict           = ls_conflict
              i_vrsio               = l_tvrsio
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

          IF sy-subrc = 3.
            lf_no_auth = 'X'.
          ENDIF.
        ENDIF.
        REFRESH: lt_confdet, lt_conowner, lt_texts.
        CLEAR l_valid.
      ENDLOOP.
    ENDIF.

    IF p_torgo = 'X'.

      IF p_fowrt = 'X'.
        DELETE FROM /psyng/swsodorgo
          WHERE vrsio  = l_tvrsio AND
                conid IN s_conid .
        COMMIT WORK.
        LOOP AT gt_swsodorgo WHERE conid IN s_conid AND
                                   vrsio = l_svrsio.
          APPEND gt_swsodorgo TO lt_swsodorgo.
        ENDLOOP.
      ELSEIF p_ins = 'X'.
        LOOP AT gt_swsodorgo WHERE conid IN s_conid AND
                                   vrsio = l_svrsio.
          APPEND gt_swsodorgo TO lt_swsodorgo.
        ENDLOOP.
      ENDIF.

* --- Check function header auth
      AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
      ID 'ACTVT' FIELD '01'
      ID 'Y&SW_VRSIO' FIELD l_tvrsio
      ID 'Y&SW_FUNCT' FIELD ''."(++)BOC UMITTAL SE VF scan-25/11/2024
      IF sy-subrc NE 0.
        MESSAGE s113 WITH text-e14 text-005.
*BOC UMITTAL PN17430 28/01/2026
        IF NOT gt_function[] IS INITIAL.
          IF l_index GT 0.
            DELETE gt_function INDEX l_index.
          ENDIF.
        ENDIF.
*EOC UMITTAL PN17430 28/01/2026
        CLEAR l_index.
        lf_no_auth = 'X'.
      ELSE.
        LOOP AT lt_swsodorgo INTO ls_swsodorgo.
          ls_swsodorgo-vrsio = l_tvrsio.
          CALL FUNCTION '/PSYNG/SW_ADD_CUSTOM_ORG'
            EXPORTING
              ls_corg     = ls_swsodorgo
              i_vrsio     = l_tvrsio
              f_corg      = p_torgo
            IMPORTING
              fcorg_added = l_corg_added.
        ENDLOOP.
      ENDIF.

    ENDIF.
    IF p_rfcdst <> 'NONE'.
      IF p_tcont EQ 'X'.
*-- Delete the previous versions of the records that are currently
*   being uploaded
        RANGES : r_contid FOR gt_mchdr-contid.
        IF g_overwrite_flag = 'X'.
          REFRESH : r_contid.
          r_contid-sign = 'I'.
          r_contid-option = 'EQ'.
          IF NOT gt_mchdr[] IS INITIAL.
            LOOP AT gt_mchdr.
              r_contid-low = gt_mchdr-contid.
              APPEND r_contid.
            ENDLOOP.
            DELETE FROM /psyng/mchdr
            WHERE contid IN r_contid.
            DELETE FROM /psyng/mcauditor
            WHERE contid IN r_contid.
            DELETE FROM /psyng/mctran
            WHERE contid IN r_contid.
            DELETE FROM /psyng/mcrepid
            WHERE contid IN r_contid.
            DELETE FROM /psyng/texts
            WHERE object = 'M' AND
                  textname IN r_contid.
            COMMIT WORK.
          ENDIF.
        ENDIF.

*--

        LOOP AT gt_mchdr INTO ls_mchdr.
          l_index  = sy-tabix.
          LOOP AT gt_mcauditor INTO lt_mcauditor
                  WHERE contid = ls_mchdr-contid.
            APPEND lt_mcauditor.
          ENDLOOP.

          LOOP AT gt_mctran INTO lt_mctran
                  WHERE contid = ls_mchdr-contid.
            APPEND lt_mctran.
          ENDLOOP.

          LOOP AT gt_mcrepid INTO lt_mcrepid
                  WHERE contid = ls_mchdr-contid.
            APPEND lt_mcrepid.
          ENDLOOP.

          LOOP AT gt_texts INTO lt_texts
                 WHERE textname = ls_mchdr-contid
                   AND object   = 'M'.
            APPEND lt_texts.
            DELETE gt_texts.
          ENDLOOP.


          CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
            EXPORTING
              is_mchdr             = ls_mchdr
              if_no_email          = 'X'
              flag                 = g_append_flag
            TABLES
              it_mcauditor         = lt_mcauditor
              it_mctran            = lt_mctran
              it_mcrepid           = lt_mcrepid
              it_texts             = lt_texts
            EXCEPTIONS
              target_not_specified = 1
              not_authorized       = 2
              locked               = 3
              OTHERS               = 4.

          IF sy-subrc = 2.
            lf_no_auth = 'X'.
            DELETE gt_mchdr INDEX l_index.
          ENDIF.

          REFRESH: lt_mcauditor, lt_mctran, lt_mcrepid, lt_texts.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ELSE.
** Test Copy
    IF p_tfunct EQ 'X'.
      LOOP AT gt_function INTO ls_function.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD l_tvrsio
               ID 'Y&SW_FUNCT' FIELD ls_function-function.
        IF sy-subrc NE 0.
          MESSAGE s113 WITH text-e14 text-005.
          DELETE gt_function INDEX l_index.
          lf_no_auth = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF p_tconid EQ 'X'.
      LOOP AT gt_conflict INTO ls_conflict.
        l_index = sy-tabix.
        AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                 ID 'ACTVT' FIELD '01'
                 ID 'Y&SW_CONID' FIELD ls_conflict-conid
                 ID 'Y&SW_VRSIO' FIELD l_tvrsio.
        IF sy-subrc NE 0.
          MESSAGE s113 WITH text-e14 text-006.
          DELETE gt_conflict INDEX l_index.
          lf_no_auth = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDIF.

  IF p_ttcode EQ 'X'.

    IF p_test IS INITIAL.
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
          WHERE vrsio = l_tvrsio AND tcode IN r_tcode.
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
               ID 'Y&SW_VRSIO' FIELD l_tvrsio.

      IF sy-subrc = 0.

        LOOP AT gt_texts INTO lt_texts WHERE object  = 'X'
                                                                     .
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.


        IF p_test IS INITIAL.
          lt_critcode_count[] = gt_critcodes[].

          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_TCODES'
            EXPORTING
              i_vrsio                  = l_tvrsio
              append_flag              = g_append_flag
            TABLES
              critcodes                = gt_critcodes
              texts                    = lt_texts
            EXCEPTIONS
              not_authorized_to_import = 1
              empty_list_provided      = 2
              OTHERS                   = 3.
          IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
          ENDIF.

          gt_critcodes[] = lt_critcode_count[].
        ENDIF.
      ELSE.
        lf_no_auth = 'X'.
        MESSAGE s113 WITH text-e14 text-010.
*--Case 17492 - This next statement was unnecessary and produced a dump
*               when users didn't have authorization to create critical
*               tcodes
*        DELETE gt_critcodes.
      ENDIF.
    ENDIF.
  ENDIF.

*---Critical authorization header
  IF p_taudid EQ 'X'.

*--DHORIONS 2013/05/28: Use Function module
    DATA :
      lt_swaudc LIKE TABLE OF gt_swaudc.
*-- Delete the previous versions of the records that are currently
*   being uploaded
    RANGES : r_swaudid FOR gt_swaudc-swaudid.
    IF p_test IS INITIAL.
      IF g_overwrite_flag = 'X'.
        IF NOT gt_swaudc[] IS INITIAL.
          r_swaudid-sign   = 'I'.
          r_swaudid-option = 'EQ'.
          LOOP AT gt_swaudc.
            r_swaudid-low = gt_swaudc-swaudid.
            APPEND  r_swaudid.
          ENDLOOP.
          DELETE FROM /psyng/swaudhdr
          WHERE vrsio = l_tvrsio AND swaudid IN r_swaudid.
          DELETE FROM /psyng/swaudc2
          WHERE vrsio = l_tvrsio AND swaudid IN r_swaudid.
          DELETE FROM /psyng/texts
          WHERE object = 'T' AND
                vrsio  = l_tvrsio AND   " Arpan changed 21.09.2022
                textname IN r_swaudid.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.

    IF NOT gt_swaudhdr[] IS INITIAL.
      LOOP AT gt_swaudhdr.
        l_index = sy-tabix.
        FREE : lt_swaudc, lt_texts.
        gt_swaudhdr-vrsio = l_tvrsio.
        LOOP AT gt_swaudc WHERE swaudid = gt_swaudhdr-swaudid.
          gt_swaudc-vrsio = l_tvrsio.
          APPEND gt_swaudc TO lt_swaudc.
        ENDLOOP.
        LOOP AT gt_texts INTO lt_texts
                  WHERE textname = gt_swaudhdr-swaudid AND
                        object   = 'T'.
          lt_texts-vrsio = l_tvrsio.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

***Code by Shekhar 13/09/2013 SE 3.1 Development ITEM C4
***Start Fix
        AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
            ID 'ACTVT' FIELD '01'
            ID 'Y&SW_VRSIO' FIELD l_tvrsio
            ID 'Y&SW_AUTID' FIELD gt_swaudhdr-swaudid.
        IF sy-subrc NE 0.
          MESSAGE s113 WITH text-e14 text-011.
          DELETE gt_swaudhdr INDEX l_index.
          CLEAR l_index.
          lf_missing_auth = 'X'.
          lf_no_auth = 'X'.
        ENDIF.
****Endfix
        IF p_test IS INITIAL.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
            EXPORTING
              wa_swaudid            = gt_swaudhdr
              i_vrsio               = l_tvrsio
*             F_CAT                 =
              flag                  = g_append_flag
            TABLES
              texts                 = lt_texts
              swaudc2               = lt_swaudc
            EXCEPTIONS
              target_not_specified  = 1
              not_authorized        = 2
              authid_already_exists = 3
              OTHERS                = 4.
          IF sy-subrc = 2.
            lf_missing_auth = 'X'.
            lf_no_auth = 'X'.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF lf_missing_auth EQ 'X'.
      MESSAGE s113 WITH text-e14 text-011.
      CLEAR lf_missing_auth.
    ENDIF.
  ENDIF.

  IF p_tagrnm EQ 'X'.
* Critical roles
    CLEAR lt_texts.
    REFRESH lt_texts.

    IF NOT gt_criroles[] IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      RANGES: r_role FOR /psyng/criroles-agr_name.


      IF p_test IS INITIAL.
        IF g_overwrite_flag = 'X'.
          IF NOT gt_criroles[] IS INITIAL.
            r_role-sign   = 'I'.
            r_role-option = 'EQ'.
            LOOP AT gt_criroles.
              r_role-low = gt_criroles-agr_name.
              APPEND r_role.
            ENDLOOP.
            DELETE FROM /psyng/criroles
            WHERE vrsio = l_tvrsio AND agr_name IN r_role.
            DELETE FROM /psyng/texts
            WHERE object = 'Q' AND
                  textname IN r_role.
            COMMIT WORK.
          ENDIF.
        ENDIF.
      ENDIF.



      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
               ID 'ACTVT' FIELD '01'
               ID 'Y&SW_VRSIO' FIELD l_tvrsio.
      IF sy-subrc = 0.
        LOOP AT gt_texts INTO lt_texts WHERE object  = 'Q'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

        IF p_test IS INITIAL.
          lt_crirole_count[] = gt_criroles[].
*---------
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_ROLES'
            EXPORTING
              i_vrsio             = l_tvrsio
              append_flag         = g_append_flag
            TABLES
              criroles            = gt_criroles
              texts               = lt_texts
            EXCEPTIONS
              empty_list_provided = 1
              OTHERS              = 2.
          IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
          ENDIF.

          gt_criroles[] = lt_crirole_count[].
        ENDIF.
      ELSE.
        lf_no_auth = 'X'.
        lf_missing_auth = 'X'.
      ENDIF.
      IF lf_missing_auth EQ 'X'.
        MESSAGE s113 WITH text-e14 text-012.
        CLEAR lf_missing_auth.
      ENDIF.
    ENDIF.
  ENDIF.
*----Critical profiles
  IF p_tprof EQ 'X'.
*-- Delete the previous versions of the records that are currently
*   being uploaded
    RANGES : r_profile FOR /psyng/criprof-profile.

    IF p_test IS INITIAL.
      IF g_overwrite_flag = 'X'.
        IF gt_criprof[] IS INITIAL.
          r_profile-sign   = 'I'.
          r_profile-option = 'EQ'.
          LOOP AT gt_criprof.
            r_profile-low = gt_criprof-profile.
            APPEND r_profile.
          ENDLOOP.
          DELETE FROM /psyng/criprof
          WHERE vrsio = l_tvrsio AND profile IN r_profile.
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
              ID 'Y&SW_VRSIO' FIELD l_tvrsio.
      IF sy-subrc = 0.
        LOOP AT gt_texts INTO lt_texts WHERE object  = 'P'.
          APPEND lt_texts.
          DELETE gt_texts.
        ENDLOOP.

        IF p_test IS INITIAL.
          lt_criprofs_count[] = gt_criprof[].
*- Make Actual DB changes
          CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_PROFILES'
            EXPORTING
              i_vrsio             = l_tvrsio
              append_flag         = g_append_flag
            TABLES
              criprof             = gt_criprof
              texts               = lt_texts
            EXCEPTIONS
              empty_list_provided = 1
              OTHERS              = 2.
          IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
          ENDIF.
          gt_criprof[] = lt_criprofs_count[].
        ENDIF.
      ELSE.
        lf_no_auth = 'X'.
        lf_missing_auth = 'X'.
      ENDIF.
      IF lf_missing_auth EQ 'X'.
        MESSAGE s113 WITH text-e14 text-013.
        CLEAR lf_missing_auth.
      ENDIF.
    ENDIF.
  ENDIF.
* All Texts
********************************************************
  DATA : lt_text_keys LIKE TABLE OF gt_texts WITH HEADER LINE.
  IF p_test IS INITIAL.
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

  IF p_tcscon EQ 'X'.
* Custom conflicts
    ls_cuscon-vrsio = l_tvrsio.
    ls_cuscon-create_usr = g_current_user."sy-uname. C0700
    ls_cuscon-create_dat = sy-datum.
    ls_cuscon-create_tim = sy-uzeit.

    MODIFY gt_cuscon FROM ls_cuscon
    TRANSPORTING vrsio create_usr create_dat create_tim
           WHERE vrsio = l_svrsio.
    LOOP AT gt_cuscon.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                 ID 'ACTVT' FIELD '01'
                 ID 'Y&SW_CONID' FIELD gt_cuscon-conid
                 ID 'Y&SW_VRSIO' FIELD l_tvrsio.
      IF sy-subrc NE 0.
        lf_missing_auth = 'X'.
        DELETE gt_cuscon.
      ENDIF.
    ENDLOOP.
    IF lf_missing_auth EQ 'X'.
      MESSAGE s113 WITH text-e14 text-016.
      CLEAR lf_missing_auth.
    ENDIF.

    IF p_test IS INITIAL.
*-- Delete the previous versions of the records that are currently
*   being uploaded
      IF g_overwrite_flag = 'X'.
        IF NOT r_conid[] IS INITIAL.
          DELETE FROM /psyng/sw_cuscon
          WHERE vrsio = l_tvrsio AND
                conid IN r_conid.
          COMMIT WORK.
        ENDIF.
      ENDIF.
      MODIFY /psyng/sw_cuscon FROM TABLE gt_cuscon.
      COMMIT WORK.
    ENDIF.
  ENDIF.
  IF lf_no_auth = 'X'.
    MESSAGE i113 WITH text-e03 text-e04.
  ENDIF.
ENDFORM.                    " copy_version

*&---------------------------------------------------------------------*
*&      Form  delete_version
*&---------------------------------------------------------------------*
*       Delete all records for given version
*----------------------------------------------------------------------*
*      -->I_VRSIO  Version to delete
*----------------------------------------------------------------------*
FORM delete_version USING i_vrsio TYPE /psyng/swsodvers-vrsio
                          i_rfcdst TYPE rfcdest.

  DATA: msg_text TYPE sy-lisel . "Message text
  DATA : l_answer(1)       TYPE c,
         l_configset       TYPE i,
         l_msg             TYPE c LENGTH 20,
         l_mandt           TYPE sy-mandt,
         l_no_valid_assign TYPE flag,
         l_question(180).



*  CHECK p_test IS INITIAL.



  IF i_rfcdst IS INITIAL.
    i_rfcdst = 'NONE'.
  ENDIF.

  IF p_test IS INITIAL.

    SELECT SINGLE mandt FROM /psyng/mcuser INTO l_mandt
    WHERE vrsio = i_vrsio
    AND to_date GE sy-datum.
    IF sy-subrc NE 0.
      SELECT SINGLE mandt FROM /psyng/mcusrgrp INTO l_mandt
              WHERE vrsio = i_vrsio
              AND to_date GE sy-datum.
      IF sy-subrc NE 0.
        SELECT SINGLE mandt FROM /psyng/mcrole INTO l_mandt
                WHERE vrsio = i_vrsio
                AND to_date GE sy-datum.
        IF sy-subrc NE 0 .
          SELECT SINGLE mandt FROM /psyng/mccauser INTO l_mandt
                  WHERE vrsio = i_vrsio
                  AND to_date GE sy-datum.
          IF sy-subrc NE 0.
            SELECT SINGLE mandt FROM /psyng/mccarole INTO l_mandt
                    WHERE vrsio = i_vrsio
                    AND to_date GE sy-datum.
            IF sy-subrc NE 0.
              l_no_valid_assign = 'X'.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    IF l_no_valid_assign EQ space.

      CONCATENATE 'Valid MC Assignments exist for version'
                   i_vrsio
                   '. Do you want to continue with the Delete ?'
                   INTO l_question SEPARATED BY space.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Copy Version'
          text_question         = l_question
          text_button_1         = text-023
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = text-024
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '2'
          display_cancel_button = space
          start_column          = 25
          start_row             = 6
        IMPORTING
          answer                = l_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    ELSE.
      l_answer = 1.
    ENDIF.

    IF l_answer = '1'.

*---Check no publish configset for this version exist
*  If so, don't allow deletion
      SELECT COUNT(*) INTO l_configset FROM /psyng/swcfgset
                                                        "#EC CI_NOFIELD
       WHERE sodvrsio = i_vrsio.

      IF l_configset > 0.
        MESSAGE e029(/psyng/sw) WITH i_vrsio.
        CLEAR: l_answer,l_no_valid_assign.
        LEAVE LIST-PROCESSING.
      ELSE.
*--Ensure no stored results exist for users
        CLEAR l_configset.
        SELECT COUNT(*) INTO l_configset FROM /psyng/swreshdr
        WHERE sodvrsio = i_vrsio.
        IF sy-subrc = 0.
          MESSAGE e028(/psyng/sw) WITH i_vrsio.
          CLEAR: l_answer,l_no_valid_assign.
          LEAVE LIST-PROCESSING.
        ENDIF.
*--Ensure no stored results exist for roles
        CLEAR l_configset.
        SELECT COUNT(*) INTO l_configset FROM /psyng/swrrshdr
        WHERE sodvrsio = i_vrsio.                       "#EC CI_NOFIELD
        IF sy-subrc = 0.
          MESSAGE e028(/psyng/sw) WITH i_vrsio.
          CLEAR: l_answer,l_no_valid_assign.
          LEAVE LIST-PROCESSING.
        ENDIF.

*BOC UMITTAL SE VF scan changes-25/11/2024
        CALL FUNCTION 'RFC_CALLBACK_REJECTED'
             EXCEPTIONS
               invalid_reject_option        = 1
               invalid_reject_state         = 2
               function_not_supported       = 3
               internal_error               = 4
               OTHERS                       = 5
                      .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        CALL FUNCTION '/PSYNG/SW_085' DESTINATION i_rfcdst
          EXPORTING
            i_vrsio = i_vrsio.                   "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        CLEAR: l_answer,l_no_valid_assign.
      ENDIF.
    ELSE.
      CLEAR: l_answer,l_no_valid_assign.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ELSE.
    PERFORM authority_check USING i_vrsio.
  ENDIF.
ENDFORM.                    " delete_version

*&---------------------------------------------------------------------*
*&      Form  output_results
*&---------------------------------------------------------------------*
*       Output summary of what was copied
*----------------------------------------------------------------------*
FORM output_results.
  TYPE-POOLS: slis.

  DATA: l_repid     TYPE sy-repid,
        ls_variant  TYPE disvariant,
        ls_layout   TYPE slis_layout_alv,
        ls_fieldcat TYPE slis_fieldcat_alv,
        lt_fieldcat TYPE slis_t_fieldcat_alv.


  l_repid = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = l_repid
      i_internal_tabname = 'GT_OUTPUT'
      i_inclname         = l_repid
    CHANGING
      ct_fieldcat        = lt_fieldcat
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             inconsistent_interface = 1
             program_error          = 2
             OTHERS                 = 3 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

  ls_fieldcat-seltext_l    = text-h01.
  ls_fieldcat-seltext_m    = text-h01.
  ls_fieldcat-seltext_s    = text-h01.
  ls_fieldcat-reptext_ddic = text-h01.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                     WHERE
                       fieldname = 'DESC'.

  ls_fieldcat-seltext_l    = text-h02.
  ls_fieldcat-seltext_m    = text-h02.
  ls_fieldcat-seltext_s    = text-h02.
  ls_fieldcat-reptext_ddic = text-h02.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                     WHERE
                       fieldname = 'COUNT'.
  IF p_tfunct EQ 'X'.
    DESCRIBE TABLE gt_function LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-005.
  APPEND gt_output.
  CLEAR gt_output-count.
  IF p_tconid EQ 'X'.
    DESCRIBE TABLE gt_conflict LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-006.
  APPEND gt_output.
  CLEAR gt_output-count.
  IF p_tcont EQ 'X'.
    DESCRIBE TABLE gt_mchdr LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-018.
  APPEND gt_output.
  CLEAR gt_output-count.
  IF p_ttcode EQ 'X'.
    DESCRIBE TABLE gt_critcodes LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-010.
  APPEND gt_output.
  CLEAR gt_output-count.
  IF p_taudid EQ 'X'.
    DESCRIBE TABLE gt_swaudhdr LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-011.
  APPEND gt_output.
  CLEAR gt_output-count.
  IF p_tagrnm EQ 'X'.
    DESCRIBE TABLE gt_criroles LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-012.
  APPEND gt_output.
  CLEAR gt_output-count.
  IF p_tprof EQ 'X'.
    DESCRIBE TABLE gt_criprof LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-013.
  APPEND gt_output.
  CLEAR gt_output-count.
  IF p_tcscon EQ 'X'.
    DESCRIBE TABLE gt_cuscon LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-016.
  APPEND gt_output.
  CLEAR gt_output-count.
* Begin changes 03.12.19 - DDHIMAN
* SOD Org Level Analysis
  IF p_torgo EQ 'X'.
    DESCRIBE TABLE gt_swsodorgo LINES gt_output-count.
  ENDIF.
  gt_output-desc = text-032.
  APPEND gt_output.
  CLEAR gt_output-count.
* End changes 03.12.19 - DDHIMAN
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = l_repid
      i_callback_top_of_page = 'ALV_TOP_OF_PAGE'
      is_layout              = ls_layout
      it_fieldcat            = lt_fieldcat
      i_save                 = 'A'
      is_variant             = ls_variant
    TABLES
      t_outtab               = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " output_results

*---------------------------------------------------------------------*
*       FORM alv_top_of_page                                          *
*---------------------------------------------------------------------*
*       Create header                                                 *
*---------------------------------------------------------------------*
FORM alv_top_of_page.
  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader.


  ls_header-typ  = 'H'.
  ls_header-info = sy-title.
  APPEND ls_header TO lt_header.
  ls_header-typ  = 'S'.
  CONCATENATE 'Version'(h03) p_svrsio
              INTO ls_header-info SEPARATED BY space.
  IF p_rfcdst <> 'NONE' AND NOT p_rfcdst IS INITIAL.
    CONCATENATE ls_header-info 'from'(h04) p_rfcdst
              INTO ls_header-info SEPARATED BY space.
  ENDIF.

  CONCATENATE ls_header-info 'copied to Version'(h05)
              p_tvrsio INTO ls_header-info SEPARATED BY space.
  APPEND ls_header TO lt_header.

  IF p_test = 'X'.
    ls_header-typ  = 'S'.
    ls_header-info = 'Test run'(h06).
    APPEND ls_header TO lt_header.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.                    " alv_top_of_page

*&---------------------------------------------------------------------*
*&      Form  get_version
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_vers_description.

  DATA: l_noedit    TYPE /psyng/swsodvers-noedit,
        l_svrsio    TYPE /psyng/swsodvers-vrsio,
        l_tvrsio    TYPE /psyng/swsodvers-vrsio,
        l_vdesc     TYPE /psyng/swsodvers-vdesc,
        l_question  TYPE string,
        l_answer(1) TYPE c,
        it_versio   TYPE TABLE OF /psyng/swsodvers WITH HEADER LINE,
        msgv1       LIKE  sy-msgv1,
        msgv2       LIKE  sy-msgv2,
        rfc_subrc   LIKE  sy-subrc.
  CLEAR sy-ucomm.

  l_svrsio = p_svrsio.
  l_tvrsio = p_tvrsio.

  IF p_dessrc = 'X'.

    IF p_rfcdst EQ 'NONE' OR  p_rfcdst IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
        EXPORTING
          iversio   = l_svrsio
        TABLES
          et_versio = it_versio.
    ELSE.

      CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
        EXPORTING
          rfcdestination = p_rfcdst
        IMPORTING
          msgv1          = msgv1
*         MSGV2          =
          rfc_subrc      = rfc_subrc.

      IF rfc_subrc NE 0.
        MESSAGE e179(/psyng/sw).
        LEAVE LIST-PROCESSING.
      ELSE.
*BOC UMITTAL SE VF scan changes-25/11/2024
        CALL FUNCTION 'RFC_CALLBACK_REJECTED'
             EXCEPTIONS
               invalid_reject_option        = 1
               invalid_reject_state         = 2
               function_not_supported       = 3
               internal_error               = 4
               OTHERS                       = 5
                      .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        CALL FUNCTION '/PSYNG/SW_COPY_VER_DESC'
          DESTINATION p_rfcdst
          EXPORTING
            iversio   = l_svrsio
          TABLES
            et_versio = it_versio                "#EC SAST_CI_GEN_CHECK
          EXCEPTIONS
          system_failure = 1
          communication_failure = 2
          OTHERS = 3.                            "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          MESSAGE e090(/psyng/sw) WITH lc_fname.
          EXIT.
        ENDIF.
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      ENDIF.
    ENDIF.

    IF NOT it_versio[] IS INITIAL.
      READ TABLE it_versio WITH KEY vrsio = l_svrsio.
      IF sy-subrc = 0.
        p_tvdesc = it_versio-vdesc.
      ENDIF.
    ELSE.
      LOOP AT SCREEN.
        CHECK screen-name = 'P_SVRSIO'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDLOOP.

      SET CURSOR FIELD 'P_SVRSIO'.
      CLEAR p_dessrc.
      MESSAGE e000 WITH l_svrsio.
      LEAVE LIST-PROCESSING.
    ENDIF.

  ELSE.

    SELECT SINGLE * FROM /psyng/swsodvers INTO it_versio
    WHERE vrsio = l_tvrsio.
    IF sy-subrc EQ 0.
      p_tvdesc = it_versio-vdesc.
    ELSE.
      LOOP AT SCREEN.
        CHECK screen-name = 'P_TVDESC'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDLOOP.

      SET CURSOR FIELD 'P_TVDESC'.
      CLEAR p_dessrc.

      IF p_tvdesc IS INITIAL.
        MESSAGE s106 WITH text-e01 l_tvrsio.
      ENDIF.

      LEAVE LIST-PROCESSING.
    ENDIF.

  ENDIF.

ENDFORM.                    " get_version
*&---------------------------------------------------------------------*
*&      Form  verify_current_sys_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_RFCDST  text
*      -->P_LF_CURRENT_RFC  text
*----------------------------------------------------------------------*
FORM verify_current_sys_rfc USING    p_rfcdst
                                     lf_current_rfc.
CONSTANTS: lc_fname TYPE rs38l_fnam VALUE '/PSYNG/SW_062'.
  DATA:l_source_rfc TYPE rfcdest,
       l_target_rfc TYPE rfcdest.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
       EXCEPTIONS
         invalid_reject_option        = 1
         invalid_reject_state         = 2
         function_not_supported       = 3
         internal_error               = 4
         OTHERS                       = 5
                .
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_062'
    DESTINATION p_rfcdst
    IMPORTING
      e_rfcdest = l_source_rfc.                  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*Begin of Addition:HBHALLA(PN-17405)(Issue3)(10/02/26)
 IF p_rfcdst IS NOT INITIAL AND l_source_rfc IS INITIAL.
  MESSAGE s089(/psyng/basis) WITH lc_fname DISPLAY LIKE 'E'.
  LEAVE LIST-PROCESSING.
 ENDIF.
*End of Addition:HBHALLA(PN-17405)(Issue3)(10/02/26)

  CONCATENATE sy-sysid sy-mandt INTO l_target_rfc.

  IF l_target_rfc = l_source_rfc.
    lf_current_rfc = 'X'.
  ENDIF.
ENDFORM.                    " verify_current_sys_rfc
*&---------------------------------------------------------------------*
*&      Form  pop_up_to_confirm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_QUESTION  text
*----------------------------------------------------------------------*
FORM pop_up_to_confirm USING    p_question.
  DATA: l_answer.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = p_question
      text_button_1         = 'Yes'(023)
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = 'No'(024)
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '1'
      display_cancel_button = ''
    IMPORTING
      answer                = l_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF l_answer EQ '1'.
    IF p_fowrt EQ 'X'.
      g_overwrite_flag = 'X'.
    ELSE.
      g_append_flag = 'X'.
    ENDIF.
  ELSE.
    MESSAGE s113 WITH text-004.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.                    " pop_up_to_confirm
*&---------------------------------------------------------------------*
*&      Form  append_critcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM append_only.
  DATA:lt_critcodes TYPE TABLE OF /psyng/critcodes WITH HEADER LINE.
  DATA:lt_function TYPE TABLE OF /psyng/function WITH HEADER LINE.
  DATA:lt_conflict TYPE TABLE OF /psyng/conflict WITH HEADER LINE.
  DATA:lt_swaudhdr TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE.
  DATA:lt_cuscon TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE.
  DATA:lt_criroles TYPE TABLE OF /psyng/criroles WITH HEADER LINE.
  DATA:lt_criprof TYPE TABLE OF /psyng/criprof WITH HEADER LINE.

  IF NOT gt_critcodes[] IS INITIAL.
*    SELECT * FROM /psyng/critcodes INTO TABLE lt_critcodes
*    WHERE vrsio EQ l_tvrsio.
    SELECT tcode FROM /psyng/critcodes
      INTO CORRESPONDING FIELDS OF TABLE lt_critcodes
    WHERE vrsio EQ l_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_critcodes.
        READ TABLE lt_critcodes WITH KEY tcode = gt_critcodes-tcode.
        IF sy-subrc EQ 0.
          DELETE gt_critcodes.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_function[] IS INITIAL.

    SELECT function FROM /psyng/function
    INTO CORRESPONDING FIELDS OF TABLE lt_function
    WHERE vrsio EQ l_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_function.
        READ TABLE lt_function
        WITH KEY function = gt_function-function.
        IF sy-subrc EQ 0.
          DELETE gt_function.
          DELETE gt_faobj WHERE funid EQ gt_function-function.
          DELETE gt_texts WHERE textname = gt_function-function AND
                                object   = 'F'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

*--DHORIONS CASE 3040
  IF NOT gt_conflict[] IS INITIAL.

    SELECT conid FROM /psyng/conflict
    INTO CORRESPONDING FIELDS OF TABLE lt_conflict
    WHERE vrsio EQ l_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_conflict.
        READ TABLE lt_conflict WITH KEY conid =  gt_conflict-conid.
        IF sy-subrc EQ 0.
          DELETE gt_conflict.
          DELETE gt_confdet WHERE conid EQ gt_conflict-conid.
          DELETE gt_conowner WHERE conid EQ gt_conflict-conid.
          DELETE gt_texts WHERE textname = gt_conflict-conid AND
                                object   = 'C'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_swaudhdr[] IS INITIAL.
    SELECT swaudid FROM /psyng/swaudhdr
    INTO CORRESPONDING FIELDS OF TABLE lt_swaudhdr
    WHERE vrsio EQ l_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_swaudhdr.
        READ TABLE lt_swaudhdr WITH KEY swaudid = gt_swaudhdr-swaudid.
        IF sy-subrc EQ 0.
          DELETE gt_swaudhdr.
          DELETE gt_swaudc WHERE swaudid = gt_swaudhdr-swaudid.
          DELETE gt_texts WHERE textname = gt_swaudhdr-swaudid AND
                                  object   = 'T'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_cuscon[] IS INITIAL.
    SELECT conid FROM  /psyng/sw_cuscon
    INTO CORRESPONDING FIELDS OF TABLE lt_cuscon
    WHERE vrsio EQ l_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_cuscon.
        READ TABLE lt_cuscon WITH KEY conid = gt_cuscon-conid.
        IF sy-subrc EQ 0.
          DELETE gt_cuscon.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_criroles[] IS INITIAL.
    SELECT agr_name FROM /psyng/criroles
     INTO CORRESPONDING FIELDS OF TABLE lt_criroles
        WHERE vrsio EQ l_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_criroles.
        READ TABLE lt_criroles WITH KEY agr_name = gt_criroles-agr_name.
        IF sy-subrc EQ 0.
          DELETE gt_criroles.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_criprof[] IS INITIAL.
    SELECT profile FROM /psyng/criprof
    INTO CORRESPONDING FIELDS OF TABLE lt_criprof
        WHERE vrsio EQ l_tvrsio.
    IF sy-subrc EQ 0.
      LOOP AT gt_criprof.
        READ TABLE lt_criprof  WITH KEY profile = gt_criprof-profile.
        IF sy-subrc EQ 0.
          DELETE gt_criprof .
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFORM.                    " append_critcodes

*&---------------------------------------------------------------------*
*&      Form  authority_check
*&---------------------------------------------------------------------*
*-   Authority check for delete soruce/target in Test Run
*----------------------------------------------------------------------*
*      -->P_I_VRSIO  text
*----------------------------------------------------------------------*
FORM authority_check USING    i_vrsio.

  DATA: BEGIN OF lt_function OCCURS 0,
          funid TYPE /psyng/function-function,
        END OF lt_function.

  DATA: BEGIN OF lt_conflict OCCURS 0,
          conid TYPE /psyng/conflict-conid,
        END OF lt_conflict.
  DATA:lt_swaudhdr     TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
       lt_swaudc2      TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
       lt_sw_cuscon    TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
       lf_missing_auth.


  SELECT function INTO TABLE lt_function FROM /psyng/function
         WHERE vrsio     = i_vrsio.

  LOOP AT lt_function.
    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
             ID 'ACTVT'      FIELD '06'
             ID 'Y&SW_VRSIO' FIELD i_vrsio
             ID 'Y&SW_FUNCT' FIELD lt_function-funid.
    IF sy-subrc NE 0.
      lf_missing_auth = 'X'.
      APPEND lt_function TO gt_test_function.
    ENDIF.
  ENDLOOP.

  IF lf_missing_auth = 'X'.
    MESSAGE s113(/psyng/sw)
    WITH 'Missing some authorization to delete Functions '(e21)
    'in version '(e22) i_vrsio.
    CLEAR lf_missing_auth.
  ENDIF.


  SELECT conid INTO TABLE lt_conflict FROM /psyng/conflict
         WHERE vrsio  = i_vrsio.
  LOOP AT lt_conflict.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
    ID 'ACTVT'      FIELD '06'
    ID 'Y&SW_VRSIO' FIELD i_vrsio
    ID 'Y&SW_CONID' FIELD lt_conflict-conid.
    IF sy-subrc NE 0.
      lf_missing_auth = 'X'.
      APPEND lt_conflict TO gt_test_conflict.
    ENDIF.
  ENDLOOP.

  IF lf_missing_auth = 'X'.
    MESSAGE s113(/psyng/sw)
    WITH 'Missing some authorization to delete Conflicts '(e15)
    'in version '(e22) i_vrsio.
    CLEAR lf_missing_auth.
  ENDIF.

* Critical authorization header
  SELECT * FROM /psyng/swaudhdr INTO TABLE lt_swaudhdr
  WHERE vrsio    = i_vrsio.
  IF sy-subrc EQ 0.
    LOOP AT lt_swaudhdr.
      AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
                 ID 'ACTVT' FIELD '06'
                 ID 'Y&SW_AUTID' FIELD lt_swaudhdr-swaudid
                 ID 'Y&SW_VRSIO' FIELD i_vrsio.
      IF sy-subrc NE 0.
        lf_missing_auth = 'X'.
        APPEND lt_swaudhdr TO gt_test_swaudhdr.
      ENDIF.
    ENDLOOP.

    IF lf_missing_auth EQ 'X'.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing some authorization to delete Crit Auth '(e16)
      'in version '(e22) i_vrsio.
      CLEAR lf_missing_auth.
    ENDIF.
  ENDIF.

***Custom Conflicts
  SELECT * FROM /psyng/sw_cuscon INTO TABLE lt_sw_cuscon
  WHERE vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    LOOP AT lt_sw_cuscon.
      AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
                 ID 'ACTVT' FIELD '06'
                 ID 'Y&SW_CONID' FIELD lt_sw_cuscon-conid
                 ID 'Y&SW_VRSIO' FIELD i_vrsio.
      IF sy-subrc NE 0.
        lf_missing_auth = 'X'.
        APPEND lt_sw_cuscon TO gt_test_sw_cuscon.
      ENDIF.
    ENDLOOP.

    IF lf_missing_auth EQ 'X'.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing some authorization to delete Cust Conf '(e17)
      'in version '(e22) i_vrsio.
      CLEAR lf_missing_auth.
    ENDIF.
  ENDIF.

* Critical TCodes
  SELECT SINGLE vrsio FROM /psyng/critcodes INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
               ID 'ACTVT' FIELD '06'
               ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc NE 0.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing authorization to delete Crit Tcode '(e18)
      'in version '(e22) i_vrsio.
      SELECT * FROM /psyng/critcodes INTO TABLE gt_test_critcodes.
    ENDIF.
  ENDIF.
* Critical roles
  SELECT SINGLE vrsio FROM /psyng/criroles INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
           ID 'ACTVT' FIELD '06'
           ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc NE 0.
      MESSAGE s113(/psyng/sw)
      WITH 'Missing authorization to delete Crit Roles '(e19)
      'in version '(e22) i_vrsio.
      SELECT * FROM /psyng/criroles INTO TABLE gt_test_criroles.
    ENDIF.
  ENDIF.

* Critical profiles
  SELECT SINGLE vrsio FROM /psyng/criprof INTO i_vrsio WHERE
  vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
          ID 'ACTVT' FIELD '06'
          ID 'Y&SW_VRSIO' FIELD i_vrsio.
    IF sy-subrc NE 0.
      MESSAGE s113(/psyng/sw)
       WITH 'Missing authorization to delete Crit Profiles '(e20)
       'in version '(e22) i_vrsio.
      SELECT * FROM /psyng/criprof INTO TABLE gt_test_criprof.
    ENDIF.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
          ID 'ACTVT' FIELD '06'
          ID 'Y&SW_VRSIO' FIELD i_vrsio.
  IF sy-subrc NE 0.
    MESSAGE s113(/psyng/sw)
    WITH 'Missing authorization to delete version '(e21)
    i_vrsio.
  ENDIF.
  FREE: lt_function, lt_conflict,lt_swaudhdr,
        lt_swaudc2 ,lt_sw_cuscon.


ENDFORM.                    " authority_check
*&---------------------------------------------------------------------*
*&      Form  append_only_test
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM append_only_test.

  IF NOT gt_critcodes[] IS INITIAL.
    IF NOT gt_test_critcodes[] IS INITIAL.
      LOOP AT gt_critcodes.
        READ TABLE gt_test_critcodes WITH KEY tcode = gt_critcodes-tcode
        .
        IF sy-subrc EQ 0.
          DELETE gt_critcodes.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_function[] IS INITIAL.
    IF NOT gt_test_function[] IS INITIAL.
      LOOP AT gt_function.
        READ TABLE gt_test_function
        WITH KEY funid = gt_function-function.
        IF sy-subrc EQ 0.
          DELETE gt_function.
          DELETE gt_faobj WHERE funid EQ gt_function-function.
          DELETE gt_texts WHERE textname = gt_function-function AND
                                object   = 'F'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_conflict[] IS INITIAL.
    IF NOT gt_test_conflict[] IS INITIAL.
      LOOP AT gt_conflict.
        READ TABLE gt_test_conflict WITH KEY conid =  gt_conflict-conid.
        IF sy-subrc EQ 0.
          DELETE gt_conflict.
          DELETE gt_confdet WHERE conid EQ gt_conflict-conid.
          DELETE gt_conowner WHERE conid EQ gt_conflict-conid.
          DELETE gt_texts WHERE textname = gt_conflict-conid AND
                                object   = 'C'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_swaudhdr[] IS INITIAL.
    IF NOT gt_test_swaudhdr[] IS INITIAL.
      LOOP AT gt_swaudhdr.
        READ TABLE gt_test_swaudhdr
        WITH KEY swaudid = gt_swaudhdr-swaudid.
        IF sy-subrc EQ 0.
          DELETE gt_swaudhdr.
          DELETE gt_swaudc WHERE swaudid = gt_swaudhdr-swaudid.
          DELETE gt_texts WHERE textname = gt_swaudhdr-swaudid AND
                                  object   = 'T'.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_cuscon[] IS INITIAL.
    IF NOT gt_test_sw_cuscon[] IS INITIAL.
      LOOP AT gt_cuscon.
        READ TABLE gt_test_sw_cuscon WITH KEY conid = gt_cuscon-conid.
        IF sy-subrc EQ 0.
          DELETE gt_cuscon.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT gt_criroles[] IS INITIAL.
    IF NOT gt_test_criroles[] IS INITIAL.
      LOOP AT gt_criroles.
        READ TABLE gt_test_criroles
        WITH KEY agr_name = gt_criroles-agr_name.
        IF sy-subrc EQ 0.
          DELETE gt_criroles.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  IF NOT gt_criprof[] IS INITIAL.
    IF NOT gt_test_criprof[] IS INITIAL.
      LOOP AT gt_criroles.
        READ TABLE gt_test_criprof  WITH KEY profile =
        gt_criprof-profile.
        IF sy-subrc EQ 0.
          DELETE gt_criroles .
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  REFRESH:gt_test_function,
          gt_test_conflict,
          gt_test_swaudhdr,
          gt_test_sw_cuscon,
          gt_test_critcodes,
          gt_test_criroles,
          gt_test_criprof.
ENDFORM.                    " append_only_test
*&---------------------------------------------------------------------*
*&      Form  f4_ctcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_TCODE_LOW  text
*----------------------------------------------------------------------*
FORM f4_ctcode CHANGING e_tcode TYPE /psyng/critcodes-tcode.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_ctcode TYPE /psyng/critcodes.

  DATA : BEGIN OF ctcode OCCURS 0,
           ttext TYPE tstct-ttext.
           INCLUDE STRUCTURE /psyng/critcodes.
         DATA END OF ctcode.

  DATA : dynpread  TYPE TABLE OF dynpread WITH HEADER LINE,
         rsselread TYPE TABLE OF rsselread WITH HEADER LINE,
         rsparams  TYPE TABLE OF rsparams WITH HEADER LINE,
         l_repid   TYPE sy-repid,
         l_dynnr   TYPE sy-dynnr.
  l_repid = sy-cprog.
  l_dynnr = sy-dynnr.
  REFRESH dynpread.
  CLEAR dynpread.
  dynpread-fieldname = 'P_SVRSIO'.

  APPEND dynpread.
  CLEAR dynpread.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname               = l_repid
      dynumb               = l_dynnr
    TABLES
      dynpfields           = dynpread
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.
  IF sy-subrc IS INITIAL.
    READ TABLE dynpread WITH KEY fieldname = 'P_SVRSIO'.
    IF sy-subrc EQ 0.
      p_svrsio = dynpread-fieldvalue.
    ENDIF .
  ENDIF.



  SELECT a~tcode
         a~vrsio
*         a~description
         a~imp
         a~owner
         b~ttext INTO CORRESPONDING FIELDS OF TABLE ctcode
         FROM /psyng/critcodes AS a INNER JOIN tstct AS b
         ON a~tcode EQ b~tcode
         WHERE vrsio = p_svrsio
           AND sprsl EQ sy-langu.
*           AND LINE EQ space.


  lt_fields-tabname   = '/PSYNG/CRITCODES'.
  lt_fields-fieldname = 'TCODE'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.

  lt_fields-tabname   = 'TSTCT'.
  lt_fields-fieldname = 'TTEXT'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/CRITCODES'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'IMP'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'OWNER'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'DESCRIPTION'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.


  LOOP AT ctcode.
    lt_values-line = ctcode-tcode.
    APPEND lt_values.
    lt_values-line = ctcode-ttext.
    APPEND lt_values.
    lt_values-line = ctcode-vrsio.
    APPEND lt_values.
    lt_values-line = ctcode-imp.
    APPEND lt_values.
    lt_values-line = ctcode-owner.
    APPEND lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t14
    IMPORTING
      select_value              = e_tcode
    TABLES
      fields                    = lt_fields
      valuetab                  = lt_values
    EXCEPTIONS
      field_not_in_ddic         = 1
      more_then_one_selectfield = 2
      no_selectfield            = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.                                                    " f4_ctcode
*&---------------------------------------------------------------------*
*&      Form  f4_ctrole
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_AGR_LOW  text
*----------------------------------------------------------------------*
FORM f4_ctrole CHANGING e_role TYPE /psyng/criroles-agr_name.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields  TYPE TABLE OF help_value WITH HEADER LINE,
        lt_return  TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_ctrole  TYPE /psyng/criroles,
        ls_agrtext TYPE agr_texts.

  DATA : BEGIN OF crole OCCURS 0,
           text TYPE agr_texts-text.
           INCLUDE STRUCTURE /psyng/criroles.
         DATA END OF crole.

  DATA : dynpread  TYPE TABLE OF dynpread WITH HEADER LINE,
         rsselread TYPE TABLE OF rsselread WITH HEADER LINE,
         rsparams  TYPE TABLE OF rsparams WITH HEADER LINE,
         l_repid   TYPE sy-repid,
         l_dynnr   TYPE sy-dynnr.
  l_repid = sy-cprog.
  l_dynnr = sy-dynnr.
  REFRESH dynpread.
  CLEAR dynpread.
  dynpread-fieldname = 'P_SVRSIO'.

  APPEND dynpread.
  CLEAR dynpread.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname               = l_repid
      dynumb               = l_dynnr
    TABLES
      dynpfields           = dynpread
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.
  IF sy-subrc IS INITIAL.
    READ TABLE dynpread WITH KEY fieldname = 'P_SVRSIO'.
    IF sy-subrc EQ 0.
      p_svrsio = dynpread-fieldvalue.
    ENDIF .
  ENDIF.


  SELECT a~agr_name
         a~vrsio
*         a~description
         a~imp
         a~owner
         b~text INTO CORRESPONDING FIELDS OF TABLE crole
         FROM /psyng/criroles AS a INNER JOIN agr_texts AS b
         ON a~agr_name EQ b~agr_name
         WHERE vrsio = p_svrsio
           AND spras EQ sy-langu
           AND line EQ space.


  REFRESH: lt_fields, lt_values.
  lt_fields-tabname   = '/PSYNG/CRIROLES'.
  lt_fields-fieldname = 'AGR_NAME'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.
  lt_fields-tabname   = 'AGR_TEXTS'.
  lt_fields-fieldname = 'TEXT'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/CRIROLES'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'IMP'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'OWNER'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'DESCRIPTION'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.


  LOOP AT crole.
    lt_values-line = crole-agr_name.
    APPEND lt_values.
    lt_values-line = crole-text.
    APPEND lt_values.
    lt_values-line = crole-vrsio.
    APPEND lt_values.
    lt_values-line = crole-imp.
    APPEND lt_values.
    lt_values-line = crole-owner.
    APPEND lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t13
    IMPORTING
      select_value              = e_role
    TABLES
      fields                    = lt_fields
      valuetab                  = lt_values
    EXCEPTIONS
      field_not_in_ddic         = 1
      more_then_one_selectfield = 2
      no_selectfield            = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  .

ENDFORM.                                                    " f4_ctrole
*&---------------------------------------------------------------------*
*&      Form  f4_ctprof
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_PROFIL_LOW  text
*----------------------------------------------------------------------*
FORM f4_ctprof CHANGING e_prof TYPE /psyng/criprof-profile.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value  WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_ctprof TYPE /psyng/criprof.

  DATA : BEGIN OF cprof OCCURS 0,
           ptext TYPE usr11-ptext.
           INCLUDE STRUCTURE /psyng/criprof.
         DATA END OF cprof.

  DATA : dynpread  TYPE TABLE OF dynpread WITH HEADER LINE,
         rsselread TYPE TABLE OF rsselread WITH HEADER LINE,
         rsparams  TYPE TABLE OF rsparams WITH HEADER LINE,
         l_repid   TYPE sy-repid,
         l_dynnr   TYPE sy-dynnr.
  l_repid = sy-cprog.
  l_dynnr = sy-dynnr.
  REFRESH dynpread.
  CLEAR dynpread.
  dynpread-fieldname = 'P_SVRSIO'.

  APPEND dynpread.
  CLEAR dynpread.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname               = l_repid
      dynumb               = l_dynnr
    TABLES
      dynpfields           = dynpread
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      invalid_parameter    = 7
      undefind_error       = 8
      double_conversion    = 9
      stepl_not_found      = 10
      OTHERS               = 11.
  IF sy-subrc IS INITIAL.
    READ TABLE dynpread WITH KEY fieldname = 'P_SVRSIO'.
    IF sy-subrc EQ 0.
      p_svrsio = dynpread-fieldvalue.
    ENDIF .
  ENDIF.



  SELECT a~profile
         a~vrsio
*         a~description
         a~imp
         a~owner
         b~ptext INTO CORRESPONDING FIELDS OF TABLE cprof
         FROM /psyng/criprof AS a INNER JOIN usr11 AS b
         ON a~profile EQ b~profn
         WHERE vrsio = p_svrsio
           AND langu EQ sy-langu.


  REFRESH: lt_fields, lt_values.
  lt_fields-tabname   = '/PSYNG/CRIPROF'.
  lt_fields-fieldname = 'PROFILE'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.

  lt_fields-tabname   = 'USR11'.
  lt_fields-fieldname = 'PTEXT'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/CRIPROF'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = ''.
  APPEND lt_fields.

  lt_fields-fieldname = 'IMP'.
  lt_fields-selectflag = ''.
  APPEND lt_fields.

  lt_fields-fieldname = 'OWNER'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'DESCRIPTION'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.



  LOOP AT cprof.
    lt_values-line = cprof-profile.
    APPEND lt_values.
    lt_values-line = cprof-ptext.
    APPEND lt_values.
    lt_values-line = cprof-vrsio.
    APPEND lt_values.
    lt_values-line = cprof-imp.
    APPEND lt_values.
    lt_values-line = cprof-owner.
    APPEND lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t16
    IMPORTING
      select_value              = e_prof
    TABLES
      fields                    = lt_fields
      valuetab                  = lt_values
    EXCEPTIONS
      field_not_in_ddic         = 1
      more_then_one_selectfield = 2
      no_selectfield            = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.



ENDFORM.                                                    " f4_ctprof
*&---------------------------------------------------------------------*
*&      Form  f4_vrsio
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_SVRSIO  text
*----------------------------------------------------------------------*
FORM f4_vrsio CHANGING e_vrsio TYPE char3 .

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value  WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_vrsio  TYPE TABLE OF /psyng/swsodvers WITH HEADER LINE.



  SELECT vrsio vdesc FROM /psyng/swsodvers
  INTO CORRESPONDING FIELDS OF TABLE lt_vrsio.

  SORT lt_vrsio BY vrsio ASCENDING.

  REFRESH: lt_fields, lt_values.
  lt_fields-tabname   = '/PSYNG/SWSODVERS'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.

  lt_fields-fieldname = 'VDESC'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.



  LOOP AT lt_vrsio.
    lt_values-line = lt_vrsio-vrsio.
    APPEND lt_values.
    lt_values-line = lt_vrsio-vdesc.
    APPEND lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t15
    IMPORTING
      select_value              = e_vrsio
    TABLES
      fields                    = lt_fields
      valuetab                  = lt_values
    EXCEPTIONS
      field_not_in_ddic         = 1
      more_then_one_selectfield = 2
      no_selectfield            = 3
      OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  .

ENDFORM.                                                    " f4_vrsio
*&---------------------------------------------------------------------*
*&      Form  rfc_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations.
  DATA : l_continue TYPE flag,
         l_cancel   TYPE flag,
         lt_return  TYPE TABLE OF bapiret2,
         r_rfcs     TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
         LINE,
         msgv1       LIKE  sy-msgv1, "HBHALLA
         rfc_subrc   LIKE  sy-subrc. "HBHALLA
  r_rfcs-sign   = 'I'.
  r_rfcs-option = 'EQ'.
*--Role Simulation Destinations
  r_rfcs-low = p_rfcdst.
  APPEND r_rfcs.

  CLEAR l_continue.
  DELETE r_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup   = 'X'
      i_module  = 'SE'
    TABLES
      it_rfcdes = r_rfcs
      et_return = lt_return.
  IF NOT lt_return[] IS INITIAL.
    LEAVE LIST-PROCESSING.
*Begin of Addition:HBHALLA(PN-17405)(Issue-2)(09/02/26)
  ELSE.
      CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
        EXPORTING
          rfcdestination = p_rfcdst
        IMPORTING
          msgv1          = msgv1
*         MSGV2          =
          rfc_subrc      = rfc_subrc.

      IF rfc_subrc NE 0.
        MESSAGE i179(/psyng/sw).
        LEAVE LIST-PROCESSING.
      ENDIF.
*End of Addition:HBHALLA(PN-17405)(Issue-2)(09/02/26)
  ENDIF.

ENDFORM.                    " rfc_validations
