FUNCTION /psyng/sw_mc_attachments .
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_HEADER) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ASSIGNMENT) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SIGNOFF) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LIST) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ADD) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(I_MCID) TYPE  /PSYNG/CONTID OPTIONAL
*"     VALUE(IS_ASSIGNMENT) TYPE  /PSYNG/MITIGATION_ASSIGNMENT OPTIONAL
*"     VALUE(IS_SIGNOFF) TYPE  /PSYNG/MCRVWSGN OPTIONAL
*"  EXPORTING
*"     VALUE(EF_HAS_ATTACHMENTS) TYPE  FLAG
*"     VALUE(E_NR_ATTACHMENTS) TYPE  SYTFILL
*"  EXCEPTIONS
*"      INVALID_INPUT
*"      NOT_IMPLEMENTED
*"      GOS_FAILURE
*"----------------------------------------------------------------------
  DATA : l_check_count TYPE i,
         o_att_mgr      TYPE REF TO cl_gos_manager,
         ls_obj         TYPE borident,
         l_service      TYPE sgs_srvnam,
         lt_attachments TYPE TABLE OF relgraphlk,
         l_key          TYPE string.
DATA :   l_folder_id   TYPE soodk,
         ls_document    TYPE sood4,
         lt_documents   LIKE STANDARD TABLE OF sood4,
         ls_obj_atta  TYPE borident.
CONSTANTS : gc_tabname    TYPE lvc_tname VALUE 'SRGBTBREL'.

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
*--Check if anything is attached
    IF sy-saprl(2) LE '46'.
      CALL FUNCTION 'SREL_GET_NEXT_RELATIONS'
           EXPORTING
                object         = ls_obj
           TABLES
                links          = lt_attachments
           EXCEPTIONS
                internal_error = 1
                no_logsys      = 2
                OTHERS         = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      DESCRIBE TABLE lt_attachments LINES e_nr_attachments.
    else.
      SELECT COUNT(*) INTO e_nr_attachments FROM (gc_tabname)
        WHERE typeid_a = ls_obj-objtype
          AND instid_a = ls_obj-objkey."#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
    endif.
    IF e_nr_attachments > 0.
      ef_has_attachments = 'X'.
    ENDIF.
  ELSE.
    CASE 'X'.
      WHEN if_list.
*  --Show Attachment list
        l_service = 'VIEW_ATTA'.
      WHEN if_add.
*  --Add Attachment
        l_service = 'CREATE_ATTA'.
    ENDCASE.
    IF l_service = 'VIEW_ATTA'.

      CREATE OBJECT o_att_mgr
      EXPORTING
        ip_no_commit = 'R'
      EXCEPTIONS
        others       = 1.
      IF sy-subrc <> 0.
        MESSAGE e002(/psyng/sw) WITH
        'Failed to create GOS manager' RAISING gos_failure.
      ELSE.
        CALL METHOD o_att_mgr->start_service_direct
          EXPORTING
            ip_service       = l_service
            is_object        = ls_obj
          EXCEPTIONS
            no_object        = 1
            object_invalid   = 2
            execution_failed = 3
            OTHERS           = 4.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.

    ELSE.

* PA Method for create attachments

      CALL FUNCTION 'SO_FOLDER_ROOT_ID_GET'
           EXPORTING
                region    = 'B'
           IMPORTING
                folder_id = l_folder_id
           EXCEPTIONS
              COMMUNICATION_FAILURE = 1
              OWNER_NOT_EXIST = 2
              SYSTEM_FAILURE = 3
              OTHERS    = 4.
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

      ls_document-foltp = l_folder_id-objtp.
      ls_document-folyr = l_folder_id-objyr.
      ls_document-folno = l_folder_id-objno.
      APPEND ls_document TO  lt_documents.

      CALL FUNCTION 'SO_DOCUMENTS_MANAGER'
           EXPORTING
                activity  = 'IMPO'
           TABLES
                documents = lt_documents.

      LOOP AT  lt_documents INTO ls_document.
        IF ls_document-okcode = 'CREA'.
          ls_obj_atta-objtype = 'MESSAGE'.
          ls_obj_atta-objkey  = ls_document(34).
          CALL FUNCTION 'BINARY_RELATION_CREATE_COMMIT'
               EXPORTING
                    obj_rolea    = ls_obj
                    obj_roleb    = ls_obj_atta
                    relationtype = 'ATTA'
               EXCEPTIONS
                    OTHERS       = 1.
          IF sy-subrc = 0.
            COMMIT WORK.
          ENDIF.
        ENDIF.
      ENDLOOP.

    ENDIF.
  ENDIF.
ENDFUNCTION.
