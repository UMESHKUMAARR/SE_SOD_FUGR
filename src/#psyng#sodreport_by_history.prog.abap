*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SODREPORT_BY_HISTORY
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

REPORT /psyng/sodreport_by_history.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.
TYPE-POOLS: sapwl, slis.
data:
  BEGIN OF gt_functran occurs 0,
       funid TYPE /psyng/functtran-functionid,
       tcode TYPE /psyng/functtran-tcode,
       END OF gt_functran.

TABLES:  usr02 , rfcdes, /psyng/conflict.
DATA:et_output TYPE TABLE OF /psyng/bc_sod_output WITH HEADER LINE.
DATA: BEGIN OF gt_hitlist OCCURS 0.
        INCLUDE STRUCTURE /psyng/hitlist.
DATA:rfc LIKE rfcdes-rfcdest.
DATA: origin TYPE /psyng/conflict_origin.
DATA : END OF gt_hitlist.

DATA : gt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE,
gt_uinfo_temp TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE.
DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE.

DATA: BEGIN OF gt_usrstat OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_entry.
DATA:rfc LIKE rfcdes-rfcdest.
DATA: origin TYPE /psyng/conflict_origin.
DATA : END OF gt_usrstat.

DATA: BEGIN OF gt_output_details OCCURS 0.
        INCLUDE STRUCTURE /psyng/hitlist.
DATA:rfc LIKE rfcdes-rfcdest.
DATA: END OF gt_output_details.


DATA:BEGIN OF  gt_rfc OCCURS 0,
     rfcdest TYPE rfcdes-rfcdest,
     END OF gt_rfc.
TYPES:   BEGIN OF type_conf_func ,
          conid TYPE /psyng/conflict_id,
          funid TYPE /psyng/function_id,
          tcode LIKE sy-tcode,
          account LIKE sy-uname,
          rfcdest TYPE rfcdes-rfcdest,
          END OF type_conf_func.
DATA:gt_final_con TYPE TABLE OF type_conf_func WITH HEADER LINE.

DATA: lines TYPE i,
exit_proc,
g_usercount TYPE i,
g_dynnr TYPE sy-dynnr.


DATA: g_reject       TYPE /psyng/bapiflagx,
      g_dsp_mng_lock TYPE /psyng/swconfig-value,
      g_dsp_slf_lock TYPE /psyng/swconfig-value,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA : gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE .

TYPES: BEGIN OF userexe_typ,
         bname LIKE usr02-bname,
         tcode LIKE sy-tcode,
         rfc LIKE rfcdes-rfcdest,
         origin TYPE /psyng/conflict_origin,
       END OF userexe_typ.

DATA: BEGIN OF iusr02 OCCURS 0,
        class TYPE usr02-class,
        bname TYPE usr02-bname,
      END OF iusr02.
DATA:gf_job_active TYPE c.
DATA: wa_userexe TYPE userexe_typ.
DATA: userexe TYPE TABLE OF userexe_typ WITH HEADER LINE.
DATA: userexe_part TYPE TABLE OF userexe_typ WITH HEADER LINE.
DATA: userexe_cross TYPE TABLE OF userexe_typ WITH HEADER LINE,
      gt_usr_tcode TYPE  TABLE OF /psyng/bc_user_tcode
      WITH HEADER LINE,
      gt_tcode TYPE TABLE OF /psyng/bc_user_tcode WITH HEADER LINE.

DATA:BEGIN OF gt_usr OCCURS 0,
     account TYPE sy-uname,
     END OF gt_usr.

DATA: functtran TYPE STANDARD TABLE OF /psyng/sw_fundtl WITH HEADER LINE
.

DATA: confdet TYPE STANDARD TABLE OF /psyng/da_confdet WITH HEADER LINE.


DATA: conflict TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
      wa_conflict TYPE /psyng/conflict.

*Validate a user can perform all functions of conflict
DATA: BEGIN OF confs1 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs1.

DATA: BEGIN OF confs2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs2.

DATA: wa_itcd TYPE /psyng/psswtcd.
DATA: itcd TYPE SORTED TABLE OF /psyng/psswtcd WITH UNIQUE KEY
           tcode
           WITH HEADER LINE.
DATA : g_1mon_cal TYPE sy-datum,
      g_lmn_cal TYPE sy-datum.

TYPES: BEGIN OF userconf_typ,
         bname LIKE usr02-bname,
         class LIKE usr02-class,
         conid LIKE /psyng/confdet-conid,
         imp LIKE /psyng/conflict-imp,
         functionid LIKE /psyng/confdet-functionid,
         tcode LIKE sy-tcode,
         rfc LIKE rfcdes-rfcdest,
         origin LIKE /psyng/sw_output_org-origin,
         origint(12) TYPE c,
       END OF userconf_typ.

DATA: wa_userconf TYPE userconf_typ.
DATA: userconf1 TYPE STANDARD TABLE OF userconf_typ WITH HEADER LINE.
DATA: userconf2 TYPE STANDARD TABLE OF userconf_typ WITH HEADER LINE.
DATA : BEGIN OF userconf3 OCCURS 0,
        account LIKE usr02-bname,
        class LIKE usr02-class,
        conid LIKE /psyng/confdet-conid,
        context LIKE /psyng/conflict-description,
        imp LIKE /psyng/conflict-imp,
        risk       LIKE /psyng/conflict-risk,
        funid LIKE /psyng/confdet-functionid,
        funtext LIKE /psyng/function-description,
        tcode LIKE sy-tcode,
        ttext LIKE tstct-ttext,
        rfcdest LIKE rfcdes-rfcdest,
*        origin LIKE /psyng/sw_output_org-origin,
        origint(12) TYPE c,
        END OF userconf3.

DATA : gt_sod_dtl TYPE TABLE OF /psyng/bc_sod_output WITH HEADER LINE,
       gt_sod_dtl_part TYPE TABLE OF /psyng/bc_sod_output WITH HEADER
LINE.

DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
WITH HEADER LINE.

DATA: lt_hitlist LIKE STANDARD TABLE OF /psyng/hitlist
       WITH HEADER LINE.

DATA:
*user_stat TYPE STANDARD TABLE OF /psyng/sw_entry WITH HEADER LINE,
*ltusr_stat LIKE STANDARD TABLE OF /psyng/hitlist,
ltusr_stat_part LIKE STANDARD TABLE OF gt_usrstat WITH HEADER LINE,
*ltusr_stat_cross LIKE STANDARD TABLE OF gt_usrstat WITH HEADER LINE

*gt_hitlist TYPE TABLE OF /psyng/hitlist WITH HEADER LINE,
*lt_hitlist_tmp LIKE STANDARD TABLE OF gt_hitlist WITH HEADER LINE,
lt_hitlist_part LIKE STANDARD TABLE OF gt_hitlist WITH HEADER LINE.
*lt_hitlist_cross  LIKE STANDARD TABLE OF gt_hitlist WITH HEADER LINE.

DATA: BEGIN OF months OCCURS 0.
DATA:   month LIKE sy-datum.
DATA: END OF months.

DATA: 1stmonth TYPE sy-datum, lastmont TYPE sy-datum,
      tcode LIKE sy-tcode.


*--Global data for tcode origin details
DATA: BEGIN OF ls_tcode_role,
        bname LIKE /psyng/bc_uidn-bname,
*        name_text TYPE ad_namtext,
        tcode LIKE agr_tcodes-tcode,
        ttext LIKE tstct-ttext,
        agr_name LIKE agr_users-agr_name,
        profile  TYPE xuprofile,
      END OF ls_tcode_role.
