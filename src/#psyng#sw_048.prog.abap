*----------------------------------------------------------------------*
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_048 MESSAGE-ID /psyng/sw NO STANDARD PAGE HEADING.
INCLUDE /psyng/sw_config.
TYPE-POOLS : shlp.
TABLES: /psyng/function,     "SW: Function Definition
        /psyng/conflict,     "SW: Conflict Header
        /psyng/mchdr,        "SW: Mitigating Controls Header
        /psyng/mcuser,       "SW: Mit. Controls Assignment to Users
        /psyng/mcusrgrp,     "SW: Mit. Controls Assignment to User Group
        /psyng/mcrole,       "SW: Mit. Controls Assignment to Roles
        /psyng/mccarole,     "Mit. Controls Assignment to Cri Auth Roles
        /psyng/mccauser,     "Mit. Controls Assignment to Cri Auth Users
        /psyng/critcodes,    "SW: Critical Tcodes
        /psyng/swaudhdr,     "SW: Critical Auths Header
        /psyng/criroles,     "SW: Critical Profiles
        /psyng/criprof,      "SW: Critical Profiles
        /psyng/sw_cuscon,    "SW: Custom Conflicts
        /psyng/sw_freq,      "SW: Frequencies
        /psyng/sw_freqt,     "SW: Frequency Texts
        /psyng/swconfig,     "SW: Config Params
        /psyng/busarea,      "SW: Application Areas
        /psyng/bus_proce,    "SW: Business process
        /psyng/sw_prj01,     "SW: Project
        /psyng/sw_sta01,     "SW: Status
        /psyng/swsodorgm,    "SW: Org levels
        /psyng/sw_systyp,
        /psyng/sw_syscat,
        /psyng/sw_risk,
        /psyng/sw_mctype,
        /psyng/sw_excltx,
        /psyng/sw_excdtx,
        tstc, /psyng/mcrvwhdr,
        stxh,
        /psyng/swcfgoe,
        /psyng/sw_varel,
        /psyng/sw_fioria,
        /psyng/sw_sysfun.

TYPES: BEGIN OF ty_systyp,
         mandt    TYPE mandt,
         sys_type TYPE /psyng/systemtype,
       END OF ty_systyp,

       BEGIN OF ty_syscat,
         mandt        TYPE mandt,
         sys_category TYPE /psyng/systemcategory,
       END OF ty_syscat,

       BEGIN OF ty_fioria,
         mandt   TYPE mandt,
         fioriid TYPE /psyng/sw_fioriid,
       END OF ty_fioria,

       BEGIN OF ty_fiorit,
         mandt     TYPE mandt,
         fioriid   TYPE /psyng/sw_fioriid,
         textfield TYPE /psyng/sw_textfield_name,
       END OF ty_fiorit,

       BEGIN OF ty_fiorio,
         mandt            TYPE mandt,
         fioriid          TYPE /psyng/sw_fioriid,
         odataservicename TYPE char40,
       END OF ty_fiorio,

       BEGIN OF ty_fiorio_t,
         mandt            TYPE mandt,
         fioriid          TYPE /psyng/sw_fioriid,
         odataservicename TYPE char16,
       END OF ty_fiorio_t.

DATA: gt_e071  TYPE e071 OCCURS 0 WITH HEADER LINE,
      gt_e071k TYPE e071k OCCURS 0 WITH HEADER LINE,
      g_trkorr TYPE trkorr,

      BEGIN OF gt_texts OCCURS 0,
        mandt    LIKE /psyng/texts-mandt,
        textname LIKE /psyng/texts-textname,
        object   LIKE /psyng/texts-object,
        spras    LIKE /psyng/texts-spras,
        line     LIKE /psyng/texts-line,
        vrsio    LIKE /psyng/texts-vrsio,
      END OF gt_texts.

DATA : l_value            TYPE /psyng/swconfig-value,
       g_ucomm            TYPE sy-ucomm,
       gt_confdet         TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
       gf_cfg_set_enabled TYPE flag.

SELECTION-SCREEN BEGIN OF BLOCK version WITH FRAME TITLE text-t10.
PARAMETERS: p_vrsio LIKE /psyng/swsodvers-vrsio.
SELECTION-SCREEN END OF BLOCK version.

SELECTION-SCREEN COMMENT 1(60) text-c00.
*SELECTION-SCREEN COMMENT 1(82) text-c01.
SELECTION-SCREEN BEGIN OF BLOCK conrep WITH FRAME TITLE text-t01.
PARAMETERS: p_tvhead AS CHECKBOX.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF BLOCK function WITH FRAME TITLE text-t02.
PARAMETERS: p_tfunct AS CHECKBOX USER-COMMAND ufunc.
SELECT-OPTIONS: s_funct FOR /psyng/function-function.
PARAMETER p_fnfltr AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK function.

SELECTION-SCREEN BEGIN OF BLOCK conflict WITH FRAME TITLE text-t03.
PARAMETERS: p_tconid AS CHECKBOX USER-COMMAND ucon.
SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid.

PARAMETERS: p_confun AS CHECKBOX USER-COMMAND ucf.

PARAMETERS: p_tcscon AS CHECKBOX USER-COMMAND uccon.
SELECT-OPTIONS: s_cuscon FOR /psyng/sw_cuscon-conid.
PARAMETER p_cnfltr AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK conflict.

SELECTION-SCREEN BEGIN OF BLOCK crittran WITH FRAME TITLE text-t06.
PARAMETERS: p_ttcode AS CHECKBOX USER-COMMAND uctcode.
SELECT-OPTIONS: s_tcode FOR /psyng/critcodes-tcode.
PARAMETER p_ctfltr AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK crittran.

SELECTION-SCREEN BEGIN OF BLOCK critauth WITH FRAME TITLE text-t07.
PARAMETERS: p_taudid AS CHECKBOX USER-COMMAND ucauth.
SELECT-OPTIONS: s_audid FOR /psyng/swaudhdr-swaudid.
PARAMETER p_cafltr AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK critauth.

SELECTION-SCREEN BEGIN OF BLOCK critrole WITH FRAME TITLE text-t08.
PARAMETERS: p_tagrnm AS CHECKBOX USER-COMMAND ucrole.
SELECT-OPTIONS: s_agrnam FOR /psyng/criroles-agr_name.
SELECTION-SCREEN END OF BLOCK critrole.

SELECTION-SCREEN BEGIN OF BLOCK critprof WITH FRAME TITLE text-t09.
PARAMETERS: p_tprof AS CHECKBOX USER-COMMAND ucprof.
SELECT-OPTIONS: s_prof FOR /psyng/criprof-profile.
SELECTION-SCREEN END OF BLOCK critprof.
SELECTION-SCREEN END OF BLOCK conrep.


SELECTION-SCREEN BEGIN OF BLOCK mc WITH FRAME TITLE text-t04.
PARAMETERS: p_tcont AS CHECKBOX USER-COMMAND ucontid.
SELECT-OPTIONS: s_contid FOR /psyng/mchdr-contid.

SELECTION-SCREEN BEGIN OF BLOCK assignment WITH FRAME TITLE text-t05.
SELECT-OPTIONS: s_mconid FOR /psyng/mcuser-conid.
PARAMETERS: p_tuasmt AS CHECKBOX USER-COMMAND umcu.
SELECT-OPTIONS: s_userid FOR /psyng/mcuser-userid.
PARAMETERS: p_tgasmt AS CHECKBOX USER-COMMAND umcug.
SELECT-OPTIONS: s_class  FOR /psyng/mcusrgrp-class.
PARAMETERS: p_trasmt AS CHECKBOX USER-COMMAND umcrole.
SELECT-OPTIONS: s_role   FOR /psyng/mcrole-agr_name.
SELECT-OPTIONS: s_caid   FOR /psyng/mccauser-swaudid.
PARAMETERS: p_tcasmt AS CHECKBOX USER-COMMAND umca.
SELECT-OPTIONS: s_causer FOR /psyng/mccauser-userid.
PARAMETERS: p_tcarol AS CHECKBOX USER-COMMAND umcarl.
SELECT-OPTIONS: s_carole FOR /psyng/mccarole-agr_name.
SELECTION-SCREEN END OF BLOCK assignment.
SELECTION-SCREEN END OF BLOCK mc.


SELECTION-SCREEN BEGIN OF BLOCK config WITH FRAME TITLE text-t11.
*SELECTION-SCREEN COMMENT 1(79) text-c02.
PARAMETERS: p_tconfg AS CHECKBOX USER-COMMAND uconfig.
SELECT-OPTIONS s_tconfg FOR /psyng/swconfig-param.

PARAMETERS :p_tapar  AS CHECKBOX USER-COMMAND uarea.
SELECT-OPTIONS : s_tapar FOR /psyng/busarea-busarea.

PARAMETER   p_tprocr AS CHECKBOX USER-COMMAND ubpro.
SELECT-OPTIONS s_tprocr FOR /psyng/bus_proce-subarea.

PARAMETER p_tproj  AS CHECKBOX USER-COMMAND uproj MODIF ID hid.
SELECT-OPTIONS s_tproj FOR /psyng/sw_prj01-project MODIF ID hid.

PARAMETER   p_tsyst AS CHECKBOX USER-COMMAND usyst.
SELECT-OPTIONS s_tsyst FOR /psyng/sw_systyp-sys_type.

PARAMETER   p_tsysc AS CHECKBOX USER-COMMAND usysc.
SELECT-OPTIONS s_tsysc FOR /psyng/sw_syscat-sys_category.

PARAMETER p_tstat  AS CHECKBOX USER-COMMAND ustat MODIF ID hid.
SELECT-OPTIONS s_tstat FOR /psyng/sw_sta01-status MODIF ID hid.

PARAMETER p_torglv AS CHECKBOX USER-COMMAND uorg.
SELECT-OPTIONS s_torgla FOR /psyng/swsodorgm-abb.
SELECT-OPTIONS s_torglo FOR /psyng/swsodorgm-object.
SELECT-OPTIONS s_torglv FOR /psyng/swsodorgm-varbl.

PARAMETER p_trisk  AS CHECKBOX USER-COMMAND urisk.
SELECT-OPTIONS s_trisk FOR /psyng/sw_risk-risk.

PARAMETER p_tmityp AS CHECKBOX USER-COMMAND umityp.
SELECT-OPTIONS s_tmityp FOR /psyng/sw_mctype-type.

PARAMETER p_tfreq  AS CHECKBOX USER-COMMAND ufreq.
SELECT-OPTIONS s_tfreq FOR /psyng/sw_freq-freq.

PARAMETER p_velemt  AS CHECKBOX USER-COMMAND uelemt.
SELECTION-SCREEN BEGIN OF BLOCK ve WITH FRAME.
PARAMETER : p_ve_hdr TYPE flag.
SELECT-OPTIONS s_vevrs FOR /psyng/sw_varel-varel_vrsio.
SELECT-OPTIONS s_velemt  FOR /psyng/sw_varel-var_element.
SELECTION-SCREEN END OF BLOCK ve.
PARAMETER p_dynam  AS CHECKBOX USER-COMMAND dynam.
SELECT-OPTIONS: s_ctcode FOR /psyng/sw_excltx-low,
               s_ctcod1 FOR /psyng/sw_excdtx-called_tcode.

PARAMETER p_cnfset  AS CHECKBOX USER-COMMAND cnfset.
SELECT-OPTIONS: s_setid FOR /psyng/swcfgoe-setid.

PARAMETERS: p_corg AS CHECKBOX USER-COMMAND corg.

PARAMETER p_appid  AS CHECKBOX USER-COMMAND fappid.
SELECT-OPTIONS: s_appid FOR /psyng/sw_fioria-fioriid
MATCHCODE OBJECT /psyng/fioriid.

SELECTION-SCREEN END OF BLOCK config.

*Email text
SELECTION-SCREEN BEGIN OF BLOCK email WITH FRAME TITLE text-t44.
PARAMETERS: p_email AS CHECKBOX USER-COMMAND email.
SELECT-OPTIONS p_emltxt FOR stxh-tdname NO INTERVALS.
SELECTION-SCREEN END OF BLOCK email.

LOAD-OF-PROGRAM.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    gf_cfg_set_enabled = 'X'.
  ENDIF.

INITIALIZATION.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.


*--- Validate version
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = p_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e128 WITH text-t10.
  ENDIF.

  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.

  CASE g_ucomm.
    WHEN 'UCF'.
      IF p_confun = 'X'.
        IF s_conid-low IS INITIAL.
          CLEAR p_confun.
          MESSAGE s002(/psyng/sw) WITH text-002.
        ELSE.
          SELECT DISTINCT functionid
          FROM /psyng/confdet
          INTO CORRESPONDING FIELDS OF TABLE gt_confdet
          WHERE conid IN s_conid
          AND vrsio = p_vrsio.
          IF sy-subrc = 0.
            s_funct-sign = 'I'.
            s_funct-option = 'EQ'.

            LOOP AT gt_confdet.
              s_funct-low = gt_confdet-functionid.
              APPEND s_funct.
            ENDLOOP.

            p_tfunct = 'X'.

          ENDIF.
        ENDIF.
      ELSE.
        p_tfunct = ' '.
        REFRESH s_funct.
      ENDIF.
  ENDCASE.

  CLEAR g_ucomm.

*--------------------- AT SELECTION-SCREEN OUTPUT ---------------------*
AT SELECTION-SCREEN OUTPUT.
*--- Check Config Param
  se_config_param 'SW_ROLES_POS_USRASGN' l_value.

  IF sy-subrc = 0 AND l_value = 'Y'.
    LOOP AT SCREEN.
      IF screen-group1 = 'HID'.
        screen-invisible = 0.
        screen-input = 1.
        screen-active = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 = 'HID'.
        screen-invisible = 1.
        screen-input = 0.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.



  LOOP AT SCREEN.
    IF screen-name CS 'S_FUNCT' OR screen-name CS 'P_FNFLTR'.
      IF p_tfunct = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CONID' OR screen-name CS 'P_CNFLTR'.
      IF p_tconid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'P_CONFUN'.
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
      IF p_tcont = space AND p_tuasmt = space AND p_trasmt = space
      AND p_tgasmt = space AND p_tcasmt = space AND p_tcarol = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_MCONID'.
      IF p_tuasmt = space AND p_tgasmt = space AND p_trasmt = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_USERID'.
      IF p_tuasmt = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CLASS'.
      IF p_tgasmt = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_ROLE'.
      IF p_trasmt = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CAID'.
      IF p_tcasmt = space AND p_tcarol = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CAUSER'.
      IF p_tcasmt = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CAROLE'.
      IF p_tcarol = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TCODE' OR screen-name CS 'P_CTFLTR'.
      IF p_ttcode = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_AUDID' OR screen-name CS 'P_CAFLTR'.
      IF p_taudid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_AGRNAM'.
      IF p_tagrnm = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_PROF'.
      IF p_tprof = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TCONFG'.
      IF p_tconfg = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TAPAR'.
      IF p_tapar = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TPROCR'.
      IF p_tprocr = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TSYST'.
      IF p_tsyst = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TSYSC'.
      IF p_tsysc = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TPROJ'.
      IF p_tproj = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TSTAT'.
      IF p_tstat = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TORGLV'
        OR screen-name CS 'S_TORGLA'
        OR screen-name CS 'S_TORGLO'.
      IF p_torglv = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TRISK'.
      IF p_trisk = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TMITYP'.
      IF p_tmityp = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TFREQ'.
      IF p_tfreq = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'P_TFUNCT'.
