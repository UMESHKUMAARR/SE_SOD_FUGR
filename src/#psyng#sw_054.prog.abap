*----------------------------------------------------------------------*
* Report  /PSYNG/SW_054                                                *
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
REPORT /psyng/sw_054 MESSAGE-ID /psyng/sw.
INCLUDE /psyng/sw_config.
DATA : l_origin TYPE /psyng/conflict_origin.
RANGES : gt_origin FOR l_origin.
TABLES: /psyng/sw_locapp,    "SOD Application Summary for child systems
        /psyng/sw_loccon,    "SOD Conflict Summary for child systems
        /psyng/sw_lochdr,    "SOD Header Summary for child systems
        /psyng/sw_locug,     "SOD User Group Summary for child systems
        /psyng/sw_locusr.    "SOD User Summary for child systems

TYPES: BEGIN OF typ_adrnr,
         adrnr TYPE adrc-addrnumber,
         orgnr TYPE /psyng/orgnr,
       END OF typ_adrnr,

       BEGIN OF typ_ug,
         class TYPE usr02-class,
         orgnr TYPE /psyng/orgnr,
       END OF typ_ug,

       BEGIN OF typ_usr,
         bname TYPE usr02-bname,
         orgnr TYPE /psyng/orgnr,
       END OF typ_usr.

DATA: BEGIN OF gt_usr02 OCCURS 0,
        sysid TYPE sysid,
        bname TYPE /psyng/ex_user_id,
        gltgv TYPE usr02-gltgv,
        gltgb TYPE usr02-gltgb,
        ustyp TYPE usr02-ustyp,
        class TYPE usr02-class,
        uflag TYPE usr02-uflag,
        orgnr TYPE /psyng/orgnr,
      END OF gt_usr02,

      BEGIN OF gt_oldst OCCURS 0,
        sysid TYPE sysid,
        orgnr TYPE /psyng/orgnr,
        date  TYPE /psyng/syscandt-scandate,
      END OF gt_oldst,

      BEGIN OF gt_conflict OCCURS 0,
        conid   TYPE /psyng/conflict-conid,
        busarea TYPE /psyng/conflict-busarea,
      END OF gt_conflict,

      BEGIN OF gt_app_user OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        busarea TYPE /psyng/sw_locapp-busarea,
        bname   TYPE xubname,
        count   TYPE i,
        ercount TYPE i,
      END OF gt_app_user,

      BEGIN OF gt_app_ug OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        busarea TYPE /psyng/sw_locapp-busarea,
        class   TYPE usr02-class,
        count   TYPE i,
        ercount TYPE i,
      END OF gt_app_ug,

      BEGIN OF gt_app OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        busarea TYPE /psyng/sw_locapp-busarea,
        count   TYPE i,
        ercount TYPE i,
      END OF gt_app,

      BEGIN OF gt_con_count OCCURS 0,
        sysid TYPE sysid,
        orgnr TYPE /psyng/orgnr,
        conid TYPE /psyng/conflict-conid,
        count TYPE i,
      END OF gt_con_count,

      BEGIN OF gt_con_user OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        conid   TYPE /psyng/conflict-conid,
        bname   TYPE xubname,
        count   TYPE i,
        ercount TYPE i,
      END OF gt_con_user,

      BEGIN OF gt_con_ug OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        conid   TYPE /psyng/conflict-conid,
        class   TYPE usr02-class,
        count   TYPE i,
        ercount TYPE i,
      END OF gt_con_ug,

      BEGIN OF gt_user_count OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        bname   TYPE xubname,
        count   TYPE i,
        ercount TYPE i,

      END OF gt_user_count,

      BEGIN OF gt_ug OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        class   TYPE usr02-class,
        count   TYPE i,
        ercount TYPE i,
      END OF gt_ug,

      BEGIN OF gt_ug_user OCCURS 0,
        sysid   TYPE sysid,
        orgnr   TYPE /psyng/orgnr,
        class   TYPE usr02-class,
        bname   TYPE xubname,
        count   TYPE i,
        ercount TYPE i,
      END OF gt_ug_user,

      BEGIN OF gt_all_org OCCURS 0,
        orgnr TYPE /psyng/orgnr,
        sysid TYPE /psyng/system,
      END OF gt_all_org,
*username should be 30 chars
*      BEGIN OF gt_syscandt OCCURS 0,
*        sysid TYPE sysid.
*        INCLUDE STRUCTURE /psyng/syscandt.
*DATA: END OF gt_syscandt,
      BEGIN OF gt_syscandt OCCURS 0,
        mandt    TYPE mandt,
        sysid    TYPE sysid,
        bname    TYPE /psyng/ex_user_id,
        conid    TYPE /psyng/conflict_id,
        vrsio    TYPE /psyng/sodvrsio,
        scandate TYPE sydatum,
        er       TYPE flag,
      END OF gt_syscandt,
      ls_config    TYPE /psyng/swconfig,
      g_sysid      LIKE sy-sysid, "the sysid of the local sap system
*     For the enhanced ruleset, and X will be added to the sysid
*     of the local system with an
      g_sysid_enh  LIKE sy-sysid,




      gt_orgnr_adr TYPE HASHED TABLE OF typ_adrnr WITH UNIQUE KEY adrnr,
      gt_orgnr_ug  TYPE HASHED TABLE OF typ_ug WITH UNIQUE KEY class,
      gt_orgnr_usr TYPE HASHED TABLE OF typ_usr WITH UNIQUE KEY bname,
      g_dflt_orgnr TYPE /psyng/orgnr,
      gf_ex_exists TYPE /psyng/bapiflagx,
      BEGIN OF   ls_vrsio   ,
        vrsio TYPE /psyng/vrsio,
        sysid TYPE /psyng/system,
      END OF ls_vrsio,
      gt_vrsio   LIKE TABLE OF ls_vrsio WITH HEADER LINE,
      l_vrsio(3) TYPE c.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE text-t02.
PARAMETERS: p_dialog AS CHECKBOX DEFAULT 'X' MODIF ID sel,
            p_comm   AS CHECKBOX DEFAULT 'X' MODIF ID sel,
            p_system AS CHECKBOX DEFAULT 'X' MODIF ID sel,
            p_servic AS CHECKBOX DEFAULT 'X' MODIF ID sel,
            p_refer  AS CHECKBOX DEFAULT 'X' MODIF ID sel.
