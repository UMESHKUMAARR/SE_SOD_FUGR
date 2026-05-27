*----------------------------------------------------------------------*
* Function Module :  /PSYNG/SW_048                                     *
* AUTHOR  : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

FUNCTION /PSYNG/SW_048.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(OBJECT) LIKE  TOBJ-OBJCT DEFAULT 'S_USER_GRP'
*"     VALUE(AKTPS) DEFAULT 'A'
*"  TABLES
*"      VALUES STRUCTURE  USREF
*"      AUTHS STRUCTURE  USREF
*"----------------------------------------------------------------------
refresh : AUTHS[].
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*!!! this is currently only written for 1 FIELD at a time!!!
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
data : lt_ust12 type table of ust12,
       lt_ust12_2 type table of ust12,
       l_idx_start like sy-tabix,
       l_idx_stop like sy-tabix,
       l_idx like sy-tabix,
       lf_value(50),
       if_value(50),
       next_field type xuobject,
       lt_compare TYPE TABLE OF /psyng/auth_compare,
       lt_compare_no_auth TYPE TABLE OF /psyng/auth_compare,
       ls_compare type /psyng/auth_compare,
       ls_auth type usref,
       ls_field type xufield,
       ls_obj type typ_obj_field.
field-symbols : <comp> type   /psyng/auth_compare,
                <comp2> type   /psyng/auth_compare,
                <val>  type   usref,
                <ust12> type ust12.
*--get field and object
read table values assigning <val> index 1.
CHECK SY-subrc = 0. "otherwise values is empty
ls_obj-field = <val>-field.
ls_obj-object = <val>-object.
*--Get all auths for object
refresh : lt_ust12[].
read table gt_objs with key
object = ls_obj-object field = ls_obj-field transporting no fields.
if sy-subrc = 0.
*- already loaded data from ust12 for this object,
*  copy those lines to local table
  MOVE ls_obj-field TO lf_value.
  CALL FUNCTION '/PSYNG/BC_GET_NEXT_CHAR'
       EXPORTING
            if_value            = lf_value
       IMPORTING
            ef_value            = if_value
*            ef_foundone         = lf_foundone
       EXCEPTIONS
            value_over_50_chars = 1
            OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
.
  move if_value to next_field.
  read table gt_ust12 with key objct = ls_obj-object
  field = ls_obj-field
  binary search transporting no fields.
  l_idx_start = sy-tabix.

  read table gt_ust12 with key objct = ls_obj-object
  field = next_field
  binary search transporting no fields.
  l_idx_stop = sy-tabix.
  IF l_idx_stop GT 1.
    l_idx_stop = l_idx_stop - 1.
  ENDIF.

  append lines of gt_ust12 from l_idx_start to l_idx_stop to lt_ust12.
else.
*DHORIONS 20101230
*   SELECT * FROM ust12 appending table lt_ust12
*         for all entries in gt_unique_userauths
*         WHERE OBJCT = ls_obj-OBJECT
*         AND   auth  = gt_unique_userauths-auth
*         AND   field = ls_obj-field
*         AND   AKTPS = AKTPS.
   SELECT * FROM ust12          "#EC CI_IMUD_NESTED
       appending table lt_ust12
         WHERE OBJCT = ls_obj-OBJECT
         AND   field = ls_obj-field
         AND   AKTPS = AKTPS.
if gt_unique_userauths[] is initial.
     append lines of lt_ust12 to gt_ust12.
else.
    loop at lt_ust12 assigning <ust12>.
        read table gt_unique_userauths
        with table key auth = <ust12>-auth
        transporting no fields.
        if sy-subrc = 0.
          append <ust12> to gt_ust12.
          append <ust12> to lt_ust12_2.
*        else.
*          delete lt_ust12 where auth = <ust12>-auth.
        endif.

    endloop.
    lt_ust12[] = lt_ust12_2[].
endif.
     sort gt_ust12 by objct field.
     append ls_obj to gt_objs.
endif.