CONSTANTS:se_def_job_txt TYPE btcjob VALUE 'SAP HISTORY CAPTURE JOB'.
DATA: gt_tcode_role LIKE STANDARD TABLE OF ls_tcode_role INITIAL SIZE 0
      WITH HEADER LINE.
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      y_layout TYPE slis_layout_alv,
      gt_sort TYPE slis_t_sortinfo_alv.

TYPES :  BEGIN OF typ_conflict,
          conid	TYPE /psyng/conflict_id,
          imp TYPE /psyng/conflict-imp,
          risk TYPE /psyng/conflict-risk,
          description TYPE  /psyng/rskdsc,
        END OF typ_conflict,
        BEGIN OF typ_function,
          function  TYPE /psyng/function_id,
          description TYPE 	/psyng/fundsc,
          END OF typ_function.

DATA:gt_conflict TYPE HASHED TABLE OF typ_conflict
     WITH UNIQUE KEY conid WITH HEADER LINE,
     gt_function TYPE HASHED TABLE OF typ_function
     WITH UNIQUE KEY function WITH HEADER LINE.
*****TEst data
DATA: g_begintime  TYPE /psyng/se16n_id,
      g_endtime    TYPE /psyng/se16n_id,
      g_tottime    TYPE /psyng/se16n_id.
******
*DATA: usertype TYPE /psyng/xuustyp.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
      g_current_user TYPE sy-uname. "C0700

SELECTION-SCREEN: BEGIN OF BLOCK prer WITH FRAME TITLE text-011.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-012.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-013.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-014.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 3(66) text-015.
SELECTION-SCREEN: COMMENT 3(70) text-015.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-016.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 2.
SELECTION-SCREEN: COMMENT 1(75) s_cmt MODIF ID cm1.
SELECTION-SCREEN:SKIP.
SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  1(30) text-026 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(30) text-027 USER-COMMAND sm37
MODIF ID sm.
SELECTION-SCREEN:END OF LINE.


SELECTION-SCREEN: END OF BLOCK prer .

SELECTION-SCREEN: BEGIN OF BLOCK prms WITH FRAME TITLE text-009.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-006.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: 1stmon(7).
SELECTION-SCREEN: COMMENT 28(30) text-005.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-007.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: lastmon(7).
SELECTION-SCREEN: COMMENT 28(30) text-005.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(65) ava_txt.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 2.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(75) text-017.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: END OF BLOCK prms .

SELECTION-SCREEN: BEGIN OF BLOCK usrs WITH FRAME TITLE text-008.
SELECT-OPTIONS: pbname FOR usr02-bname NO INTERVALS.
SELECT-OPTIONS: s_class FOR usr02-class.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

SELECTION-SCREEN: END OF BLOCK usrs .

*Version selection
SELECTION-SCREEN: BEGIN OF BLOCK blk0 WITH FRAME TITLE text-022.
PARAMETER : sodvrsio LIKE /psyng/conflict-vrsio DEFAULT '0'.
SELECTION-SCREEN: END OF BLOCK blk0 .
*version selection

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid,
                s_imp   FOR /psyng/conflict-imp,
                s_risk  FOR /psyng/conflict-risk,
                s_rfc FOR rfcdes-rfcdest MATCHCODE OBJECT
                                         /psyng/sw_rfcsh_coll.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(60) text-m01.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(60) text-m02.
SELECTION-SCREEN: END OF LINE.

PARAMETERS:remote AS CHECKBOX USER-COMMAND remo DEFAULT ' '.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) text-075.
SELECTION-SCREEN : POSITION 22.
PARAMETERS : p_local TYPE flag DEFAULT 'X'.
SELECTION-SCREEN COMMENT 24(10) text-072 FOR FIELD p_local.
SELECTION-SCREEN : POSITION 35.
PARAMETERS : p_remote TYPE flag USER-COMMAND rm DEFAULT ' '.
SELECTION-SCREEN COMMENT 37(10) text-073 FOR FIELD p_remote.
SELECTION-SCREEN : POSITION 49.
PARAMETERS : p_cross TYPE flag AS CHECKBOX USER-COMMAND cr DEFAULT ' '.
SELECTION-SCREEN COMMENT 51(20) text-074 FOR FIELD p_cross.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN END OF BLOCK blk1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

AT SELECTION-SCREEN OUTPUT.
  PERFORM check_job_status.

  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
        IF validusr = 'X'.
          exlckusr = 'X'.
          outvdate = 'X'.
          PERFORM set_def_usrtype.
          screen-input = 0.
          CLEAR p_flag.
        ELSE.
          PERFORM get_config_usr.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

  IF remote = 'X'.
    CLEAR : p_local.
*    p_remote = 'X'.
    LOOP AT SCREEN.
      CASE screen-name.
        WHEN 'P_LOCAL'.
          screen-input = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.
  ENDIF.

INITIALIZATION.
  PERFORM exelog.
  PERFORM initialization.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
AT SELECTION-SCREEN.
  PERFORM user_command.
  PERFORM at_selection_screen.


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
  IF exit_proc = 'Y'.
    EXIT.
  ENDIF.

  IF NOT s_rfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

  IF p_remote = 'X' OR p_cross = 'X'.
*    PERFORM get_rfc_destinations.
  ELSE.
    FREE gt_rfcdest.
  ENDIF.

  PERFORM on_scr_date_validation.
  PERFORM get_users.

  PERFORM get_history_data.
  PERFORM sod_analysis.

  gt_uinfo_temp[] = gt_uinfo[].
  SORT gt_uinfo_temp BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM gt_uinfo_temp
    COMPARING rfcdest bname.

  DESCRIBE TABLE gt_uinfo_temp LINES g_usercount.


  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s190(/psyng/sw).
  ELSE.
    IF userconf3[] IS INITIAL.
      MESSAGE s174(/psyng/sw).
      EXIT.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.

  PERFORM alv_output.

*&---------------------------------------------------------------------*
*&      Form  alv_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM alv_output.
  DATA: isort         TYPE STANDARD TABLE OF slis_sortinfo_alv,
        l_sort        TYPE slis_sortinfo_alv,
        alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant,
        program       LIKE sy-repid,
        begindate_c(10),
        enddate_c(10),
        l_pos TYPE i.


******macro to build sort table
  DEFINE sort_output.
    l_sort-spos = l_pos + 1.
    l_sort-fieldname = &1.
    l_sort-tabname = 'USERCONF3'.
    l_sort-up = 'X'.
    append l_sort to isort.
  END-OF-DEFINITION.
**************************************
  CONCATENATE sy-title text-023 sodvrsio
          INTO sy-title SEPARATED BY space.

  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

******Build sort table
  sort_output 'ACCOUNT'.
  sort_output 'CLASS'.
  sort_output 'CONID'.
  sort_output 'CONTEXT'.
  sort_output 'FUNID'.
  sort_output 'FUNTEXT'.
  sort_output 'TCODE'.
  sort_output 'TTEXT'.
  sort_output 'IMP'.
  sort_output 'RISK'.
  sort_output 'ORIGINT'.
**sort_output 'RFCDEST'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'USERCONF3'
            i_inclname         = program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  WRITE: 1stmonth TO begindate_c.
  WRITE: lastmont TO enddate_c.

