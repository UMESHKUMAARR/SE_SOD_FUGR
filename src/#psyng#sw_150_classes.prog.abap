*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_150
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_150_CLASSES                                      *
*----------------------------------------------------------------------*
*--Class to handle tree events
CLASS lcl_application DEFINITION.
  PUBLIC SECTION.
    METHODS: handle_expand FOR EVENT expand_no_children
                  OF cl_gui_column_tree
      IMPORTING node_key,
      handle_link_click FOR EVENT link_click
                    OF cl_gui_column_tree
        IMPORTING node_key item_name.
ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS lcl_application IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.
  METHOD handle_expand.
    DATA : ls_item LIKE LINE OF gt_item.
*--NODE_KEY type TV_NODEKEY
    READ TABLE gt_item INTO ls_item
         WITH KEY node_key  = node_key
                  item_name = 'NODETYPE'.
    IF sy-subrc = 0.
      CASE ls_item-text.
        WHEN 'GROUP'.
          PERFORM expand_group    USING node_key.
        WHEN 'AGR_NAME'.
          PERFORM expand_role    USING node_key.
        WHEN 'ROLECON'.
          PERFORM expand_rolecon  USING node_key.
        WHEN 'CONFUN'.
          PERFORM expand_function USING node_key.
        WHEN 'VAREL'.
          PERFORM expand_varel    USING node_key.
        WHEN 'ORG'.
          PERFORM expand_org      USING node_key.
      ENDCASE.
    ENDIF.
  ENDMETHOD.

  METHOD handle_link_click.
    DATA : l_node_type  TYPE string,
           answer,
           ls_item      LIKE LINE OF gt_item,
           line(80),
           l_authfield  TYPE authx-fieldname,
           l_fld        TYPE xufield,
           l_obj        TYPE xuobject,
           l_val_from   TYPE xuval,
           l_val_to     TYPE xuval,
           l_hashcode   TYPE xupname,
           l_fioriid    TYPE /psyng/sw_fioriid,
           l_functionid TYPE /psyng/function_id,
           l_tcode      TYPE tcode,
           l_node_key   TYPE tv_nodekey,
           l_objct      TYPE tobj-objct,
           l_agr_name   TYPE agr_define-agr_name,
           l_sod        TYPE /psyng/swsodvers-vrsio,
           l_sodvrsio   TYPE /psyng/swsodvers-vrsio,
           l_uname      LIKE sy-uname,
           l_parva      TYPE usr05-parva,
*             lt_swresisys TYPE TABLE OF /psyng/swresisys,
           lt_system    TYPE TABLE OF /psyng/sw_rfcdes,
           ls_sys       LIKE LINE OF lt_system,
           l_local      TYPE rfcdest,
           lf_local     TYPE flag,
           ls_node      LIKE LINE OF gt_node,
           l_nodetype   TYPE string,
           l_rest       TYPE string.
    DATA : lt_iseltab TYPE STANDARD TABLE OF  rsparams,
           ls_iseltab TYPE rsparams.
    REFRESH lt_iseltab.

*--system
*    SELECT * FROM /psyng/swresisys INTO TABLE lt_swresisys
*    WHERE aid = g_aid.
*    IF NOT lt_swresisys[] IS INITIAL.
    SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_system
*      FOR ALL ENTRIES IN lt_swresisys
    WHERE systid = gs_hdr-sysid.
*    ENDIF.
    CONCATENATE sy-sysid sy-mandt INTO l_local.
    SELECT SINGLE sodvrsio FROM /psyng/swrrshdr INTO (l_sodvrsio)
       WHERE aid = g_aid.
*--Handle link clicks
    READ TABLE gt_item INTO ls_item WITH KEY node_key  = node_key
                                            item_name = 'DATA'.
*---node tree's drill down
    SPLIT node_key AT '_' INTO l_nodetype l_rest.
    CASE l_nodetype.
      WHEN 'C'. " Conflict
        CHECK ls_item-text <> space.
        l_uname = g_current_user. "sy-uname. C0700