*B8643.
      IF p_tfunct = space.
        REFRESH s_funct[].
        p_fnfltr = space.
      ENDIF.
*END.
      IF p_confun = 'X'.
*        screen-active = 0.
        screen-input = 0.
      ELSE.
*        screen-active = 1.
        screen-input = 1.
      ENDIF.
    ELSEIF screen-name CS 'S_VELEMT'  OR
           screen-name CS 'S_VEVRS'   OR
           screen-name CS 'P_VE_HDR' .
      IF p_velemt = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

* B8643.
    ELSEIF screen-name CS 'P_EMLTXT'.
      IF p_email = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'S_SETID'.
      IF p_cnfset = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'S_CTCOD'.
      IF p_dynam = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'P_TCONID'.
      IF p_tconid = space.
        REFRESH s_conid[].
        p_cnfltr = space.
      ENDIF.
    ELSEIF screen-name CS 'P_TTCODE'.
      IF p_ttcode = space.
        REFRESH s_tcode[].
        p_ctfltr = space.
      ENDIF.
    ELSEIF screen-name CS 'P_TAUDID'.
      IF p_taudid  = space.
        REFRESH s_audid[].
        p_cafltr = space.
      ENDIF.
    ELSEIF screen-name CS 'P_TCSCON'.
      IF p_tcscon = space.
        REFRESH s_cuscon[].
      ENDIF.
    ELSEIF screen-name CS 'S_APPID'.
      IF p_appid = space.
        screen-active = 0.
        screen-invisible = 1.
        REFRESH s_appid[].
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ENDIF.

*--SHow/Hide fields based on config set functionality being active
    IF gf_cfg_set_enabled <> 'X'.
*--Hide Config Set
      IF screen-name CS 'S_SETID' OR
         screen-name CS 'P_CNFSET'.
        screen-active    = 0.
        screen-invisible = 1.
      ENDIF.
    ELSE.
*--Hide Org Area
      IF screen-name CS 'S_TORGLV' OR
         screen-name CS 'S_TORGLA'  OR
         screen-name CS 'SS_TORGLO'  OR
         screen-name CS 'P_TORGLV'.
        screen-active    = 0.
        screen-invisible = 1.
      ENDIF.
    ENDIF.



    MODIFY SCREEN.
  ENDLOOP.

  IF p_tconid = 'X'.
    CHECK p_confun = 'X'.
    CHECK NOT s_conid[] IS INITIAL.
    SELECT * FROM /psyng/confdet INTO TABLE gt_confdet
            WHERE conid IN s_conid
            AND vrsio = p_vrsio.
    IF sy-subrc = 0.
      s_funct-sign = 'I'.
      s_funct-option = 'EQ'.

      LOOP AT gt_confdet.
        s_funct-low = gt_confdet-functionid.
        APPEND s_funct.
      ENDLOOP.
    ENDIF.
    SORT s_funct BY low.
    DELETE ADJACENT DUPLICATES FROM s_funct COMPARING low.
  ENDIF.

  IF p_appid = 'X'.
    IF s_appid[] IS INITIAL.
      s_appid-sign   = 'I'.
      s_appid-option = 'CP'.
      s_appid-low    = 'Z*'.
      APPEND s_appid.
    ENDIF.
  ENDIF.


*---------------- AT SELECTION-SCREEN ON VALUE-REQUEST ----------------*

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_funct-low.
  PERFORM f4_function CHANGING s_funct-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_funct-high.
  PERFORM f4_function CHANGING s_funct-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_conid-low.
  PERFORM f4_conflicts CHANGING s_conid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_conid-high.
  PERFORM f4_conflicts CHANGING s_conid-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_audid-low.
  PERFORM f4_crit_auth CHANGING s_audid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_audid-high.
  PERFORM f4_crit_auth CHANGING s_audid-high.
*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mconid-low.
  PERFORM f4_conflicts CHANGING s_mconid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_mconid-high.
  PERFORM f4_conflicts CHANGING s_mconid-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_userid-low.
  PERFORM f4_mcuser CHANGING s_userid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_userid-high.
  PERFORM f4_mcuser CHANGING s_userid-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_class-low.
  PERFORM f4_mcusrgrp CHANGING s_class-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_class-high.
  PERFORM f4_mcusrgrp CHANGING s_class-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR  s_role-low.
  PERFORM f4_mcrole CHANGING s_role-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR  s_role-high.
  PERFORM f4_mcrole CHANGING s_role-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR   s_caid-low.
  PERFORM f4_crit_auth CHANGING s_caid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR   s_caid-high.
  PERFORM f4_crit_auth CHANGING s_caid-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuscon-low.
  PERFORM f4_cuscon CHANGING s_cuscon-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuscon-high.
  PERFORM f4_cuscon CHANGING s_cuscon-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-low.
  PERFORM f4_ctcode CHANGING s_tcode-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-high.
  PERFORM f4_ctcode CHANGING s_tcode-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_agrnam-low.
  PERFORM f4_ctrole CHANGING s_agrnam-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_agrnam-high.
  PERFORM f4_ctrole CHANGING s_agrnam-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_prof-low.
  PERFORM f4_ctprof CHANGING s_prof-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_prof-high.
  PERFORM f4_ctprof CHANGING s_prof-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tconfg-low.
  PERFORM f4_config CHANGING s_tconfg-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tconfg-high.
  PERFORM f4_config CHANGING s_tconfg-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tstat-low.
  PERFORM f4_status CHANGING s_tstat-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tstat-high.
  PERFORM f4_status CHANGING s_tstat-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglo-low.
  PERFORM f4_orglvlo CHANGING s_torglo-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglo-high.
  PERFORM f4_orglvlo CHANGING s_torglo-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglv-low.
  PERFORM f4_orglvl CHANGING s_torglv-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglv-high.
  PERFORM f4_orglvl CHANGING s_torglv-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tfreq-low.
  PERFORM f4_frequency CHANGING s_tfreq-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tfreq-high.
  PERFORM f4_frequency CHANGING s_tfreq-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tproj-low.
  PERFORM f4_project CHANGING s_tproj-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tproj-high.
  PERFORM f4_project CHANGING s_tproj-high.

*Start of changes vk 19/3/18
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_velemt-low.
  PERFORM f4_elements CHANGING s_velemt-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_velemt-high.
  PERFORM f4_elements CHANGING s_velemt-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcod1-low.
  PERFORM f4_called_tcode CHANGING s_ctcod1-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcod1-high.
  PERFORM f4_called_tcode CHANGING s_ctcod1-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcode-low.
  PERFORM f4_calling_tcode CHANGING s_ctcode-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcode-high.
  PERFORM f4_calling_tcode CHANGING s_ctcode-high.

*End of changes

AT SELECTION-SCREEN ON VALUE-REQUEST FOR  p_emltxt-low.
  PERFORM f4_emltxt CHANGING p_emltxt-low.

*------------------------- START-OF-SELECTION -------------------------*
START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024

  IF p_tfunct = space AND p_tconid = space AND p_tcont = space
  AND p_tuasmt = space AND p_tgasmt = space AND p_ttcode = space
  AND p_taudid = space AND p_tagrnm = space AND p_tprof = space
  AND p_tcscon = space AND p_tconfg = space AND p_tapar = space
  AND p_tprocr = space AND p_tproj = space AND p_tstat = space
  AND p_tsyst = space AND p_tsysc = space
  AND p_torglv = space AND p_trisk = space AND p_tmityp = space
  AND p_tvhead = space AND p_tfreq = space AND p_trasmt = space
  AND p_tcasmt = space AND p_tcarol = space AND p_velemt = space
  AND p_dynam = space AND p_cnfset = space AND p_email = space
  AND p_corg = space AND p_appid = space.
    MESSAGE s113(/psyng/sw) WITH text-e01.
    LEAVE LIST-PROCESSING.
  ENDIF.

**  Bug 2721
*    upon Execution, when the "include relevant functions" checkbox is
*   on, we should gather all function ID at that point in case Conflict
**  IDs changed.
  IF p_confun = 'X'.
    PERFORM get_relevant_funcs.
  ENDIF.

  IF p_tvhead = 'X'.
    PERFORM transport_vrshead.
  ENDIF.

  IF p_tfunct = 'X'.
    PERFORM transport_functions.
  ENDIF.

  IF p_tconid = 'X'.
    PERFORM transport_conflicts.
  ENDIF.

  IF p_tcscon = 'X'.
    PERFORM transport_custom_conflicts.
  ENDIF.

  IF p_tcont = 'X'.
    PERFORM transport_mc.
  ENDIF.

  IF p_tuasmt = 'X'.
    PERFORM transport_user_assignment.
  ENDIF.

  IF p_tgasmt = 'X'.
    PERFORM transport_ugrp_assignment.
  ENDIF.

  IF p_trasmt = 'X'.
    PERFORM transport_role_assignment.
  ENDIF.

  IF p_tcasmt = 'X'.
    PERFORM transport_ca_assignment.
  ENDIF.

  IF p_tcarol = 'X'.
    PERFORM transport_ca_role_assignment.
  ENDIF.

  IF p_ttcode = 'X'.
    PERFORM transport_crittran.
  ENDIF.

  IF p_taudid = 'X'.
    PERFORM transport_critauths.
  ENDIF.

  IF p_tagrnm = 'X'.
    PERFORM transport_critroles.
  ENDIF.

  IF p_tprof = 'X'.
    PERFORM transport_critprofs.
  ENDIF.

  IF p_tconfg = 'X'.
    PERFORM transport_config.
  ENDIF.

  IF p_tapar = 'X'.
    PERFORM transport_app_areas.
  ENDIF.

  IF p_tprocr = 'X'.
    PERFORM transport_proc_areas.
  ENDIF.

  IF p_tproj = 'X'.
    PERFORM transport_projects.
  ENDIF.

  IF p_tsyst = 'X'.
    PERFORM transport_sys_types.
  ENDIF.

  IF p_tsysc = 'X'.
    PERFORM transport_sys_cat.
  ENDIF.

  IF p_tstat = 'X'.
    PERFORM transport_status.
  ENDIF.

  IF p_torglv = 'X'.
    PERFORM transport_orglvl.
  ENDIF.

  IF p_trisk = 'X'.
    PERFORM transport_risk.
  ENDIF.

  IF p_tmityp = 'X'.
    PERFORM transport_mit_types.
  ENDIF.

  IF p_tfreq = 'X'.
    PERFORM transport_frequency.
  ENDIF.

*Start of changes vk 19/3/2018
  IF p_velemt = 'X'.
    PERFORM transport_varelements.
  ENDIF.
*End of change

  IF p_dynam = 'X'.
    PERFORM transport_dynamic_enhance.
  ENDIF.

  IF p_cnfset = 'X'.
    PERFORM transport_configuration_set.
  ENDIF.

  IF p_email = 'X'.
    PERFORM transport_standard_email_txt.
  ENDIF.

  IF p_corg = 'X'.
    PERFORM transport_corg.
  ENDIF.

  IF p_appid = 'X'.
    PERFORM transport_custom_fiori_app_id.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  transport_vrshead
*&---------------------------------------------------------------------*
*       Transport Version header
*----------------------------------------------------------------------*
FORM transport_vrshead.
  DATA: BEGIN OF lt_vers OCCURS 0,
          mandt LIKE /psyng/swsodvers-mandt,
          vrsio LIKE /psyng/swsodvers-vrsio,
        END OF lt_vers.

* Get version header
  SELECT SINGLE mandt vrsio INTO lt_vers FROM /psyng/swsodvers
                WHERE vrsio = p_vrsio.
  APPEND lt_vers.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SWSODVERS'.
  gt_e071-objfunc  = 'K'.

* Add functions to transport
  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWSODVERS'.
  LOOP AT lt_vers.
    AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
             ID 'ACTVT' FIELD '01'
             ID 'Y&SW_VRSIO' FIELD p_vrsio.

    IF sy-subrc <> 0.
      WRITE: / text-e12, text-t10, lt_vers-vrsio.
      DELETE lt_vers.
      CONTINUE.
    ENDIF.

    MOVE lt_vers TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_vers[] IS INITIAL.

  APPEND gt_e071.

  PERFORM add_to_transport.
ENDFORM.                    " transport_vrshead

*&---------------------------------------------------------------------*
*&      Form  transport_functions
*&---------------------------------------------------------------------*
*       Transport Functions
*----------------------------------------------------------------------*
FORM transport_functions.
  DATA: BEGIN OF lt_func OCCURS 0,
          mandt    LIKE /psyng/function-mandt,
          function LIKE /psyng/function-function,
          vrsio    LIKE /psyng/function-vrsio,
        END OF lt_func,
        BEGIN OF lt_obj OCCURS 0,
          mandt    LIKE /psyng/faobj2-mandt,
          vrsio    LIKE /psyng/faobj2-vrsio,
          function LIKE /psyng/faobj2-funid,
        END OF lt_obj,
        BEGIN OF lt_tran OCCURS 0,
          mandt    LIKE /psyng/function-mandt,
          function LIKE /psyng/function-function,
          tcode    LIKE /psyng/functtran-tcode,
          vrsio    LIKE /psyng/function-vrsio,
        END OF lt_tran.

  DATA: lt_sysfun   TYPE TABLE OF /psyng/sw_sysfun WITH HEADER LINE,
        l_index     LIKE sy-tabix,
        lv_text(50) TYPE c.
* Get all function data
  SELECT mandt function vrsio INTO TABLE lt_func FROM /psyng/function
         WHERE function IN s_funct
           AND vrsio     = p_vrsio.

  DESCRIBE TABLE lt_func LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113(/psyng/sw)   WITH text-e03 text-e02.
    EXIT.
  ENDIF.

  SELECT mandt functionid tcode vrsio INTO TABLE lt_tran
         FROM /psyng/functtran
         WHERE functionid IN s_funct
           AND vrsio       = p_vrsio.
*  LOOP AT lt_tran.
*    l_index = sy-tabix.
*    IF lt_tran-type = ''.
*      IF lt_tran-fioriid = ''.
*        lt_tran-type = 'T'.
*      ELSE.
*        lt_tran-type = 'F'.
*      ENDIF.
*      MODIFY lt_tran INDEX l_index TRANSPORTING type.
*    ENDIF.
*  ENDLOOP.

  SELECT DISTINCT mandt vrsio funid INTO TABLE lt_obj FROM /psyng/faobj2
                                                  WHERE vrsio  = p_vrsio
                                                   AND funid IN s_funct.

  SELECT mandt textname object spras line vrsio INTO TABLE gt_texts
         FROM /psyng/texts
         WHERE textname IN s_funct
           AND object    = 'F'
*           AND spras     = sy-langu
           AND vrsio     = p_vrsio.

*system filters for function
  IF p_fnfltr = 'X'.
    SELECT * FROM /psyng/sw_sysfun INTO TABLE
      lt_sysfun WHERE vrsio = p_vrsio
         AND function IN s_funct.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/FUNCTION'.
  gt_e071-objfunc  = 'K'.

* Add functions to transport
  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/FUNCTION'.
  LOOP AT lt_func.
    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
             ID 'ACTVT' FIELD '21'
             ID 'Y&SW_VRSIO' FIELD p_vrsio
             ID 'Y&SW_FUNCT' FIELD lt_func-function.
    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e03, lt_func-function, text-t10, p_vrsio.
      DELETE lt_func.
      DELETE lt_tran WHERE function = lt_func-function.
      DELETE lt_obj WHERE function = lt_func-function.
      DELETE gt_texts WHERE textname = lt_func-function.
      CONTINUE.
    ENDIF.

    MOVE lt_func TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_func[] IS INITIAL.

  APPEND gt_e071.

