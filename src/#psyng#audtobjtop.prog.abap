*----------------------------------------------------------------------*
* INCLUDE PROGRAM       : /PSYNG/AUDTOBJTOP
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
REPORT /psyng/audtobjtop MESSAGE-ID tree_control_msg.

DATA: OBJECTID              LIKE CDHDR-OBJECTID,
      TCODE                 LIKE CDHDR-TCODE,
      PLANNED_CHANGE_NUMBER LIKE CDHDR-PLANCHNGNR,
      UTIME                 LIKE CDHDR-UTIME,
      UDATE                 LIKE CDHDR-UDATE,
      USERNAME              LIKE CDHDR-USERNAME,
      CDOC_PLANNED_OR_REAL  LIKE CDHDR-CHANGE_IND,
      CDOC_UPD_OBJECT       LIKE CDHDR-CHANGE_IND VALUE 'U',
      CDOC_NO_CHANGE_POINTERS LIKE CDHDR-CHANGE_IND.
*INCLUDE /psyng/fsw_cdupdcdc.

DATA: UPD_ICDTXT_SWAUDC           TYPE C.
DATA: BEGIN OF ICDTXT_SWAUDC           OCCURS 20.
        INCLUDE STRUCTURE CDTXT.
DATA: END OF ICDTXT_SWAUDC          .

TABLES: */psyng/swaudc2                  , /psyng/swaudc2
 .
DATA: UPD_PSYNG_SWAUDC                    TYPE C.
TABLES: */PSYNG/SWAUDHDR                  , /PSYNG/SWAUDHDR.
INCLUDE /PSYNG/FSW_AUDUPDCD.

CLASS lcl_application DEFINITION DEFERRED.
CLASS cl_gui_cfw DEFINITION LOAD.

CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.

*CAUTION: MTREEITM is the name of the item structure which must
*be defined by the programmer. DO NOT USE MTREEITM!
TYPES: t_tree_item LIKE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY.

TYPES: BEGIN OF t_swaudc,
         swaudid       TYPE /psyng/swaudc2-swaudid,
         description TYPE /psyng/swaudhdr-description,
         tcode       TYPE /psyng/swaudc2-tcode,
         ttext       TYPE tstct-ttext,
         object      TYPE /psyng/swaudc2-object,
         otext       TYPE tobjt-ttext,
         tnode       TYPE i,
         onode       TYPE i,
         valueset    TYPE /psyng/swaudc2-valueset,
         field       TYPE /psyng/swaudc2-field,
         ddtext      TYPE dd04t-ddtext,
         val_from    TYPE /psyng/swaudc2-val_from,
         val_to      TYPE /psyng/swaudc2-val_to,
         sel         TYPE c,
         rec_num     TYPE i,
       END OF t_swaudc.

*&spwizard: declaration of tablecontrol 'TC_SELTAB' itself
CONTROLS: tc_seltab TYPE TABLEVIEW USING SCREEN 0100.

DATA: BEGIN OF gt_file OCCURS 0,
        swaudid  TYPE /psyng/swaudc2-swaudid,
        tcode    TYPE /psyng/swaudc2-tcode,
        object   TYPE /psyng/swaudc2-object,
        valueset TYPE /psyng/swaudc2-valueset,
        field    TYPE /psyng/swaudc2-field,
        val_from TYPE /psyng/swaudc2-val_from,
        val_to   TYPE /psyng/swaudc2-val_to,
      END OF gt_file.

DATA: BEGIN OF gt_changes OCCURS 0,
        swaudid  TYPE /psyng/swaudc2-swaudid,
        tcode  TYPE /psyng/swaudc2-tcode,
        object TYPE /psyng/swaudc2-object,
      END OF gt_changes.

DATA: BEGIN OF gt_values OCCURS 0,
        line(60) TYPE c,
      END OF gt_values.

DATA: BEGIN OF gt_node_state OCCURS 0,
        node_key TYPE tv_nodekey,
        swaudid  TYPE /psyng/swaudc2-swaudid,
        tcode    TYPE /psyng/swaudc2-tcode,
        object   TYPE /psyng/swaudc2-object,
        tnode    TYPE i,
        onode    TYPE i,
        valueset TYPE /psyng/swaudc2-valueset,
        expanded TYPE flag,
      END OF gt_node_state.

DATA: g_application      TYPE REF TO lcl_application,
      g_custom_container TYPE REF TO cl_gui_custom_container,
      g_tree             TYPE REF TO cl_gui_column_tree,
      g_ok_code          TYPE sy-ucomm,
      g_search_swaudid   TYPE /psyng/swaudc2-swaudid,
      g_search_tcode     TYPE /psyng/swaudc2-tcode,
      g_search_object    TYPE /psyng/swaudc2-object,
      g_start_pos        TYPE i,
      g_start_onode      TYPE tv_nodekey,
      g_start_tnode      TYPE tv_nodekey,
      g_start_swaudid    TYPE tv_nodekey,
      gf_dispchg(1)      TYPE c VALUE 'D',       "Change / Display mode
      gf_uppercase       TYPE /psyng/bapiflagx VALUE 'X',
      g_event(20)        TYPE c,
      g_node_key         TYPE tv_nodekey,
      g_answer(1)        TYPE c,
      g_tc_seltab_lines  LIKE sy-loopc,
      gl_tobjt           TYPE tobjt,
      gt_node            TYPE treev_ntab,
      gt_item            TYPE t_tree_item,
      gt_keys            TYPE TABLE OF tv_nodekey WITH HEADER LINE,
      gt_fields          TYPE help_value OCCURS 0 WITH HEADER LINE,
      gt_swaudc          TYPE t_swaudc OCCURS 0 WITH HEADER LINE,
      gt_select          TYPE t_swaudc OCCURS 0 WITH HEADER LINE,
      gt_del_vs          TYPE t_swaudc OCCURS 0.

*Security related fields
data: act_change(2)   value '02'.    "change activity
data: act_display(2)  value '03'.    "display activity

*-------------------------- SELECTION SCREEN --------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t05.
PARAMETERS: p_vrsio LIKE /psyng/swaudc2-vrsio.
SELECT-OPTIONS: swaudid FOR /psyng/swaudc2-swaudid,
                swatcde FOR /psyng/swaudc2-tcode.
PARAMETERS: P_NODSP NO-DISPLAY.
SELECTION-SCREEN END OF BLOCK blk1.
