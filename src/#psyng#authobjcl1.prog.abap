*----------------------------------------------------------------------*
* INCLUDE PROGRAM       : /PSYNG/AUTHOBJCL1
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
    DATA: ll_faobj              TYPE t_faobj,
          ll_select             TYPE t_faobj,
          lt_autotab            TYPE TABLE OF t_faobj,
          l_valueset            TYPE t_faobj-valueset,
          l_valueset_count      TYPE i,
          ls_node               TYPE treev_node,
          ls_tobj               TYPE tobj,
          l_node_key_funid      TYPE tv_nodekey,
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
          l_dokname             TYPE /psyng/faobj2-object,
          lt_links              TYPE TABLE OF tline.

    FIELD-SYMBOLS: <fld> TYPE tobj-fiel1.


*   Cannot push buttons in display mode
    IF gf_dispchg = gc_display
    AND ( node_key(1) <> 'O' OR item_name <> 'INFO' ).
      MESSAGE i151(/psyng/sw).
      EXIT.
    ENDIF.

    g_node_key = node_key.
    REFRESH gt_select.

    CASE node_key(1).
      WHEN 'T'.              "Transaction
        IF item_name = 'VALUEFROM'.    "Add new auth. object
*         Get new authorization object from user
          CLEAR gl_tobjt-object.
          CALL SCREEN 900 STARTING AT 3 10.

          CHECK sy-ucomm = 'CONTINUE'.

*         Check that object does not already exist
          READ TABLE gt_faobj WITH KEY tnode  = node_key+1
                                       object = gl_tobjt-object
                              TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            MESSAGE i101(/psyng/sw).
            EXIT.
          ENDIF.

*         Add transaction to internal table
          READ TABLE gt_faobj INTO ll_faobj WITH KEY tnode = node_key+1.

          SELECT SINGLE objct INTO ll_faobj-object FROM tobj
                        WHERE objct = gl_tobjt-object.
          IF sy-subrc = 0.
*           Get object description
            SELECT SINGLE ttext INTO ll_faobj-otext FROM tobjt
                          WHERE langu  = sy-langu
                            AND object = ll_faobj-object.
          ELSE.
            CLEAR ll_faobj-otext.
            MESSAGE i398(00) WITH text-t03 gl_tobjt-object text-e04.
          ENDIF.

          ll_faobj-object = gl_tobjt-object.
          ll_faobj-valueset = 1.
          ls_tobj-objct = ll_faobj-object.
          PERFORM get_object_fields CHANGING ls_tobj.
          CLEAR: ll_faobj-field, ll_faobj-val_from, ll_faobj-val_to.

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
                CLEAR ll_faobj-ddtext.
                APPEND ll_faobj TO gt_faobj.
              ENDIF.

              EXIT.
            ENDIF.

            ll_faobj-field = <fld>.
            PERFORM get_field_name USING ll_faobj-field
                                   CHANGING ll_faobj-ddtext.
            APPEND ll_faobj TO gt_faobj.
          ENDDO.

          PERFORM mark_changes USING ll_faobj-funid ll_faobj-tcode
                                     ll_faobj-object.
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

          LOOP AT gt_faobj INTO ll_faobj WHERE tnode = node_key+1.
*BOC:HBHALLA (PN-12804) (15/04/25)
*Wrong gt_changes entry due to passing of gt_faobj rather ll_faobj.
**            PERFORM mark_changes USING gt_faobj-funid gt_faobj-tcode
**                                       gt_faobj-object.
            PERFORM mark_changes USING ll_faobj-funid ll_faobj-tcode
                                       ll_faobj-object.
*EOC:HBHALLA (PN-12804) (15/04/25)
          ENDLOOP.

*----get where condition om start changes
          TYPES: BEGIN OF ty_name,
                   sign   TYPE /psyng/range_fioriid-sign,
                   option TYPE /psyng/range_fioriid-option,
                   low    TYPE usobt_c-name,
                   high   TYPE usobt_c-name,
                 END OF ty_name.
          DATA: lr_name  TYPE TABLE OF ty_name,
                ls_name  LIKE LINE OF lr_name,
                lt_usobt TYPE TABLE OF usobt_c,
                ls_usobt LIKE LINE OF lt_usobt.
          IF ll_faobj-type = 'F'.
*---get hashkey
            PERFORM get_appid_hashkey
            TABLES lt_usobt
              USING ll_faobj-fioriid.

            LOOP AT lt_usobt INTO ls_usobt.
              ls_name-sign = 'I'.
              ls_name-option = 'EQ'.
              ls_name-low = ls_usobt-name.
              APPEND ls_name TO lr_name.
            ENDLOOP.
          ELSE." tcode