* Add tcodes to transport
  DESCRIBE TABLE lt_tran LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/FUNCTTRAN'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/FUNCTTRAN'.
  LOOP AT lt_tran.
    CLEAR lv_text.
*    IF lt_tran-tcode CS '_'.
*      SPLIT lt_tran-tcode AT '_' INTO lt_tran-tcode lv_text.
*    ENDIF.
    MOVE lt_tran TO gt_e071k-tabkey.
*    CONCATENATE gt_e071k-tabkey '*' INTO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

*  Add system filters
  DESCRIBE TABLE lt_sysfun LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SW_SYSFUN'.
    APPEND gt_e071.
  ENDIF.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_SYSFUN'.
  LOOP AT lt_sysfun.
    MOVE lt_sysfun TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add auth objects to transport
  DESCRIBE TABLE lt_obj LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/FAOBJ2'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/FAOBJ2'.
  LOOP AT lt_obj.
    CLEAR lv_text.
    IF lt_obj-function CS '_'.
      SPLIT lt_obj-function AT '_' INTO lt_obj-function lv_text.
    ENDIF.
    MOVE lt_obj TO gt_e071k-tabkey.
*   Table key is > 120 characters to transport generically
    CONCATENATE gt_e071k-tabkey '*' INTO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE gt_texts LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/TEXTS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/TEXTS'.
  LOOP AT gt_texts.
    MOVE gt_texts TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  DESCRIBE TABLE lt_func LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/FUNCTION'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_functions

*&---------------------------------------------------------------------*
*&      Form  transport_conflicts
*&---------------------------------------------------------------------*
*       Transport SOD Conflicts
*----------------------------------------------------------------------*
FORM transport_conflicts.
  DATA: BEGIN OF lt_conflict OCCURS 0,
          mandt LIKE /psyng/conflict-mandt,
          conid LIKE /psyng/conflict-conid,
          vrsio LIKE /psyng/conflict-vrsio,
        END OF lt_conflict,

        BEGIN OF lt_confdet OCCURS 0,
          mandt      LIKE /psyng/confdet-mandt,
          conid      LIKE /psyng/confdet-conid,
          functionid LIKE /psyng/confdet-functionid,
          vrsio      LIKE /psyng/confdet-vrsio,
        END OF lt_confdet,
        BEGIN OF lt_conowner OCCURS 0,
          mandt   LIKE /psyng/conowner-mandt,
          vrsio   LIKE /psyng/conowner-vrsio,
          conid   LIKE /psyng/conowner-conid,
          owner   LIKE /psyng/conowner-owner,
          company LIKE /psyng/conowner-company,
        END OF lt_conowner.

  DATA lt_syscon TYPE TABLE OF /psyng/sw_syscon WITH HEADER LINE.


* Get all SOD conflict data
  SELECT mandt conid vrsio INTO TABLE lt_conflict FROM /psyng/conflict
         WHERE conid IN s_conid
           AND vrsio  = p_vrsio.

  DESCRIBE TABLE lt_conflict LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e04 text-e02.
    EXIT.
  ENDIF.

  SELECT * INTO TABLE lt_confdet FROM /psyng/confdet
         WHERE conid IN s_conid
           AND vrsio  = p_vrsio.

  SELECT * INTO CORRESPONDING FIELDS OF
         TABLE lt_conowner FROM /psyng/conowner
         WHERE conid IN s_conid
           AND vrsio  = p_vrsio.

  SELECT mandt textname object spras line vrsio INTO TABLE gt_texts
         FROM /psyng/texts
         WHERE textname IN s_conid
           AND object    = 'C'
*           AND spras     = sy-langu
           AND vrsio     = p_vrsio.

*system filters for conflict
  IF p_cnfltr = 'X'.
    SELECT * FROM /psyng/sw_syscon INTO TABLE
      lt_syscon WHERE vrsio = p_vrsio
               AND   conid IN s_conid.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/CONFLICT'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add conflicts to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/CONFLICT'.
  LOOP AT lt_conflict.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT' FIELD '21'
             ID 'Y&SW_CONID' FIELD lt_conflict-conid
             ID 'Y&SW_VRSIO' FIELD p_vrsio.
    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e04, lt_conflict-conid, text-t10, p_vrsio.
      DELETE lt_conflict.
      DELETE lt_confdet WHERE conid = lt_conflict-conid.
      DELETE gt_texts WHERE textname = lt_conflict-conid.
      CONTINUE.
    ENDIF.

    MOVE lt_conflict TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_conflict[] IS INITIAL.

  APPEND gt_e071.

* Add details to transport
  DESCRIBE TABLE lt_confdet LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/CONFDET'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/CONFDET'.
  LOOP AT lt_confdet.
    MOVE lt_confdet TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

*  Add system filters
  DESCRIBE TABLE lt_syscon LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SW_SYSCON'.
    APPEND gt_e071.
  ENDIF.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_SYSCON'.
  LOOP AT lt_syscon.
    MOVE lt_syscon TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add owners to transport
  DESCRIBE TABLE lt_conowner LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/CONOWNER'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/CONOWNER'.
  LOOP AT lt_conowner.
    MOVE lt_conowner TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE gt_texts LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/TEXTS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/TEXTS'.
  LOOP AT gt_texts.
    MOVE gt_texts TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  DESCRIBE TABLE lt_conflict LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/CONFLICT'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_conflicts

*&---------------------------------------------------------------------*
*&      Form  transport_custom_conflicts
*&---------------------------------------------------------------------*
*       Transport Custom SOD Conflicts
*----------------------------------------------------------------------*
FORM transport_custom_conflicts.
  DATA: BEGIN OF lt_cuscon OCCURS 0,
          mandt LIKE /psyng/sw_cuscon-mandt,
          conid LIKE /psyng/sw_cuscon-conid,
          vrsio LIKE /psyng/sw_cuscon-vrsio,
        END OF lt_cuscon.

* Get all SOD conflict data
  SELECT mandt conid vrsio INTO TABLE lt_cuscon FROM /psyng/sw_cuscon
         WHERE conid IN s_cuscon
           AND vrsio  = p_vrsio.

  DESCRIBE TABLE lt_cuscon LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e04 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_CUSCON'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add conflicts to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_CUSCON'.
  LOOP AT lt_cuscon.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT' FIELD '21'
             ID 'Y&SW_CONID' FIELD lt_cuscon-conid
             ID 'Y&SW_VRSIO' FIELD p_vrsio.
    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e04, lt_cuscon-conid, text-t10, p_vrsio.
      DELETE lt_cuscon.
      CONTINUE.
    ENDIF.

    MOVE lt_cuscon TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_cuscon[] IS INITIAL.

  APPEND gt_e071.

  DESCRIBE TABLE lt_cuscon LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/SW_CUSCON'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_custom_conflicts

*&---------------------------------------------------------------------*
*&      Form  transport_mc
*&---------------------------------------------------------------------*
*       Transport Mitigating Controls
*----------------------------------------------------------------------*
FORM transport_mc.
  DATA: BEGIN OF lt_mchdr OCCURS 0,
          mandt  LIKE /psyng/mchdr-mandt,
          contid LIKE /psyng/mchdr-contid,
        END OF lt_mchdr,

        BEGIN OF lt_mctran OCCURS 0,
          mandt  LIKE /psyng/mctran-mandt,
          contid LIKE /psyng/mctran-contid,
          tcode  LIKE /psyng/mctran-tcode,
        END OF lt_mctran,

        BEGIN OF lt_mcrepid OCCURS 0,
          mandt  LIKE /psyng/mcrepid-mandt,
          contid LIKE /psyng/mcrepid-contid,
          repid  LIKE /psyng/mcrepid-repid,
        END OF lt_mcrepid,

        BEGIN OF lt_mcauditor OCCURS 0,
          mandt  LIKE /psyng/mcauditor-mandt,
          contid LIKE /psyng/mcauditor-contid,
        END OF lt_mcauditor,

        BEGIN OF lt_mcrvwhdr OCCURS 0,
          mandt  LIKE /psyng/mcrvwhdr-mandt,
          contid LIKE /psyng/mcrvwhdr-contid,
        END OF lt_mcrvwhdr,

        BEGIN OF lt_mcrvwtext OCCURS 0,
          mandt      LIKE /psyng/mcrvwtxt-mandt,
          objectid   LIKE /psyng/mcrvwtxt-objectid,
          createuser LIKE /psyng/mcrvwtxt-createuser,
          createdate LIKE /psyng/mcrvwtxt-createdate,
          createtime LIKE /psyng/mcrvwtxt-createtime,
          line       LIKE /psyng/mcrvwtxt-line,
        END OF lt_mcrvwtext.
*        lt_mcauditor TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE.

* Get Mitigating Control data
  SELECT mandt contid  INTO TABLE lt_mchdr FROM /psyng/mchdr
         WHERE contid IN s_contid.

  DESCRIBE TABLE lt_mchdr LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e05 text-e02.
    EXIT.
  ENDIF.

  SELECT mandt contid tcode  INTO TABLE lt_mctran
         FROM /psyng/mctran
         WHERE contid IN s_contid.

  SELECT mandt contid repid  INTO TABLE lt_mcrepid
         FROM /psyng/mcrepid
         WHERE contid IN s_contid.

  SELECT * INTO CORRESPONDING FIELDS OF
  TABLE lt_mcauditor FROM /psyng/mcauditor
         WHERE contid IN s_contid.

  SELECT * INTO CORRESPONDING FIELDS OF TABLE
     lt_mcrvwhdr FROM /psyng/mcrvwhdr
     WHERE contid IN s_contid.

  SELECT mandt textname object spras line vrsio INTO TABLE gt_texts
         FROM /psyng/texts
         WHERE textname IN s_contid
           AND object    = 'M'.
*           AND spras     = sy-langu.

*select mandt objectid createuser createdate createtime line
*into corresponding fields of table
*    lt_mcrvwtxt from /psyng/mcrvwtxt where
*      OBJECTID in s_contid.


  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/MCHDR'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Mitigating Controls to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCHDR'.
  LOOP AT lt_mchdr.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'      FIELD '21'
             ID 'Y&SW_CNTID' FIELD lt_mchdr-contid
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e05, lt_mchdr-contid.
      DELETE lt_mchdr.
      DELETE lt_mctran WHERE contid = lt_mchdr-contid.
      DELETE lt_mcrepid WHERE contid = lt_mchdr-contid.
      DELETE lt_mcauditor WHERE contid = lt_mchdr-contid.
      DELETE gt_texts WHERE textname = lt_mchdr-contid.

      CONTINUE.
    ENDIF.

    MOVE lt_mchdr TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_mchdr[] IS INITIAL.

  APPEND gt_e071.

* Add tcodes to transport
  DESCRIBE TABLE lt_mctran LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/MCTRAN'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCTRAN'.
  LOOP AT lt_mctran.
    MOVE lt_mctran TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add reports to transport
  DESCRIBE TABLE lt_mcrepid LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/MCREPID'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCREPID'.
  LOOP AT lt_mcrepid.
    MOVE lt_mcrepid TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add auditors to transport
  DESCRIBE TABLE lt_mcauditor LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/MCAUDITOR'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCAUDITOR'.
  LOOP AT lt_mcauditor.
    MOVE lt_mcauditor TO gt_e071k-tabkey.
    CONCATENATE gt_e071k-tabkey '*' INTO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE lt_mcrvwhdr LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/MCRVWHDR'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCRVWHDR'.
  LOOP AT lt_mcrvwhdr.
    MOVE lt_mcrvwhdr TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE gt_texts LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/TEXTS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/TEXTS'.
  LOOP AT gt_texts.
    MOVE gt_texts TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  DESCRIBE TABLE lt_mchdr LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/MCHDR'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_mc

*&---------------------------------------------------------------------*
*&      Form  transport_user_assignment
*&---------------------------------------------------------------------*
*       Transport Mitigating Control assignments to users
*----------------------------------------------------------------------*
FORM transport_user_assignment.
  DATA: BEGIN OF lt_user OCCURS 0,
          mandt  LIKE /psyng/mcuser-mandt,
          contid LIKE /psyng/mcuser-contid,
          conid  LIKE /psyng/mcuser-conid,
          userid LIKE /psyng/mcuser-userid,
          vrsio  LIKE /psyng/mcuser-vrsio,
"Begin of Change : UMITTAL 31/10/2024 PN-3552 C1299
          auditor   LIKE /psyng/mcuser-auditor,
          from_date LIKE /psyng/mcuser-from_date,
          to_date   LIKE /psyng/mcuser-to_date,
"End of Change : UMITTAL 31/10/2024 PN-3552 C1299
        END OF lt_user.

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

* Get Mitigating Control User Assignment data
  SELECT mandt contid conid userid vrsio
"Begin of Change : Umittal 31/10/2024 PN-3552 C1299
         auditor
         from_date
         to_date
"End of Change : Umittal 31/10/2024 PN-3552 C1299
    INTO TABLE lt_user
         FROM /psyng/mcuser
         WHERE contid IN s_contid
           AND conid  IN s_mconid
           AND userid IN s_userid
           AND vrsio   = p_vrsio.
*DHO 20101202

  LOOP AT lt_user.
    lt_uinfo-bname = lt_user-userid.
    APPEND lt_uinfo.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_USER_INFO'
    EXPORTING
      vrsio        = p_vrsio
*     ENHANCED_SCANTABLE       = ''
      i_name_only  = 'X'
      i_mr_company = 'X'
    TABLES
      sw_uinfo     = lt_uinfo.

  DESCRIBE TABLE lt_user LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e10 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/MCUSER'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Mitigating Controls User Assignment to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCUSER'.
  LOOP AT lt_user.
    READ TABLE lt_uinfo WITH KEY bname = lt_user-userid.
*DHO 20101202
    IF lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
               ID 'ACTVT' FIELD '21'
               ID 'Y&SW_VRSIO' FIELD p_vrsio
               ID 'Y&SW_CNTID' FIELD lt_user-contid
               ID 'Y&SW_CONID' FIELD lt_user-conid
               ID 'Y&SW_BNAME' FIELD lt_user-userid
               ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e95).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
    ELSE.
      AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
               ID 'ACTVT' FIELD '21'
               ID 'Y&SW_VRSIO' FIELD p_vrsio
               ID 'Y&SW_CNTID' FIELD lt_user-contid
               ID 'Y&SW_CONID' FIELD lt_user-conid
               ID 'Y&SW_BNAME' FIELD lt_user-userid
               ID 'Y&SW_COMP'  FIELD lt_uinfo-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e95).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
    ENDIF.

    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e10, lt_user-contid, lt_user-conid,
               lt_user-userid, text-t10, p_vrsio.
      DELETE lt_user.
      CONTINUE.
    ENDIF.

    MOVE lt_user TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_user[] IS INITIAL.

  APPEND gt_e071.

  DESCRIBE TABLE lt_user LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/MCUSER'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_user_assignment

*&---------------------------------------------------------------------*
*&      Form  transport_ugrp_assignment
*&---------------------------------------------------------------------*
*       Transport Mitigating Control assignments to user groups
*----------------------------------------------------------------------*
FORM transport_ugrp_assignment.
  DATA: BEGIN OF lt_usrgrp OCCURS 0,
          mandt  LIKE /psyng/mcusrgrp-mandt,
          contid LIKE /psyng/mcusrgrp-contid,
          conid  LIKE /psyng/mcusrgrp-conid,
          class  LIKE /psyng/mcusrgrp-class,
          vrsio  LIKE /psyng/mcusrgrp-vrsio,
        END OF lt_usrgrp.

