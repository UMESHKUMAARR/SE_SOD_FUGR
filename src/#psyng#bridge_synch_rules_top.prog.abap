*&---------------------------------------------------------------------*
*&  Include           /PSYNG/BRIDGE_SYNCH_RULES_TOP
*&---------------------------------------------------------------------*
TYPE-POOLS : slis, icon.
TABLES sscrfields.

TYPES: BEGIN OF ty_schema,
  schema_name TYPE string,
  END OF ty_schema,

  BEGIN OF ty_group,
  group TYPE string,
  description TYPE string,
  type TYPE string,
  END OF ty_group,

  BEGIN OF ty_actmodval,
    actmodval TYPE string,
    END OF ty_actmodval,

    BEGIN OF ty_rule,
      cmb_name TYPE string,
      cmb_des TYPE string,
      risk_lev TYPE string,
      risk_des TYPE string,
      prcs_ctrl TYPE string,
      schema TYPE string,
      obj1 TYPE string,
      obj1_type TYPE string,
      obj2 TYPE string,
      obj2_type TYPE string,
      obj3 TYPE string,
      obj3_type TYPE string,
      obj4 TYPE string,
      obj4_type TYPE string,
      obj5 TYPE string,
      obj5_type TYPE string,
      END OF ty_rule,

      BEGIN OF ty_actvtmod,
        actvt TYPE string,
        actvtmod TYPE string,
        authobj TYPE string,
        authfield TYPE string,
        authval TYPE string,
        actvtdes TYPE string,
        sys TYPE string,
        END OF ty_actvtmod,

        BEGIN OF ty_grpcmp,
          grp TYPE string,
          actvt TYPE string,
          actvtmod TYPE string,
          actvtdes TYPE string,
          apparea TYPE string,
          actvtgrptyp TYPE string,
          desc TYPE string,
          sys TYPE string,
          END OF ty_grpcmp,

          BEGIN OF ty_mcdef,
            title TYPE string,
            short_des TYPE string,
            long_des TYPE string,
            procedure TYPE string,
            auto_lev TYPE string,
            rpt_send_auto TYPE string,
            ctl_time_scope TYPE string,
            performer TYPE string,
            owner TYPE string,
            email_msg_temp TYPE string,
            bpw TYPE string,
            rsc TYPE string,
            END OF ty_mcdef,

BEGIN OF ty_csv,
line TYPE c LENGTH 10000,
END OF ty_csv,

BEGIN OF ty_logs,
msg_typ TYPE c,
log_msg(200) TYPE c,
detail(15) TYPE c,
END OF ty_logs,

BEGIN OF ty_cnnectcfg,
param TYPE char100,
value TYPE char100,
END OF ty_cnnectcfg,

BEGIN OF ty_md_pull_logs,
  contid TYPE /psyng/contid,
  status TYPE char10,
  END OF ty_md_pull_logs,

  BEGIN OF ty_ma_pull_logs.
    INCLUDE STRUCTURE /psyng/sw_mit_emp_vlation_plc.
    TYPES: status TYPE char255,
    END OF ty_ma_pull_logs,

*--To store activity modes created for function
        BEGIN OF ty_am,
          funid TYPE /psyng/function_id,
          am TYPE string,
          tcode TYPE tcode,
          END OF ty_am,

          BEGIN OF ty_ftorobj,
            funid TYPE /psyng/function_id,
            tcode TYPE tcode,
            object TYPE /psyng/object,
            END OF ty_ftorobj.

TYPES : tt_pbridge_con TYPE TABLE OF /psyng/api_conf,
        tt_return TYPE TABLE OF bapiret2,
        tt_pbridge_con_txt TYPE TABLE OF /psyng/api_conf_txt,
        tt_pbridge_con_detail TYPE TABLE OF /psyng/api_conf_details,
        tt_pbridge_fun TYPE TABLE OF /psyng/pbridge_fun,
        tt_pbridge_fun_detail TYPE TABLE OF /psyng/pbridge_func_detail,
        tt_pbridge_fun_obj TYPE TABLE OF /psyng/sw_pbridge_fun_obj,
        tt_conflict TYPE TABLE OF /psyng/conflict,
        tt_texts TYPE TABLE OF /psyng/texts,
        tt_confdet TYPE TABLE OF /psyng/confdet,
        tt_function TYPE TABLE OF /psyng/function,
        tt_fundet   TYPE TABLE OF /psyng/functtran,
        tt_funobj   TYPE TABLE OF /psyng/faobj2,
        tt_schema TYPE TABLE OF ty_schema,
        tt_group TYPE TABLE OF ty_group,
        tt_actmodval TYPE TABLE OF ty_actmodval,
        tt_rule TYPE TABLE OF ty_rule,
        tt_csv TYPE TABLE OF ty_csv,
        tt_actvtmod TYPE TABLE OF ty_actvtmod,
        tt_grpcmp TYPE TABLE OF ty_grpcmp,
        tt_logs TYPE TABLE OF ty_logs,
        tt_cnnectcfg TYPE TABLE OF ty_cnnectcfg,
        tt_pbridge_sys TYPE TABLE OF /psyng/pbridge_systems,
        tt_mcdef TYPE TABLE OF ty_mcdef,
        tt_am TYPE TABLE OF ty_am.

