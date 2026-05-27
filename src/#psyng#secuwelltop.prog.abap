*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECUWELLTOP
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
*INCLUDE /PSYNG/SECUWELLTOP .                                        *
*----------------------------------------------------------------------*
TYPE-POOLS: trwbo, ustyp.
TYPE-POOLS: vrm.
TABLES: /psyng/mchdr,        "SW: Mitigating Controls Header
        /psyng/mcuser,       "SW: Mitigating Controls Users
        /psyng/mcrole.       "Mitigating Controls Assignment to Roles
TABLES: usr11,/psyng/mcusrgrp,/psyng/mtrees,/psyng/mcrvwhdr.
TABLES : /psyng/mcugrpaud, /psyng/tsw_hst, /psyng/tsw_grhst.
TABLES: agr_agrs, agr_tcodes.
TABLES: /psyng/mccauser, /psyng/mctran, /psyng/sw_fioria.
CLASS lcl_application DEFINITION DEFERRED.
CLASS cl_gui_cfw DEFINITION LOAD.

CONSTANTS: gc_type_button TYPE /psyng/sw_button_tab_type VALUE 'Button',
           gc_type_box    TYPE /psyng/sw_button_tab_type VALUE 'Box',
           gc_type_tab    TYPE /psyng/sw_button_tab_type VALUE 'Tab'.

DATA : gf_custom_tab_selected TYPE flag.
TYPES: node_table_type LIKE STANDARD TABLE OF /psyng/mtrees
           WITH DEFAULT KEY.

TYPES: BEGIN OF t_trans,
         tcode   LIKE tstct-tcode,
         ttext   LIKE tstct-ttext,
         imp     LIKE /psyng/critcodes-imp,
         owner   LIKE /psyng/critcodes-owner,
         busarea LIKE /psyng/critcodes-busarea,
*         description LIKE /psyng/critcodes-description,
         flag,       "flag for mark column
       END OF t_trans.

*select-options for calling SODREPORT
TYPES: BEGIN OF t_role,
         sign(1)   TYPE c,
         option(2) TYPE c,
         low       LIKE agr_define-agr_name,
         high      LIKE agr_define-agr_name,
       END OF t_role.

* DECLARATION OF TABLECONTROL 'CONFLICT_DISP' ITSELF
CONTROLS: conflict_disp TYPE TABLEVIEW USING SCREEN 0302.

DATA : l_tbl_cntrl TYPE sy-ucomm.

DATA: g_application            TYPE REF TO lcl_application,
      g_left_custom_container  TYPE REF TO cl_gui_custom_container,
      g_right_custom_container TYPE REF TO cl_gui_custom_container,
      g_left_tree              TYPE REF TO cl_gui_simple_tree,
      g_right_tree             TYPE REF TO cl_gui_simple_tree,
      left_node_table          TYPE node_table_type,
      right_node_table         TYPE node_table_type,
      local_node_table         TYPE node_table_type,
      behaviour_left           TYPE REF TO cl_dragdrop,
      behaviour_right          TYPE REF TO cl_dragdrop,
      next_node_key_right      TYPE i,
      g_ok_code                TYPE sy-ucomm,
      g_active_inactive        TYPE string.

DATA: node         LIKE /psyng/mtrees,
      effect       TYPE i,
      handle_left  TYPE i,
      handle_right TYPE i.

DATA: BEGIN OF itab_tcode   OCCURS 0.
DATA:     tcode TYPE tstct-tcode.
DATA: END OF itab_tcode.

* INTERNAL TABLE FOR TABLECONTROL 'ROLE_TRANS'
DATA:     BEGIN OF g_role_trans_itab   OCCURS 0.
DATA:     tcode TYPE tstct-tcode,
          ttext TYPE tstct-ttext,
          flag  TYPE c.
DATA: END OF g_role_trans_itab.

DATA:     BEGIN OF g_role_trans_itab2   OCCURS 0.
DATA:     tcode TYPE tstct-tcode,
          ttext TYPE tstct-ttext.
DATA: END OF g_role_trans_itab2.

DATA:     BEGIN OF itab_funct1   OCCURS 0.
DATA:     functionid TYPE /psyng/functtran-functionid,
          tcode      TYPE /psyng/functtran-tcode.