* Get Mitigating Control User Groups Assignment data
  SELECT mandt contid conid class vrsio INTO TABLE lt_usrgrp
         FROM /psyng/mcusrgrp
         WHERE contid IN s_contid
           AND conid  IN s_mconid
           AND class  IN s_class
           AND vrsio   = p_vrsio.

  DESCRIBE TABLE lt_usrgrp LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e11 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/MCUSRGRP'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Mitigating Controls User Group Assignment to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCUSRGRP'.
  LOOP AT lt_usrgrp.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
             ID 'ACTVT' FIELD '21'
             ID 'Y&SW_VRSIO' FIELD p_vrsio
             ID 'Y&SW_CNTID' FIELD lt_usrgrp-contid
             ID 'Y&SW_CONID' FIELD lt_usrgrp-conid
             ID 'Y&SW_CLASS' FIELD lt_usrgrp-class.

    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e11, lt_usrgrp-contid, lt_usrgrp-conid,
               lt_usrgrp-class, text-t10, p_vrsio.
      DELETE lt_usrgrp.
      CONTINUE.
    ENDIF.

    MOVE lt_usrgrp TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_usrgrp[] IS INITIAL.

  APPEND gt_e071.

  DESCRIBE TABLE lt_usrgrp LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/MCUSRGRP'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_ugrp_assignment

*&---------------------------------------------------------------------*
*&      Form  transport_role_assignment
*&---------------------------------------------------------------------*
*       Transport Mitigating Control assignments to role
*----------------------------------------------------------------------*
FORM transport_role_assignment.
  DATA: BEGIN OF lt_role OCCURS 0,
          mandt    LIKE /psyng/mcrole-mandt,
          contid   LIKE /psyng/mcrole-contid,
          conid    LIKE /psyng/mcrole-conid,
          agr_name LIKE /psyng/mcrole-agr_name,
          vrsio    LIKE /psyng/mcrole-vrsio,
        END OF lt_role.

* Get Mitigating Control Roles Assignment data
  SELECT mandt contid conid agr_name vrsio INTO TABLE lt_role
         FROM /psyng/mcrole
         WHERE contid   IN s_contid
           AND conid    IN s_mconid
           AND agr_name IN s_role
           AND vrsio     = p_vrsio.

  DESCRIBE TABLE lt_role LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e20 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/MCROLE'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Mitigating Controls User Group Assignment to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCROLE'.
  LOOP AT lt_role.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
             ID 'ACTVT'      FIELD '21'
             ID 'Y&SW_VRSIO' FIELD p_vrsio
             ID 'Y&SW_CNTID' FIELD lt_role-contid
             ID 'Y&SW_CONID' FIELD lt_role-conid
             ID 'ACT_GROUP'  FIELD lt_role-agr_name.

    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e20, lt_role-contid, lt_role-conid,
               lt_role-agr_name, text-t10, p_vrsio.
      DELETE lt_role.
      CONTINUE.
    ENDIF.

    MOVE lt_role TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_role[] IS INITIAL.

  APPEND gt_e071.

  DESCRIBE TABLE lt_role LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/MCROLE'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_role_assignment

*&---------------------------------------------------------------------*
*&      Form  transport_ca_assignment
*&---------------------------------------------------------------------*
*       Transport Mitigating Control assignments to critical auth users
*----------------------------------------------------------------------*
FORM transport_ca_assignment.
  DATA: BEGIN OF lt_ca OCCURS 0,
          mandt   LIKE /psyng/mccauser-mandt,
          contid  LIKE /psyng/mccauser-contid,
          swaudid LIKE /psyng/mccauser-swaudid,
          userid  LIKE /psyng/mccauser-userid,
          vrsio   LIKE /psyng/mccauser-vrsio,
        END OF lt_ca.

* Get Mitigating Control Critical Auths Assignment data
  SELECT mandt contid swaudid userid vrsio INTO TABLE lt_ca
         FROM /psyng/mccauser
         WHERE contid  IN s_contid
           AND swaudid IN s_caid
           AND userid  IN s_causer
           AND vrsio    = p_vrsio.

  DESCRIBE TABLE lt_ca LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e21 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/MCCAUSER'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Mitigating Controls Critical Auth Assignment to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCCAUSER'.
  LOOP AT lt_ca.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
             ID 'ACTVT'      FIELD '21'
             ID 'Y&SW_VRSIO' FIELD p_vrsio
             ID 'Y&SW_SWAUD' FIELD lt_ca-swaudid
             ID 'Y&SW_CNTID' FIELD lt_ca-contid
             ID 'Y&SW_BNAME' FIELD lt_ca-userid.

    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e11, lt_ca-contid, lt_ca-swaudid,
               lt_ca-userid, text-t10, p_vrsio.
      DELETE lt_ca.
      CONTINUE.
    ENDIF.

    MOVE lt_ca TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_ca[] IS INITIAL.

  APPEND gt_e071.

  DESCRIBE TABLE lt_ca LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/MCCAUSER'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_ca_assignment

*&---------------------------------------------------------------------*
*&      Form  transport_ca_role_assignment
*&---------------------------------------------------------------------*
*       Transport Mitigating Control assignments to critical auth roles
*----------------------------------------------------------------------*
FORM transport_ca_role_assignment.
  DATA: BEGIN OF lt_ca OCCURS 0,
          mandt    LIKE /psyng/mccarole-mandt,
          contid   LIKE /psyng/mccarole-contid,
          swaudid  LIKE /psyng/mccarole-swaudid,
          agr_name LIKE /psyng/mccarole-agr_name,
          vrsio    LIKE /psyng/mccarole-vrsio,
        END OF lt_ca.

* Get Mitigating Control Critical Auths Assignment data
  SELECT mandt contid swaudid agr_name vrsio INTO TABLE lt_ca
         FROM /psyng/mccarole
         WHERE contid  IN s_contid
           AND swaudid IN s_caid
           AND agr_name IN s_carole
           AND vrsio    = p_vrsio.

  DESCRIBE TABLE lt_ca LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e21 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/MCCAROLE'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Mitigating Controls Critical Auth Assignment to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/MCCAROLE'.
  LOOP AT lt_ca.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
             ID 'ACTVT'      FIELD '21'
             ID 'Y&SW_VRSIO' FIELD p_vrsio
             ID 'Y&SW_SWAUD' FIELD lt_ca-swaudid
             ID 'Y&SW_CNTID' FIELD lt_ca-contid
             ID 'ACT_GROUP'  FIELD lt_ca-agr_name.

    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e07, lt_ca-contid, lt_ca-swaudid,
               lt_ca-agr_name, text-t10, p_vrsio.
      DELETE lt_ca.
      CONTINUE.
    ENDIF.

    MOVE lt_ca TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_ca[] IS INITIAL.

  APPEND gt_e071.

  DESCRIBE TABLE lt_ca LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/MCCAROLE'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_ca_role_assignment

*&---------------------------------------------------------------------*
*&      Form  transport_crittran
*&---------------------------------------------------------------------*
*       Transport Critical Transactions
*----------------------------------------------------------------------*
FORM transport_crittran.
  DATA: BEGIN OF lt_tcodes OCCURS 0,
          mandt LIKE /psyng/critcodes-mandt,
          tcode LIKE /psyng/critcodes-tcode,
          vrsio LIKE /psyng/critcodes-vrsio,
*          owner LIKE /psyng/critcodes-owner,
*          imp LIKE /psyng/critcodes-imp,
        END OF lt_tcodes.
  DATA lt_systcd TYPE TABLE OF /psyng/sw_systcd WITH HEADER LINE.

  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
           ID 'ACTVT' FIELD '21'
           ID 'Y&SW_VRSIO' FIELD p_vrsio.
  IF sy-subrc <> 0.
    WRITE: / text-e12, text-e06, text-t10, p_vrsio.
    EXIT.
  ENDIF.

* Get Critical Tcode data
  SELECT mandt tcode vrsio INTO TABLE lt_tcodes FROM /psyng/critcodes
         WHERE tcode IN s_tcode
           AND vrsio  = p_vrsio.

  SELECT mandt textname object spras line vrsio INTO TABLE gt_texts
         FROM /psyng/texts
         WHERE textname IN s_tcode
           AND object    = 'X'
*           AND spras     = sy-langu
           AND vrsio     = p_vrsio.

  IF p_ctfltr = 'X'.
    SELECT * FROM /psyng/sw_systcd INTO TABLE
          lt_systcd WHERE vrsio = p_vrsio
             AND         tcode IN s_tcode.
  ENDIF.

  DESCRIBE TABLE lt_tcodes LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e06 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/CRITCODES'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Critical Tcodes to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/CRITCODES'.
  LOOP AT lt_tcodes.
    MOVE lt_tcodes TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE gt_texts LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/TEXTS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/TEXTS'.
  LOOP AT gt_texts.
    MOVE gt_texts TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

*  Add system filters
  DESCRIBE TABLE lt_systcd LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SW_SYSTCD'.
    APPEND gt_e071.
  ENDIF.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_SYSTCD'.
  LOOP AT lt_systcd.
    MOVE lt_systcd TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_crittran

*&---------------------------------------------------------------------*
*&      Form  transport_critauths
*&---------------------------------------------------------------------*
*       Transport Critical Authorizations
*----------------------------------------------------------------------*
FORM transport_critauths.
  DATA: BEGIN OF lt_audhdr OCCURS 0,
          mandt   LIKE /psyng/swaudhdr-mandt,
          swaudid LIKE /psyng/swaudhdr-swaudid,
          vrsio   LIKE /psyng/swaudhdr-vrsio,
        END OF lt_audhdr,

        BEGIN OF lt_audc OCCURS 0,
          mandt   LIKE /psyng/swaudc2-mandt,
          vrsio   LIKE /psyng/swaudc2-vrsio,
          swaudid LIKE /psyng/swaudc2-swaudid,
        END OF lt_audc.

  DATA lt_sysca TYPE TABLE OF /psyng/sw_sysca WITH HEADER LINE.
* Get Critical Authorization data
  SELECT mandt swaudid vrsio INTO TABLE lt_audhdr FROM /psyng/swaudhdr
         WHERE swaudid IN s_audid
           AND vrsio    = p_vrsio.

  SELECT DISTINCT mandt vrsio swaudid INTO TABLE lt_audc
         FROM /psyng/swaudc2
         WHERE vrsio    = p_vrsio
           AND swaudid IN s_audid.

  SELECT mandt textname object spras line vrsio INTO TABLE gt_texts
         FROM /psyng/texts
         WHERE textname IN s_audid
           AND object    = 'T'
*           AND spras     = sy-langu
           AND vrsio     = p_vrsio.

  IF p_cafltr = 'X'.
    SELECT * FROM /psyng/sw_sysca INTO TABLE
          lt_sysca WHERE vrsio = p_vrsio
             AND       swaudid IN s_audid.
  ENDIF.

  DESCRIBE TABLE lt_audhdr LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e07 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SWAUDHDR'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Critical Authorizations to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWAUDHDR'.
  LOOP AT lt_audhdr.
    AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
             ID 'ACTVT' FIELD '21'
             ID 'Y&SW_AUTID' FIELD lt_audhdr-swaudid
             ID 'Y&SW_VRSIO' FIELD p_vrsio.
    IF sy-subrc <> 0.
      WRITE: / text-e12, text-e07, lt_audhdr-swaudid, text-t10, p_vrsio.
      DELETE lt_audhdr.
      DELETE lt_audc WHERE swaudid = lt_audhdr-swaudid.
      DELETE gt_texts WHERE textname = lt_audhdr-swaudid.
      CONTINUE.
    ENDIF.

    MOVE lt_audhdr TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_audhdr[] IS INITIAL.

  APPEND gt_e071.

* Add reports to transport
  DESCRIBE TABLE lt_audc LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SWAUDC2'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWAUDC2'.
  LOOP AT lt_audc.
    MOVE lt_audc TO gt_e071k-tabkey.
*   Table key is > 120 characters to transport generically
    CONCATENATE gt_e071k-tabkey '*' INTO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

*  Add system filters
  DESCRIBE TABLE lt_sysca LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SW_SYSCA'.
    APPEND gt_e071.
  ENDIF.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_SYSCA'.
  LOOP AT lt_sysca.
    MOVE lt_sysca TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE gt_texts LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/TEXTS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/TEXTS'.
  LOOP AT gt_texts.
    MOVE gt_texts TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  DESCRIBE TABLE lt_audhdr LINES sy-tfill.
  IF sy-tfill = 0.
    DELETE gt_e071 WHERE obj_name = '/PSYNG/SWAUDHDR'.
    EXIT.
  ENDIF.

  PERFORM add_to_transport.
ENDFORM.                    " transport_critauths

*&---------------------------------------------------------------------*
*&      Form  transport_critroles
*&---------------------------------------------------------------------*
*       Transport Critical Roles
*----------------------------------------------------------------------*
FORM transport_critroles.
  DATA: BEGIN OF lt_roles OCCURS 0,
          mandt    LIKE /psyng/criroles-mandt,
          agr_name LIKE /psyng/criroles-agr_name,
          vrsio    LIKE /psyng/criroles-vrsio,
        END OF lt_roles.


  AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
           ID 'ACTVT' FIELD '21'
           ID 'Y&SW_VRSIO' FIELD p_vrsio.

  IF sy-subrc <> 0.
    WRITE: / text-e12, text-e08, lt_roles-agr_name, text-t10, p_vrsio.
    EXIT.
  ENDIF.

* Get Critical Role data
  SELECT mandt agr_name vrsio INTO TABLE lt_roles FROM /psyng/criroles
         WHERE agr_name IN s_agrnam
           AND vrsio     = p_vrsio.

  SELECT mandt textname object spras line vrsio INTO TABLE gt_texts
    FROM /psyng/texts
    WHERE textname IN s_agrnam
      AND object    = 'Q'
*      AND spras     = sy-langu
      AND vrsio     = p_vrsio.

  DESCRIBE TABLE lt_roles LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e08 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/CRIROLES'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Critical Roles to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/CRIROLES'.
  LOOP AT lt_roles.
    MOVE lt_roles TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE gt_texts LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/TEXTS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/TEXTS'.
  LOOP AT gt_texts.
    MOVE gt_texts TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.



  PERFORM add_to_transport.
ENDFORM.                    " transport_critroles

*&---------------------------------------------------------------------*
*&      Form  transport_critprofs
*&---------------------------------------------------------------------*
*       Transport Critical Profiles
*----------------------------------------------------------------------*
FORM transport_critprofs.
  DATA: BEGIN OF lt_prof OCCURS 0,
          mandt   LIKE /psyng/criprof-mandt,
          profile LIKE /psyng/criprof-profile,
          vrsio   LIKE /psyng/criprof-vrsio,
        END OF lt_prof.


  AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
           ID 'ACTVT' FIELD '21'
           ID 'Y&SW_VRSIO' FIELD p_vrsio.
  IF sy-subrc <> 0.
    WRITE: / text-e12, text-e09, lt_prof-profile, text-t10, p_vrsio.
    EXIT.
  ENDIF.

