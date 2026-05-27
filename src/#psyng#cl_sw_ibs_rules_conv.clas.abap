class /PSYNG/CL_SW_IBS_RULES_CONV definition
  public
  inheriting from /PSYNG/CL_SW_RULESET_CONVSN
  final
  create public .

public section.
protected section.

  methods CONV_CONFLICT_DETAILS
    redefinition .
  methods CONV_CONFLICT_HEADER
    redefinition .
  methods CONV_CONFLICT_TEXT
    redefinition .
  methods CONV_FUNCTION_DETAILS
    redefinition .
  methods CONV_FUNCTION_HEADER
    redefinition .
  methods CONV_FUNCTION_TEXT
    redefinition .
  methods CONV_MATRIX_DETAILS
    redefinition .
  methods CONV_MATRIX_TEXT
    redefinition .
  methods CONV_PROBLEM_HEADER
    redefinition .
  methods CONV_PROBLEM_TEXT
    redefinition .
  methods CONV_PROCESS_HEADER
    redefinition .
  methods CONV_PROCESS_TEXT
    redefinition .
  methods CONV_SEARCH_RULE_DETAILS
    redefinition .
  methods CONV_SEARCH_RULE_HEADER
    redefinition .
  methods CONV_SEARCH_RULE_TEXT
    redefinition .
  methods CONV_MATRIX_HEADER
    redefinition .
private section.
ENDCLASS.



CLASS /PSYNG/CL_SW_IBS_RULES_CONV IMPLEMENTATION.


  method CONV_CONFLICT_DETAILS.
  endmethod.


 METHOD conv_conflict_header.

   DATA : converted_h   TYPE c,
          converted_d   TYPE c,
          converted_t   TYPE c,

*   ---------------------------- INTERNAL TABLES

          lt_conflict_h TYPE STANDARD TABLE OF /psyng/conflict,
          lt_conflict_d TYPE STANDARD TABLE OF /psyng/confdet,
          lt_gt_log     TYPE TABLE OF /psyng/sw_gt_log,
          ls_gt_log     TYPE /psyng/sw_gt_log,
          valid_log     TYPE TABLE OF /psyng/sw_gt_log,

*   ----------------------------   WORK AREA

          ls_conflict_h LIKE LINE OF lt_conflict_h,
          ls_conflict_d LIKE LINE OF lt_conflict_d,
          lt_conf_t     TYPE TABLE OF /psyng/sw_conf_t,
          ls_conf_t     TYPE /psyng/sw_conf_t.


   DATA : msg_var           TYPE symsgv,
          msg_key           TYPE string,
          l_index           TYPE sy-tabix,
          l_text            TYPE t100-text,
          lv_field          TYPE dd03d-fieldname,
          lv_value          TYPE t100-text,
          lv_objctid        TYPE t100-text,
          lf_locked         TYPE flag,
          l_locks           TYPE i,
          l_msg             TYPE string,
          l_answer          TYPE c,
          l_conid_added     TYPE c,
          l_conid_hdr_added TYPE c,
          l_conid_fun_added TYPE c,
          l_conid_txt_added TYPE c,
          l_conowner_added  TYPE c,
          l_conpmit_added   TYPE c,
          l_corg_added      TYPE c,
          lt_cont_part      TYPE TABLE OF /psyng/texts,
          lt_cond_part      TYPE TABLE OF /psyng/confdet,
          lt_cono_part      TYPE TABLE OF /psyng/conowner,
          lt_conpmit_part   TYPE TABLE OF /psyng/conpmit,
          l_conh_uploaded   TYPE i,
          l_cond_uploaded   TYPE i,
          l_cont_uploaded   TYPE i,
          l_cono_uploaded   TYPE i,
          l_conm_uploaded   TYPE i,
          l_syscon_uploaded TYPE i,
          l_corg_uploaded   TYPE i.

   DATA: sw_data_t TYPE STANDARD TABLE OF /psyng/texts,
         ls_data_t LIKE LINE OF sw_data_t.
* Local strurcture,tables, work area to capture risk id's
   TYPES : BEGIN OF ty_risk,
            risk_id    TYPE /PSYNG/RISK,
            severity   TYPE char1,
          END OF ty_risk.

   DATA : lt_risk TYPE STANDARD TABLE OF ty_risk,
          ls_risk TYPE ty_risk.

*   ----------------------------  FIELD SYMBOLS

   FIELD-SYMBOLS: <fs_meta_conf_h>   TYPE /psyng/sw_conf_h,
                  <fs_meta_conf_d>   TYPE /psyng/sw_conf_d,
                  <fs_conflict_h>    TYPE /psyng/conflict,
                  <fs_conflict_d>    TYPE /psyng/confdet,
                  <fs_risk>          TYPE ty_risk,
                  <fs_meta_prob_hdr> TYPE /psyng/sw_risk_h.
   FIELD-SYMBOLS : <meta_entry_t> TYPE /psyng/sw_conf_t,
                   <sw_entry_t>   TYPE /psyng/texts.

   CLEAR lt_conf_t[].
   SELECT * FROM /psyng/sw_conf_t INTO TABLE lt_conf_t
     WHERE lang = 'E'.
   ASSIGN ls_conflict_h  TO <fs_conflict_h>.

    ASSIGN ls_risk TO <fs_risk>.
    LOOP at full_data-problem_header ASSIGNING <fs_meta_prob_hdr>.
     <fs_risk>-risk_id = <fs_meta_prob_hdr>-risk_id.
     <fs_risk>-severity = <fs_meta_prob_hdr>-severity.
     APPEND <fs_risk> to lt_risk.
    ENDLOOP.

*   ---------------------------- CONFLICT-HEADER
   LOOP AT full_data-conflict_header ASSIGNING <fs_meta_conf_h>.

     <fs_conflict_h>-mandt = sy-mandt.
     <fs_conflict_h>-conid = <fs_meta_conf_h>-sod_conflict.
     <fs_conflict_h>-vrsio = p_vrsn.
     <fs_conflict_h>-create_usr = sy-uname.
     <fs_conflict_h>-create_dat = sy-datum.
     <fs_conflict_h>-create_tim = sy-uzeit.
     SORT lt_risk BY risk_id.
     CLEAR ls_risk.
     READ TABLE lt_risk INTO ls_risk
      WITH KEY risk_id = <fs_meta_conf_h>-risk_id
      BINARY SEARCH.
     IF sy-subrc EQ 0.
       IF ls_risk-severity EQ 1.
          <fs_conflict_h>-imp = 'CRITICAL'.
       ELSEIF ls_risk-severity EQ 2.
         <fs_conflict_h>-imp = 'HIGH'.
       ELSEIF ls_risk-severity EQ 3.
         <fs_conflict_h>-imp = 'MEDIUM'.
       ELSEIF ls_risk-severity EQ 4.
          <fs_conflict_h>-imp = 'LOW'.
       ENDIF.
     ENDIF.

     SORT lt_conf_t BY sod_conflict ASCENDING.
     READ TABLE lt_conf_t INTO ls_conf_t WITH
            KEY sod_conflict = <fs_meta_conf_h>-sod_conflict .
     <fs_conflict_h>-description = ls_conf_t-description.
     APPEND <fs_conflict_h> TO lt_conflict_h .
     CLEAR <fs_conflict_h>.
*     IF <fs_conflict_h> IS ASSIGNED.
*        UNASSIGN <fs_conflict_h>.
*     ENDIF.
   ENDLOOP.