*  enddate_c = sy-datum.

  CONCATENATE text-004 1stmon text-007 lastmon
              INTO alv_grid_titl SEPARATED BY space.

  PERFORM change_catalog_info.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title             = alv_grid_titl
            i_callback_top_of_page   = 'ALV_HEADER'
            i_callback_user_command  = 'HOTSPOT_CLICK'
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_program       = program
            it_sort                  = isort
            is_layout                = alv_layout
            it_fieldcat              = i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = userconf3
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " alv_output
*&---------------------------------------------------------------------*
*&      Form  initialization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM initialization.
  DATA: st_txt(10), ls_txt(10).
  DATA : l_value TYPE /psyng/param_value.

*Valid & Dialog Users only
  se_config_param 'DFLT_VALID_DIALOG' l_value.
  IF l_value = 'Y'.
    validusr = 'X'.
  ELSEIF l_value = 'N'.
    validusr = ' '.
  ENDIF.
  CLEAR l_value.



  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
       TABLES
            idirectory = idirectory.

  LOOP AT idirectory.
    IF 1stmonth IS INITIAL OR 1stmonth > idirectory-startdate.
      1stmonth = idirectory-startdate.
    ENDIF.
    IF lastmont < idirectory-startdate.
      lastmont = idirectory-startdate.
    ENDIF.
    months-month = idirectory-startdate.
    APPEND months.
  ENDLOOP.

  CONCATENATE 1stmonth+4(2) '/' 1stmonth(4) INTO 1stmon.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO lastmon.


  CONCATENATE 1stmonth+4(2) '/' 1stmonth(4) INTO st_txt.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO ls_txt.

  CONCATENATE text-010 st_txt text-007 ls_txt
              INTO ava_txt SEPARATED BY space.

ENDFORM.                    " initialization


*&---------------------------------------------------------------------*
*&      Form  change_catalog_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM change_catalog_info.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA:l_counter TYPE i.

  DEFINE rearrange_position.
    l_counter = l_counter + 1.
    wa_fieldcat_alv-col_pos = l_counter.
    modify i_fieldcat_alv from wa_fieldcat_alv
                      transporting col_pos
                     where fieldname = &1.
  END-OF-DEFINITION.

  l_counter = 5.
  rearrange_position 'ORIGINT'.
  rearrange_position 'RISK'.
  rearrange_position 'FUNID'.
  rearrange_position 'FUNTEXT'.
  rearrange_position 'TCODE'.
  rearrange_position 'TTEXT'.
  rearrange_position 'TCODE'.
  rearrange_position 'RFCDEST'.


  wa_fieldcat_alv-seltext_l = text-020.
  wa_fieldcat_alv-seltext_m = text-020.
  wa_fieldcat_alv-seltext_s = text-021.
  wa_fieldcat_alv-reptext_ddic = text-020.
  wa_fieldcat_alv-hotspot      = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.


  wa_fieldcat_alv-hotspot      = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'FUNID'.
  wa_fieldcat_alv-hotspot      = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CONID'.

  wa_fieldcat_alv-seltext_l = text-025.
  wa_fieldcat_alv-seltext_m = text-025.
  wa_fieldcat_alv-seltext_s = text-025.
  wa_fieldcat_alv-reptext_ddic = text-025.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
*                      hotspot
                   WHERE
                      fieldname = 'ORIGINT'.
ENDFORM.                    " change_catalog_info
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        count TYPE i,
        exetime(8) TYPE c,
        exedate TYPE char10,
         c_usercount(6) TYPE c,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c.
  .
  wa-typ = 'H'.
  wa-info = 'SOD Conflicts by History'(h04).
  APPEND wa TO header.

  wa-typ = 'A'.
  wa-info = 'Segregation of Duties Summary Report'(h01).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
                INTO exetime SEPARATED BY ':'.
  WRITE sy-datum TO exedate.
  CONCATENATE g_current_user"sy-uname C0700
  text-h05 exedate exetime INTO wa-info SEPARATED
BY space.
*  wa-info = l_date.
  APPEND wa TO header.

*Summary.
  wa-typ = 'S'.
  wa-key = 'Summary'(h05).
  c_usercount = g_usercount.
  CONCATENATE c_usercount text-h06 INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM HOTSPOT_CLICK                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM hotspot_click USING r_ucomm LIKE sy-ucomm
                                  is_selfield TYPE slis_selfield.
  DATA: functionid  TYPE slis_selfield-value,
        answer(1) TYPE c,
               l_sod          TYPE /psyng/swsodvers-vrsio,
         l_uname        LIKE sy-uname,
         l_parva        TYPE usr05-parva,
         g_dynnr        LIKE sy-dynnr,
         l_parva_exists like sy-subrc.
  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.

  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE userconf3 INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      PERFORM get_tcode_origin USING
      is_selfield-value
      userconf3-account
      userconf3-rfcdest.
      PERFORM fieldcat_drill_detail_tcode.
      PERFORM build_sort_detail_tcode.
      PERFORM drill_alv_detail_tcode.
    WHEN 'FUNID'.
      CHECK is_selfield-value <> space.
      l_uname = g_current_user."sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      l_parva_exists = sy-subrc.
      IF l_parva_exists = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion
        USING sodvrsio l_uname 0.
      SET PARAMETER ID '/PSYNG/FUN' FIELD is_selfield-value.
      g_dynnr = '0201'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
        PERFORM set_default_sodversion
          USING l_sod l_uname l_parva_exists.
   WHEN 'CONID'.
     CHECK is_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      l_parva_exists = sy-subrc.
      IF l_parva_exists = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname 0.
      SET PARAMETER ID '/PSYNG/CON' FIELD is_selfield-value.
      g_dynnr = '0202'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
      PERFORM set_default_sodversion
        USING l_sod l_uname l_parva_exists.
     EXIT.
    WHEN OTHERS.
*--No action

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_tcode_origin
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_tcode_origin USING i_tcode i_bname TYPE xubname
                                   i_rfc   TYPE rfcdes-rfcdest ."i_name.

  DATA : lt_output TYPE TABLE OF /psyng/sw_outputdet3 WITH HEADER LINE,
         l_rfcdest TYPE rfcdes-rfcdest,
         l_tcode TYPE sy-tcode.

  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
  REFRESH : lt_output, gt_tcode_role.
  l_tcode = i_tcode.

  IF i_rfc = l_rfcdest.
    CALL FUNCTION '/PSYNG/SW_GET_TCODE_ORIGIN'
         EXPORTING
              i_bname   = i_bname
              i_tcode   = l_tcode
         TABLES
              et_output = lt_output.
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

    CALL FUNCTION '/PSYNG/SW_GET_TCODE_ORIGIN'
    DESTINATION i_rfc
        EXPORTING
             i_bname   = i_bname
             i_tcode   = l_tcode
        TABLES
             et_output = lt_output
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2.   "#EC SAST_CI_GEN_CHECK
 IF sy-subrc <> 0.
    CASE sy-subrc.
       WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
       WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
       WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
     ENDCASE.
  ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025

*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ENDIF.

  LOOP AT lt_output.
    gt_tcode_role-bname     = i_bname.
    gt_tcode_role-tcode     = i_tcode.
    gt_tcode_role-ttext     = lt_output-description.
    gt_tcode_role-agr_name  = lt_output-agr_name.
    gt_tcode_role-profile = lt_output-profile.
    APPEND gt_tcode_role.
  ENDLOOP.

  SORT gt_tcode_role.
  DELETE ADJACENT DUPLICATES FROM gt_tcode_role.