* Get Critical Profile data
  SELECT mandt profile vrsio INTO TABLE lt_prof FROM /psyng/criprof
         WHERE profile IN s_prof
           AND vrsio    = p_vrsio.

  SELECT mandt textname object spras line vrsio INTO TABLE gt_texts
        FROM /psyng/texts
        WHERE textname IN s_prof
          AND object    = 'P'
*          AND spras     = sy-langu
          AND vrsio     = p_vrsio.

  DESCRIBE TABLE lt_prof LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e09 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/CRIPROF'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Critical Profiles to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/CRIPROF'.
  LOOP AT lt_prof.
    MOVE lt_prof TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add texts to transport
  DESCRIBE TABLE gt_texts LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/TEXTS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/TEXTS'.
  LOOP AT gt_texts.
    MOVE gt_texts TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.


  PERFORM add_to_transport.
ENDFORM.                    " transport_critprofs

*&---------------------------------------------------------------------*
*&      Form  transport_config
*&---------------------------------------------------------------------*
*       Transport Config
*----------------------------------------------------------------------*
FORM transport_config.
  DATA: BEGIN OF lt_config OCCURS 0,
          mandt LIKE /psyng/swconfig-mandt,
          param LIKE /psyng/swconfig-param,
        END OF lt_config.

* Get Configuration data
  SELECT mandt param INTO TABLE lt_config FROM /psyng/swconfig
  WHERE param IN s_tconfg.

  DESCRIBE TABLE lt_config LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-t11 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SWCONFIG'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Config data to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWCONFIG'.
  LOOP AT lt_config.
    MOVE lt_config TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_config

*&---------------------------------------------------------------------*
*&      Form  transport_app_areas
*&---------------------------------------------------------------------*
*       Transport Application Areas
*----------------------------------------------------------------------*
FORM transport_app_areas.
  DATA: BEGIN OF lt_busarea OCCURS 0,
          mandt   LIKE /psyng/busarea-mandt,
          busarea LIKE /psyng/busarea-busarea,
        END OF lt_busarea.

* Get Application Area data
  SELECT mandt busarea INTO TABLE lt_busarea FROM /psyng/busarea
  WHERE busarea IN s_tapar.

  DESCRIBE TABLE lt_busarea LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e13 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/BUSAREA'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add App Areas to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/BUSAREA'.
  LOOP AT lt_busarea.
    MOVE lt_busarea TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_app_areas

*&---------------------------------------------------------------------*
*&      Form  transport_proc_areas
*&---------------------------------------------------------------------*
*       Transport
*----------------------------------------------------------------------*
FORM transport_proc_areas.
  DATA: BEGIN OF lt_bus_proce OCCURS 0,
          mandt   LIKE /psyng/bus_proce-mandt,
          subarea LIKE /psyng/bus_proce-subarea,
        END OF lt_bus_proce.

* Get Process Area data
  SELECT mandt subarea INTO TABLE lt_bus_proce FROM /psyng/bus_proce
  WHERE subarea IN s_tprocr.

  DESCRIBE TABLE lt_bus_proce LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e14 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/BUS_PROCE'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add process areas to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/BUS_PROCE'.
  LOOP AT lt_bus_proce.
    MOVE lt_bus_proce TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_proc_areas

*&---------------------------------------------------------------------*
*&      Form  transport_projects
*&---------------------------------------------------------------------*
*       Transport projects
*----------------------------------------------------------------------*
FORM transport_projects.
  DATA: BEGIN OF lt_prj OCCURS 0,
          mandt   LIKE /psyng/sw_prj01-mandt,
          project LIKE /psyng/sw_prj01-project,
        END OF lt_prj.

* Get project data
  SELECT mandt project INTO TABLE lt_prj FROM /psyng/sw_prj01
  WHERE project IN s_tproj.

  DESCRIBE TABLE lt_prj LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e15 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_PRJ01'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add project to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_PRJ01'.
  LOOP AT lt_prj.
    MOVE lt_prj TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_projects

*&---------------------------------------------------------------------*
*&      Form  transport_status
*&---------------------------------------------------------------------*
*       Transport
*----------------------------------------------------------------------*
FORM transport_status.
  DATA: BEGIN OF lt_stat OCCURS 0,
          mandt  LIKE /psyng/sw_sta01-mandt,
          status LIKE /psyng/sw_sta01-status,
        END OF lt_stat.

* Get status data
  SELECT mandt status INTO TABLE lt_stat FROM /psyng/sw_sta01
  WHERE status IN s_tstat.

  DESCRIBE TABLE lt_stat LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e16 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_STA01'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add stats to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_STA01'.
  LOOP AT lt_stat.
    MOVE lt_stat TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_status

*&---------------------------------------------------------------------*
*&      Form  transport_orglvl
*&---------------------------------------------------------------------*
*       Transport Org. Levels
*----------------------------------------------------------------------*
FORM transport_orglvl.
  DATA: BEGIN OF lt_orglvl OCCURS 0,
          mandt  LIKE /psyng/swsodorgm-mandt,
          abb    LIKE /psyng/swsodorgm-abb,
          object LIKE /psyng/swsodorgm-object,
          varbl  LIKE /psyng/swsodorgm-varbl,
          low    LIKE /psyng/swsodorgm-low,
        END OF lt_orglvl.

* Get Org. Level data
  SELECT mandt abb object varbl low INTO TABLE lt_orglvl
         FROM /psyng/swsodorgm
         WHERE varbl IN s_torglv
           AND object IN s_torglo
           AND abb IN s_torgla.

  DESCRIBE TABLE lt_orglvl LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e17 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SWSODORGM'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add org levels to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWSODORGM'.
  LOOP AT lt_orglvl.
    MOVE lt_orglvl TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_orglvl

*&---------------------------------------------------------------------*
*&      Form  transport_risk
*&---------------------------------------------------------------------*
*       Transport Risk Scenarios
*----------------------------------------------------------------------*
FORM transport_risk.
  DATA: BEGIN OF lt_risk OCCURS 0,
          mandt LIKE /psyng/sw_risk-mandt,
          risk  LIKE /psyng/sw_risk-risk,
        END OF lt_risk.

* Get Risk Scenario data
  SELECT mandt risk INTO TABLE lt_risk FROM /psyng/sw_risk
  WHERE risk IN s_trisk.

  DESCRIBE TABLE lt_risk LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e18 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_RISK'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add risk scenarios to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_RISK'.
  LOOP AT lt_risk.
    MOVE lt_risk TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_risk

*&---------------------------------------------------------------------*
*&      Form  transport_mit_types
*&---------------------------------------------------------------------*
*       Transport Mitigation Types
*----------------------------------------------------------------------*
FORM transport_mit_types.
  DATA: BEGIN OF lt_mctyp OCCURS 0,
          mandt LIKE /psyng/sw_mctype-mandt,
          type  LIKE /psyng/sw_mctype-type,
        END OF lt_mctyp.

* Get Mitigation Type data
  SELECT mandt type INTO TABLE lt_mctyp FROM /psyng/sw_mctype
  WHERE type IN s_tmityp.

  DESCRIBE TABLE lt_mctyp LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e19 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_MCTYPE'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add mitigation types to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_MCTYPE'.
  LOOP AT lt_mctyp.
    MOVE lt_mctyp TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.                    " transport_mit_types


*---------------------------------------------------------------------*
*       FORM transport_frequency                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM transport_frequency.
  DATA: BEGIN OF lt_freq OCCURS 0,
          mandt LIKE /psyng/sw_freq-mandt,
          freq  LIKE /psyng/sw_freq-freq,
        END OF lt_freq,
        BEGIN OF lt_freqt OCCURS 0,
          mandt LIKE /psyng/sw_freqt-mandt,
          freq  LIKE /psyng/sw_freqt-freq,
          lang  LIKE /psyng/sw_freqt-lang,
        END OF lt_freqt.

* Get Frequency data
  SELECT mandt freq INTO TABLE lt_freq FROM /psyng/sw_freq
  WHERE freq IN s_tfreq.
  IF NOT lt_freq[] IS INITIAL.
    SELECT mandt freq lang INTO TABLE lt_freqt FROM /psyng/sw_freqt
    FOR ALL ENTRIES IN lt_freq
    WHERE freq = lt_freq-freq.
    DESCRIBE TABLE lt_freq LINES sy-tfill.
    IF sy-tfill = 0.
      MESSAGE i113 WITH 'Frequency'(e22) text-e02.
      EXIT.
    ENDIF.
  ENDIF.
  PERFORM create_transport.
*--Frequency
  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_FREQ'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add frequencies to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_FREQ'.
  LOOP AT lt_freq.
    MOVE lt_freq TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.
*--Frequency Text
  gt_e071-obj_name = '/PSYNG/SW_FREQT'.
  APPEND gt_e071.
* Add frequency texts to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_FREQT'.
  LOOP AT lt_freqt.
    MOVE lt_freqt TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.
  PERFORM add_to_transport.
ENDFORM.                    " transport_mit_types


*&---------------------------------------------------------------------*
*&      Form  create_transport
*&---------------------------------------------------------------------*
*       Create/choose transport request
*----------------------------------------------------------------------*
FORM create_transport.
  CHECK g_trkorr IS INITIAL.

  CALL FUNCTION 'TRINT_ORDER_CHOICE'
    EXPORTING
      wi_order_type          = 'W'
      wi_task_type           = 'Q'
      wi_category            = 'CUST'
      wi_cli_dep             = 'X'
      wi_display_button      = 'X'
    IMPORTING
      we_task                = g_trkorr
    TABLES
      wt_e071                = gt_e071
      wt_e071k               = gt_e071k
    EXCEPTIONS
      no_correction_selected = 1
      display_mode           = 2
      object_append_error    = 3
      recursive_call         = 4
      wrong_order_type       = 5
      OTHERS                 = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* Get existing data
  SELECT * INTO TABLE gt_e071 FROM e071
         WHERE trkorr = g_trkorr.

  SELECT * INTO TABLE gt_e071k FROM e071k
         WHERE trkorr = g_trkorr.
ENDFORM.                    " create_transport

*&---------------------------------------------------------------------*
*&      Form  add_to_transport
*&---------------------------------------------------------------------*
*       Add entries to transport
*----------------------------------------------------------------------*
FORM add_to_transport.

  DATA: ls_e070 TYPE e070,
        ls_e07t TYPE e07t.
  DATA : l_trnsport TYPE e070-strkorr.

  SELECT SINGLE * INTO ls_e070 FROM e070
                WHERE trkorr = g_trkorr.

  SELECT SINGLE * INTO ls_e07t FROM e07t
                WHERE trkorr = g_trkorr.

  SORT gt_e071 BY pgmid object obj_name.
  DELETE ADJACENT DUPLICATES FROM gt_e071
                             COMPARING pgmid object obj_name.
  SORT gt_e071k BY pgmid object objname tabkey.
  DELETE ADJACENT DUPLICATES FROM gt_e071k
                             COMPARING pgmid object objname tabkey.

  CALL FUNCTION 'TRINT_MODIFY_COMM'
    EXPORTING
      wi_called_by_editor            = 'X'
      wi_e070                        = ls_e070
      wi_e07t                        = ls_e07t
      wi_lock_sort_flag              = 'X'
      wi_save_user                   = 'X'
      wi_sel_e071                    = 'X'
      wi_sel_e071k                   = 'X'
      wi_sel_e07t                    = space
    TABLES
      wt_e071                        = gt_e071
      wt_e071k                       = gt_e071k
    EXCEPTIONS
      chosen_project_closed          = 1
      e070_insert_error              = 2
      e070_update_error              = 3
      e071k_insert_error             = 4
      e071k_update_error             = 5
      e071_insert_error              = 6
      e071_update_error              = 7
      e07t_insert_error              = 8
      e07t_update_error              = 9
      e070c_insert_error             = 10
      e070c_update_error             = 11
      locked_entries                 = 12
      locked_object_not_deleted      = 13
      ordername_forbidden            = 14
      order_change_but_locked_object = 15
      order_released                 = 16
      order_user_locked              = 17
      tr_check_keysyntax_error       = 18
      no_authorization               = 19
      wrong_client                   = 20 "#EC SAST_CI_GEN_CHECK
      unallowed_source_client        = 21
      unallowed_user                 = 22
      unallowed_trfunction           = 23
      unallowed_trstatus             = 24
      no_systemname                  = 25
      no_systemtype                  = 26
      OTHERS                         = 27.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    IF NOT ls_e070 IS INITIAL.
      l_trnsport = ls_e070-strkorr.
      MESSAGE s181(/psyng/sw) WITH l_trnsport text-001.
    ENDIF.
  ENDIF.
ENDFORM.                    " add_to_transport

*&---------------------------------------------------------------------*
*&      Form  f4_cuscon
*&---------------------------------------------------------------------*
*       F4 help for Custom Conflict ID
*----------------------------------------------------------------------*
*      <--E_CUSCON  Custom Conflict ID
*----------------------------------------------------------------------*
FORM f4_cuscon CHANGING e_conid TYPE /psyng/sw_cuscon-conid.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_cuscon TYPE /psyng/sw_cuscon.


  lt_fields-tabname   = '/PSYNG/SW_CUSCON'.
  lt_fields-fieldname = 'CONID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CDESC'.
  APPEND lt_fields.
  lt_fields-fieldname = 'FUNCT'.
  APPEND lt_fields.
  lt_fields-fieldname = 'BUSAREA'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_cuscon FROM /psyng/sw_cuscon WHERE vrsio = p_vrsio.
    lt_values-line = ls_cuscon-conid.
    APPEND lt_values.
    lt_values-line = ls_cuscon-cdesc.
    APPEND lt_values.
    lt_values-line = ls_cuscon-funct.
    APPEND lt_values.
    lt_values-line = ls_cuscon-busarea.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CONID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_conid = lt_return-fieldval.
ENDFORM.                                                    " f4_conid

**** F4 help for critical tcodes

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

  SELECT a~tcode
         a~vrsio
*         a~description
         a~imp
         a~owner
         b~ttext INTO CORRESPONDING FIELDS OF TABLE ctcode
         FROM /psyng/critcodes AS a INNER JOIN tstct AS b
         ON a~tcode EQ b~tcode
         WHERE vrsio = p_vrsio.
*           AND sprsl EQ sy-langu.
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
*    lt_values-line = ctcode-description.
*    APPEND lt_values.
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


** Get values for popup
*  SELECT * INTO ls_ctcode FROM /psyng/critcodes
*                          WHERE vrsio = p_vrsio
*                          ORDER BY tcode.
*    lt_values-line = ls_ctcode-tcode.
*    APPEND lt_values.
*    lt_values-line = ls_ctcode-vrsio.
*    APPEND lt_values.
*    lt_values-line = ls_ctcode-imp.
*    APPEND lt_values.
*    lt_values-line = ls_ctcode-owner.
*    APPEND lt_values.
*    lt_values-line = ls_ctcode-description.
*    APPEND lt_values.
*  ENDSELECT.
*
*
*  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
*       EXPORTING
*            retfield        = 'TCODE'
*       TABLES
*            value_tab       = lt_values
*            field_tab       = lt_fields
*            return_tab      = lt_return
*       EXCEPTIONS
*            parameter_error = 1
*            no_values_found = 2
*            OTHERS          = 3.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.
*
*  READ TABLE lt_return INDEX 1.
*  e_tcode = lt_return-fieldval.
ENDFORM.                                                    " f4_conid


**** F4 help for critical roles

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


  SELECT a~agr_name
         a~vrsio
