FUNCTION /psyng/sw_ao_save.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      IT_ORG_VALUES STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
  DATA : ls_configset TYPE /psyng/swcfgset.
  ef_success = 'X'.
*--Validate the set exists
  SELECT SINGLE * FROM /psyng/swcfgset INTO ls_configset
  WHERE setid = i_setid.
  IF sy-subrc <> 0.
    log et_return 'E' 'INVALID_SET' 'Configuration Set' i_setid
                                    'does not exist.'
                                    ''.
    CLEAR ef_success.
  ELSE.
    IF ls_configset-published = 'X'.
      log et_return 'E' 'ALREADY_PUBLISHED'
                        'Saving not allowed for Published Set'
                        '' '' ''.
      CLEAR ef_success.
    ENDIF.
  ENDIF.

  CHECK ef_success = 'X'.

  SORT it_org_values.
* by setid abb varbl SYSID value.
  delete adjacent duplicates from it_org_values comparing
  ALL FIELDS.
*  setid abb varbl SYSID value.
*--delete old values
  DELETE from /psyng/swcfgoe WHERE setid = i_setid.
  COMMIT WORK.
*--save the new values
  it_org_values-setid = i_setid.
  modify it_org_values transporting setid where setid <> i_setid.
*  INSERT /psyng/swcfgoe FROM TABLE it_org_values.
  modify /psyng/swcfgoe FROM TABLE it_org_values.
  COMMIT WORK.


ENDFUNCTION.