*            l_name = ll_faobj-tcode.
            ls_name-sign = 'I'.
            ls_name-option = 'EQ'.
            ls_name-low = ll_faobj-tcode.
            APPEND ls_name TO lr_name.
          ENDIF.

*         Delete existing rows from GT_FAOBJ and insert new ones
          IF NOT lr_name[] IS INITIAL.
            SELECT object field low high
              INTO (ll_faobj-object, ll_faobj-field, ll_faobj-val_from,
                    ll_faobj-val_to)
              FROM usobt_c
             WHERE name IN lr_name.

              IF sy-dbcnt = 1.
                DELETE gt_faobj WHERE tnode = node_key+1.
              ENDIF.

*           Get object text
              SELECT SINGLE ttext INTO ll_faobj-otext FROM tobjt
                            WHERE langu = sy-langu
                              AND object = ll_faobj-object.

              APPEND ll_faobj TO lt_autotab.
            ENDSELECT.
          ENDIF.
          IF sy-subrc <> 0 and ll_faobj-type <> 'F'.
            MESSAGE e398(00) WITH text-e05.
          ENDIF.

*---add s_service object for appid
          IF  ll_faobj-type = 'F'.
            READ TABLE lt_autotab INTO ll_faobj INDEX 1.
            ll_faobj-object = 'S_SERVICE'.
*Get object text
            SELECT SINGLE ttext INTO ll_faobj-otext FROM tobjt
                          WHERE langu = sy-langu
                            AND object = ll_faobj-object.
            ll_faobj-field = 'SRV_TYPE'.
            ll_faobj-val_from   = 'HT'.
            APPEND ll_faobj TO lt_autotab.
*assign service(hash key)
            LOOP AT lt_usobt INTO ls_usobt.
              ll_faobj-field = 'SRV_NAME'.
              ll_faobj-val_from   = ls_usobt-name.
              APPEND ll_faobj TO lt_autotab.
            ENDLOOP.
          ENDIF.

*         Populate valueset and node counts and append to GT_FAOBJ
          LOOP AT lt_autotab INTO ll_faobj.
            ll_faobj-valueset = 1.    "Always value set 1 when auto-fill
            PERFORM get_field_name USING ll_faobj-field
                                   CHANGING ll_faobj-ddtext.
            APPEND ll_faobj TO gt_faobj.
            PERFORM mark_changes USING ll_faobj-funid ll_faobj-tcode
                                       ll_faobj-object.
          ENDLOOP.

          PERFORM refresh_tree.
          REFRESH gt_select.
        ENDIF.

      WHEN 'G'.              "Value set
        CASE item_name.
          WHEN 'VALUEFROM'.    "Edit value set
            REFRESH gt_select.
            SPLIT node_key+1 AT '|' INTO l_onode l_valueset.
            LOOP AT gt_faobj INTO ll_faobj WHERE onode = l_onode
                                             AND valueset = l_valueset.
              APPEND ll_faobj TO gt_select.
            ENDLOOP.

          WHEN 'VALUETO'.      "Delete value set
            REFRESH gt_select.
            PERFORM save_value_set.
        ENDCASE.

      WHEN 'O'.              "Object
        CASE item_name.
          WHEN 'VALUEFROM'.    "Add value set
            LOOP AT gt_faobj INTO ll_faobj WHERE onode = node_key+1.
              ll_select = ll_faobj.

              IF l_valueset <> ll_faobj-valueset.
                ADD 1 TO l_valueset_count.
                l_valueset = ll_faobj-valueset.

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
*             If no rows were found, that means that all other value
*             sets were deleted.
              READ TABLE gt_del_vs INTO gt_faobj
                         WITH KEY onode = node_key+1.

              IF sy-subrc = 0.
                ll_faobj           = gt_faobj.
                ll_select          = ll_faobj.
                ll_select-valueset = l_valueset_count.
              ELSE.
*               No existing valueset was ever there
                ADD 1 TO l_valueset_count.
                ll_faobj = gt_faobj.
                ll_select          = ll_faobj.
                ll_select-valueset = l_valueset_count.
              ENDIF.

              CLEAR: ll_select-field, ll_select-val_from,
                     ll_select-val_to, ll_select-ddtext.
              ls_tobj-objct = ll_faobj-object.
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
                    APPEND ll_select TO gt_faobj.
                  ENDIF.

                  EXIT.
                ENDIF.

                ll_select-field = <fld>.
                PERFORM get_field_name USING ll_select-field
                                       CHANGING ll_select-ddtext.
                APPEND ll_select TO gt_faobj.
              ENDDO.

              PERFORM mark_changes USING ll_faobj-funid ll_faobj-tcode
                                         ll_faobj-object.
            ELSE.
              ll_select-valueset = l_valueset_count.
              CLEAR: ll_select-field, ll_select-val_from,
                     ll_select-val_to, ll_select-ddtext.

              ls_tobj-objct = ll_faobj-object.
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
                    APPEND ll_select TO gt_faobj.
                  ENDIF.

                  EXIT.
                ENDIF.

                ll_select-field = <fld>.
                PERFORM get_field_name USING ll_select-field
                                       CHANGING ll_select-ddtext.
                APPEND ll_select TO gt_faobj.
              ENDDO.

              PERFORM mark_changes USING ll_faobj-funid ll_faobj-tcode
                                         ll_faobj-object.
            ENDIF.

            PERFORM refresh_tree.

          WHEN 'VALUETO'.              "Delete object

            READ TABLE gt_faobj INTO ll_faobj
                       WITH KEY onode = node_key+1.
            l_index = sy-tabix.

            PERFORM mark_changes USING ll_faobj-funid ll_faobj-tcode
                                       ll_faobj-object.