*         a~description
         a~imp
         a~owner
         b~text INTO CORRESPONDING FIELDS OF TABLE crole
         FROM /psyng/criroles AS a INNER JOIN agr_texts AS b
         ON a~agr_name EQ b~agr_name
         WHERE vrsio = p_vrsio
*           AND spras EQ sy-langu
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


** Get values for popup
*  SELECT * INTO ls_ctrole FROM /psyng/criroles
*                          WHERE vrsio = p_vrsio
*                          ORDER BY agr_name.
*    lt_values-line = ls_ctrole-agr_name.
*    APPEND lt_values.
*    lt_values-line = ls_ctrole-vrsio.
*    APPEND lt_values.
*    lt_values-line = ls_ctrole-imp.
*    APPEND lt_values.
*    lt_values-line = ls_ctrole-owner.
*    APPEND lt_values.
*    lt_values-line = ls_ctrole-description.
*    APPEND lt_values.
*
**    SELECT * INTO ls_agrtext FROM agr_texts
**                             WHERE agr_name = ls_ctrole-agr_name
**                             AND spras = sy-langu.
**      lt_values-line = ls_agrtext-text.
**      APPEND lt_values.
**    ENDSELECT.
*  ENDSELECT.

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
*    lt_values-line = crole-description.
*    APPEND lt_values.

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


*  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
*       EXPORTING
*            retfield        = 'AGR_NAME'
**             VALUE_ORG              = 'S'
*       TABLES
*            value_tab       = lt_values
*            field_tab       = lt_fields
*            return_tab      = lt_return
*       EXCEPTIONS
*            parameter_error = 1
*            no_values_found = 2
*            OTHERS          = 3.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.
*
*  READ TABLE lt_return INDEX 1.
*  e_role = lt_return-fieldval.
ENDFORM.                                                    " f4_conid


**** F4 help for critical profile

FORM f4_ctprof CHANGING e_prof TYPE /psyng/criprof-profile.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value  WITH HEADER LINE,
        ls_ctprof TYPE /psyng/criprof.

  DATA : BEGIN OF cprof OCCURS 0,
           ptext TYPE usr11-ptext.
           INCLUDE STRUCTURE /psyng/criprof.
         DATA END OF cprof.

*    SELECT * INTO ls_ctprof FROM /psyng/criprof
*                          WHERE vrsio = p_vrsio
*                          ORDER BY profile.
*     move-corresponding ls_ctprof to cprof.
  SELECT a~profile
         a~vrsio
*         a~description
         a~imp
         a~owner
         b~ptext INTO CORRESPONDING FIELDS OF TABLE cprof
         FROM /psyng/criprof AS a INNER JOIN usr11 AS b
         ON a~profile EQ b~profn
         WHERE vrsio = p_vrsio.
*           AND langu EQ sy-langu.



*  lt_fields-tabname   = '/PSYNG/CRIPROF'.
*  lt_fields-fieldname = 'PROFILE'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'VRSIO'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'IMP'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'OWNER'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'DESCRIPTION'.
*  APPEND lt_fields.

* Get values for popup
*  SELECT * INTO ls_ctprof FROM /psyng/criprof
*                          WHERE vrsio = p_vrsio
*                          ORDER BY profile.

*    lt_values-line = ls_ctprof-profile.
*    APPEND lt_values.
*    lt_values-line = ls_ctprof-vrsio.
*    APPEND lt_values.
*    lt_values-line = ls_ctprof-imp.
*    APPEND lt_values.
*    lt_values-line = ls_ctprof-owner.
*    APPEND lt_values.
*    lt_values-line = ls_ctprof-description.
*    APPEND lt_values.
*  ENDSELECT.
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
*    lt_values-line = cprof-description.
*    APPEND lt_values.


  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t12
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



ENDFORM.                                                    " f4_conid

*&---------------------------------------------------------------------*
*&      Form  f4_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_PROF_LOW  text
*----------------------------------------------------------------------*
FORM f4_config CHANGING e_config TYPE /psyng/swconfig-param.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_config TYPE /psyng/swconfig.


  lt_fields-tabname   = '/PSYNG/SWCONFIG'.
  lt_fields-fieldname = 'PARAM'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VALUE'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_config FROM /psyng/swconfig ORDER BY param.

    lt_values-line = ls_config-param.
    APPEND lt_values.
    lt_values-line = ls_config-value.
    APPEND lt_values.
  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PARAM'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_config = lt_return-fieldval.

ENDFORM.                                                    " f4_config
*&---------------------------------------------------------------------*
*&      Form  f4_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_TSTAT_LOW  text
*----------------------------------------------------------------------*
FORM f4_status CHANGING e_stat TYPE /psyng/sw_sta01-status .
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_status TYPE /psyng/sw_sta01.


  lt_fields-tabname   = '/PSYNG/SW_STA01'.
  lt_fields-fieldname = 'STATUS'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TEXT'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_status FROM /psyng/sw_sta01 ORDER BY status.

    lt_values-line = ls_status-status.
    APPEND lt_values.
    lt_values-line = ls_status-text.
    APPEND lt_values.
  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'STATUS'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_stat = lt_return-fieldval.

ENDFORM.                                                    " f4_status
*&---------------------------------------------------------------------*
*&      Form  f4_orglvl
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_TORGLV_HIGH  text
*----------------------------------------------------------------------*
FORM f4_orglvl CHANGING e_org TYPE /psyng/swsodorgm-varbl.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_orglvl TYPE /psyng/swsodorgm.


  lt_fields-tabname   = '/PSYNG/SWSODORGM'.
  lt_fields-fieldname = 'ABB'.
  APPEND lt_fields.
  lt_fields-fieldname = 'OBJECT'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VARBL'.
  APPEND lt_fields.
  lt_fields-fieldname = 'LOW'.
  APPEND lt_fields.
  lt_fields-fieldname = 'HIGH'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_orglvl FROM /psyng/swsodorgm ORDER BY abb.

    lt_values-line = ls_orglvl-abb.
    APPEND lt_values.
    lt_values-line = ls_orglvl-object.
    APPEND lt_values.
    lt_values-line = ls_orglvl-varbl.
    APPEND lt_values.
    lt_values-line = ls_orglvl-low.
    APPEND lt_values.
    lt_values-line = ls_orglvl-high.
    APPEND lt_values.
  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VARBL'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_org = lt_return-fieldval.

ENDFORM.                                                    " f4_orglvl
*&---------------------------------------------------------------------*
*&      Form  f4_frequency
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_TFREQ_LOW  text
*----------------------------------------------------------------------*
FORM f4_frequency CHANGING e_freq TYPE /psyng/sw_freq-freq .
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_freq   TYPE TABLE OF /psyng/sw_freq WITH HEADER LINE,
        lt_ftext  TYPE TABLE OF /psyng/sw_freqt WITH HEADER LINE.


  lt_fields-tabname   = '/PSYNG/SW_FREQ'.
  lt_fields-fieldname = 'FREQ'.
  APPEND lt_fields.
  lt_fields-fieldname = 'NUMDAYS'.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/SW_FREQT'.
  lt_fields-fieldname = 'TEXT'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO TABLE lt_freq FROM /psyng/sw_freq
  WHERE freq IS NOT NULL.
  IF NOT lt_freq[] IS INITIAL.
    SELECT * INTO TABLE lt_ftext FROM /psyng/sw_freqt
    FOR ALL ENTRIES IN lt_freq WHERE freq = lt_freq-freq.
  ENDIF.
  SORT lt_freq BY freq.

  LOOP AT lt_freq.
    lt_values-line = lt_freq-freq.
    APPEND lt_values.
    lt_values-line = lt_freq-numdays.
    APPEND lt_values.
    READ TABLE lt_ftext WITH KEY freq = lt_freq-freq. "lang = sy-langu.
    IF sy-subrc = 0.
      lt_values-line = lt_ftext-text.
      APPEND lt_values.
    ELSE.
      lt_values-line = ''.
      APPEND lt_values.
    ENDIF.
  ENDLOOP.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'FREQ'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_freq = lt_return-fieldval.

ENDFORM.                    " f4_frequency
*&---------------------------------------------------------------------*
*&      Form  f4_orglvlo
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_TORGLV_LOW  text
*----------------------------------------------------------------------*
FORM f4_orglvlo CHANGING e_orgo TYPE /psyng/swsodorgm-object .
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_orglvl TYPE /psyng/swsodorgm.


  lt_fields-tabname   = '/PSYNG/SWSODORGM'.
  lt_fields-fieldname = 'ABB'.
  APPEND lt_fields.
  lt_fields-fieldname = 'OBJECT'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VARBL'.
  APPEND lt_fields.
  lt_fields-fieldname = 'LOW'.
  APPEND lt_fields.
  lt_fields-fieldname = 'HIGH'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_orglvl FROM /psyng/swsodorgm ORDER BY abb.

    lt_values-line = ls_orglvl-abb.
    APPEND lt_values.
    lt_values-line = ls_orglvl-object.
    APPEND lt_values.
    lt_values-line = ls_orglvl-varbl.
    APPEND lt_values.
    lt_values-line = ls_orglvl-low.
    APPEND lt_values.
    lt_values-line = ls_orglvl-high.
    APPEND lt_values.
  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'OBJECT'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_orgo = lt_return-fieldval.

ENDFORM.                    " f4_orglvlo

**** F4 help for Mitigation assignment for User

FORM f4_mcuser CHANGING e_mcuser TYPE /psyng/mcuser-userid.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_mcuser TYPE /psyng/mcuser.


  lt_fields-tabname   = '/PSYNG/MCUSER'.
  lt_fields-fieldname = 'USERID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONTID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VRSIO'.
  APPEND lt_fields.
  lt_fields-fieldname = 'AUDITOR'.
  APPEND lt_fields.
  lt_fields-fieldname = 'FROM_DATE'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TO_DATE'.
  APPEND lt_fields.


* Get values for popup
  SELECT * INTO ls_mcuser FROM /psyng/mcuser
                          WHERE vrsio = p_vrsio
                          ORDER BY userid.
    lt_values-line = ls_mcuser-userid.
    APPEND lt_values.
    lt_values-line = ls_mcuser-contid.
    APPEND lt_values.
    lt_values-line = ls_mcuser-conid.
    APPEND lt_values.
    lt_values-line = ls_mcuser-vrsio.
    APPEND lt_values.
    lt_values-line = ls_mcuser-auditor.
    APPEND lt_values.
    lt_values-line = ls_mcuser-from_date.
    APPEND lt_values.
    lt_values-line = ls_mcuser-to_date.
    APPEND lt_values.


  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'USERID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_mcuser = lt_return-fieldval.
ENDFORM.                                                    " f4_mcuser


**** F4 help for Mitigation assignment for User group

FORM f4_mcusrgrp CHANGING e_mcusrgrp TYPE /psyng/mcusrgrp-class.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields   TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return   TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_mcusrgrp TYPE /psyng/mcusrgrp.


  lt_fields-tabname   = '/PSYNG/MCUSRGRP'.
  lt_fields-fieldname = 'CLASS'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONTID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VRSIO'.
  APPEND lt_fields.
  lt_fields-fieldname = 'AUDITOR'.
  APPEND lt_fields.
  lt_fields-fieldname = 'FROM_DATE'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TO_DATE'.
  APPEND lt_fields.


* Get values for popup
  SELECT * INTO ls_mcusrgrp FROM /psyng/mcusrgrp
                          WHERE vrsio = p_vrsio
                          ORDER BY class.

    lt_values-line = ls_mcusrgrp-class.
    APPEND lt_values.
    lt_values-line = ls_mcusrgrp-contid.
    APPEND lt_values.
    lt_values-line = ls_mcusrgrp-conid.
    APPEND lt_values.
    lt_values-line = ls_mcusrgrp-vrsio.
    APPEND lt_values.
    lt_values-line = ls_mcusrgrp-auditor.
    APPEND lt_values.
    lt_values-line = ls_mcusrgrp-from_date.
    APPEND lt_values.
    lt_values-line = ls_mcusrgrp-to_date.
    APPEND lt_values.


  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CLASS'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_mcusrgrp = lt_return-fieldval.
ENDFORM.                                                  " f4_mcusergrp


**** F4 help for Mitigation assignment for role

FORM f4_mcrole CHANGING e_mcrole TYPE /psyng/mcrole-agr_name.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_mcrole TYPE /psyng/mcrole.


  lt_fields-tabname   = '/PSYNG/MCROLE'.
  lt_fields-fieldname = 'AGR_NAME'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONTID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VRSIO'.
  APPEND lt_fields.
  lt_fields-fieldname = 'AUDITOR'.
  APPEND lt_fields.
  lt_fields-fieldname = 'FROM_DATE'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TO_DATE'.
  APPEND lt_fields.


* Get values for popup
  SELECT * INTO ls_mcrole FROM /psyng/mcrole
                          WHERE vrsio = p_vrsio
                          ORDER BY agr_name.

    lt_values-line = ls_mcrole-agr_name.
    APPEND lt_values.
    lt_values-line = ls_mcrole-contid.
    APPEND lt_values.
    lt_values-line = ls_mcrole-conid.
    APPEND lt_values.
    lt_values-line = ls_mcrole-vrsio.
    APPEND lt_values.
    lt_values-line = ls_mcrole-auditor.
    APPEND lt_values.
    lt_values-line = ls_mcrole-from_date.
    APPEND lt_values.
    lt_values-line = ls_mcrole-to_date.
    APPEND lt_values.


  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'AGR_NAME'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_mcrole = lt_return-fieldval.
ENDFORM.                                                    " f4_mcrole

**** F4 help for projects

FORM f4_project CHANGING e_project TYPE /psyng/sw_prj01-project.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields  TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return  TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_project TYPE /psyng/sw_prj01.


  lt_fields-tabname   = '/PSYNG/SW_PRJ01'.
  lt_fields-fieldname = 'PROJECT'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TEXT'.
  APPEND lt_fields.


* Get values for popup
  SELECT * INTO ls_project FROM /psyng/sw_prj01
                          ORDER BY text.

    lt_values-line = ls_project-project.
    APPEND lt_values.
    lt_values-line = ls_project-text.
    APPEND lt_values.

  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PROJECT'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_project = lt_return-fieldval.
ENDFORM.                                                  " f4_mccauser


**** F4 help for function

*FORM f4_function CHANGING e_function TYPE /psyng/function-function.
*
*  DATA: BEGIN OF lt_values OCCURS 0,
*          line(255) TYPE c,
*        END OF lt_values.
*
*  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
*        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
*        ls_function TYPE /psyng/function.
*
*
*   CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
*       EXPORTING
*            tabname           = '/PSYNG/FUNCTION'
*            fieldname         = 'FUNCTION'
*            searchhelp        = '/PSYNG/FUN'
*       TABLES
*            return_tab        = lt_return
*       EXCEPTIONS
*            field_not_found   = 1
*            no_help_for_field = 2
*            inconsistent_help = 3
*            no_values_found   = 4
*            OTHERS            = 5.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.
*
*  READ TABLE lt_return INDEX 1.
*  e_function = lt_return-fieldval.
*
*ENDFORM.                                                  " f4_mccause
*&---------------------------------------------------------------------*
*&      Form  get_relevant_funcs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_relevant_funcs.
  REFRESH : gt_confdet.
  CLEAR gt_confdet.

  SELECT DISTINCT functionid FROM /psyng/confdet
  INTO CORRESPONDING FIELDS OF TABLE gt_confdet
  WHERE conid IN s_conid
  AND vrsio = p_vrsio.
  IF sy-subrc = 0.
    s_funct-sign = 'I'.
    s_funct-option = 'EQ'.


    LOOP AT gt_confdet.
      READ TABLE s_funct WITH KEY low =
  gt_confdet-functionid BINARY SEARCH TRANSPORTING NO FIELDS .
      IF sy-subrc NE 0.
        s_funct-low = gt_confdet-functionid.
        APPEND s_funct.

      ENDIF.
    ENDLOOP.

    SORT s_funct.
    DELETE ADJACENT DUPLICATES FROM s_funct COMPARING ALL FIELDS.

  ENDIF.