SELECTION-SCREEN END OF BLOCK blk2.
SELECTION-SCREEN BEGIN OF BLOCK blk3 WITH FRAME TITLE text-t03.
PARAMETERS: p_adlock AS CHECKBOX DEFAULT 'X' MODIF ID sel,
            p_ulock  AS CHECKBOX DEFAULT 'X' MODIF ID sel.
SELECTION-SCREEN END OF BLOCK blk3.
PARAMETERS: p_inactv AS CHECKBOX DEFAULT 'X' MODIF ID sel.
SELECTION-SCREEN END OF BLOCK blk1.

*  2016/06/07 - ALways use specific scan table /psyng/locscandt
SELECTION-SCREEN BEGIN OF BLOCK blk4 WITH FRAME TITLE text-t04.
*PARAMETERS : p_loc_e TYPE flag DEFAULT 'X',
*             p_loc_n TYPE flag DEFAULT ' '.
SELECT-OPTIONS : sodvrsio FOR l_vrsio DEFAULT '000'.
SELECTION-SCREEN END OF BLOCK blk4.


INITIALIZATION.
*--Set preferences for Origin of conflicts (only relevant
*  for SE conflicts (not EN)
  gt_origin-sign = 'I'.
  gt_origin-option = 'EQ'.

  se_config_param 'SW_054_LOCAL' ls_config-value.
  IF  ls_config-value = 'Y'.
    gt_origin-low = '1'.
    APPEND gt_origin.
    MESSAGE s113 WITH 'Local conflicts included'(s01).

  ENDIF.
  se_config_param 'SW_054_REMOTE' ls_config-value.
  IF ls_config-value = 'Y'.
    gt_origin-low = '2'.
    APPEND gt_origin.
    MESSAGE s113 WITH 'Remote conflicts included'(s02).
  ENDIF.
  se_config_param 'SW_054_CROSS' ls_config-value.
  IF  ls_config-value = 'Y'.
    gt_origin-low = '3'.
    APPEND gt_origin.
    MESSAGE s113 WITH 'Cross system conflicts included'(s03).
  ENDIF.

  IF gt_origin[] IS INITIAL.
    gt_origin-sign = 'E'.
    gt_origin-option = 'BT'.
    gt_origin-low  = '1'.
    gt_origin-high = '3'.
    APPEND gt_origin.
  ENDIF.



*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.

  p_dialog = 'X'.
  p_comm   = 'X'.
  p_system = 'X'.
  p_servic = 'X'.
  p_refer  = 'X'.
  p_adlock = 'X'.
  p_ulock  = 'X'.
  p_inactv = 'X'.

  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
            ID 'Y&SW_ADMF' FIELD  'SUMMTAB'.
  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH text-e03.
  ENDIF.

  IF sy-batch IS INITIAL.
    IF p_dialog = space AND p_comm = space AND p_system = space
    AND p_servic = space AND p_refer = space.
      MESSAGE e113 WITH text-e01.
    ENDIF.
*    IF p_loc_e IS INITIAL AND p_loc_n IS INITIAL.
*      MESSAGE e113 WITH
*      'Normal and/or enhanced conflicts checkbox should'(e10)
*      'be selected.'(e11).
*    ENDIF.
*** Check for blank sod vrsion
** SF case 3753 fix
    IF sodvrsio IS INITIAL.
      MESSAGE e113 WITH 'Please enter SOD Version'(e12).
    ENDIF.
  ELSE.
***  Passing minimun required parameters to execute report in BG
** SF case 3753 fix
    IF p_dialog = space AND p_comm = space AND p_system = space
        AND p_servic = space AND p_refer = space.
      p_dialog = 'X'.
    ENDIF.
*    IF p_loc_e IS INITIAL AND p_loc_n IS INITIAL.
*      p_loc_e = 'X'.
*    ENDIF.
    IF sodvrsio IS INITIAL OR sodvrsio EQ space.
      sodvrsio = '000'.
    ENDIF.

  ENDIF.

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    IF screen-group1 = 'SEL'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

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
*************************************
**Authorization check for SW Admin Populate Local Scan tables
**SF 1665
*  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
*            ID 'Y&SW_ADMF' FIELD  'SUMMTAB'.
*  IF sy-subrc <> 0.
*    MESSAGE e108(/psyng/sw) WITH text-e03.
*    LEAVE LIST-PROCESSING.
*  ENDIF.

***SF 1665
*************************************

  p_dialog = 'X'.
  p_comm   = 'X'.
  p_system = 'X'.
  p_servic = 'X'.
  p_refer  = 'X'.
  p_adlock = 'X'.
  p_ulock  = 'X'.
  p_inactv = 'X'.

* Gather distinct versions


*Determine wether SOD Scan information for enhanced ruleset is stored in
*a separate table
  g_sysid = g_sysid_enh =  sy-sysid.
  se_config_param 'SW_ENH_SCAN_TBL' ls_config-value.
  IF sy-subrc = 0 AND ls_config-value = 'Y'.
    CONCATENATE g_sysid  'X' INTO g_sysid_enh.
  ENDIF.

* Check if SW for External Applications is installed
  DATA : l_tabname       TYPE dd02l-tabname.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = '/PSYNG/EX_SCANDT'
                  AND as4local = 'A'.            "#EC SAST_CI_GEN_CHECK
  IF sy-subrc = 0.
    gf_ex_exists = 'X'.
    SELECT DISTINCT vrsio sysid FROM (l_tabname) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
        APPENDING TABLE gt_vrsio WHERE vrsio IN sodvrsio."
  ENDIF.
*--2016/06/07 - Always use Specific Scan table /PSYNG/LOCSCANDT
  SELECT DISTINCT vrsio FROM /psyng/locscandt           "#EC CI_NOFIRST
  APPENDING CORRESPONDING FIELDS OF TABLE gt_vrsio
  WHERE vrsio IN sodvrsio.".
  gt_vrsio-sysid = sy-sysid.
  MODIFY gt_vrsio TRANSPORTING sysid WHERE sysid = ''.


*gather summary for each version.
  LOOP AT gt_vrsio.
* Delete existing records
    DELETE FROM /psyng/sw_lochdr                    "#EC CI_IMUD_NESTED
    WHERE orgnr NE space
    AND vrsio = gt_vrsio-vrsio .
*    AND sysid = gt_vrsio-sysid.
*Add version to these tables as well
*2016/06/07 - Delete all data from these tables
*             not just for the selected systems

    DELETE FROM /psyng/sw_locapp                    "#EC CI_IMUD_NESTED
           WHERE orgnr NE space
           AND vrsio = gt_vrsio-vrsio.
*         AND sysid = gt_vrsio-sysid.
    DELETE FROM /psyng/sw_loccon                    "#EC CI_IMUD_NESTED
               WHERE orgnr NE space
               AND vrsio = gt_vrsio-vrsio.
*             AND sysid = gt_vrsio-sysid.
    DELETE FROM /psyng/sw_locug                     "#EC CI_IMUD_NESTED
               WHERE orgnr NE space
               AND vrsio = gt_vrsio-vrsio.
*             AND sysid = gt_vrsio-sysid.
    DELETE FROM /psyng/sw_locusr                    "#EC CI_IMUD_NESTED
               WHERE orgnr NE space
               AND vrsio = gt_vrsio-vrsio.
*             AND sysid = gt_vrsio-sysid.
    COMMIT WORK.

    PERFORM gather_data.
    PERFORM initialize_tables.
    PERFORM summarize.
    PERFORM insert_database.
  ENDLOOP.
  MESSAGE s129.

*&---------------------------------------------------------------------*
*&      Form  gather_data
*&---------------------------------------------------------------------*
*       Retrieve data from database
*----------------------------------------------------------------------*
FORM gather_data.
  DATA: yulock TYPE x VALUE '80',     "Locked by incorrect login
        yusloc TYPE x VALUE '40',     "Locked by Administrator
        yugloc TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.


  DATA: lf_has_conflict TYPE /psyng/bapiflagx,
        l_value         TYPE /psyng/sw_loccfg-value,
        l_tabname       TYPE dd02l-tabname,
        ls_orgnr_adr    TYPE typ_adrnr,
        ls_orgnr_ug     TYPE typ_ug,
        ls_orgnr_usr    TYPE typ_usr.

  REFRESH :
      gt_syscandt[],
      gt_conflict[],
      gt_usr02[],
      gt_all_org[],
      gt_orgnr_adr[],
      gt_orgnr_ug[],
      gt_orgnr_usr[],
      gt_app[],
      gt_app_ug[],
      gt_app_user[],
      gt_con_ug[],
      gt_syscandt[],
      gt_con_count[],
      gt_con_user[],
      gt_ug[],
      gt_ug_user[],
      gt_user_count[],
      gt_oldst[].

  CLEAR: /psyng/sw_locapp , /psyng/sw_locug, /psyng/sw_loccon,
  /psyng/sw_locusr.
*check if this is local SAP system
  IF gt_vrsio-sysid = g_sysid OR gt_vrsio-sysid = g_sysid_enh.
* Get SOD Scan information
*--2016/06/07 - Always use Specific Scan table /PSYNG/LOCSCANDT
    gt_syscandt-sysid = g_sysid.
    SELECT bname conid scandate er FROM /psyng/locscandt
                                                        "#EC CI_NOFIRST
      INTO
        (gt_syscandt-bname, gt_syscandt-conid,
         gt_syscandt-scandate,gt_syscandt-er )
         WHERE
          vrsio = gt_vrsio-vrsio
          AND
          (

           ( conid <> 'NONE' AND origin IN gt_origin )
           OR
*16579 - also include NONE
           conid = 'NONE'
          ).
      APPEND gt_syscandt.
    ENDSELECT.

* Get total number of possible conflicts
    SELECT conid busarea INTO TABLE gt_conflict      "#EC CI_SEL_NESTED
     FROM /psyng/conflict
           WHERE inactive = space
           AND vrsio = gt_vrsio-vrsio.

* Add custom conflicts to list of all conflicts
    SELECT conid busarea APPENDING TABLE gt_conflict "#EC CI_SEL_NESTED
           FROM /psyng/sw_cuscon
           WHERE inactive = space
           AND vrsio = gt_vrsio-vrsio.
* Get all Organization numbers
    SELECT SINGLE value INTO l_value                 "#EC CI_SEL_NESTED
      FROM /psyng/sw_loccfg
                  WHERE param = 'DFLT_ORG_NUMBER'.

    IF sy-subrc <> 0.
      MESSAGE e128 WITH text-e02.
    ENDIF.

    g_dflt_orgnr = l_value.
    gt_all_org-orgnr = g_dflt_orgnr.
    gt_all_org-sysid = gt_vrsio-sysid.
    COLLECT gt_all_org.

    SELECT addrnumber orgnr INTO TABLE gt_orgnr_adr  "#EC CI_SEL_NESTED
       FROM /psyng/orgnr_adr.

    LOOP AT gt_orgnr_adr INTO ls_orgnr_adr.
      gt_all_org-orgnr = ls_orgnr_adr-orgnr.
      COLLECT gt_all_org.
    ENDLOOP.

    SELECT class orgnr INTO TABLE gt_orgnr_ug        "#EC CI_SEL_NESTED
      FROM /psyng/orgnr_ug.

    LOOP AT gt_orgnr_ug INTO ls_orgnr_ug.
      gt_all_org-orgnr = ls_orgnr_ug-orgnr.
      COLLECT gt_all_org.
    ENDLOOP.

    SELECT bname orgnr INTO TABLE gt_orgnr_usr       "#EC CI_SEL_NESTED
           FROM /psyng/orgnr_usr.

    LOOP AT gt_orgnr_usr INTO ls_orgnr_usr.
      gt_all_org-orgnr = ls_orgnr_usr-orgnr.
      COLLECT gt_all_org.
    ENDLOOP.

* Get user information
    SELECT bname gltgv gltgb ustyp class uflag       "#EC CI_SEL_NESTED
           INTO CORRESPONDING FIELDS OF TABLE gt_usr02
           FROM usr02.

* Check user options
    LOOP AT gt_usr02.
      CASE gt_usr02-ustyp.
        WHEN 'A'.
          IF p_dialog = space.           "Exclude dialog users
            DELETE gt_usr02.
            CONTINUE.
          ENDIF.

        WHEN 'B'.
          IF p_system = space.           "Exclude system users
            DELETE gt_usr02.
            CONTINUE.
          ENDIF.

        WHEN 'C'.
          IF p_comm = space.             "Exclude communication users
            DELETE gt_usr02.
            CONTINUE.
          ENDIF.

        WHEN 'L'.
          IF p_refer = space.            "Exclude reference users
            DELETE gt_usr02.
            CONTINUE.
          ENDIF.

        WHEN 'S'.
          IF p_servic = space.           "Exclude service users
            DELETE gt_usr02.
            CONTINUE.
          ENDIF.

      ENDCASE.
*--SF CASE 1405
      l_uflagx = gt_usr02-uflag."unicode

*   Exclude administrative locked users
*   IF gt_usr02-uflag > 0 AND gt_usr02-uflag <= 64 AND p_adlock = space.
      IF ( l_uflagx O yusloc OR "locked by admin
         l_uflagx O yugloc )    "locked by CUA admin
         AND
         p_adlock = space.
        DELETE gt_usr02.
        CONTINUE.
      ENDIF.

*   Exclude self-locked users
*    IF gt_usr02-uflag > 64 AND p_ulock = space.
      IF l_uflagx O yulock "User locked by failed logins
         AND p_ulock = space.
        DELETE gt_usr02.
        CONTINUE.
      ENDIF.

      IF p_inactv = space.               "Exclude inactive users
        IF gt_usr02-gltgv > sy-datum OR ( gt_usr02-gltgb < sy-datum
        AND NOT gt_usr02-gltgb IS INITIAL ).
          DELETE gt_usr02.
          CONTINUE.
        ENDIF.
      ENDIF.

*   Set system ID
      gt_usr02-sysid = gt_vrsio-sysid.

*   Get and update Organization Number
      PERFORM get_orgnr USING gt_usr02-bname gt_usr02-class
                        CHANGING gt_usr02-orgnr.
      MODIFY gt_usr02 TRANSPORTING sysid orgnr.
    ENDLOOP.

  ENDIF.
* Check if SW for External Applications is installed
  SELECT SINGLE tabname INTO l_tabname FROM dd02l    "#EC CI_SEL_NESTED
                WHERE tabname  = '/PSYNG/EX_SCANDT'
                  AND as4local = 'A'.            "#EC SAST_CI_GEN_CHECK

  IF sy-subrc = 0.
    gf_ex_exists = 'X'.

*   Get conflicts from External Application scan table
    l_tabname = '/PSYNG/EX_SCANDT'.
    SELECT sysid mandt bname  conid scandate         "#EC CI_SEL_NESTED
    APPENDING CORRESPONDING FIELDS OF TABLE gt_syscandt
           FROM (l_tabname)                      "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
           WHERE "conid <> 'NONE' AND
               vrsio = gt_vrsio-vrsio
           AND sysid = gt_vrsio-sysid.
  ENDIF.
  IF gf_ex_exists = 'X'.
*   Add conflicts from External Applications
    l_tabname = '/PSYNG/EX_CONHDR'.
    SELECT conid busarea APPENDING TABLE gt_conflict "#EC CI_SEL_NESTED
      FROM (l_tabname)                           "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
    WHERE vrsio = gt_vrsio-vrsio .

*   Add users from External Applications
    l_tabname = '/PSYNG/EX_USRHDR'.
    SELECT bname class orgnr sysid                   "#EC CI_SEL_NESTED
      INTO (gt_usr02-bname, gt_usr02-class, gt_usr02-orgnr,
            gt_usr02-sysid)
      FROM (l_tabname)                           "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
      WHERE sysid = gt_vrsio-sysid.

      APPEND gt_usr02.
      gt_all_org-orgnr = gt_usr02-orgnr.
      gt_all_org-sysid = gt_usr02-sysid.
      COLLECT gt_all_org.
    ENDSELECT.
  ENDIF.

  SORT gt_conflict BY conid.
ENDFORM.                    " gather_data

*&---------------------------------------------------------------------*
*&      Form  initialize_tables
*&---------------------------------------------------------------------*
*       Start with no conflicts for all possible combinations.  This
*       way, the summarized tables will also show where no conflicts
*       exist by having rows with zero SOD counts.
*----------------------------------------------------------------------*
FORM initialize_tables.
  DATA: BEGIN OF lt_busarea OCCURS 0,
          busarea TYPE /psyng/busarea-busarea,
        END OF lt_busarea.

  DATA: l_tabname  TYPE dd02l-tabname.
  DATA: l_version  TYPE /psyng/prog_vrsio.
  IF gt_vrsio-sysid = g_sysid OR gt_vrsio-sysid = g_sysid_enh.
* Get business areas
    SELECT busarea INTO TABLE lt_busarea             "#EC CI_SEL_NESTED
     FROM /psyng/busarea.
  ENDIF.
  IF gf_ex_exists = 'X'.
    l_tabname = '/PSYNG/EX_CONHDR'.
    SELECT DISTINCT busarea                          "#EC CI_SEL_NESTED
    APPENDING TABLE lt_busarea
     FROM (l_tabname)                            "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
      WHERE vrsio = gt_vrsio-vrsio .
  ENDIF.

* Set static fields for this job
  /psyng/sw_lochdr-erdat = /psyng/sw_locapp-erdat
                         = /psyng/sw_loccon-erdat
                         = /psyng/sw_locug-erdat
                         = /psyng/sw_locusr-erdat = sy-datum.
  /psyng/sw_lochdr-erzet = sy-uzeit.

* Get version numbers for header
*BOC UMITTAL PN-16237 28/01/2026
*the method of fetching SW version has been cahnged and instead
*of table it is now being fetched from SW_VERSION FM
*  SELECT SINGLE vrsio
*       INTO /psyng/sw_lochdr-sw_vrsio
*           FROM /psyng/sw_vrsio.

  CALL FUNCTION '/PSYNG/SW_VERSION'
    IMPORTING
      e_module_version = l_version.
  IF sy-subrc EQ 0.
    CLEAR /psyng/sw_lochdr-sw_vrsio.
    /psyng/sw_lochdr-sw_vrsio = l_version.
  ENDIF.
*EOC UMITTAL PN-16237 28/01/2026
  SELECT SINGLE vrsio                                "#EC CI_SEL_NESTED
      INTO /psyng/sw_lochdr-sod_vrsio
           FROM /psyng/sod_vrsio.
*  /psyng/sw_lochdr-sod_vrsio = gt_vrsio-vrsio.

* Insert initial rows into all tables
  LOOP AT gt_all_org.
    /psyng/sw_lochdr-sysid = /psyng/sw_locapp-sysid
                           = /psyng/sw_loccon-sysid = gt_all_org-sysid.
    /psyng/sw_lochdr-orgnr = /psyng/sw_locapp-orgnr
                           = /psyng/sw_loccon-orgnr = gt_all_org-orgnr.
    /psyng/sw_lochdr-vrsio = /psyng/sw_locapp-vrsio
                           = /psyng/sw_loccon-vrsio
                           = /psyng/sw_locusr-vrsio
                           = /psyng/sw_locug-vrsio
                           = gt_vrsio-vrsio.

    INSERT /psyng/sw_lochdr.

    LOOP AT lt_busarea.
      /psyng/sw_locapp-busarea = lt_busarea-busarea.
      INSERT /psyng/sw_locapp.
    ENDLOOP.

    LOOP AT gt_conflict.
      /psyng/sw_loccon-conid   = gt_conflict-conid.
      /psyng/sw_loccon-busarea = gt_conflict-busarea.
      INSERT /psyng/sw_loccon.
    ENDLOOP.
  ENDLOOP.

  LOOP AT gt_usr02.
*sf case 2001
*    /psyng/sw_locug-sysid = /psyng/sw_locusr-sysid = sy-sysid.
    /psyng/sw_locug-sysid = /psyng/sw_locusr-sysid = gt_vrsio-sysid.
    /psyng/sw_locug-orgnr = gt_usr02-orgnr.
    /psyng/sw_locug-class = gt_usr02-class.
    MODIFY /psyng/sw_locug.
    /psyng/sw_locusr-orgnr = gt_usr02-orgnr.
    /psyng/sw_locusr-bname = gt_usr02-bname.
    INSERT /psyng/sw_locusr.
  ENDLOOP.

  COMMIT WORK.
ENDFORM.                    " initialize_tables

*&---------------------------------------------------------------------*
*&      Form  summarize
*&---------------------------------------------------------------------*
*       Summarize information and insert into database
*----------------------------------------------------------------------*
FORM summarize.
  SORT gt_usr02 BY sysid bname.
  LOOP AT gt_syscandt.
    READ TABLE gt_usr02 WITH KEY sysid = gt_syscandt-sysid
                                 bname = gt_syscandt-bname
               BINARY SEARCH.
    CHECK sy-subrc = 0.

*   Calculate oldest scan date
    READ TABLE gt_oldst WITH KEY sysid = gt_syscandt-sysid
                                 orgnr = gt_usr02-orgnr
                        BINARY SEARCH.
    IF sy-subrc = 0.
      IF gt_oldst-date > gt_syscandt-scandate.
        gt_oldst-date = gt_syscandt-scandate.
        MODIFY gt_oldst INDEX sy-tabix TRANSPORTING date.
      ENDIF.
    ELSE.
      gt_oldst-sysid = gt_usr02-sysid.
      gt_oldst-orgnr = gt_usr02-orgnr.
      gt_oldst-date  = gt_syscandt-scandate.
      INSERT gt_oldst INDEX sy-tabix.
    ENDIF.
    CHECK gt_syscandt-conid <> 'NONE'.
    PERFORM sum_app        USING gt_usr02-bname gt_usr02-class
                                 gt_syscandt-conid gt_usr02-orgnr
                                 gt_usr02-sysid gt_syscandt-er.
    PERFORM sum_conflict   USING gt_usr02-bname gt_usr02-class
                                 gt_syscandt-conid gt_usr02-orgnr
                                 gt_usr02-sysid gt_syscandt-er.
    PERFORM sum_user       USING gt_usr02-bname gt_usr02-orgnr
                                 gt_usr02-sysid gt_syscandt-er.
    PERFORM sum_user_group USING gt_usr02-bname gt_usr02-class
                                 gt_usr02-orgnr
                                 gt_usr02-sysid gt_syscandt-er.
  ENDLOOP.    "gt_syscandt
  FREE gt_syscandt.
  SORT: gt_app_user   BY orgnr busarea bname,
        gt_app_ug     BY orgnr busarea class,
        gt_app        BY orgnr busarea,
        gt_con_count  BY orgnr conid,
        gt_con_user   BY orgnr conid bname,
        gt_con_ug     BY orgnr conid class,
        gt_user_count BY orgnr bname,
        gt_ug         BY orgnr class,
        gt_ug_user    BY orgnr class bname.
ENDFORM.                    " summarize

*&---------------------------------------------------------------------*
*&      Form  get_orgnr
*&---------------------------------------------------------------------*
*       Get organization number
*----------------------------------------------------------------------*
*      -->I_BNAME  User ID
*      -->I_CLASS  User Group
*      <--E_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM get_orgnr USING    i_bname TYPE /psyng/ex_user_id
                        i_class TYPE usr02-class
               CHANGING e_orgnr TYPE /psyng/orgnr.

  STATICS: lt_priority TYPE TABLE OF /psyng/sw_loccfg WITH HEADER LINE.

* Get priority of Org. Number selection
  IF lt_priority[] IS INITIAL.
    SELECT * INTO TABLE lt_priority                  "#EC CI_SEL_NESTED
      FROM /psyng/sw_loccfg
           WHERE param IN ('PRI_ORG_COMP_NUM', 'PRI_ORG_DFLT',
                           'PRI_ORG_USER_GROUP', 'PRI_ORG_USER_ID').

*   If not found, default order to be User ID, User Group, Company
*   Number, Default Org. Number
    IF sy-subrc <> 0.
      lt_priority-param = 'PRI_ORG_USER_ID'.
      lt_priority-value = '1'.
      APPEND lt_priority.
      lt_priority-param = 'PRI_ORG_USER_GROUP'.
      lt_priority-value = '2'.
      APPEND lt_priority.
      lt_priority-param = 'PRI_ORG_COMP_NUM'.
      lt_priority-value = '3'.
      APPEND lt_priority.
      lt_priority-param = 'PRI_ORG_DFLT'.
      lt_priority-value = '4'.
      APPEND lt_priority.
    ENDIF.

    SORT lt_priority BY value.
  ENDIF.

  LOOP AT lt_priority.
    CASE lt_priority-param.
      WHEN 'PRI_ORG_COMP_NUM'.
        PERFORM get_orgnr_comp USING i_bname
                               CHANGING e_orgnr.
      WHEN 'PRI_ORG_DFLT'.
        PERFORM get_orgnr_dflt CHANGING e_orgnr.
      WHEN 'PRI_ORG_USER_GROUP'.
        PERFORM get_orgnr_ug USING i_class
                             CHANGING e_orgnr.
      WHEN 'PRI_ORG_USER_ID'.
        PERFORM get_orgnr_user USING i_bname
                               CHANGING e_orgnr.
    ENDCASE.

    IF NOT e_orgnr IS INITIAL.
      EXIT.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " get_orgnr

*&---------------------------------------------------------------------*
*&      Form  get_orgnr_comp
*&---------------------------------------------------------------------*
*       Get Organization Number by company
*----------------------------------------------------------------------*
*      -->I_BNAME  User ID
*      <--E_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM get_orgnr_comp USING    i_bname TYPE /psyng/ex_user_id
                    CHANGING e_orgnr TYPE /psyng/orgnr.
  DATA: ls_adrnr TYPE typ_adrnr.


  SELECT SINGLE addrnumber INTO ls_adrnr-adrnr       "#EC CI_SEL_NESTED
    FROM usr21
                WHERE bname = i_bname.

  READ TABLE gt_orgnr_adr INTO ls_adrnr
             WITH TABLE KEY adrnr = ls_adrnr-adrnr.

  CHECK sy-subrc = 0.
  e_orgnr = ls_adrnr-orgnr.
ENDFORM.                    " get_orgnr_comp

*&---------------------------------------------------------------------*
*&      Form  get_orgnr_dflt
*&---------------------------------------------------------------------*
*       Get default Organization Number
*----------------------------------------------------------------------*
*      <--E_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM get_orgnr_dflt CHANGING e_orgnr TYPE /psyng/orgnr.
  e_orgnr = g_dflt_orgnr.
ENDFORM.                    " get_orgnr_dflt

*&---------------------------------------------------------------------*
*&      Form  get_orgnr_ug
*&---------------------------------------------------------------------*
*       Get Organization Number by user group
*----------------------------------------------------------------------*
*      -->I_CLASS  User Group
*      <--E_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM get_orgnr_ug USING    i_class TYPE usr02-class
                  CHANGING e_orgnr TYPE /psyng/orgnr.
  DATA: ls_ug TYPE typ_ug.


  READ TABLE gt_orgnr_ug INTO ls_ug WITH TABLE KEY class = i_class.

  CHECK sy-subrc = 0.
  e_orgnr = ls_ug-orgnr.
ENDFORM.                    " get_orgnr_ug

*&---------------------------------------------------------------------*
*&      Form  get_orgnr_user
*&---------------------------------------------------------------------*
*       Get Organization Number by user ID
*----------------------------------------------------------------------*
*      -->I_BNAME  User ID
*      <--E_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM get_orgnr_user USING    i_bname TYPE /psyng/ex_user_id
                    CHANGING e_orgnr TYPE /psyng/orgnr.
  DATA: ls_usr TYPE typ_usr.


  READ TABLE gt_orgnr_usr INTO ls_usr WITH TABLE KEY bname = i_bname.

  CHECK sy-subrc = 0.
  e_orgnr = ls_usr-orgnr.
ENDFORM.                    " get_orgnr_user

*&---------------------------------------------------------------------*
*&      Form  sum_app
*&---------------------------------------------------------------------*
*       Summarize by application area
*----------------------------------------------------------------------*
*      -->I_BNAME  User ID
*      -->I_CLASS  User Group
*      -->I_CONID  Conflict ID
*      -->I_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM sum_app USING i_bname TYPE /psyng/ex_user_id
                   i_class TYPE usr02-class
                   i_conid TYPE /psyng/conflict-conid
                   i_orgnr TYPE /psyng/orgnr
                   i_sysid TYPE sysid
                   i_er    TYPE flag.
  gt_app_user-count = gt_app_ug-count = gt_app-count = 0.
  gt_app_user-ercount = gt_app_ug-ercount = gt_app-ercount = 0.
  IF i_er IS INITIAL.
    gt_app_user-count = gt_app_ug-count = gt_app-count = 1.
  ELSE.
    gt_app_user-ercount = gt_app_ug-ercount = gt_app-ercount = 1.
  ENDIF.
  gt_app_user-orgnr = gt_app_ug-orgnr = gt_app-orgnr = i_orgnr.

  CLEAR gt_conflict.
  READ TABLE gt_conflict WITH KEY conid = i_conid
                         BINARY SEARCH.
  gt_app-sysid   =  i_sysid .
  gt_app-busarea = gt_conflict-busarea.
  COLLECT gt_app.
  gt_app_user-sysid   =  i_sysid .
  gt_app_user-bname   = i_bname.
  gt_app_user-busarea = gt_conflict-busarea.
  COLLECT gt_app_user.
  gt_app_ug-sysid   =  i_sysid .
  gt_app_ug-class   = i_class.
  gt_app_ug-busarea = gt_conflict-busarea.
  COLLECT gt_app_ug.
ENDFORM.                    " sum_app

*&---------------------------------------------------------------------*
*&      Form  sum_conflict
*&---------------------------------------------------------------------*
*       Summarize by conflict ID
*----------------------------------------------------------------------*
*      -->I_BNAME  User ID
*      -->I_CLASS  User Group
*      -->I_CONID  Conflict ID
*      -->I_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM sum_conflict USING i_bname TYPE /psyng/ex_user_id
                        i_class TYPE usr02-class
                        i_conid TYPE /psyng/conflict-conid
                        i_orgnr TYPE /psyng/orgnr
                        i_sysid TYPE sysid
                        i_er    TYPE flag.

  gt_con_count-count = 1.
  gt_con_user-count = gt_con_ug-count = 0.
  gt_con_user-ercount = gt_con_ug-ercount = 0.
  IF i_er IS INITIAL.
    gt_con_user-count = gt_con_ug-count = 1.
  ELSE.
    gt_con_user-ercount = gt_con_ug-ercount = 1.
  ENDIF.
  gt_con_user-orgnr = gt_con_ug-orgnr = gt_con_count-orgnr = i_orgnr.

  gt_con_count-conid = i_conid.
  gt_con_count-sysid = i_sysid.
  COLLECT gt_con_count.
  gt_con_user-bname = i_bname.
  gt_con_user-conid = i_conid.
  gt_con_user-sysid = i_sysid.

  COLLECT gt_con_user.
  gt_con_ug-class = i_class.
  gt_con_ug-conid = i_conid.
  gt_con_ug-sysid = i_sysid.

  COLLECT gt_con_ug.
ENDFORM.                    " sum_conflict

*&---------------------------------------------------------------------*
*&      Form  sum_user
*&---------------------------------------------------------------------*
*       Summarize by user ID
*----------------------------------------------------------------------*
*      -->I_BNAME  User ID
*      -->I_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM sum_user USING i_bname TYPE /psyng/ex_user_id
                    i_orgnr TYPE /psyng/orgnr
                    i_sysid TYPE sysid
                    i_er    TYPE flag.

  IF i_er IS INITIAL.
    gt_user_count-count   = 1.
    gt_user_count-ercount = 0.
  ELSE.
    gt_user_count-count   = 0.
    gt_user_count-ercount = 1.
  ENDIF.
  gt_user_count-orgnr = i_orgnr.
  gt_user_count-bname = i_bname.
  gt_user_count-sysid = i_sysid.
  COLLECT gt_user_count.
ENDFORM.                    " sum_user

*&---------------------------------------------------------------------*
*&      Form  sum_user_group
*&---------------------------------------------------------------------*
*       Summarize by user group
*----------------------------------------------------------------------*
*      -->I_BNAME  User ID
*      -->I_CLASS  User Group
*      -->I_ORGNR  Organization Number
*----------------------------------------------------------------------*
FORM sum_user_group USING i_bname TYPE /psyng/ex_user_id
                          i_class TYPE usr02-class
                          i_orgnr TYPE /psyng/orgnr
                          i_sysid TYPE sysid
                          if_er    TYPE flag.


  gt_ug-count = gt_ug_user-count = 0.
  gt_ug-ercount = gt_ug_user-ercount = 0.
  IF if_er IS INITIAL.
    gt_ug-count = gt_ug_user-count = 1.
  ELSE.
    gt_ug-ercount = gt_ug_user-ercount = 1.
  ENDIF.
  gt_ug-orgnr = gt_ug_user-orgnr = i_orgnr.
  gt_ug-sysid = i_sysid.
  gt_ug-class = i_class.
  COLLECT gt_ug.
  gt_ug_user-sysid = i_sysid.
  gt_ug_user-class = i_class.
  gt_ug_user-bname = i_bname.
  COLLECT gt_ug_user.
ENDFORM.                    " sum_user_group

*&---------------------------------------------------------------------*
*&      Form  insert_database
*&---------------------------------------------------------------------*
*       Insert into database
*----------------------------------------------------------------------*
FORM insert_database.
  DATA: BEGIN OF lt_lochdr OCCURS 0,
          orgnr TYPE /psyng/sw_lochdr-orgnr,
          sysid TYPE /psyng/sw_lochdr-sysid,
          erdat TYPE /psyng/sw_lochdr-erdat,
          erzet TYPE /psyng/sw_lochdr-erzet,
        END OF lt_lochdr.

  DATA: l_user_index TYPE i,
        l_ug_index   TYPE i.


* Insert into application area table
*  clear /psyng/sw_locapp.
  LOOP AT gt_app.
    /psyng/sw_locapp-orgnr     = gt_app-orgnr.
    /psyng/sw_locapp-busarea   = gt_app-busarea.
    /psyng/sw_locapp-sod_count = gt_app-count.
    /psyng/sw_locapp-sod_er_ct = gt_app-ercount.
    /psyng/sw_locapp-sysid     = gt_app-sysid.

*   Calculate affected user count
    LOOP AT gt_app_user FROM l_user_index.
      IF gt_app_user-orgnr   <> gt_app-orgnr
      OR gt_app_user-busarea <> gt_app-busarea
*20090909 - added for systems with only one conflict
      OR gt_app_user-sysid   <> gt_app-sysid.
        l_user_index = sy-tabix.

        EXIT.
      ENDIF.
      IF gt_app_user-ercount > 0.
        ADD 1 TO /psyng/sw_locapp-aff_usr_er_ct.
      ENDIF.
      IF gt_app_user-count > 0.
        ADD 1 TO /psyng/sw_locapp-aff_usr_ct.
      ENDIF.

    ENDLOOP.

*   Calculate affected user group count
*    clear /psyng/sw_locapp.
    LOOP AT gt_app_ug FROM l_ug_index.
      IF gt_app_ug-orgnr   <> gt_app-orgnr
      OR gt_app_ug-busarea <> gt_app-busarea
*20090909 - added for systems with only one conflict
      OR gt_app_ug-sysid   <> gt_app-sysid
.
        l_ug_index = sy-tabix.
        EXIT.
      ENDIF.
      IF gt_app_ug-ercount > 0.
        ADD 1 TO /psyng/sw_locapp-aff_ug_er_ct.
      ENDIF.
      IF gt_app_ug-count > 0.
        ADD 1 TO /psyng/sw_locapp-aff_ug_count.
      ENDIF.

    ENDLOOP.

    MODIFY /psyng/sw_locapp.
    CLEAR:
          /psyng/sw_locapp-aff_usr_ct, /psyng/sw_locapp-aff_ug_count,
          /psyng/sw_locapp-aff_ug_er_ct, /psyng/sw_locapp-aff_usr_er_ct.
  ENDLOOP.

* Insert into conflict table
  CLEAR: l_user_index, l_ug_index.
  LOOP AT gt_con_count.
    CLEAR gt_conflict-busarea.
    READ TABLE gt_conflict WITH KEY conid = gt_con_count-conid
                           BINARY SEARCH.
    /psyng/sw_loccon-orgnr   = gt_con_count-orgnr.
    /psyng/sw_loccon-conid   = gt_con_count-conid.
    /psyng/sw_loccon-sysid   = gt_con_count-sysid.
    /psyng/sw_loccon-busarea = gt_conflict-busarea.


*   Calculate affected user count
    LOOP AT gt_con_user FROM l_user_index.
      IF gt_con_user-orgnr <> gt_con_count-orgnr
      OR gt_con_user-conid <> gt_con_count-conid
*20090909 - added for systems with only one conflict
      OR gt_con_user-sysid <> gt_con_count-sysid.
        l_user_index = sy-tabix.
        EXIT.
      ENDIF.
      IF gt_con_user-count > 0.
        ADD 1 TO /psyng/sw_loccon-aff_usr_ct.
      ENDIF.
      IF gt_con_user-ercount > 0.
        ADD 1 TO /psyng/sw_loccon-aff_usr_er_ct.
      ENDIF.
    ENDLOOP.

*   Calculate affected user group count
    LOOP AT gt_con_ug FROM l_ug_index.
      IF gt_con_ug-orgnr <> gt_con_count-orgnr
      OR gt_con_ug-conid <> gt_con_count-conid
*20090909 - added for systems with only one conflict
      OR gt_con_ug-sysid <> gt_con_count-sysid.
        l_ug_index = sy-tabix.
        EXIT.
      ENDIF.
      IF gt_con_ug-count > 0.
        ADD 1 TO /psyng/sw_loccon-aff_ug_count.
      ENDIF.
      IF gt_con_ug-ercount > 0.
        ADD 1 TO /psyng/sw_loccon-aff_ug_er_ct.
      ENDIF.
    ENDLOOP.

    MODIFY /psyng/sw_loccon.
    CLEAR: /psyng/sw_loccon-aff_usr_ct, /psyng/sw_loccon-aff_ug_count,
           /psyng/sw_loccon-aff_usr_er_ct,
           /psyng/sw_loccon-aff_ug_er_ct.
  ENDLOOP.

* Insert into user group table
  CLEAR l_user_index.
  LOOP AT gt_ug.
    /psyng/sw_locug-orgnr     = gt_ug-orgnr.
    /psyng/sw_locug-class     = gt_ug-class.
    /psyng/sw_locug-sysid     = gt_ug-sysid.
    /psyng/sw_locug-sod_count = gt_ug-count.
    /psyng/sw_locug-sod_er_ct = gt_ug-ercount.


*   Calculate affected user count
    LOOP AT gt_ug_user FROM l_user_index.
      IF gt_ug_user-orgnr <> gt_ug-orgnr
      OR gt_ug_user-class <> gt_ug-class
*20090909 - added for systems with only one conflict
      OR gt_ug_user-sysid <> gt_ug-sysid.
        l_user_index = sy-tabix.
        EXIT.
      ENDIF.
      IF gt_ug_user-count > 0.
        ADD 1 TO /psyng/sw_locug-aff_usr_ct.
      ENDIF.
      IF gt_ug_user-ercount > 0.
        ADD 1 TO /psyng/sw_locug-aff_usr_er_ct.
      ENDIF.
*      ADD 1 TO /psyng/sw_locug-aff_usr_ct.
    ENDLOOP.

    MODIFY /psyng/sw_locug.
    CLEAR : /psyng/sw_locug-aff_usr_ct,
          /psyng/sw_locug-aff_usr_er_ct,
          /psyng/sw_locug-sod_count,
          /psyng/sw_locug-sod_er_ct.
  ENDLOOP.

* Insert into user table
  LOOP AT gt_user_count.
    /psyng/sw_locusr-orgnr     = gt_user_count-orgnr.
    /psyng/sw_locusr-bname     = gt_user_count-bname.
    /psyng/sw_locusr-sod_count = gt_user_count-count.
    /psyng/sw_locusr-sod_er_ct = gt_user_count-ercount.
    /psyng/sw_locusr-sysid     = gt_user_count-sysid.
    MODIFY /psyng/sw_locusr.
  ENDLOOP.

* Insert into header table
  SORT gt_usr02 BY sysid orgnr.
  SORT gt_user_count BY sysid orgnr.
  CLEAR l_user_index.
  LOOP AT gt_user_count.
    AT NEW orgnr.
      /psyng/sw_lochdr-sysid = gt_user_count-sysid.

      CLEAR gt_oldst.
      READ TABLE gt_oldst WITH KEY sysid = gt_user_count-sysid
                                   orgnr = gt_user_count-orgnr
                          BINARY SEARCH.

      /psyng/sw_lochdr-oldst_date = gt_oldst-date.
*     Calculate total user count by Organization Number
      LOOP AT gt_usr02 FROM l_user_index
                       WHERE sysid = gt_user_count-sysid
                         AND orgnr = gt_user_count-orgnr.

        l_user_index = sy-tabix.
        ADD 1 TO /psyng/sw_lochdr-tot_usr_ct.
      ENDLOOP.
    ENDAT.

    /psyng/sw_lochdr-orgnr = gt_user_count-orgnr.
*    ADD 1 TO /psyng/sw_lochdr-aff_usr_ct.
    IF gt_user_count-count > 0.
      ADD 1 TO /psyng/sw_lochdr-aff_usr_ct.
      ADD gt_user_count-count TO /psyng/sw_lochdr-sod_count.
    ENDIF.
    IF gt_user_count-ercount > 0.
      ADD 1 TO /psyng/sw_lochdr-aff_usr_er_ct.
      ADD gt_user_count-ercount TO /psyng/sw_lochdr-sod_er_ct.
    ENDIF.


    AT END OF orgnr.
      MODIFY /psyng/sw_lochdr.
      CLEAR: /psyng/sw_lochdr-aff_usr_ct, /psyng/sw_lochdr-tot_usr_ct,
             /psyng/sw_lochdr-sod_count,/psyng/sw_lochdr-sod_er_ct,
             /psyng/sw_lochdr-aff_usr_er_ct.
    ENDAT.
  ENDLOOP.

* Get total user count for all organizations/systems with no conflicts
  CLEAR l_user_index.
  SELECT orgnr sysid erdat erzet                     "#EC CI_SEL_NESTED
      INTO TABLE lt_lochdr
         FROM /psyng/sw_lochdr
         WHERE tot_usr_ct = 0.

  SORT lt_lochdr BY sysid orgnr.
  LOOP AT lt_lochdr.
    CLEAR /psyng/sw_lochdr-tot_usr_ct.
    LOOP AT gt_usr02 FROM l_user_index
            WHERE sysid = lt_lochdr-sysid
              AND orgnr = lt_lochdr-orgnr.

      l_user_index = sy-tabix.
      ADD 1 TO /psyng/sw_lochdr-tot_usr_ct.
    ENDLOOP.

    CLEAR gt_oldst.
    READ TABLE gt_oldst WITH KEY sysid = lt_lochdr-sysid
                                 orgnr = lt_lochdr-orgnr
                        BINARY SEARCH.
    /psyng/sw_lochdr-oldst_date = gt_oldst-date.

    UPDATE /psyng/sw_lochdr                         "#EC CI_IMUD_NESTED
                 SET tot_usr_ct = /psyng/sw_lochdr-tot_usr_ct
                     oldst_date = /psyng/sw_lochdr-oldst_date
                                    WHERE orgnr = lt_lochdr-orgnr
                                      AND sysid = lt_lochdr-sysid
                                      AND erdat = lt_lochdr-erdat
                                      AND erzet = lt_lochdr-erzet.
  ENDLOOP.
  COMMIT WORK.
ENDFORM.                    " insert_database