*           Check for other rows for this TCode
            LOOP AT gt_faobj TRANSPORTING NO FIELDS
                    WHERE funid = ll_faobj-funid
                      AND tcode = ll_faobj-tcode
                      AND onode <> node_key+1.
              EXIT.
            ENDLOOP.

            IF sy-subrc = 0.
              DELETE gt_faobj WHERE onode = node_key+1.
            ELSE.
              CLEAR ll_select.
              ll_select-funid = ll_faobj-funid.
              ll_select-description = ll_faobj-description.
              ll_select-tcode = ll_faobj-tcode.
              ll_select-ttext = ll_faobj-ttext.
              ll_select-fioriid = ll_faobj-fioriid.
              ll_select-appname = ll_faobj-appname.
              ll_select-type = ll_faobj-type.
              DELETE gt_faobj WHERE onode = node_key+1.
              APPEND ll_select TO gt_faobj.
            ENDIF.

            PERFORM refresh_tree.

          WHEN 'OBJ_OR'.
*           get the current status of the first record
            read table gt_faobj INTO ll_faobj
            with key onode = node_key+1.
            if sy-subrc = 0.
*               Switch And/Or
                CASE ll_faobj-obj_or.
                  WHEN 'OR'.
                    CLEAR ll_faobj-obj_or.
                  WHEN space.
                    ll_faobj-obj_or = 'OR'.
                ENDCASE.
                MODIFY  gt_faobj
                  FROM ll_faobj
                  TRANSPORTING obj_or
                  where  onode = ll_faobj-onode.
                IF sy-subrc <> 0.
                  MESSAGE e020(/psyng/sw) WITH text-008.
                ENDIF.
            endif.
            PERFORM mark_changes USING ll_faobj-funid ll_faobj-tcode
                                       ll_faobj-object.

            PERFORM refresh_tree.
            g_node_key = node_key.

          WHEN 'INFO'.
            READ TABLE gt_faobj INTO ll_faobj
                                WITH KEY onode = node_key+1
                                BINARY SEARCH.
            CHECK sy-subrc = 0.

            l_dokclass = 'UO'.
            l_dokname  = ll_faobj-object.
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
          l_dokname  TYPE /psyng/faobj2-object,
          lt_links   TYPE TABLE OF tline.

    FIELD-SYMBOLS: <faobj> LIKE LINE OF gt_faobj.


*   Only for clicking on the field of valueset or the Auth Object
    CHECK ( node_key(1) = 'V' OR node_key(1) = 'O' )
    AND item_name = 'FUNID'.

    IF node_key(1) = 'V'.
*     Cannot do this in display mode
      IF gf_dispchg = gc_display.
        MESSAGE i151(/psyng/sw).
        EXIT.
      ENDIF.

*     Toggle field level AND/OR
      READ TABLE gt_faobj ASSIGNING <faobj>
                          WITH KEY rec_num = node_key+1
                          BINARY SEARCH.
      CHECK sy-subrc = 0.

      LOOP AT gt_faobj ASSIGNING <faobj> WHERE funid    = <faobj>-funid
                                           AND tcode    = <faobj>-tcode
                                           AND object   = <faobj>-object
                                         AND valueset = <faobj>-valueset
                                           AND field    = <faobj>-field.
        IF <faobj>-fld_and IS INITIAL.
          <faobj>-fld_and = 'X'.
        ELSE.
          CLEAR <faobj>-fld_and.
        ENDIF.
      ENDLOOP.

      PERFORM mark_changes USING <faobj>-funid <faobj>-tcode
                                 <faobj>-object.
      PERFORM refresh_tree.
    ELSE.
      READ TABLE gt_faobj ASSIGNING <faobj>
                          WITH KEY onode = node_key+1
                          BINARY SEARCH.
      CHECK sy-subrc = 0.

      l_dokclass = 'UO'.
      l_dokname  = <faobj>-object.
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
    ENDIF.
  ENDMETHOD.
ENDCLASS.
