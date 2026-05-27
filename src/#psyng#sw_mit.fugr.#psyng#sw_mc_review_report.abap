FUNCTION /psyng/sw_mc_review_report.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_UNREVIEWED) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_AUTOREVIEWED) TYPE  FLAG DEFAULT ''
*"     VALUE(IF_MANREVIEWED) TYPE  FLAG DEFAULT ''
*"     VALUE(I_BNAME) TYPE  XUBNAME DEFAULT SY-UNAME
*"  TABLES
*"      IT_AUDITOR STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_PERIOD STRUCTURE  /PSYNG/SW_SEL_OPTS_DATE OPTIONAL
*"      IT_SODUSER STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_CAUSER STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_SODROLE STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_CAROLE STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_VERSIONS STRUCTURE  /PSYNG/RANGE_VRSIO OPTIONAL
*"      IT_SIGNOFFID STRUCTURE  /PSYNG/RANGE_MC_SINGOFFID OPTIONAL
*"      IT_CONTID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      ET_SUMMARY STRUCTURE  /PSYNG/MCRVWSGN OPTIONAL
*"      ET_DETAILS STRUCTURE  /PSYNG/SW_MC_REVIEW_REPORT OPTIONAL
*"----------------------------------------------------------------------

  DATA : lt_mcrvwsgn TYPE TABLE OF /psyng/mcrvwsgn WITH HEADER LINE,
         lf_reviewed_flag type flag,
         lf_unreviewed_flag type flag,
         lf_signoff_type_man type c,
         lf_signoff_type_aut type c.

*--Prepare some variables to use in Select Statement
  if if_unreviewed = 'X'.
    lf_unreviewed_flag = ''.
  else.
    lf_unreviewed_flag = '_'.
  endif.
  if IF_AUTOREVIEWED = 'X' or IF_MANREVIEWED = 'X'.
    lf_reviewed_flag = 'X'.
    if IF_AUTOREVIEWED = 'X'.
      lf_signoff_type_aut = 'A'.
    else.
      clear lf_signoff_type_aut.
    endif.
    if IF_MANREVIEWED = 'X'.
      lf_signoff_type_man = 'M'.
    else.
      clear lf_signoff_type_man.
    endif.
  else.
    lf_reviewed_flag = '_'.
  endif.
*--Select the appropriate records from the database
  SELECT * FROM /psyng/mcrvwsgn INTO TABLE lt_mcrvwsgn
    WHERE
          signoffid   in IT_SIGNOFFID AND
          auditor     IN it_auditor   AND
          vrsio       IN IT_VERSIONS  AND
          contid      IN it_contid    AND
          (
            from_date IN it_period OR
            to_date   IN it_period
          ) and
          (
            signoff_complete = lf_unreviewed_flag or
            (
              signoff_complete = lf_reviewed_flag and
              (
                signoff_type = lf_signoff_type_man  or
                signoff_type = lf_signoff_type_aut
              )
            )
          )
          and
          (
*--Type specific restrictions
             (
*    --    Restrict based on SOD user
               ( type = 1 OR type = 2 OR type = 4 )
               AND  userid IN it_soduser AND "#EC SAST_CI_GEN_CHECK
               userid <> ''
             )
             OR
             (
*    --    Restrict based on SOD CA
               ( type = 3 OR type = 5 )
               AND  userid IN it_causer AND
               userid <> ''
             )
             OR
             (
*    --    Restrict based on Role SOD
               ( type = 4 )
               AND  agr_name IN it_sodrole AND
               agr_name <> ''
             )
             OR
             (
*    --    Restrict based on Role CA
               ( type = 5 )
               AND  agr_name IN it_carole AND
               agr_name <> ''
             )
         )
         .

ET_SUMMARY[] = lt_mcrvwsgn[].
free : lt_mcrvwsgn.

perform prepare_review_report_details

  tables
    et_summary
    et_details
using
    I_BNAME
  .


ENDFUNCTION.
