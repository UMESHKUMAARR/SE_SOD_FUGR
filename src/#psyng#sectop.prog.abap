FUNCTION-POOL /psyng/sectop NO STANDARD PAGE HEADING.
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECTOP
* AUTHOR                : Principal Synergy LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Principal Synergy LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*
TABLES  /psyng/mcuseraud.
* Includes
INCLUDE <ctldef>.
INCLUDE cnt4defs.
INCLUDE /PSYNG/SW_CONFIG.
DATA  l_value.
TYPE-POOLS: shlp.
CLASS /psyng/sw_cl_constants DEFINITION LOAD.
TABLES: /psyng/texts, /psyng/policy, /psyng/function,
  /psyng/functtran, tstct, /psyng/conflict, /psyng/confdet,
/psyng/rolehdr,
  /psyng/roletrans, /psyng/roleconf, /psyng/position, /psyng/posndet,
  /psyng/user, /psyng/usrdet,
  /psyng/sodobject,
  /psyng/history,
  /psyng/critcodes,
  /psyng/swaudc2,
  /psyng/swaudhdr,
  /psyng/swinvisbl,
  /psyng/swconfig,
  /psyng/conowner.
TABLES:  agr_texts.
TABLES:   /psyng/criroles, /psyng/criprof.
TABLES: rfcdes, agr_define.

DATA: screen_323.
DATA  eaobj_flag.
DATA: agr_tab LIKE agr_texts OCCURS 0 WITH HEADER LINE .
DATA: ivsble LIKE /psyng/swinvisbl OCCURS 0 WITH HEADER LINE .
DATA:  ok_code LIKE sy-ucomm.
DATA: ok_code1 LIKE sy-ucomm.
DATA: BEGIN OF s_text ,                                     "OCCURS 0,
*      text LIKE agr_texts-text,
      text LIKE /psyng/texts-text, "HBHALLA(PN-11459)
      END OF s_text.
DATA: BEGIN OF zi_text ,                                    "OCCURS 0,
      text(240), " LIKE agr_texts-text,
      END OF zi_text.
DATA  tcode LIKE tstct-tcode.
DATA: icon5(150) TYPE c.
DATA: icon2(150) TYPE c.
DATA: BEGIN OF p_role,
      roleid LIKE /psyng/rolehdr-roleid,
      END OF p_role.

DATA: itstct TYPE HASHED TABLE OF tstct
      WITH UNIQUE KEY sprsl tcode
      WITH HEADER LINE.
TYPES: BEGIN OF ift_typ,    "/psyng/functtran where tcode is in begining
         tcode TYPE sy-tcode,
         functionid LIKE /psyng/functtran-functionid,
       END OF ift_typ.
DATA: ift TYPE SORTED TABLE OF ift_typ WITH UNIQUE KEY tcode functionid
      WITH HEADER LINE.
DATA: ift_idx TYPE i.
DATA: crt_dte LIKE sy-datum, crt_tme LIKE sy-uzeit.
DATA: old_role LIKE /psyng/rolehdr.
DATA: old_position LIKE /psyng/position.
DATA: old_user LIKE /psyng/user.

DATA: BEGIN OF u_role,
      positionid LIKE /psyng/posndet-positionid,
      END OF u_role.
