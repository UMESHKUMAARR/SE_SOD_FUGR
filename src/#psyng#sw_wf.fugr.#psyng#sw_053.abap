FUNCTION /psyng/sw_053.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      AC_CONTAINER STRUCTURE  SWCONT OPTIONAL
*"      ACTOR_TAB STRUCTURE  SWHACTOR OPTIONAL
*"----------------------------------------------------------------------
DATA: l_contid  TYPE /psyng/mcauditor-contid,
      l_auditor TYPE /psyng/mcauditor-auditor.


  actor_tab-otype = 'US'.

  READ TABLE ac_container WITH KEY element = 'MITCONTID'.
  l_contid = ac_container-value.

  CLEAR ac_container.
  READ TABLE ac_container WITH KEY element = 'AUDITOR'.

  IF NOT ac_container-value IS INITIAL.
    actor_tab-objid = ac_container-value.
    APPEND actor_tab.
  ELSE.
    SELECT auditor INTO l_auditor FROM /psyng/mcauditor
           WHERE contid = l_contid.

      actor_tab-objid = l_auditor.
      APPEND actor_tab.
    ENDSELECT.
  ENDIF.
ENDFUNCTION.