ENDFORM.                    " get_tcode_origin
*&---------------------------------------------------------------------*
*&      Form  get_tcode_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_USRHIS_RPT  text
*      <--P_GT_USRHIS_RPT_TCODE_TEXT  text
*----------------------------------------------------------------------*
FORM get_tcode_text USING    i_tcode
                    CHANGING e_text.
  TYPES: BEGIN OF t_tran,
           tcode TYPE tstct-tcode,
           ttext TYPE tstct-ttext,
         END OF t_tran.

  DATA: ls_tran TYPE t_tran.

  STATICS: lt_tran TYPE HASHED TABLE OF t_tran WITH UNIQUE KEY tcode.


  CLEAR e_text.

  READ TABLE lt_tran INTO ls_tran WITH TABLE KEY tcode = i_tcode.
  IF sy-subrc = 0.
    e_text = ls_tran-ttext.
    EXIT.
  ENDIF.

  SELECT SINGLE ttext INTO ls_tran-ttext FROM tstct
                WHERE sprsl = sy-langu
                  AND tcode = i_tcode.
  IF sy-subrc = 0.
    e_text        = ls_tran-ttext.
    ls_tran-tcode = i_tcode.
    INSERT ls_tran INTO TABLE lt_tran.
  ENDIF.
ENDFORM.                    " get_tcode_text
*&---------------------------------------------------------------------*
*&      Form  fieldcat_drill_detail_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fieldcat_drill_detail_tcode.

  REFRESH gt_fieldcat[].
  DATA : ls_fieldcat TYPE slis_fieldcat_alv.
  ls_fieldcat-fieldname = 'BNAME'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'User ID'(d01).
  ls_fieldcat-col_pos = 1.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'TCODE'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Transaction'(d03).
  ls_fieldcat-col_pos = 2.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'TTEXT'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Transaction Text'(d04).
  ls_fieldcat-col_pos = 3.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'AGR_NAME'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Single Role Name'(d05).
  ls_fieldcat-col_pos = 4.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'PROFILE'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Profile'(d06).
  ls_fieldcat-col_pos = 5.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

ENDFORM.                    " fieldcat_drill_detail_tcode

*&---------------------------------------------------------------------*
*&      Form  build_sort_detail_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_detail_tcode.
  FREE : gt_sort.
  DATA: ls_sort TYPE slis_sortinfo_alv.

ENDFORM.                    " build_sort_detail_tcode

*&---------------------------------------------------------------------*
*&      Form  drill_alv_detail_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM drill_alv_detail_tcode.
  DATA: l_program  LIKE sy-repid,
        ls_variant TYPE disvariant.


  l_program = sy-repid.

  y_layout-zebra = 'X'.
  y_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = l_program
            is_layout          = y_layout
            it_fieldcat        = gt_fieldcat
            it_sort            = gt_sort
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = gt_tcode_role[]
       EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " drill_alv_detail_tcode

*&---------------------------------------------------------------------*
*&      Form  on_scr_date_validation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM on_scr_date_validation.

  DATA:  l_val_sdate TYPE dats,
         l_val_edate TYPE dats,
         l_sdate TYPE dats,
         l_edate TYPE dats,
         l_message(220) TYPE c.



  l_val_sdate = 1stmonth.
  l_val_edate = sy-datum.
  CONCATENATE 1stmon+3(4) 1stmon(2) '01' INTO l_sdate.
  CONCATENATE lastmon+3(4) lastmon(2) '01' INTO l_edate.


  PERFORM validate_date USING l_sdate
                              l_edate
                              l_val_sdate
                              l_val_edate
                     CHANGING l_message.
  IF l_message IS INITIAL.
    lastmont = l_edate.
    1stmonth = l_sdate.
  ELSE.

    SET CURSOR FIELD 1stmon.

    MESSAGE s002(/psyng/sw) WITH l_message.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.                    " on_scr_date_validation


*---------------------------------------------------------------------*
*       FORM validate_date                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM validate_date USING p_sdate
                         p_edate
                         p_val_sdate
                         p_val_edate
                     CHANGING l_message.

  DATA: l_from_date LIKE sy-datum,
        l_to_date LIKE sy-datum,
        l_date LIKE l_to_date.

  CLEAR l_message.
  l_from_date = p_sdate.
  l_to_date = p_edate.

  IF NOT p_sdate IS INITIAL.
    l_date = l_from_date.
    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
         EXPORTING
              date                      = l_date
         EXCEPTIONS
              plausibility_check_failed = 1
              OTHERS                    = 2.
    IF sy-subrc <> 0.
      CONCATENATE text-ed1 text-d07 INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE text-d07 text-p04 INTO l_message SEPARATED BY space.
    EXIT.
  ENDIF.

  IF NOT p_edate IS INITIAL.

    l_date = l_to_date.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
         EXPORTING
              date                      = l_date
         EXCEPTIONS
              plausibility_check_failed = 1
              OTHERS                    = 2.
    IF sy-subrc <> 0.
      CONCATENATE text-ed1 text-d08 INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE text-d08 text-p04 INTO l_message SEPARATED BY space.
    EXIT.
  ENDIF.

  IF l_to_date < l_from_date.
    l_message = 'From date cannot be greater than end date'(p05).
    EXIT.
  ENDIF.

  IF l_from_date < p_val_sdate OR l_from_date > p_val_edate.
    l_message = 'From date is out of availabe history range'(p06).
    EXIT.
  ENDIF.

  IF l_to_date < p_val_sdate OR l_to_date > p_val_edate.
    l_message = 'To date is out of availabe history range'(p07).
    EXIT.
  ENDIF.



ENDFORM.                    " validate_date

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data.



ENDFORM.                    " get_data
*&---------------------------------------------------------------------*
*&      Form  get_rfc_destinations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_rfc_destinations.

  DATA : l_rfcdest TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c,
         l_local_sys TYPE rfcdest.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

*--Get sysid and mandt into field RFCOPTIONS
  LOOP AT gt_rfcdest ASSIGNING <rfcdes>.
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
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e03
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e03
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

*--Delete any RFC pointing to the local system.
  SORT gt_rfcdest BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM gt_rfcdest COMPARING rfcoptions.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  gt_rfcdest WHERE rfcoptions = l_local_sys
AND rfcdest <> 'LOCAL'.


ENDFORM.                    " get_rfc_destinations
*&---------------------------------------------------------------------*
*&      Form  sod_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sod_analysis.
  MESSAGE s398(00) WITH 'Begin of SOD analysis'.
  PERFORM con_analysis.
  MESSAGE s398(00) WITH 'End of SOD analysis'.
  PERFORM build_output.

ENDFORM.                    " sod_analysis
*&---------------------------------------------------------------------*
*&      Form  at_selection_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM at_selection_screen.

  IF sy-ucomm = 'REMO'.
    IF remote = 'X'.
      CLEAR : p_local.
*      p_remote = 'X'.
      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'P_LOCAL'.
            screen-input = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.
*      p_remote = 'X'.
      IF s_rfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(184).
      ENDIF.
    ELSE.
      p_local = 'X'.
      CLEAR p_remote.
      CLEAR p_cross.
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'RM'.
    IF p_remote = 'X'.
      IF s_rfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(184).
      ENDIF.
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'CR'.
    IF p_cross = 'X'.
      IF s_rfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for Cross analysis'(183).
      ENDIF.
    ENDIF.
  ENDIF.



  IF remote = 'X' OR p_remote = 'X' OR p_cross = 'X'.
    IF s_rfc[] IS INITIAL.
      MESSAGE w140(/psyng/sw) WITH
    'Please enter RFC destinations for remote analysis'(184).
    ENDIF.
  ENDIF.
