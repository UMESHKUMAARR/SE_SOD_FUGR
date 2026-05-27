FUNCTION /psyng/sw_mc_pending_in_sp.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      IT_ASSIGNMENTS STRUCTURE  /PSYNG/MCUSER
*"      ET_SP_PENDING STRUCTURE  /PSYNG/MCUSER
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_MC_PENDING_IN_SP'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  CONSTANTS : lc_tabreqstcnfl TYPE tabname VALUE '/PSYNG/REQSTCNFL',
              lc_tabreqstupdt TYPE tabname VALUE '/PSYNG/REQSTUPDT',
              lc_tabspconfig  TYPE tabname VALUE '/PSYNG/SPCONFIG'.
  DATA : lt_assignments TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
         lf_sp_installed TYPE flag,
         BEGIN OF lt_requests OCCURS 0,
           requestid    TYPE /psyng/reqid,
           bname        TYPE xubname,
         END OF lt_requests,
         BEGIN OF lt_sp_mit OCCURS 0,
           requestid TYPE /psyng/reqid,
           conid     TYPE /psyng/conflict_id,
           contid    TYPE /psyng/contid,
         END OF lt_sp_mit,
         l_sp_vrsio(255) TYPE  c,
         l_vrsio   TYPE /psyng/sodvrsio.
  CHECK NOT it_assignments[] IS INITIAL.
*--If SP is not installed, no assignments are pending in SP
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module    = 'SP'
       IMPORTING
            e_installed = lf_sp_installed.
  CHECK lf_sp_installed = 'X'.

*--Only mitigation assignments that relate to the SOD Matrix version
* configured in SP can be pending
  lt_assignments[] = it_assignments[].
  SELECT SINGLE value INTO l_sp_vrsio FROM (lc_tabspconfig)
    WHERE param = 'SAP_DFLT_SOD_VERSION'."#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  IF sy-subrc = 0.
    l_vrsio = l_sp_vrsio.
  ENDIF.
  DELETE lt_assignments WHERE vrsio <> l_vrsio.
  CHECK NOT lt_assignments[] IS INITIAL.

*--Get all pending requests for the users
* in the mitigation assignment table

  SELECT requestid newuserid AS bname
  INTO TABLE lt_requests
  FROM (lc_tabreqstupdt) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  FOR ALL ENTRIES IN lt_assignments
  WHERE
    ( appl     = 'SAP' OR appl = '' )
    AND
    newuserid  = lt_assignments-userid AND
    status     = 0 AND
    rqststatus <> 'Approved'.


  CHECK NOT lt_requests[] IS INITIAL.
*--There are pending requests, check if they have mitigations assigned
  SELECT requestid conid mitigateid AS contid
    FROM (lc_tabreqstcnfl) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
  INTO TABLE lt_sp_mit
  FOR ALL ENTRIES IN lt_requests WHERE
    requestid = lt_requests-requestid AND
    status    = '0' AND
    mitigateid    <> ''.
  CHECK NOT lt_sp_mit[] IS INITIAL.

  SORT lt_requests BY bname.
  SORT lt_sp_mit BY requestid conid contid.
  LOOP AT lt_assignments.
*--Check all requests for this user for assigned mitigations
    READ TABLE lt_requests WITH KEY bname = lt_assignments-userid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    LOOP AT lt_requests FROM sy-tabix.
      IF lt_requests-bname <> lt_assignments-userid.
        EXIT.
      ENDIF.
      READ TABLE lt_sp_mit WITH KEY requestid = lt_requests-requestid
                                    conid     = lt_assignments-conid
                                    contid    = lt_assignments-contid
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
*--A request is pending in SP for this mitigation
        APPEND lt_assignments TO et_sp_pending.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

  SORT et_sp_pending.
  DELETE ADJACENT DUPLICATES FROM et_sp_pending.
ENDFUNCTION.
