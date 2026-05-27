FUNCTION /psyng/sw_mc_justification.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_HEADER) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ASSIGNMENT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SIGNOFF) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ADD) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LIST) TYPE  FLAG OPTIONAL
*"     VALUE(IF_DELETE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(I_MCID) TYPE  /PSYNG/CONTID OPTIONAL
*"     VALUE(IS_ASSIGNMENT) TYPE  /PSYNG/MITIGATION_ASSIGNMENT OPTIONAL
*"     VALUE(IS_SIGNOFF) TYPE  /PSYNG/MCRVWSGN OPTIONAL
*"     VALUE(I_JUSTIFICATION_TEXT) TYPE  STRING OPTIONAL
*"     VALUE(I_BNAME) TYPE  XUBNAME DEFAULT SY-UNAME
*"  EXPORTING
*"     VALUE(EF_HAS_JUSTIFICATION) TYPE  FLAG
*"     VALUE(E_NR_JUSTIFICATION) TYPE  SYTFILL
*"  TABLES
*"      ET_LIST STRUCTURE  /PSYNG/MCRVWTXT OPTIONAL
*"      ET_DETAILS STRUCTURE  /PSYNG/MCRVWTXT OPTIONAL
*"      IT_TEXT STRUCTURE  SOLISTI1 OPTIONAL
*"  EXCEPTIONS
*"      INVALID_INPUT
*"      NOT_IMPLEMENTED
*"      GOS_FAILURE
*"----------------------------------------------------------------------
  DATA : l_check_count TYPE i,
         o_att_mgr      TYPE REF TO cl_gos_manager,
         ls_obj         TYPE borident,
*         l_service      TYPE sgs_srvnam,
         lt_texts       TYPE TABLE OF solisti1 WITH HEADER LINE,
         lt_revwtxt     TYPE TABLE OF /psyng/mcrvwtxt WITH HEADER LINE,
         l_key          TYPE string.
* BOC by RGUPTA on 08.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
  IF i_bname IS INITIAL.
    i_bname = l_current_user. "sy-uname. C0700
  ENDIF.
*--Domain /PSYNG/SW_MITIGATION_TYPE
*1  Mitigation assignment to user
*2  Mitigation assignment to user group
*3  Mitigation assignment to user for critical auth
*4  Mitigation assignment to role
*5  Mitigation assignment to role for critical auth

  DEFINE check_1_of_3.
*--Macro to check if only 1 of 3 flags are provided
    clear: l_check_count.
    if &1 = 'X'. add 1 to l_check_count. endif.
    if &2 = 'X'. add 1 to l_check_count. endif.
    if &3 = 'X'. add 1 to l_check_count. endif.
    if l_check_count > 1.
      message e002(/psyng/sw) with &4 &5
      raising invalid_input.
    endif.
  END-OF-DEFINITION.
*--Validate input parameters
*  Only one of IF_HEADER,IF_ASSIGNMENT and IF_SIGNOFF can be selected.
  check_1_of_3 if_header if_assignment if_signoff
 'Only select 1 of the options' 'IF_HEADER,IF_ASSIGNMENT and IF_SIGNOF'.
*  Only one of IF_LIST, IF_ADD and IF_CHECK can be selected.
  check_1_of_3 if_list if_add if_check
  'Only select 1 of the options' 'F_LIST, IF_ADD and IF_CHECK'.
  ls_obj-objtype = '/PSYNG/SEM'.
*--Create the object ID based on the input data
  PERFORM create_obj_id
    USING
      i_mcid
      if_header
      if_assignment
      if_signoff
      is_assignment
      is_signoff
    CHANGING
      ls_obj-objkey.
  IF if_check = 'X'.
*--Check if justificatiuon texts are created
    SELECT SINGLE  COUNT( * )
    INTO e_nr_justification
    FROM /psyng/mcrvwtxt
    WHERE
      objectid = ls_obj-objkey AND line = '00001'.
    IF e_nr_justification > 0.
      ef_has_justification = 'X'.
    ENDIF.
  ELSE.
    CASE 'X'.
      WHEN if_list.
*--Export a list of unique justifications and all details
        SELECT * FROM /psyng/mcrvwtxt INTO TABLE et_details
          WHERE objectid = ls_obj-objkey.
        et_list[] = et_details[].
        SORT et_list BY
          createuser
          createdate
          createtime.
        DELETE ADJACENT DUPLICATES FROM et_list COMPARING
          createuser
          createdate
          createtime.
      WHEN if_add.
*  --Add Justification
        IF NOT i_justification_text IS INITIAL.
*--Convert the string to a table of 255 character long strings
          CALL FUNCTION '/PSYNG/BC_034'
            EXPORTING
              i_text         = i_justification_text
            TABLES
              et_texts       = lt_texts.
          APPEND LINES OF lt_texts TO it_text.
        ENDIF.
        lt_revwtxt-objectid   = ls_obj-objkey.
        lt_revwtxt-createuser = i_bname.
        lt_revwtxt-createdate = sy-datum.
        lt_revwtxt-createtime = sy-uzeit.
        lt_revwtxt-line       = 0.
        LOOP AT it_text.
          ADD 1 TO lt_revwtxt-line.
          lt_revwtxt-text = it_text-line.
          APPEND lt_revwtxt.
        ENDLOOP.
        MODIFY /psyng/mcrvwtxt FROM TABLE lt_revwtxt.
        COMMIT WORK.

      WHEN if_delete.
*        CONDENSE ls_obj-objkey.
        DELETE FROM /psyng/mcrvwtxt WHERE
             objectid = ls_obj-objkey.
        COMMIT WORK.
    ENDCASE.
  ENDIF.
ENDFUNCTION.
