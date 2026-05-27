*----------------------------------------------------------------------*
* INCLUDE PROGRAM       : /PSYNG/AUDTOBJCL1
* AUTHOR                : Security Weaver, LLC
* RELEASE               : 1.0.1.0
* DATE OF RELEASE       :
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
CLASS lcl_application DEFINITION.

  PUBLIC SECTION.
    METHODS:
      handle_button_click
        FOR EVENT button_click
        OF cl_gui_column_tree
        IMPORTING node_key item_name,
      item_double_click FOR EVENT item_double_click
        OF cl_gui_column_tree
        IMPORTING node_key item_name.
ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.

*---------------------------------------------------------------------*
*       METHOD handle_button_click
*---------------------------------------------------------------------*
* This method handles the button click event of tree control instance *
*---------------------------------------------------------------------*
  METHOD handle_button_click.
    DATA: ll_swaudc             TYPE t_swaudc,
          ll_select             TYPE t_swaudc,
          lt_autotab            TYPE TABLE OF t_swaudc,
          l_valueset            TYPE t_swaudc-valueset,
          l_valueset_count      TYPE i,
          lt_node               TYPE treev_ntab,
          ls_node               TYPE treev_node,
          ls_tobj               TYPE tobj,
          lt_tree_item          TYPE t_tree_item,
          l_node_key_swaudid    TYPE tv_nodekey,
          l_node_key_object     TYPE tv_nodekey,
          l_node_key_tcode      TYPE tv_nodekey,
          l_node_key_prev_tcode TYPE tv_nodekey,
          l_node_key_vs         TYPE tv_nodekey,
          l_node_key_next_vs    TYPE tv_nodekey,
          l_tcode_count         TYPE i,
          l_object_count        TYPE i,
          l_node_pos            TYPE i,
          l_curr_node_pos       TYPE i,
          l_onode(10)           TYPE c,
          l_index               TYPE i,
          l_field(5)            TYPE c,
          l_insert_node         TYPE i,
          l_dokclass            TYPE dsysh-dokclass,
          l_dokname             TYPE /psyng/swaudc2-object,
          lt_links              TYPE TABLE OF tline.

    FIELD-SYMBOLS: <fld> TYPE tobj-fiel1.


*   Cannot push buttons in display mode
    IF gf_dispchg = gc_display.
      MESSAGE i151(/psyng/sw).
      EXIT.
    ENDIF.

    g_node_key = node_key.

    CASE node_key(1).
      WHEN 'T'.              "Transaction
        IF item_name = 'VALUEFROM'.    "Add new auth. object
*         Get new authorization object from user
          CLEAR gl_tobjt-object.
          CALL SCREEN 900 STARTING AT 3 10.

          CHECK sy-ucomm = 'CONTINUE'.

*         Check that object does not already exist
          READ TABLE gt_swaudc WITH KEY tnode  = node_key+1
                                        object = gl_tobjt-object
                               TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            MESSAGE i101(/psyng/sw).
            EXIT.
          ENDIF.

*         Add transaction to internal table
          READ TABLE gt_swaudc INTO ll_swaudc
                     WITH KEY tnode = node_key+1.

          SELECT SINGLE objct INTO ll_swaudc-object FROM tobj
                        WHERE objct = gl_tobjt-object.
          IF sy-subrc <> 0.
*            MESSAGE e398(00) WITH text-t03 gl_tobjt-object text-e04.
**Case #14012
            CLEAR ll_swaudc-otext.
            MESSAGE i398(00) WITH text-t03 gl_tobjt-object text-e04.
          ENDIF.

*         Get object description
          SELECT SINGLE ttext INTO ll_swaudc-otext FROM tobjt
                        WHERE langu  = sy-langu
                          AND object = ll_swaudc-object.

          ll_swaudc-object = gl_tobjt-object.
          ll_swaudc-valueset = 1.
          ls_tobj-objct = ll_swaudc-object.
          PERFORM get_object_fields CHANGING ls_tobj.
          CLEAR: ll_swaudc-field, ll_swaudc-val_from, ll_swaudc-val_to.

          DO.
            IF sy-index < 10.
              l_field = sy-index.
              CONDENSE l_field.
              CONCATENATE 'FIEL' l_field INTO l_field.
            ELSEIF sy-index = 10.
              l_field = 'FIEL0'.
            ELSE.
              EXIT.
            ENDIF.