DATA  j_prole LIKE u_role OCCURS 0 WITH HEADER LINE.
DATA: mark_col TYPE c .
DATA  i_prole LIKE p_role OCCURS 0 WITH HEADER LINE.
DATA: count_line TYPE i.
DATA num(3) TYPE c.
DATA role_txt LIKE agr_texts-text.
DATA role_txt1 LIKE agr_texts-text.
DATA  i_text LIKE s_text OCCURS 0 WITH HEADER LINE.
DATA  z_text LIKE zi_text OCCURS 0 WITH HEADER LINE.
DATA: text_fill TYPE i.
DATA:  modified TYPE c VALUE '' .
DATA: user TYPE c VALUE space,  exist TYPE c VALUE '' .
DATA: first_time TYPE c VALUE space.
DATA: populated TYPE c VALUE space.
DATA: first_mit TYPE c VALUE space.
DATA: stext_reload1 TYPE char1.
DATA: first_sod TYPE c VALUE space.
DATA: first_txn1 TYPE c VALUE space.
DATA: first_role1 TYPE c VALUE space.
DATA: first_prof1 TYPE c VALUE space.
DATA: dell_all TYPE c VALUE space.
DATA function LIKE /psyng/function-function.
DATA userid LIKE /psyng/user-userid.
DATA conid LIKE /psyng/conflict-conid.
DATA positionid LIKE /psyng/position-positionid.
DATA: old_trans_current_line LIKE sy-tabix VALUE 0.
DATA: old_critroles_current_line LIKE sy-tabix VALUE 0.
DATA: old_critprofs_current_line LIKE sy-tabix VALUE 0.
DATA: old_funct_current_line LIKE sy-tabix VALUE 0.
DATA: old_sodobj_current_line LIKE sy-tabix VALUE 0.
DATA: conf_mit LIKE agr_texts-text.
DATA: usr_mit LIKE agr_texts-text.
DATA roleid LIKE /psyng/rolehdr-roleid.
DATA: old_n TYPE i, new_n TYPE i, n TYPE i, j TYPE i.
DATA funct1 LIKE /psyng/function-function.
DATA: mark_col1 TYPE c, mark_col2 TYPE c.
DATA  cursor_field(30) TYPE c .
DATA  cursor_line LIKE sy-loopc.
DATA: txn1 LIKE tstct-tcode, txn2 LIKE tstct-tcode.
DATA: sod_conflict TYPE c.
DATA: color(10) TYPE c .
DATA: icon_name(70) .
DATA: icon_text(30) TYPE c.
DATA: icon_info LIKE icont-quickinfo.
DATA: tot_lines(3) TYPE n.
DATA: messagetext(80).
DATA: popup_question(80).
DATA: popup_answer.

*Security related fields
DATA: sec_actvt(2).      "activity that user is performing
DATA: sec_actvt_tmp(2).  "activity that user is performing temporary
DATA: miss_auths.        "flag if user is missing authorizations
DATA: actvt_txt(11).     "activity text
DATA: act_create(2)   VALUE '01'.    "create activity
DATA: act_change(2)   VALUE '02'.    "change activity
DATA: act_display(2)  VALUE '03'.    "display activity
DATA: act_print(2)    VALUE '04'.    "print activity
DATA: act_delete(2)   VALUE '06'.    "delete activity
DATA: act_assign(2)   VALUE '22'.    "assign activity
DATA: act_download(2) VALUE 'DL'.    "download activity
DATA: act_upload(2)   VALUE 'UL'.    "upload activity
DATA: act_import(2)   VALUE '60'.    "import activity
DATA: act_export(2)   VALUE '60'.    "export activity

DATA  upd_flag.
DATA: itcodes TYPE STANDARD TABLE OF twbtcode WITH HEADER LINE.
DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE.
DATA: pertext(200).
DATA: userresponse.
DATA: irfcdes TYPE STANDARD TABLE OF rfcdes WITH HEADER LINE.
DATA: comment1 LIKE agr_texts-text,
      comment2 LIKE agr_texts-text,
      comment3 LIKE agr_texts-text,
      agr_desc LIKE agr_texts-text,
      today    LIKE sy-datum,
      c_today(10).

DATA: BEGIN OF itab OCCURS 0,
      functid LIKE /psyng/functtran-functionid,
      desc LIKE /psyng/function-description,
      busarea LIKE /psyng/function-busarea,
      owner LIKE /psyng/function-owner,
      text LIKE /psyng/texts-text,
      END OF itab.
DATA: BEGIN OF itab1 OCCURS 0,
      text LIKE /psyng/texts-text,
      END OF itab1.

DATA: c_e377 TYPE char4 VALUE 'e377'.
DATA: c_e378 TYPE char4 VALUE 'e378'.

DATA: g_memory_text TYPE TABLE OF char80.

DATA : g_upgrade_check_done TYPE flag.

DATA : g_value TYPE /psyng/param_value,
     gf_mit_asgn_auth_check type c.

** Changes for dashboard tab.
DATA : GV_MODULE_CHECK TYPE FLAG.
DATA : GV_PARAM_VALUE_CHECK TYPE FLAG.
data : gv_tab_flag type flag.
data : go_emp_status type ref to cl_gui_custom_container.
data : go_emp_status_html type ref to cl_gui_html_viewer.
data : go_emp_pie_conflicts type ref to cl_gui_custom_container.
data : go_pie_conflicts_html type ref to cl_gui_html_viewer.
data : gv_widget1_value(30) type c.
data : gv_widget2_value(30) type c.
**end of changes.