ENDFORM.                    " at_selection_screen
*&---------------------------------------------------------------------*
*&      Form  get_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users.
  TYPES: BEGIN OF typ_usr_auth,
         class TYPE usr02-class,
         company TYPE uscompany-company,
    hasaccess TYPE c,
       END OF typ_usr_auth.
  DATA: lt_usr_auth TYPE HASHED TABLE OF  typ_usr_auth
  WITH UNIQUE KEY class company WITH HEADER LINE,
  i_include_locked TYPE flag,
   i_include_expire TYPE flag..

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_USER_INFO_NEW'
       EXPORTING
            i_validuser   = validusr
            i_exlckusr    = exlckusr
            i_outvdate    = outvdate
            i_remote_only = remote
       TABLES
            it_users      = pbname
            it_usergroup  = s_class
            it_usertype   = usrtype
            it_user_rfc   = s_rfc
            et_uinfo      = lt_uinfo.

  SORT lt_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.


  LOOP AT lt_uinfo.
    READ TABLE lt_usr_auth WITH TABLE KEY class = lt_uinfo-class
                                          company = lt_uinfo-company
                                          TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      IF NOT lt_uinfo-class IS INITIAL AND
         NOT lt_uinfo-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO'  FIELD sodvrsio
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSEIF NOT lt_uinfo-class IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO'  FIELD sodvrsio
             ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSEIF NOT lt_uinfo-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO'  FIELD sodvrsio
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSEIF  lt_uinfo-class IS INITIAL AND
              lt_uinfo-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
            ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
            ID 'Y&SW_VRSIO'  FIELD sodvrsio
            ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ENDIF.

**
      IF sy-subrc <> 0.
        lt_usr_auth-class = lt_uinfo-class.
        lt_usr_auth-company = lt_uinfo-company.
        lt_usr_auth-hasaccess = ''.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        gf_missing_auth_ugroup = 'X'.
        DELETE lt_uinfo.
        INSERT TABLE lt_usr_auth.
      ELSE.
        lt_usr_auth-class = lt_uinfo-class.
        lt_usr_auth-company = lt_uinfo-company.
        lt_usr_auth-hasaccess = 'X'.
        INSERT TABLE lt_usr_auth.
      ENDIF.
    ELSE.
      IF lt_usr_auth-hasaccess = ''.
        DELETE lt_uinfo.
      ENDIF.
    ENDIF.
  ENDLOOP.

  gt_uinfo[] = lt_uinfo[].

ENDFORM.                    " get_users
*&---------------------------------------------------------------------*
*&      Form  GET_HISTORY_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_history_data.

  DATA:l_account TYPE sy-uname,
       l_tcode TYPE tstc-tcode,
       l_rfc TYPE rfcdes-rfcdest,
       l_system_msg(80),
       lt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
       l_sys TYPE string.

  DATA l_local_sys TYPE rfcdes-rfcdest.

  CHECK NOT gt_uinfo[] IS INITIAL.

  IF p_local = ' ' AND p_remote = ' ' AND p_cross = ' '.
    p_local = 'X'.
  ENDIF.

  CONCATENATE 1stmon+3(4) 1stmon(2) '01' INTO 1stmonth.
  CONCATENATE lastmon+3(4) lastmon(2) '01' INTO lastmont.

* add local system to list of rfc destinations
  IF remote NE 'X'.
    CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
    gt_rfcdest-rfcoptions = l_local_sys.
    gt_rfcdest-rfcdest = 'LOCAL'.
    APPEND gt_rfcdest.
  ENDIF.
  SORT gt_rfcdest.
*--Summary statistics are only available on a per system basis
*  Not client specific.  We don't analyze more than 1 client per system.
  lt_rfcdest[] = gt_rfcdest[].
  LOOP AT gt_rfcdest.
    CONCATENATE
      gt_rfcdest-rfcoptions(3)
      '*' INTO l_sys.
    DELETE gt_rfcdest WHERE rfcoptions CP l_sys AND NOT
                            rfcdest    = gt_rfcdest-rfcdest.
  ENDLOOP.
  IF NOT lt_rfcdest[] = gt_rfcdest[].
*--At least one rfc destination was deleted.
    MESSAGE i002(/psyng/sw) WITH
    'Report will only report on a system level.'(m01)
    'Maximum 1 client per system allowed.'(m02).
*   & & & &

  ENDIF.


  LOOP AT gt_rfcdest.

    IF gt_rfcdest-rfcdest = 'LOCAL'.

      LOOP AT months.
        CHECK months-month GE 1stmonth AND months-month LE lastmont.

        CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
             EXPORTING
                  startdate = months-month
             TABLES
                  user_stat = ltusr_stat_part
                  hitlist   = lt_hitlist_part.

        LOOP AT ltusr_stat_part WHERE entry_id+72(1) = 'T'.  "tcode
*          CHECK ltusr_stat_part-account IN pbname.
          READ TABLE gt_uinfo WITH KEY rfcdest = gt_rfcdest-rfcoptions
                                      bname   = ltusr_stat_part-account.
          CHECK sy-subrc = 0.
          tcode = ltusr_stat_part-entry_id(20).
          CONDENSE tcode NO-GAPS.
          l_account = ltusr_stat_part-account.
          l_tcode = tcode.
          l_rfc = gt_rfcdest-rfcoptions.
          PERFORM collect_stats USING l_account l_tcode l_rfc.

        ENDLOOP.

        REFRESH: ltusr_stat_part.
        CLEAR: ltusr_stat_part.

        LOOP AT lt_hitlist_part WHERE tcode <> space.
          READ TABLE gt_uinfo WITH KEY rfcdest = gt_rfcdest-rfcoptions
                               bname   = lt_hitlist_part-account.
          CHECK sy-subrc = 0.
          l_account = lt_hitlist_part-account.
          l_tcode = lt_hitlist_part-tcode.
          l_rfc = gt_rfcdest-rfcoptions.
          PERFORM collect_stats USING l_account l_tcode l_rfc.

        ENDLOOP.
        REFRESH: lt_hitlist_part.
        CLEAR: lt_hitlist_part.
      ENDLOOP.   "months
    ELSE.
      LOOP AT months.
        CHECK months-month GE 1stmonth AND months-month LE lastmont.
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

        CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
        DESTINATION gt_rfcdest-rfcdest
                EXPORTING
                     startdate = months-month
                TABLES
                     user_stat = ltusr_stat_part
                     hitlist   = lt_hitlist_part
             EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3.  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e03
              gt_rfcdest-rfcdest
              l_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e03
              gt_rfcdest-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.

        LOOP AT ltusr_stat_part WHERE entry_id+72(1) = 'T'.  "tcode
          READ TABLE gt_uinfo WITH KEY rfcdest = gt_rfcdest-rfcoptions
                                      bname   = ltusr_stat_part-account.
          CHECK sy-subrc = 0.
          tcode = ltusr_stat_part-entry_id(20).
          CONDENSE tcode NO-GAPS.
          l_account = ltusr_stat_part-account.
          l_tcode = tcode.
          l_rfc = gt_rfcdest-rfcoptions.
          PERFORM collect_stats USING l_account l_tcode l_rfc.

        ENDLOOP.

        REFRESH: ltusr_stat_part.
        CLEAR: ltusr_stat_part.

        LOOP AT lt_hitlist_part WHERE tcode   <> space.

          READ TABLE gt_uinfo WITH KEY rfcdest = gt_rfcdest-rfcoptions
                                bname   = lt_hitlist_part-account.
          CHECK sy-subrc = 0.
          l_account = lt_hitlist_part-account.
          l_tcode = lt_hitlist_part-tcode.
          l_rfc = gt_rfcdest-rfcoptions.
          PERFORM collect_stats USING l_account l_tcode l_rfc.

        ENDLOOP.
        REFRESH: lt_hitlist_part.
        CLEAR: lt_hitlist_part.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " GET_HISTORY_DATA
