FUNCTION /PSYNG/SW_VE_SAVE.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      IT_VE_VALUES STRUCTURE  /PSYNG/SWCFGVE OPTIONAL
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

  SORT it_ve_values by setid VAR_ELEMENT SYSID value.
  delete adjacent duplicates from it_ve_values comparing
  setid VAR_ELEMENT SYSID value.
*--delete old values
  DELETE from /psyng/swcfgve WHERE setid = i_setid.
  COMMIT WORK.
*--save the new values
  it_ve_values-setid = i_setid.
  modify it_ve_values transporting setid where setid <> i_setid.
  INSERT /psyng/swcfgve FROM TABLE it_ve_values.
  COMMIT WORK.


ENDFUNCTION.
