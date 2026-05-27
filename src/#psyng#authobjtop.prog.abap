*----------------------------------------------------------------------*
* INCLUDE PROGRAM       : /PSYNG/AUTHOBJTOP
* AUTHOR                : Security Weaver, LLC
* RELEASE               : 1.0.1.0
* DATE OF RELEASE       :
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/authobjtop MESSAGE-ID tree_control_msg.

***********************************************************************
***********************************************************************
***********************************************************************
*INCLUDE /psyng/fsw_cdupdcdt.
*INCLUDE /psyng/fsw_cdupdcdc.

DATA: OBJECTID              LIKE CDHDR-OBJECTID,
      TCODE                 LIKE CDHDR-TCODE,
      PLANNED_CHANGE_NUMBER LIKE CDHDR-PLANCHNGNR,
      UTIME                 LIKE CDHDR-UTIME,
      UDATE                 LIKE CDHDR-UDATE,
      USERNAME              LIKE CDHDR-USERNAME,
      CDOC_PLANNED_OR_REAL  LIKE CDHDR-CHANGE_IND,
      CDOC_UPD_OBJECT       LIKE CDHDR-CHANGE_IND VALUE 'U',
      CDOC_NO_CHANGE_POINTERS LIKE CDHDR-CHANGE_IND.

TABLES: */PSYNG/FAOBJ2                  , /PSYNG/FAOBJ2.

DATA: UPD_ICDTXT_FAOBJ           TYPE C.
DATA: BEGIN OF ICDTXT_FAOBJ           OCCURS 20.
        INCLUDE STRUCTURE CDTXT.
DATA: END OF ICDTXT_FAOBJ          .

DATA: UPD_PSYNG_FAOBJ                    TYPE C.


***********************************************************************
***********************************************************************
***********************************************************************

CLASS lcl_application DEFINITION DEFERRED.
CLASS cl_gui_cfw DEFINITION LOAD.

CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.

*CAUTION: MTREEITM is the name of the item structure which must
*be defined by the programmer. DO NOT USE MTREEITM!
TYPES: t_tree_item LIKE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY.

TYPES: BEGIN OF t_faobj,
         funid       TYPE /psyng/faobj2-funid,
         description TYPE /psyng/function-description,
         tcode       TYPE /psyng/faobj2-tcode,
         ttext       TYPE tstct-ttext,
         fioriid     type /PSYNG/SW_FIORIA-fioriid,
         appname     type /psyng/sw_fioria-APPNAME,
         type        type /psyng/functtran-type,
         object      TYPE /psyng/faobj2-object,
         otext       TYPE tobjt-ttext,
         tnode       TYPE i,
         onode       TYPE i,
         valueset    TYPE /psyng/faobj2-valueset,
         field       TYPE /psyng/faobj2-field,
         ddtext      TYPE dd04t-ddtext,
         val_from    TYPE /psyng/faobj2-val_from,
         val_to      TYPE /psyng/faobj2-val_to,
         obj_or      TYPE /psyng/faobj2-obj_or,
         fld_and     TYPE /psyng/faobj2-fld_and,
         sel         TYPE c,
         rec_num     TYPE i,
       END OF t_faobj.

*&spwizard: declaration of tablecontrol 'TC_SELTAB' itself
CONTROLS: tc_seltab TYPE TABLEVIEW USING SCREEN 0100.

DATA: BEGIN OF gt_file OCCURS 0,
        funid    TYPE /psyng/faobj2-funid,
        tcode    TYPE /psyng/faobj2-tcode,
        object   TYPE /psyng/faobj2-object,
        valueset TYPE /psyng/faobj2-valueset,
        field    TYPE /psyng/faobj2-field,
        val_from TYPE /psyng/faobj2-val_from,
        val_to   TYPE /psyng/faobj2-val_to,
        obj_or   TYPE /psyng/faobj2-obj_or,
        fld_and  TYPE /psyng/faobj2-fld_and,
      END OF gt_file.

DATA: BEGIN OF gt_changes OCCURS 0,
        funid  TYPE /psyng/faobj2-funid,
        tcode  TYPE /psyng/faobj2-tcode,
        object TYPE /psyng/faobj2-object,
      END OF gt_changes.

DATA: BEGIN OF gt_values OCCURS 0,
        line(60) TYPE c,
      END OF gt_values.

DATA: BEGIN OF gt_node_state OCCURS 0,
        node_key TYPE tv_nodekey,
        funid    TYPE /psyng/faobj2-funid,
        tcode    TYPE /psyng/faobj2-tcode,
        object   TYPE /psyng/faobj2-object,
        tnode    TYPE i,
        onode    TYPE i,
        valueset TYPE /psyng/faobj2-valueset,
        expanded TYPE flag,
      END OF gt_node_state.

DATA: g_application      TYPE REF TO lcl_application,
      g_custom_container TYPE REF TO cl_gui_custom_container,
      g_tree             TYPE REF TO cl_gui_column_tree,
      g_ok_code          TYPE sy-ucomm,
      g_search_funid     TYPE /psyng/faobj2-funid,
      g_search_tcode     TYPE /psyng/faobj2-tcode,
      g_search_object    TYPE /psyng/faobj2-object,
      g_start_pos        TYPE i,
      g_start_onode      TYPE tv_nodekey,
      g_start_tnode      TYPE tv_nodekey,
      g_start_funid      TYPE tv_nodekey,
      gf_dispchg(1)      TYPE c VALUE 'D',       "Change / Display mode
      gf_uppercase       TYPE /psyng/bapiflagx VALUE 'X',
      g_node_key         TYPE tv_nodekey,
      g_answer(1)        TYPE c,
      g_tc_seltab_lines  LIKE sy-loopc,
      gl_tobjt           TYPE tobjt,
      gt_node            TYPE treev_ntab,
      gt_item            TYPE t_tree_item,
      gt_keys            TYPE TABLE OF tv_nodekey WITH HEADER LINE,
      gt_fields          TYPE help_value OCCURS 0 WITH HEADER LINE,
      gt_faobj           TYPE t_faobj OCCURS 0 WITH HEADER LINE,
      gt_select          TYPE t_faobj OCCURS 0 WITH HEADER LINE,
      gt_chng_rec        TYPE t_faobj OCCURS 0 WITH HEADER LINE,
*HBHALLA(PN-4547)
      gt_del_vs          TYPE t_faobj OCCURS 0.

types: begin of ty_hashkey,
       name     type usobhash-name,
       obj_name type usobhash-obj_name,
       end of ty_hashkey.
*Security related fields
DATA: sec_actvt(2).      "activity that user is performing
data: act_change(2)   value '02'.    "change activity
data: act_display(2)  value '03'.    "display activity

*-------------------------- SELECTION SCREEN --------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t05.
PARAMETERS: p_vrsio LIKE /psyng/faobj2-vrsio.
SELECT-OPTIONS: s_funid FOR /psyng/faobj2-funid.
PARAMETERS: P_NODSP NO-DISPLAY .
SELECTION-SCREEN END OF BLOCK blk1.
