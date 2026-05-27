*&---------------------------------------------------------------------*
*&  Include           ZARP_DISTRIBUTION_CFGSETS_TOP
*&---------------------------------------------------------------------*

TYPES : BEGIN OF ty_system,
          sysid   TYPE /psyng/swcfgsys-sysid,
          rfcdest TYPE /psyng/sw_rfcdes-rfcdest,
        END OF ty_system,
        tt_system TYPE STANDARD TABLE OF ty_system,
        g_mess    LIKE sy-uline.

TYPES tt_system_range TYPE TABLE OF /psyng/range_sysid.
"B17172 Changes by GSINGH
RANGES: gr_system FOR /psyng/range_sysid-low."B17172 Changes by GSINGH
DATA if_access_check     TYPE flag."B17172 Changes by GSINGH

DATA: BEGIN OF gt_output OCCURS 0,
        target_sysid LIKE /psyng/swcfgve-sysid,
        system       LIKE /psyng/swcfgve-sysid,
        setid        LIKE /psyng/swcfgve-setid,
        description  LIKE /psyng/swcfgset-description,
        type         LIKE /psyng/swcfsel-type,
        name         LIKE /psyng/swcfgoe-varbl, "/psyng/swcfgoe-abb,
        field        LIKe /psyng/swcfgoe-varbl,
        value        LIKE /psyng/swcfgoe-value,
        active       LIKE /psyng/swcfgoe-active,
        modified     LIKE /psyng/swcfgoe-modified,
      END OF gt_output.

data: BEGIN OF gt_logs occurs 0,
      system  like /psyng/swcfgve-sysid,
      setid   like /PSYNG/SWCFGSET-setid,
      sodvrsio like /PSYNG/SWCFGSET-sodvrsio,
      message like /psyng/swcfgset-description,
end of gt_logs.

data: g_ucomm               LIKE sy-ucomm,
curr_variant          LIKE  rsvar-variant,
g_exit_proc,
g_curr_variant        LIKE  rsvar-variant,
g_variant             LIKE vari-variant,
g_vari_desc           TYPE varid OCCURS 0 WITH HEADER LINE,
g_vari_contents       LIKE  rsparams OCCURS 0 WITH HEADER LINE,
g_vari_text           LIKE varit OCCURS 0 WITH HEADER LINE,
gt_irsparams          TYPE rsparams OCCURS 0 WITH HEADER LINE,
g_program             LIKE sy-repid,
g_total_ana_systems   type i,
g_error_systems       type i,
g_rfc_error           type flag.

*----Macros
DEFINE msg.
  if sy-batch = 'X'.
    message s002(/psyng/sw) with &1 &2 &3 &4.
    commit work.
  endif.
END-OF-DEFINITION.

define alv_logs.

*-- Logs
if p_alv = 'X'.
  gt_output-system = &1.
  gt_output-description = &2.
  append gt_output.
  clear gt_output.
endif.

if p_log = 'X'.
  gt_logs-system = &1.
  gt_logs-setid  = &3.
  gt_logs-sodvrsio = &4.
  gt_logs-message = &2.
  append gt_logs.
  clear gt_logs.
endif.

end-of-definition.
