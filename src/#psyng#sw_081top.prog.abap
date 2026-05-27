*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_081TOP.
**
*----------------------------------------------------------------------*
CLASS gcl_application DEFINITION DEFERRED.
CLASS cl_gui_cfw DEFINITION LOAD.

*CAUTION: MTREEITM is the name of the item structure which must
*be defined by the programmer. DO NOT USE MTREEITM!
TYPES: t_item_table LIKE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY,

       BEGIN OF t_detail,
         functionid TYPE /psyng/functtran-functionid,
         tcode      TYPE /psyng/functtran-tcode,
       END OF t_detail,

       BEGIN OF t_object,
         tcode     TYPE /psyng/faobj2-tcode,
         object    TYPE /psyng/faobj2-object,
         valueset  TYPE /psyng/faobj2-valueset,
         field     TYPE /psyng/faobj2-field,
         val_from  TYPE /psyng/faobj2-val_from,
         val_to    TYPE /psyng/faobj2-val_to,
         obj_or    TYPE /psyng/faobj2-obj_or,
         fld_and   TYPE /psyng/faobj2-fld_and,
      END OF t_object.

DATA: go_application   TYPE REF TO gcl_application,
      go_container     TYPE REF TO cl_gui_custom_container,
      go_tree          TYPE REF TO cl_gui_list_tree,
      g_node_key       TYPE tv_nodekey,
      g_lvdesc         TYPE /psyng/swsodvers-vdesc,
      g_rvdesc         TYPE /psyng/swsodvers-vdesc,
      g_format         TYPE /psyng/swconfig-value,
      g_lid(30)        TYPE c,
      g_rid(30)        TYPE c,
      g_ldesc          TYPE /psyng/function-description,
      g_rdesc          TYPE /psyng/function-description,
      g_linactive(8)   TYPE c,
      g_rinactive(8)   TYPE c,
      g_limp           TYPE /psyng/conflict-imp,
      g_rimp           TYPE /psyng/conflict-imp,
      g_lowner         TYPE /psyng/function-owner,
      g_rowner         TYPE /psyng/function-owner,
      g_lbusarea       TYPE /psyng/function-busarea,
      g_rbusarea       TYPE /psyng/function-busarea,
      g_lid2(20)       TYPE c,
      g_rid2(20)       TYPE c,
      gt_lfunction     TYPE TABLE OF /psyng/function, "Left header
      gt_rfunction     TYPE TABLE OF /psyng/function, "Right header
      gt_lmfunction    TYPE TABLE OF /psyng/function, "Left missing hdr
      gt_rmfunction    TYPE TABLE OF /psyng/function, "Right missing hdr
      gt_sfunction     TYPE TABLE OF /psyng/function, "Same header
      gt_ldfaobj       TYPE TABLE OF /psyng/faobj2,   "Left diff objects
      gt_rdfaobj       TYPE TABLE OF /psyng/faobj2,   "Right diff object
      gt_lconflict     TYPE TABLE OF /psyng/conflict, "Left header
      gt_rconflict     TYPE TABLE OF /psyng/conflict, "Right header
      gt_lmconflict    TYPE TABLE OF /psyng/conflict, "Left missing hdr
      gt_rmconflict    TYPE TABLE OF /psyng/conflict, "Right missing hdr
      gt_sconflict     TYPE TABLE OF /psyng/conflict, "Same header
      gt_ldcritcodes   TYPE TABLE OF /psyng/critcodes,"Left diff header
      gt_rdcritcodes   TYPE TABLE OF /psyng/critcodes,"Right diff header
      gt_lmtran        TYPE TABLE OF /psyng/critcodes,"Left missing hdr
      gt_rmtran        TYPE TABLE OF /psyng/critcodes,"Right missing hdr
      gt_stran         TYPE TABLE OF /psyng/critcodes,"Same header
      gt_ldauth        TYPE TABLE OF /psyng/swaudhdr, "Left diff header
      gt_rdauth        TYPE TABLE OF /psyng/swaudhdr, "Right diff header
      gt_lmauth        TYPE TABLE OF /psyng/swaudhdr, "Left missing hdr
      gt_rmauth        TYPE TABLE OF /psyng/swaudhdr, "Right missing hdr
      gt_sauth         TYPE TABLE OF /psyng/swaudhdr, "Same header
      gt_ldaudc    TYPE TABLE OF /psyng/swaudc2, "Left diff objects
      gt_rdaudc    TYPE TABLE OF /psyng/swaudc2, "Right diff object
      gt_ldrole        TYPE TABLE OF /psyng/criroles, "Left diff header
      gt_rdrole        TYPE TABLE OF /psyng/criroles, "Right diff header
      gt_lmrole        TYPE TABLE OF /psyng/criroles, "Left missing hdr
      gt_rmrole        TYPE TABLE OF /psyng/criroles, "Right missing hdr
      gt_srole         TYPE TABLE OF /psyng/criroles, "Same header
      gt_ldprof        TYPE TABLE OF /psyng/criprof,  "Left diff header
      gt_rdprof        TYPE TABLE OF /psyng/criprof,  "Right diff header
      gt_lmprof        TYPE TABLE OF /psyng/criprof,  "Left missing hdr
      gt_rmprof        TYPE TABLE OF /psyng/criprof,  "Right missing hdr
      gt_sprof         TYPE TABLE OF /psyng/criprof,  "Same header
      gt_ldisptext     TYPE TABLE OF /psyng/texts,    "Left diff texts
      gt_rdisptext     TYPE TABLE OF /psyng/texts,    "Right diff texts
      go_ldetail       TYPE REF TO cl_gui_custom_container,
      go_rdetail       TYPE REF TO cl_gui_custom_container,
      go_lobject       TYPE REF TO cl_gui_custom_container,
      go_robject       TYPE REF TO cl_gui_custom_container,
      go_ldetgrid      TYPE REF TO cl_gui_alv_grid,
      go_rdetgrid      TYPE REF TO cl_gui_alv_grid,
      go_lobjgrid      TYPE REF TO cl_gui_alv_grid,
      go_robjgrid      TYPE REF TO cl_gui_alv_grid,
      gt_ldetail       TYPE TABLE OF t_detail,
      gt_rdetail       TYPE TABLE OF t_detail,
      gt_lobject       TYPE TABLE OF t_object,
      gt_robject       TYPE TABLE OF t_object,
      gs_layout        TYPE lvc_s_layo,
      g_ldetcontainer  TYPE scrfname VALUE 'G_LDETAIL',
      g_rdetcontainer  TYPE scrfname VALUE 'G_RDETAIL',
      g_lobjcontainer  TYPE scrfname VALUE 'G_LOBJECT',
      g_robjcontainer  TYPE scrfname VALUE 'G_ROBJECT',
      gt_detfieldcat   TYPE lvc_t_fcat,
      gt_objfieldcat   TYPE lvc_t_fcat,
      gs_fieldcat      TYPE lvc_s_fcat,
      go_ltxtcontainer TYPE REF TO cl_gui_custom_container,
      go_rtxtcontainer TYPE REF TO cl_gui_custom_container,
      go_ltxtedit      TYPE REF TO cl_gui_textedit,
      go_rtxtedit      TYPE REF TO cl_gui_textedit,
      g_return_code    TYPE i,
      g_lid2_text      TYPE string,
      g_rid2_text      TYPE string,
      g_flag      TYPE c,

      BEGIN OF gt_ldtran OCCURS 0,                    "Left diff tcodes
        functionid TYPE /psyng/functtran-functionid,
        tcode      TYPE /psyng/functtran-tcode,
      END OF gt_ldtran,

      BEGIN OF gt_rdtran OCCURS 0,                    "Right diff tcodes
        functionid TYPE /psyng/functtran-functionid,
        tcode      TYPE /psyng/functtran-tcode,
      END OF gt_rdtran,

      BEGIN OF gt_lddet OCCURS 0,                     "Left diff funcs
        conid TYPE /psyng/confdet-conid,
        funid TYPE /psyng/confdet-functionid,
      END OF gt_lddet,

      BEGIN OF gt_rddet OCCURS 0,                     "Right diff funcs
        conid TYPE /psyng/confdet-conid,
        funid TYPE /psyng/confdet-functionid,
      END OF gt_rddet,

      BEGIN OF gt_ldtexts OCCURS 0,                   "Left diff texts
        spras TYPE /psyng/texts-spras,
        text  TYPE /psyng/texts-text,
      END OF gt_ldtexts,

      BEGIN OF gt_rdtexts OCCURS 0,                   "Right diff texts
        spras TYPE /psyng/texts-spras,
        text  TYPE /psyng/texts-text,
      END OF gt_rdtexts.

*-------------------------- SELECTION-SCREEN --------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 1(12) text-c01.
SELECTION-SCREEN COMMENT 1(14) text-c01.
PARAMETERS p_lvrsio TYPE /psyng/swsodvers-vrsio OBLIGATORY.
*SELECTION-SCREEN COMMENT 35(13) text-c02.
SELECTION-SCREEN COMMENT 37(15) text-c02.
PARAMETERS p_rvrsio TYPE /psyng/swsodvers-vrsio OBLIGATORY.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN SKIP.
PARAMETERS: p_cfunc AS CHECKBOX DEFAULT 'X',
            p_cconf AS CHECKBOX DEFAULT 'X',
            p_ctran AS CHECKBOX DEFAULT 'X',
            p_cauth AS CHECKBOX DEFAULT 'X',
            p_crole AS CHECKBOX DEFAULT 'X',
            p_cprof AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN SKIP 2.
SELECTION-SCREEN COMMENT 1(75) text-c03.
SELECTION-SCREEN END OF BLOCK blk1.
