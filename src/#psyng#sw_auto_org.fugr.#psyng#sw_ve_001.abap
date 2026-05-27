FUNCTION /PSYNG/SW_VE_001.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_SYSID) TYPE  /PSYNG/RFCDEST OPTIONAL
*"     VALUE(IF_LOCAL_CONFIG) TYPE  FLAG DEFAULT ''
*"  TABLES
*"      IT_FAOBJ2 STRUCTURE  /PSYNG/FAOBJ2
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_VAREL STRUCTURE  /PSYNG/SW_VAREL OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VE_001'.
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

**  DATA : ls_authx TYPE authx,
**         ls_dd01v  TYPE dd01v,
**         l_objname TYPE ddobjname,
**         l_sysid TYPE rfcdest,
**         lt_syst_specific LIKE TABLE OF gt_varel WITH HEADER LINE.
**  DATA :
**  lt_elements LIKE TABLE OF gt_varel WITH HEADER LINE.
**
***--Check if SOD Matrix contains ANY variable elements
**  loop at IT_FAOBJ2 where val_from CP '/PSYNG/$*'.
**    exit.
**  endloop.
**  check sy-subrc = 0.
**  IF i_sysid IS INITIAL.
***--Assume local system
**    CONCATENATE sy-sysid sy-mandt INTO l_sysid.
**  ELSE.
**    l_sysid = i_sysid.
**  ENDIF.
**  if IF_LOCAL_CONFIG  = 'X'.
***--Read the local variable elements
**    SELECT * FROM /psyng/sw_varel                    "#EC CI_NOFIRST
**                                                     "#EC CI_NOWHERE
**    INTO CORRESPONDING FIELDS OF TABLE gt_varel.
**  else.
***--The variable elements were passed from the server
***    delete it_varel where sysid <> '' and sysid <> l_sysid.
**    gt_varel[] = it_varel[].
**  endif.
**
**
**
***--Remove any values from the definition that are not used
***  in this SOD Matrix
**  SORT it_faobj2 BY field val_from.
**  LOOP AT gt_varel.
**    READ TABLE it_faobj2 WITH KEY
**      field    = gt_varel-element
**      val_from = gt_varel-var_element
**      BINARY SEARCH TRANSPORTING NO FIELDS.
**    IF sy-subrc = 0.
**      APPEND gt_varel TO lt_elements.
**    ENDIF.
**  ENDLOOP.
**  gt_varel[] = lt_elements[].
**
**  SORT lt_elements BY var_element.
**  DELETE ADJACENT DUPLICATES FROM lt_elements COMPARING var_element.
**
**  LOOP AT lt_elements.
**    SELECT SINGLE * FROM authx INTO ls_authx
**    WHERE fieldname = lt_elements-element.
**    IF ls_authx-checktable IS INITIAL.
**      l_objname = lt_elements-element.
**      CALL FUNCTION 'DDIF_DOMA_GET'
**           EXPORTING
**                name          = l_objname
**           IMPORTING
**                dd01v_wa      = ls_dd01v
**           EXCEPTIONS
**                illegal_input = 1
**                OTHERS        = 2.
**      IF sy-subrc <> 0.
**        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**      ENDIF.
**      ls_authx-checktable = ls_dd01v-entitytab.
**    ENDIF.
**    IF ls_authx-checktable IS INITIAL.
**      log et_return 'E'
**                    'No check table found for '
**                    lt_elements-var_element
**                    lt_elements-element '' ''.
**    ELSE.
***--Get records corresponding to the rule.
**      PERFORM get_values TABLES gt_varel
**                                et_return
**                                it_faobj2
**                         USING  lt_elements
**                                ls_authx-checktable.
**    ENDIF.
**  ENDLOOP.
**
**  SORT IT_FAOBJ2 BY funid tcode object field val_from val_to.

ENDFUNCTION.