ASSIGN COMPONENT l_field OF STRUCTURE ls_tobj TO <fld>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
            IF <fld> IS INITIAL.
              IF l_field = 'FIEL1'.
                CLEAR ll_swaudc-ddtext.
                APPEND ll_swaudc TO gt_swaudc.
              ENDIF.

              EXIT.
            ENDIF.

            ll_swaudc-field = <fld>.
            PERFORM get_field_name USING ll_swaudc-field
                                   CHANGING ll_swaudc-ddtext.
            APPEND ll_swaudc TO gt_swaudc.
          ENDDO.

          PERFORM mark_changes USING ll_swaudc-swaudid ll_swaudc-tcode
                                     ll_swaudc-object.
          PERFORM refresh_tree.
        ELSE.                          "Auto-fill objects and values
          CALL FUNCTION 'POPUP_TO_CONFIRM'
               EXPORTING
                    titlebar              = text-t04
                    text_question         = text-q01
                    text_button_1         = text-003
                    icon_button_1         = 'ICON_OKAY'
                    text_button_2         = text-004
                    icon_button_2         = 'ICON_CANCEL'
                    default_button        = '2'
                    display_cancel_button = space
               IMPORTING
                    answer                = g_answer
               EXCEPTIONS
                    text_not_found        = 1
                    OTHERS                = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

          CHECK g_answer = '1'.

          LOOP AT gt_swaudc INTO ll_swaudc WHERE tnode = node_key+1.
           PERFORM mark_changes USING gt_swaudc-swaudid gt_swaudc-tcode
                                       gt_swaudc-object.
          ENDLOOP.

*         Delete existing rows from GT_swaudc and insert new ones
          SELECT object field low high
            INTO (ll_swaudc-object, ll_swaudc-field, ll_swaudc-val_from,
                  ll_swaudc-val_to)
            FROM usobt_c
           WHERE name = ll_swaudc-tcode.

            IF sy-dbcnt = 1.
              DELETE gt_swaudc WHERE tnode = node_key+1.
            ENDIF.

*           Get object text
            SELECT SINGLE ttext INTO ll_swaudc-otext FROM tobjt
                          WHERE langu = sy-langu
                            AND object = ll_swaudc-object.

            APPEND ll_swaudc TO lt_autotab.
          ENDSELECT.

          IF sy-subrc <> 0.
            MESSAGE e398(00) WITH text-e05.
          ENDIF.

*         Populate valueset and node counts and append to GT_swaudc
          LOOP AT lt_autotab INTO ll_swaudc.
            ll_swaudc-valueset = 1. "Always value set 1 whenauto-fill
            PERFORM get_field_name USING ll_swaudc-field
                                   CHANGING ll_swaudc-ddtext.
            APPEND ll_swaudc TO gt_swaudc.
           PERFORM mark_changes USING ll_swaudc-swaudid ll_swaudc-tcode
                                       ll_swaudc-object.
          ENDLOOP.

          PERFORM refresh_tree.
          REFRESH gt_select.
        ENDIF.

      WHEN 'G'.              "Value set
        CASE item_name.
          WHEN 'VALUEFROM'.    "Edit value set
            REFRESH gt_select.
            SPLIT node_key+1 AT '|' INTO l_onode l_valueset.
            LOOP AT gt_swaudc INTO ll_swaudc WHERE onode    = l_onode
                                               AND valueset = l_valueset
.
              APPEND ll_swaudc TO gt_select.
            ENDLOOP.

          WHEN 'VALUETO'.      "Delete value set
            REFRESH gt_select.
            PERFORM save_value_set.
        ENDCASE.

      WHEN 'O'.              "Object
        CASE item_name.
          WHEN 'VALUEFROM'.            "Add value set
            LOOP AT gt_swaudc INTO ll_swaudc WHERE onode = node_key+1.
              ll_select = ll_swaudc.

              IF l_valueset <> ll_swaudc-valueset.
                ADD 1 TO l_valueset_count.
                l_valueset = ll_swaudc-valueset.

*               Insert valueset in between others
                IF l_valueset_count < l_valueset.
                  l_insert_node = l_valueset_count.
                  SUBTRACT 1 FROM l_valueset_count.
                  EXIT.
                ENDIF.
              ENDIF.
            ENDLOOP.

            ADD 1 TO l_valueset_count.

            IF sy-subrc <> 0.
*           If no rows were found, that means that all other value sets
*             were deleted.
              READ TABLE gt_del_vs INTO gt_swaudc
                         WITH KEY onode = node_key+1.

              ll_swaudc = gt_swaudc.
              ll_select = ll_swaudc.
              ll_select-valueset = l_valueset_count.
              CLEAR: ll_select-field, ll_select-val_from,
                     ll_select-val_to, ll_select-ddtext.
              ls_tobj-objct = ll_swaudc-object.
              PERFORM get_object_fields CHANGING ls_tobj.

              DO.
                IF sy-index < 10.
                  l_field = sy-index.
                  CONDENSE l_field.
                  CONCATENATE 'FIEL' l_field INTO l_field.
                ELSEIF sy-index = 10.
                  l_field = 'FIEL0'.
                ELSE.
                  EXIT.
                ENDIF.