DATA: END OF itab_funct1.

* FUNCTION CODES FOR TABSTRIP 'SODFUN'
CONSTANTS: BEGIN OF c_sodfun,
             tab1 LIKE sy-ucomm VALUE 'SODFUN_FC1',
             tab2 LIKE sy-ucomm VALUE 'SODFUN_FC2',
             tab4 LIKE sy-ucomm VALUE 'SODFUN_FC4',
             tab5 LIKE sy-ucomm VALUE 'SODFUN_FC5',
             tab6 LIKE sy-ucomm VALUE 'SODFUN_FC6',
             tab7 LIKE sy-ucomm VALUE 'SODFUN_FC7',
             tab8 LIKE sy-ucomm VALUE 'SODFUN_FC8',

           END OF c_sodfun.
* DATA FOR TABSTRIP 'SODFUN'
CONTROLS:  sodfun TYPE TABSTRIP.
DATA:      BEGIN OF g_sodfun,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE '/PSYNG/SECUWELL',
             pressed_tab LIKE sy-ucomm , "VALUE c_sodfun-tab1,
           END OF g_sodfun.

* FUNCTION CODES FOR TABSTRIP 'MITCON'
CONSTANTS: BEGIN OF c_mitcon,
             tab1 LIKE sy-ucomm VALUE 'MITCON_FC1',
             tab2 LIKE sy-ucomm VALUE 'MITCON_FC2',
             tab3 LIKE sy-ucomm VALUE 'MITCON_FC3',
             tab4 LIKE sy-ucomm VALUE 'MITCON_FC4',
             tab5 LIKE sy-ucomm VALUE 'MITCON_FC5',
             tab6 LIKE sy-ucomm VALUE 'MITCON_FC6',
             tab7 LIKE sy-ucomm VALUE 'MITCON_FC7',
           END OF c_mitcon.

* DATA FOR TABSTRIP 'MITCON'
CONTROLS:  mitcon TYPE TABSTRIP.
DATA:      BEGIN OF g_mitcon,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE '/PSYNG/SECUWELL',
             pressed_tab LIKE sy-ucomm , "VALUE c_mitcon-tab1,
           END OF g_mitcon.

* Mitigating controls
CONTROLS: tc_mctran    TYPE TABLEVIEW USING SCREEN 0227,
          tc_mcrepid   TYPE TABLEVIEW USING SCREEN 0227,
          tc_mcauditor TYPE TABLEVIEW USING SCREEN 0211,
          tc_mcuser    TYPE TABLEVIEW USING SCREEN 0212,
          tc_mcusrgrp  TYPE TABLEVIEW USING SCREEN 0222,
          tc_mccriauth TYPE TABLEVIEW USING SCREEN 0223,
          tc_mcrole    TYPE TABLEVIEW USING SCREEN 0224,
          tc_mccarole  TYPE TABLEVIEW USING SCREEN 0225.


DATA: BEGIN OF gt_mctran OCCURS 0.
        INCLUDE STRUCTURE /psyng/mctran.
DATA:   sel TYPE /psyng/flagx,
        END OF gt_mctran.

DATA: BEGIN OF gt_mcrepid OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcrepid.
DATA:   sel TYPE /psyng/flagx,
        END OF gt_mcrepid.

DATA: BEGIN OF gt_mcauditor OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcauditor.
DATA:   comp_name(20) TYPE c,
        sel           TYPE /psyng/flagx,
        END OF gt_mcauditor.

DATA : wa_mcauditor LIKE  gt_mcauditor.

DATA: BEGIN OF gt_mcuser OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcuser.
DATA: show_dtl(10) TYPE c,
      attach_avl(15)   type c,
      just_avl(15)  type c,
      sel          TYPE /psyng/flagx,
      END OF gt_mcuser.

DATA: gl_mcuser LIKE gt_mcuser.
DATA:l_mes_text(72) TYPE c.
DATA: BEGIN OF gt_mccauser OCCURS 0.
        INCLUDE STRUCTURE /psyng/mccauser.
DATA:  attach_avl(15)   type c,
       just_avl(15)  type c,
       sel TYPE /psyng/flagx,
      END OF gt_mccauser.

DATA: gl_mccauser LIKE gt_mccauser.

