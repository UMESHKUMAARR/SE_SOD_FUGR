FUNCTION /psyng/sw_028.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_ORGCHECK) TYPE  CHAR1 OPTIONAL
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(I_ENHANCE) TYPE  /PSYNG/BAPIFLAGX OPTIONAL
*"     VALUE(I_ORPHAN_FUNCTIONS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_IGNORE_VAR_ELEM) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ANALYSIS) TYPE  FLAG OPTIONAL
*"     VALUE(I_ORG_FIELD) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(ET_FAOBJ_SYS) TYPE  /PSYNG/SW_TAB_SYS_FAOBJ
*"     VALUE(ET_SWSODORGM_SYS) TYPE  /PSYNG/SW_TAB_SYS_AO
*"     VALUE(EF_INVALID_VERSION) TYPE  /PSYNG/BAPIFLAGX
*"  TABLES
*"      IT_SPCONFS STRUCTURE  /PSYNG/SW_SEL_OPTS_CONID OPTIONAL
*"      IT_BUS_AREA STRUCTURE  /PSYNG/SW_SEL_OPTS_BUS_AREA OPTIONAL
*"      IT_IMP STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      IT_COWNER STRUCTURE  /PSYNG/SW_SEL_OPTS_CONFOWNER OPTIONAL
*"      IT_CONTID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      IT_ORG STRUCTURE  /PSYNG/SW_SEL_OPTS_ORG OPTIONAL
*"      IT_RISK STRUCTURE  /PSYNG/RANGE_RISK OPTIONAL
*"      IT_FUNCTIONS STRUCTURE  /PSYNG/RANGE_FUNID OPTIONAL
*"      ET_CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      ET_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      ET_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      ET_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      ET_SWSODORGM STRUCTURE  /PSYNG/SWSODORGM OPTIONAL
*"      ET_TCODES STRUCTURE  /PSYNG/SW_PAR_TCODE_OUTPUT OPTIONAL
*"      ET_FUNCTRAN_NO_ENH STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_RFCDEST STRUCTURE  RFCDES OPTIONAL
*"      ET_FAOBJ_ORG STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"----------------------------------------------------------------------
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  17/02/2020   Gurpinder   C0016       P33K940469                     *
*----------------------------------------------------------------------*
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_028'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  DATA: lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
        lt_func_obj  TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
        lt_faobj     TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_tcodes    TYPE TABLE OF /psyng/sw_par_tcode_output
                     WITH KEY called_tcode,
        lt_faobj_key TYPE SORTED TABLE OF /psyng/faobj2
                     WITH NON-UNIQUE KEY tcode,
        l_tcode_idx  TYPE i,
        l_faobj_idx  TYPE i,
        l_local      TYPE rfcdest,
        l_dest       TYPE rfcdest,
        lt_faobj_sys TYPE /psyng/sw_tab_faobj,
        lt_varel     TYPE TABLE OF /psyng/sw_varel,
        lt_varel_sys TYPE TABLE OF /psyng/sw_varel,
        l_system_msg(80) TYPE c,
        ls_faobj_sys TYPE /psyng/sw_sys_faobj,
        ls_orgm_sys  TYPE /psyng/sw_sys_ao,
        lt_return    TYPE TABLE OF bapiret2 WITH HEADER LINE,
        lf_success   TYPE flag,
        l_sysid      TYPE /psyng/sysid,
        lt_rfcdes   TYPE TABLE OF rfcdes WITH HEADER LINE,
*BOC 04-02-2025 AKUMAR OPL645
       lt_faobj2 type table of /psyng/faobj2,
       lt_org_obj type table of tobj,
       ls_org_obj type tobj.
*EOC 04-02-2025 AKUMAR OPL645

  FIELD-SYMBOLS: <faobj>  TYPE /psyng/faobj2,
                 <tcodes> TYPE /psyng/sw_par_tcode_output,
                 <functtran> TYPE /psyng/functtran.

  ranges: lr_tcode for tstc-tcode,