*   ---------------------------- CONFLICT-DETAILS

   ASSIGN ls_conflict_d  TO <fs_conflict_d>.

   LOOP AT full_data-conflict_details ASSIGNING <fs_meta_conf_d>.

     <fs_conflict_d>-mandt = sy-mandt.
     <fs_conflict_d>-conid = <fs_meta_conf_d>-sod_conflict.
     <fs_conflict_d>-vrsio = p_vrsn.

     IF NOT <fs_meta_conf_d>-sod_function_1 IS INITIAL.
       <fs_conflict_d>-functionid = <fs_meta_conf_d>-sod_function_1.
       APPEND <fs_conflict_d> TO lt_conflict_d .
     ENDIF.

     IF NOT <fs_meta_conf_d>-sod_function_2 IS INITIAL.
       <fs_conflict_d>-functionid = <fs_meta_conf_d>-sod_function_2.
       APPEND <fs_conflict_d> TO lt_conflict_d .
     ENDIF.

     IF NOT <fs_meta_conf_d>-sod_function_3 IS INITIAL.
       <fs_conflict_d>-functionid = <fs_meta_conf_d>-sod_function_3.
       APPEND <fs_conflict_d> TO lt_conflict_d .
     ENDIF.

     IF NOT <fs_meta_conf_d>-sod_function_4 IS INITIAL.
       <fs_conflict_d>-functionid = <fs_meta_conf_d>-sod_function_4.
       APPEND <fs_conflict_d> TO lt_conflict_d .
     ENDIF.

     IF NOT <fs_meta_conf_d>-sod_function_5 IS INITIAL.
       <fs_conflict_d>-functionid = <fs_meta_conf_d>-sod_function_5.
       APPEND <fs_conflict_d> TO lt_conflict_d .
     ENDIF.

   ENDLOOP.

*   ---------------------------- CONFLICT-TEXT

   LOOP AT full_data-conflict_text ASSIGNING <meta_entry_t>.
     APPEND INITIAL LINE TO sw_data_t ASSIGNING <sw_entry_t>.

     <sw_entry_t>-mandt    = sy-mandt.
     <sw_entry_t>-textname = <meta_entry_t>-sod_conflict.
     <sw_entry_t>-object   = 'C'.
     <sw_entry_t>-spras    = <meta_entry_t>-lang.
*     <sw_entry_t>-LINE     = <meta_entry_t>-.
     <sw_entry_t>-vrsio    = p_vrsn.
     <sw_entry_t>-text    = <meta_entry_t>-description.

   ENDLOOP.

*   ---------------------------- DELETE ENTRIES

   SORT: lt_conflict_h, lt_conflict_d, sw_data_t.
   DELETE ADJACENT DUPLICATES FROM lt_conflict_h COMPARING ALL FIELDS.
   DELETE ADJACENT DUPLICATES FROM lt_conflict_d COMPARING ALL FIELDS.
   DELETE ADJACENT DUPLICATES FROM sw_data_t COMPARING ALL FIELDS.
   DELETE lt_conflict_h WHERE conid EQ space.
   DELETE lt_conflict_d WHERE conid EQ space.

*   ---------------------------- AUTHORITY-CHECK

   LOOP AT lt_conflict_h INTO ls_conflict_h.
     l_index = sy-tabix.
     AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
         ID 'ACTVT' FIELD 'UL'
         ID 'Y&SW_CONID' FIELD ls_conflict_h-conid
         ID 'Y&SW_VRSIO' FIELD p_vrsn.

     IF sy-subrc NE 0.
       CONCATENATE text-e14 text-006 INTO l_text.
       lv_field = ls_conflict_h-conid.
       lv_value = ls_conflict_h-description.


       me->log(
       EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFLICT'
                  i_type = 'E'
                  i_object = ''
                  i_object_id = ''
                  i_field = lv_field
                  i_value = lv_value
                  i_message = l_text
       IMPORTING  e_gt_log  = lt_gt_log
                  ).
       LOOP AT lt_gt_log INTO ls_gt_log.
         APPEND ls_gt_log TO gt_log.
         CLEAR: ls_gt_log.
       ENDLOOP.
       CLEAR: lt_gt_log.

       DELETE lt_conflict_h INDEX l_index.
       CLEAR: l_index,l_text.
     ENDIF.
   ENDLOOP.

   LOOP AT lt_conflict_d INTO ls_conflict_d.
     l_index = sy-tabix.
     AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
         ID 'ACTVT' FIELD 'UL'
         ID 'Y&SW_CONID' FIELD ls_conflict_d-conid
         ID 'Y&SW_VRSIO' FIELD p_vrsn.

     IF sy-subrc NE 0.
       CONCATENATE text-e14 text-006 INTO l_text.
       lv_field = ls_conflict_d-conid.
       lv_value = ls_conflict_d-functionid.


       me->log(
       EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFDET'
                  i_type = 'E'
                  i_object = ''
                  i_object_id = ''
                  i_field = lv_field
                  i_value = lv_value
                  i_message = l_text
       IMPORTING  e_gt_log  = lt_gt_log
                  ).
       LOOP AT lt_gt_log INTO ls_gt_log.
         APPEND ls_gt_log TO gt_log.
         CLEAR: ls_gt_log.
       ENDLOOP.
       CLEAR: lt_gt_log.

       DELETE lt_conflict_d INDEX l_index.
       CLEAR: l_index,l_text.
     ENDIF.
   ENDLOOP.

*   ---------------------------- UPLOAD DATA

   me->check_lock(
   EXPORTING
    i_object = 'CONFLICT'
    p_vrsn   =  p_vrsn
   CHANGING
     ef_locked = lf_locked
     e_locks   =   l_locks
                  ).
   l_msg = l_locks.
   CONCATENATE l_msg 'Conflict(s) are locked by other users'(l05)
   INTO l_msg SEPARATED BY space.
   IF lf_locked <> 'X'.
     l_answer = 1.
   ELSE.

     CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
         titlebar      = l_msg
         text_question = 'Do you want to continue?'(l02)
         text_button_1 = 'Yes'(l03)
         text_button_2 = 'No'(l04)
       IMPORTING
         answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
          IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.           .
   ENDIF.
   IF l_answer = '1'.
     IF ovrwrt = 'X'.

       me->delete_data(
           EXPORTING i_object = 'CONFLICT'
                     if_lock  = lf_locked
                     p_vrsn   = p_vrsn
                     testrun  = testrun
                       ).

     ENDIF.
     IF p_noval IS INITIAL.
       me->validation(
       EXPORTING     iconflict = lt_conflict_h
                    iconfdet  = lt_conflict_d
                    ctexts    = sw_data_t
                    i_vrsn      = p_vrsn
       IMPORTING    vald_log  = valid_log
                  ).

       LOOP AT valid_log INTO ls_gt_log.
         APPEND ls_gt_log TO gt_log.
         CLEAR: ls_gt_log.
       ENDLOOP.
       CLEAR: valid_log.
     ENDIF.


     IF testrun IS INITIAL.
       LOOP AT lt_conflict_h INTO ls_conflict_h.
         CLEAR :
         l_conid_added,
         l_conid_hdr_added,
         l_conid_fun_added,
         l_conid_txt_added,
         l_conowner_added,
         l_conpmit_added,
         l_corg_added.

         lv_objctid = ls_conflict_h-conid.

         CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
           EXPORTING
             wa_conflict           = ls_conflict_h
             i_vrsio               = p_vrsn
             f_cont                = 'X'
           IMPORTING
             conid_added           = l_conid_added
             conid_hdr_added       = l_conid_hdr_added
           EXCEPTIONS
             target_not_specified  = 1
             target_already_exists = 2
             not_authorized        = 3
             locked                = 4
             OTHERS                = 5.
         IF sy-subrc <> 0.

           CASE sy-subrc.
             WHEN 1.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFLICT'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a02
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 2.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFLICT'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a08
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 3.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFLICT'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a01
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 4.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFLICT'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a15
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN OTHERS.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFLICT'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a04
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

           ENDCASE.
         ELSE.
           converted_h = 'X'.
           "umittal 03 may 2024