ENDFORM.                    " get_relevant_funcs
*&---------------------------------------------------------------------*
*&      Form  f4_function
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_FUNCT_LOW  text
*----------------------------------------------------------------------*
FORM f4_function CHANGING e_funid TYPE /psyng/function-function.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields   TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return   TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_function TYPE /psyng/function.

*
  lt_fields-tabname   = '/PSYNG/FUNCTION'.
  lt_fields-fieldname = 'FUNCTION'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VRSIO'.
  APPEND lt_fields.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-fieldname = 'OWNER'.
  APPEND lt_fields.
  lt_fields-fieldname = 'BUSAREA'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_function FROM /psyng/function WHERE vrsio = p_vrsio.
    lt_values-line = ls_function-function.
    APPEND lt_values.
    lt_values-line = ls_function-vrsio.
    APPEND lt_values.
    lt_values-line = ls_function-description.
    APPEND lt_values.
    lt_values-line = ls_function-owner.
    APPEND lt_values.
    lt_values-line = ls_function-busarea.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'FUNCTION'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_funid = lt_return-fieldval.

ENDFORM.                    " f4_function

**Do not delete commented code below
**---------------------------------------------------------------------*
**       FORM set_VRSIO                                                *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  RECORD_TAB                                                    *
**  -->  SHLP_TOP                                                      *
**  -->  CALLCONTROL                                                   *
**---------------------------------------------------------------------*
*FORM set_vrsio TABLES record_tab STRUCTURE seahlpres
*CHANGING shlp_top TYPE shlp_descr_t
*callcontrol LIKE ddshf4ctrl.
*
*
*  DATA: wa_selopt LIKE ddshselopt.
*  CLEAR wa_selopt.
*  wa_selopt-shlpname = '/PSYNG/FUN'.
*  wa_selopt-shlpfield = 'VRSIO'.
*  wa_selopt-sign = 'I'.
*  wa_selopt-option = 'EQ'.
*  wa_selopt-low = p_vrsio.
*  APPEND wa_selopt TO shlp_top-selopt.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  f4_conflicts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_CONID_LOW  text
*----------------------------------------------------------------------*
FORM f4_conflicts CHANGING e_conid TYPE /psyng/conflict-conid
.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields   TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return   TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_conflict TYPE /psyng/conflict.

*
  lt_fields-tabname   = '/PSYNG/CONFLICT'.
  lt_fields-fieldname = 'IMP'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VRSIO'.
  APPEND lt_fields.
  lt_fields-fieldname = 'INACTIVE'.
  APPEND lt_fields.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-fieldname = 'OWNER'.
  APPEND lt_fields.
  lt_fields-fieldname = 'BUSAREA'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CONTID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'RISK'.
  APPEND lt_fields.
  lt_fields-fieldname = 'SUBAREA'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_conflict FROM /psyng/conflict WHERE vrsio = p_vrsio.
    lt_values-line = ls_conflict-imp.
    APPEND lt_values.
    lt_values-line = ls_conflict-conid.
    APPEND lt_values.
    lt_values-line = ls_conflict-vrsio.
    APPEND lt_values.
    lt_values-line = ls_conflict-inactive.
    APPEND lt_values.
    lt_values-line = ls_conflict-description.
    APPEND lt_values.
    lt_values-line = ls_conflict-owner.
    APPEND lt_values.
    lt_values-line = ls_conflict-busarea.
    APPEND lt_values.
    lt_values-line = ls_conflict-contid.
    APPEND lt_values.
    lt_values-line = ls_conflict-risk.
    APPEND lt_values.
    lt_values-line = ls_conflict-subarea.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CONID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_conid = lt_return-fieldval.

ENDFORM.                    " f4_conflicts
*&---------------------------------------------------------------------*
*&      Form  f4_crit_auth
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_AUDID_LOW  text
*----------------------------------------------------------------------*
FORM f4_crit_auth CHANGING e_swaudid TYPE /psyng/swaudhdr-swaudid .
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_swaud  TYPE /psyng/swaudhdr.

*
  lt_fields-tabname   = '/PSYNG/SWAUDHDR'.
  lt_fields-fieldname = 'SWAUDID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'VRSIO'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TCODE'.
  APPEND lt_fields.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-fieldname = 'OWNER'.
  APPEND lt_fields.
  lt_fields-fieldname = 'IMP'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_swaud FROM /psyng/swaudhdr WHERE vrsio = p_vrsio.
    lt_values-line = ls_swaud-swaudid.
    APPEND lt_values.
    lt_values-line = ls_swaud-vrsio.
    APPEND lt_values.
    lt_values-line = ls_swaud-tcode.
    APPEND lt_values.
    lt_values-line = ls_swaud-description.
    APPEND lt_values.
    lt_values-line = ls_swaud-owner.
    APPEND lt_values.
    lt_values-line = ls_swaud-imp.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SWAUDID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_swaudid = lt_return-fieldval.
ENDFORM.                    " f4_crit_auth
*&---------------------------------------------------------------------*
*&      Form  f4_elements
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_VELEMT_LOW  text
*----------------------------------------------------------------------*
FORM f4_elements CHANGING e_elements TYPE /psyng/sw_varel-var_element.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields   TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return   TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_elements TYPE /psyng/sw_varel.


  lt_fields-tabname   = '/PSYNG/SW_VAREL'.
  lt_fields-fieldname = 'VAR_ELEMENT'.
  APPEND lt_fields.
*  lt_fields-fieldname = 'SYSID'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'VALUESET'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'ELEMENT'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'FIELD'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'VAL_FROM'.
*  APPEND lt_fields.
*  lt_fields-fieldname = 'VAL_TO'.
*  APPEND lt_fields.
*


* Get values for popup
  SELECT DISTINCT var_element  FROM /psyng/sw_varel
  INTO CORRESPONDING FIELDS OF
  ls_elements
  WHERE varel_vrsio IN s_vevrs.


    lt_values-line = ls_elements-var_element.
    APPEND lt_values.
  ENDSELECT.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VAR_ELEMENT'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_elements = lt_return-fieldval.

ENDFORM.                    " f4_elements


*---------------------------------------------------------------------*
*       FORM f4_called_tcode                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_TCODE                                                       *
*---------------------------------------------------------------------*
FORM f4_called_tcode CHANGING e_tcode TYPE
                  /psyng/sw_excdtx-called_tcode.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_excdtx TYPE /psyng/sw_excdtx.


  lt_fields-tabname   = '/PSYNG/SW_EXCDTX'.
  lt_fields-fieldname = 'CALLED_TCODE'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_excdtx FROM /psyng/sw_excdtx.
    lt_values-line = ls_excdtx-called_tcode.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CALLED_TCODE'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_tcode = lt_return-fieldval.
ENDFORM.

*form f4_setid CHANGING e_setid TYPE
*                  /PSYNG/SWCFGOE-setid.
*
*
*endform.
*---------------------------------------------------------------------*
*       FORM f4_called_tcode                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_TCODE                                                       *
*---------------------------------------------------------------------*
FORM f4_calling_tcode CHANGING e_tcode TYPE
                  /psyng/sw_excltx-low.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_excltx TYPE /psyng/sw_excltx.


  lt_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  lt_fields-fieldname = 'SIGN'.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  lt_fields-fieldname = 'TYPE'.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  lt_fields-fieldname = 'LOW'.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  lt_fields-fieldname = 'HIGH'.
  APPEND lt_fields.

* Get values for popup
  SELECT * INTO ls_excltx FROM /psyng/sw_excltx.

    lt_values-line = ls_excltx-sign.
    APPEND lt_values.
    lt_values-line = ls_excltx-type.
    APPEND lt_values.
    lt_values-line = ls_excltx-low.
    APPEND lt_values.
    lt_values-line = ls_excltx-high.
    APPEND lt_values.

  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LOW'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_tcode = lt_return-fieldval.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_emltxt                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_TDNAME                                                      *
*---------------------------------------------------------------------*
FORM f4_emltxt CHANGING e_tdname TYPE stxh-tdname.

  DATA: BEGIN OF lt_texts OCCURS 0,
          mandt    TYPE mandt,
          tdobject TYPE stxh-tdobject,
          tdname   TYPE stxh-tdname,
          tdid     TYPE stxh-tdid,
          tdspras  TYPE stxh-tdspras,
        END OF lt_texts.

  DATA: lt_fields   TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return   TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_swconfig TYPE TABLE OF /psyng/swconfig
        WITH HEADER LINE.

  DATA: BEGIN OF lt_swtexts OCCURS 0,
          value TYPE stxh-tdname,
        END OF lt_swtexts,

        BEGIN OF lt_rvwhdr OCCURS 0,
          dflt_review TYPE /psyng/mcrvwhdr-dflt_review,
        END OF lt_rvwhdr.

  REFRESH: lt_swconfig, lt_texts, lt_fields.

  lt_fields-tabname   = 'STXH'.

  lt_fields-fieldname = 'MANDT'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TDOBJECT'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TDNAME'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TDID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'TDSPRAS'.
  APPEND lt_fields.

* Get values for popup
  DATA lt_config_param TYPE TABLE OF /psyng/se_config_param
  WITH HEADER LINE.

*---get all email templates name
  PERFORM     get_email_config_texts TABLES
    lt_config_param.
  LOOP AT lt_config_param WHERE
            value IN p_emltxt.
    MOVE-CORRESPONDING lt_config_param TO lt_swconfig.
    APPEND lt_swconfig.
  ENDLOOP.
*  SELECT * FROM /psyng/swconfig
*            INTO CORRESPONDING FIELDS OF TABLE lt_swconfig
*            WHERE value IN p_emltxt.
*include review header text
  SELECT dflt_review FROM /psyng/mcrvwhdr
  INTO TABLE lt_rvwhdr WHERE
       contid <> space.

  LOOP AT lt_rvwhdr.
    lt_swconfig-value = lt_rvwhdr-dflt_review.
    APPEND lt_swconfig.
  ENDLOOP.

  SORT lt_swconfig BY value.
  DELETE ADJACENT DUPLICATES FROM lt_swconfig COMPARING value.

  LOOP AT lt_swconfig.
    MOVE-CORRESPONDING lt_swconfig TO lt_swtexts.
    APPEND lt_swtexts.
  ENDLOOP.

  IF NOT lt_swtexts[] IS INITIAL.
    SELECT mandt tdobject tdname tdid tdspras FROM stxh
             INTO CORRESPONDING FIELDS OF TABLE lt_texts
             FOR ALL ENTRIES IN lt_swtexts
             WHERE tdobject = 'TEXT'
               AND tdname   = lt_swtexts-value.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'TDNAME'
      dynpprog        = sy-cprog
      dynpnr          = sy-dynnr
      dynprofield     = 'TDNAME'
      value_org       = 'S'
    TABLES
      value_tab       = lt_texts
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_tdname = lt_return-fieldval.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  transport_varelements
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM transport_varelements.

*  DATA: BEGIN OF lt_varele OCCURS 0,
*            mandt LIKE /psyng/sw_varel-mandt,
*            var_element LIKE /psyng/sw_varel-var_element,
**            sysid LIKE /psyng/sw_varel-sysid,
*            valueset LIKE /psyng/sw_varel-valueset,
*            element LIKE /psyng/sw_varel-element,
*            field LIKE /psyng/sw_varel-field,
*            val_from LIKE /psyng/sw_varel-val_from,
*          END OF lt_varele.
  DATA : lt_varele  TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE,
         lt_ve_hdr  TYPE TABLE OF /psyng/sw_varvr WITH HEADER LINE,
         l_text(50) TYPE c.
* Get Variable Element data
  SELECT varel_vrsio
         var_element
          INTO CORRESPONDING FIELDS OF
          TABLE lt_varele
          FROM /psyng/sw_varel
          WHERE var_element IN s_velemt AND
                varel_vrsio IN s_vevrs.
  SORT lt_varele.
  DELETE ADJACENT DUPLICATES FROM lt_varele.


*  DESCRIBE TABLE lt_varele LINES sy-tfill.
*  IF sy-tfill = 0.
*    MESSAGE i113 WITH 'Variable Elements'(e22) text-e02.
*    EXIT.
*  ENDIF.

  PERFORM create_transport.
*--Variable Element Version Header
  IF p_ve_hdr = 'X'.
    SELECT varel_vrsio FROM /psyng/sw_varvr INTO
       CORRESPONDING FIELDS OF
       TABLE lt_ve_hdr
    WHERE varel_vrsio IN s_vevrs.
    IF NOT lt_ve_hdr[] IS INITIAL.
      gt_e071-trkorr   = g_trkorr.
      gt_e071-pgmid    = 'R3TR'.
      gt_e071-object   = 'TABU'.
      gt_e071-obj_name = '/PSYNG/SW_VARVR'.
      gt_e071-objfunc  = 'K'.
      APPEND gt_e071.

      MOVE-CORRESPONDING gt_e071 TO gt_e071k.
      CLEAR gt_e071k-objfunc.
      gt_e071k-mastertype = 'TABU'.

*     Add Variable Elements to transport
      gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_VARVR'.
      LOOP AT lt_ve_hdr.
        CONCATENATE sy-mandt
                    lt_ve_hdr-varel_vrsio
                    INTO gt_e071k-tabkey.
        APPEND gt_e071k.
      ENDLOOP.

    ELSE.
      MESSAGE i113 WITH
      'No Matching Variable Elements versions found'(e25) .
    ENDIF.
  ENDIF.

*--Variable Element Version Content
  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_VAREL'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add Variable Elements to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_VAREL'.
  LOOP AT lt_varele.
    IF lt_varele-var_element CS '_'.
      SPLIT lt_varele-var_element AT '_' INTO lt_varele-var_element
        l_text.
    ENDIF.
    CONCATENATE sy-mandt
                lt_varele-varel_vrsio
                lt_varele-var_element '*'
                INTO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.


ENDFORM.                    " transport_varelements

*---------------------------------------------------------------------*
*       FORM transport_dynamic_enhance                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM transport_dynamic_enhance.

  DATA: lt_excltx TYPE TABLE OF /psyng/sw_excltx WITH HEADER LINE,
        lt_excdtx TYPE TABLE OF /psyng/sw_excdtx WITH HEADER LINE.

* Get calling tcode data
  SELECT * FROM /psyng/sw_excltx INTO TABLE lt_excltx
  WHERE low IN s_ctcode.

  DESCRIBE TABLE lt_excltx  LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e89 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_EXCLTX'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add calling tcode to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_EXCLTX'.
  LOOP AT lt_excltx.
    MOVE lt_excltx TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

*Called Tcode
  SELECT * FROM /psyng/sw_excdtx INTO TABLE lt_excdtx
  WHERE called_tcode IN s_ctcod1.

  DESCRIBE TABLE lt_excdtx  LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e90 text-e02.
    EXIT.
  ENDIF.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_EXCDTX'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add calling tcode to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_EXCDTX'.
  LOOP AT lt_excdtx.
    MOVE lt_excdtx TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.