*BOC 04-02-2025 AKUMAR OPL645
          lr_fields for tobj-fiel1,
          lr_org_obj for tobj-objct.
*EOC 04-02-2025 AKUMAR OPL645

  CONCATENATE sy-sysid sy-mandt INTO l_local.

*BOC 04-02-2025 AKUMAR OPL645
*--Get org level objects associated with tcode and function
*--which contain any org level field in SOD matrix.
*--Prepare the range of org field names

  data: lt_faobj1 type table of /psyng/faobj2 with header line.
  select distinct object from /psyng/faobj2
   into corresponding fields of table lt_faobj1
   where vrsio = i_vrsio.
  sort lt_faobj1 by object.

  if i_org_field = 'X'.
    lr_fields-sign   = 'I'.
    lr_fields-option = 'EQ'.
    lr_fields-low = 'BUKRS'. append lr_fields.
    lr_fields-low = 'EKORG'. append lr_fields.
    lr_fields-low = 'WERKS'. append lr_fields.
    lr_fields-low = 'IWERK'. append lr_fields.
    lr_fields-low = 'GSBER'. append lr_fields.
    lr_fields-low = 'SPART'. append lr_fields.
    lr_fields-low = 'VTWEG'. append lr_fields.
    lr_fields-low = 'KKBER'. append lr_fields.
    lr_fields-low = 'KOKRS'. append lr_fields.
    lr_fields-low = 'VKORG'. append lr_fields.
    lr_fields-low = 'VSTEL'. append lr_fields.

*--Get org level objects which contains org fields in SAP
    select * from tobj
          into table lt_org_obj
      for all entries in lt_faobj1
          where objct = lt_faobj1-object and
                  ( fiel1 in lr_fields or
                  fiel2 in lr_fields or
                  fiel3 in lr_fields or
                  fiel4 in lr_fields or
                  fiel5 in lr_fields or
                  fiel6 in lr_fields or
                  fiel7 in lr_fields or
                  fiel8 in lr_fields or
                  fiel9 in lr_fields
          ).

*--Prepare the range of org level objects
    loop at lt_org_obj into ls_org_obj.
      lr_org_obj-sign   = 'I'.
      lr_org_obj-option = 'EQ'.
      lr_org_obj-low = ls_org_obj-objct.
      append lr_org_obj.
    endloop.

*--Get org level objects associated with tcode and function but not
*--contain any org level field in SOD matrix.
    refresh lt_faobj2.
    select * from /psyng/faobj2
             into table lt_faobj2
             where vrsio = i_vrsio and
             object in lr_org_obj and
             field  in lr_fields.
    if sy-subrc = 0.
      et_faobj_org[] = lt_faobj2[].
    endif.
  endif.
*EOC 04-02-2025 AKUMAR OPL645

*--Validate SOD Matrix version
  PERFORM validate_sod_matrix USING i_vrsio CHANGING ef_invalid_version.
  CHECK ef_invalid_version IS INITIAL.

* Get SOD matrix
  CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
       EXPORTING
            orgcheck           = i_orgcheck
            i_config_set       = i_config_set
            vrsio              = i_vrsio
            i_orphan_functions = i_orphan_functions
       TABLES
            conflict_fm        = et_conflict
            confdet_fm         = et_confdet
            functtran_fm       = et_functtran
            faobj_fm           = et_faobj
            spconfs_fm         = it_spconfs
            bus_area_fm        = it_bus_area
            imp_fm             = it_imp
            cowner_fm          = it_cowner
            contid_fm          = it_contid
            swsodorgm_fm       = et_swsodorgm
            org_fm             = it_org
            it_risk            = it_risk
            it_functions       = it_functions.

*--START determine Org Values
*--Variable elements will be derived for each system in IT_RFCDEST
*  table et_swsodorgm already contains the values for the local system
  IF i_orgcheck = 'X'.