*           IF p_noval EQ 'X'.
           IF p_noval EQ space.
             me->log(
                 EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFLICT'
                            i_type = 'S'
                            i_object = 'Conflict ID :'(137)
                            i_object_id = lv_objctid
                            i_field = ''
                            i_value = ''
                            i_message = 'Successful Conflict Header'
                 IMPORTING  e_gt_log  = lt_gt_log
                            ).
             LOOP AT lt_gt_log INTO ls_gt_log.
               APPEND ls_gt_log TO gt_log.
               CLEAR: ls_gt_log.
             ENDLOOP.
             CLEAR: lt_gt_log.
           ENDIF.
           "umittal
         ENDIF.

         REFRESH :lt_cont_part,  lt_cond_part, lt_cono_part.

         LOOP AT sw_data_t INTO ls_data_t WHERE textname = ls_conflict_h-conid.
           APPEND ls_data_t TO lt_cont_part.
         ENDLOOP.

         CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
           EXPORTING
             wa_conflict           = ls_conflict_h
             i_vrsio               = p_vrsn
             f_cont                = 'X'
           IMPORTING
             conid_txt_added       = l_conid_txt_added
           TABLES
             texts                 = lt_cont_part
           EXCEPTIONS
             target_not_specified  = 1
             target_already_exists = 2
             not_authorized        = 3
             locked                = 4
             OTHERS                = 5.
         IF sy-subrc <> 0.

           CASE sy-subrc.
             WHEN 1.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/TEXTS'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a02
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 2.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/TEXTS'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a08
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 3.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/TEXTS'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a01
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 4.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/TEXTS'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a15
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN OTHERS.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/TEXTS'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a04
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

           ENDCASE.
         ELSE.
           converted_t = 'X'.
           "umittal 03 may 2024
*           IF p_noval EQ 'X'.
           IF p_noval EQ space.
             me->log(
                 EXPORTING  i_file = 'Conflict Header- /PSYNG/TEXTS'
                            i_type = 'S'
                            i_object = 'Conflict ID :'(137)
                            i_object_id = lv_objctid
                            i_field = ''
                            i_value = ''
                            i_message = 'Successful Conflict Texts'
                 IMPORTING  e_gt_log  = lt_gt_log
                            ).
             LOOP AT lt_gt_log INTO ls_gt_log.
               APPEND ls_gt_log TO gt_log.
               CLEAR: ls_gt_log.
             ENDLOOP.
             CLEAR: lt_gt_log.
           ENDIF.
           "umittal
         ENDIF.
         LOOP AT lt_conflict_d INTO ls_conflict_d WHERE conid = ls_conflict_h-conid.
           APPEND ls_conflict_d TO lt_cond_part.
         ENDLOOP.
         CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
           EXPORTING
             wa_conflict           = ls_conflict_h
             i_vrsio               = p_vrsn
             f_cont                = 'X'
           IMPORTING
             conid_fun_added       = l_conid_fun_added
           TABLES
             confdet               = lt_cond_part
           EXCEPTIONS
             target_not_specified  = 1
             target_already_exists = 2
             not_authorized        = 3
             locked                = 4
             OTHERS                = 5.
         IF sy-subrc <> 0.

           CASE sy-subrc.
             WHEN 1.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFDET'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a02
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 2.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFDET'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a08
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 3.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFDET'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a01
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN 4.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFDET'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a15
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

             WHEN OTHERS.

               me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFDET'
                          i_type = 'E'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = text-a04
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.

           ENDCASE.
         ELSE.
           converted_d = 'X'.
           "umittal 03 May 2024
*           IF p_noval EQ 'X'.
           IF p_noval EQ space.
           me->log(
               EXPORTING  i_file = 'Conflict Header- /PSYNG/CONFDET'
                          i_type = 'S'
                          i_object = 'Conflict ID :'(137)
                          i_object_id = lv_objctid
                          i_field = ''
                          i_value = ''
                          i_message = 'Successful Confdet Function'
               IMPORTING  e_gt_log  = lt_gt_log
                          ).
               LOOP AT lt_gt_log INTO ls_gt_log.
                 APPEND ls_gt_log TO gt_log.
                 CLEAR: ls_gt_log.
               ENDLOOP.
               CLEAR: lt_gt_log.
           ENDIF.
           "umittal
         ENDIF.
       ENDLOOP.
     ENDIF.
   ENDIF.

   IF converted_h = 'X' AND converted_d = 'X' AND converted_t = 'X'.
     is_converted = 'X'.
   ENDIF.
   SORT: gt_log.
   DELETE ADJACENT DUPLICATES FROM gt_log COMPARING ALL FIELDS.
   DELETE gt_log WHERE object EQ space.
 ENDMETHOD.


  method CONV_CONFLICT_TEXT.

*****  DATA sast_data                      TYPE STANDARD TABLE OF /sast/proc_grp_h.
*****  DATA number                         TYPE /sast/lfdnr6.
*****  DATA checkid                        TYPE /sast/check_id.
*****
*****  DATA check_creation_protocol        TYPE /sast/return_protocol_t.
*****  DATA check_creation_protocol_entry  TYPE /sast/return_protocol_s..
*****
*****  DATA sw_data_t TYPE STANDARD TABLE OF /PSYNG/TEXTS.
*****
*****  DATA ls_data_t LIKE LINE OF sw_data_t.
*****
*****  FIELD-SYMBOLS <meta_entry_t> TYPE /SAST/EC_CONF_T.
*****
*****  FIELD-SYMBOLS <sw_entry_t> TYPE /PSYNG/TEXTS.
*****
*****
*****  DATA msg_var                 TYPE symsgv.
*****  DATA msg_key                 TYPE string.
*****
*****  number = '000000'.
*****
*****
*****  LOOP AT full_data-CONFLICT_TEXT ASSIGNING <meta_entry_t>.
*****    APPEND INITIAL LINE TO sw_data_t ASSIGNING <sw_entry_t>.
*****
*****     <sw_entry_t>-MANDT    = sy-mandt.
*****     <sw_entry_t>-TEXTNAME = <meta_entry_t>-SOD_CONFLICT.
*****     <sw_entry_t>-OBJECT   = 'C'.
*****     <sw_entry_t>-SPRAS    = <meta_entry_t>-LANG.
******     <sw_entry_t>-LINE     = <meta_entry_t>-.
*****     <sw_entry_t>-VRSIO    = p_vrsn.
*****     <sw_entry_t>-TEXT    = <meta_entry_t>-DESCRIPTION.
*****
*****   ENDLOOP.

     is_converted = 'X'.
  endmethod.


  method CONV_FUNCTION_DETAILS.
  "NOT REQUIRED - see conv_function_header
  is_converted = 'X'.
  endmethod.


  METHOD conv_function_header.

    DATA: converted_functtran TYPE c,
          converted_faobj     TYPE c,
          converted_function  TYPE c,
          converted_texts     TYPE c,

*   ----------------------------INTERNAL TABLES

          lt_functtran        TYPE STANDARD TABLE OF /psyng/functtran,
          lt_faobj            TYPE STANDARD TABLE OF /psyng/faobj2,
          lt_function         TYPE STANDARD TABLE OF /psyng/function,

          lt_gt_log           TYPE TABLE OF /psyng/sw_gt_log,
          ls_gt_log           TYPE /psyng/sw_gt_log,
          valid_log           TYPE TABLE OF /psyng/sw_gt_log,