DATA: BEGIN OF gt_mcusrgrp OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcusrgrp.
DATA:  show_dtl(10) TYPE c,
       attach_avl(15)   type c,
       just_avl(15)  type c,
       sel          TYPE /psyng/flagx,
       END OF gt_mcusrgrp.

DATA: gl_mcusrgrp LIKE gt_mcusrgrp.

DATA: BEGIN OF gt_mcrole OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcrole.
DATA:  show_dtl(10) TYPE c,
       attach_avl(15)   type c,
       just_avl(15)  type c,
       sel          TYPE /psyng/flagx,
       END OF gt_mcrole.

DATA: gl_mcrole LIKE gt_mcrole.

DATA: BEGIN OF gt_mccarole OCCURS 0.
        INCLUDE STRUCTURE /psyng/mccarole.
DATA: show_dtl(10) TYPE c,
      attach_avl(15)   type c,
      just_avl(15)  type c,
      sel          TYPE /psyng/flagx,
      END OF gt_mccarole.

DATA: gl_mccarole LIKE LINE OF gt_mccarole.

* FUNCTION CODES FOR TABSTRIP 'ROLES'
CONSTANTS: BEGIN OF c_roles,
             tab1 LIKE sy-ucomm VALUE 'ROLES_FC1',
             tab2 LIKE sy-ucomm VALUE 'ROLES_FC2',
             tab3 LIKE sy-ucomm VALUE 'ROLES_FC3',
           END OF c_roles.
* DATA FOR TABSTRIP 'ROLES'
CONTROLS:  roles TYPE TABSTRIP.
DATA:      BEGIN OF g_roles,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE '/PSYNG/SECUWELL',
             pressed_tab LIKE sy-ucomm VALUE c_roles-tab1,
           END OF g_roles.

* FUNCTION CODES FOR TABSTRIP 'ROLEHDR'
CONSTANTS: BEGIN OF c_rolehdr,
             tab1 LIKE sy-ucomm VALUE 'ROLEHDR_FC1',
             tab2 LIKE sy-ucomm VALUE 'ROLEHDR_FC2',
           END OF c_rolehdr.
* DATA FOR TABSTRIP 'ROLEHDR'
CONTROLS:  rolehdr TYPE TABSTRIP.
DATA:      BEGIN OF g_rolehdr,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE '/PSYNG/SECUWELL',
             pressed_tab LIKE sy-ucomm VALUE c_rolehdr-tab1,
           END OF g_rolehdr.

* INTERNAL TABLE FOR Conflicts Display
DATA:     BEGIN OF conflict  OCCURS 0.
DATA:     conid       TYPE /psyng/conflict-conid,
          description TYPE /psyng/conflict-description.
DATA:     END OF conflict.

DATA:     BEGIN OF itab_con  OCCURS 0.
DATA:     conid TYPE /psyng/conflict-conid.
DATA:     END OF itab_con.

*--Conflict Owner
DATA: BEGIN OF gt_conowner OCCURS 0.
        INCLUDE STRUCTURE /psyng/conowner.
DATA:   comp_name(20) TYPE c,
        sel           TYPE /psyng/flagx,
        END OF gt_conowner.
CONTROLS: tc_conowner  TYPE TABLEVIEW USING SCREEN 0904.


*--Conflict proposed Mitigations
DATA: BEGIN OF gt_conpmit OCCURS 0.
        INCLUDE STRUCTURE /psyng/conpmit.
DATA:   comp_name(20) TYPE c,
        sel           TYPE /psyng/flagx,
        END OF gt_conpmit.
CONTROLS: tc_conpmit  TYPE TABLEVIEW USING SCREEN 0906.

* INTERNAL TABLE FOR Conflicts Display
DATA:     BEGIN OF conflict2  OCCURS 0.
DATA:     conid       TYPE /psyng/conflict-conid,
          description TYPE /psyng/conflict-description.
DATA:     END OF conflict2.

* TYPE FOR THE DATA OF TABLECONTROL 'FUNCT'
TYPES: BEGIN OF t_funct,
         function    LIKE /psyng/functtran-functionid,
         description LIKE /psyng/function-description,
       END OF t_funct.