*--Local Values
    ls_orgm_sys-rfcdest     = l_local.
    ls_orgm_sys-swsodorgm[] = et_swsodorgm[].
    APPEND ls_orgm_sys TO et_swsodorgm_sys.
    CLEAR ls_orgm_sys.
*--Values for remote systems
    LOOP AT it_rfcdest WHERE rfcoptions <> l_local.
      l_sysid              = it_rfcdest-rfcoptions.
      ls_orgm_sys-rfcdest  = l_sysid.
      CALL FUNCTION '/PSYNG/SW_AO_READ_VALUES'
           EXPORTING
                i_vrsio      = i_vrsio
                i_setid      = i_config_set
                i_sysid      = l_sysid
           IMPORTING
                ef_success   = lf_success
           TABLES
                et_swsodorgm = ls_orgm_sys-swsodorgm[]
                et_return    = lt_return.
      APPEND ls_orgm_sys TO et_swsodorgm_sys.
      CLEAR ls_orgm_sys.
    ENDLOOP.
  ELSE.
*--If this is not an ORG check, remove all values that start with a $
*    MESSAGE s002(/psyng/sw) WITH 'Not an org level analysis'
*                          'Removing Org Values from SOD matrix'
*                          '' ''.
    DELETE et_faobj WHERE val_from CP '$*' AND val_to IS initial.
  ENDIF.
*--END determine Org Values

*--START Interpret Variable Elements
  IF if_ignore_var_elem IS INITIAL.

    LOOP AT it_rfcdest.
      l_sysid              = it_rfcdest-rfcoptions.
      ls_faobj_sys-rfcdest = l_sysid.
      ls_faobj_sys-faobj[] = et_faobj[].
      CALL FUNCTION '/PSYNG/SW_VE_READ_VALUES'
           EXPORTING
                i_vrsio     = i_vrsio
                i_setid     = i_config_set
                i_sysid     = l_sysid
                if_analysis = if_analysis
           IMPORTING
                ef_success  = lf_success
           TABLES
                et_faobj2   = ls_faobj_sys-faobj[]
                it_rfcdest  = it_rfcdest
                et_return   = lt_return.

      APPEND ls_faobj_sys TO et_faobj_sys.
      CLEAR ls_faobj_sys.
    ENDLOOP.
**--The local Determination will be applied to the et_faobj table
    CLEAR ls_faobj_sys.
    READ TABLE et_faobj_sys WITH KEY rfcdest = l_local
    INTO ls_faobj_sys.
    IF sy-subrc <> 0.
      l_sysid              = l_local.
      ls_faobj_sys-rfcdest = l_local.
      ls_faobj_sys-faobj[] = et_faobj[].
      lt_rfcdes-rfcoptions = l_local.
      APPEND lt_rfcdes.
      CALL FUNCTION '/PSYNG/SW_VE_READ_VALUES'
           EXPORTING
                i_vrsio     = i_vrsio
                i_setid     = i_config_set
                i_sysid     = l_sysid
                if_analysis = if_analysis
           IMPORTING
                ef_success  = lf_success
           TABLES
                et_faobj2   = ls_faobj_sys-faobj[]
                it_rfcdest  = lt_rfcdes
                et_return   = lt_return.
      APPEND ls_faobj_sys TO et_faobj_sys.
    ENDIF.
    et_faobj[] = ls_faobj_sys-faobj[].
  ENDIF.
  CHECK i_enhance = 'X'.

  SORT lt_functtran BY functionid tcode.
* This table will contain all tcodes that are the result of an
* enhancement, but also were already part of the sod matrix.
  et_functran_no_enh[] = et_functtran[].

  lr_tcode-sign = 'I'.
  LOOP AT et_faobj ASSIGNING <faobj>.