*&---------------------------------------------------------------------*
*&      Form  con_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM con_analysis.

  DATA:BEGIN OF lt_functran OCCURS 0,
       funid TYPE /psyng/functtran-functionid,
       tcode TYPE /psyng/functtran-tcode,
       END OF lt_functran.
  DATA:lt_unique_fun LIKE TABLE OF lt_functran WITH HEADER LINE.

  DATA : lt_conflict TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
         lt_faobj    TYPE TABLE oF /psyng/faobj2.

  DATA: BEGIN OF lt_condtl OCCURS 0,
             conid TYPE /psyng/confdet-conid,
             funid TYPE /psyng/confdet-functionid,
             END OF lt_condtl.
  DATA:  lt_conf_func TYPE TABLE OF type_conf_func WITH HEADER LINE.

  DATA:local TYPE rfcdes-rfcdest,
       l_rfc LIKE local,
       l_user TYPE sy-uname,
       l_conid TYPE /psyng/confdet-conid,
       l_index TYPE i.

  GET RUN TIME FIELD g_begintime.

  SELECT functionid as funid tcode
  FROM /psyng/functtran INTO corresponding fields of TABLE lt_functran
  WHERE  vrsio = sodvrsio.

  SELECT *
  FROM /psyng/faobj2 INTO TABLE lt_faobj
  WHERE  vrsio  = sodvrsio  and
         object = 'S_TCODE' and
         field  = 'TCD'     and
         VAL_TO = ''.

*--Get the tcodes from the object details
  gt_functran[] = lt_functran[].
  perform get_tcodes_from_objects
    tables
      lT_FAOBJ.
  lt_functran[] = gt_functran[].
  free :   gt_functran[].


  SELECT a~conid b~functionid INTO TABLE lt_condtl
  FROM /psyng/conflict AS a INNER JOIN /psyng/confdet AS b
  ON a~conid = b~conid
  WHERE a~conid IN s_conid
  AND a~imp IN s_imp
  AND a~risk IN s_risk
  AND a~vrsio EQ sodvrsio
  AND b~vrsio EQ sodvrsio.

  DESCRIBE TABLE gt_usr.
  MESSAGE s398(00) WITH 'Users to be analysed' sy-tfill.

  DATA:lt_conf_tmp LIKE sorted TABLE OF lt_conf_func
        WITH UNIQUE KEY account conid funid rfcdest tcode
        WITH HEADER LINE.

  delete lt_functran where tcode cp '/PSYNG/-*'.
  LOOP AT gt_usr.
    LOOP AT gt_rfcdest.
      LOOP AT gt_uinfo WHERE bname = gt_usr-account
                         AND rfcdest = gt_rfcdest-rfcoptions.
        l_user = gt_usr-account.
        LOOP AT gt_usr_tcode WHERE account EQ l_user
                               AND rfcdest = gt_uinfo-rfcdest.
          LOOP AT lt_functran
          WHERE tcode EQ gt_usr_tcode-tcode.
            LOOP AT lt_condtl WHERE
            funid = lt_functran-funid.
              l_conid = lt_condtl-conid.
              LOOP AT lt_condtl WHERE
              conid = l_conid.
                lt_conf_tmp-conid = lt_condtl-conid.
                lt_conf_tmp-funid = lt_condtl-funid.
                IF lt_condtl-funid EQ lt_functran-funid.
                  lt_conf_tmp-tcode = lt_functran-tcode.
                  lt_conf_tmp-account = gt_usr-account.
                  lt_conf_tmp-rfcdest = gt_usr_tcode-rfcdest.
                ELSE.
                  lt_conf_tmp-tcode = ' '.
                  lt_conf_tmp-account = ' '.
                  lt_conf_tmp-rfcdest = ' '.
                ENDIF.
*                COLLECT lt_conf_tmp.
                 insert table lt_conf_tmp.
              ENDLOOP.
            ENDLOOP.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.

      LOOP AT lt_conf_tmp WHERE rfcdest EQ space.
        l_index = sy-tabix.
        READ TABLE lt_conf_tmp WITH KEY conid = lt_conf_tmp-conid
                                        funid = lt_conf_tmp-funid
                                        account = l_user
                                        TRANSPORTING NO FIELDS.
        IF sy-subrc EQ 0.
          DELETE lt_conf_tmp INDEX l_index.
        ELSE.
          read table lt_functran with key funid = lt_conf_tmp-funid
          transporting no fields.
          if sy-subrc = 0.
            DELETE lt_conf_tmp WHERE conid EQ lt_conf_tmp-conid.
          else.
*--There are no tcodes in this function, so don't delete it
          endif.
        ENDIF.
      ENDLOOP.
      APPEND LINES OF lt_conf_tmp TO gt_final_con.
      FREE lt_conf_tmp.
    ENDLOOP.
  ENDLOOP.

  GET RUN TIME FIELD g_endtime.
  g_tottime = ( g_endtime - g_begintime ) / 1000000.
  MESSAGE s398(00) WITH 'Runtime :' g_tottime.
  IF gf_missing_auth_ugroup = space.
    MESSAGE s398(00) WITH text-003.
  ELSE.
    MESSAGE s398(00) WITH text-003 text-018.
  ENDIF.

ENDFORM.                    " con_analysis
*&---------------------------------------------------------------------*
*&      Form  build_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_output.

  DATA:local TYPE rfcdes-rfcdest,
       l_rfc LIKE local,
       l_account TYPE sy-uname,
       l_conid LIKE gt_final_con-conid,
       lf_rfc_change.
  CONCATENATE sy-sysid sy-mandt INTO local.
  CHECK NOT gt_final_con[] IS INITIAL.

  LOOP AT gt_final_con.
    CLEAR lf_rfc_change.
    l_rfc = gt_final_con-rfcdest.
    l_account = gt_final_con-account.
    l_conid = gt_final_con-conid.
    CLEAR userconf3.

    LOOP AT gt_final_con WHERE conid EQ l_conid
    AND account EQ l_account.
      IF gt_final_con-rfcdest NE l_rfc.
        lf_rfc_change = 'X'.
        MOVE-CORRESPONDING gt_final_con TO userconf3.
        APPEND userconf3.
      ELSE.
        MOVE-CORRESPONDING gt_final_con TO userconf3.
        APPEND userconf3.
      ENDIF.
      CLEAR userconf3.
      DELETE gt_final_con.
    ENDLOOP.

    IF lf_rfc_change EQ 'X'.
      userconf3-origint = 'CROSS'.
      MODIFY userconf3
         TRANSPORTING origint
         WHERE account EQ l_account AND conid EQ l_conid.
    ENDIF.

  ENDLOOP.

  FIELD-SYMBOLS:<conf> LIKE LINE OF userconf3.