* INTERNAL TABLE FOR TABLECONTROL 'FUNCT'
DATA:     BEGIN OF g_funct_itab OCCURS 0.
DATA:     function    LIKE /psyng/functtran-functionid,
          description LIKE /psyng/function-description,
          flag        TYPE /psyng/flagx.
DATA:     END OF g_funct_itab.

DATA:     g_funct_wa     TYPE t_funct. "work area

* DECLARATION OF TABLECONTROL 'FUNCT' ITSELF
CONTROLS: funct TYPE TABLEVIEW USING SCREEN 0202.

* TYPE FOR THE DATA OF TABLECONTROL 'ROLE_TRANS'
TYPES: BEGIN OF t_role_trans,
         tcode LIKE tstct-tcode,
         ttext LIKE tstct-ttext,
       END OF t_role_trans.

* DECLARATION OF TABLECONTROL 'ROLE_TRANS' ITSELF
CONTROLS: role_trans TYPE TABLEVIEW USING SCREEN 0302.


* INTERNAL TABLE FOR TABLECONTROL 'JOBTXN'
DATA:    BEGIN OF g_jobtxn_itab  OCCURS 0.
DATA:    tcode TYPE tstct-tcode,
         ttext TYPE tstct-ttext.
DATA:    END OF g_jobtxn_itab.

* INTERNAL TABLE FOR TABLECONTROL 'TRANS'
DATA: g_trans_itab TYPE TABLE OF t_trans WITH HEADER LINE,
      gt_trans_bckup TYPE TABLE OF t_trans WITH HEADER LINE. "HBHALLA

DATA: BEGIN OF gt_fiori_app OCCURS 0,
        fioriid TYPE /psyng/sw_fioria-fioriid,
        appname TYPE  /psyng/sw_fioria-appname,
        flag,       "flag for mark column
      END OF gt_fiori_app.
data: gs_fiori_wa like gt_fiori_app.
DATA:   BEGIN OF g_critrans,
          tcode   TYPE /psyng/critcodes-tcode,
          imp     TYPE /psyng/critcodes-imp,
          owner   TYPE /psyng/critcodes-owner,
          busarea TYPE /psyng/critcodes-busarea,
          sel     TYPE /psyng/flagx,
        END OF g_critrans.

DATA: gl_critrans LIKE g_critrans.
* INTERNAL TABLE FOR TABLECONTROL 'CRITROLE'
DATA:     BEGIN OF g_criroles_itab  OCCURS 0.
DATA:     agr_name TYPE agr_texts-agr_name,
          text     TYPE agr_texts-text,
          imp      TYPE /psyng/criroles-imp,
          owner    TYPE /psyng/criroles-owner,
*          description TYPE /psyng/criroles-description,
          flag.
DATA:     END OF g_criroles_itab.

DATA: gt_criroles_bckup LIKE TABLE OF g_criroles_itab
      WITH HEADER LINE. "HBHALLA

DATA: gl_critrole LIKE g_criroles_itab.
* INTERNAL TABLE FOR TABLECONTROL 'CRITPROF'
DATA:     BEGIN OF g_criprofs_itab  OCCURS 0.
DATA:     profn TYPE usr11-profn,
          ptext TYPE usr11-ptext,
          imp   TYPE /psyng/criprof-imp,
          owner TYPE /psyng/criprof-owner,
*          description TYPE /psyng/criprof-description,
          flag.
DATA:     END OF g_criprofs_itab.

DATA: gt_criprofs_bckup LIKE TABLE OF g_criprofs_itab
      WITH HEADER LINE. "HBHALLA

DATA: gl_criprofs LIKE g_criprofs_itab.

TYPES: BEGIN OF t_jobtxn,
         tcode LIKE tstct-tcode,
         ttext LIKE tstct-ttext,
       END OF t_jobtxn.

DATA:     g_jobtxn_wa     TYPE t_jobtxn. "work area

TYPES: BEGIN OF t_critrole,
         agr_name TYPE agr_texts-agr_name,
         text     TYPE agr_texts-text,
         imp      TYPE /psyng/criroles-imp,
         owner    TYPE /psyng/criroles-owner,
*          description TYPE /psyng/criroles-description,
         flag,       "flag for mark column
       END OF t_critrole.


