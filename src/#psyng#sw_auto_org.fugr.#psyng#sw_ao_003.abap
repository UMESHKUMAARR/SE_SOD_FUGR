FUNCTION /PSYNG/SW_AO_003 .
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_SODVRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(I_UPDATE_TABLE) TYPE  FLAG OPTIONAL
*"     VALUE(I_CLEAR_TABLE) TYPE  FLAG OPTIONAL
*"  TABLES
*"      ET_SWSODORGM STRUCTURE  /PSYNG/SWSODORGM
*"      IT_SWSODORGM STRUCTURE  /PSYNG/SWSODORGM
*"      IT_RFCDES STRUCTURE  RFCDES OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_003'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

data : lt_varbls type table of /PSYNG/ORGFIELD with header line,
       lt_tobj  type table of tobj with header line,
       lt_faobj  TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
       lt_tobj_all type table of tobj with header line,
       l_idx like sy-tabix,
       lt_varbls_all  TYPE TABLE OF /psyng/orgfield WITH HEADER LINE.

SELECT DISTINCT object FROM /psyng/faobj2
INTO CORRESPONDING FIELDS OF TABLE lt_faobj
WHERE vrsio = i_sodvrsio.

*--Parse Matrix on all systems
  LOOP AT it_rfcdes.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.


  CALL FUNCTION '/PSYNG/SW_AO_002'
    DESTINATION it_rfcdes-rfcdest
    EXPORTING
      i_sodvrsio      = I_SODVRSIO
   TABLES
     IT_FAOBJ         = lt_faobj
     ET_VARBLS        = lt_varbls
     ET_TOBJ          = lt_tobj
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
     CASE sy-subrc.
        WHEN 1.
           MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
        WHEN 2.
           MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
        WHEN OTHERS.
           MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
      ENDCASE.
   ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    APPEND LINES OF lt_varbls TO lt_varbls_all.
    append lines of lt_tobj to lt_tobj_all.
    REFRESH : lt_varbls, lt_tobj.
  ENDLOOP.

SORT lt_varbls_all.
DELETE ADJACENT DUPLICATES FROM lt_varbls_all.
lt_varbls[] = lt_varbls_all[].
free : lt_varbls_all.
SORT lt_tobj_all.
DELETE ADJACENT DUPLICATES FROM lt_tobj_all.
lt_tobj[] = lt_tobj_all[].
free : lt_tobj_all.


sort lt_tobj by fiel1 objct.
sort IT_SWSODORGM by varbl.
loop at IT_SWSODORGM.
  read table lt_tobj with key fiel1 = IT_SWSODORGM-varbl.
  if sy-subrc = 0.
    l_idx = sy-tabix.
    ET_SWSODORGM = IT_SWSODORGM.
    loop at lt_tobj from sy-tabix where fiel1 = IT_SWSODORGM-varbl .
      ET_SWSODORGM-object = lt_tobj-objct.
      append ET_SWSODORGM.
    endloop.
  endif.
endloop.


if I_UPDATE_TABLE = 'X'.
  if I_CLEAR_TABLE = 'X'.
    delete from /PSYNG/SWSODORGM where ABB <> '' or abb = ''.
    commit work.
  endif.
  modify /PSYNG/SWSODORGM from table ET_SWSODORGM.
endif.

ENDFUNCTION.