*  MESSAGE s398(00) WITH 'Filling Texts Begins'.
  LOOP AT userconf3 ASSIGNING <conf>.
    IF <conf>-origint EQ space.
      IF <conf>-rfcdest EQ local.
        <conf>-origint = 'LOCAL'.
      ELSE.
        <conf>-origint = 'REMOTE'.
      ENDIF.
    ENDIF.
*        Add Tcode Text
    PERFORM get_tcode_text USING <conf>-tcode
    CHANGING <conf>-ttext.
*        Add Conflict Text
    PERFORM get_con_text USING <conf>-conid
    CHANGING <conf>-imp
             <conf>-risk
             <conf>-context.
*        Add Function Text
    PERFORM get_fun_text USING <conf>-funid
    CHANGING <conf>-funtext.
*        Add Class
    PERFORM get_usr_class USING <conf>-account
    CHANGING <conf>-class.
  ENDLOOP.
  IF p_local = ' ' OR remote EQ 'X'.
    DELETE userconf3 WHERE origint EQ 'LOCAL'.
  ENDIF.

  IF p_remote = ' '.
    DELETE userconf3 WHERE origint EQ 'REMOTE'.
  ENDIF.

  IF p_cross = ' '.
    DELETE userconf3 WHERE origint EQ 'CROSS'.
  ENDIF.

ENDFORM.                    " build_output
*&---------------------------------------------------------------------*
*&      Form  get_con_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<CONF>_CONID  text
*      <--P_<CONF>_CONTEXT  text
*----------------------------------------------------------------------*
FORM get_con_text USING    p_conid
                  CHANGING p_imp p_risk p_context.

  READ TABLE gt_conflict WITH TABLE KEY conid = p_conid
  TRANSPORTING imp risk description.
  IF sy-subrc EQ 0.
    p_context = gt_conflict-description.
    p_imp = gt_conflict-imp.
    p_risk = gt_conflict-risk.
  ELSE.
    SELECT SINGLE conid imp risk description FROM /psyng/conflict
    INTO gt_conflict
    WHERE conid EQ p_conid AND
          vrsio = sodvrsio.
    CHECK sy-subrc EQ 0.
    p_imp = gt_conflict-imp.
    p_risk = gt_conflict-risk.
    p_context = gt_conflict-description.
    INSERT  gt_conflict INTO TABLE gt_conflict.
  ENDIF.

ENDFORM.                    " get_con_text
*&---------------------------------------------------------------------*
*&      Form  get_fun_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<CONF>_FUNID  text
*      <--P_<CONF>_FUNTEXT  text
*----------------------------------------------------------------------*
FORM get_fun_text USING    p_functionid
                  CHANGING p_fun_text.
  READ TABLE gt_function WITH TABLE KEY function = p_functionid
  TRANSPORTING description.
  IF sy-subrc EQ 0.
    p_fun_text = gt_function-description.
  ELSE.
    SELECT SINGLE function description FROM /psyng/function
    INTO gt_function
    WHERE function EQ p_functionid AND
          vrsio = sodvrsio.
    CHECK sy-subrc EQ 0.
    p_fun_text = gt_function-description.
    INSERT  gt_function INTO TABLE gt_function.
  ENDIF.
ENDFORM.                    " get_fun_text
*&---------------------------------------------------------------------*
*&      Form  get_usr_class
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<CONF>_BNAME  text
*      <--P_<CONF>_CLASS  text
*----------------------------------------------------------------------*
FORM get_usr_class USING    p_bname
                   CHANGING p_class.
  READ TABLE gt_uinfo WITH KEY bname = p_bname
  TRANSPORTING class.
  CHECK sy-subrc EQ 0.
  p_class = gt_uinfo-class.

ENDFORM.                    " get_usr_class
*&---------------------------------------------------------------------*
*&      Form  collect_stats
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_ACCOUNT  text
*      -->P_L_TCODE  text
*      -->P_L_RFC  text
*----------------------------------------------------------------------*
FORM collect_stats USING    p_account
                            p_tcode
                            p_rfc.
  gt_usr-account = p_account.
  gt_usr_tcode-account = p_account.
  gt_usr_tcode-tcode = p_tcode.
  gt_usr_tcode-rfcdest = p_rfc.
  COLLECT gt_usr_tcode.
  COLLECT gt_usr.

ENDFORM.                    " collect_stats

*&---------------------------------------------------------------------*
*&      Form  f4_usrtype
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USRTYPE_LOW  text
*----------------------------------------------------------------------*
FORM f4_usrtype CHANGING p_usrtype_low.
  DATA: BEGIN OF ls_data,
               value TYPE domvalue_l,
               dtext TYPE val_text,
             END OF ls_data,
             lt_data   LIKE TABLE OF ls_data,
             lth_return TYPE TABLE OF ddshretval,
             wah_return LIKE LINE OF lth_return.

  SELECT a~domvalue_l AS value b~ddtext AS dtext "#EC CI_NOORDER
    INTO CORRESPONDING FIELDS OF TABLE lt_data
    FROM dd07l AS a INNER JOIN dd07t AS b
    ON a~domname = b~domname
    AND a~as4local = b~as4local
    AND a~valpos = b~valpos
    AND a~as4vers = b~as4vers
    WHERE a~domname = '/PSYNG/XUUSTYP'
    AND b~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK

  IF   lt_data[] IS INITIAL.
*--Fallback to English
    SELECT a~domvalue_l AS value b~ddtext AS dtext "#EC CI_NOORDER
      INTO CORRESPONDING FIELDS OF TABLE lt_data
      FROM dd07l AS a INNER JOIN dd07t AS b
      ON a~domname = b~domname
      AND a~as4local = b~as4local
      AND a~valpos = b~valpos
      AND a~as4vers = b~as4vers
      WHERE a~domname = '/PSYNG/XUUSTYP'
      AND b~ddlanguage = 'EN'."#EC SAST_CI_GEN_CHECK
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'VALUE'
            value_org       = 'S'
            window_title    = 'Title'
       TABLES
            value_tab       = lt_data
            return_tab      = lth_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.

  READ TABLE lth_return INTO wah_return INDEX 1.
  IF sy-subrc = 0.
    p_usrtype_low = wah_return-fieldval.
  ENDIF.

ENDFORM.                    " f4_usrtype
*&---------------------------------------------------------------------*
*&      Form  check_job_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_job_status.
  DATA:se_job_txt_msg(77) TYPE c.
  PERFORM get_job_name USING
                             se_def_job_txt
                       CHANGING se_job_txt_msg.

  s_cmt = se_job_txt_msg.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'CM1'.
        screen-intensified = '1'.
        MODIFY SCREEN.
      WHEN 'BGD'.
        IF gf_job_active EQ 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'OUT'.
        screen-active = 0.
        MODIFY SCREEN.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.