TYPES: BEGIN OF t_critprof,
         profn TYPE usr11-profn,
         ptext TYPE usr11-ptext,
         imp   TYPE /psyng/criprof-imp,
         owner TYPE /psyng/criprof-owner,
*          description TYPE /psyng/criprof-description,
       END OF t_critprof.


DATA:     g_critprof_wa TYPE t_critprof. "workarea

DATA:     g_critrole_wa TYPE t_critrole. "workarea


DATA:     g_trans_wa     TYPE t_trans. "work area

DATA:     g_role_trans_wa     TYPE t_trans. "work area

DATA : g_transroleid(12).

DATA: headr(255).  "Header line for POP-UP
* INTERNAL TABLE TO CAPTURE TCODE DATA FOR POP-UP
DATA: BEGIN OF funtcodes OCCURS 10.
DATA:   tcodeline(255).
DATA: END OF funtcodes.

* DECLARATION OF TABLECONTROL 'TRANS' ITSELF
CONTROLS: critrans  TYPE TABLEVIEW USING SCREEN 0229,
          critran   TYPE TABLEVIEW USING SCREEN 0208,
          fioriapps TYPE TABLEVIEW USING SCREEN 0230.

* FUNCTION CODES FOR TABSTRIP 'YX_SECTAB'
CONSTANTS: BEGIN OF c_yx_sectab,
             tab1 LIKE sy-ucomm VALUE 'YX_SECTAB_FC1',
             tab2 LIKE sy-ucomm VALUE 'YX_SECTAB_FC2',
             tab3 LIKE sy-ucomm VALUE 'YX_SECTAB_FC3',
             tab4 LIKE sy-ucomm VALUE 'YX_SECTAB_FC4',
             tab5 LIKE sy-ucomm VALUE 'YX_SECTAB_FC5',
             tab6 LIKE sy-ucomm VALUE 'YX_SECTAB_FC6',
             tab7 LIKE sy-ucomm VALUE 'YX_SECTAB_FC7',
             tab8 LIKE sy-ucomm VALUE 'YX_SECTAB_FC8',
           END OF c_yx_sectab.
* DATA FOR TABSTRIP 'YX_SECTAB'
CONTROLS:  yx_sectab TYPE TABSTRIP.

DATA:      BEGIN OF g_yx_sectab,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE '/PSYNG/SECUWELL',
             pressed_tab LIKE sy-ucomm VALUE c_yx_sectab-tab1,
           END OF g_yx_sectab.

* DECLARATION OF TABLECONTROL 'JOBCONFLICT' ITSELF
CONTROLS: jobconflict TYPE TABLEVIEW USING SCREEN 0104.

* TYPE FOR THE DATA OF TABLECONTROL 'JOBTXN'

* DECLARATION OF TABLECONTROL 'JOBTXN' ITSELF
CONTROLS: jobtxn TYPE TABLEVIEW USING SCREEN 0104.

* F4 help
DATA: BEGIN OF gt_values OCCURS 0,
        line TYPE /psyng/desc,
      END OF gt_values.

DATA: gt_fields TYPE help_value OCCURS 0 WITH HEADER LINE,
      gl_mchdr  TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
      gl_trdirt TYPE trdirt.
DATA : gl_freq TYPE TABLE OF /psyng/sw_freq WITH HEADER LINE.
DATA : gl_freq1 TYPE TABLE OF /psyng/sw_freqt WITH HEADER LINE.
DATA: BEGIN OF gt_values_f OCCURS 0,
        line TYPE int2,
      END OF gt_values_f.

* DISPLAY / CHANGE TOGGLE
CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C',
           gc_select(1)  TYPE c VALUE 'X'.

* Flags
DATA: gf_dispchg(1)     TYPE c VALUE 'D',   "Change / Display mode
      gf_data_change(1) TYPE c,             "Screen data changed
      gf_answer(1)      TYPE c,             "Answer to popup question
      gf_edit           TYPE /psyng/bapiflagx,     "Currently editing
      gf_mcaud_chg      TYPE /psyng/bapiflagx,     "Mit auditor changed
      gf_val_mit_aud(1) TYPE c,          "Validate mit auditor
      gf_disp_pfcg      TYPE /psyng/bapiflagx,     "Disp tech role name
      g_nodsp           TYPE c,          "Edit auth obj change/display
      gf_data_create.                    " Create New Data


