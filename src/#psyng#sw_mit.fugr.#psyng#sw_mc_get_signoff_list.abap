FUNCTION /PSYNG/SW_MC_GET_SIGNOFF_LIST.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_SIGNOFF_INCOMPLETE) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_SIGNOFF_COMPLETE) TYPE  FLAG DEFAULT ''
*"     VALUE(IF_RETURN_AUDITOR_LIST) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_AUDITORS STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_MCID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      ET_SIGNOFFS STRUCTURE  /PSYNG/MCRVWSGN
*"      ET_AUDITOR_INFO STRUCTURE  /PSYNG/BC_USERID_NAME OPTIONAL
*"----------------------------------------------------------------------

ranges : lr_signoff_complete for IF_SIGNOFF_COMPLETE.
lr_signoff_complete-sign   = 'I'.
lr_signoff_complete-option = 'EQ'.
if IF_SIGNOFF_INCOMPLETE = 'X'.
  lr_signoff_complete-low    = ''.
  append lr_signoff_complete.
endif.
if IF_SIGNOFF_COMPLETE = 'X'.
  lr_signoff_complete-low    = 'X'.
  append lr_signoff_complete.
endif.

select * from /PSYNG/MCRVWSGN into table ET_SIGNOFFS
where auditor          in it_auditors and
      contid           in IT_MCID     and
      SIGNOFF_COMPLETE in lr_signoff_complete.



if IF_RETURN_AUDITOR_LIST = 'X'.
  loop at ET_SIGNOFFS.
    ET_AUDITOR_INFO-BNAME = ET_SIGNOFFS-auditor.
    collect et_auditor_info.
  endloop.
  check not et_auditor_info[] is initial.
  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
    TABLES
      username       = et_auditor_info
            .

endif.


ENDFUNCTION.
