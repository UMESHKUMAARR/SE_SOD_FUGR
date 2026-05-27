FUNCTION /psyng/sw_odata_text.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_HASHCODE) TYPE  XUPNAME
*"     VALUE(IF_SHOW_MESSAGE) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_NAME) TYPE  SOBJ_NAME
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------

  DATA: l_version TYPE string,
        l_textline1 TYPE string,
        l_textline2 TYPE string.
  SELECT obj_name
    FROM usobhash
    INTO e_name
    UP TO 1 ROWS
    WHERE name EQ i_hashcode."#EC SAST_CI_GEN_CHECK
  ENDSELECT.

  IF sy-subrc EQ 0.
    SPLIT e_name AT space INTO e_name l_version.
    IF NOT if_show_message IS INITIAL.
      CONCATENATE 'Hash Key'(t23) i_hashcode INTO l_textline1
      SEPARATED BY ' : '.
      CONCATENATE 'Odata Service Name'(t24) e_name INTO l_textline2
      SEPARATED BY ' : '.
      CALL FUNCTION 'POPUP_CONTINUE_YES_NO'
        EXPORTING
          textline1           = l_textline1
          textline2           = l_textline2
          titel               = 'Odata Service Information'(t22).
    ENDIF.
  ELSE.
*##RAISE_OK
    MESSAGE i002(/psyng/sw) WITH text-t25 RAISING not_found.
  ENDIF.

ENDFUNCTION.