ASSIGN COMPONENT l_field OF STRUCTURE ls_tobj TO <fld>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
                IF <fld> IS INITIAL.
                  IF l_field = 'FIEL1'.
                    APPEND ll_select TO gt_swaudc.
                  ENDIF.

                  EXIT.
                ENDIF.

                ll_select-field   = <fld>.
                PERFORM get_field_name USING ll_select-field
                                       CHANGING ll_select-ddtext.
                APPEND ll_select TO gt_swaudc.
              ENDDO.

              PERFORM mark_changes USING ll_swaudc-swaudid
                                         ll_swaudc-tcode
                                         ll_swaudc-object.
            ELSE.
              ll_select-valueset = l_valueset_count.
              CLEAR: ll_select-field, ll_select-val_from,
                     ll_select-val_to, ll_select-ddtext.
              ls_tobj-objct = ll_select-object.
              PERFORM get_object_fields CHANGING ls_tobj.

              DO.
                IF sy-index < 10.
                  l_field = sy-index.
                  CONDENSE l_field.
                  CONCATENATE 'FIEL' l_field INTO l_field.
                ELSEIF sy-index = 10.
                  l_field = 'FIEL0'.
                ELSE.
                  EXIT.
                ENDIF.

ASSIGN COMPONENT l_field OF STRUCTURE ls_tobj TO <fld>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
                IF <fld> IS INITIAL.
                  IF l_field = 'FIEL1'.
                    APPEND ll_select TO gt_swaudc.
                  ENDIF.

                  EXIT.
                ENDIF.

                ll_select-field = <fld>.
                PERFORM get_field_name USING ll_select-field
                                       CHANGING ll_select-ddtext.
                APPEND ll_select TO gt_swaudc.
              ENDDO.

              PERFORM mark_changes USING ll_swaudc-swaudid
                                         ll_swaudc-tcode
                                         ll_swaudc-object.
            ENDIF.

            PERFORM refresh_tree.

          WHEN 'VALUETO'.              "Delete object
            READ TABLE gt_swaudc INTO ll_swaudc
                       WITH KEY onode = node_key+1.
            l_index = sy-tabix.

           PERFORM mark_changes USING ll_swaudc-swaudid ll_swaudc-tcode
                                       ll_swaudc-object.

*           Check for other rows for this TCode
            LOOP AT gt_swaudc TRANSPORTING NO FIELDS
                    WHERE swaudid = ll_swaudc-swaudid
                      AND tcode   = ll_swaudc-tcode
                      AND onode  <> node_key+1.
              EXIT.
            ENDLOOP.

            IF sy-subrc = 0.
              DELETE gt_swaudc WHERE onode = node_key+1.
            ELSE.
              CLEAR ll_select.
              ll_select-swaudid = ll_swaudc-swaudid.
              ll_select-description = ll_swaudc-description.
              ll_select-tcode = ll_swaudc-tcode.
              ll_select-ttext = ll_swaudc-ttext.

              DELETE gt_swaudc WHERE onode = node_key+1.
              APPEND ll_select TO gt_swaudc.
            ENDIF.

            PERFORM refresh_tree.

          WHEN 'INFO'.
            READ TABLE gt_swaudc INTO ll_swaudc
                                 WITH KEY onode = node_key+1
                                 BINARY SEARCH.
            CHECK sy-subrc = 0.

            l_dokclass = 'UO'.
            l_dokname  = ll_swaudc-object.
            CALL FUNCTION 'HELP_OBJECT_SHOW'
                 EXPORTING
                      dokclass         = l_dokclass
                      dokname          = l_dokname
                 TABLES
                      links            = lt_links
                 EXCEPTIONS
                      object_not_found = 1
                      sapscript_error  = 2
                      OTHERS           = 3.
            IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
        ENDCASE.
    ENDCASE.
  ENDMETHOD.

*---------------------------------------------------------------------*
*       METHOD item_double_click
*---------------------------------------------------------------------*
* This method handles the double click event of tree control instance *
*---------------------------------------------------------------------*
*      -->NODE_KEY   Key of the node
*      -->ITEM_NAME  Name of the column clicked
*---------------------------------------------------------------------*
  METHOD item_double_click.
    DATA: l_dokclass TYPE dsysh-dokclass,
          l_dokname  TYPE /psyng/swaudc2-object,
          lt_links   TYPE TABLE OF tline.

    FIELD-SYMBOLS: <swaudc> LIKE LINE OF gt_swaudc.


*   Only for clicking on the authorization object, no other place
    CHECK node_key(1) = 'O' AND item_name = 'swaudid'.

    READ TABLE gt_swaudc ASSIGNING <swaudc>
                         WITH KEY onode = node_key+1
                         BINARY SEARCH.
    CHECK sy-subrc = 0.

    l_dokclass = 'UO'.
    l_dokname  = <swaudc>-object.
    CALL FUNCTION 'HELP_OBJECT_SHOW'
         EXPORTING
              dokclass         = l_dokclass
              dokname          = l_dokname
         TABLES
              links            = lt_links
         EXCEPTIONS
              object_not_found = 1
              sapscript_error  = 2
              OTHERS           = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