*   ---------------------------- WORK AREA

          ls_functtran        LIKE LINE OF lt_functtran,
          ls_faobj            LIKE LINE OF lt_faobj,
          ls_function         LIKE LINE OF lt_function,

          ls_busprocid        TYPE /psyng/sw_buspro,
          lt_auth_d           TYPE TABLE OF /psyng/sw_auth_d,
          ls_auth_d           TYPE /psyng/sw_auth_d,
          lt_func_d           TYPE TABLE OF /psyng/sw_func_d,
          ls_func_d           TYPE /psyng/sw_func_d,

          lt_texts            TYPE STANDARD TABLE OF /psyng/texts,
          ls_texts            LIKE LINE OF lt_texts.

    DATA : number             TYPE n,
           l_index            TYPE sy-tabix,
           l_text             TYPE t100-text,
           lv_field           TYPE dd03d-fieldname,
           lv_value           TYPE t100-text,
           lf_locked          TYPE flag,
           l_locks            TYPE i,
           l_msg              TYPE string,
           l_answer           TYPE c,

           l_funid_added      TYPE c,
           l_funid_hdr_added  TYPE c,
           l_funid_tc_added   TYPE c,
           l_funid_txt_added  TYPE c,
           l_funct_objs_added TYPE c,
           lt_funt_part       TYPE TABLE OF /psyng/texts,
           lt_fund_part       TYPE TABLE OF /psyng/functtran,
           lt_objd_part       TYPE TABLE OF /psyng/faobj2,
           l_funh_uploaded    TYPE i,
           l_fund_uploaded    TYPE i,
           l_funt_uploaded    TYPE i,
           l_objd_uploaded    TYPE i,
           l_sysfun_uploaded  TYPE i,
           lv_objctid         TYPE t100-text.


*   ---------------------------- FIELD SYMBOLS

    FIELD-SYMBOLS:<fs_meta_func_h> TYPE /psyng/sw_func_h,
                  <fs_meta_func_d> TYPE /psyng/sw_func_d,
                  <fs_meta_func_t> TYPE /psyng/sw_func_t,

                  <fs_functtran>   TYPE /psyng/functtran,
                  <fs_faobj>       TYPE /psyng/faobj2,
                  <fs_function>    TYPE /psyng/function,

                  <fs_texts>       TYPE /psyng/texts.


    number = '0'.

    CLEAR lt_func_d[].
    SELECT * FROM /psyng/sw_func_d INTO TABLE lt_func_d.

    ASSIGN ls_functtran  TO <fs_functtran>.

*   ---------------------------- FUNCTION-HEADER

    LOOP AT conv_data ASSIGNING <fs_meta_func_h>.
      <fs_functtran>-mandt = sy-mandt.
      <fs_functtran>-functionid = <fs_meta_func_h>-sod_function.
      <fs_functtran>-vrsio = p_vrsn.
      <fs_functtran>-type = 'P'.
      LOOP AT lt_func_d INTO ls_func_d WHERE
        sod_function = <fs_meta_func_h>-sod_function.
        CONCATENATE '/PSYNG/-' ls_func_d-search_rule INTO
                <fs_functtran>-tcode .
        APPEND <fs_functtran> TO lt_functtran .
      ENDLOOP.
    ENDLOOP.

*   ---------------------------- FUNCTION-DETAILS
    CLEAR : lt_auth_d[].
    DATA : ls_obj TYPE xuobject,
           ls_auth_grp TYPE /psyng/sw_gruppe,
           cnt TYPE n VALUE 0,
           prvs TYPE n VALUE 0.
    SELECT * FROM /psyng/sw_auth_d INTO TABLE lt_auth_d.
    SORT lt_auth_d BY search_rule object auth_group field.

    ASSIGN ls_faobj  TO <fs_faobj>.

    LOOP AT full_data-function_details ASSIGNING <fs_meta_func_d>.
      <fs_faobj>-mandt = sy-mandt.
      <fs_faobj>-vrsio = p_vrsn.
      <fs_faobj>-funid = <fs_meta_func_d>-sod_function.
      CONCATENATE '/PSYNG/-' <fs_meta_func_d>-search_rule INTO
      <fs_faobj>-tcode .
      <fs_faobj>-create_usr = sy-uname.
      <fs_faobj>-create_dat = sy-datum.
      <fs_faobj>-create_tim = sy-uzeit.
      LOOP AT lt_auth_d INTO ls_auth_d
        WHERE search_rule = <fs_meta_func_d>-search_rule.
        IF ls_obj NE ls_auth_d-object.
*First iteration : the object will not be equal
*and hence valuset with count = 1 will be passed
          cnt = 1.
          ls_obj = ls_auth_d-object.
          ls_auth_grp = ls_auth_d-auth_group.
          <fs_faobj>-object    =  ls_auth_d-object.
          <fs_faobj>-valueset  =  cnt.
          <fs_faobj>-field     =  ls_auth_d-field.
          <fs_faobj>-val_from  =  ls_auth_d-low.
          <fs_faobj>-val_to    =  ls_auth_d-high.
*For IBS , realtion between objects will always be AND
          <fs_faobj>-obj_or    =  'AND'.
          IF ls_auth_d-searchtype EQ 'OR'.
            <fs_faobj>-fld_and   = space.
          ELSEIF ls_auth_d-searchtype EQ 'AND'.
            <fs_faobj>-fld_and   = 'X'.
          ENDIF.
          APPEND <fs_faobj> TO lt_faobj .
        ELSE.
          IF ls_auth_d-auth_group EQ ls_auth_grp.
*2nd iteration when the objects are same,
*hence the count will not be increase as the auth group is still same
*with previous object
            <fs_faobj>-object    =  ls_auth_d-object.
            <fs_faobj>-valueset  =  cnt.
            <fs_faobj>-field     =  ls_auth_d-field.
            <fs_faobj>-val_from  =  ls_auth_d-low.
            <fs_faobj>-val_to    =  ls_auth_d-high.
*For IBS , realtion between objects will always be AND
            <fs_faobj>-obj_or    =  'AND'.
            IF ls_auth_d-searchtype EQ 'OR'.
              <fs_faobj>-fld_and   = space.
            ELSEIF ls_auth_d-searchtype EQ 'AND'.
              <fs_faobj>-fld_and   = 'X'.
            ENDIF.
            APPEND <fs_faobj> TO lt_faobj .

          ELSE.
*Count to increment by 1 as object is same but auth group has been
*changed
            cnt = cnt + 1.
            ls_auth_grp = ls_auth_d-auth_group.
            <fs_faobj>-object    =  ls_auth_d-object.
            <fs_faobj>-valueset  =  cnt.
            <fs_faobj>-field     =  ls_auth_d-field.
            <fs_faobj>-val_from  =  ls_auth_d-low.
            <fs_faobj>-val_to    =  ls_auth_d-high.
*For IBS , realtion between objects will always be AND
            <fs_faobj>-obj_or    =  'AND'.
            IF ls_auth_d-searchtype EQ 'OR'.
              <fs_faobj>-fld_and   = space.
            ELSEIF ls_auth_d-searchtype EQ 'AND'.
              <fs_faobj>-fld_and   = 'X'.
            ENDIF.
            APPEND <fs_faobj> TO lt_faobj .
          ENDIF.
        ENDIF.
      ENDLOOP.
      CLEAR ls_auth_d.
      CLEAR ls_obj.
    ENDLOOP.

*   ---------------------------- FUNCTION-DESCRIPTION

    LOOP AT full_data-function_text ASSIGNING <fs_meta_func_t>.
*      WHERE lang = 'E'.
*      WHERE lang = sy-langu.
      APPEND INITIAL LINE TO lt_function ASSIGNING <fs_function>.
      <fs_function>-mandt = sy-mandt.
      <fs_function>-function = <fs_meta_func_t>-sod_function.
      <fs_function>-vrsio = p_vrsn.
      <fs_function>-description = <fs_meta_func_t>-description.
      READ TABLE full_data-bus_process_header
        INTO ls_busprocid INDEX number.
      <fs_function>-busarea = ls_busprocid-busprocid .
      <fs_function>-create_usr = sy-uname.
      <fs_function>-create_dat = sy-datum.
      <fs_function>-create_tim = sy-uzeit.
      number = number + 1.
      CLEAR ls_busprocid.
    ENDLOOP.

