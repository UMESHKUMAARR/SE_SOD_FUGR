*----------------------------------------------------------------------*
* Function Module :  /PSYNG/SW_047                                     *
* AUTHOR  : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

FUNCTION /PSYNG/SW_073.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_DETAILS) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_UPDTSCANTBLE) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_ENHANCE) TYPE  FLAG DEFAULT ''
*"     VALUE(I_SHONOCAUTH) TYPE  FLAG DEFAULT ''
*"     VALUE(I_COMPOSITE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SINGLE_ROLES) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     VALUE(O_NR_ROLES_ANALYZED) TYPE  I
*"  TABLES
*"      IT_SWAUDID STRUCTURE  /PSYNG/RANGE_SWAUDID OPTIONAL
*"      O_OUTPUT STRUCTURE  /PSYNG/SW_CA_ROUTPUT OPTIONAL
*"      O_OUTPUTDET STRUCTURE  /PSYNG/SW_CA_ROUTPUTDET OPTIONAL
*"      IT_AGR_NAME STRUCTURE  /PSYNG/RANGE_AGR_NAME OPTIONAL
*"      IT_SWAUDC STRUCTURE  /PSYNG/SWAUDC2 OPTIONAL
*"      IT_SWAUDHDR STRUCTURE  /PSYNG/SWAUDHDR OPTIONAL
*"----------------------------------------------------------------------

*--> BOC PN 11269 - ATC fixes - HBHALLA - 21/01/25
    CONSTANTS: lc_fname TYPE rs38l_fnam
    VALUE '/PSYNG/SW_073'.
*  S_RFC AUTHORITY CHECK
    AUTHORITY-CHECK OBJECT 'S_RFC'
          ID 'RFC_TYPE' FIELD 'FUNC'
          ID 'RFC_NAME' FIELD lc_fname
          ID 'ACTVT' FIELD '16'.
    IF sy-subrc <> 0.
      MESSAGE e089(/psyng/sw) WITH lc_fname.
    ENDIF.

*--> EOC PN 11269 - ATC fixes - HBHALLA - 21/01/25

  data : l_numres type i,
         l_msg type string,
         lf_local_ca type flag.

  g_vrsio      = i_vrsio.
  gf_details   = i_details.
  gf_enhanced  = I_ENHANCE.
  PERFORM refresh_internal_tables .

  MESSAGE s113(/psyng/sw) WITH
  'Loading roles'(017).
  COMMIT WORK.
  if IT_SWAUDC[] is initial and IT_SWAUDHDR[] is initial.
* if critical auths content is not passed to fm, load from local db
    lf_local_ca = 'X'.
  else.
    clear lf_local_ca.
  endif.
  PERFORM get_critical_auth_data TABLES it_swaudid
                                        IT_SWAUDC
                                        IT_SWAUDHDR
                                 USING  I_ENHANCE
                                        lf_local_ca
                                        ''.

  PERFORM get_roles TABLES IT_AGR_NAME
  using   i_composite_roles
          i_single_roles.
  perform get_roles_data.
*--DHORIONS : limit system auths.
  data : ls_auth type usrbf2.
  loop at roleauth.
    ls_auth-auth = roleauth-auth.
    insert ls_auth into table gt_unique_userauths.
  endloop.
  if not gt_unique_userauths[] is initial.
    PERFORM get_system_auths.
  endif.
  PERFORM compare_role_auths_with_system.
  sort gt_routput.
  delete adjacent duplicates from gt_routput.
  if i_shonocauth = 'X'.
    perform report_roles_without_cauth.
  endif.

  o_output[] = gt_routput[].
  o_outputdet[] = gt_routputdet[].

sort gt_routput by agr_name.
delete adjacent duplicates from gt_routput comparing agr_name.

*--Get the role names
data : lt_agr_names type table of agr_texts with header line.
if not gt_routput[] is initial.
  select agr_name text from agr_texts into
  corresponding fields of  table lt_agr_names
  for all entries in gt_routput
  where
  agr_name = gt_routput-agr_name and
  spras = sy-langu and
  line < 1.
endif.
free gt_routput.

loop at lt_agr_names.
  o_output-agr_text = lt_agr_names-text.
  modify o_output
  transporting agr_text
  where agr_name = lt_agr_names-agr_name.
endloop.

  describe table gt_roles lines o_nr_roles_analyzed.
  describe table o_output lines l_numres.
  MESSAGE s113(/psyng/sw) WITH
  'Analyzed'(015) O_NR_ROLES_ANALYZED ' roles'(018).
  MESSAGE s113(/psyng/sw) WITH
  'Found'(013) l_numres ' Critical Auths.'(014).
ENDFUNCTION.