**-- Get user's default version
        SELECT SINGLE parva INTO l_parva FROM usr05
                   WHERE bname = l_uname
                     AND parid = '/PSYNG/VRSIO'.
        IF sy-subrc = 0 AND l_parva <> space.
          l_sod = l_parva.
        ENDIF.

        PERFORM set_default_sodversion USING  l_sodvrsio l_uname.
        SET PARAMETER ID '/PSYNG/CON' FIELD ls_item-text.
        g_dynnr = '0202'.
        EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
        IF sy-subrc <> 0.
          MESSAGE e077(s#) WITH '/PSYNG/SE'.
        else.
          CALL TRANSACTION '/PSYNG/SE'.
        endif.
*-- Set back to Default
        PERFORM set_default_sodversion USING l_sod l_uname.

      WHEN 'F'.
        CHECK ls_item-text <> space.
        l_uname = g_current_user. "sy-uname. C0700
**-- Get user's default version
        SELECT SINGLE parva INTO l_parva FROM usr05
                   WHERE bname = l_uname
                     AND parid = '/PSYNG/VRSIO'.
        IF sy-subrc = 0 AND l_parva <> space.
          l_sod = l_parva.
        ENDIF.

        PERFORM set_default_sodversion USING l_sodvrsio l_uname.
        SET PARAMETER ID '/PSYNG/FUN' FIELD ls_item-text.
        g_dynnr = '0201'.
        EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
        IF sy-subrc <> 0.
          MESSAGE e077(s#) WITH '/PSYNG/SE'.
        else.
          CALL TRANSACTION '/PSYNG/SE'.
        endif.
*-- Set back to Default
        PERFORM set_default_sodversion USING l_sod l_uname.

*---roles or comp roles
      WHEN 'S'.
        CHECK ls_item-text <> space.
        CLEAR answer.
        l_agr_name = ls_item-text.
        CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
          EXPORTING
            defaultoption     = '1'
            diagnosetext1     = l_agr_name
            diagnosetext2     = text-057
            diagnosetext3     = text-058
            textline1         = text-059
            text_option1      = text-060
            text_option2      = text-061
            icon_text_option1 = 'ICON_DISPLAY'
            icon_text_option2 = 'ICON_CHECK'
            titel             = text-062
            cancel_display    = 'X'
          IMPORTING
            answer            = answer.

        CASE answer.
          WHEN '1'.
            PERFORM display_role_in_pfcg USING l_agr_name ''.
            "ls_item-text.
          WHEN '2'.

            ls_iseltab-selname = 'ROLE'.
            ls_iseltab-kind    = 'S'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = l_agr_name.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'SODVRSIO'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = l_sodvrsio. "l_sod.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'CFGSET'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = gs_hdr-setid.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'XMC'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = 'X'.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'SHOSUM'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = 'X'.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'SHODET'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = ''.
            APPEND ls_iseltab TO lt_iseltab.

*            LOOP AT lt_system INTO ls_sys.
            IF NOT gs_hdr-sysid = l_local.
              READ TABLE gt_sysinfo INTO gt_sysinfo
              WITH KEY systid = gs_hdr-sysid.
              ls_iseltab-selname = 'REMRFC'.
              ls_iseltab-kind    = 'P'.
              ls_iseltab-sign    = 'I'.
              ls_iseltab-option  = 'EQ'.
              ls_iseltab-low     = gt_sysinfo-rfcdest.
              APPEND ls_iseltab TO lt_iseltab.
            ENDIF.
*            ENDLOOP.
            SUBMIT /psyng/sod_syswide_byrole
                      WITH SELECTION-TABLE lt_iseltab
                      AND RETURN.

        ENDCASE.


**---Profile
      WHEN 'A'.
        IF item_name = 'DATA'.
          CHECK ls_item-text <> space.
          AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
          IF sy-subrc <> 0.
            MESSAGE e077(s#) WITH 'SU02'.
          ELSE.
            SET PARAMETER ID 'XUP' FIELD ls_item-text.
            CALL TRANSACTION 'SU02'.
          ENDIF.
        ENDIF.
    ENDCASE.


*---Child tree's drill down
    CASE item_name.
      WHEN 'FIELD'.
        READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                   item_name = 'FIELD'.

        l_authfield = ls_item-text.

        CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
          EXPORTING
            fieldname = l_authfield.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      WHEN 'CHILD_ROLE'." OR 'COMP_AGR'.
        READ TABLE gt_item INTO ls_item
        WITH KEY node_key  = node_key
                 item_name = 'CHILD_ROLE'.
        CLEAR answer.
        l_agr_name = ls_item-text.
        CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
          EXPORTING
            defaultoption     = '1'
            diagnosetext1     = l_agr_name
            diagnosetext2     = text-057
            diagnosetext3     = text-058
            textline1         = text-059
            text_option1      = text-060
            text_option2      = text-061
            icon_text_option1 = 'ICON_DISPLAY'
            icon_text_option2 = 'ICON_CHECK'
            titel             = text-062
            cancel_display    = 'X'
          IMPORTING
            answer            = answer.

        CASE answer.
          WHEN '1'.
*            READ TABLE gt_node INTO ls_node WITH KEY
*            relatkey = node_key
*            isfolder = 'X'.
*            IF sy-subrc = 0.
*              READ TABLE gt_item INTO ls_item
*              WITH KEY node_key = ls_node-node_key
*                       item_name = 'SYSINDEX'.

*            ENDIF.
            PERFORM display_role_in_pfcg USING l_agr_name ''.
            "ls_item-text.
          WHEN '2'.

            ls_iseltab-selname = 'ROLE'.
            ls_iseltab-kind    = 'S'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = l_agr_name.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'SODVRSIO'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = l_sodvrsio. "l_sod.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'XMC'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = 'X'.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'SHOSUM'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = 'X'.
            APPEND ls_iseltab TO lt_iseltab.

            ls_iseltab-selname = 'SHODET'.
            ls_iseltab-kind    = 'P'.
            ls_iseltab-sign    = 'I'.
            ls_iseltab-option  = 'EQ'.
            ls_iseltab-low     = ''.
            APPEND ls_iseltab TO lt_iseltab.

*            LOOP AT lt_system INTO ls_sys.
            IF NOT gs_hdr-sysid = l_local.
              READ TABLE gt_sysinfo INTO gt_sysinfo
              WITH KEY systid = gs_hdr-sysid.
              ls_iseltab-selname = 'REMRFC'.
              ls_iseltab-kind    = 'P'.
              ls_iseltab-sign    = 'I'.
              ls_iseltab-option  = 'EQ'.
              ls_iseltab-low     = gt_sysinfo-rfcdest.
              APPEND ls_iseltab TO lt_iseltab.
            ENDIF.
*            ENDLOOP.
            SUBMIT /psyng/sod_syswide_byrole
                      WITH SELECTION-TABLE lt_iseltab
                      AND RETURN.

        ENDCASE.

      WHEN 'PROFILE'.
        READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                                            item_name = 'PROFILE'.
        CHECK ls_item-text <> space.
*        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
*Begin of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU02'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
        IF sy-subrc = 1.
          SET PARAMETER ID 'XUP' FIELD ls_item-text.
          CALL TRANSACTION 'SU02'.
        ELSE.
          MESSAGE e077(s#) WITH 'SU02'.
        ENDIF.
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)

      WHEN 'TCODE'.
        READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                                           item_name = 'TCODE'.
        l_tcode = ls_item-text.
*--Read parent node
        READ TABLE gt_node INTO ls_node WITH KEY node_key = node_key.
        IF sy-subrc = 0.
          l_node_key = ls_node-relatkey.
        ENDIF.
*--Again Read parent node
*        READ TABLE gt_node INTO ls_node WITH KEY node_key = l_node_key.
*        IF sy-subrc = 0.
*          l_node_key = ls_node-relatkey.
*        ENDIF.
        CLEAR: l_functionid.
        READ TABLE gt_item INTO ls_item
        WITH KEY node_key = l_node_key
        item_name = 'DATA'.
        IF sy-subrc = 0.
          l_functionid = ls_item-text.
        ENDIF.

        CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
          EXPORTING
           i_tcode           = l_tcode
           I_VRSIO           = gs_hdr-sodvrsio
           I_FUNID           = l_functionid .

      WHEN 'OBJECT'.
        READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                                              item_name = 'OBJECT'.
        CHECK ls_item-text <> space.
        l_objct = ls_item-text.
        CALL FUNCTION 'SUSR_SHOW_OBJECT'
          EXPORTING
            object  = l_objct
            eu_mode = ' '.

      WHEN 'VAL_FROM' OR 'VAL_TO'.
        READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                                             item_name = 'FIELD'.
        l_fld = ls_item-text.
        READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                                             item_name = 'OBJECT'.
        l_obj = ls_item-text.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
        IF  l_obj EQ gc_service
        AND l_fld EQ gc_srv_name.
          IF item_name EQ 'VAL_FROM'.
            READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                                                 item_name = 'VAL_FROM'.
            l_val_from = ls_item-text.
            l_hashcode = l_val_from.
          ELSEIF item_name EQ 'VAL_TO'.
            READ TABLE gt_item INTO ls_item WITH KEY node_key = node_key
                                                   item_name = 'VAL_TO'.
            l_val_to = ls_item-text.
            l_hashcode = l_val_to.
          ENDIF.
*--Displays a popup with the name of the Odata Service
          CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
            EXPORTING
              i_hashcode      = l_hashcode
              if_show_message = 'X'
            EXCEPTIONS
              not_found       = 1
              OTHERS          = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          RETURN.
        ENDIF.

        CALL FUNCTION 'SUSR_AUTH_FIELD_VALUES'
          EXPORTING
            fieldname       = l_fld
            object          = l_obj
*       IMPORTING
*           SEL_VALUE       =
          EXCEPTIONS
            field_not_found = 1
            OTHERS          = 2.
        IF sy-subrc <> 0.
          MESSAGE s398(00) WITH 'Object'(o01) l_objct
          'not found in local system'(o02).
        ENDIF.

    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*---------------------------------------------------------------------*
*       FORM display_role_in_pfcg                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  AGR_NAME                                                      *
*---------------------------------------------------------------------*
FORM display_role_in_pfcg USING
                  agr_name LIKE agr_define-agr_name
                  i_sysindex   .

  DATA: answer,
        l_repid      LIKE sy-repid,
        pertext(200).        "Progress indicator text.


  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
    EXPORTING
      defaultoption     = '1'
      diagnosetext1     = text-147
      diagnosetext2     = text-064
      diagnosetext3     = text-130
      textline1         = text-075
      text_option1      = text-131
      text_option2      = text-132
      icon_text_option1 = 'ICON_INCOMING_TASK'
      icon_text_option2 = 'ICON_OUTGOING_TASK'
      titel             = text-075
      cancel_display    = 'X'
    IMPORTING
      answer            = answer.

  CASE answer.
    WHEN '1'.
 CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
   EXPORTING
     agr_name      = agr_name
   EXCEPTIONS
     agr_not_found = 1
     OTHERS        = 2.
      IF sy-subrc <> 0.
        IF sy-subrc = 1.
          CLEAR pertext.
          CONCATENATE text-076 text-188
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ELSEIF sy-subrc = 2.
          CONCATENATE text-077 text-188 text-078
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ENDIF.
      ENDIF.
    WHEN '2'.
      DATA: userresponse, dflt_rfc LIKE /psyng/swconfig-value,
            ifields      TYPE STANDARD TABLE OF sval WITH HEADER LINE..

      CLEAR: ifields.
      REFRESH: ifields.
*      gt_system-sysindex = i_sysindex.
*      READ TABLE gt_system
*      WITH KEY sysindex = gt_system-sysindex.
*      IF sy-subrc = 0.
      READ TABLE gt_sysinfo WITH KEY systid = gs_hdr-sysid.
      IF sy-subrc = 0.
        dflt_rfc = gt_sysinfo-rfcdest.
      ENDIF.
*      ENDIF.
*      se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
      IF ifields[] IS INITIAL.
        ifields-tabname = 'RFCDES'.
        ifields-fieldname = 'RFCDEST'.
        ifields-fieldtext = text-090.
        IF NOT dflt_rfc IS INITIAL.
          ifields-value = dflt_rfc.
        ENDIF.
        APPEND ifields.
      ENDIF.

      CLEAR userresponse.
      l_repid = sy-repid.
      CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
        EXPORTING
          formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
          programname       = l_repid
          popup_title       = text-066
          ok_pushbuttontext = text-127
        IMPORTING
          returncode        = userresponse
        TABLES
          fields            = ifields
        EXCEPTIONS
          error_in_fields   = 1
          OTHERS            = 2.

      IF sy-subrc <> 0.
        MESSAGE e208(00) WITH text-067.
      ENDIF.

      CHECK userresponse NE 'A'."#EC SAST_CI_GEN_CHECK
        "check to see user doesn't abort

      READ TABLE ifields WITH KEY tabname = 'RFCDES'
                                  fieldname = 'RFCDEST'.

      IF ifields-value IS INITIAL.
        MESSAGE w208(00) WITH text-068.
      ENDIF.
*      SELECT SINGLE * FROM rfcdes WHERE rfcdest = ifields-value AND
*                                        rfctype = '3'.
      IF sy-subrc EQ 0.
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
        CALL FUNCTION 'PRGN_SHOW_EDIT_AGR'
          DESTINATION ifields-value
          EXPORTING
            agr_name      = agr_name
          EXCEPTIONS
            SYSTEM_FAILURE        = 1
            COMMUNICATION_FAILURE = 2
            agr_not_found = 3
            OTHERS        = 4."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF sy-subrc = 3.
          CLEAR pertext.
          CONCATENATE text-076 ifields-value
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ELSEIF sy-subrc = 4.
          CONCATENATE text-077 ifields-value text-078
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ENDIF.
      ELSE.
        CLEAR pertext.
        CONCATENATE text-090 ifields-value text-133
                                 INTO pertext SEPARATED BY space.
        MESSAGE i208(00) WITH pertext.
      ENDIF.

    WHEN OTHERS.
  ENDCASE.
ENDFORM.