ENDFORM.                    " check_job_status
*&---------------------------------------------------------------------*
*&      Form  get_job_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4426   text
*      -->P_SE_DEF_JOB_TXT  text
*      <--P_SE_JOB_TXT_MSG  text
*----------------------------------------------------------------------*
FORM get_job_name USING    i_default  TYPE tbtcp-jobname
                  CHANGING e_job_msg .
  DATA:t_icon TYPE icon-id,
       l_freq_h TYPE tbtco-prdhours,
       l_freq_d TYPE tbtco-prddays.
  CLEAR:gf_job_active.

  SELECT SINGLE o~prdhours o~prddays INTO (l_freq_h,l_freq_d)
           FROM tbtcp AS p
          INNER JOIN tbtco AS o
             ON p~jobname  = o~jobname
            AND p~jobcount = o~jobcount
          WHERE
          (   p~progname  = 'RSCOLL00' OR
              p~progname  = 'RSBPCOLL'
          ) AND o~status    = 'S'."#EC SAST_CI_GEN_CHECK

  IF sy-subrc EQ 0.
    gf_job_active = 'X'.
    t_icon = '@08@'.
    IF NOT l_freq_h IS INITIAL.
      CONCATENATE t_icon 'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_h 'hours'(s05)
      INTO e_job_msg SEPARATED BY space.
    ELSEIF NOT l_freq_d IS INITIAL.
      CONCATENATE t_icon 'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_d 'days'(s06)
      INTO e_job_msg SEPARATED BY space.
    ENDIF.

  ELSE.
    t_icon = '@0A@'.
    CONCATENATE t_icon
                'History Capture job is not running.'(w01)
                INTO e_job_msg SEPARATED BY space.
  ENDIF.
  .

ENDFORM.                    " get_job_name
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_command.
  CASE sy-ucomm.
    WHEN 'SCJB'.
      exit_proc = 'Y'.
      PERFORM schedule_background_job.
      EXIT.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
        EXIT.
      ENDIF.
  ENDCASE.
ENDFORM.                    " user_command
*&---------------------------------------------------------------------*
*&      Form  schedule_background_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_background_job.
  DATA: curr_report LIKE rsvar-report,
          l_jobname TYPE btcjob.
  DATA:lt_vari_desc TYPE TABLE OF varid WITH HEADER LINE,
           ls_variant LIKE vari-variant,
           ls_prev_variant LIKE vari-variant,
           ls_report LIKE rsvar-report,
           l_last_id(7).

  curr_report = sy-repid.
  l_jobname = 'SAP_COLLECTOR_FOR_PERFMONITOR'.
  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
       EXPORTING
            in_jobname  = l_jobname
            in_repvarnt = ls_variant
            in_report   = 'RSCOLL00'.
  IF sy-subrc <> 0.
    CALL SCREEN 1000.
  ELSE.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.                    " schedule_background_job
*&---------------------------------------------------------------------*
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_VARI_DESC  text
*      <--P_LS_VARIANT  text
*      <--P_L_LAST_ID  text
*      <--P_LS_REPORT  text
*----------------------------------------------------------------------*
FORM get_next_variant_id TABLES vari_desc STRUCTURE varid
 CHANGING variant LIKE vari-variant
          last_id
          report.
*  DATA: oldnumber(7) TYPE n, oldnumber_c(7).
*variant
  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.

*  SELECT variant INTO variant FROM varid WHERE
*                      report = report AND
*                      variant LIKE '/PSYNG/%'
*     order by variant DESCENDING.
*    oldnumber = variant+7(7).
*    exit.
*  ENDSELECT.
*  last_id = oldnumber.
*  IF sy-subrc NE 0.
*    variant = '/PSYNG/0000000'.
*  ELSE.
*    oldnumber = oldnumber + 1.
*    MOVE oldnumber TO oldnumber_c.
*    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
*  ENDIF.

*--C017 Odubey 29/11/2021
CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
  EXPORTING
    i_report        = sy-repid
 IMPORTING
   E_VARIANT       =   variant.

  vari_desc-report = report.
  vari_desc-variant = variant.
  APPEND vari_desc.


ENDFORM.                    " get_next_variant_id
*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.

ENDFORM.                    " fill_sel_screen_fields_to_tab
*---------------------------------------------------------------------*
*       FORM pf_status_summary                                        *
*---------------------------------------------------------------------*
*       Set PF status for summary screen                              *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM pf_status USING it_extab TYPE slis_t_extab.
  DATA: BEGIN OF lt_func OCCURS 0,
          fcode LIKE rsmpe-func,
        END OF lt_func.

  IF gf_missing_auth_ugroup IS INITIAL.
    lt_func-fcode = 'FUSER'.
    APPEND lt_func.
  ENDIF.


  SET PF-STATUS 'SODHIS' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*&---------------------------------------------------------------------*
*&      Form  show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.
  DATA : alv_layout      TYPE slis_layout_alv,
         alv_grid_titl   TYPE lvc_title,
         i_fieldcat_alv  TYPE slis_t_fieldcat_alv.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: gs_variant TYPE disvariant.

  CLEAR alv_layout.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  REFRESH i_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h27.
  wa_fieldcat_alv-seltext_m = text-h27.
  wa_fieldcat_alv-seltext_s = text-h27.
  wa_fieldcat_alv-reptext_ddic = text-h27.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h26.
  wa_fieldcat_alv-seltext_m = text-h26.
  wa_fieldcat_alv-seltext_s = text-h26.
  wa_fieldcat_alv-reptext_ddic = text-h26.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.


  SORT gt_rpoug_auth_fail BY class company.

  CLEAR : sy-ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   	EXPORTING
          i_grid_title          = alv_grid_titl
          is_layout             = alv_layout
          it_fieldcat           = i_fieldcat_alv
          i_save                = 'A'
          is_variant            = gs_variant
   	TABLES
          t_outtab              = gt_rpoug_auth_fail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SOD  text
*      -->P_L_UNAME  text
*      l_delete  : if this has a value <> 0, delete the
*                   /PSYNG/VRSIO parameter
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname
                                  l_delete type sy-subrc.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
          lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
          ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.
  if l_delete <> 0.
    delete lt_param where parid = '/PSYNG/VRSIO'.
  endif.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            username   = l_uname
            parameterx = ls_paramx
       TABLES
            parameter  = lt_param
            return     = lt_return.


ENDFORM.                    " set_default_sodversion
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
       r_rfcs TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE.


  APPEND LINES OF s_rfc TO r_rfcs.
  CLEAR l_continue.
  DELETE r_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
       EXPORTING
            i_popup    = 'X'
            i_module   = 'SE'
       IMPORTING
            e_continue = l_continue
       TABLES
            it_rfcdes  = r_rfcs.
  IF l_continue <> 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  FREE : gt_rfcdest.
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.

ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_RFCS  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc TABLES
      it_role_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
           rfcdest TYPE rfcdes-rfcdest,
         END OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc.
  ENDIF.


  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
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
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.


ENDFORM.                    " load_role_rfc
*&---------------------------------------------------------------------*
*&      Form  get_tcodes_from_objects
*&---------------------------------------------------------------------*
*       Get transaction codes from Function Objects definition for
*       SOD Live analysis.
*       This ensures that even functions with placeholder tcodes
*      can be analyzed with SOD Live
*      This only supports S_TCODE TCD entries with only a Tcode in the
*      val_from field, no ranges, no wildcards
*----------------------------------------------------------------------*
*      -->P_IT_FAOBJ  text
*      -->P_LT_FUNCTTRAN  text
*----------------------------------------------------------------------*
form get_tcodes_from_objects tables
  it_faobj     structure  /psyng/faobj2.
data : lt_faobj like table of   /psyng/faobj2 with header line.
  lt_faobj[] = it_faobj[].
  sort lt_faobj by object field.
  delete lt_faobj where object <> 'S_TCODE' or field <> 'TCD'.
  loop at lt_faobj.
    check lt_faobj-VAL_FROM NS '*' and lt_faobj-VAL_TO is initial.
    gt_functran-funid      = lt_faobj-funid.
    gt_functran-tcode      = lt_faobj-VAL_FROM.
    append gt_functran.
  endloop.
endform.                    " get_tcodes_from_objects
