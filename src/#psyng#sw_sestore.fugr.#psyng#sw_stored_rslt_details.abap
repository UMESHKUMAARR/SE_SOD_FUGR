FUNCTION /psyng/sw_stored_rslt_details.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_AID) TYPE  /PSYNG/SERESID OPTIONAL
*"     VALUE(I_ROLE_AID) TYPE  /PSYNG/SERRSID OPTIONAL
*"     VALUE(IF_ROLE) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_RESULTSET STRUCTURE  /PSYNG/SWRESHDR OPTIONAL
*"      IT_ROLE_RESULTSET STRUCTURE  /PSYNG/SWRRSHDR OPTIONAL
*"----------------------------------------------------------------------



*CREATE OBJECT gr_event_handler_sys.
  IF if_role IS INITIAL.
    gt_swreshdr[] = it_resultset[].
    IF NOT gt_swreshdr[] IS INITIAL.
      CALL SCREEN 100 STARTING AT 15 1.
    ENDIF.
  ELSE.
    gt_swrrshdr[] = it_role_resultset[].
    IF NOT gt_swrrshdr[] IS INITIAL.
      CALL SCREEN 200 STARTING AT 15 1.
    ENDIF.
  ENDIF.

ENDFUNCTION.
