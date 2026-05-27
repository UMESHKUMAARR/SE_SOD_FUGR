FUNCTION /psyng/sw_display_object.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_OBJECTTYPE) TYPE  SLIS_FIELDNAME
*"     REFERENCE(I_OBJECTID) TYPE  SLIS_ENTRY
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"----------------------------------------------------------------------
  DATA : l_sodvrsio TYPE /psyng/sodvrsio,
         g_dynnr    TYPE sy-dynnr,
         l_parva_exists type sy-subrc.
* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
  AUTHORITY-CHECK OBJECT 'S_TCODE'
           ID 'TCD' FIELD '/PSYNG/SE'.
  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH 'execute Transaction /PSYNG/SE'(e01).

  ELSE.

    CASE i_objecttype.
      WHEN 'CONID' OR 'L_CONID'.
        SET PARAMETER ID '/PSYNG/CON'    FIELD i_objectid.
        g_dynnr = '0202'.
      WHEN 'FUNCTIONID' OR 'L_FUNCTIONID'.
        SET PARAMETER ID '/PSYNG/FUN'    FIELD i_objectid.
        g_dynnr = '0201'.
      WHEN 'CONTID'.
        SET PARAMETER ID '/PSYNG/SW_MIT' FIELD i_objectid.
        g_dynnr = '0211'.
    ENDCASE.

    PERFORM get_default_sodversion USING l_current_user "sy-uname C0700
           CHANGING l_sodvrsio l_parva_exists.
    PERFORM set_default_sodversion USING i_vrsio l_current_user "C0700
           0.
    EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.

    IF sy-subrc <> 0.
* Implement a suitable exception handling here
    ENDIF.

    CALL TRANSACTION '/PSYNG/SE'.
    PERFORM set_default_sodversion USING l_sodvrsio l_current_user "C0700
           l_parva_exists.

  ENDIF.


ENDFUNCTION.