ENDFORM.


*---------------------------------------------------------------------*
*       FORM transport_configuration_set                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM transport_configuration_set.

  DATA: BEGIN OF lt_swcfgsys OCCURS 0,
          mandt TYPE /psyng/swcfgid-mandt,
          setid TYPE /psyng/swcfgsys-setid,
          sysid TYPE /psyng/swcfgsys-sysid,
        END OF lt_swcfgsys.

  DATA: BEGIN OF lt_swcfgset OCCURS 0,
          mandt TYPE /psyng/swcfgid-mandt,
          set   TYPE /psyng/swcfgset-setid,
        END OF lt_swcfgset.

  DATA: BEGIN OF lt_swcfgve OCCURS 0,
          mandt       TYPE /psyng/swcfgid-mandt,
          setid       TYPE /psyng/swcfgve-setid,
          var_element TYPE /psyng/swcfgve-var_element,
          sysid       TYPE /psyng/swcfgve-sysid,
          value       TYPE /psyng/swcfgve-value,
        END OF lt_swcfgve.

  DATA: BEGIN OF lt_swcfgoe OCCURS 0,
          mandt TYPE /psyng/swcfgid-mandt,
          setid TYPE /psyng/swcfgoe-setid,
          abb   TYPE /psyng/swcfgoe-abb,
          varbl TYPE /psyng/swcfgoe-varbl,
          sysid TYPE /psyng/swcfgoe-sysid,
          value TYPE /psyng/swcfgoe-value,
        END OF lt_swcfgoe.

***  get config setid data
  SELECT mandt setid  INTO TABLE lt_swcfgset
          FROM /psyng/swcfgset
          WHERE setid IN s_setid.


  DESCRIBE TABLE lt_swcfgset LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e24 text-e02.
    EXIT.
  ENDIF.

  SELECT mandt setid sysid  INTO TABLE lt_swcfgsys
          FROM /psyng/swcfgsys
          WHERE setid IN s_setid.

  SELECT mandt setid var_element sysid value "active
  INTO TABLE lt_swcfgve
          FROM /psyng/swcfgve
          WHERE setid IN s_setid.

  SELECT mandt setid abb varbl sysid value INTO TABLE lt_swcfgoe
          FROM /psyng/swcfgoe
          WHERE setid IN s_setid.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SWCFGSET'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

*  * Add configset to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWCFGSET'.

  LOOP AT lt_swcfgset.
    MOVE lt_swcfgset TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  CHECK NOT lt_swcfgset[] IS INITIAL.
  APPEND gt_e071.

* Add tcodes to transport
*  DESCRIBE TABLE lt_swcfgid LINES sy-tfill.
*  IF sy-tfill > 0.
*    gt_e071-obj_name = '/PSYNG/SWCFGID'.
*    APPEND gt_e071.
*  ENDIF.
*
*  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWCFGID'.
*  LOOP AT lt_swcfgid.
*    MOVE lt_swcfgid TO gt_e071k-tabkey.
*
*    APPEND gt_e071k.
*  ENDLOOP.

* Add system to transport
  DESCRIBE TABLE lt_swcfgsys LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SWCFGSYS'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWCFGSYS'.
  LOOP AT lt_swcfgsys.
    MOVE lt_swcfgsys TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

* Add variable to transport
  DESCRIBE TABLE lt_swcfgve LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SWCFGVE'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWCFGVE'.
  LOOP AT lt_swcfgve.
    MOVE lt_swcfgve TO gt_e071k-tabkey.
*       CONCATENATE lt_swcfgve-mandt lt_swcfgve-SETID
*       lt_swcfgve-VAR_ELEMENT lt_swcfgve-SYSID t_swcfgve-value
*      INTO gt_e071k-tabkey.

    APPEND gt_e071k.
  ENDLOOP.

* Add org element to transport
  DESCRIBE TABLE lt_swcfgoe LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SWCFGOE'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWCFGOE'.
  LOOP AT lt_swcfgoe.
    MOVE lt_swcfgoe TO gt_e071k-tabkey.
* CONCATENATE lt_swcfgoe-mandt lt_swcfgoe-SETID
*       lt_swcfgoe-ABB lt_swcfgoe-VARBL '*'
*      INTO gt_e071k-tabkey.

    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM transport_standard_email_txt                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM transport_standard_email_txt.

  DATA: BEGIN OF lt_config OCCURS 0,
          param LIKE /psyng/swconfig-param,
          value LIKE stxh-tdname,
        END OF lt_config,

        BEGIN OF lt_texts OCCURS 0,
          tdname  LIKE stxh-tdname,
          tdspras LIKE stxh-tdspras,
        END OF lt_texts,

        BEGIN OF lt_rvwhdr OCCURS 0,
          dflt_review TYPE /psyng/mcrvwhdr-dflt_review,
        END OF lt_rvwhdr.

  DATA lt_config_param TYPE TABLE OF /psyng/se_config_param
  WITH HEADER LINE.

*---get all email templates name
  PERFORM     get_email_config_texts TABLES
    lt_config_param.
  LOOP AT lt_config_param WHERE
            value IN p_emltxt.
    MOVE-CORRESPONDING lt_config_param TO lt_config.
    APPEND lt_config.
  ENDLOOP.

*  Dont take from db, bcz initially value not present in db
*  SELECT * FROM /psyng/swconfig
*           INTO CORRESPONDING FIELDS OF TABLE lt_config
*           WHERE value IN p_emltxt.

*include review header text
  SELECT dflt_review FROM /psyng/mcrvwhdr
  INTO TABLE lt_rvwhdr WHERE
     dflt_review IN p_emltxt.

  LOOP AT lt_rvwhdr.
    lt_config-value = lt_rvwhdr-dflt_review.
    APPEND lt_config.
  ENDLOOP.

  SORT lt_config BY value.
  DELETE ADJACENT DUPLICATES FROM lt_config COMPARING value.

  IF NOT lt_config[] IS INITIAL.
    SELECT * FROM stxh
             INTO CORRESPONDING FIELDS OF TABLE lt_texts
             FOR ALL ENTRIES IN lt_config
             WHERE tdobject = 'TEXT'
               AND tdname   = lt_config-value.
  ENDIF.

  SORT lt_texts BY tdname tdspras.
  DELETE ADJACENT DUPLICATES FROM lt_texts COMPARING tdname tdspras.

  DESCRIBE TABLE lt_texts  LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e91 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TEXT'.
  CLEAR gt_e071-objfunc.

  LOOP AT lt_texts.
    CONCATENATE 'TEXT' lt_texts-tdname 'ST' lt_texts-tdspras
                INTO gt_e071-obj_name SEPARATED BY ','.
    APPEND gt_e071.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  transport_corg
*&---------------------------------------------------------------------*
*       Transport Custom Org Level Det.
*----------------------------------------------------------------------*
FORM transport_corg.
  DATA: lt_corg  TYPE TABLE OF /psyng/swsodorgo,
        ls_corg  TYPE /psyng/swsodorgo,
        l_keylen TYPE i.

  IF NOT p_vrsio IS INITIAL.
    SELECT mandt vrsio conid field type description
     FROM /psyng/swsodorgo
     INTO TABLE lt_corg
     WHERE vrsio = p_vrsio.
  ELSE.
    SELECT mandt vrsio conid field type  description
     FROM /psyng/swsodorgo
     INTO TABLE lt_corg.
  ENDIF.
  DESCRIBE TABLE lt_corg LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e92 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SWSODORGO'.
  gt_e071-objfunc  = 'K'.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

*  * Add Custom org level to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SWSODORGO'.

  LOOP AT lt_corg INTO ls_corg.
    MOVE ls_corg TO gt_e071k-tabkey.
*    condense gt_e071k-tabkey.
*    l_keylen = strlen( gt_e071k-tabkey ).
**    describe field gt_e071k-tabkey length l_keylen .
*    if l_keylen > 68.
*      concatenate
*        gt_e071k-tabkey(67)
*        '*'
*      into gt_e071k-tabkey.
*    endif.
    gt_e071k-tabkey = gt_e071k-tabkey(68).
    APPEND gt_e071k.
  ENDLOOP.
  CHECK NOT lt_corg[] IS INITIAL.
  APPEND gt_e071.

  PERFORM add_to_transport.
ENDFORM.                    " transport_corg
*&---------------------------------------------------------------------*
*&      Form  transport_sys_types.
*&---------------------------------------------------------------------*
*       Transport system types
*----------------------------------------------------------------------*
FORM transport_sys_types.
  DATA: lt_systyp TYPE TABLE OF ty_systyp,
        ls_systyp TYPE ty_systyp.

* Get system type data
  SELECT mandt sys_type INTO TABLE lt_systyp FROM /psyng/sw_systyp
  WHERE sys_type IN s_tsyst.

  DESCRIBE TABLE lt_systyp LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e92 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_SYSTYP'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add system types to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_SYSTYP'.
  LOOP AT lt_systyp INTO ls_systyp.
    MOVE ls_systyp TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.

ENDFORM.                    " transport_sys_types
*&---------------------------------------------------------------------*
*&      Form  transport_sys_cat
*&---------------------------------------------------------------------*
*       Transport System Category
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM transport_sys_cat.

  DATA: lt_syscat TYPE TABLE OF ty_syscat,
        ls_syscat TYPE ty_syscat.

* Get system type data
  SELECT mandt sys_category INTO TABLE lt_syscat FROM /psyng/sw_syscat
  WHERE sys_category IN s_tsysc.

  DESCRIBE TABLE lt_syscat LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113 WITH text-e93 text-e02.
    EXIT.
  ENDIF.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_SYSCAT'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add system types to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_SYSCAT'.
  LOOP AT lt_syscat INTO ls_syscat.
    MOVE ls_syscat TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.

ENDFORM.                    " transport_sys_cat
*&---------------------------------------------------------------------*
*&      Form  TRANSPORT_CUSTOM_FIORI_APP_ID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM transport_custom_fiori_app_id .

  DATA: lt_fiorin   TYPE TABLE OF /psyng/sw_fiorin,
        ls_fiorin   TYPE /psyng/sw_fiorin,
        lt_fioria   TYPE TABLE OF ty_fioria,
        ls_fioria   TYPE ty_fioria,
        lt_fiorio   TYPE TABLE OF ty_fiorio,
        ls_fiorio   TYPE ty_fiorio,
        ls_fiorio_t TYPE ty_fiorio_t,
        lt_fiorit   TYPE TABLE OF ty_fiorit,
        ls_fiorit   TYPE ty_fiorit,
        l_index     LIKE sy-tabix,
        l_length    TYPE sy-tabix,
        l_text(100) TYPE c.
* Get all function data
  SELECT mandt fioriid INTO TABLE lt_fioria FROM /psyng/sw_fioria
         WHERE fioriid IN s_appid.

  DESCRIBE TABLE lt_fioria LINES sy-tfill.
  IF sy-tfill = 0.
    MESSAGE i113(/psyng/sw)   WITH 'Fioriid'(e94) text-e02.
    EXIT.
  ENDIF.

  SELECT mandt fioriid note INTO TABLE lt_fiorin
         FROM /psyng/sw_fiorin
         WHERE fioriid IN s_appid.

  SELECT mandt fioriid textfield
    INTO TABLE lt_fiorit
     FROM /psyng/sw_fiorit
    WHERE fioriid IN s_appid.

  SELECT mandt fioriid odataservicename
    INTO TABLE lt_fiorio
     FROM /psyng/sw_fiorio
    WHERE fioriid IN s_appid.

  PERFORM create_transport.

  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_FIORIA'.
  gt_e071-objfunc  = 'K'.

* Add fiori ids information to transport
  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_FIORIA'.
  LOOP AT lt_fioria INTO ls_fioria.
    MOVE ls_fioria TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  APPEND gt_e071.

* Add fiori app texts to transport
  DESCRIBE TABLE lt_fiorit LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SW_FIORIT'.
    APPEND gt_e071.
  ENDIF.

  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_FIORIT'.
  LOOP AT lt_fiorit INTO ls_fiorit.
    MOVE ls_fiorit TO gt_e071k-tabkey.
*   Table key is > 120 characters to transport generically
    CONCATENATE gt_e071k-tabkey '*' INTO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

*  Add fiori odata to transport
  DESCRIBE TABLE lt_fiorio LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SW_FIORIO'.
    APPEND gt_e071.
  ENDIF.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_FIORIO'.
  LOOP AT lt_fiorio INTO ls_fiorio.
    IF ls_fiorio-odataservicename CS '_'.
      SPLIT ls_fiorio-odataservicename AT '_' INTO
      ls_fiorio-odataservicename l_text.
    ENDIF.
    ls_fiorio_t = ls_fiorio.
    MOVE ls_fiorio_t TO gt_e071k-tabkey.
*   Table key is > 120 characters to transport generically
    CONCATENATE gt_e071k-tabkey '*' INTO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

*  Add fiori notes to transport
  DESCRIBE TABLE lt_fiorin LINES sy-tfill.
  IF sy-tfill > 0.
    gt_e071-obj_name = '/PSYNG/SW_FIORIN'.
    APPEND gt_e071.
  ENDIF.
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_FIORIN'.
  LOOP AT lt_fiorin INTO ls_fiorin.
    MOVE ls_fiorin TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  PERFORM add_to_transport.
ENDFORM.

FORM get_email_config_texts TABLES
  lt_email_config STRUCTURE /psyng/se_config_param.

  DATA lt_emailtemp TYPE TABLE OF
        /psyng/se_config_param WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
    TABLES
      et_config = lt_emailtemp.

* Mitigation assignment email
  READ TABLE lt_emailtemp WITH KEY
       param = 'SW_MIT_ASG_NOTIF_OID'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

* Mitigation reminder email
  READ TABLE lt_emailtemp WITH KEY
       param = 'SW_MIT_REMIND_EMAIL'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

* Mitigation URL
  READ TABLE lt_emailtemp WITH KEY
       param = 'MIT_ATTACH_URL'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

* User Inactivity Email
  READ TABLE lt_emailtemp WITH KEY
       param = 'SW_USR_INACTIV_EMAIL'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

* Mitigation Signoff Email
  READ TABLE lt_emailtemp WITH KEY
       param = 'SW_MIT_SIGNOFF_EMAIL'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

* Configuration Set Comparison E-Mail
  READ TABLE lt_emailtemp WITH KEY
       param = 'CFGGSET_COMP_EMAIL'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

* /PSYNG/BC_EMAIL_CSS
  READ TABLE lt_emailtemp WITH KEY
       param = 'SW_CSS_EMAIL'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

*SW_MIT_SIGNOFF_TEXT
    READ TABLE lt_emailtemp WITH KEY
       param = 'SW_MIT_SIGNOFF_TEXT'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.

*Mitigation Assignment Expire email odubey 20/02/2024 start
    READ TABLE lt_emailtemp WITH KEY
       param = 'SW_MIT_EXPIRE_EMAIL'.
  IF sy-subrc = 0.
    lt_email_config-param = lt_emailtemp-param.
    IF NOT lt_emailtemp-value IS INITIAL.
      lt_email_config-value = lt_emailtemp-value.
    ELSE.
      lt_email_config-value = lt_emailtemp-default.
    ENDIF.
    APPEND lt_email_config.
  ENDIF.
*end
  FREE lt_emailtemp.
ENDFORM.