* Picture classes
DATA: gcl_pic_container TYPE REF TO cl_gui_custom_container,
      gcl_pic_control   TYPE REF TO cl_gui_picture.

DATA:  gt_exelog TYPE /psyng/exelog OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF rconfdet OCCURS 0,
        functionid LIKE /psyng/confdet-functionid,
        conid      LIKE /psyng/confdet-conid,
      END OF rconfdet.
DATA: iconflict TYPE STANDARD TABLE OF /psyng/conflict
      WITH HEADER LINE.

DATA: g_sw_vrsio(20)      TYPE c,
      g_sod_vrsio         TYPE /psyng/swsodvers-vrsio,
      g_sod_vrsio_desc    TYPE /psyng/swsodvers-vdesc,
      g_hometab           TYPE xuvalue,
      g_get_vrsio         TYPE /psyng/swsodvers-vrsio,
      g_set_default       TYPE /psyng/bapiflagx,
      g_prog_name         TYPE trdir-name,
      g_subrc             TYPE sy-subrc,
      g_call_scrn(4)      TYPE n,
      g_mit_vrsio_fld     TYPE flag,
      g_sw_custvrsio1     TYPE /psyng/swcusvers-text,
      g_sw_custvrsio2     TYPE /psyng/swcusvers-text,
      g_sw_custvrsio3     TYPE /psyng/swcusvers-text,
      g_config_value      TYPE /psyng/swconfig-value,
      g_profile           TYPE usprof-profile,
      gt_roles            TYPE TABLE OF /psyng/roles3 WITH HEADER LINE,
*      gf_excl_orgcheck(1) TYPE c,
*      gf_excl_sodvers(1)  TYPE c,
      g_dflt_con_ma_email TYPE /psyng/mcauditor-ma_email,
      g_dflt_mit_ma_email TYPE /psyng/mcauditor-ma_email,
      g_apr_same_usr_msg  TYPE /psyng/swconfig-value,
      g_aud_same_usr_msg  TYPE /psyng/swconfig-value.

DATA: BEGIN OF gt_func OCCURS 0,
        fcode LIKE rsmpe-func,
      END OF gt_func.

DATA: BEGIN OF gt_locked OCCURS 0,
        type(10)   TYPE c,
        object(20) TYPE c,
      END OF gt_locked.

*&spwizard: declaration of tablecontrol 'CRITROLE' itself
CONTROLS: critrole TYPE TABLEVIEW USING SCREEN 0210.
CONTROLS: critprof TYPE TABLEVIEW USING SCREEN 0213.



*DATA: gv_process TYPE /psyng/bus_proce-text.
DATA: gv_process TYPE /psyng/bus_proce-subarea.
DATA : btn_owner LIKE icons-text,
       btn_pmit  LIKE icons-text.

DATA : g_fullscreen   TYPE numc4,
       g_filtertext   TYPE string,
       g_filtertext_p TYPE string,
       g_filtertext_t TYPE string,
       g_mitfilter_au TYPE string,
       g_mitfilter_ug TYPE string,
       g_mitfilter_ar TYPE string,
       g_mitfilter_cu TYPE string,
       g_mitfilter_cr TYPE string.

*--Global Variables related to expanding and collapsing areas on
*  monitoring and misc tabs
*--Define the collapse/expand buttons globally
DATA :
*Monitoring Tab
  sodbutton  TYPE icon_text,
  critbutton TYPE icon_text,
  hisbutton  TYPE icon_text,
  mitbutton  TYPE icon_text,
  mostbutton TYPE icon_text,
  mgmbutton  TYPE icon_text,
  usrbutton  TYPE icon_text,
  docbutton  TYPE icon_text,
  arebutton  TYPE icon_text,
  stobutton  TYPE icon_text,
  strbutton  TYPE icon_text,

  mu_01      TYPE icon_text,
  mu_02      TYPE icon_text,
  mu_03      TYPE icon_text,
  mu_04      TYPE icon_text,
  mu_05      TYPE icon_text,
*Misc Tab
  conbutton  TYPE icon_text,
  corbutton  TYPE icon_text,
  repbutton  TYPE icon_text,
  verbutton  TYPE icon_text,
  diabutton  TYPE icon_text,
  rdcbutton  TYPE icon_text,
  setbutton  TYPE icon_text.