DATA: gt_messages TYPE TABLE OF bapiret2,
      gt_incmpobj TYPE TABLE OF /psyng/inco_object,
      g_ucomm TYPE sy-ucomm,
      gt_fieldcat1 TYPE lvc_t_fcat,
      gs_layout TYPE lvc_s_layo,
      g_cust_cont TYPE REF TO cl_gui_custom_container,
      g_alv_grid TYPE REF TO cl_gui_alv_grid.

DATA : gt_logs TYPE TABLE OF ty_logs,
       gt_fieldcat TYPE slis_t_fieldcat_alv,
       gs_fieldcat TYPE slis_fieldcat_alv,
       g_layout TYPE slis_layout_alv,
       gt_top TYPE slis_t_listheader,
       gt_cnnectcfg TYPE TABLE OF ty_cnnectcfg,
       g_host TYPE string,
       g_user TYPE string,
       g_pass TYPE string,
       g_port TYPE string,
       gf_dischg TYPE flag,
       client TYPE sy-mandt,
       gt_pbridge_sys TYPE TABLE OF /psyng/pbridge_systems,
       gf_sysid_success TYPE flag,
       gf_sysid_valid TYPE flag,
       gf_sysname_valid TYPE flag,
       g_current_user TYPE sy-uname,
       g_button_set TYPE flag,
gt_schema TYPE TABLE OF ty_schema,
gt_group TYPE TABLE OF ty_group,
gt_rule TYPE TABLE OF ty_rule,
gt_actmodval TYPE TABLE OF ty_actmodval,
gt_actvtmod TYPE TABLE OF  ty_actvtmod,
gt_grpcmp TYPE TABLE OF ty_grpcmp,
gt_mcdef TYPE TABLE OF ty_mcdef,
curr_variant             LIKE  rsvar-variant,
g_curr_variant           LIKE  rsvar-variant,
g_variant                LIKE vari-variant,
g_vari_desc              TYPE varid OCCURS 0 WITH HEADER LINE,
g_vari_contents          LIKE  rsparams OCCURS 0 WITH HEADER LINE,
g_vari_text              LIKE varit OCCURS 0 WITH HEADER LINE,
gt_irsparams             TYPE rsparams OCCURS 0 WITH HEADER LINE,
g_program                LIKE sy-repid,
g_exit_proc TYPE flag,
gs_top TYPE slis_listheader,
gt_mchdr TYPE TABLE OF /psyng/mchdr,
gt_mcuser TYPE TABLE OF /psyng/da_sw_mcuser,
gt_md_logs TYPE TABLE OF ty_md_pull_logs,
gt_ma_pull_logs TYPE TABLE OF ty_ma_pull_logs.
CONSTANTS : co_password_length           TYPE i  VALUE 40,
            co_number_of_characters     TYPE i  VALUE 94,
            co_password_characters(94)  TYPE c VALUE
         ' !"#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQ' &
         'RSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~',

         co_key(40)                  TYPE c  VALUE
        'WzAu=GM?pLrU&N\`EF!@mBbg K/nc)e;SvR+Daw[',
        gc_display TYPE c VALUE 'D',
        gc_change TYPE c VALUE 'C',
        gc_true TYPE c VALUE 'X',
        gc_see_details(15) TYPE c VALUE 'See details'.

DEFINE add_column.
  gs_fieldcat-fieldname = &1.
  gs_fieldcat-seltext_l  = &2.
  append gs_fieldcat to &3.
  clear gs_fieldcat.
END-OF-DEFINITION.

DEFINE add_header.
  gs_top-typ = &1.
  gs_top-info = &2.
  APPEND gs_top to gt_top.
  clear gs_top.
END-OF-DEFINITION.
