*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_095_TOP                                          *
*----------------------------------------------------------------------*
CONSTANTS: gc_service       TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name      TYPE xufield  VALUE 'SRV_NAME'.
DATA : gt_res TYPE TABLE OF /psyng/sw_output_org,
      gt_res_before TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
      gt_res_after TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
        ls_output TYPE /psyng/sw_output_org.
DATA : exit_proc.
DATA: program         LIKE sy-repid.                  "For ALV call
DATA: curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text LIKE varit OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant,
      gt_functions TYPE TABLE OF /psyng/function WITH HEADER LINE,
      gf_central_uid TYPE flag,
      gt_enh_fun TYPE TABLE OF /psyng/sw_enh_usr_fun WITH HEADER LINE.
*data : orgchk type flag value 'X'.

DATA: simuagrs LIKE STANDARD TABLE OF /psyng/sw_sod_remote_roles INITIAL
 SIZE 0 WITH HEADER LINE.

DATA : it_simu_role_addition TYPE TABLE OF /psyng/sw_role_addition_simu
WITH HEADER LINE,
      gt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu WITH HEADER LINE,
               gt_role_removal_simu
         TYPE TABLE OF /psyng/sw_role_removal_simu WITH HEADER LINE.

DATA : lt_simu_roleauth  TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
  lt_simu_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE.
DATA : lt_role_names TYPE TABLE OF agr_define WITH HEADER LINE,
  lt_faobj TYPE TABLE OF /psyng/faobj2,
  lt_functtran TYPE TABLE OF /psyng/functtran,
  lt_roleauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
  lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
  gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
RANGES : range_roles FOR agr_define-agr_name.

DATA: BEGIN OF gt_output OCCURS 10,
        rfcdest      LIKE rfcdes-rfcdest,
        class        LIKE usr02-class,
        company      LIKE /psyng/sw_uinfo-company,
        compshort    LIKE /psyng/sw_uinfo-company,
        department   LIKE /psyng/sw_uinfo-department,
        central_uid  LIKE /psyng/sw_uinfo-central_uid,
        bname        LIKE ust04-bname,
        name_text    LIKE adrp-name_text,
        funid        LIKE /psyng/function-function,
        org_abb      LIKE /psyng/swsodorgm-abb,
        description  LIKE /psyng/function-description,
        er           TYPE c,
        simu         TYPE c,
        simu_before  TYPE c,
        simu_after   TYPE c,
      END OF gt_output.

DATA: lt_outdet LIKE TABLE OF /psyng/sw_outputdet3 WITH HEADER LINE,
     lt_outdet_temp LIKE TABLE OF /psyng/sw_outputdet3 WITH HEADER LINE,
      lt_simrols TYPE TABLE OF /psyng/sw_sel_opts_agr_name
      WITH HEADER LINE,
      lt_bnames TYPE TABLE OF /psyng/range_bname WITH HEADER LINE.
DATA : lt_conflict  TYPE TABLE OF /psyng/conflict,
       lt_confdet   TYPE TABLE OF /psyng/confdet.
*       lt_functtran TYPE TABLE OF /psyng/functtran,
*       lt_faobj     TYPE TABLE OF /psyng/faobj2.
DATA: lt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output.

DATA : gt_uinfo_remote TYPE TABLE OF /psyng/sw_uinfo_remote
       WITH HEADER LINE,
       gf_company_longtext    TYPE /psyng/bapiflagx,
       gf_er_inst             TYPE /psyng/bapiflagx,
       g_usercount TYPE i.
DATA:
*usertype TYPE /psyng/xuustyp,
*DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE
*,
gf_missing_auth_ugroup TYPE flag,
         lt_uinfo_sorted TYPE SORTED TABLE OF /psyng/sw_uinfo_remote
         WITH UNIQUE KEY rfcdest bname  WITH HEADER LINE.

DATA g_dynnr LIKE sy-dynnr.
DATA : g_rfcdes_local TYPE rfcdes-rfcoptions.
*Parallel processing Status
DATA : BEGIN OF gt_process_status OCCURS 0,
        rfcdest TYPE rfcdest,
        numproc TYPE i,
       END OF gt_process_status,
       BEGIN OF gt_process_name OCCURS 0,
         procname(72) TYPE c,
         rfcdest TYPE rfcdest,
       END OF gt_process_name.

*--SE 3.2
DATA: lt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
      gt_rfcdes TYPE TABLE OF rfcdes WITH HEADER LINE,
      gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
      gt_rfcdest_anal TYPE TABLE OF rfcdes WITH HEADER LINE,
      gt_confdet_after TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
      gt_confdet_before TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
      l_tabname TYPE dd02l-tabname.
DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE,
      pertext(200),        "Progress indicator text.
      g_orgchk TYPE c. "C0766