*--Type and table that will take care of showing/hiding areas
TYPES :
  BEGIN OF type_state,
    screen      TYPE scradnum,
    ucomm       LIKE sy-ucomm,
    button_name TYPE scrfname,
    group_name  TYPE scrfname,
    expanded    TYPE flag,
    button_text TYPE string,
  END OF type_state.
DATA : gt_states TYPE TABLE OF type_state WITH HEADER LINE.
*--Type and table with most used reports
TYPES :
  BEGIN OF type_report,
    report      LIKE sy-repid,
    uses        TYPE i,
    button_name TYPE scrfname, "button currently linked to this report
  END OF type_report.

*DATA : gt_reports TYPE TABLE OF type_report WITH HEADER LINE.
DATA : gt_buttons TYPE TABLE OF /psyng/sw_most_used_reports
WITH HEADER LINE.

DATA : url TYPE char255.

DATA: fld_list LIKE tc_conowner-cols.
DATA: col TYPE cxtab_column.
DATA: fldname(100),fldname2(100),fldname3(100).
DATA sort_type(20).

** SE 3.1 Critical object additional attributes
DATA : go_text_editor TYPE REF TO cl_gui_custom_container,
       go_text_edit   TYPE REF TO cl_gui_textedit,
       gt_editor_text TYPE TABLE OF /psyng/longtextfield,
       gf_is_modified TYPE i,
       gtitle(80)     TYPE c,
       gt_texts_ct    TYPE TABLE OF /psyng/texts WITH HEADER LINE,
       gt_texts_cr    TYPE TABLE OF /psyng/texts WITH HEADER LINE,
       gt_texts_cp    TYPE TABLE OF /psyng/texts WITH HEADER LINE.
DATA : gt_crit_trans TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
       gt_crit_roles TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
       gt_crit_profs TYPE TABLE OF /psyng/criprof WITH HEADER LINE.


** SE 3.1 Conflict repository Pop-up message changes
DATA : gt_func_pop TYPE TABLE OF /psyng/function WITH HEADER LINE.
DATA : gt_conf_pop TYPE TABLE OF /psyng/conflict WITH HEADER LINE.
DATA : gt_mith_pop TYPE TABLE OF /psyng/mchdr WITH HEADER LINE.
DATA : gt_caut_pop TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE.


*** SE 3.1 table control changes

DATA : g_curr_line TYPE i,
       g_tc_lines  TYPE sy-loopc. "HBHALLA: C1347


**   SE 3.1 Role tab changes
DATA : gt_hdrtxt  TYPE TABLE OF /psyng/texts WITH HEADER LINE,
       gt_desctxt TYPE TABLE OF /psyng/texts WITH HEADER LINE.

*--SE3.5 Sys_filter data dec

DEFINE add_column.
  gs_fieldcat-hotspot   = &1.
  gs_fieldcat-fieldname = &2.
  gs_fieldcat-seltext   = &3.
  gs_fieldcat-coltext   = &3.
  gs_fieldcat-intlen    = &5.
  gs_fieldcat-outputlen = &5.
  gs_fieldcat-fix_column = 'X'.
  gs_fieldcat-lzero = 'X'.
  if gf_dispchg1 =  gc_change.
    gs_fieldcat-edit = &6.
  endif.
  gs_fieldcat-emphasize = '0004'.
  gs_fieldcat-f4availabl = &7.
  gs_fieldcat-style      = &8.
  gs_fieldcat-checkbox   = &9.
  append gs_fieldcat to &4.
END-OF-DEFINITION.

*--- Field catalog table
DATA gt_fieldcat TYPE lvc_t_fcat .
FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.
*--- Layout structure
DATA: gs_layout      TYPE lvc_s_layo,
      gt_sort        TYPE lvc_t_sort,
      gs_fieldcat    TYPE lvc_s_fcat,
      gf_dispchg1(1) TYPE c.