*   ---------------------------- FUNCTION-TEXT

    number = '0'.
*    LOOP AT full_data-function_text ASSIGNING <fs_meta_func_t>.
*      APPEND INITIAL LINE TO lt_texts ASSIGNING <fs_texts>.
*
*      <fs_texts>-mandt    = sy-mandt.
*      <fs_texts>-textname = <fs_meta_func_t>-sod_function.
*      <fs_texts>-object   = 'F'.
*      <fs_texts>-spras    = <fs_meta_func_t>-lang.
*      <fs_texts>-vrsio    = p_vrsn.
*      <fs_texts>-text    = <fs_meta_func_t>-description.
*
*    ENDLOOP.

*   ---------------------------- DELETE ENTRIES
    SORT: lt_functtran, lt_faobj, lt_function,lt_texts.

    DELETE ADJACENT DUPLICATES FROM lt_functtran COMPARING ALL FIELDS.
    DELETE ADJACENT DUPLICATES FROM lt_faobj COMPARING ALL FIELDS.
    DELETE ADJACENT DUPLICATES FROM lt_function COMPARING ALL FIELDS.
    DELETE ADJACENT DUPLICATES FROM lt_texts COMPARING ALL FIELDS.

    DELETE lt_functtran WHERE functionid EQ space.
    DELETE lt_faobj WHERE funid EQ space.
    DELETE lt_function WHERE function EQ space.
    DELETE lt_texts WHERE textname EQ space.

*   ---------------------------- AUTHORITY-CHECK

    LOOP AT lt_function INTO ls_function.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                ID 'ACTVT' FIELD 'UL'
                ID 'Y&SW_FUNCT' FIELD ls_function-function
                ID 'Y&SW_VRSIO' FIELD p_vrsn.
      IF sy-subrc NE 0.
        CONCATENATE text-e14 text-005 INTO l_text.

        lv_field = ls_function-function.
        lv_value = ls_function-description.

        me->log(
        EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTION'
                   i_type = 'E'
                   i_object = ''
                   i_object_id = ''
                   i_field = lv_field
                   i_value = lv_value
                   i_message = l_text
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.
        DELETE lt_function INDEX l_index.
        CLEAR: l_index, l_text.
      ENDIF.
    ENDLOOP.


    LOOP AT lt_functtran INTO ls_functtran.
      l_index = sy-tabix.
      AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                ID 'ACTVT' FIELD 'UL'
                ID 'Y&SW_FUNCT' FIELD ls_functtran-functionid
                ID 'Y&SW_VRSIO' FIELD p_vrsn.
      IF sy-subrc NE 0.
        CONCATENATE text-e14 text-005 INTO l_text.

        lv_field = ls_functtran-functionid.
        lv_value = ls_functtran-tcode.

        me->log(
        EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTTRAN'
                   i_type = 'E'
                   i_object = ''
                   i_object_id = ''
                   i_field = lv_field
                   i_value = lv_value
                   i_message = l_text
        IMPORTING  e_gt_log  = lt_gt_log
                   ).
        LOOP AT lt_gt_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: lt_gt_log.
        DELETE lt_function INDEX l_index.
        CLEAR: l_index, l_text.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_faobj INTO ls_faobj.
      READ TABLE lt_function WITH KEY function = ls_faobj-funid
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE lt_faobj WHERE funid = ls_faobj-funid.
      ENDIF.
    ENDLOOP.

*   ---------------------------- UPLOAD DATA


    me->check_lock(
    EXPORTING
     i_object = 'FUNCTION'
     p_vrsn   =  p_vrsn
    CHANGING
      ef_locked = lf_locked
      e_locks   =   l_locks
                   ).
    l_msg = l_locks.
    CONCATENATE l_msg 'Functions are locked by other users'(l01)
    INTO l_msg SEPARATED BY space.
    IF lf_locked <> 'X'.
      l_answer = 1.
    ELSE.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar      = l_msg
          text_question = 'Do you want to continue?'(l02)
          text_button_1 = 'Yes'(l03)
          text_button_2 = 'No'(l04)
        IMPORTING
          answer        = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
        EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.            .
    ENDIF.
    IF l_answer = '1'.
      IF ovrwrt = 'X'.

        me->delete_data(
            EXPORTING i_object = 'FUNCTION'
                      if_lock  = lf_locked
                      p_vrsn   = p_vrsn
                      testrun  = testrun
                        ).
      ENDIF.


      IF p_noval NE 'X'.
        me->validation(
        EXPORTING     ifunction   = lt_function
                      ifuncttrans = lt_functtran
                      ifaobj      = lt_faobj
                      ftexts      = lt_texts
                      i_vrsn      = p_vrsn
         IMPORTING    vald_log  = valid_log
                    ).

        LOOP AT valid_log INTO ls_gt_log.
          APPEND ls_gt_log TO gt_log.
          CLEAR: ls_gt_log.
        ENDLOOP.
        CLEAR: valid_log.
      ENDIF.


      IF testrun IS INITIAL.

        LOOP AT lt_function INTO ls_function.
          CLEAR :
          l_funid_added,
          l_funid_hdr_added,
          l_funid_tc_added,
          l_funid_txt_added,
          l_funct_objs_added ,
          l_sysfun_uploaded.

          lv_objctid = ls_function-function.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = ls_function
              i_vrsio                 = p_vrsn
              i_langu                 = sy-langu
              f_funt                  = 'X'
            IMPORTING
              funid_added             = l_funid_added
              funid_hdr_added         = l_funid_hdr_added
            EXCEPTIONS
              target_not_specified    = 1
              not_authorized          = 2
              function_already_exists = 3
              locked                  = 4
              OTHERS                  = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.

                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTION'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a02
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 2.

                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTION'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a01
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 3.

                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTION'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a03
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 4.

                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTION'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a15
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN OTHERS.

                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTION'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a04
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

            ENDCASE.
          ELSE.
            converted_function = 'X'.
*            IF p_noval EQ 'X'.
            IF p_noval EQ space.
              me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTION'
                             i_type = 'S'
                             i_object = 'SOD Function ID :'(125)
                             i_object_id = lv_objctid
                             i_field = ''
                             i_value = ''
                             i_message = 'Successful Functions'
                  IMPORTING  e_gt_log  = lt_gt_log
                             ).
              LOOP AT lt_gt_log INTO ls_gt_log.
                APPEND ls_gt_log TO gt_log.
                CLEAR: ls_gt_log.
              ENDLOOP.
              CLEAR: lt_gt_log.
            ENDIF.
          ENDIF.

          REFRESH :lt_funt_part,  lt_fund_part, lt_objd_part.
          LOOP AT lt_texts INTO ls_texts
            WHERE textname = ls_function-function.
            APPEND ls_texts TO lt_funt_part.
          ENDLOOP.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = ls_function
              i_vrsio                 = p_vrsn
              i_langu                 = sy-langu
              f_funt                  = 'X'
            IMPORTING
              funid_txt_added         = l_funid_txt_added
            TABLES
              texts                   = lt_funt_part
            EXCEPTIONS
              target_not_specified    = 1
              not_authorized          = 2
              function_already_exists = 3
              locked                  = 4
              OTHERS                  = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/TEXTS'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a02
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 2.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/TEXTS'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a01
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 3.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/TEXTS'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a03
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 4.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/TEXTS'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a15
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN OTHERS.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/TEXTS'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a04
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

            ENDCASE.
          ELSE.
            converted_texts = 'X'.
            "umittal 03 May 2024