*--determine how many comparisons have to be executed.
*--for memory reasons, if there are more than 10 million, we will use
*  an SAP function module which is slower but uses less memory
data : l_vals type i,
       l_auths type i,
       l_comparisons type i.
describe table values lines l_vals.
describe table lt_ust12 lines l_auths.
l_comparisons = l_vals * l_auths.
*dhorions 20130527 : increased limit
* this fm is only called from fm sw_047, which is only called when
* checking for obsolete mitigations
if l_comparisons > '10000000'.
  free : lt_ust12.
  CALL FUNCTION 'SUSR_GET_AUTHS_WITH_SPEC_VALS'
       EXPORTING
            object                  = object
            srchtype                = 'OR'
            aktps                   = 'A'
       IMPORTING
            number_of_auths         = l_auths
       TABLES
            values                  = values
            auths                   = auths
       EXCEPTIONS
            parameter_error         = 1
            object_doesnt_exist     = 2
            not_authorized_for_auth = 3
            OTHERS                  = 4. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

else.
*--get all auths that match values provided in table VALUES
loop at values assigning <val>.
  ls_compare-sod_from = <val>-von.
  ls_compare-sod_to   = <val>-bis.
  if ls_compare-sod_from = ls_compare-sod_to.
    clear ls_compare-sod_to.
  endif.
  loop at lt_ust12 assigning <ust12>.
    ls_compare-auth      = <ust12>-auth.
    ls_compare-auth_from = <ust12>-von.
    ls_compare-auth_to   = <ust12>-bis.
  if ls_compare-sod_to is initial  AND
     <ust12>-bis       is initial  AND
      ls_compare-sod_from NS '*'   AND
      <ust12>-von NS '*'            .
*--if there are no ranges, a simple compare will suffice
     if ls_compare-sod_from = <ust12>-von .
        ls_auth-object = object.
        ls_auth-auth   = <ust12>-auth.
        append ls_auth to auths.
     endif.
  else.
*--An "*" in SOD From, is also a simple compare
*  This only matches '*' in an authorization
    if ls_compare-sod_from EQ '*'.
       IF ls_compare-auth_from EQ '*'.
          ls_auth-object = object.
          ls_auth-auth   = <ust12>-auth.
          append ls_auth to auths.
       endif.
    else.
      append ls_compare to lt_compare.
    endif.
  endif.
  endloop.
endloop.
  lt_compare_no_auth[] = lt_compare[].


  sort lt_compare_no_auth by sod_from sod_to auth_from auth_to auth.
  delete adjacent duplicates from lt_compare_no_auth
  comparing sod_from sod_to auth_from auth_to.
*  CALL FUNCTION '/PSYNG/SW_021'
   CALL FUNCTION '/PSYNG/SW_COMPARE_RANGES'
   EXPORTING
     I_BUFFER_SIZE    = 50000
   TABLES
     IT_COMPARE       = lt_compare_no_auth.
sort lt_compare_no_auth by match.
delete lt_compare_no_auth where match <> 'X'.

sort lt_compare by sod_from sod_to auth_from auth_to auth.

ls_auth-object = ls_obj-object.
*ls_auth-field = ls_obj-field.
loop at lt_compare_no_auth assigning <comp>.
  read table lt_compare assigning <comp2>
                                 with key sod_from = <comp>-sod_from
                                 sod_to   = <comp>-sod_to
                                 auth_from = <comp>-auth_from
                                 auth_to   = <comp>-auth_to
                                 binary search.
   check sy-subrc = 0.
   l_idx = sy-tabix.
   ls_auth-auth = <comp2>-auth.
   append ls_auth to auths.
   add 1 to l_idx.
   loop at lt_compare assigning <comp2> from l_idx where
             sod_from = <comp>-sod_from AND
             sod_to   = <comp>-sod_to AND
             auth_from = <comp>-auth_from AND
             auth_to   = <comp>-auth_to.
   ls_auth-auth = <comp2>-auth.
   append ls_auth to auths.
   endloop.
endloop.
sort auths by auth.
delete adjacent duplicates from auths comparing auth.
refresh : lt_compare[], lt_compare_no_auth[].
endif.
ENDFUNCTION.