*   Find other transactions in authorization objects that use S_TCODE
    IF <faobj>-object = 'S_TCODE'.
      REFRESH lr_tcode.
      IF <faobj>-val_from CS '*' OR <faobj>-val_to CS '*'.
        lr_tcode-option = 'CP'.
      ELSEIF <faobj>-val_to IS INITIAL.
        lr_tcode-option = 'EQ'.
      ELSE.
        lr_tcode-option = 'BT'.
      ENDIF.

      lr_tcode-low  = <faobj>-val_from.
      lr_tcode-high = <faobj>-val_to.
      APPEND lr_tcode.

      SELECT tcode INTO lt_func_obj-tcode FROM tstc  "#EC CI_SEL_NESTED
             WHERE tcode IN lr_tcode.

        READ TABLE et_functtran WITH KEY functionid = <faobj>-funid
                                         tcode      = lt_func_obj-tcode
                                BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc <> 0.
        lt_func_obj-functionid = <faobj>-funid.
        lt_func_obj-vrsio      = i_vrsio.
        APPEND lt_func_obj.
      ENDSELECT.
    ENDIF.
  ENDLOOP.

  APPEND LINES OF lt_func_obj TO et_functtran.
  SORT et_functtran BY functionid tcode.
  DELETE ADJACENT DUPLICATES FROM et_functtran
                  COMPARING functionid tcode.

* Get list of called tcodes
  CALL FUNCTION '/PSYNG/SW_ENH_GET'
       EXPORTING
            i_vrsio      = i_vrsio
       TABLES
            it_functtran = et_functtran
            et_tcodes    = et_tcodes.

  SORT et_tcodes BY called_tcode.
  SORT et_faobj  BY tcode.
  lt_tcodes[]    = et_tcodes[].
  lt_faobj_key[] = et_faobj[].

* Combine SOD matrix with called tcodes
  LOOP AT et_functtran.
    READ TABLE lt_tcodes WITH KEY called_tcode = et_functtran-tcode
               TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    l_tcode_idx = sy-tabix.

    LOOP AT lt_tcodes FROM l_tcode_idx ASSIGNING <tcodes>
            WHERE called_tcode = et_functtran-tcode.
      lt_functtran       = et_functtran.
      lt_functtran-tcode = <tcodes>-calling_tcode.
      lt_functtran-vrsio = i_vrsio.
      APPEND lt_functtran.

      READ TABLE lt_faobj_key WITH KEY tcode = <tcodes>-called_tcode
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.
      l_faobj_idx = sy-tabix.

      LOOP AT lt_faobj_key FROM l_faobj_idx ASSIGNING <faobj>
              WHERE tcode = <tcodes>-called_tcode.
*              AND funid = et_functtran-functionid.
        lt_faobj       = <faobj>.
        lt_faobj-tcode = <tcodes>-calling_tcode.
        APPEND lt_faobj.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
  SORT lt_functtran BY functionid tcode.
* Delete unnesecary lines from the table that contains tcodes that are
*  the result of an enhancement, but also were already part of the sod
*  matrix
  LOOP AT et_functran_no_enh ASSIGNING <functtran>.
    READ TABLE lt_tcodes WITH KEY calling_tcode  = <functtran>-tcode
                                  BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--DHORIONS 2014/06/10 - removal should be from enhanced tcodes,
*  not from non-enhanced tcodes
*   DELETE et_functran_no_enh WHERE  functionid = <functtran>-functionid
*                                 AND    tcode     = <functtran>-tcode
*                                 .
      DELETE lt_tcodes WHERE calling_tcode = <functtran>-tcode.
    ENDIF.
  ENDLOOP.




  APPEND LINES OF lt_functtran TO et_functtran.
  SORT et_functtran BY functionid tcode.
  DELETE ADJACENT DUPLICATES FROM et_functtran
                  COMPARING functionid tcode.

  APPEND LINES OF lt_faobj TO et_faobj.
  SORT et_faobj BY funid tcode object valueset field val_from val_to.
  DELETE ADJACENT DUPLICATES FROM et_faobj
         COMPARING funid tcode object valueset field val_from val_to.

  MESSAGE s208(00) WITH text-034.
  COMMIT WORK.
ENDFUNCTION.