*            IF p_noval EQ 'X'.
            IF p_noval EQ space.
              me->log(
                  EXPORTING  i_file = 'Function Header- /PSYNG/TEXTS'
                             i_type = 'S'
                             i_object = 'SOD Function ID :'(125)
                             i_object_id = lv_objctid
                             i_field = ''
                             i_value = ''
                             i_message = 'Successful Texts'
                  IMPORTING  e_gt_log  = lt_gt_log
                             ).
              LOOP AT lt_gt_log INTO ls_gt_log.
                APPEND ls_gt_log TO gt_log.
                CLEAR: ls_gt_log.
              ENDLOOP.
              CLEAR: lt_gt_log.
            ENDIF.
          ENDIF.

          LOOP AT lt_functtran INTO ls_functtran
            WHERE functionid = ls_function-function.
            APPEND ls_functtran TO lt_fund_part.
          ENDLOOP.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = ls_function
              i_vrsio                 = p_vrsn
              i_langu                 = sy-langu
              f_funt                  = 'X'
            IMPORTING
              funid_tc_added          = l_funid_tc_added
            TABLES
              functtran               = lt_fund_part
            EXCEPTIONS
              target_not_specified    = 1
              not_authorized          = 2
              function_already_exists = 3
              locked                  = 4
              OTHERS                  = 5.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                me->log(
               EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTTRAN'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a02
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 2.
                me->log(
               EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTTRAN'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a01
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 3.

                me->log(
               EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTTRAN'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a03
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 4.
                me->log(
               EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTTRAN'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a15
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN OTHERS.
                me->log(
               EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTTRAN'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a04
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

            ENDCASE.
          ELSE.
            converted_functtran = 'X'.
            "umittal 03 May 2024
*            IF p_noval EQ 'X'.
            IF p_noval EQ space.
              me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FUNCTTRAN'
                             i_type = 'S'
                             i_object = 'SOD Function ID :'(125)
                             i_object_id = lv_objctid
                             i_field = ''
                             i_value = ''
                             i_message = 'Successfu FUNCTTRAN'
                  IMPORTING  e_gt_log  = lt_gt_log
                             ).
              LOOP AT lt_gt_log INTO ls_gt_log.
                APPEND ls_gt_log TO gt_log.
                CLEAR: ls_gt_log.
              ENDLOOP.
              CLEAR: lt_gt_log.
            ENDIF.
            "umittal 03 May 2024
          ENDIF.


          LOOP AT lt_faobj INTO ls_faobj
            WHERE funid = ls_function-function.
            APPEND ls_faobj TO lt_objd_part.
          ENDLOOP.

          CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
            EXPORTING
              wa_function             = ls_function
              i_vrsio                 = p_vrsn
              i_langu                 = sy-langu
              f_funt                  = 'X'
            IMPORTING
              funct_objs_added        = l_funct_objs_added
            TABLES
              faobj                   = lt_objd_part
            EXCEPTIONS
              target_not_specified    = 1
              not_authorized          = 2
              function_already_exists = 3
              locked                  = 4
              OTHERS                  = 5.
          IF sy-subrc <> 0.

            CASE sy-subrc.
              WHEN 1.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FAOBJ2'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a02
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 2.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FAOBJ2'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a01
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 3.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FAOBJ2'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a03
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN 4.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FAOBJ2'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a15
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

              WHEN OTHERS.
                me->log(
                EXPORTING  i_file = 'Function Header- /PSYNG/FAOBJ2'
                           i_type = 'E'
                           i_object = 'SOD Function ID :'(125)
                           i_object_id = lv_objctid
                           i_field = ''
                           i_value = ''
                           i_message = text-a04
                IMPORTING  e_gt_log  = lt_gt_log
                           ).
                LOOP AT lt_gt_log INTO ls_gt_log.
                  APPEND ls_gt_log TO gt_log.
                  CLEAR: ls_gt_log.
                ENDLOOP.
                CLEAR: lt_gt_log.

            ENDCASE.
          ELSE.
            converted_faobj = 'X'.
            "umittal 03 may 2024
*            IF p_noval EQ 'X'.
            IF p_noval EQ space.
              me->log(
                  EXPORTING  i_file = 'Function Header- /PSYNG/FAOBJ2'
                             i_type = 'S'
                             i_object = 'SOD Function ID :'(125)
                             i_object_id = lv_objctid
                             i_field = ''
                             i_value = ''
                             i_message = 'Successful FAOBJ2'
                  IMPORTING  e_gt_log  = lt_gt_log
                             ).
              LOOP AT lt_gt_log INTO ls_gt_log.
                APPEND ls_gt_log TO gt_log.
                CLEAR: ls_gt_log.
              ENDLOOP.
              CLEAR: lt_gt_log.
            ENDIF.
            "umittal
          ENDIF.
        ENDLOOP.

        LOOP AT lt_faobj INTO ls_faobj.
          l_index = sy-tabix.
          AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                    ID 'ACTVT' FIELD 'UL'
                    ID 'Y&SW_FUNCT' FIELD ls_faobj-funid
                    ID 'Y&SW_VRSIO' FIELD p_vrsn.
          IF sy-subrc NE 0.
            CONCATENATE text-e14 text-005 INTO l_text.

            lv_field = ls_faobj-funid.
            lv_value = ls_faobj-tcode.

            me->log(
            EXPORTING  i_file = 'Function Header- /PSYNG/FAOBJ2'
                       i_type = 'E'
                       i_object = ''
                       i_object_id = ''
                       i_field = lv_field
                       i_value = lv_value
                       i_message = l_text
            IMPORTING  e_gt_log  = lt_gt_log
                       ).
            LOOP AT lt_gt_log INTO ls_gt_log.
              APPEND ls_gt_log TO gt_log.
              CLEAR: ls_gt_log.
            ENDLOOP.
            CLEAR: lt_gt_log.

            DELETE lt_function INDEX l_index.
            CLEAR: l_index, l_text.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

    IF converted_functtran = 'X' AND
       converted_faobj     = 'X' AND
       converted_function  = 'X' AND
       converted_texts     = 'X'.
      is_converted = 'X'.
    ENDIF.

    SORT: gt_log.
    DELETE ADJACENT DUPLICATES FROM gt_log COMPARING ALL FIELDS.
    DELETE gt_log WHERE object EQ space.
  ENDMETHOD.


  method CONV_FUNCTION_TEXT.
     is_converted = 'X'.
  endmethod.


  method CONV_MATRIX_DETAILS.
  endmethod.


  METHOD conv_matrix_header.

 DATA: lt_matrix_h    TYPE /psyng/swsodvers,  " itab of /PSYNG/SWSODVERS
       ls_sast_mthdr  TYPE /psyng/sw_rule_h, " wa of /SAST/EC_RULE_h
       ls_vrsio_o     TYPE /psyng/swsodvers,
       ls_vrsio_n     TYPE /psyng/swsodvers,
       l_objid        TYPE cdhdr-objectid,
       lt_cdtxt       TYPE TABLE OF cdtxt,
       g_current_user TYPE sy-uname, "C0700
       lv_mandt     LIKE sy-mandt,
       lv_vers_exst TYPE c,
       ls_valueset_and TYPE /psyng/vrs_and.

    FIELD-SYMBOLS <fs_meta_rule_t> TYPE /psyng/sw_rule_t.

*   Version already exist or not.
    CLEAR lv_mandt.
    SELECT SINGLE mandt INTO lv_mandt FROM /psyng/swsodvers
                   WHERE vrsio = p_vrsn.
    IF sy-subrc = 0.
      lv_vers_exst = 'X'.
    ENDIF.

*----version header and text

*If version does not exist
    IF lv_vers_exst IS INITIAL.
      lt_matrix_h-vrsio = p_vrsn.
      IF NOT iv_check IS INITIAL.    "Use existing version description
        READ TABLE full_data-matrix_text ASSIGNING <fs_meta_rule_t>
        INDEX 1.
        IF sy-subrc = 0.
          lt_matrix_h-vdesc = <fs_meta_rule_t>-description.
        ENDIF.
      ELSE.                          "Use new version description
        lt_matrix_h-vdesc = i_vdesc.
      ENDIF.

      l_objid     = p_vrsn.
      ls_vrsio_n  = lt_matrix_h.

      IF testrun IS INITIAL.                         "if testrun initial
        SELECT SINGLE * FROM /psyng/swsodvers INTO
        ls_vrsio_o WHERE vrsio = p_vrsn.
        IF sy-subrc <> 0.
          INSERT /psyng/swsodvers FROM lt_matrix_h.  "insert using itab
          IF sy-subrc = 0.
            is_converted = 'X'.
          ENDIF.
          CLEAR : ls_valueset_and.
          ls_valueset_and-mandt = sy-mandt.
          ls_valueset_and-vrsio = p_vrsn.
          ls_valueset_and-valueset_and = 'X'.
          MODIFY /psyng/vrs_and FROM ls_valueset_and.
          IF sy-subrc = 0.
            is_converted = 'X'.
          ENDIF.

          CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
            EXPORTING
              objectid                = l_objid
              tcode                   = sy-tcode
              utime                   = sy-uzeit
              udate                   = sy-datum
              username                = g_current_user "C0700
              planned_change_number   = ' '
              object_change_indicator = 'I'
              planned_or_real_changes = 'R'
              no_change_pointers      = ' '
              n_psyng_swsodvers       = ls_vrsio_n
              o_psyng_swsodvers       = ls_vrsio_o
              upd_psyng_swsodvers     = 'I'
            TABLES
              icdtxt_vrsio            = lt_cdtxt.
        ENDIF.
      ENDIF.

*   If version already exists and new version description is there
    ELSEIF lv_vers_exst = 'X' AND i_vdesc IS NOT INITIAL.

      lt_matrix_h-vrsio = p_vrsn.
      lt_matrix_h-vdesc = i_vdesc.

      l_objid = p_vrsn.
      ls_vrsio_n = lt_matrix_h.

      IF testrun IS INITIAL.
        MODIFY /psyng/swsodvers FROM lt_matrix_h.  "modify using itab
        IF sy-subrc = 0.
          is_converted = 'X'.
        ENDIF.
*Adding version in valusets table
        CLEAR : ls_valueset_and.
        ls_valueset_and-mandt = sy-mandt.
        ls_valueset_and-vrsio = p_vrsn.
        ls_valueset_and-valueset_and = 'X'.
        MODIFY /psyng/vrs_and FROM ls_valueset_and.
        IF sy-subrc = 0.
          is_converted = 'X'.
        ENDIF.
        CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
          EXPORTING
            objectid                = l_objid
            tcode                   = sy-tcode
            utime                   = sy-uzeit
            udate                   = sy-datum
            username                = g_current_user "C0700
            planned_change_number   = ' '
            object_change_indicator = 'I'
            planned_or_real_changes = 'R'
            no_change_pointers      = ' '
            n_psyng_swsodvers       = ls_vrsio_n
            o_psyng_swsodvers       = ls_vrsio_o
            upd_psyng_swsodvers     = 'I'
          TABLES
            icdtxt_vrsio            = lt_cdtxt.
      ENDIF.

*   If version already exists and new version description is null
    ELSE.
      is_converted = 'X'.
    ENDIF.

  ENDMETHOD.


  method CONV_MATRIX_TEXT.
  endmethod.


  method CONV_PROBLEM_HEADER.
  endmethod.


  METHOD conv_problem_text.
    DATA: lt_texts  TYPE STANDARD TABLE OF /psyng/texts,
          ls_txts_o TYPE /psyng/texts,
          ls_texts  LIKE LINE OF lt_texts.

    FIELD-SYMBOLS: <fs_meta_risk_t> TYPE /psyng/sw_risk_t,
                   <fs_texts>       TYPE /psyng/texts.

    DATA: lv_problem_text TYPE string,
          lv_solution_text TYPE string,
          lv_text_line    TYPE string,
          lv_segment      TYPE string,
          lv_index        TYPE i,
          lv_length       TYPE i,
          lv_total_len    TYPE i,
          cnt TYPE menu_num_5.
    DATA : lt_prob_text TYPE /psyng/sw_line_tt,
           lt_sol_text  TYPE /psyng/sw_line_tt,
           ls_prob_text LIKE LINE OF lt_prob_text,
           ls_sol_text  LIKE LINE OF lt_prob_text.
    CLEAR : lv_problem_text.


    LOOP AT full_data-problem_text ASSIGNING <fs_meta_risk_t>.

      CLEAR : lt_prob_text[],ls_prob_text.
      CALL FUNCTION '/PSYNG/SE_WORD_WRAP'
        EXPORTING
          iv_text           = <fs_meta_risk_t>-problem_text
         iv_line_length     = 70
       TABLES
         et_lines           = lt_prob_text.

      CONCATENATE 'Problem Text: ' ls_prob_text  INTO  ls_prob_text.
      cnt = 1.
      ls_txts_o-mandt         = sy-mandt.
      ls_txts_o-textname      = <fs_meta_risk_t>-risk_id.
      ls_txts_o-object        = 'C'.
      ls_txts_o-vrsio         = p_vrsn.
      ls_txts_o-text          = ls_prob_text.
      ls_txts_o-line          = cnt.
      IF <fs_meta_risk_t>-lang EQ 'E'.
        ls_txts_o-spras    = 'E'.
      ELSE.
        ls_txts_o-spras    = 'D'.
      ENDIF.
      APPEND ls_txts_o TO lt_texts.

      CLEAR :ls_prob_text,ls_txts_o.
      LOOP AT lt_prob_text INTO ls_prob_text.
        cnt = cnt + 1.
        ls_txts_o-mandt         = sy-mandt.
        ls_txts_o-textname      = <fs_meta_risk_t>-risk_id.
        ls_txts_o-object        = 'C'.
        ls_txts_o-vrsio         = p_vrsn.
        ls_txts_o-text          = ls_prob_text.
        ls_txts_o-line          = cnt.
        IF <fs_meta_risk_t>-lang EQ 'E'.
          ls_txts_o-spras    = 'E'.
        ELSE.
          ls_txts_o-spras    = 'D'.
        ENDIF.
        APPEND ls_txts_o TO lt_texts.
      ENDLOOP.

      CLEAR : ls_sol_text.
      CLEAR : lt_sol_text[].
      CALL FUNCTION '/PSYNG/SE_WORD_WRAP'
        EXPORTING
          iv_text           = <fs_meta_risk_t>-solution_text
         iv_line_length     = 70
       TABLES
         et_lines           = lt_sol_text.

*
      CLEAR :ls_sol_text.
      cnt = cnt + 1.
      CONCATENATE 'Solution Text: ' ls_sol_text  INTO  ls_sol_text.
      ls_txts_o-mandt         = sy-mandt.
      ls_txts_o-textname      = <fs_meta_risk_t>-risk_id.
      ls_txts_o-object        = 'C'.
      ls_txts_o-vrsio         = p_vrsn.
      ls_txts_o-text          = ls_sol_text.
      ls_txts_o-line          = cnt.
      IF <fs_meta_risk_t>-lang EQ 'E'.
        ls_txts_o-spras    = 'E'.
      ELSE.
        ls_txts_o-spras    = 'D'.
      ENDIF.
      APPEND ls_txts_o TO lt_texts.
*
      CLEAR :ls_sol_text,ls_txts_o.
      LOOP AT lt_sol_text INTO ls_sol_text.
        cnt = cnt + 1.
        ls_txts_o-mandt         = sy-mandt.
        ls_txts_o-textname      = <fs_meta_risk_t>-risk_id.
        ls_txts_o-object        = 'C'.
        ls_txts_o-vrsio         = p_vrsn.
        ls_txts_o-text          = ls_sol_text.
        ls_txts_o-line          = cnt.
        IF <fs_meta_risk_t>-lang EQ 'E'.
          ls_txts_o-spras    = 'E'.
        ELSE.
          ls_txts_o-spras    = 'D'.
        ENDIF.
        APPEND ls_txts_o TO lt_texts.
      ENDLOOP.
      CLEAR cnt.
    ENDLOOP.


    SORT: lt_texts.
    DELETE ADJACENT DUPLICATES FROM lt_texts COMPARING ALL FIELDS.
    DELETE lt_texts WHERE textname EQ space.
    IF testrun IS INITIAL.
      SELECT SINGLE * FROM /psyng/texts INTO
        ls_txts_o WHERE vrsio = p_vrsn.
      IF sy-subrc <> 0.
        INSERT /psyng/texts FROM TABLE lt_texts.
        IF sy-subrc = 0.
           COMMIT WORK.
          is_converted = 'X'.
        ENDIF.
      ELSE.
        IF ovrwrt IS NOT INITIAL.

          MODIFY /psyng/texts FROM TABLE lt_texts.
          IF sy-subrc = 0.
            COMMIT WORK.
            is_converted = 'X'.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    is_converted = 'X'.
  ENDMETHOD.


  METHOD conv_process_header.

    DATA: lt_process_h TYPE STANDARD TABLE OF /psyng/busarea,  " itab of /PSYNG/BUSAREA
          ls_process_h LIKE LINE OF lt_process_h,              " wa of /PSYNG/BUSAREA
          ls_busprocid TYPE /psyng/sw_buspro,                  " wa of /SAST/EC_BUSPROC
          lt_busprot   TYPE TABLE OF /psyng/sw_busprt,         " itab of /SAST/EC_BUSPROT
          ls_busprot   TYPE /psyng/sw_busprt.                  " wa of /SAST/EC_BUSPROT
    FIELD-SYMBOLS : <fs_meta_busproc> TYPE /psyng/sw_buspro,   " field symbol of /SAST/EC_BUSPROC
                    <fs_process_h> TYPE /psyng/busarea.        " field symbol of /PSYNG/BUSAREA

    CLEAR : lt_busprot[].
    SELECT * FROM /psyng/sw_busprt INTO TABLE lt_busprot.

    ASSIGN ls_process_h  TO <fs_process_h>.

*--Loop to append data in itab of
*--/PSYNG/BUSAREA using /SAST/EC_BUSPROC.
    LOOP AT full_data-bus_process_header
        ASSIGNING <fs_meta_busproc>.
      <fs_process_h>-mandt = sy-mandt.
      <fs_process_h>-busarea = <fs_meta_busproc>-busprocid.
      SORT lt_busprot BY busprocid ASCENDING.
      CLEAR ls_busprot.
      READ TABLE lt_busprot INTO ls_busprot
        WITH KEY busprocid = <fs_meta_busproc>-busprocid .
      <fs_process_h>-text = ls_busprot-description.
    ENDLOOP.

    SORT: lt_process_h.     " sort itab of /PSYNG/BUSAREA
    DELETE ADJACENT DUPLICATES FROM
      lt_process_h COMPARING ALL FIELDS.
* Delete duplicate entries from itab

    DELETE lt_process_h WHERE busarea EQ space.
* Delete entries with no value in busarea field

    IF testrun IS INITIAL.
      MODIFY /psyng/busarea FROM TABLE lt_process_h.   "Modify table /PSYNG/BUSAREA using itab.
      IF sy-subrc = 0.
        is_converted = 'X'.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  method CONV_PROCESS_TEXT.
*
*  DATA sast_data                      TYPE STANDARD TABLE OF /sast/proc_grp_h.
*  DATA number                         TYPE /sast/lfdnr6.
*  DATA checkid                        TYPE /sast/check_id.
*
*  DATA check_creation_protocol        TYPE /sast/return_protocol_t.
*  DATA check_creation_protocol_entry  TYPE /sast/return_protocol_s..
*
*  DATA sw_data_t TYPE STANDARD TABLE OF /PSYNG/TEXTS.
*
*  DATA ls_data_t LIKE LINE OF sw_data_t.
*
*  FIELD-SYMBOLS <meta_entry_t> TYPE /SAST/EC_BUSPROT.
*
*  FIELD-SYMBOLS <sw_entry_t> TYPE /PSYNG/TEXTS.
*
*
*  DATA msg_var                 TYPE symsgv.
*  DATA msg_key                 TYPE string.
*
*  number = '000000'.
*
*
*  LOOP AT full_data-BUS_PROCESS_TEXT ASSIGNING <meta_entry_t>.
*    APPEND INITIAL LINE TO sw_data_t ASSIGNING <sw_entry_t>.
*
*     <sw_entry_t>-MANDT    = sy-mandt.
*     <sw_entry_t>-TEXTNAME = <meta_entry_t>-BUSPROCID.
******     <sw_entry_t>-OBJECT   = 'P'.
*     <sw_entry_t>-SPRAS    = <meta_entry_t>-LANG.
**     <sw_entry_t>-LINE     = <meta_entry_t>-.
*     <sw_entry_t>-VRSIO    = p_vrsn.
*     <sw_entry_t>-TEXT    = <meta_entry_t>-DESCRIPTION.
*
*   ENDLOOP.
*
*     is_converted = 'X'.
  endmethod.


  method CONV_SEARCH_RULE_DETAILS.

  endmethod.


  method CONV_SEARCH_RULE_HEADER.
  endmethod.


  METHOD conv_search_rule_text.

    DATA: lt_texts  TYPE STANDARD TABLE OF /psyng/texts,
          ls_txts_o TYPE /psyng/texts,
          ls_texts LIKE LINE OF lt_texts.

    FIELD-SYMBOLS: <fs_meta_auth_t> TYPE /psyng/sw_auth_t,
                   <fs_texts> TYPE /psyng/texts.

    LOOP AT full_data-search_rule_text
         ASSIGNING <fs_meta_auth_t>.
      APPEND INITIAL LINE TO lt_texts ASSIGNING <fs_texts>.
      <fs_texts>-mandt    = sy-mandt.
      <fs_texts>-textname = <fs_meta_auth_t>-search_rule.
      <fs_texts>-object   = 'T'.
      <fs_texts>-spras    = <fs_meta_auth_t>-lang.
      <fs_texts>-vrsio    = p_vrsn.
      <fs_texts>-text    = <fs_meta_auth_t>-description.
    ENDLOOP.

    SORT: lt_texts.
    DELETE ADJACENT DUPLICATES FROM lt_texts COMPARING ALL FIELDS.
    DELETE lt_texts WHERE textname EQ space.
    IF testrun IS INITIAL.
      SELECT SINGLE * FROM /psyng/texts INTO
        ls_txts_o WHERE vrsio = p_vrsn.
      IF sy-subrc <> 0.
        INSERT /psyng/texts FROM TABLE lt_texts.
        IF sy-subrc = 0.
          is_converted = 'X'.
        ENDIF.

      ELSE.
        IF ovrwrt IS NOT INITIAL.
          MODIFY /psyng/texts FROM TABLE lt_texts.
          IF sy-subrc = 0.
            is_converted = 'X'.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