DATA: gt_syscon     TYPE TABLE OF /psyng/sw_syscon WITH HEADER LINE,
      gt_sysfun     TYPE TABLE OF /psyng/sw_sysfun WITH HEADER LINE,
      gt_sysca      TYPE TABLE OF /psyng/sw_sysca WITH HEADER LINE,
      gt_systcd     TYPE TABLE OF /psyng/sw_systcd WITH HEADER LINE,
      gt_systcd_del TYPE TABLE OF /psyng/sw_systcd WITH HEADER LINE.

DATA : gr_alvgrid          TYPE REF TO cl_gui_alv_grid,
       gr_alvgrid_fun      TYPE REF TO cl_gui_alv_grid,
       gr_alvgrid_ca       TYPE REF TO cl_gui_alv_grid,
       gr_alvgrid_tcd      TYPE REF TO cl_gui_alv_grid,
       gr_alvgrid_audit    TYPE REF TO cl_gui_alv_grid,
       gr_ccontainer       TYPE REF TO cl_gui_custom_container,
       gr_ccontainer_fun   TYPE REF TO cl_gui_custom_container,
       gr_ccontainer_ca    TYPE REF TO cl_gui_custom_container,
       gr_ccontainer_tcd   TYPE REF TO cl_gui_custom_container,
       gr_ccontainer_audit TYPE REF TO cl_gui_custom_container.


*   screen fields name
DATA: g_busareatext       TYPE /psyng/busarea-text,
      g_app_text          TYPE /psyng/busarea-text,
      g_fun_description   TYPE /psyng/function-description,
      g_cricauth_text(60) TYPE c,
      g_imp               TYPE /psyng/critcodes-imp,
      wa_trans_itab       LIKE g_trans_itab.
*B8639.
RANGES gr_conid FOR /psyng/conflict-conid.
* END.

*4.0 Dev start
* FUNCTION CODES FOR TABSTRIP
CONSTANTS: BEGIN OF c_tc_md,
             tab1 LIKE sy-ucomm VALUE 'TAB1',
             tab2 LIKE sy-ucomm VALUE 'TAB2',
           END OF c_tc_md.

CONTROLS: tc_md    TYPE TABSTRIP,
          tc_fiori TYPE TABSTRIP.

DATA: BEGIN OF g_tc_md,
        subscreen   LIKE sy-dynnr,
        prog        LIKE sy-repid VALUE '/PSYNG/SECUWELL',
        pressed_tab LIKE sy-ucomm VALUE c_tc_md-tab1,
      END OF g_tc_md.

DATA: rev_text(40)   TYPE c,
      lang(2)        TYPE c,
      g_mit_ar_am    TYPE flag,
      g_mit_ar_ct    TYPE flag,
      g_mit_ar_ncct  TYPE flag,
      g_mit_just_req TYPE flag,
      g_mit_att_req  TYPE flag,
      gt_tline       TYPE TABLE OF tline WITH HEADER LINE.

DATA: gt_mcaudit TYPE TABLE OF /psyng/sw_mc_audit_overview
      WITH HEADER LINE.
DATA: g_mc_fltr_fcode   LIKE sy-ucomm,
      g_dynnr           LIKE sy-dynnr,
      gf_use_ta_history TYPE flag,
*BOC UMITTAL SE-CAC Integration 17/02/2026
      gv_se_cac     TYPE flag,
      gv_sod_dflt   TYPE /psyng/swsodvers-vrsio.
*EOC UMITTAL SE-CAC Integration 17/02/2026
*mitigation filter
RANGES: r_contid FOR /psyng/mcuser-contid,
             r_conid FOR /psyng/mcuser-conid,
             r_auditor   FOR /psyng/mcuser-auditor,
             r_userid FOR /psyng/mcuser-userid,
             r_vrsio  FOR /psyng/mcuser-vrsio,
             r_from_date FOR sy-datum,
             r_to_date FOR sy-datum,
             r_class FOR /psyng/mcusrgrp-class,
             r_swaudid FOR /psyng/mccauser-swaudid,
             r_agr_name FOR /psyng/mcrole-agr_name.
DATA: r_fcode TYPE RANGE OF rpy_dyfatc-push_fcode WITH HEADER LINE.

DATA: gt_ftc TYPE TABLE OF rpy_dyfatc.

*SE4.6
data: gs_assingment type /PSYNG/MITIGATION_ASSIGNMENT,
      g_exist type flag,
      g_current_user TYPE sy-uname. "C0700
