*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECUWELLF01
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SECUWELLF01                                         *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  user_command_0104
*&---------------------------------------------------------------------*
*       Handle user commands from screen 104
*----------------------------------------------------------------------*
FORM user_command_0104.
  DATA: new_node TYPE /psyng/mtrees.
  DATA: ip_lines TYPE i.
  DATA : lt_param         TYPE TABLE OF rsparams WITH HEADER LINE,
         success          VALUE 'Y',
         l_long_ques(200) TYPE c,
         l_index          TYPE i,
         l_saptechname    TYPE /psyng/position-saptechname,
         l_bysimu         TYPE /psyng/bapiflagx,
         lt_roles         TYPE TABLE OF t_role WITH HEADER LINE,
         lt_simuroles     TYPE TABLE OF t_role WITH HEADER LINE,
         lt_node_keys     TYPE treev_nks.

  DATA: BEGIN OF lt_userid OCCURS 0,
          userid TYPE /psyng/usrdet-userid,
        END OF lt_userid.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_positionid
            USING sec_actvt /psyng/position-positionid.
  ENDIF.

  upd_flag = space.

* Unlock previous position id
  IF /psyng/position-positionid <> /psyng/posndet-positionid.
    CALL FUNCTION 'DEQUEUE_/PSYNG/POSITION'
      EXPORTING
        positionid = /psyng/position-positionid.
  ENDIF.

  MOVE /psyng/posndet-positionid TO /psyng/position-positionid.
  crt_dte = sy-datum.
  crt_tme = sy-uzeit.
**  rkanaka
  CLEAR new_node.
  CLEAR /psyng/user.
  populated = 'X'.
  CLEAR sod_conflict.

  CASE ok_code.
    WHEN 'SYNCH'.
      CHECK NOT /psyng/position-positionid IS INITIAL.
      REFRESH lt_param[].
      lt_param-selname = 'PPOSIT'.
      lt_param-sign    = 'I'.
      lt_param-low     = /psyng/position-positionid.
      APPEND lt_param.

      lt_param-selname = 'POSIT'.
      lt_param-sign    = 'I'.
      lt_param-low     = 'X'.
      APPEND lt_param.

      lt_param-selname = 'ROLES'.
      lt_param-sign    = 'I'.
      lt_param-low     = space.
      APPEND lt_param.

      lt_param-selname = 'USER'.
      lt_param-sign    = 'I'.
      lt_param-low     = space.
      APPEND lt_param.

      SUBMIT /psyng/weavsync WITH SELECTION-TABLE lt_param AND RETURN.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'UPDT'.
      dell_all = space.
      IF upd_flag  = space.
        upd_flag = 'X'.
      ENDIF.
      REFRESH local_node_table.
      CLEAR next_node_key_right.
      DESCRIBE TABLE i_prole LINES ip_lines.
      SORT i_prole BY roleid.

      IF ip_lines > 0.
        next_node_key_right = ip_lines.                     " - 1.
      ENDIF.

      CLEAR new_node.

      CALL METHOD g_left_tree->get_selected_nodes
        CHANGING
          node_key_table               = lt_node_keys
        EXCEPTIONS
          cntl_system_error            = 1
          dp_error                     = 2
          failed                       = 3
          multiple_node_selection_only = 4
          OTHERS                       = 5.

      LOOP AT lt_node_keys INTO new_node-node_key.
        CHECK new_node-node_key <> 'Root'
        AND NOT new_node-node_key IS INITIAL.

        READ TABLE i_prole WITH KEY roleid = new_node-node_key
                   TRANSPORTING NO FIELDS.
        CHECK sy-subrc NE 0.

        i_prole-roleid = new_node-node_key.
        APPEND i_prole.

        SELECT SINGLE description saptechname        "#EC CI_SEL_NESTED
                      INTO (/psyng/rolehdr-description,
                            /psyng/rolehdr-saptechname)
                      FROM /psyng/rolehdr
                      WHERE roleid = i_prole-roleid.

        CLEAR new_node.
        new_node-node_key = i_prole-roleid.
        new_node-relatkey = 'Root'.
        new_node-relatship = cl_gui_simple_tree=>relat_last_child.

        IF gf_disp_pfcg IS INITIAL.
          CONCATENATE i_prole-roleid '-' /psyng/rolehdr-description
                      INTO new_node-text.
        ELSE.
          CONCATENATE i_prole-roleid '-' /psyng/rolehdr-saptechname
                      INTO new_node-text.
        ENDIF.

        APPEND new_node TO local_node_table.
        APPEND new_node TO right_node_table.
        ADD 1 TO next_node_key_right.

        PERFORM populate_transactions.
      ENDLOOP.

      IF NOT local_node_table[] IS INITIAL.
        CALL METHOD g_right_tree->add_nodes
          EXPORTING
            table_structure_name           = '/PSYNG/MTREES'
            node_table                     = local_node_table
          EXCEPTIONS
            failed                         = 1
            error_in_node_table            = 2
            dp_error                       = 3
            table_structure_name_not_found = 4
            OTHERS                         = 5.

        CALL METHOD g_right_tree->expand_root_nodes
          EXPORTING
            expand_subtree      = 'X'
          EXCEPTIONS
            failed              = 1
            illegal_level_count = 2
            cntl_system_error   = 3.
      ENDIF.

      REFRESH conflict.
      REFRESH conflict2.

      PERFORM populate_conflict.
      PERFORM populate_conflict2.

    WHEN 'CHANGES'.
      SUBMIT /psyng/positonhist VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'CREATE'.
      PERFORM authority_check_positionid
              USING act_create /psyng/position-positionid.
      sec_actvt = act_create.
      PERFORM exit_without_save.
      CHECK gf_answer = '1'.

*     Unlock position id
      IF NOT /psyng/position-positionid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/POSITION'
          EXPORTING
            positionid = /psyng/position-positionid.
      ENDIF.

      first_time = space.
      old_funct_current_line = 0.
      REFRESH: g_jobtxn_itab, conflict2.
      CLEAR: /psyng/position, /psyng/posndet, gf_data_change.
      PERFORM refresh_tree_change.

    WHEN 'DELALL'.
      first_time = space.
      dell_all = 'X'.
      LOOP AT right_node_table INTO new_node WHERE node_key <> 'Root'.
        CALL METHOD g_right_tree->delete_node
          EXPORTING
            node_key = new_node-node_key
          EXCEPTIONS
            failed   = 1
            OTHERS   = 5.

        DELETE right_node_table.
      ENDLOOP.
      REFRESH i_prole.
      REFRESH conflict2.
      REFRESH g_jobtxn_itab.

    WHEN 'DISPLAY'.
      dell_all = space.
      CLEAR new_node.
      REFRESH g_jobtxn_itab.
      CALL METHOD g_right_tree->get_selected_node
        IMPORTING
          node_key                   = new_node-node_key
        EXCEPTIONS
          failed                     = 1
          single_node_selection_only = 2
          cntl_system_error          = 3
          OTHERS                     = 4.

      IF new_node-node_key = 'Root' OR new_node-node_key IS INITIAL.
        MESSAGE i113(/psyng/sw) WITH text-e17.
        EXIT.
      ENDIF.

      READ TABLE i_prole WITH KEY roleid = new_node-node_key.
      SELECT * FROM /psyng/roletrans
             WHERE roleid = i_prole-roleid.

        g_jobtxn_itab-tcode = /psyng/roletrans-tcode.

        SELECT SINGLE * FROM tstct
                      WHERE tcode = /psyng/roletrans-tcode
                        AND sprsl = sy-langu.
        g_jobtxn_itab-ttext = tstct-ttext.
        APPEND g_jobtxn_itab.
      ENDSELECT.

    WHEN 'DELNODE'.
      dell_all = space.
      CLEAR new_node.
      CALL METHOD g_right_tree->get_selected_node
        IMPORTING
          node_key                   = new_node-node_key
        EXCEPTIONS
          failed                     = 1
          single_node_selection_only = 2
          cntl_system_error          = 3
          OTHERS                     = 4.
      IF new_node-node_key <> space.
        IF new_node-node_key = 'Root'.
          MESSAGE i113(/psyng/sw) WITH text-e17.
          EXIT.
        ENDIF.

        DELETE right_node_table WHERE node_key = new_node-node_key.
        DELETE i_prole WHERE roleid = new_node-node_key.
        REFRESH g_role_trans_itab.
        LOOP AT i_prole.
          SELECT * FROM /psyng/roletrans             "#EC CI_SEL_NESTED
                 WHERE roleid = i_prole-roleid.

            g_role_trans_itab-tcode = /psyng/roletrans-tcode.

            SELECT SINGLE * FROM tstct
                          WHERE tcode = /psyng/roletrans-tcode
                            AND sprsl = sy-langu.

            g_role_trans_itab-ttext = tstct-ttext.
            APPEND g_role_trans_itab.
          ENDSELECT.
        ENDLOOP.

        CALL METHOD g_right_tree->delete_node
          EXPORTING
            node_key = new_node-node_key
          EXCEPTIONS
            failed   = 1
            OTHERS   = 5.
      ENDIF.
      REFRESH conflict.
      REFRESH conflict2.
      PERFORM populate_conflict.
      PERFORM populate_conflict2.

    WHEN 'ENTER'.
      PERFORM authority_check_positionid
              USING sec_actvt /psyng/position-positionid.

      dell_all = space.
      IF first_time = space.
        first_time = 'X'.

*       Check if position ID already exists
        SELECT SINGLE * FROM /psyng/position
                      WHERE positionid = /psyng/posndet-positionid.
        IF sy-subrc <> 0 AND /psyng/posndet-positionid <> space.
          MESSAGE w100(/psyng/sw).

          LOOP AT right_node_table INTO new_node
                  WHERE node_key <> 'Root'.
            CALL METHOD g_right_tree->delete_node
              EXPORTING
                node_key = new_node-node_key
              EXCEPTIONS
                failed   = 1
                OTHERS   = 5.

            DELETE right_node_table.
          ENDLOOP.

          CLEAR: /psyng/position-description,
                 /psyng/position-saptechname,
                 i_prole[].
        ELSE.
          CALL METHOD g_right_tree->delete_all_nodes
            EXCEPTIONS
              failed            = 1
              cntl_system_error = 2
              OTHERS            = 3.

**************************
          REFRESH i_prole.
***************
          DELETE right_node_table WHERE node_key <> 'Root'.
          CLEAR next_node_key_right.

          SELECT * FROM /psyng/posndet
                 WHERE positionid = /psyng/posndet-positionid.

            i_prole-roleid = /psyng/posndet-roleid.
            APPEND i_prole.

            SELECT SINGLE * FROM /psyng/rolehdr      "#EC CI_SEL_NESTED
                           WHERE roleid = /psyng/posndet-roleid.
            IF sy-subrc <> 0.
              /psyng/rolehdr-description = text-166.
            ENDIF.

            CLEAR new_node.
            new_node-node_key = /psyng/posndet-roleid.
            new_node-relatkey = 'Root'.
            new_node-relatship = cl_gui_simple_tree=>relat_last_child.

            IF gf_disp_pfcg IS INITIAL.
              CONCATENATE /psyng/posndet-roleid '-'
                          /psyng/rolehdr-description INTO new_node-text.
            ELSE.
              CONCATENATE /psyng/posndet-roleid '-'
                          /psyng/rolehdr-saptechname INTO new_node-text.
            ENDIF.

            APPEND new_node TO right_node_table.
            ADD 1 TO next_node_key_right.
          ENDSELECT.

          PERFORM populate_transactions.

          CALL METHOD g_right_tree->add_nodes
            EXPORTING
              table_structure_name           = '/PSYNG/MTREES'
              node_table                     = right_node_table
            EXCEPTIONS
              failed                         = 1
              error_in_node_table            = 2
              dp_error                       = 3
              table_structure_name_not_found = 4
              OTHERS                         = 5.

          IF NOT /psyng/position-positionid IS INITIAL
          AND gf_dispchg = gc_change.
*           Lock position ID
            CALL FUNCTION 'ENQUEUE_/PSYNG/POSITION'
              EXPORTING
                positionid     = /psyng/position-positionid
              EXCEPTIONS
                foreign_lock   = 1
                system_failure = 2
                OTHERS         = 3.
            IF sy-subrc <> 0.
              gf_dispchg = gc_display.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      PERFORM populate_conflict.
      PERFORM populate_conflict2.

    WHEN 'FIND'.
      PERFORM find_role_tree.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'TOG_PFCG'.         "Toggle technical role names/description
      PERFORM toggle_pfcg_desc.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'DELETE'.
      PERFORM authority_check_positionid
              USING act_delete /psyng/position-positionid.
      sec_actvt = act_delete.
*     Check if position is tied to any users
      SELECT userid INTO TABLE lt_userid FROM /psyng/usrdet
             WHERE positionid = /psyng/position-positionid.
      IF NOT lt_userid[] IS INITIAL.
        LOOP AT lt_userid.
          CONCATENATE l_long_ques lt_userid-userid
                      INTO l_long_ques SEPARATED BY space.
        ENDLOOP.

        CONCATENATE text-168 l_long_ques '.' text-q01 text-169
                    INTO l_long_ques SEPARATED BY space.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = text-027
            text_question         = l_long_ques
            text_button_1         = text-123
            icon_button_1         = 'ICON_DELETE'
            text_button_2         = text-124
            icon_button_2         = 'ICON_SYSTEM_CANCEL'
            default_button        = '2'
            display_cancel_button = ' '
          IMPORTING
            answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
        CHECK popup_answer = '1'.
      ENDIF.

      CONCATENATE text-026 /psyng/posndet-positionid
                  INTO popup_question SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = popup_question
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

*     Populate History
      PERFORM populate_history USING '/PSYNG/POSITION' 'POSITIONID'
              space /psyng/posndet-positionid space 'D'.
      PERFORM populate_history USING '/PSYNG/POSITION'
              /psyng/posndet-positionid 'SAPTECHNAME'
              /psyng/position-saptechname space 'D'.

      SELECT * FROM /psyng/posndet
             WHERE positionid = /psyng/posndet-positionid.
        PERFORM populate_history USING '/PSYNG/POSNDET'
                /psyng/posndet-positionid 'ROLEID' /psyng/posndet-roleid
                space 'D'.
      ENDSELECT.
*     End History

*     Delete from positions if necessary
      LOOP AT lt_userid.
        DELETE FROM /psyng/usrdet                   "#EC CI_IMUD_NESTED
                    WHERE userid     = lt_userid-userid
                      AND positionid = /psyng/posndet-positionid.
      ENDLOOP.

      DELETE FROM /psyng/position
                  WHERE positionid = /psyng/posndet-positionid.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        CONCATENATE text-007 /psyng/posndet-positionid text-126
                    INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
      ENDIF.

      DELETE FROM /psyng/posndet
                  WHERE positionid = /psyng/posndet-positionid.
      IF sy-subrc = 0.
        REFRESH i_prole.
        LOOP AT right_node_table INTO new_node WHERE node_key <> 'Root'.

          CALL METHOD g_right_tree->delete_node
            EXPORTING
              node_key = new_node-node_key
            EXCEPTIONS
              failed   = 1
              OTHERS   = 5.
        ENDLOOP.

        REFRESH right_node_table.
      ENDIF.

      CALL FUNCTION 'DEQUEUE_/PSYNG/POSITION'
        EXPORTING
          positionid = /psyng/position-positionid.

      CLEAR: gf_data_change, /psyng/position, /psyng/posndet,
             conflict2[].

    WHEN 'SAVE'.
      IF /psyng/position-positionid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-007.
      ENDIF.

      PERFORM authority_check_positionid
              USING act_change /psyng/position-positionid.
      sec_actvt = act_change.
*      SELECT SINGLE * FROM /psyng/position INTO old_position
*                WHERE positionid = /psyng/posndet-positionid.

      SELECT SINGLE positionid saptechname
        FROM /psyng/position INTO CORRESPONDING FIELDS OF   old_position
                WHERE positionid = /psyng/posndet-positionid.


      IF sy-subrc <> 0.                "Insert
        dell_all = space.
        /psyng/position-create_usr = g_current_user."sy-uname. C0700
        /psyng/position-create_dat = sy-datum.
        /psyng/position-create_tim = sy-uzeit.
        /psyng/position-change_usr = g_current_user."sy-uname. C0700
        /psyng/position-change_dat = sy-datum.
        /psyng/position-change_tim = sy-uzeit.
        INSERT /psyng/position.
        IF sy-subrc <> 0.
          MESSAGE e122(/psyng/sw).  " Data Not Saved
          EXIT.
        ELSE.
          MESSAGE s120(/psyng/sw).  " Data Saved
        ENDIF.

*       Populate History
        PERFORM populate_history USING '/PSYNG/POSITION' 'POSITIONID'
                space /psyng/posndet-positionid space 'I'.
        PERFORM populate_history USING '/PSYNG/POSITION'
                /psyng/posndet-positionid 'SAPTECHNAME'
                /psyng/position-saptechname space 'I'.
*       End History

        DELETE FROM /psyng/posndet
                    WHERE positionid = /psyng/posndet-positionid.
*======== Capture tree data in Detail table.
        LOOP AT i_prole.
          /psyng/posndet-roleid = i_prole-roleid.
          INSERT /psyng/posndet.
*         Populate History
          PERFORM populate_history USING '/PSYNG/POSNDET'
                  /psyng/posndet-positionid 'ROLEID'
                  /psyng/posndet-roleid space 'I'.
*         End History
        ENDLOOP.

        first_time = 'X'.
      ELSE.                            "Update
        positionid = old_position-positionid.

*       Populate History
        PERFORM populate_history USING '/PSYNG/POSITION' 'POSITIONID'
                space /psyng/posndet-positionid space 'U'.

        IF old_position-saptechname <> /psyng/position-saptechname.
          PERFORM populate_history USING '/PSYNG/POSITION'
                  /psyng/posndet-positionid 'SAPTECHNAME'
                  old_position-saptechname /psyng/position-saptechname
                  'U'.
        ENDIF.

        SELECT * FROM /psyng/posndet
               WHERE positionid = /psyng/posndet-positionid.
          READ TABLE i_prole WITH KEY roleid = /psyng/posndet-roleid.
          IF sy-subrc <> 0.
            PERFORM populate_history USING '/PSYNG/POSNDET'
                    /psyng/posndet-positionid 'ROLEID'
                    /psyng/posndet-roleid space 'D'.
          ENDIF.
        ENDSELECT.

        LOOP AT i_prole.
          SELECT SINGLE * FROM /psyng/posndet        "#EC CI_SEL_NESTED
                        WHERE positionid = /psyng/posndet-positionid
                          AND roleid     = i_prole-roleid.
          IF sy-subrc <> 0.
            PERFORM populate_history USING '/PSYNG/POSNDET'
                    /psyng/posndet-positionid 'ROLEID' i_prole-roleid
                    space 'I'.
          ENDIF.
        ENDLOOP.
*       End History

        /psyng/position-change_usr = g_current_user."sy-uname. C0700
        /psyng/position-change_dat = sy-datum.
        /psyng/position-change_tim = sy-uzeit.
        UPDATE /psyng/position.
        DELETE FROM /psyng/posndet
                    WHERE positionid = /psyng/posndet-positionid.
*======== Capture tree data in Detail table.
        LOOP AT i_prole.
          /psyng/posndet-roleid = i_prole-roleid.
          INSERT /psyng/posndet.
          IF sy-subrc NE 0.
            success = 'N'.
          ENDIF.
        ENDLOOP.

        IF success = 'Y'.
          MESSAGE s120(/psyng/sw).  " Data Saved
        ELSE.
          MESSAGE w122(/psyng/sw).  " Data Not Saved
        ENDIF.

        CLEAR gf_data_change.
      ENDIF.


    WHEN 'CONDISP'.
      PERFORM display_conflict.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'UPDOWN'.                          "Upload/download
      SUBMIT /psyng/sw_068 VIA SELECTION-SCREEN AND RETURN.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'SODCON'.
      lt_roles-sign = 'I'.
      lt_roles-option = 'EQ'.

      l_saptechname = /psyng/position-saptechname.
      IF NOT l_saptechname IS INITIAL.
*       Check if PFCG role exists
        SELECT SINGLE mandt INTO sy-mandt FROM agr_define
                      WHERE agr_name = /psyng/position-saptechname.
        IF sy-subrc <> 0.
          CLEAR l_saptechname.
          MESSAGE i410(s#) WITH /psyng/position-saptechname.
        ENDIF.
      ENDIF.

      PERFORM objcheck_pos.

      IF l_saptechname IS INITIAL.
        IF NOT gt_roles[] IS INITIAL.
          CHECK sy-ucomm <> 'NOCONTINUE'.

          lt_simuroles-sign   = 'I'.
          lt_simuroles-option = 'EQ'.
          LOOP AT gt_roles WHERE saptechname <> space.
            ADD 1 TO l_index.

            IF l_index = 1.
              lt_roles-low = gt_roles-saptechname.
              APPEND lt_roles.
              CONTINUE.
            ENDIF.

            lt_simuroles-low = gt_roles-saptechname.
            APPEND lt_simuroles.
          ENDLOOP.

          IF NOT lt_simuroles[] IS INITIAL.
            l_bysimu = 'X'.
          ENDIF.
        ENDIF.
      ELSE.
        lt_roles-low = /psyng/position-saptechname.
        APPEND lt_roles.
      ENDIF.



      CHECK NOT lt_roles[] IS INITIAL.
*      SUBMIT /psyng/sodreport_org
      SUBMIT /psyng/sod_syswide_byrole
*            WITH byrole = 'X'
*            WITH byuser = ' '
            WITH role IN lt_roles
            WITH bysimu = l_bysimu
            WITH ar_rfcs1 = 'LOCAL'
            WITH ar_rfcd1 =  'LOCAL'
            WITH ar_rol_1 IN lt_simuroles
            WITH sodvrsio = g_sod_vrsio
*SF 2282
            WITH comprol = 'X'
            WITH singrol = 'X'
            AND RETURN.
      CLEAR ok_code.
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.

        PERFORM authority_check_positionid
                USING act_change /psyng/position-positionid.
        sec_actvt = act_change.

        gf_dispchg = gc_change.

        IF NOT /psyng/position-positionid IS INITIAL.
*         Lock position ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/POSITION'
            EXPORTING
              positionid     = /psyng/position-positionid
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM authority_check_positionid
                USING act_display /psyng/position-positionid.
        sec_actvt = act_display.
        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.
        ok_code = 'ENTER'.
        PERFORM user_command_0104.

        gf_dispchg = gc_display.

*       Unlock position id
        IF NOT /psyng/position-positionid IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/POSITION'
            EXPORTING
              positionid = /psyng/position-positionid.
        ENDIF.
      ENDIF.

      CLEAR: ok_code, sy-ucomm.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

*     Unlock position id
      IF NOT /psyng/position-positionid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/POSITION'
          EXPORTING
            positionid = /psyng/position-positionid.
      ENDIF.

      CLEAR: first_time, gf_data_change, g_role_trans_itab,
             g_role_trans_itab[], conflict, conflict[], conflict2,
             conflict2[], itab_funct1, itab_funct1[], itab_con,
             itab_con[], g_role_trans_itab2, g_role_trans_itab2[],
             /psyng/position, /psyng/posndet, /psyng/roletrans,
             /psyng/rolehdr, populated.

      CLEAR sec_actvt.
    WHEN 'FS'.
      g_fullscreen = '0104'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

  ENDCASE.
ENDFORM.                    " user_command_0104

*---------------------------------------------------------------------*
*       FORM set_default_sodversion                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_SOD                                                         *
*  -->  L_UNAME                                                       *
*---------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
        lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
        ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE'     "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = l_uname
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return.
  .

ENDFORM.                    " set_default_sodversion


*&---------------------------------------------------------------------*
*&      Form  user_command_0105
*&---------------------------------------------------------------------*
*       Handle user commands from screen 105
*----------------------------------------------------------------------*
FORM user_command_0105.
  DATA: new_node TYPE /psyng/mtrees.
  DATA ip_lines TYPE i.
  DATA: success VALUE 'Y'.
  DATA : lt_param     TYPE TABLE OF rsparams WITH HEADER LINE,
         lt_node_keys TYPE treev_nks.
  DATA: BEGIN OF suser OCCURS 0,
          sign(1),
          option(2),
          low       LIKE agr_define-agr_name,
          high      LIKE agr_define-agr_name,
        END OF suser.
*******************************
**SF 1665
  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.
*  * Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_userid
            USING sec_actvt /psyng/user-userid.
  ENDIF.
***SF 1665
*******************************
  IF userid <> /psyng/user-userid.
*   Unlock old user
    CALL FUNCTION 'DEQUEUE_/PSYNG/USER'
      EXPORTING
        userid = /psyng/user-userid.
  ENDIF.

  CLEAR: /psyng/position, /psyng/posndet.
  userid = /psyng/user-userid.
  crt_dte = sy-datum.
  crt_tme = sy-uzeit.

  first_mit = space.
  populated = 'X'.
  CLEAR sod_conflict.

  CASE ok_code.
    WHEN 'UPDT'.
      dell_all = space.
      IF upd_flag  = space.
        upd_flag = 'X'.
      ENDIF.
      REFRESH i_prole.
      REFRESH local_node_table.
      CLEAR next_node_key_right.
      DESCRIBE TABLE j_prole LINES ip_lines.
      SORT j_prole BY positionid.

      IF ip_lines > 0.
        next_node_key_right = ip_lines.                     " - 1.
      ENDIF.

      CLEAR new_node.
      CALL METHOD g_left_tree->get_selected_nodes
        CHANGING
          node_key_table               = lt_node_keys
        EXCEPTIONS
          cntl_system_error            = 1
          dp_error                     = 2
          failed                       = 3
          multiple_node_selection_only = 4
          OTHERS                       = 5.

      LOOP AT lt_node_keys INTO new_node-node_key.
        CHECK new_node-node_key <> 'Root'
        AND NOT new_node-node_key IS INITIAL.

        j_prole-positionid = new_node-node_key.
        READ TABLE j_prole WITH KEY positionid = j_prole-positionid
                           TRANSPORTING NO FIELDS.
        CHECK sy-subrc NE 0.
        APPEND j_prole TO j_prole.
        SELECT SINGLE description                    "#EC CI_SEL_NESTED
             INTO /psyng/position-description
                      FROM /psyng/position
                      WHERE positionid = j_prole-positionid.

        CLEAR new_node.
        new_node-node_key = j_prole-positionid.
        new_node-relatkey = 'Root'.
        new_node-relatship = cl_gui_simple_tree=>relat_last_child.
        CONCATENATE j_prole-positionid ' - ' /psyng/position-description
                                                     INTO new_node-text.
        APPEND new_node TO local_node_table.
        APPEND new_node TO right_node_table.
        ADD 1 TO next_node_key_right.
      ENDLOOP.

      IF NOT local_node_table[] IS INITIAL.
        CALL METHOD g_right_tree->add_nodes
          EXPORTING
            table_structure_name           = '/PSYNG/MTREES'
            node_table                     = local_node_table
          EXCEPTIONS
            failed                         = 1
            error_in_node_table            = 2
            dp_error                       = 3
            table_structure_name_not_found = 4
            OTHERS                         = 5.

        CALL METHOD g_right_tree->expand_root_nodes
          EXPORTING
            expand_subtree      = 'X'
          EXCEPTIONS
            failed              = 1
            illegal_level_count = 2
            cntl_system_error   = 3.
      ENDIF.

      PERFORM fill_iprole.
      PERFORM populate_transactions.
      PERFORM populate_conflict.
      PERFORM populate_conflict2.

    WHEN 'SYNCH'.
      CHECK NOT /psyng/user-userid IS INITIAL.
      REFRESH lt_param[].
      lt_param-selname = 'USER'.
      lt_param-sign    = 'I'.
      lt_param-option  = 'EQ'.
      lt_param-kind    = 'P'.
      lt_param-low     = 'X'.
      APPEND lt_param.
      lt_param-selname = 'POSIT'.
      lt_param-sign    = 'I'.
      lt_param-option  = 'EQ'.
      lt_param-kind    = 'P'.
      lt_param-low     = space.
      APPEND lt_param.
      lt_param-selname = 'ROLES'.
      lt_param-sign    = 'I'.
      lt_param-option  = 'EQ'.
      lt_param-kind    = 'P'.
      lt_param-low     = space.
      APPEND lt_param.
      lt_param-kind    = 'S'.
      lt_param-selname = 'PBNAME'.
      lt_param-sign    = 'I'.
      lt_param-option  = 'EQ'.
      lt_param-low     = /psyng/user-userid.
      APPEND lt_param.
      SUBMIT /psyng/weavsync WITH SELECTION-TABLE lt_param AND RETURN.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'CHANGES'.
      SUBMIT /psyng/userhist VIA SELECTION-SCREEN
*      WITH sodvrsio = g_sod_vrsio
      AND RETURN.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'CREATE'.
*****************************************************
*  ***SF 1665
      PERFORM authority_check_userid
          USING sec_actvt /psyng/user-userid.
      sec_actvt = act_create.
*   ***SF 1665
* *****************************************************
      PERFORM exit_without_save.
      CHECK gf_answer = '1'.

      IF userid <> /psyng/user-userid.
*       Unlock old user
        CALL FUNCTION 'DEQUEUE_/PSYNG/USER'
          EXPORTING
            userid = /psyng/user-userid.
      ENDIF.

      first_time = space.
      old_funct_current_line = 0.
      REFRESH conflict2.
      CLEAR /psyng/user.
      CLEAR /psyng/posndet.
      PERFORM refresh_tree_change.
      REFRESH i_prole.
      REFRESH j_prole.

    WHEN 'CONDISP'.
      num = '100'.
      cursor_line = cursor_line + jobconflict-top_line - 1.
      PERFORM display_conflict.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'DELALL'.
      first_time = space.
      dell_all = 'X'.
      LOOP AT right_node_table INTO new_node WHERE node_key <> 'Root'.
        CALL METHOD g_right_tree->delete_node
          EXPORTING
            node_key = new_node-node_key
          EXCEPTIONS
            failed   = 1
            OTHERS   = 5.

        DELETE right_node_table.
      ENDLOOP.
      REFRESH i_prole.
      REFRESH j_prole.
      REFRESH conflict2.

    WHEN 'DELNODE'.
      dell_all = space.
      CLEAR new_node.
      CALL METHOD g_right_tree->get_selected_node
        IMPORTING
          node_key                   = new_node-node_key
        EXCEPTIONS
          failed                     = 1
          single_node_selection_only = 2
          cntl_system_error          = 3
          OTHERS                     = 4.
      IF new_node-node_key <> space.
        IF new_node-node_key = 'Root'.
          MESSAGE i113(/psyng/sw) WITH text-e17.
          EXIT.
        ENDIF.

        CALL METHOD g_right_tree->delete_node
          EXPORTING
            node_key = new_node-node_key
          EXCEPTIONS
            failed   = 1
            OTHERS   = 5.

        DELETE right_node_table WHERE node_key = new_node-node_key.
        DELETE j_prole WHERE positionid = new_node-node_key.
        PERFORM fill_iprole.
        REFRESH g_role_trans_itab.
        REFRESH conflict2.
        REFRESH conflict.
        PERFORM populate_transactions.
        PERFORM populate_conflict.
        PERFORM populate_conflict2.
      ENDIF.

    WHEN 'ENTER'.
********************************
**SF 1665
      PERFORM authority_check_userid
             USING sec_actvt /psyng/user-userid.
**SF 1665
********************************
      dell_all = space.
      IF first_time = space.
*       Refresh Internal Tables
        REFRESH i_prole.
        REFRESH j_prole.
        first_time = 'X'.
        SELECT SINGLE * FROM /psyng/user
                      WHERE userid = /psyng/user-userid.
        IF sy-subrc <> 0 AND /psyng/user-userid <> space.
          MESSAGE w100(/psyng/sw).
          CLEAR: /psyng/user-location, /psyng/user-validdte.

          LOOP AT right_node_table INTO new_node
                  WHERE node_key <> 'Root'.
            CALL METHOD g_right_tree->delete_node
              EXPORTING
                node_key = new_node-node_key
              EXCEPTIONS
                failed   = 1
                OTHERS   = 5.

            DELETE right_node_table.
          ENDLOOP.
        ELSE.
          LOOP AT right_node_table INTO new_node
                  WHERE node_key <> 'Root'.
            CALL METHOD g_right_tree->delete_node
              EXPORTING
                node_key = new_node-node_key
              EXCEPTIONS
                failed   = 1
                OTHERS   = 5.
          ENDLOOP.

          REFRESH i_prole.
          REFRESH right_node_table.
          CLEAR next_node_key_right.
          SELECT * FROM /psyng/usrdet
               INTO /psyng/usrdet
                  WHERE userid = /psyng/user-userid.
            j_prole-positionid = /psyng/usrdet-positionid.
            APPEND j_prole TO j_prole.

            SELECT SINGLE * FROM /psyng/position     "#EC CI_SEL_NESTED
                          WHERE positionid = /psyng/usrdet-positionid.
            IF sy-subrc <> 0.
              /psyng/position-description = text-167.
            ENDIF.

            CLEAR new_node.
            new_node-node_key = /psyng/usrdet-positionid.
            new_node-relatkey = 'Root'.
            new_node-relatship = cl_gui_simple_tree=>relat_last_child.
            CONCATENATE /psyng/usrdet-positionid ' - '
                        /psyng/position-description INTO new_node-text.
            APPEND new_node TO right_node_table.
            ADD 1 TO next_node_key_right.
          ENDSELECT.

          IF sy-subrc = 0.
            CALL METHOD g_right_tree->add_nodes
              EXPORTING
                table_structure_name           = '/PSYNG/MTREES'
                node_table                     = right_node_table
              EXCEPTIONS
                failed                         = 1
                error_in_node_table            = 2
                dp_error                       = 3
                table_structure_name_not_found = 4
                OTHERS                         = 5.
          ENDIF.

          IF NOT /psyng/user-userid IS INITIAL
          AND gf_dispchg = gc_change.
*           Lock user
            CALL FUNCTION 'ENQUEUE_/PSYNG/USER'
              EXPORTING
                userid         = /psyng/user-userid
              EXCEPTIONS
                foreign_lock   = 1
                system_failure = 2
                OTHERS         = 3.
            IF sy-subrc <> 0.
              gf_dispchg = gc_display.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

      PERFORM fill_iprole.
      PERFORM populate_transactions.
      PERFORM populate_conflict.
      PERFORM populate_conflict2.

    WHEN 'DELETE'.
********************************
**SF 1665
      PERFORM authority_check_userid
             USING sec_actvt /psyng/user-userid.
      sec_actvt = act_delete.
**SF 1665
********************************
      CONCATENATE text-028 text-128 /psyng/user-userid
                  INTO popup_question SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = popup_question
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

*     Populate History
      crt_dte = sy-datum.
      crt_tme = sy-uzeit.
      PERFORM populate_history USING '/PSYNG/USER' 'USERID' space
              /psyng/user-userid space 'D'.
      PERFORM populate_history USING '/PSYNG/USER' /psyng/user-userid
              'LOCATION' /psyng/user-location space 'D'.
      PERFORM populate_history USING '/PSYNG/USER' /psyng/user-userid
              'VALIDDTE' /psyng/user-validdte space 'D'.

      SELECT * FROM /psyng/usrdet
             WHERE userid = /psyng/user-userid.
        PERFORM populate_history USING '/PSYNG/USRDET'
                /psyng/user-userid 'POSITIONID' /psyng/usrdet-positionid
                space 'D'.
      ENDSELECT.
*     End History

      DELETE FROM /psyng/user
                  WHERE userid = /psyng/user-userid.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        CONCATENATE text-129 /psyng/user-userid
                    text-126
                    INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
      ENDIF.

      DELETE FROM /psyng/usrdet
                  WHERE userid = /psyng/user-userid.
      IF sy-subrc = 0.
        REFRESH i_prole.
        REFRESH j_prole.
        LOOP AT right_node_table INTO new_node WHERE node_key <> 'Root'.

          CALL METHOD g_right_tree->delete_node
            EXPORTING
              node_key = new_node-node_key
            EXCEPTIONS
              failed   = 1
              OTHERS   = 5.
        ENDLOOP.

        REFRESH right_node_table.
      ENDIF.

*     Unlock user
      CALL FUNCTION 'DEQUEUE_/PSYNG/USER'
        EXPORTING
          userid = /psyng/user-userid.

      CLEAR: gf_data_change, /psyng/user, /psyng/usrdet, conflict2[].

    WHEN 'FIND'.
      PERFORM find_position_tree.
      CLEAR: ok_code, sy-ucomm.

    WHEN 'SAVE'.
      IF /psyng/user-userid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-e07.
      ENDIF.
******************************
**SF 1665
      PERFORM authority_check_userid
             USING sec_actvt /psyng/user-userid.
      sec_actvt = act_change.
**SF 1665
******************************
      SELECT SINGLE * FROM /psyng/user INTO old_user
                WHERE userid = /psyng/user-userid.

      /psyng/user-change_usr = g_current_user. "sy-uname. C0700
      /psyng/user-change_dat = sy-datum.
      /psyng/user-change_tim = sy-uzeit.

      IF sy-subrc <> 0.
        first_time = 'X'.
        dell_all = space.
        /psyng/user-create_usr = g_current_user. "sy-uname. C0700
        /psyng/user-create_dat = sy-datum.
        /psyng/user-create_tim = sy-uzeit.
        INSERT /psyng/user.
        IF sy-subrc <> 0.
          MESSAGE e122(/psyng/sw).  " Data Not Saved
          EXIT.
        ELSE.
          MESSAGE s120(/psyng/sw).  " Data Saved
        ENDIF.

*       Populate History
        PERFORM populate_history USING '/PSYNG/USER' 'USERID' space
                /psyng/user-userid space 'I'.
        PERFORM populate_history USING '/PSYNG/USER' /psyng/user-userid
                'LOCATION' /psyng/user-location space 'I'.
        PERFORM populate_history USING '/PSYNG/USER' /psyng/user-userid
                'VALIDDTE' /psyng/user-validdte space 'I'.
*       End History

        DELETE FROM /psyng/usrdet
                    WHERE userid = userid.
*  ======== Capture tree data in Detail table.
        /psyng/usrdet-userid = userid.
        LOOP AT j_prole.
          /psyng/usrdet-positionid = j_prole-positionid.
          INSERT /psyng/usrdet.
*         Populate History
          PERFORM populate_history USING '/PSYNG/USRDET'
                  /psyng/user-userid 'POSITIONID' j_prole-positionid
                  space 'I'.
*         End History
        ENDLOOP.

      ELSE.                            "Update
        userid = old_user-userid.
*       Populate History
        PERFORM populate_history USING '/PSYNG/USER' 'USERID' space
                /psyng/user-userid space 'U'.

        IF old_user-location <> /psyng/user-location.
          PERFORM populate_history USING '/PSYNG/USER'
                  /psyng/user-userid 'LOCATION' old_user-location
                  /psyng/user-location 'U'.
        ENDIF.

        IF old_user-validdte <> /psyng/user-validdte.
          PERFORM populate_history USING '/PSYNG/USER'
                  /psyng/user-userid 'VALIDDTE' old_user-validdte
                  /psyng/user-validdte 'U'.
        ENDIF.

        SELECT * FROM /psyng/usrdet
               WHERE userid = /psyng/user-userid.
          READ TABLE j_prole WITH KEY positionid =
          /psyng/usrdet-positionid.
          IF sy-subrc <> 0.
            PERFORM populate_history USING '/PSYNG/USRDET'
                    /psyng/user-userid 'POSITIONID'
                    /psyng/usrdet-positionid space 'D'.
          ENDIF.
        ENDSELECT.

        LOOP AT j_prole.
          SELECT SINGLE * FROM /psyng/usrdet         "#EC CI_SEL_NESTED
                        WHERE userid     = /psyng/user-userid
                          AND positionid = j_prole-positionid
                           .
          IF sy-subrc <> 0.
            PERFORM populate_history USING '/PSYNG/USRDET'
                    /psyng/user-userid 'POSITIONID' j_prole-positionid
                    space 'I'.
          ENDIF.
        ENDLOOP.
*       End History

        UPDATE /psyng/user.

        DELETE FROM /psyng/usrdet
                    WHERE userid = userid.
*  ======== Capture tree data in Detail table.
        /psyng/usrdet-userid = userid.
        LOOP AT j_prole.
          /psyng/usrdet-positionid = j_prole-positionid.
          INSERT /psyng/usrdet.
          IF sy-subrc NE 0.
            success = 'N'.
          ENDIF.
        ENDLOOP.

        IF success = 'Y'.
          MESSAGE s120(/psyng/sw).  " Data Saved
        ELSE.
          MESSAGE w122(/psyng/sw).  " Data Not Saved
        ENDIF.

      ENDIF.

      PERFORM fill_iprole.
      PERFORM populate_transactions.
      PERFORM populate_conflict.
      PERFORM populate_conflict2.
      CLEAR gf_data_change.

    WHEN 'SODCON'.

      REFRESH: suser.
      CLEAR: suser.
      suser-sign = 'I'.
      suser-option = 'EQ'.
      suser-low = /psyng/user-userid.
      APPEND suser.

      SUBMIT /psyng/sodreport_org
             WITH byrole = ' '
             WITH byuser = 'X'
             WITH pbname IN suser
             WITH sodvrsio = g_sod_vrsio
             AND RETURN.

      CLEAR: ok_code, sy-ucomm.

*      CLEAR /psyng/rolehdr.
*      CLEAR cursor_field.
*      CLEAR cursor_line.
*      sod_conflict = 'X'.
**      I_PROLE is the table with all ROLES
*      REFRESH  g_role_trans_itab.
*      LOOP AT i_prole.
*        SELECT SINGLE * FROM /psyng/rolehdr
*        WHERE roleid = i_prole-roleid.
*
*        IF /psyng/rolehdr-saptechname > space.
*          SELECT * FROM /psyng/roletrans
*          WHERE roleid = i_prole-roleid.
*            g_role_trans_itab-tcode = /psyng/roletrans-tcode.
*            APPEND  g_role_trans_itab.
*          ENDSELECT.
*        ENDIF.
*      ENDLOOP.
*      PERFORM populate_sod_conflict.

    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
************************************************
**SF 1665
        PERFORM authority_check_userid
                    USING sec_actvt /psyng/user-userid.
        sec_actvt = act_change.
**SF 1665
************************************************
        gf_dispchg = gc_change.

        IF NOT /psyng/user-userid IS INITIAL.
*         Lock user
          CALL FUNCTION 'ENQUEUE_/PSYNG/USER'
            EXPORTING
              userid         = /psyng/user-userid
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM exit_without_save.
**************************************************
**SF 1665
        PERFORM authority_check_userid
            USING sec_actvt /psyng/user-userid.
        sec_actvt = act_display.
**SF 1665
**************************************************
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.
        ok_code = 'ENTER'.
        PERFORM user_command_0105.

        gf_dispchg = gc_display.

*       Unlock user
        IF NOT /psyng/user-userid IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/USER'
            EXPORTING
              userid = /psyng/user-userid.
        ENDIF.
      ENDIF.

      CLEAR: ok_code, sy-ucomm.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
        'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
        'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
*     If data was changed,ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

*     Unlock position id
      IF NOT /psyng/position-positionid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/USER'
          EXPORTING
            userid = /psyng/user-userid.
      ENDIF.

      CLEAR: first_time, gf_data_change, g_role_trans_itab,
             g_role_trans_itab[], conflict, conflict[], conflict2,
             conflict2[], itab_funct1, itab_funct1[], itab_con,
             itab_con[], g_role_trans_itab2, g_role_trans_itab2[],
             /psyng/user, /psyng/usrdet, /psyng/confdet,
             /psyng/conflict, /psyng/functtran, populated.
    WHEN 'FS'.
      g_fullscreen = '0105'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

  ENDCASE.
ENDFORM.                    " user_command_0105

*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND_0201
*&---------------------------------------------------------------------*
*       Handle user commands from screen 201
*----------------------------------------------------------------------*
FORM user_command_0201.
  DATA: lf_ins_upd(1)   TYPE c,
        records         TYPE i,
        records_c(4),
        lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
        lt_texts        TYPE TABLE OF /psyng/texts WITH HEADER LINE,
        lt_faobj        TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_sel_tcodes   TYPE TABLE OF ssm_tcodes WITH HEADER LINE,
        l_fioriid_index TYPE i,
        l_fiori_ids     TYPE string.

  DATA: BEGIN OF lt_id OCCURS 0,
          id TYPE i,
        END OF lt_id.

  DATA:lt_functtran2 TYPE TABLE OF /psyng/functtran
                WITH HEADER LINE.

  DATA: BEGIN OF lt_tcode OCCURS 0,
          tcode TYPE /psyng/faobj2-tcode,
        END OF lt_tcode.

  RANGES: lr_funid FOR /psyng/function-function,
          lr_vrsio FOR /psyng/function-vrsio.

  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_function
            USING sec_actvt /psyng/functtran-functionid.
  ENDIF.

  crt_dte = sy-datum.
  crt_tme = sy-uzeit.

* Unlock previous function id
*  IF NOT /psyng/function-function IS INITIAL.
  IF /psyng/function-function <> /psyng/functtran-functionid.

    CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
      EXPORTING
        function = /psyng/function-function
        vrsio    = g_sod_vrsio.
*BOC:HBHALLA (27/11/24) PN-7208
    CALL FUNCTION 'DEQUEUE_/PSYNG/FAOBJ'
         EXPORTING
              funid = /psyng/function-function
              vrsio = g_sod_vrsio.
*EOC:HBHALLA (27/11/24) PN-7208

    DELETE gt_locked WHERE type = 'FUNCTION'.
*--Dhorions 2013/10/18 added so we load data when a new function
*  id is entered
    CLEAR : first_time." gf_data_change.
  ENDIF.

  /psyng/function-function = /psyng/functtran-functionid.

  PERFORM get_editor_text.
  populated = 'X'.
  CASE ok_code.
    WHEN 'IMPORT'.
      SUBMIT /psyng/sw_041 VIA SELECTION-SCREEN
      WITH trgvrsio = g_sod_vrsio AND RETURN.
    WHEN 'COPY'.
      CHECK NOT /psyng/function-function IS INITIAL.
      PERFORM copy_function_id.
    WHEN 'QCUSER'.
      CALL FUNCTION '/PSYNG/SW_SOD_QUICK_CHECK_USER'
        EXPORTING
          vrsio = g_sod_vrsio.

    WHEN 'EAOBJ'.
*--Check if existing function is selected.
      SELECT SINGLE vrsio INTO /psyng/function-vrsio
      FROM /psyng/function
      WHERE function = /psyng/function-function AND
            vrsio    = g_sod_vrsio.
      IF sy-subrc <> 0 OR gf_data_change = 'X'.
        MESSAGE i193(/psyng/sw).
        EXIT.
      ENDIF.

      PERFORM authority_check_function
              USING act_display /psyng/function-function.

      IF NOT /psyng/function-function IS INITIAL.
        lr_funid-sign = 'I'.
        lr_funid-option = 'EQ'.
        lr_funid-low = /psyng/function-function.
        APPEND lr_funid.
      ENDIF.

      IF gf_dispchg = gc_change.
        g_nodsp = 'X'.
      ELSE.
        g_nodsp = ' '.
      ENDIF.

      SUBMIT /psyng/authobj
             WITH p_vrsio  = g_sod_vrsio
             WITH s_funid IN lr_funid
             WITH p_nodsp = g_nodsp
             AND RETURN.

    WHEN 'LUKUP'.
      SUBMIT /psyng/sw_025 VIA SELECTION-SCREEN
                           WITH p_vrsio = g_sod_vrsio
                           AND RETURN.

    WHEN 'LMTRX'.
      SUBMIT /psyng/sw_sodmatrix_overview VIA SELECTION-SCREEN
                           WITH p_vrsio = g_sod_vrsio
                           AND RETURN.

    WHEN 'FROMMENU'.
      CALL FUNCTION 'MENU_F4_HELP_HIERARCHY'
        EXPORTING
          show_technical_names     = 'X'
        TABLES
          selected_tcodes          = lt_sel_tcodes
        EXCEPTIONS
          menu_does_not_exist      = 1
          too_many_tcodes_selected = 2
          OTHERS                   = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK NOT lt_sel_tcodes[] IS INITIAL.

      LOOP AT lt_sel_tcodes.
        CLEAR g_trans_itab.
        READ TABLE g_trans_itab WITH KEY tcode = lt_sel_tcodes-tcode
                   TRANSPORTING NO FIELDS.
        CHECK sy-subrc <> 0.

        SELECT SINGLE ttext INTO g_trans_itab-ttext FROM tstct
                      WHERE sprsl = sy-langu
                        AND tcode = lt_sel_tcodes-tcode.

        g_trans_itab-tcode = lt_sel_tcodes-tcode.
        APPEND g_trans_itab.
        ADD 1 TO critrans-lines.
      ENDLOOP.


    WHEN 'CHANGES'.
      lr_vrsio-sign   = 'I'.
      lr_vrsio-option = 'EQ'.
      lr_vrsio-low    = g_sod_vrsio.
      APPEND lr_vrsio.

      IF NOT /psyng/function-function IS INITIAL.
        lr_funid-sign   = 'I'.
        lr_funid-option = 'EQ'.
        lr_funid-low = /psyng/function-function.
        APPEND lr_funid.
      ENDIF.

      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH s_vrsio IN lr_vrsio
             WITH p_funct  = 'X'
             WITH s_funct IN lr_funid
             AND RETURN.

    WHEN 'ENTER'.
*      CLEAR gf_data_create.
      PERFORM load_function.
    WHEN 'DELETE'.

*--Check if Function exists
      SELECT SINGLE vrsio INTO /psyng/function-vrsio
      FROM /psyng/function
        WHERE function = /psyng/function-function
        AND   vrsio   = g_sod_vrsio.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
        EXIT.
      ENDIF.


      PERFORM authority_check_function
              USING act_delete /psyng/function-function.
      sec_actvt = act_delete.

*      IF rconfdet[] IS INITIAL.
      SELECT * FROM /psyng/confdet INTO CORRESPONDING FIELDS OF
               TABLE rconfdet
               WHERE vrsio = g_sod_vrsio.
      SORT rconfdet.
      DELETE ADJACENT DUPLICATES FROM rconfdet.
*      ENDIF.
      REFRESH: iconflict, iconflict[].
      READ TABLE rconfdet WITH KEY
                functionid = /psyng/functtran-functionid
                BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.
        CLEAR: iconflict.
        LOOP AT rconfdet WHERE functionid = /psyng/functtran-functionid.
          SELECT SINGLE * FROM /psyng/conflict       "#EC CI_SEL_NESTED
                 INTO CORRESPONDING FIELDS OF iconflict
                 WHERE conid = rconfdet-conid
                   AND vrsio = g_sod_vrsio.
          APPEND iconflict.
        ENDLOOP.
        SORT iconflict.
        DELETE ADJACENT DUPLICATES FROM iconflict.
        CLEAR: records, records_c.
        DESCRIBE TABLE iconflict LINES records.

        MOVE records TO records_c.
        CONDENSE records_c.

        CONCATENATE text-004 /psyng/functtran-functionid
                    text-130 records_c text-161 INTO headr
                    SEPARATED BY space.

        MESSAGE i113(/psyng/sw) WITH text-030.
        CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
          EXPORTING
            header       = headr
            tabname      = '/PSYNG/CONFLICT'
            display_only = 'X'
            no_insert    = 'X'
            no_delete    = 'X'
            no_move      = 'X'
            no_undo      = 'X'
            no_button    = ' '
            x_end        = 90
          TABLES
            table        = iconflict
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             no_more_tables   = 1
             too_many_fields = 2
             nametab_not_valid = 3
             handle_not_valid  = 4
             OTHERS          = 5 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.

        EXIT.
      ENDIF.

      CONCATENATE text-031 /psyng/functtran-functionid
                  INTO popup_question SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = popup_question
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
        EXCEPTIONS
          text_not_found  = 1
          OTHERS          = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.          .
      CHECK popup_answer = '1'.

      CALL FUNCTION '/PSYNG/SW_CR_DELETE_FUNCTION'
        EXPORTING
          i_vrsio        = g_sod_vrsio
          i_funid        = /psyng/functtran-functionid
        EXCEPTIONS
          not_authorized = 1
          not_exist      = 2
          OTHERS         = 3.
      IF sy-subrc = 0.
        CONCATENATE text-004 /psyng/functtran-functionid text-126
                    INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
      ELSE.
        MESSAGE w103(/psyng/sw).
        EXIT.
      ENDIF.

      CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
        EXPORTING
          function = /psyng/function-function
          vrsio    = g_sod_vrsio
"(++)BOC UMITTAL SE VF scan-25/11/2024
        EXCEPTIONS
          OTHERS = 1  .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      DELETE gt_locked WHERE type = 'FUNCTION'.

      CLEAR: /psyng/function, /psyng/functtran, g_trans_itab[],
             gf_data_change, i_text, i_text[], critrans-lines,
             gf_data_create,g_editor_text[].

    WHEN 'SAVE'.
*--Check if changes were actually made
      IF gf_data_change <> 'X'.
        MESSAGE s024(/psyng/sw).
*       Data not saved. No changes found.
        EXIT.
      ENDIF.
      IF /psyng/function-function IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-004.
      ENDIF.

      PERFORM authority_check_function
              USING act_change /psyng/function-function.
      sec_actvt = act_change.

      /psyng/function-vrsio      = g_sod_vrsio.
      /psyng/function-change_usr = g_current_user."sy-uname. C0700
      /psyng/function-change_dat = crt_dte.
      /psyng/function-change_tim = crt_tme.

      lt_functtran-vrsio      = g_sod_vrsio.
      lt_functtran-functionid = /psyng/functtran-functionid.

      DELETE g_trans_itab WHERE tcode = space.
      DESCRIBE TABLE g_trans_itab LINES critrans-lines.

      LOOP AT g_trans_itab.
        MOVE-CORRESPONDING g_trans_itab TO lt_functtran.
        IF g_trans_itab-tcode  CP
                /psyng/sw_cl_constants=>placeholder_tcode_prefix.
          lt_functtran-type = 'P'. " Place holder
        ELSE.
          lt_functtran-type = 'T'. " Tcode
        ENDIF.
        APPEND lt_functtran.
*        clear lt_functtran.
      ENDLOOP.

*--fiori app changes start
*Get existing fiori id and assign a index to calculate new tcode
      SELECT * FROM /psyng/functtran INTO
     CORRESPONDING FIELDS OF   TABLE  lt_functtran2 WHERE
               functionid = /psyng/functtran-functionid
               AND vrsio =  g_sod_vrsio
               AND type  = 'F'.
*----get highest tcode index
      LOOP AT lt_functtran2.
        SPLIT lt_functtran2-tcode AT '-' INTO lt_functtran2-tcode
      l_fiori_ids.
        IF l_fiori_ids CO '0123456789'.
          lt_id-id = l_fiori_ids.
*BOC for B17112 by GSINGH on 23.01.2023 - Fiori id Length can be upto 12
*to concatenate it to the tcode
*        ELSEif strlen( lt_functtran2-fioriid ) > 13 . " Om
        ELSEIF strlen( lt_functtran2-fioriid ) > 12 .
* EOC by GSINGH
          lt_id-id = sy-tabix.
        ENDIF.
        APPEND lt_id.
*        endif.
      ENDLOOP.
      SORT lt_id DESCENDING BY id .
      READ TABLE lt_id INDEX 1.
      l_fioriid_index = lt_id-id.

*--Prepare funttran structure
*      CLEAR: l_fiori_ids.
      LOOP AT gt_fiori_app.

*----validate each appid
        SELECT SINGLE mandt FROM /psyng/sw_fioria INTO
          sy-mandt WHERE fioriid = gt_fiori_app-fioriid.
        IF sy-subrc <> 0.
          MESSAGE e113(/psyng/sw) WITH
         'Fiori Id Does not exist'(e50).

        ELSE.
          READ TABLE lt_functtran2 WITH KEY
                      fioriid = gt_fiori_app-fioriid.
          IF sy-subrc = 0.
            MOVE-CORRESPONDING gt_fiori_app TO lt_functtran.
            lt_functtran-tcode = lt_functtran2-tcode.
*BOC for B17112 by GSINGH on 23.01.2023 - Fiori id Length can be upto 12
*to concatenate it to the tcode
*          ELSEif strlen( gt_fiori_app-fioriid ) > 13.
          ELSEIF strlen( gt_fiori_app-fioriid ) > 12.
* EOC by GSINGH
*-----if new fioriid then assign number in tcode next to saved
            MOVE-CORRESPONDING gt_fiori_app TO lt_functtran.
            ADD 1 TO l_fioriid_index.
            l_fiori_ids = l_fioriid_index.
            CONDENSE l_fiori_ids.
            CONCATENATE '/PSYNG/-' l_fiori_ids INTO
                    lt_functtran-tcode.
          ELSE.
            MOVE-CORRESPONDING gt_fiori_app TO lt_functtran.
            CONCATENATE '/PSYNG/-' gt_fiori_app-fioriid INTO
                lt_functtran-tcode.
          ENDIF.
          lt_functtran-type = 'F'. "Fiori
          APPEND lt_functtran.
        ENDIF.
      ENDLOOP.
      DELETE lt_functtran WHERE fioriid = space AND
                                type    = 'F'.
      DELETE gt_fiori_app WHERE fioriid = space.
      DESCRIBE TABLE gt_fiori_app LINES fioriapps-lines.
*--end fiori app changes

      PERFORM get_editor_text.

      lt_texts-vrsio    = g_sod_vrsio.
      lt_texts-textname = /psyng/functtran-functionid.
      LOOP AT i_text.
        MOVE-CORRESPONDING i_text TO lt_texts.
        APPEND lt_texts.
      ENDLOOP.


*     Check tcodes that need to be deleted from authorization objects
      SELECT * INTO TABLE lt_faobj FROM /psyng/faobj2
             WHERE vrsio = g_sod_vrsio
               AND funid = /psyng/functtran-functionid.

      SORT lt_functtran BY tcode.
      LOOP AT lt_faobj.
        READ TABLE lt_functtran WITH KEY tcode = lt_faobj-tcode
                                TRANSPORTING NO FIELDS.
        CHECK sy-subrc <> 0.
        DELETE lt_faobj.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
        EXPORTING
          wa_function             = /psyng/function
          i_vrsio                 = g_sod_vrsio
        IMPORTING
          funid_added             = lf_ins_upd
        TABLES
          texts                   = lt_texts
          functtran               = lt_functtran
          faobj                   = lt_faobj
        EXCEPTIONS
          target_not_specified    = 1
          not_authorized          = 2
          function_already_exists = 3
          OTHERS                  = 4.
      IF sy-subrc = 0.
        MESSAGE s120(/psyng/sw).  " Data Saved
      ENDIF.

      IF lf_ins_upd = 'Y'.
        lf_ins_upd = 'I'.

*       Lock function ID
        CALL FUNCTION 'ENQUEUE_/PSYNG/FUNCTION'
          EXPORTING
            function       = /psyng/function-function
            vrsio          = g_sod_vrsio
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          gt_locked-type   = 'FUNCTION'.
          gt_locked-object = /psyng/function-function.
          APPEND gt_locked.
        ENDIF.
      ELSE.
        lf_ins_upd = 'U'.
      ENDIF.

      CLEAR gf_data_change.
      CLEAR gf_data_create.
      first_time = gc_select.

    WHEN 'CREATE'.
*--Clear Function ID Parameter
      SET PARAMETER ID '/PSYNG/FUN' FIELD space.

      PERFORM authority_check_function
              USING act_create space.
      sec_actvt = act_create.

      PERFORM exit_without_save.
      CHECK gf_answer = '1'.

*     Unlock function id
      IF NOT /psyng/function-function IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
          EXPORTING
            function = /psyng/function-function
            vrsio    = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'FUNCTION'.
      ENDIF.

      old_trans_current_line = 0.
      REFRESH i_text.
      REFRESH: g_trans_itab, gt_fiori_app.
      CLEAR: /psyng/function, /psyng/functtran,g_editor_text[],
*      first_time,
*             gf_data_change,
             critrans-lines.
      first_time = 'X'.
      gf_data_change = 'X'.
      gf_data_create = 'X'.

*   Transport table entries
    WHEN 'TRANSPORT'.
      IF /psyng/function-function IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-004.
      ENDIF.

      lr_funid-sign = 'I'.
      lr_funid-option = 'EQ'.
      lr_funid-low = /psyng/function-function.
      APPEND lr_funid.

      SUBMIT /psyng/sw_048
             VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tfunct = gc_select
             WITH p_tvhead = gc_select
             WITH s_funct IN lr_funid
             AND RETURN.

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.  "if DISPLAY, change mode to CHANGE

        PERFORM authority_check_function
*                USING sec_actvt /psyng/function-function.
                USING act_change /psyng/function-function.
        sec_actvt = act_change.

        gf_dispchg = gc_change.
        PERFORM check_version_editable.
        CHECK gf_dispchg = gc_change.

        IF NOT /psyng/function-function IS INITIAL.
*         Lock function ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/FUNCTION'
            EXPORTING
              function       = /psyng/function-function
              vrsio          = g_sod_vrsio
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ELSE.
            gt_locked-type   = 'FUNCTION'.
            gt_locked-object = /psyng/function-function.
            APPEND gt_locked.
          ENDIF.
*BOC:HBHALLA (27/11/24) PN-7208
          CALL FUNCTION 'ENQUEUE_/PSYNG/FAOBJ'
               EXPORTING
                    funid          = /psyng/function-function
                    vrsio          = g_sod_vrsio
               EXCEPTIONS
                    foreign_lock   = 1
                    system_failure = 2
                    OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
*EOC:HBHALLA (27/11/24) PN-7208
        ENDIF.
      ELSE.                        "if CHANGE, change mode to DISPLAY
        PERFORM authority_check_function
                USING act_display /psyng/function-function.
        sec_actvt = act_display.
        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.
        ok_code = 'ENTER'.
        PERFORM user_command_0201.

        gf_dispchg = gc_display.

*       Unlock function id
        IF NOT /psyng/function-function IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
            EXPORTING
              function = /psyng/function-function
              vrsio    = g_sod_vrsio.
*BOC:HBHALLA (27/11/24) PN-7208
          COMMIT WORK.
          CALL FUNCTION 'DEQUEUE_/PSYNG/FAOBJ'
               EXPORTING
                    funid = /psyng/function-function
                    vrsio = g_sod_vrsio.
          COMMIT WORK.
*EOC:HBHALLA (27/11/24) PN-7208
          DELETE gt_locked WHERE type = 'FUNCTION'.
        ENDIF.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
     'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
     'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.

*      clear: sec_actvt.

*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

*     Unlock function id
      IF NOT /psyng/function-function IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
          EXPORTING
            function = /psyng/function-function
            vrsio    = g_sod_vrsio.
*BOC:HBHALLA (27/11/24) PN-7208
        CALL FUNCTION 'DEQUEUE_/PSYNG/FAOBJ'
             EXPORTING
                  funid = /psyng/function-function
                  vrsio = g_sod_vrsio.
*EOC:HBHALLA (27/11/24) PN-7208
        DELETE gt_locked WHERE type = 'FUNCTION'.
      ENDIF.

      CLEAR: first_time, g_trans_itab, g_trans_itab[], i_text[],
             critrans-lines, /psyng/function, /psyng/functtran,
             sec_actvt,g_editor_text[].

      IF ok_code <> 'YX_SECTAB_FC2'.
        CLEAR: gf_data_change, populated.
      ENDIF.
    WHEN 'FS'.
      g_fullscreen = '0201'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

    WHEN 'SYSFLTR'.
      IF NOT /psyng/functtran-functionid IS INITIAL.
        CALL SCREEN '0909'.
* B8620
      ELSE.
        MESSAGE i106(/psyng/sw) WITH text-004.
*end.
      ENDIF.
  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.
ENDFORM.                   " USER_COMMAND_0201

*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND_0202
*&---------------------------------------------------------------------*
*       Handle user commands from screen 202
*----------------------------------------------------------------------*
FORM user_command_0202.
  DATA: lf_ins_upd(1) TYPE c,
        lt_confdet    TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
        lt_conowner   TYPE TABLE OF /psyng/conowner WITH HEADER LINE,
        lt_texts      TYPE TABLE OF /psyng/texts WITH HEADER LINE.

  RANGES: lr_conid FOR /psyng/conflict-conid,
          lr_vrsio FOR /psyng/conflict-vrsio.

  DATA : l_answer(1)       TYPE c,
         l_mandt           TYPE sy-mandt,
         l_no_valid_assign TYPE flag,
         l_question(180),
         ls_tstct          TYPE tstct.

  DATA : lt_mcuser   TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
         lt_mcrole   TYPE TABLE OF /psyng/mcrole  WITH HEADER LINE,
         lt_mcusrgrp TYPE TABLE OF /psyng/mcusrgrp WITH HEADER LINE,
         ls_mchdr    TYPE /psyng/mchdr.


*BOC UMITTAL SE-CAC Integration 17/02/2026
  DATA :
         ls_clskey     TYPE seoclskey,
         ls_vseoclass  TYPE vseoclass,
         lv_method     TYPE string,
         ls_conflict   TYPE /psyng/conflict.
  DATA : lo_obj        TYPE REF TO object,
         lx_error      TYPE REF TO cx_root.
*EOC UMITTAL SE-CAC Integration 17/02/2026
  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_conflict_h
            USING sec_actvt /psyng/confdet-conid.
  ENDIF.

  crt_dte = sy-datum.
  crt_tme = sy-uzeit.

* Unlock previous conflict id
  IF /psyng/conflict-conid <> /psyng/confdet-conid.
    CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
      EXPORTING
        conid = /psyng/conflict-conid
        vrsio = g_sod_vrsio.

    DELETE gt_locked WHERE type = 'CONFLICT'.
*    IF gf_data_change NE 'X'.
    CLEAR first_time.
*    ENDIF.
  ENDIF.
  PERFORM get_editor_text.
* /psyng/function-function = /psyng/functtran-functionid.
  populated = 'X'.
  CASE ok_code.
    WHEN 'IMPORT'.
      SUBMIT /psyng/sw_042 VIA SELECTION-SCREEN
      WITH trgvrsio = g_sod_vrsio AND RETURN.
    WHEN 'COPY'.
      IF NOT /psyng/conflict-conid IS INITIAL.
        PERFORM copy_conflict_id.
      ELSE.
        MESSAGE e106(/psyng/sw) WITH 'Conflict ID'(006).
      ENDIF.
    WHEN 'QCUSER'.
      CALL FUNCTION '/PSYNG/SW_SOD_QUICK_CHECK_USER'
        EXPORTING
          vrsio = g_sod_vrsio.
    WHEN 'INSR'.
      LOOP AT g_funct_itab WHERE flag = 'X'.
        CLEAR g_funct_itab-flag.
        MODIFY g_funct_itab.
      ENDLOOP.

      DESCRIBE TABLE g_funct_itab LINES funct-lines.
      PERFORM insert_row_into_tc USING  'FUNCT' 'G_FUNCT_ITAB'.
    WHEN 'LUKUP'.
      SUBMIT /psyng/sw_025 VIA SELECTION-SCREEN
                           WITH p_vrsio = g_sod_vrsio
                           AND RETURN.
    WHEN 'LMTRX'.
      SUBMIT /psyng/sw_sodmatrix_overview VIA SELECTION-SCREEN
                           WITH p_vrsio = g_sod_vrsio
                           AND RETURN.

    WHEN 'DELL'.
      DELETE g_funct_itab WHERE flag = 'X'.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
*   Select an entry
      ELSE.
        DESCRIBE TABLE g_funct_itab LINES funct-lines.
      ENDIF.

    WHEN 'CHANGES'.
      lr_vrsio-sign   = 'I'.
      lr_vrsio-option = 'EQ'.
      lr_vrsio-low    = g_sod_vrsio.
      APPEND lr_vrsio.

      IF NOT /psyng/conflict-conid IS INITIAL.
        lr_conid-sign   = 'I'.
        lr_conid-option = 'EQ'.
        lr_conid-low = /psyng/conflict-conid.
        APPEND lr_conid.
      ENDIF.

      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH s_vrsio IN lr_vrsio
             WITH p_conid  = 'X'
             WITH s_conid IN lr_conid
             AND RETURN.

    WHEN 'ACTIVATE' OR 'DEACTIVATE'.
      IF ok_code = 'ACTIVATE'.
        CLEAR /psyng/conflict-inactive.
        g_active_inactive = text-008.
      ELSE.
        /psyng/conflict-inactive = 'X'.
        g_active_inactive = text-009.
      ENDIF.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
        EXPORTING
          wa_conflict           = /psyng/conflict
          i_vrsio               = g_sod_vrsio
        EXCEPTIONS
          target_not_specified  = 1
          target_already_exists = 2
          not_authorized        = 3
          locked                = 4
          OTHERS                = 5.
      "(++)BOC UMITTAL SE VF scan-25/11/2024
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
    WHEN 'ENTER'.
      PERFORM load_conflict.
* Begin of Addition 12/20/04
    WHEN 'SHTCOD'.
      REFRESH funtcodes.
      CLEAR funtcodes.
*     Show tcodes of function
      LOOP AT g_funct_itab WHERE flag = 'X'.
        REFRESH funtcodes.
        CLEAR funtcodes.
        SELECT SINGLE * FROM /psyng/function         "#EC CI_SEL_NESTED
                      WHERE function = g_funct_itab-function
                        AND vrsio    = g_sod_vrsio.

        CONCATENATE /psyng/function-function '-'
                    /psyng/function-description
                    INTO headr SEPARATED BY space.

        SELECT * FROM /psyng/functtran               "#EC CI_SEL_NESTED
               WHERE functionid = g_funct_itab-function
                 AND vrsio      = g_sod_vrsio.
          CASE /psyng/functtran-type.
            WHEN 'T' OR ' '.
              SELECT SINGLE * FROM tstct INTO funtcodes-tcodeline
                              WHERE tcode = /psyng/functtran-tcode AND
                                    sprsl = sy-langu.

              IF sy-subrc <> 0.
                ls_tstct-sprsl = sy-langu.
                ls_tstct-tcode = /psyng/functtran-tcode.
             ls_tstct-ttext = 'Transaction for Cross System Anal.'(tc1).
                funtcodes-tcodeline = ls_tstct.
              ENDIF.
            WHEN 'P'.
              ls_tstct-sprsl = sy-langu.
              ls_tstct-tcode = /psyng/functtran-tcode.
              ls_tstct-ttext = 'Placeh. for Obj. Level Analysis'(tc3).
              funtcodes-tcodeline = ls_tstct.
            WHEN 'F'.
              ls_tstct-sprsl = sy-langu.
              SELECT SINGLE fioriid AS tcode appname AS ttext
               FROM /psyng/sw_fioria
               INTO CORRESPONDING FIELDS OF  ls_tstct
               WHERE fioriid EQ /psyng/functtran-fioriid.
              IF sy-subrc <> 0.
                ls_tstct-sprsl = sy-langu.
                ls_tstct-tcode = /psyng/functtran-fioriid.
            ls_tstct-ttext = 'Fiori App for Cross System Analysis'(tc2).
              ENDIF.
              funtcodes-tcodeline = ls_tstct.
          ENDCASE.
          APPEND funtcodes.
        ENDSELECT.

        CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
          EXPORTING
            header       = headr
            tabname      = 'TSTCT'
            display_only = 'X'
            no_insert    = 'X'
            no_delete    = 'X'
            no_move      = 'X'
            no_undo      = 'X'
            no_button    = ' '
            x_end        = 90
          TABLES
            table        = funtcodes
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             no_more_tables   = 1
             too_many_fields = 2
             nametab_not_valid = 3
             handle_not_valid  = 4
             OTHERS          = 5 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
        g_funct_itab-flag = space.
        MODIFY g_funct_itab.
      ENDLOOP.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
*   Select an entry
      ENDIF.
* End of Addition 12/20/04

    WHEN 'DELETE'.
*--Check if Conflict exists
      SELECT SINGLE vrsio INTO /psyng/conflict-vrsio
      FROM /psyng/conflict
        WHERE conid = /psyng/conflict-conid
        AND   vrsio   = g_sod_vrsio.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
        EXIT.
      ENDIF.



      PERFORM authority_check_conflict_h
              USING act_delete /psyng/confdet-conid.
      sec_actvt = act_delete.
      CONCATENATE text-032 /psyng/confdet-conid
                  INTO popup_question SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = popup_question
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

** Start of 3.1 changes
**Check whether any valid assignment made to the conflict
      SELECT SINGLE mandt FROM /psyng/mcuser INTO l_mandt
              WHERE vrsio = g_sod_vrsio
              AND conid = /psyng/confdet-conid
              AND to_date GE sy-datum.
*if even single valid assignment found then no need to check
*the other tables
      IF sy-subrc NE 0.
        SELECT SINGLE mandt FROM /psyng/mcusrgrp INTO l_mandt
                WHERE vrsio = g_sod_vrsio
                AND conid = /psyng/confdet-conid
                AND to_date GE sy-datum.
        IF sy-subrc NE 0.
          SELECT SINGLE mandt FROM /psyng/mcrole INTO l_mandt
                  WHERE vrsio = g_sod_vrsio
                  AND conid = /psyng/confdet-conid
                  AND to_date GE sy-datum.
          IF sy-subrc NE 0 .
            l_no_valid_assign = 'X'.
          ENDIF.
        ENDIF.
      ENDIF.

      IF l_no_valid_assign EQ space.

        CONCATENATE 'Valid MC Assignments exist for conflict'
                     /psyng/confdet-conid
                     '. Do you want to continue with the Delete ?'
                     INTO l_question SEPARATED BY space.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = text-027
            text_question         = l_question
            text_button_1         = text-123
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = text-124
            icon_button_2         = 'ICON_CANCEL'
            default_button        = '2'
            display_cancel_button = space
            start_column          = 25
            start_row             = 6
          IMPORTING
            answer                = l_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSE.
** if no valid assigment found then no need of pop up message
        l_answer = 1.
      ENDIF.

      CHECK l_answer = '1'.

      CLEAR: l_answer,l_no_valid_assign.

**Delete conflict with details
      CALL FUNCTION '/PSYNG/SW_CR_DELETE_CONFLICT'
        EXPORTING
          i_vrsio        = g_sod_vrsio
          i_conid        = /psyng/confdet-conid
        EXCEPTIONS
          not_authorized = 1
          not_exist      = 2
          OTHERS         = 3.
      IF sy-subrc = 0.
*BOC UMITTAL SE-CAC Integration 17/02/2026
*Update Conflict Details at CAC side as well.
      IF gv_se_cac EQ 'Y' AND
         gv_sod_dflt EQ g_sod_vrsio.

        CLEAR ls_clskey.
        ls_clskey-clsname = '/SAST/CL_SE_RULE_MAPPER'.

        CALL FUNCTION 'SEO_CLASS_GET'
          EXPORTING
            clskey         = ls_clskey
         IMPORTING
           class          =  ls_vseoclass
         EXCEPTIONS
           not_existing   = 1
           deleted        = 2
           is_interface   = 3
           model_only     = 4
           OTHERS         = 5.
        IF sy-subrc <> 0.
*        Implement suitable error handling here
        MESSAGE
 'CAC module not found.Disable SE–CAC Integration flag to continue'(302)
   TYPE 'S' DISPLAY LIKE 'E'.
   LEAVE LIST-PROCESSING.
        ELSE.

          CREATE OBJECT lo_obj TYPE (ls_clskey-clsname).
          IF lo_obj IS BOUND.
            TRY.
                lv_method = 'RUN'.
                CALL METHOD lo_obj->(lv_method)
                 EXPORTING
                   conid       = /psyng/conflict-conid
                   busarea     = /psyng/conflict-busarea
                   subarea     = /psyng/conflict-subarea
                   imp         = /psyng/conflict-imp
                   description = /psyng/conflict-description
                   action      = 'D'.
              CATCH cx_sy_dyn_call_illegal_method.
                WRITE: / 'Method RUN not found'.

              CATCH cx_root.
                WRITE: / 'Error while calling method'.
            ENDTRY.
          ENDIF.
        ENDIF.
      ENDIF.
*EOC UMITTAL SE-CAC Integration 17/02/2026
        CONCATENATE text-006 /psyng/confdet-conid text-126
                    INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
      ELSE.
        MESSAGE w103(/psyng/sw).
        EXIT.
      ENDIF.

** Mitigation assignment to users
*** Will delete all the assignments expired, current and future

      SELECT * FROM /psyng/mcuser INTO TABLE lt_mcuser
      WHERE vrsio EQ g_sod_vrsio
      AND conid = /psyng/confdet-conid .

      LOOP AT lt_mcuser.
        ls_mchdr-contid = lt_mcuser-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcuser            = lt_mcuser
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        "(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDLOOP.

*** Mitigation assignments to user groups
*** Will delete all the assignments expired,current and future

      SELECT * FROM /psyng/mcusrgrp INTO TABLE lt_mcusrgrp
      WHERE vrsio EQ g_sod_vrsio
      AND conid = /psyng/confdet-conid.

      LOOP AT lt_mcusrgrp.

        ls_mchdr-contid = lt_mcusrgrp-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcusrgrp          = lt_mcusrgrp
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        "(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDLOOP.

*** Mitigation assignments to roles
*** Will delete all the assignments expired,current and future

      SELECT * FROM /psyng/mcrole INTO TABLE lt_mcrole
      WHERE vrsio EQ g_sod_vrsio
      AND conid = /psyng/confdet-conid.

      LOOP AT lt_mcrole.

        ls_mchdr-contid = lt_mcrole-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcrole            = lt_mcrole
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        "(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.

      ENDLOOP.

**** End of 3.1 Changes

      CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
        EXPORTING
          conid = /psyng/conflict-conid
          vrsio = g_sod_vrsio.

      DELETE gt_locked WHERE type = 'CONFLICT'.

      CLEAR: /psyng/conflict, /psyng/confdet, g_funct_itab[],
             gf_data_change, i_text, i_text[], g_active_inactive,
             funct-lines,g_editor_text[].

    WHEN 'SAVE'.
      IF /psyng/confdet-conid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-006.
      ENDIF.

*     Check if conflict already exists as a custom conflict
      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/sw_cuscon
                    WHERE conid = /psyng/confdet-conid
                      AND vrsio = g_sod_vrsio.
      IF sy-subrc = 0.
        MESSAGE e113(/psyng/sw) WITH text-006 /psyng/confdet-conid
                                     text-e20.
      ENDIF.

      PERFORM authority_check_conflict_h
              USING act_change /psyng/confdet-conid.
      sec_actvt = act_change.
      /psyng/conflict-conid      = /psyng/confdet-conid.
      /psyng/conflict-vrsio      = g_sod_vrsio.
      /psyng/conflict-change_usr = g_current_user. "sy-uname. C0700
      /psyng/conflict-change_dat = sy-datum.
      /psyng/conflict-change_tim = sy-uzeit.

      PERFORM get_editor_text.

      lt_texts-vrsio    = g_sod_vrsio.
      lt_texts-textname = /psyng/confdet-conid.
      LOOP AT i_text.
        MOVE-CORRESPONDING i_text TO lt_texts.
        APPEND lt_texts.
      ENDLOOP.

      lt_confdet-conid = /psyng/confdet-conid.
      lt_confdet-vrsio = g_sod_vrsio.

      LOOP AT g_funct_itab.
        lt_confdet-functionid = g_funct_itab-function.
*--DHORIONS 2013/05/02 - Validate each function
        SELECT SINGLE vrsio FROM /psyng/function     "#EC CI_SEL_NESTED
        INTO lt_confdet-vrsio
        WHERE
          function   = lt_confdet-functionid AND
          vrsio      = g_sod_vrsio.
        IF sy-subrc = 0.
          APPEND lt_confdet.
        ELSE.
          MESSAGE e058(00) WITH
          'Function ID'(004) lt_confdet-functionid ''.
*         Entry & & & does not exist - check your entry
        ENDIF.
      ENDLOOP.

      LOOP AT gt_conowner.
        MOVE-CORRESPONDING gt_conowner TO lt_conowner.
        APPEND lt_conowner.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
        EXPORTING
          wa_conflict           = /psyng/conflict
          i_vrsio               = g_sod_vrsio
        IMPORTING
          conid_added           = lf_ins_upd
        TABLES
          texts                 = lt_texts
          confdet               = lt_confdet
          conowner              = lt_conowner
        EXCEPTIONS
          target_not_specified  = 1
          target_already_exists = 2
          not_authorized        = 3
          locked                = 4
          OTHERS                = 5.
      IF sy-subrc = 0.
        MESSAGE s120(/psyng/sw).  " Data Saved
      ENDIF.

      IF lf_ins_upd = 'Y'.
        lf_ins_upd = 'I'.

*       Lock Conflict ID
        CALL FUNCTION 'ENQUEUE_/PSYNG/CONFLICT'
          EXPORTING
            conid          = /psyng/conflict-conid
            vrsio          = g_sod_vrsio
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          gt_locked-type   = 'CONFLICT'.
          gt_locked-object = /psyng/confdet-conid.
          APPEND gt_locked.
        ENDIF.
      ELSE.
        lf_ins_upd = 'U'.
      ENDIF.

      CLEAR gf_data_change.
      first_time = gc_select.

*BOC UMITTAL SE-CAC Integration 17/02/2026
      IF gv_se_cac EQ 'Y' AND
         gv_sod_dflt EQ g_sod_vrsio.

        CLEAR ls_clskey.
        ls_clskey-clsname = '/SAST/CL_SE_RULE_MAPPER'.

        CALL FUNCTION 'SEO_CLASS_GET'
          EXPORTING
            clskey         = ls_clskey
         IMPORTING
           class          =  ls_vseoclass
         EXCEPTIONS
           not_existing   = 1
           deleted        = 2
           is_interface   = 3
           model_only     = 4
           OTHERS         = 5.
        IF sy-subrc <> 0.
*        Implement suitable error handling here
        MESSAGE
 'CAC module not found.Disable SE–CAC Integration flag to continue'(302)
   TYPE 'S' DISPLAY LIKE 'E'.
   LEAVE LIST-PROCESSING.
        ELSE.

          CREATE OBJECT lo_obj TYPE (ls_clskey-clsname).
          IF lo_obj IS BOUND.
            TRY.
                lv_method = 'RUN'.
                CALL METHOD lo_obj->(lv_method)
                 EXPORTING
                   conid       = /psyng/conflict-conid
                   busarea     = /psyng/conflict-busarea
                   subarea     = /psyng/conflict-subarea
                   imp         = /psyng/conflict-imp
                   description = /psyng/conflict-description
                   action      = lf_ins_upd.
              CATCH cx_sy_dyn_call_illegal_method.
                WRITE: / 'Method RUN not found'.

              CATCH cx_root.
                WRITE: / 'Error while calling method'.
            ENDTRY.
          ENDIF.
        ENDIF.
      ENDIF.
*EOC UMITTAL SE-CAC Integration 17/02/2026






    WHEN 'CREATE'.
*--Clear conflict ID Parameter
      SET PARAMETER ID '/PSYNG/CON' FIELD space.
      PERFORM authority_check_conflict_h
              USING act_create /psyng/confdet-conid.
      sec_actvt = act_create.

      PERFORM exit_without_save.
      CHECK gf_answer = '1'.

*     Unlock conflict id
      IF NOT /psyng/conflict-conid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
          EXPORTING
            conid = /psyng/conflict-conid
            vrsio = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'CONFLICT'.
      ENDIF.

      first_time = 'X'.
      gf_data_change = 'X'.
      old_funct_current_line = 0.
      REFRESH i_text.
      REFRESH g_funct_itab.
      REFRESH funtcodes.
      CLEAR: /psyng/function, /psyng/functtran, /psyng/conflict,
            /psyng/confdet, funct-lines,
             g_active_inactive,g_editor_text[].

*   Transport table entries
    WHEN 'TRANSPORT'.
      IF /psyng/conflict-conid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-006.
      ENDIF.

      lr_conid-sign = 'I'.
      lr_conid-option = 'EQ'.
      lr_conid-low = /psyng/conflict-conid.
      APPEND lr_conid.

      SUBMIT /psyng/sw_048
      VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tconid = gc_select
             WITH p_tvhead = gc_select
             WITH s_conid IN lr_conid
             AND RETURN.

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        PERFORM authority_check_conflict_h
                USING act_change /psyng/confdet-conid.
        sec_actvt = act_change.
        gf_dispchg = gc_change.
        PERFORM check_version_editable.
        CHECK gf_dispchg = gc_change.

        IF NOT /psyng/conflict-conid IS INITIAL.
*        Lock conflict ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/CONFLICT'
            EXPORTING
              conid          = /psyng/conflict-conid
              vrsio          = g_sod_vrsio
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ELSE.
            gt_locked-type   = 'CONFLICT'.
            gt_locked-object = /psyng/conflict-conid.
            APPEND gt_locked.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM authority_check_conflict_h
                USING act_display /psyng/confdet-conid.
        sec_actvt = act_display.
        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.
        ok_code = 'ENTER'.
        PERFORM user_command_0202.

        gf_dispchg = gc_display.

*       Unlock conflict id
        IF NOT /psyng/conflict-conid IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
            EXPORTING
              conid = /psyng/conflict-conid
              vrsio = g_sod_vrsio.

          DELETE gt_locked WHERE type = 'CONFLICT'.
        ENDIF.
      ENDIF.

    WHEN 'SYSFLTR'.
      IF  NOT /psyng/confdet-conid IS INITIAL.
        CALL SCREEN '0908'.
* B8620.
      ELSE.
        MESSAGE i106(/psyng/sw) WITH text-006.
* End.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.

*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

*     Unlock conflict id
      IF NOT /psyng/conflict-conid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
          EXPORTING
            conid = /psyng/conflict-conid
            vrsio = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'CONFLICT'.
      ENDIF.

      CLEAR: first_time, i_text[], funct-lines, g_active_inactive,
           g_funct_itab, g_funct_itab[], /psyng/conflict, sec_actvt,
             /psyng/confdet, /psyng/function, /psyng/functtran,
g_editor_text[].

      IF ok_code <> 'YX_SECTAB_FC2'.
        CLEAR: gf_data_change, populated.
      ENDIF.
    WHEN 'OWNERS'.
      CALL SCREEN 904 STARTING AT 55 8.
    WHEN 'PMIT'.
      CALL SCREEN 906 STARTING AT 55 8.
    WHEN 'FS'.
      g_fullscreen = '0202'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.
ENDFORM.                   " USER_COMMAND_0202

*---------------------------------------------------------------------*
*       FORM mit_assignment_detail                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ICONTID                                                       *
*---------------------------------------------------------------------*
FORM mit_assignment_detail USING i_contid.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  user_command_0208
*&---------------------------------------------------------------------*
*       Handle user commands from screen 208
*----------------------------------------------------------------------*
FORM user_command_0208 CHANGING l_flag.
  DATA: l_filename    LIKE rlgrap-filename,
        lt_file       LIKE g_trans_itab OCCURS 0 WITH HEADER LINE,
        l_file_trans  TYPE string,
        ls_filename   TYPE string,
        ls_critcodes  TYPE /psyng/critcodes,
        lt_texts      TYPE TABLE OF /psyng/texts WITH HEADER LINE,
        lt_trans_itab LIKE TABLE OF g_trans_itab WITH HEADER LINE.


  crt_dte = sy-datum.
  crt_tme = sy-uzeit.
  populated = 'X'.

  CASE ok_code.
    WHEN 'IMPORT'.
      SUBMIT /psyng/sw_044 VIA SELECTION-SCREEN
      WITH trgvrsio = g_sod_vrsio AND RETURN.

    WHEN 'INSR'.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                 ID 'ACTVT' FIELD '01'
                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        MESSAGE e108(/psyng/sw) WITH text-116.
      ENDIF.

*      ADD 20 TO critrans-lines.
      DESCRIBE TABLE g_trans_itab LINES critran-lines.
      PERFORM insert_row_into_tc USING  'CRITRAN' 'G_TRANS_ITAB'.

    WHEN 'DELL'.

      AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                  ID 'ACTVT' FIELD '06'
                  ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        MESSAGE e108(/psyng/sw) WITH text-117.
      ENDIF.

      READ TABLE g_trans_itab WITH KEY flag = 'X'.
      IF sy-subrc <> 0.
        MESSAGE i161(/psyng/sw).
        EXIT.
      ENDIF.



      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = text-q01
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

*BOC: HBHALLA
      l_flag = 'Y'.
*END OF CHANGE: HBHALLA

*  get system filter for selected CT
      LOOP AT g_trans_itab WHERE flag = 'X'.
        MOVE-CORRESPONDING g_trans_itab TO lt_trans_itab.
        APPEND lt_trans_itab.
      ENDLOOP.
      REFRESH gt_systcd_del.
      IF NOT lt_trans_itab[] IS INITIAL.
        SELECT * FROM /psyng/sw_systcd INTO TABLE
            gt_systcd_del FOR ALL ENTRIES IN lt_trans_itab
            WHERE tcode = lt_trans_itab-tcode
            AND   vrsio = g_sod_vrsio.
      ENDIF.


      DELETE g_trans_itab WHERE flag = 'X'.
*BOC:HBHALLA
      IF gt_trans_bckup[] IS NOT INITIAL.
        LOOP AT lt_trans_itab.
          DELETE gt_trans_bckup WHERE tcode = lt_trans_itab-tcode.
        ENDLOOP.
      ENDIF.
*END OF CHANGE: HBHALLA
      DESCRIBE TABLE g_trans_itab LINES critran-lines.
      MESSAGE s121(/psyng/sw) WITH 'Tcode(s)'.

    WHEN 'SAVE'.
      DATA: success VALUE 'Y'.
*      DELETE FROM /psyng/critcodes WHERE tcode > space
*                                     AND vrsio = g_sod_vrsio.
*      gt_crit_trans[] = g_trans_itab[].

*BOC:HBHALLA
*   Validation for Application Area Field
      DATA  lv_busarea TYPE   /psyng/bus_area.
      DATA  ls_trans TYPE t_trans.
      CLEAR  lv_busarea.

      LOOP AT g_trans_itab INTO ls_trans.
        IF ls_trans-busarea IS NOT INITIAL.
          SELECT SINGLE  busarea FROM /psyng/busarea INTO lv_busarea
            WHERE busarea = ls_trans-busarea.
          IF sy-subrc NE 0.
            MESSAGE e020(/psyng/sw) WITH
*BOC UMITTAL PN-17849 05/03/2026
            'App Area:'(249)
*EOC UMITTAL PN-17849 05/03/2026
            ls_trans-busarea.
            LEAVE LIST-PROCESSING.
          ENDIF.
        ENDIF.

*    Validation for Owner Field
        IF ls_trans-owner IS NOT INITIAL.
          CALL FUNCTION 'SUSR_USER_CHECK_EXISTENCE'
          EXPORTING
            user_name            = ls_trans-owner
          EXCEPTIONS
            user_name_not_exists = 1
            OTHERS               = 2.

          IF sy-subrc NE 0.
            MESSAGE e020(/psyng/sw) WITH ls_trans-owner.
            LEAVE LIST-PROCESSING.
          ENDIF.
        ENDIF.

      ENDLOOP.
*  *EOC:HBHALLA



*BOC:HBHALLA
      LOOP AT g_trans_itab.
        MODIFY gt_trans_bckup FROM g_trans_itab
        TRANSPORTING owner busarea imp
        WHERE tcode = g_trans_itab-tcode.
      ENDLOOP.
*END OF CHANGE:HBHALLA

*BOC: HBHALLA
      IF gt_trans_bckup[] IS INITIAL.
        LOOP AT g_trans_itab.
          gt_crit_trans-tcode = g_trans_itab-tcode.
          gt_crit_trans-vrsio = g_sod_vrsio.
          gt_crit_trans-owner = g_trans_itab-owner.
          gt_crit_trans-busarea = g_trans_itab-busarea.
*        gt_crit_trans-description = g_trans_itab-description.
          gt_crit_trans-imp = g_trans_itab-imp.
          APPEND gt_crit_trans.
        ENDLOOP.
      ELSE.
        LOOP AT gt_trans_bckup.
          gt_crit_trans-tcode = gt_trans_bckup-tcode.
          gt_crit_trans-vrsio = g_sod_vrsio.
          gt_crit_trans-owner = gt_trans_bckup-owner.
          gt_crit_trans-busarea = gt_trans_bckup-busarea.
*        gt_crit_trans-description = gt_trans_bckup-description.
          gt_crit_trans-imp = gt_trans_bckup-imp.
          APPEND gt_crit_trans.
        ENDLOOP.
      ENDIF.
*END OF CHANGE: HBHALLA


      CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_TCODES'
        EXPORTING
          i_vrsio                  = g_sod_vrsio
          append_flag              = l_flag      "HBHALLA
*       IMPORTING
*         critran_modif            = 'X'
        TABLES
          critcodes                = gt_crit_trans
          texts                    = gt_texts_ct
        EXCEPTIONS
          not_authorized_to_import = 1
          empty_list_provided      = 2
          OTHERS                   = 3.
      IF sy-subrc = 0.
        MESSAGE s120(/psyng/sw).  " Data Saved

        LOOP AT gt_systcd_del.
          DELETE FROM /psyng/sw_systcd
                  WHERE tcode = gt_systcd_del-tcode
                    AND vrsio = gt_systcd_del-vrsio.
        ENDLOOP.

        IF g_trans_itab[] IS INITIAL.
          DELETE FROM /psyng/sw_systcd
                           WHERE vrsio = g_sod_vrsio.
        ENDIF.
      ENDIF.

      l_flag = 'X'. "HBHALLA

***   SE 3.1 DEVELOPEMNT ITEM C46 Code by Shekhar 17/10/2013
***   ITEM C46 Start fix

      DELETE g_trans_itab WHERE tcode = space.
      DESCRIBE TABLE g_trans_itab LINES critran-lines.
***   ENDFIX.

    WHEN 'CHANGES'.

      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH s_vrsio = g_sod_vrsio
             WITH p_ctcode  = 'X'
*             WITH s_cauth IN lr_swaudid
             AND RETURN.
    WHEN 'ENTER'.
*     Do nothing

*   Transport table entries
    WHEN 'TRANSPORT'.
* B8639.
      REFRESH gr_conid[].
      LOOP AT g_trans_itab WHERE flag = 'X'.
        gr_conid-sign = 'I'.
        gr_conid-option = 'EQ'.
        gr_conid-low = g_trans_itab-tcode.
        APPEND gr_conid.
      ENDLOOP.
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_ttcode = gc_select
             WITH p_tvhead = gc_select
             WITH p_ctfltr = gc_select
             WITH s_tcode  IN gr_conid
             AND RETURN.
    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_data_upload_download VIA SELECTION-SCREEN
               WITH sodvrsio  = g_sod_vrsio
*             WITH p_ttcode = gc_select
               WITH f_ct = 'X'
               WITH f_ctxt = 'X'
               WITH f_cr = ' '
               WITH f_crtxt = ' '
               WITH f_cp = ' '
               WITH f_cptxt = ' '
               WITH f_funh = ' '
               WITH f_fund = ' '
               WITH f_funt = ' '
               WITH f_objd = ' '
               WITH f_conh = ' '
               WITH f_cond = ' '
               WITH f_cont = ' '
               WITH f_cono = ' '
               WITH f_cah = ' '
               WITH f_cad = ' '
               WITH f_cat = ' '
               AND RETURN.



    WHEN 'CADET'.
      sec_actvt = act_print.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
               ID 'ACTVT' FIELD sec_actvt
               ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        MESSAGE e108(/psyng/sw) WITH text-034.
      ENDIF.

      SUBMIT /psyng/sw_019 WITH sodvrsio = g_sod_vrsio AND RETURN.

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        sec_actvt = act_change.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                 ID 'ACTVT' FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
        IF sy-subrc NE 0.
          MESSAGE e108(/psyng/sw) WITH text-017.
        ENDIF.

        gf_dispchg = gc_change.
        PERFORM check_version_editable.
        CHECK gf_dispchg = gc_change.

        CALL FUNCTION 'ENQUEUE_/PSYNG/TABLEVERS'
          EXPORTING
            tabname        = '/PSYNG/CRITCODES'
            vrsio          = g_sod_vrsio
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          gf_dispchg = gc_display.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          gt_locked-type   = 'TABLEVERS'.
          gt_locked-object = '/PSYNG/CRITCODES'.
          APPEND gt_locked.
        ENDIF.
      ELSE.
        sec_actvt = act_display.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
                 ID 'ACTVT' FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
        IF sy-subrc NE 0.
          MESSAGE e108(/psyng/sw) WITH text-016.
        ENDIF.

        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.

        CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
          EXPORTING
            tabname = '/PSYNG/CRITCODES'
            vrsio   = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'TABLEVERS'.
        gf_dispchg = gc_display.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

      CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
        EXPORTING
          tabname = '/PSYNG/CRITCODES'
          vrsio   = g_sod_vrsio.

      DELETE gt_locked WHERE type = 'TABLEVERS'.
      CLEAR: gf_data_change, g_trans_itab, g_trans_itab[], tstct,
             first_txn1, populated.
    WHEN 'FS'.
      g_fullscreen = '0208'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
    WHEN 'LTEXT'.
      DATA  : l_index      TYPE i,
              lt_texts_ct  TYPE TABLE OF /psyng/texts WITH HEADER LINE,
              lt_texts_ct1 TYPE TABLE OF /psyng/texts WITH HEADER LINE,
              l_line       TYPE /psyng/texts-line.
      REFRESH: i_text.
      READ TABLE g_trans_itab WITH KEY flag = 'X'.
      l_index = sy-tabix.
      IF sy-subrc NE 0.
        MESSAGE i161(/psyng/sw).
        EXIT.
      ENDIF.

      DELETE gt_texts_ct WHERE vrsio NE g_sod_vrsio.

      LOOP AT gt_texts_ct WHERE textname = g_trans_itab-tcode.
        i_text-text = gt_texts_ct-text.
        APPEND i_text.
      ENDLOOP.
      IF sy-subrc = 0.
        gt_editor_text[] = i_text[].
      ELSE.

        SELECT line text FROM /psyng/texts
            INTO CORRESPONDING FIELDS OF TABLE i_text
            WHERE textname = g_trans_itab-tcode
            AND   object   = 'X'
            AND   vrsio    = g_sod_vrsio
            AND   spras    = sy-langu
            ORDER BY line.
        IF sy-subrc = 0.
          gt_editor_text[] = i_text[].
        ELSE.
          REFRESH gt_editor_text.
          CLEAR gt_editor_text.
        ENDIF.
      ENDIF.

      CONCATENATE 'Tcode' g_trans_itab-tcode  '- SOD Version -'
      g_sod_vrsio INTO gtitle SEPARATED BY space.

      PERFORM popup_long_text.
      CLEAR gtitle.
      CLEAR g_trans_itab-flag.
      CLEAR i_text.
      REFRESH i_text.
      REFRESH : lt_texts_ct.
      i_text[] = gt_editor_text[].

      FREE : gt_editor_text.
      CLEAR : gt_editor_text.

      lt_texts_ct-vrsio    = g_sod_vrsio.
      lt_texts_ct-textname = g_trans_itab-tcode.
      lt_texts_ct-object = 'X'.
      IF i_text[] IS INITIAL.
        SELECT SINGLE line FROM /psyng/texts
        INTO l_line WHERE textname = g_trans_itab-tcode
        AND vrsio = g_sod_vrsio
        AND object = 'X'.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts WHERE textname = g_trans_itab-tcode
                                      AND vrsio = g_sod_vrsio
                                      AND object = 'X'.
          MODIFY g_trans_itab INDEX l_index TRANSPORTING flag.
          CLEAR g_trans_itab.
          EXIT.
        ELSE.
          MODIFY g_trans_itab INDEX l_index TRANSPORTING flag.
          CLEAR g_trans_itab.
          EXIT.
        ENDIF.
      ELSE.
        LOOP AT i_text.
          lt_texts_ct-line = lt_texts_ct-line + 1.
          MOVE-CORRESPONDING i_text TO lt_texts_ct.
          APPEND lt_texts_ct.
        ENDLOOP.
      ENDIF.
      lt_texts_ct1[] = lt_texts_ct[].
      SORT lt_texts_ct1 BY textname.
      DELETE ADJACENT DUPLICATES FROM lt_texts_ct1 COMPARING textname.

      LOOP AT lt_texts_ct1.
        DELETE gt_texts_ct WHERE textname = lt_texts_ct1-textname.
      ENDLOOP.


      APPEND LINES OF lt_texts_ct TO gt_texts_ct.
      CLEAR lt_texts_ct.
      REFRESH lt_texts_ct.
      SORT gt_texts_ct.
      DELETE ADJACENT DUPLICATES FROM gt_texts_ct COMPARING ALL FIELDS.

      MODIFY g_trans_itab INDEX l_index TRANSPORTING flag.
      CLEAR g_trans_itab.


    WHEN 'SORT_A'.
      sort_type = 'A'.
      PERFORM sort_col_ct USING sort_type.
      first_txn1 = 'X'.

    WHEN 'SORT_D'.
      sort_type = 'D'.
      PERFORM sort_col_ct USING sort_type.
      first_txn1 = 'X'.


*    WHEN 'SEARCH'.
    WHEN 'FILTER'.

      DATA: l_tabix     LIKE sy-tabix,
            lt_critrans LIKE TABLE OF g_trans_itab WITH HEADER LINE.

      CLEAR: gl_critrans.
      g_call_scrn = '0208'.
      CALL SCREEN 907 STARTING AT 3 10.
      CHECK sy-ucomm = 'CONTINUE'.



      RANGES: r_tcode FOR tstc-tcode,
              r_towner FOR /psyng/critcodes-owner,
              r_timp   FOR /psyng/critcodes-imp,
              r_tbusarea FOR /psyng/critcodes-busarea.
      REFRESH: lt_critrans, r_tcode, r_towner, r_timp, r_tbusarea.
*--Collect Search value in Ranges
      IF NOT gl_critrans-tcode IS INITIAL.
        IF  gl_critrans-tcode CS '*'.
          r_tcode-sign = 'I'.
          r_tcode-option = 'CP'.
        ELSE.
          r_tcode-sign = 'I'.
          r_tcode-option = 'EQ'.
        ENDIF.
        r_tcode-low = gl_critrans-tcode.
        COLLECT r_tcode.
      ENDIF.

      IF NOT gl_critrans-owner IS INITIAL.
        IF  gl_critrans-owner CS '*'.
          r_towner-sign = 'I'.
          r_towner-option = 'CP'.
        ELSE.
          r_towner-sign = 'I'.
          r_towner-option = 'EQ'.
        ENDIF.
        r_towner-low = gl_critrans-owner.
        COLLECT r_towner.
      ENDIF.

      IF NOT gl_critrans-imp IS INITIAL.
        IF  gl_critrans-imp CS '*'.
          r_timp-sign = 'I'.
          r_timp-option = 'CP'.
        ELSE.
          r_timp-sign = 'I'.
          r_timp-option = 'EQ'.
        ENDIF.
        r_timp-low = gl_critrans-imp.
        COLLECT r_timp.
      ENDIF.

      IF NOT gl_critrans-busarea IS INITIAL.
        IF  gl_critrans-busarea CS '*'.
          r_tbusarea-sign = 'I'.
          r_tbusarea-option = 'CP'.
        ELSE.
          r_tbusarea-sign = 'I'.
          r_tbusarea-option = 'EQ'.
        ENDIF.
        r_tbusarea-low = gl_critrans-busarea.
        COLLECT r_tbusarea.
      ENDIF.
*----- Filter data from tc table acc. to search input
      LOOP AT g_trans_itab WHERE tcode IN r_tcode
                             AND owner IN r_towner
                             AND imp   IN r_timp
                             AND busarea IN r_tbusarea.
        MOVE-CORRESPONDING  g_trans_itab TO lt_critrans.
        APPEND lt_critrans.
      ENDLOOP.

      APPEND LINES OF g_trans_itab TO gt_trans_bckup. "HBHALLA
      REFRESH  g_trans_itab.
      LOOP AT lt_critrans.
        MOVE-CORRESPONDING lt_critrans TO g_trans_itab.
        APPEND g_trans_itab.

*MODIFY g_trans_itab FROM lt_critrans INDEX critrans-current_line.
        CLEAR: lt_critrans.
      ENDLOOP.

      IF g_trans_itab[] IS INITIAL.
        CLEAR g_filtertext_t.
      ENDIF.
*      ELSE.
      g_filtertext_t = 'Filter applied'(248).

*---->when no input in search screen
      IF gl_critrans-tcode IS INITIAL
                     AND gl_critrans-owner IS INITIAL
                     AND gl_critrans-imp IS INITIAL
                     AND gl_critrans-busarea IS INITIAL.
        CLEAR: critran-lines, g_trans_itab[].
        SELECT tcode imp owner busarea
       INTO (g_trans_itab-tcode, g_trans_itab-imp, g_trans_itab-owner,
              g_trans_itab-busarea)
               FROM /psyng/critcodes
               WHERE vrsio = g_sod_vrsio.

          g_trans_itab-flag = space.

          SELECT SINGLE ttext INTO g_trans_itab-ttext FROM tstct
          WHERE sprsl = sy-langu
          AND   tcode = g_trans_itab-tcode.
          IF sy-subrc = 0.
            APPEND g_trans_itab.
          ELSE.
            g_trans_itab-ttext = 'Tcode for cross system analysis'(192).
            APPEND g_trans_itab.
          ENDIF.
          ADD 1 TO critran-lines.
        ENDSELECT.
        CLEAR g_filtertext_t.
      ENDIF.

    WHEN 'TUNFILTER'.
      CLEAR: g_filtertext_t, g_trans_itab[].
      SELECT tcode imp owner busarea
      INTO (g_trans_itab-tcode, g_trans_itab-imp, g_trans_itab-owner,
            g_trans_itab-busarea)
             FROM /psyng/critcodes
             WHERE vrsio = g_sod_vrsio.

        g_trans_itab-flag = space.

        SELECT SINGLE ttext INTO g_trans_itab-ttext FROM tstct
        WHERE sprsl = sy-langu
        AND   tcode = g_trans_itab-tcode.
        IF sy-subrc = 0.
          APPEND g_trans_itab.
        ELSE.
          g_trans_itab-ttext = 'Tcode for cross system analysis'(192).
          APPEND g_trans_itab.
        ENDIF.
*        ADD 1 TO critran-lines.
      ENDSELECT.

      REFRESH: gt_trans_bckup. "HBHALLA
      CLEAR: gt_trans_bckup. "HBHALLA
      DESCRIBE TABLE g_trans_itab LINES critran-lines.
      SORT g_trans_itab BY tcode.

    WHEN 'SYSFLTR'.
*  B8628.
      DATA lv_rowcnt TYPE i.
      LOOP AT g_trans_itab WHERE flag = 'X'.
        lv_rowcnt = lv_rowcnt + 1.
      ENDLOOP.
      IF lv_rowcnt = 0.
        MESSAGE i168(/psyng/sw).
      ELSEIF lv_rowcnt = 1.
        MOVE-CORRESPONDING g_trans_itab TO wa_trans_itab.
        CALL SCREEN '0911'.
      ELSE.
        MESSAGE i189(/psyng/sw).
      ENDIF.
      CLEAR :g_trans_itab,wa_trans_itab, lv_rowcnt.
* End.
    WHEN OTHERS.
      CLEAR populated.
  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.
ENDFORM.                    " user_command_0208


*---------------------------------------------------------------------*
*       FORM fill_con_mit_auditor_text                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_MCUSER                                                      *
*  -->  E_CONFLICT_T                                                  *
*  -->  E_MITIGATION_T                                                *
*  -->  E_AUDITOR_T                                                   *
*---------------------------------------------------------------------*
FORM fill_con_mit_auditor_text USING
         i_conid i_contid i_auditor
CHANGING e_conflict_t TYPE /psyng/conflict-description
          e_mitigation_t TYPE /psyng/mchdr-description
          e_auditor_t TYPE /psyng/bc_uidn-name_first
          e_type TYPE /psyng/mchdr-type
          e_mit_just_req
          e_mit_att_req.

  DATA: ls_mchdr    TYPE /psyng/mchdr,
        l_full_name TYPE /psyng/bc_uidn-name_text.

  IF NOT i_contid IS INITIAL.
    SELECT SINGLE description FROM /psyng/conflict
    INTO e_conflict_t WHERE
         conid = i_conid.

    SELECT SINGLE *
        FROM /psyng/mchdr
        INTO  ls_mchdr WHERE
       contid = i_contid.

    e_mit_just_req   = ls_mchdr-just_req.
    e_mit_att_req    = ls_mchdr-attach_req.
    e_type           = ls_mchdr-type.

    SELECT SINGLE name_text FROM /psyng/bc_uidn
    INTO l_full_name WHERE bname = i_auditor.
    e_auditor_t =  l_full_name.

*    get text
    SELECT line text INTO CORRESPONDING FIELDS OF TABLE i_text
                   FROM /psyng/texts
                   WHERE textname = i_contid
                    AND   object   = 'M'
                    AND   spras    = sy-langu
                    ORDER BY line.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  user_command_0211
*&---------------------------------------------------------------------*
*       Handle user commands from screen 211
*----------------------------------------------------------------------*
FORM user_command_0211.
  DATA: ll_mctran    TYPE /psyng/mctran,
        ll_mcrepid   TYPE /psyng/mcrepid,
        lt_texts     TYPE TABLE OF /psyng/texts WITH HEADER LINE,
        lt_mcauditor TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
        lt_mctran    TYPE TABLE OF /psyng/mctran WITH HEADER LINE,
        lt_mcrepid   TYPE TABLE OF /psyng/mcrepid WITH HEADER LINE,
        lt_mcuser    TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
        lt_mcusrgrp  TYPE TABLE OF /psyng/mcusrgrp WITH HEADER LINE,
        ls_mcauditor TYPE /psyng/mcauditor,
        l_noedit     TYPE /psyng/swsodvers-noedit,
        ls_mcrvwhdr  TYPE /psyng/mcrvwhdr.
*        ls_mit_assgn  TYPE /psyng/mitigation_assignment,
*        lf_aud_email  TYPE /psyng/bapiflagx.
  DATA: if_add  TYPE flag,
        if_list TYPE flag.
  STATICS: ls_contid TYPE /psyng/mchdr-contid.

  RANGES: lr_contid FOR /psyng/mchdr-contid.

* Unlock previous mitigating control ID
*  IF NOT ls_contid IS INITIAL.
  IF /psyng/mchdr-contid <> ls_contid.
    CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
      EXPORTING
   mandt  = sy-mandt                   "#EC SAST_CI_GEN_CHECK (HBHALLA)
   contid = ls_contid
   _scope = 3.
    CLEAR first_time.
  ENDIF.
*  ENDIF.

  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC' AND ok_code <> 'DISPCHG'.
    PERFORM authority_check_mc_h
            USING sec_actvt /psyng/mchdr-contid.
  ENDIF.

  populated = 'X'.

  CASE ok_code.
    WHEN 'AUDIT'.
      SUBMIT /psyng/sw_043 VIA SELECTION-SCREEN
      WITH p_sodvrs = g_sod_vrsio AND RETURN.
    WHEN 'UPDOWN'.
      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
                           WITH mithead = 'X'
      AND RETURN.
    WHEN 'ENTER'.
      PERFORM load_mitigation CHANGING ls_contid.
    WHEN 'CREATE'.
*--Clear Mitigation ID Parameter
      SET PARAMETER ID '/PSYNG/SW_MIT' FIELD space.

      PERFORM authority_check_mc_h
              USING act_create /psyng/mchdr-contid.
      sec_actvt = act_create.
      PERFORM exit_without_save.
      CHECK gf_answer = '1'.



*     Unlock mitigating control ID
      IF NOT /psyng/mchdr-contid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
          EXPORTING
  mandt  = sy-mandt                    "#EC SAST_CI_GEN_CHECK (HBHALLA)
           contid = /psyng/mchdr-contid
           _scope = 3.
      ENDIF.


      CLEAR: first_time, gf_data_change, i_text[], /psyng/mchdr,
             gt_mctran, gt_mctran[], gt_mcrepid, gt_mcrepid[],
             i_text, i_text[], gt_mcauditor, gt_mcauditor[],
             tc_mctran-lines, tc_mcrepid-lines, tc_mcauditor-lines,
             gf_mcaud_chg,ls_contid,g_editor_text[].
    WHEN 'SAVE'.
      IF /psyng/mchdr-contid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-011.
      ENDIF.

      PERFORM authority_check_mc_h
              USING act_change /psyng/mchdr-contid.
      sec_actvt = act_change.
      first_time = space.

      CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
        EXPORTING
    mandt  = sy-mandt                  "#EC SAST_CI_GEN_CHECK (HBHALLA)
    contid = /psyng/mchdr-contid
    _scope = 3.

      DELETE gt_mctran    WHERE tcode = space.
      DELETE gt_mcauditor WHERE auditor = space.
      DELETE gt_mcrepid   WHERE repid = space.
      DESCRIBE TABLE gt_mctran    LINES tc_mctran-lines.
      DESCRIBE TABLE gt_mcauditor LINES tc_mcauditor-lines.
      DESCRIBE TABLE gt_mcrepid   LINES tc_mcrepid-lines.

      LOOP AT gt_mcauditor.
        MOVE-CORRESPONDING gt_mcauditor TO lt_mcauditor.
        lt_mcauditor-contid = /psyng/mchdr-contid.
        APPEND lt_mcauditor.
      ENDLOOP.

      LOOP AT gt_mctran.
        MOVE-CORRESPONDING gt_mctran TO lt_mctran.
        lt_mctran-contid = /psyng/mchdr-contid.
        APPEND lt_mctran.
      ENDLOOP.

      LOOP AT gt_mcrepid.
        MOVE-CORRESPONDING gt_mcrepid TO lt_mcrepid.
        lt_mcrepid-contid = /psyng/mchdr-contid.
        APPEND lt_mcrepid.
      ENDLOOP.

      PERFORM get_editor_text.
      CLEAR lt_texts-vrsio.
      lt_texts-textname = /psyng/mchdr-contid.
      LOOP AT i_text.
        MOVE-CORRESPONDING i_text TO lt_texts.
        APPEND lt_texts.
      ENDLOOP.

*Add in below fm to update /PSYNG/MCRVWHDR table
      MOVE-CORRESPONDING /psyng/mcrvwhdr TO ls_mcrvwhdr.
      ls_mcrvwhdr-contid = /psyng/mchdr-contid.


      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
        EXPORTING
          is_mchdr             = /psyng/mchdr
          is_mcrvwhdr          = ls_mcrvwhdr
        TABLES
          it_mcauditor         = lt_mcauditor
          it_mctran            = lt_mctran
          it_mcrepid           = lt_mcrepid
          it_texts             = lt_texts
        EXCEPTIONS
          target_not_specified = 1
          not_authorized       = 2
          locked               = 3
          OTHERS               = 4.
      CASE sy-subrc.
        WHEN 0.
          MESSAGE s120(/psyng/sw).  " Data Saved
        WHEN 1 OR 4.
          MESSAGE e122(/psyng/sw).  " Data Not Saved
        WHEN 2.
          MESSAGE e108(/psyng/sw) WITH text-134 /psyng/mchdr.
        WHEN 3.
          MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDCASE.

*     Lock mitigating control ID
      CALL FUNCTION 'ENQUEUE_/PSYNG/MCHDR'
        EXPORTING
   mandt          = sy-mandt           "#EC SAST_CI_GEN_CHECK (HBHALLA)
   contid         = /psyng/mchdr-contid
   _scope         = '2'
        EXCEPTIONS
          foreign_lock   = 1
          system_failure = 2
          OTHERS         = 3.
      IF sy-subrc <> 0.
        gf_dispchg = gc_display.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CLEAR gf_data_change.

    WHEN 'DELETE'.

*--Check if Mitigation exists
      SELECT SINGLE contid INTO /psyng/mchdr-contid
      FROM /psyng/mchdr
        WHERE contid = /psyng/mchdr-contid.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
        EXIT.
      ENDIF.
      IF /psyng/mchdr-contid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-011.
      ENDIF.


      PERFORM authority_check_mc_h
              USING act_delete /psyng/mchdr-contid.
      sec_actvt = act_delete.
      CHECK NOT /psyng/mchdr-contid IS INITIAL.

*     Check that mitigation control ID is not assigned
      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcuser
                    WHERE contid = /psyng/mchdr-contid.
      IF sy-subrc = 0.
        MESSAGE e113(/psyng/sw) WITH text-e11 text-011 text-e12.
      ENDIF.

      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcusrgrp
                    WHERE contid = /psyng/mchdr-contid.
      IF sy-subrc = 0.
        MESSAGE e113(/psyng/sw) WITH text-e11 text-011 text-e13.
      ENDIF.

      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mccauser
                    WHERE contid = /psyng/mchdr-contid.
      IF sy-subrc = 0.
        MESSAGE e113(/psyng/sw) WITH text-e11 text-011 text-e22.
      ENDIF.

      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcrole
                    WHERE contid = /psyng/mchdr-contid.
      IF sy-subrc = 0.
        MESSAGE e113(/psyng/sw) WITH text-e11 text-011 text-e24.
      ENDIF.

      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conpmit
                    WHERE contid = /psyng/mchdr-contid.
      IF sy-subrc = 0.
        MESSAGE e113(/psyng/sw) WITH text-e11 text-011 text-e32.
      ENDIF.

      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                    WHERE contid = /psyng/mchdr-contid.
      IF sy-subrc = 0.
        MESSAGE e113(/psyng/sw) WITH text-e11 text-011 text-e32.
      ENDIF.

      CONCATENATE text-q02 /psyng/mchdr-contid
          INTO popup_question SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = popup_question
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

*     Unlock mitigating control ID
      CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
        EXPORTING
   mandt  = sy-mandt                   "#EC SAST_CI_GEN_CHECK (HBHALLA)
   contid = /psyng/mchdr-contid
   _scope = 3.

      CALL FUNCTION '/PSYNG/SW_CR_DELETE_MIT_CTRL'
        EXPORTING
          i_contid       = /psyng/mchdr-contid
        EXCEPTIONS
          not_authorized = 1
          not_exist      = 2
          locked         = 3
          OTHERS         = 4.
      CASE sy-subrc.
        WHEN 0.
          CONCATENATE text-011 /psyng/mchdr-contid text-126
                      INTO messagetext SEPARATED BY space.

          MESSAGE i208(00) WITH messagetext.
        WHEN 1.
          MESSAGE e108(/psyng/sw) WITH text-137 text-055.
        WHEN 2 OR 4.
          MESSAGE e113(/psyng/sw) WITH text-e11.
        WHEN 3.
          MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDCASE.

      CLEAR: first_time, gf_data_change, i_text[], /psyng/mchdr,
             gt_mctran, gt_mctran[], gt_mcrepid, gt_mcrepid[],
             i_text, i_text[], gt_mcauditor, gt_mcauditor[],
             tc_mctran-lines, tc_mcrepid-lines, tc_mcauditor-lines,
             gf_mcaud_chg,g_editor_text[].

*   Transport table entries
    WHEN 'TRANSPORT'.
      IF /psyng/mchdr-contid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-t02.
      ENDIF.

      lr_contid-sign = 'I'.
      lr_contid-option = 'EQ'.
      lr_contid-low = /psyng/mchdr-contid.
      APPEND lr_contid.

      SUBMIT /psyng/sw_048
      VIA SELECTION-SCREEN
             WITH p_tcont = gc_select
*             WITH p_tvhead = gc_select
             WITH s_contid IN lr_contid
             AND RETURN.

    WHEN 'MCTRAN_INSR'.

      LOOP AT gt_mctran WHERE sel = 'X'.
        CLEAR gt_mctran-sel.
        MODIFY gt_mctran.
      ENDLOOP.

*      ADD 5 TO tc_mctran-lines.
      DESCRIBE TABLE gt_mctran LINES tc_mctran-lines.
      PERFORM insert_row_into_tc USING  'TC_MCTRAN' 'GT_MCTRAN'.


    WHEN 'MCTRAN_DELE'.
      DELETE gt_mctran WHERE sel = 'X'.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ELSE.
        DESCRIBE TABLE gt_mctran LINES tc_mctran-lines.
      ENDIF.

    WHEN 'MCREPID_INSR'.

      LOOP AT gt_mcrepid WHERE sel = 'X'.
        CLEAR gt_mcrepid-sel.
        MODIFY gt_mcrepid.
      ENDLOOP.
*      ADD 5 TO tc_mcrepid-lines.
      DESCRIBE TABLE gt_mcrepid LINES tc_mcrepid-lines.
      PERFORM insert_row_into_tc USING  'TC_MCREPID' 'GT_MCREPID'.



    WHEN 'MCREPID_DELE'.
      DELETE gt_mcrepid WHERE sel = 'X'.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ELSE.
        DESCRIBE TABLE gt_mcrepid LINES tc_mcrepid-lines.
      ENDIF.

    WHEN 'MCAUDITOR_INSR'.
*      ADD 20 TO tc_mcauditor-lines.

      LOOP AT gt_mcauditor WHERE sel = 'X'.
        CLEAR gt_mcauditor-sel.
        MODIFY gt_mcauditor.
      ENDLOOP.

      DESCRIBE TABLE gt_mcauditor LINES tc_mcauditor-lines.
      PERFORM insert_row_into_tc USING  'TC_MCAUDITOR' 'GT_MCAUDITOR'.

    WHEN 'MCAUDITOR_DELE'.
      DELETE gt_mcauditor WHERE sel = gc_select.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ELSE.
        DESCRIBE TABLE gt_mcauditor LINES tc_mcauditor-lines.
      ENDIF.

    WHEN 'CHANGES'.
      IF NOT /psyng/mchdr-contid IS INITIAL.
        lr_contid-sign   = 'I'.
        lr_contid-option = 'EQ'.
        lr_contid-low    = /psyng/mchdr-contid.
        APPEND lr_contid.
      ENDIF.

      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH p_cont    = 'X'
             WITH s_contid IN lr_contid
             AND RETURN.

    WHEN 'ATTACHMENT'.
*      IF gf_dispchg = 'C'.
*        if_add = 'X'.
*        CLEAR if_list.
*       ELSE.
*        if_list = 'X'.
*        CLEAR if_add.
*      ENDIF.
      CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
        EXPORTING
          if_header       = 'X'
          if_list         = 'X'
          if_add          = ''
          i_mcid          = /psyng/mchdr-contid
        EXCEPTIONS
          invalid_input   = 1
          not_implemented = 2
          gos_failure     = 3
          OTHERS          = 4.
      IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
    WHEN 'ADDATTACH'.
      CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
        EXPORTING
          if_header       = 'X'
          if_list         = ''
          if_add          = 'X'
          i_mcid          = /psyng/mchdr-contid
        EXCEPTIONS
          invalid_input   = 1
          not_implemented = 2
          gos_failure     = 3
          OTHERS          = 4.
      IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.


*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        PERFORM authority_check_mc_h
                USING act_change /psyng/mchdr-contid.
        sec_actvt = act_change.
        gf_dispchg = gc_change.

        IF NOT /psyng/mchdr-contid IS INITIAL.
*         Check if Mitigation ID is used in SOD Conflicts
          SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                        WHERE contid = /psyng/mchdr-contid
                          AND vrsio  = g_sod_vrsio.
          IF sy-subrc = 0.
            MESSAGE w113(/psyng/sw) WITH text-011 /psyng/mchdr-contid
                                         text-e14.
          ENDIF.

*        Lock mitigating control ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/MCHDR'
            EXPORTING
*             mandt          = sy-mandt
              contid         = /psyng/mchdr-contid
*             _scope         = '2
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM authority_check_mc_h
                USING act_display /psyng/mchdr-contid.
        sec_actvt = act_display.
        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change, gf_mcaud_chg.
        ok_code = 'ENTER'.
        PERFORM user_command_0211.

        gf_dispchg = gc_display.

*       Unlock mitigating control ID
        IF NOT /psyng/mchdr-contid IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
            EXPORTING
*             mandt  = sy-mandt
              contid = /psyng/mchdr-contid.
*                    _scope = 3.

          COMMIT WORK.
        ENDIF.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8' OR
      'SODFUN_FC1' OR 'SODFUN_FC2' OR 'SODFUN_FC4' OR 'SODFUN_FC5' OR
         'MITCON_FC2'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.


*     Unlock mitigating control ID
      IF NOT /psyng/mchdr-contid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/MCHDR'
          EXPORTING
    mandt  = sy-mandt                  "#EC SAST_CI_GEN_CHECK (HBHALLA)
    contid = /psyng/mchdr-contid
    _scope = 3.
      ENDIF.


      CLEAR: first_time, i_text, i_text[], gf_data_change, /psyng/mchdr,
               gt_mctran, gt_mctran[], gt_mcrepid, gt_mcrepid[],
               ls_contid, populated, gt_mcauditor, gt_mcauditor[],
               tc_mctran-lines, tc_mcrepid-lines, tc_mcauditor-lines,
               gf_mcaud_chg,g_editor_text[].

      IF gf_dispchg = gc_change.
        IF g_sodfun-pressed_tab <> c_sodfun-tab4.
          SELECT SINGLE noedit INTO l_noedit FROM /psyng/swsodvers
                   WHERE vrsio = g_sod_vrsio.
          IF l_noedit = gc_select.
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ENDIF.


    WHEN 'FS'.
      g_fullscreen = '0211'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

    WHEN 'ATTACH'.
      DATA l TYPE i.
      DATA url1 TYPE string.
      IF /psyng/mchdr-contid IS INITIAL.
        /psyng/mchdr-contid = space.
      ELSE.
   SELECT SINGLE * FROM /psyng/mchdr WHERE contid = /psyng/mchdr-contid.
        IF sy-subrc NE 0.
          MESSAGE e157(/psyng/sw).
        ENDIF.
      ENDIF.

      CALL FUNCTION '/PSYNG/SW_101'
        EXPORTING
          i_contid              = /psyng/mchdr-contid
        IMPORTING
          e_url                 = url1
        EXCEPTIONS
          parameter_not_defined = 1
          text_not_maintained   = 2
          OTHERS                = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.


      l = strlen( url1 ).

      url = url1+0(l).

      CHECK NOT url IS INITIAL.
      CALL FUNCTION 'CALL_BROWSER'
        EXPORTING
          url                    = url
*         WINDOW_NAME            = ' '
*         BROWSER_TYPE           =
*         CONTEXTSTRING          =
        EXCEPTIONS
          frontend_not_supported = 1
          frontend_error         = 2
          prog_not_found         = 3
          no_batch               = 4
          unspecified_error      = 5
          OTHERS                 = 6.
      IF sy-subrc <> 0.
        MESSAGE e002(/psyng/sw) WITH
        'Unable to load url to documentation'.

      ENDIF.


    WHEN 'ACTIVATE' OR 'DEACTIVATE'.
      IF ok_code = 'ACTIVATE'.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
                  ID 'ACTVT' FIELD '07'
                  ID 'Y&SW_VRSIO' FIELD  g_sod_vrsio
                  ID 'Y&SW_CNTID' FIELD /psyng/mchdr-contid.
        IF sy-subrc = 0.
          CLEAR /psyng/mchdr-inactive.
          g_active_inactive = text-008.
        ELSE.
          MESSAGE e108(/psyng/sw) WITH text-e30.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
                 ID 'ACTVT' FIELD '07'
                 ID 'Y&SW_VRSIO' FIELD  g_sod_vrsio
                 ID 'Y&SW_CNTID' FIELD /psyng/mchdr-contid.
        IF sy-subrc = 0.
          /psyng/mchdr-inactive = 'X'.
          g_active_inactive = text-009.
        ELSE.
          MESSAGE e108(/psyng/sw) WITH text-e29.
        ENDIF.

      ENDIF.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
        EXPORTING
          is_mchdr             = /psyng/mchdr
        EXCEPTIONS
          target_not_specified = 1
          not_authorized       = 2
          locked               = 3
          OTHERS               = 4.
      "(++)BOC UMITTAL SE VF scan-25/11/2024
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
    WHEN 'SORT_A'.
      sort_type = 'A'.
      PERFORM sort_col_mc USING sort_type.

    WHEN 'SORT_D'.
      sort_type = 'D'.
      PERFORM sort_col_mc USING sort_type.



  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.
ENDFORM.                    " user_command_0211

*&---------------------------------------------------------------------*
*&      Form  user_command_0212
*&---------------------------------------------------------------------*
*       Handle user commands from screen 212
*----------------------------------------------------------------------*
FORM user_command_0212.
  DATA: ll_cols       TYPE cxtab_column,
        l_table(10)   TYPE c,
        l_column(10)  TYPE c,
        l_tabix       TYPE sy-tabix,
        l_filename    TYPE rlgrap-filename,
        lt_file       LIKE gt_mcuser OCCURS 0 WITH HEADER LINE,
        l_file_mcuser TYPE string,
        ls_return     TYPE bapireturn,
        ls_filename   TYPE string,
        ls_mcuser     TYPE /psyng/mcuser,
        ls_mchdr      TYPE /psyng/mchdr,
        lf_update     TYPE /psyng/bapiflagx,
        lt_rfc        LIKE rfcdes OCCURS 0 WITH HEADER LINE,
        lt_mcuser     TYPE TABLE OF /psyng/mitigation_assignment
                      WITH HEADER LINE,
        lt_mcusersave TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
        lt_uinfo      TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
        l_noedit      TYPE /psyng/swsodvers-noedit,
        l_objid       TYPE slis_entry.

  STATICS: BEGIN OF ls_sort,
             name  LIKE screen-name,
             ucomm TYPE sy-ucomm,
           END OF ls_sort.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_mc_assign USING sec_actvt space space
                                                      space space.
  ENDIF.

  CASE ok_code.

*__________________________________________
*-----New upload download Functionality----

    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
                           WITH p_usassn = 'X'
      AND RETURN.

      REFRESH gt_mcuser.
*__________________________________________

    WHEN 'QCUSER'.
      CALL FUNCTION '/PSYNG/SW_SOD_QUICK_CHECK_USER'
        EXPORTING
          vrsio = g_sod_vrsio.

    WHEN 'CREATE'.
      IF gf_mit_asgn_auth_check = 'X'.
*-- Check new Auth Object
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
           ID 'ACTVT'      FIELD '01'
           ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
             ID 'ACTVT'      FIELD '01'
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ENDIF.

      IF sy-subrc <> 0.
        MESSAGE e108(/psyng/sw) WITH text-051
                'mitigation user assignments'(e25).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      lt_mcuser-rfcdest = lt_rfc-rfcoptions.
      lt_mcuser-type    = '1'.
      APPEND lt_mcuser.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert  = 'X'
        TABLES
          it_mcuser  = lt_mcuser
          it_rfcdest = lt_rfc.
*                it_sw_uinfo = lt_uinfo.

      LOOP AT lt_mcuser.
        READ TABLE gt_mcuser WITH KEY contid  = lt_mcuser-contid
                                      conid   = lt_mcuser-conid
                                      userid  = lt_mcuser-userid
                                      vrsio   = lt_mcuser-vrsio
                                      org_abb = lt_mcuser-org_abb.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mcuser.
        APPEND gt_mcuser.
        ADD 1 TO tc_mcuser-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcuser BY (ls_sort-name).
        ELSE.
          SORT gt_mcuser BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcuser BY userid conid vrsio contid from_date.
      ENDIF.

    WHEN 'COPY'.

      READ TABLE gt_mcuser WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mcuser WHERE sel = gc_select.
        PERFORM authority_check_mc_assign
                USING act_change
                      gt_mcuser-userid
                      gt_mcuser-contid
                      gt_mcuser-conid
                      gt_mcuser-vrsio.

        MOVE-CORRESPONDING gt_mcuser TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '1'.                 "User
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert   = 'X'
        TABLES
          it_mcuser   = lt_mcuser
          it_rfcdest  = lt_rfc
          it_sw_uinfo = lt_uinfo.

      LOOP AT lt_mcuser.
        READ TABLE gt_mcuser WITH KEY contid  = lt_mcuser-contid
                                      conid   = lt_mcuser-conid
                                      userid  = lt_mcuser-userid
                                      vrsio   = lt_mcuser-vrsio
                                      org_abb = lt_mcuser-org_abb.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mcuser.
        APPEND gt_mcuser.
        ADD 1 TO tc_mcuser-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcuser BY (ls_sort-name).
        ELSE.
          SORT gt_mcuser BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcuser BY userid conid vrsio contid from_date.
      ENDIF.

    WHEN 'EDIT'.
      sec_actvt = act_change.
      READ TABLE gt_mcuser WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mcuser WHERE sel = gc_select.
        PERFORM authority_check_mc_assign
                USING act_change
                      gt_mcuser-userid
                      gt_mcuser-contid
                      gt_mcuser-conid
                      gt_mcuser-vrsio.

        MOVE-CORRESPONDING gt_mcuser TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '1'.                 "User
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_maint_all = 'X'
        TABLES
          it_mcuser    = lt_mcuser
          it_rfcdest   = lt_rfc
          it_sw_uinfo  = lt_uinfo.

      LOOP AT gt_mcuser WHERE sel = gc_select.
        READ TABLE lt_mcuser WITH KEY contid  = gt_mcuser-contid
                                      conid   = gt_mcuser-conid
                                      userid  = gt_mcuser-userid
                                      vrsio   = gt_mcuser-vrsio
                                      org_abb = lt_mcuser-org_abb.
        IF sy-subrc = 0.
          l_tabix = sy-tabix.
          gl_mcuser = gt_mcuser.
          gl_mcuser-auditor   = lt_mcuser-auditor.
          gl_mcuser-from_date = lt_mcuser-from_date.
          gl_mcuser-to_date   = lt_mcuser-to_date.
          gl_mcuser-approved  = lt_mcuser-approved.
          gl_mcuser-org_abb   = lt_mcuser-org_abb.

          IF gl_mcuser <> gt_mcuser.
            MODIFY gt_mcuser FROM gl_mcuser
                   TRANSPORTING auditor from_date to_date approved.
          ENDIF.

          DELETE lt_mcuser INDEX l_tabix.
        ELSE.
          DELETE gt_mcuser.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcuser.
        MOVE-CORRESPONDING lt_mcuser TO gt_mcuser.
        APPEND gt_mcuser.
        ADD 1 TO tc_mcuser-lines.

        IF NOT ls_sort IS INITIAL.
          IF ls_sort-ucomm = 'SORTA'.
            SORT gt_mcuser BY (ls_sort-name).
          ELSE.
            SORT gt_mcuser BY (ls_sort-name) DESCENDING.
          ENDIF.
        ELSE.
          SORT gt_mcuser BY userid conid vrsio contid from_date.
        ENDIF.
      ENDLOOP.

    WHEN 'SEL_ALL'.
      gt_mcuser-sel = 'X'.
      MODIFY gt_mcuser TRANSPORTING sel WHERE sel = space.

    WHEN 'DSEL_ALL'.
      CLEAR gt_mcuser-sel.
      MODIFY gt_mcuser TRANSPORTING sel WHERE sel = 'X'.

    WHEN 'PICK'.
      DATA: l_lin           TYPE i,
            l_fieldname(30) TYPE c,
            l_uname         LIKE sy-uname,
            l_contid        TYPE /psyng/mchdr-contid,
            l_parva         TYPE usr05-parva,
            l_sod           TYPE /psyng/swsodvers-vrsio,
            l_dynnr         TYPE sy-dynnr.


      GET CURSOR FIELD l_fieldname LINE l_lin.
      l_lin = l_lin + tc_mcuser-top_line - 1.
      READ TABLE gt_mcuser INDEX l_lin.
      IF l_fieldname = 'GT_MCUSER-CONID'.
        l_objid = gt_mcuser-conid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONID'
            i_objectid   = l_objid
            i_vrsio      = gt_mcuser-vrsio.
      ENDIF.

      IF l_fieldname = 'GT_MCUSER-CONTID'.
        l_objid = gt_mcuser-contid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONTID'
            i_objectid   = l_objid
            i_vrsio      = gt_mcuser-vrsio.
      ENDIF.

    WHEN 'DELETE'.

      READ TABLE gt_mcuser WITH KEY sel = gc_select.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.
      l_tabix = sy-tabix.


      PERFORM authority_check_mc_assign
              USING act_delete
                    gt_mcuser-userid gt_mcuser-contid gt_mcuser-conid
                    gt_mcuser-vrsio.
      sec_actvt = act_delete.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-t02
          text_question         = text-q01
          text_button_1         = text-001
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = text-002
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = gf_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK gf_answer = '1'.

      LOOP AT gt_mcuser WHERE sel = gc_select.
        ls_mchdr-contid = gt_mcuser-contid.
        MOVE-CORRESPONDING gt_mcuser TO lt_mcusersave.
        APPEND lt_mcusersave.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcuser            = lt_mcusersave
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        CASE sy-subrc.
          WHEN 0.
            MESSAGE s117(/psyng/sw).  " Mitigation Deleted
          WHEN 1 OR 4.
            MESSAGE e122(/psyng/sw).  " Data Not Saved
          WHEN 2.
            MESSAGE e108(/psyng/sw) WITH text-134 /psyng/mchdr.
          WHEN 3.
            MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDCASE.
        MOVE-CORRESPONDING gt_mcuser TO gs_assingment.
        DELETE gt_mcuser.
        REFRESH lt_mcusersave.

*---odubey 08/06/2022 Delete justification as well

        gs_assingment-type = '1'.
        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment = 'X'
            if_delete     = 'X'
            i_mcid        = gt_mcuser-contid
            is_assignment = gs_assingment
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             invalid_input   = 1
             not_implemented = 2
             gos_failure     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
        CLEAR gs_assingment.

      ENDLOOP.

      CLEAR: gl_mcuser, gf_edit, gt_mcuser.

    WHEN 'CHANGES'.
      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH p_cont   = 'X'
             WITH p_userid = 'X'
             AND RETURN.

    WHEN 'CURR_VER' OR 'ALL_VER' .

      DATA lt_mcuser1 LIKE TABLE OF gt_mcuser
                   WITH HEADER LINE.
      CLEAR g_mc_fltr_fcode.
      g_mc_fltr_fcode = ok_code.
**----> when click for current version
      IF ok_code = 'CURR_VER'.
        LOOP AT gt_mcuser WHERE vrsio = g_sod_vrsio.
          MOVE-CORRESPONDING  gt_mcuser TO lt_mcuser1.
          APPEND lt_mcuser1.
        ENDLOOP.

        REFRESH  gt_mcuser.
        LOOP AT lt_mcuser1.
          MOVE-CORRESPONDING lt_mcuser1 TO gt_mcuser.
          APPEND gt_mcuser.
          CLEAR: lt_mcuser1.
        ENDLOOP.
        MESSAGE s113(/psyng/sw) WITH text-a96.
      ENDIF.

**---->when click for all version filter
      IF ok_code = 'ALL_VER'.
        SELECT * FROM /psyng/mcuser INTO TABLE gt_mcuser.
        SORT gt_mcuser BY userid conid vrsio contid from_date.
        MESSAGE s113(/psyng/sw) WITH text-a95.
      ENDIF.

    WHEN 'SEARCH' OR 'FINDNEXT'.
      IF ok_code = 'SEARCH'.
        CLEAR gl_mcuser.
        g_call_scrn = '0212'.
        CALL SCREEN 905 STARTING AT 3 10.
        CHECK sy-ucomm = 'CONTINUE'.
      ENDIF.

      IF gl_mcuser-userid IS INITIAL AND gl_mcuser-conid IS INITIAL AND
     gl_mcuser-contid IS INITIAL   AND gl_mcuser-auditor IS INITIAL AND
        gl_mcuser-from_date IS INITIAL AND gl_mcuser-to_date IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-e01.
      ENDIF.

      LOOP AT gt_mcuser WHERE sel = gc_select.
        CLEAR gt_mcuser-sel.
        MODIFY gt_mcuser INDEX sy-tabix.
        l_tabix = sy-tabix + 1.
      ENDLOOP.

      IF ok_code = 'SEARCH'.
        l_tabix = 1.
      ENDIF.

      LOOP AT gt_mcuser FROM l_tabix.
        IF NOT gl_mcuser-userid IS INITIAL.
          CHECK gt_mcuser-userid = gl_mcuser-userid.
        ENDIF.
        IF NOT gl_mcuser-conid IS INITIAL.
          CHECK gt_mcuser-conid = gl_mcuser-conid.
        ENDIF.
        IF NOT gl_mcuser-vrsio IS INITIAL.
          CHECK gt_mcuser-vrsio = gl_mcuser-vrsio.
        ENDIF.
        IF NOT gl_mcuser-contid IS INITIAL.
          CHECK gt_mcuser-contid = gl_mcuser-contid.
        ENDIF.
        IF NOT gl_mcuser-auditor IS INITIAL.
          CHECK gt_mcuser-auditor = gl_mcuser-auditor.
        ENDIF.
        IF NOT gl_mcuser-from_date IS INITIAL.
          CHECK gt_mcuser-from_date = gl_mcuser-from_date.
        ENDIF.
        IF NOT gl_mcuser-to_date IS INITIAL.
          CHECK gt_mcuser-to_date = gl_mcuser-to_date.
        ENDIF.
        gt_mcuser-sel = gc_select.
        MODIFY gt_mcuser INDEX sy-tabix.
        tc_mcuser-top_line = sy-tabix.
        EXIT.
      ENDLOOP.

      READ TABLE gt_mcuser WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
      ENDIF.

      CLEAR gf_edit.

*   Transport table entries
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048
             VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tvhead = gc_select
             WITH p_tuasmt = gc_select
             AND RETURN.

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.

        IF gf_mit_asgn_auth_check = 'X'.
*-- Check new Auth Object
          AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
             ID 'ACTVT'      FIELD act_change
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
             ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ELSE.
          AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
             ID 'ACTVT'      FIELD act_change
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
             ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ENDIF.

        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-038.
        ENDIF.

        sec_actvt = act_change.
        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
      ELSE.
*DHO 20101202


        IF gf_mit_asgn_auth_check = 'X'.
*-- Check new Auth Object
          AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
             ID 'ACTVT'      FIELD act_display
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
             ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ELSE.
          AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
             ID 'ACTVT'      FIELD act_display
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
             ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ENDIF.
        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-035.
        ENDIF.

        sec_actvt = act_display.
        gf_dispchg = gc_display.
        CLEAR gf_edit.
      ENDIF.

    WHEN 'SORTA' OR 'SORTD'.
      CLEAR ls_sort.

      LOOP AT tc_mcuser-cols INTO ll_cols WHERE selected = 'X'.
        SPLIT ll_cols-screen-name AT '-' INTO l_table l_column.
        IF ok_code = 'SORTA'.
          SORT gt_mcuser BY (l_column).
        ELSE.
          SORT gt_mcuser BY (l_column) DESCENDING.
        ENDIF.

        ls_sort-name  = l_column.
        ls_sort-ucomm = ok_code.
      ENDLOOP.

    WHEN 'SHOW_DTL'.
      DATA: l_line        TYPE i,
            lt_mitdetails TYPE TABLE OF /psyng/mitigation_assignment
            WITH HEADER LINE,
            l_signoffid   TYPE /psyng/mcrvwsgn-signoffid.
      GET CURSOR LINE l_line.
      l_line = l_line + tc_mcuser-top_line - 1.
      READ TABLE gt_mcuser INDEX l_line.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING gt_mcuser TO lt_mitdetails.
        lt_mitdetails-type = '1'.
        APPEND lt_mitdetails.

        CALL FUNCTION '/PSYNG/SW_MIT_ASSIGN_DETAILS'
          EXPORTING
            i_contid      = gt_mcuser-contid
            if_show_user  = 'X'
            if_dispchg    = gf_dispchg
          TABLES
            it_mitdetails = lt_mitdetails.
      ELSE.
        MESSAGE i113(/psyng/sw) WITH
              'No Assignment details found!'(e35).
      ENDIF.
    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8' OR
      'SODFUN_FC1' OR 'SODFUN_FC2' OR 'SODFUN_FC4' OR 'SODFUN_FC5' OR
         'MITCON_FC1'.

      IF ok_code <> 'YX_SECTAB_FC2'.
        CLEAR: gl_mcuser, gt_mcuser, gt_mcuser[], populated, i_text[],
             gf_edit.
      ENDIF.

      IF gf_dispchg = gc_change.
        IF g_sodfun-pressed_tab <> c_sodfun-tab4.
          SELECT SINGLE noedit INTO l_noedit FROM /psyng/swsodvers
                   WHERE vrsio = g_sod_vrsio.
          IF l_noedit = gc_select.
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ENDIF.


    WHEN 'FS'.
      g_fullscreen = '0212'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

  ENDCASE.
ENDFORM.                    " user_command_0212

*---------------------------------------------------------------------*
*       FORM get_screen_intput                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_screen_intput.
  REFRESH:  r_contid, r_conid, r_auditor, r_userid,
               r_vrsio, r_from_date, r_to_date,
               r_class,r_swaudid, r_agr_name.
*--Collect Search value in Ranges
  IF NOT gl_mcuser-contid IS INITIAL.
    IF  gl_mcuser-contid CS '*'.
      r_contid-sign = 'I'.
      r_contid-option = 'CP'.
    ELSE.
      r_contid-sign = 'I'.
      r_contid-option = 'EQ'.
    ENDIF.
    r_contid-low = gl_mcuser-contid.
    COLLECT r_contid.
  ENDIF.
  IF NOT gl_mcuser-vrsio IS INITIAL.
    r_vrsio-sign = 'I'.
    r_vrsio-option = 'EQ'.
    r_vrsio-low = gl_mcuser-vrsio.
    COLLECT r_vrsio.
  ENDIF.
  IF NOT gl_mcuser-from_date IS INITIAL.
    r_from_date-sign = 'I'.
    r_from_date-option = 'EQ'.
    r_from_date-low = gl_mcuser-from_date.
    COLLECT r_from_date.
  ENDIF.

  IF NOT gl_mcuser-to_date IS INITIAL.
    r_to_date-sign = 'I'.
    r_to_date-option = 'EQ'.
    r_to_date-low = gl_mcuser-to_date.
    COLLECT r_to_date.
  ENDIF.

  IF NOT gl_mcuser-conid IS INITIAL.
    IF gl_mcuser-conid CS '*'.
      r_conid-sign = 'I'.
      r_conid-option = 'CP'.
    ELSE.
      r_conid-sign = 'I'.
      r_conid-option = 'EQ'.
    ENDIF.
    r_conid-low = gl_mcuser-conid.
    COLLECT r_conid.
  ENDIF.

  IF NOT gl_mcuser-auditor IS INITIAL.
    IF  gl_mcuser-auditor CS '*'.
      r_auditor-sign = 'I'.
      r_auditor-option = 'CP'.
    ELSE.
      r_auditor-sign = 'I'.
      r_auditor-option = 'EQ'.
    ENDIF.
    r_auditor-low = gl_mcuser-auditor.
    COLLECT r_auditor.
  ENDIF.

  IF NOT gl_mcuser-userid IS INITIAL.
    IF  gl_mcuser-userid CS '*'.
      r_userid-sign = 'I'.
      r_userid-option = 'CP'.
    ELSE.
      r_userid-sign = 'I'.
      r_userid-option = 'EQ'.
    ENDIF.
    r_userid-low = gl_mcuser-userid.
    COLLECT r_userid.
  ENDIF.

  IF NOT gl_mcusrgrp-class IS INITIAL.
    IF  gl_mcusrgrp-class CS '*'.
      r_class-sign = 'I'.
      r_class-option = 'CP'.
    ELSE.
      r_class-sign = 'I'.
      r_class-option = 'EQ'.
    ENDIF.
    r_class-low = gl_mcusrgrp-class.
    COLLECT r_class.
  ENDIF.

  IF NOT gl_mcusrgrp-class IS INITIAL.
    IF  gl_mcusrgrp-class CS '*'.
      r_class-sign = 'I'.
      r_class-option = 'CP'.
    ELSE.
      r_class-sign = 'I'.
      r_class-option = 'EQ'.
    ENDIF.
    r_class-low = gl_mcusrgrp-class.
    COLLECT r_class.
  ENDIF.
  IF NOT gl_mcrole-agr_name IS INITIAL.
    IF  gl_mcrole-agr_name CS '*'.
      r_agr_name-sign = 'I'.
      r_agr_name-option = 'CP'.
    ELSE.
      r_agr_name-sign = 'I'.
      r_agr_name-option = 'EQ'.
    ENDIF.
    r_agr_name-low = gl_mcrole-agr_name.
    COLLECT r_agr_name.
  ENDIF.

  IF NOT gl_mccauser-swaudid IS INITIAL.
    IF  gl_mccauser-swaudid CS '*'.
      r_swaudid-sign = 'I'.
      r_swaudid-option = 'CP'.
    ELSE.
      r_swaudid-sign = 'I'.
      r_swaudid-option = 'EQ'.
    ENDIF.
    r_swaudid-low = gl_mccauser-swaudid.
    COLLECT r_swaudid.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  user_command_0222
*&---------------------------------------------------------------------*
*       Handle user commands from screen 222
*----------------------------------------------------------------------*
FORM user_command_0222.
  DATA: ll_cols         TYPE cxtab_column,
        l_table(10)     TYPE c,
        l_column(10)    TYPE c,
        l_tabix         TYPE sy-tabix,
        l_filename      TYPE rlgrap-filename,
        lt_file1        LIKE gt_mcusrgrp OCCURS 0 WITH HEADER LINE,
        l_file_mcusrgrp TYPE string,
        ls_mchdr        TYPE /psyng/mchdr,
        ls_mit_assgn    TYPE /psyng/mitigation_assignment,
        ls_filename     TYPE string,
        lt_rfc          LIKE rfcdes OCCURS 0 WITH HEADER LINE,
        lt_mcuser       TYPE TABLE OF /psyng/mitigation_assignment
                        WITH HEADER LINE,
        lt_mcusrgrp     TYPE TABLE OF /psyng/mcusrgrp WITH HEADER LINE,
        lt_uinfo        TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
        l_noedit        TYPE /psyng/swsodvers-noedit,
        l_objid         TYPE slis_entry.

  STATICS: BEGIN OF ls_sort,
             name  LIKE screen-name,
             ucomm TYPE sy-ucomm,
           END OF ls_sort.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_mc_assign_grp
            USING sec_actvt space space space 0.
  ENDIF.

  CASE ok_code.
    WHEN 'QCUSER'.
      CALL FUNCTION '/PSYNG/SW_SOD_QUICK_CHECK_USER'
        EXPORTING
          vrsio = g_sod_vrsio.
*__________________________________________
*-----New upload download Functionality----

    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
                           WITH p_usrgrp = 'X'
      AND RETURN.

      REFRESH gt_mcusrgrp.
*__________________________________________

    WHEN 'CREATE'.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
         ID 'ACTVT'      FIELD '01'
         ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CLASS' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        MESSAGE e108(/psyng/sw) WITH text-051
                'mitigation user group assignments'(e26).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      lt_mcuser-rfcdest = lt_rfc-rfcoptions.
      lt_mcuser-type    = '2'.
      APPEND lt_mcuser.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert     = 'X'
          if_show_class = 'X'
        TABLES
          it_mcuser     = lt_mcuser
          it_rfcdest    = lt_rfc
          it_sw_uinfo   = lt_uinfo.

      LOOP AT lt_mcuser.
        READ TABLE gt_mcusrgrp WITH KEY contid = lt_mcuser-contid
                                        conid  = lt_mcuser-conid
                                        class  = lt_mcuser-class
                                        vrsio  = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mcusrgrp.
        gt_mcusrgrp-conid = lt_mcuser-conid.
        APPEND gt_mcusrgrp.
        ADD 1 TO tc_mcusrgrp-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcusrgrp BY (ls_sort-name).
        ELSE.
          SORT gt_mcusrgrp BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcusrgrp BY class conid vrsio contid from_date.
      ENDIF.

    WHEN 'COPY'.
      sec_actvt = act_change.
      READ TABLE gt_mcusrgrp WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mcusrgrp WHERE sel = gc_select.
        PERFORM authority_check_mc_assign_grp
                USING act_change
                      gt_mcusrgrp-class
                      gt_mcusrgrp-contid
                      gt_mcusrgrp-conid
                      gt_mcusrgrp-vrsio.

        MOVE-CORRESPONDING gt_mcusrgrp TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '2'.                 "User group
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert     = 'X'
          if_show_class = 'X'
        TABLES
          it_mcuser     = lt_mcuser
          it_rfcdest    = lt_rfc
          it_sw_uinfo   = lt_uinfo.


      LOOP AT lt_mcuser.
        READ TABLE gt_mcusrgrp WITH KEY contid = lt_mcuser-contid
                                        conid  = lt_mcuser-conid
                                        class  = lt_mcuser-class
                                        vrsio  = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mcusrgrp.
        gt_mcusrgrp-conid = lt_mcuser-conid.
        APPEND gt_mcusrgrp.
        ADD 1 TO tc_mcusrgrp-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcusrgrp BY (ls_sort-name).
        ELSE.
          SORT gt_mcusrgrp BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcusrgrp BY class conid vrsio contid from_date.
      ENDIF.

    WHEN 'EDIT'.
      sec_actvt = act_change.
      READ TABLE gt_mcusrgrp WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mcusrgrp WHERE sel = gc_select.
        PERFORM authority_check_mc_assign_grp
                USING act_change
                      gt_mcusrgrp-class
                      gt_mcusrgrp-contid
                      gt_mcusrgrp-conid
                      gt_mcusrgrp-vrsio.

        MOVE-CORRESPONDING gt_mcusrgrp TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '2'.                 "User group
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_maint_all  = 'X'
          if_show_class = 'X'
        TABLES
          it_mcuser     = lt_mcuser
          it_rfcdest    = lt_rfc
          it_sw_uinfo   = lt_uinfo.

      LOOP AT gt_mcusrgrp WHERE sel = gc_select.
        READ TABLE lt_mcuser WITH KEY contid = gt_mcusrgrp-contid
                                      conid  = gt_mcusrgrp-conid
                                      class  = gt_mcusrgrp-class
                                      vrsio  = gt_mcusrgrp-vrsio.
        IF sy-subrc = 0.
*         Record updated
          l_tabix = sy-tabix.
          gl_mcusrgrp = gt_mcusrgrp.
          gl_mcusrgrp-auditor   = lt_mcuser-auditor.
          gl_mcusrgrp-from_date = lt_mcuser-from_date.
          gl_mcusrgrp-to_date   = lt_mcuser-to_date.
          gl_mcusrgrp-approved  = lt_mcuser-approved.

          IF gl_mcusrgrp <> gt_mcusrgrp.
            MODIFY gt_mcusrgrp FROM gl_mcusrgrp
                   TRANSPORTING auditor from_date to_date approved.
          ENDIF.

          DELETE lt_mcuser INDEX l_tabix.
        ELSE.
          DELETE gt_mcusrgrp.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcuser.
*       Record inserted
        MOVE-CORRESPONDING lt_mcuser TO gt_mcusrgrp.
        APPEND gt_mcusrgrp.
        ADD 1 TO tc_mcusrgrp-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcusrgrp BY (ls_sort-name).
        ELSE.
          SORT gt_mcusrgrp BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcusrgrp BY class conid vrsio contid from_date.
      ENDIF.

    WHEN 'DELETE'.

      READ TABLE gt_mcusrgrp WITH KEY sel = gc_select.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.
      l_tabix = sy-tabix.
      PERFORM authority_check_mc_assign_grp
              USING act_delete gt_mcusrgrp-class gt_mcusrgrp-contid
                    gt_mcusrgrp-conid gt_mcusrgrp-vrsio.
      sec_actvt = act_delete.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-t02
          text_question         = text-q01
          text_button_1         = text-001
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = text-002
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = gf_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK gf_answer = '1'.

      LOOP AT gt_mcusrgrp WHERE sel = gc_select.
        ls_mchdr-contid = gt_mcusrgrp-contid.
        MOVE-CORRESPONDING gt_mcusrgrp TO lt_mcusrgrp.
        APPEND lt_mcusrgrp.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcusrgrp          = lt_mcusrgrp
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        CASE sy-subrc.
          WHEN 0.
            MESSAGE s117(/psyng/sw).  " Mitigation Deleted
          WHEN 1 OR 4.
            MESSAGE e122(/psyng/sw).  " Data Not Saved
          WHEN 2.
            MESSAGE e108(/psyng/sw) WITH text-134 /psyng/mchdr.
          WHEN 3.
            MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDCASE.
        MOVE-CORRESPONDING gt_mcusrgrp TO gs_assingment.
        DELETE gt_mcusrgrp.
        REFRESH lt_mcusrgrp.

*---odubey 08/06/2022 Delete justification as well
        gs_assingment-type = '2'.
        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment = 'X'
            if_delete     = 'X'
            i_mcid        = gt_mcusrgrp-contid
            is_assignment = gs_assingment
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             invalid_input   = 1
             not_implemented = 2
             gos_failure     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.

        CLEAR gs_assingment.
      ENDLOOP.

      CLEAR: gl_mcusrgrp, gf_edit.

    WHEN 'SEL_ALL'.
      gt_mcusrgrp-sel = 'X'.
      MODIFY gt_mcusrgrp TRANSPORTING sel WHERE sel = space.

    WHEN 'DSEL_ALL'.
      CLEAR gt_mcusrgrp-sel.
      MODIFY gt_mcusrgrp TRANSPORTING sel WHERE sel = 'X'.

    WHEN 'PICK'.
      DATA: l_lin           TYPE i,
            l_fieldname(30) TYPE c,
            l_uname         LIKE sy-uname,
            l_contid        TYPE /psyng/mchdr-contid,
            l_parva         TYPE usr05-parva,
            l_sod           TYPE /psyng/swsodvers-vrsio,
            l_dynnr         TYPE sy-dynnr.


      GET CURSOR FIELD l_fieldname LINE l_lin.
      l_lin = l_lin +  tc_mcusrgrp-top_line - 1.
      READ TABLE gt_mcusrgrp INDEX l_lin.
      IF l_fieldname = 'GT_MCUSRGRP-CONID'.
        l_objid = gt_mcusrgrp-conid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONID'
            i_objectid   = l_objid
            i_vrsio      = gt_mcusrgrp-vrsio.
      ENDIF.

      IF l_fieldname = 'GT_MCUSRGRP-CONTID'.
        l_objid = gt_mcusrgrp-contid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONTID'
            i_objectid   = l_objid
            i_vrsio      = gt_mcusrgrp-vrsio.
      ENDIF.

    WHEN 'CHANGES'.
      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH p_cont  = 'X'
             WITH p_class = 'X'
             AND RETURN.

    WHEN 'CURR_VER' OR 'ALL_VER' .
      DATA lt_mcusrgrp1 LIKE TABLE OF gt_mcusrgrp
                   WITH HEADER LINE.

**----> when click for current version
      IF ok_code = 'CURR_VER'.
        LOOP AT gt_mcusrgrp WHERE vrsio = g_sod_vrsio.
          MOVE-CORRESPONDING  gt_mcusrgrp TO lt_mcusrgrp1.
          APPEND lt_mcusrgrp1.
        ENDLOOP.

        REFRESH  gt_mcusrgrp.
        LOOP AT lt_mcusrgrp1.
          MOVE-CORRESPONDING lt_mcusrgrp1 TO gt_mcusrgrp.
          APPEND gt_mcusrgrp.
          CLEAR: lt_mcusrgrp1.
        ENDLOOP.
        MESSAGE s113(/psyng/sw) WITH text-a96.
      ENDIF.

*---->when no input in search screen
      IF ok_code = 'ALL_VER'.
        SELECT *  FROM /psyng/mcusrgrp
            INTO CORRESPONDING FIELDS OF TABLE gt_mcusrgrp.
*        DESCRIBE TABLE gt_mcusrgrp LINES tc_mcusrgrp-lines.
*        SORT gt_mcusrgrp BY class conid vrsio contid from_date.
        MESSAGE s113(/psyng/sw) WITH text-a95.
      ENDIF.

    WHEN 'SEARCH' OR 'FINDNEXT'.
      IF ok_code = 'SEARCH'.
        CLEAR: gl_mcuser, gl_mcusrgrp.
        g_call_scrn = '0222'.
        CALL SCREEN 905 STARTING AT 3 10.
        CHECK sy-ucomm = 'CONTINUE'.
        MOVE-CORRESPONDING gl_mcuser TO gl_mcusrgrp.
      ENDIF.

      IF gl_mcusrgrp-class IS INITIAL AND gl_mcusrgrp-conid IS INITIAL
      AND gl_mcusrgrp-contid IS INITIAL AND gl_mcusrgrp-auditor IS
      INITIAL AND gl_mcusrgrp-from_date IS INITIAL AND
      gl_mcusrgrp-to_date IS INITIAL.

        MESSAGE e106(/psyng/sw) WITH text-e01.
      ENDIF.

      LOOP AT gt_mcusrgrp WHERE sel = gc_select.
        CLEAR gt_mcusrgrp-sel.
        MODIFY gt_mcusrgrp INDEX sy-tabix.
        l_tabix = sy-tabix + 1.
      ENDLOOP.

      IF ok_code = 'SEARCH'.
        l_tabix = 1.
      ENDIF.

      LOOP AT gt_mcusrgrp FROM l_tabix.
        IF NOT gl_mcusrgrp-class IS INITIAL.
          CHECK gt_mcusrgrp-class = gl_mcusrgrp-class.
        ENDIF.
        IF NOT gl_mcusrgrp-conid IS INITIAL.
          CHECK gt_mcusrgrp-conid = gl_mcusrgrp-conid.
        ENDIF.
        IF NOT gl_mcusrgrp-vrsio IS INITIAL.
          CHECK gt_mcusrgrp-vrsio = gl_mcusrgrp-vrsio .
        ENDIF.
        IF NOT gl_mcusrgrp-contid IS INITIAL.
          CHECK gt_mcusrgrp-contid = gl_mcusrgrp-contid.
        ENDIF.
        IF NOT gl_mcusrgrp-auditor IS INITIAL.
          CHECK gt_mcusrgrp-auditor = gl_mcusrgrp-auditor.
        ENDIF.
        IF NOT gl_mcusrgrp-from_date IS INITIAL.
          CHECK gt_mcusrgrp-from_date = gl_mcusrgrp-from_date.
        ENDIF.
        IF NOT gl_mcusrgrp-to_date IS INITIAL.
          CHECK gt_mcusrgrp-to_date = gl_mcusrgrp-to_date.
        ENDIF.

        gt_mcusrgrp-sel = gc_select.
        MODIFY gt_mcusrgrp INDEX sy-tabix.
        tc_mcusrgrp-top_line = sy-tabix.
        EXIT.
      ENDLOOP.

      READ TABLE gt_mcusrgrp WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
      ENDIF.

      CLEAR gf_edit.

*   Transport table entries
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048
             VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tgasmt = gc_select
             WITH p_tvhead = gc_select
             AND RETURN.

    WHEN 'UPLD'.
*__________________________________________
*-----New upload download Functionality----
*__________________________________________

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
      AND RETURN.
*__________________________________________

    WHEN 'DWLD'.
      sec_actvt = act_download.
*DHO 20101202
      AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
         ID 'ACTVT'      FIELD sec_actvt
         ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
         ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc NE 0.
*       You are not authorizied to & & & &
        MESSAGE e108(/psyng/sw) WITH text-037.
      ENDIF.

      PERFORM get_filename USING text-t03
                           CHANGING l_filename.
      CHECK NOT l_filename IS INITIAL.


      l_file_mcusrgrp = l_filename.

*BOC:HBHALLA (096)
      AUTHORITY-CHECK OBJECT  'S_GUI'
                       ID      'ACTVT'
                       FIELD   '61'.
      IF sy-subrc = 0.
        CALL FUNCTION 'GUI_DOWNLOAD'             "#EC SAST_CI_GEN_CHECK
          EXPORTING
            filename                = l_file_mcusrgrp
            filetype                = 'ASC'
            write_field_separator   = 'X'
            dat_mode                = ' '
          TABLES
            data_tab                = gt_mcusrgrp
          EXCEPTIONS
            file_write_error        = 1
            no_batch                = 2
            gui_refuse_filetransfer = 3
            invalid_type            = 4
            no_authority            = 5
            unknown_error           = 6
            header_not_allowed      = 7
            separator_not_allowed   = 8
            filesize_not_allowed    = 9
            header_too_long         = 10
            dp_error_create         = 11
            dp_error_send           = 12
            dp_error_write          = 13
            unknown_dp_error        = 14
            access_denied           = 15
            dp_out_of_memory        = 16
            disk_full               = 17
            dp_timeout              = 18
            file_not_found          = 19
            dataprovider_exception  = 20
            control_flush_error     = 21
            OTHERS                  = 22.
        IF sy-subrc <> 0.
        PERFORM handle_download_error USING sy-subrc l_file_mcusrgrp ''.
        ENDIF.
      ENDIF.
*EOC:HBHALLA (096)

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
*DHO 20101202
        AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
           ID 'ACTVT'      FIELD act_change
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CLASS' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-038.
        ENDIF.

        sec_actvt = act_change.
        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
      ELSE.
*DHO 20101202
        AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
           ID 'ACTVT'      FIELD act_display
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CLASS' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-035.
        ENDIF.

        sec_actvt = act_display.
        gf_dispchg = gc_display.
        CLEAR gf_edit.
      ENDIF.

    WHEN 'SORTA' OR 'SORTD'.
      CLEAR ls_sort.

      LOOP AT tc_mcusrgrp-cols INTO ll_cols WHERE selected = 'X'.
        SPLIT ll_cols-screen-name AT '-' INTO l_table l_column.
        IF ok_code = 'SORTA'.
          SORT gt_mcusrgrp BY (l_column).
        ELSE.
          SORT gt_mcusrgrp BY (l_column) DESCENDING.
        ENDIF.

        ls_sort-name  = l_column.
        ls_sort-ucomm = ok_code.
      ENDLOOP.

    WHEN 'SHOW_DTL'.
      DATA: l_line        TYPE i,
            lt_mitdetails TYPE TABLE OF /psyng/mitigation_assignment
              WITH HEADER LINE,
            l_signoffid   TYPE /psyng/mcrvwsgn-signoffid.

      GET CURSOR LINE l_line.
      l_line = l_line + tc_mcusrgrp-top_line - 1.
      READ TABLE gt_mcusrgrp INDEX l_line.
      IF sy-subrc = 0.

        MOVE-CORRESPONDING gt_mcusrgrp TO lt_mitdetails.
        lt_mitdetails-type = '2'.
        APPEND lt_mitdetails.


        CALL FUNCTION '/PSYNG/SW_MIT_ASSIGN_DETAILS'
          EXPORTING
            i_contid      = gt_mcusrgrp-contid
            if_show_class = 'X'
            if_dispchg    = gf_dispchg
          TABLES
            it_mitdetails = lt_mitdetails.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8' OR
         'SODFUN_FC1' OR 'SODFUN_FC2' OR 'SODFUN_FC4' OR 'SODFUN_FC5' OR
         'MITCON_FC1'.

      CLEAR: gl_mcuser, gt_mcuser, gt_mcuser[], populated, i_text[],
             gf_edit.

      IF gf_dispchg = gc_change.
        IF g_sodfun-pressed_tab <> c_sodfun-tab4.
          SELECT SINGLE noedit INTO l_noedit FROM /psyng/swsodvers
                   WHERE vrsio = g_sod_vrsio.
          IF l_noedit = gc_select.
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ENDIF.

    WHEN 'FS'.
      g_fullscreen = '0222'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
  ENDCASE.
ENDFORM.                    " user_command_0222

*&---------------------------------------------------------------------*
*&      Form  user_command_0224
*&---------------------------------------------------------------------*
*       Handle user commands from screen 224
*----------------------------------------------------------------------*
FORM user_command_0224.
  DATA: ll_cols       TYPE cxtab_column,
        l_table(10)   TYPE c,
        l_column(10)  TYPE c,
        l_tabix       TYPE sy-tabix,
        l_filename    TYPE rlgrap-filename,
        lt_file1      LIKE gt_mcrole OCCURS 0 WITH HEADER LINE,
        l_file_mcrole TYPE string,
        ls_mit_assgn  TYPE /psyng/mitigation_assignment,
        ls_filename   TYPE string,
        ls_mchdr      TYPE /psyng/mchdr,
        lt_rfc        LIKE rfcdes OCCURS 0 WITH HEADER LINE,
        lt_mcrole     TYPE TABLE OF /psyng/mcrole WITH HEADER LINE,
        lt_mcuser     TYPE TABLE OF /psyng/mitigation_assignment
                      WITH HEADER LINE,
        lt_uinfo      TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
        l_noedit      TYPE /psyng/swsodvers-noedit,
        l_objid       TYPE slis_entry.

  STATICS: BEGIN OF ls_sort,
             name  LIKE screen-name,
             ucomm TYPE sy-ucomm,
           END OF ls_sort.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_mc_assign_role
            USING sec_actvt space space space 0.
  ENDIF.

  CASE ok_code.
*__________________________________________
*-----New upload download Functionality----

    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
                           WITH p_rlassn = 'X'
      AND RETURN.

      REFRESH gt_mcrole.
*__________________________________________

    WHEN 'QCUSER'.
      CALL FUNCTION '/PSYNG/SW_SOD_QUICK_CHECK_USER'
        EXPORTING
          vrsio = g_sod_vrsio.

    WHEN 'CREATE'.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
         ID 'ACTVT'      FIELD '01'
         ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'ACT_GROUP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        MESSAGE e108(/psyng/sw) WITH text-051
                'mitigation role assignments'(e28).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      lt_mcuser-rfcdest = lt_rfc-rfcoptions.
      lt_mcuser-type    = '4'.
      APPEND lt_mcuser.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert    = 'X'
          if_show_role = 'X'
        TABLES
          it_mcuser    = lt_mcuser
          it_rfcdest   = lt_rfc
          it_sw_uinfo  = lt_uinfo.

      LOOP AT lt_mcuser.
        READ TABLE gt_mcrole WITH KEY contid   = lt_mcuser-contid
                                      conid    = lt_mcuser-conid
                                      agr_name = lt_mcuser-agr_name
                                      vrsio    = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mcrole.
        gt_mcrole-conid = lt_mcuser-conid.
        APPEND gt_mcrole.
        ADD 1 TO tc_mcrole-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcrole BY (ls_sort-name).
        ELSE.
          SORT gt_mcrole BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcrole BY agr_name conid vrsio contid from_date.
      ENDIF.

    WHEN 'COPY'.
      sec_actvt = act_change.
      READ TABLE gt_mcrole WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mcrole WHERE sel = gc_select.
        PERFORM authority_check_mc_assign_role
                USING act_change
                      gt_mcrole-agr_name
                      gt_mcrole-contid
                      gt_mcrole-conid
                      gt_mcrole-vrsio.

        MOVE-CORRESPONDING gt_mcrole TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '4'.                 "Role
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert    = 'X'
          if_show_role = 'X'
        TABLES
          it_mcuser    = lt_mcuser
          it_rfcdest   = lt_rfc
          it_sw_uinfo  = lt_uinfo.
      LOOP AT lt_mcuser.
        READ TABLE gt_mcrole WITH KEY contid   = lt_mcuser-contid
                                      conid    = lt_mcuser-conid
                                      agr_name = lt_mcuser-agr_name
                                      vrsio    = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mcrole.
        gt_mcrole-conid = lt_mcuser-conid.
        APPEND gt_mcrole.
        ADD 1 TO tc_mcrole-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcrole BY (ls_sort-name).
        ELSE.
          SORT gt_mcrole BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcrole BY agr_name conid vrsio contid from_date.
      ENDIF.

    WHEN 'EDIT'.
      sec_actvt = act_change.
      READ TABLE gt_mcrole WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mcrole WHERE sel = gc_select.
        PERFORM authority_check_mc_assign_role
                USING act_change
                      gt_mcrole-agr_name
                      gt_mcrole-contid
                      gt_mcrole-conid
                      gt_mcrole-vrsio.

        MOVE-CORRESPONDING gt_mcrole TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '4'.                 "Role
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_maint_all = 'X'
          if_show_role = 'X'
        TABLES
          it_mcuser    = lt_mcuser
          it_rfcdest   = lt_rfc
          it_sw_uinfo  = lt_uinfo.

      LOOP AT gt_mcrole WHERE sel = gc_select.
        READ TABLE lt_mcuser WITH KEY contid   = gt_mcrole-contid
                                      conid    = gt_mcrole-conid
                                      agr_name = gt_mcrole-agr_name
                                      vrsio    = gt_mcrole-vrsio.
        IF sy-subrc = 0.
*         Record updated
          l_tabix = sy-tabix.
          gl_mcrole           = gt_mcrole.
          gl_mcrole-auditor   = lt_mcuser-auditor.
          gl_mcrole-from_date = lt_mcuser-from_date.
          gl_mcrole-to_date   = lt_mcuser-to_date.
          gl_mcrole-approved  = lt_mcuser-approved.

          IF gl_mcrole <> gt_mcrole.
            MODIFY gt_mcrole FROM gl_mcrole
                   TRANSPORTING auditor from_date to_date approved.
          ENDIF.

          DELETE lt_mcuser INDEX l_tabix.
        ELSE.
          DELETE gt_mcrole.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcuser.
*       Record inserted
        MOVE-CORRESPONDING lt_mcuser TO gt_mcrole.
        APPEND gt_mcrole.
        ADD 1 TO tc_mcrole-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mcrole BY (ls_sort-name).
        ELSE.
          SORT gt_mcrole BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mcrole BY agr_name conid vrsio contid from_date.
      ENDIF.

    WHEN 'DELETE'.
      READ TABLE gt_mcrole WITH KEY sel = gc_select.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      l_tabix = sy-tabix.
      PERFORM authority_check_mc_assign_role
              USING act_delete gt_mcrole-agr_name gt_mcrole-contid
                    gt_mcrole-conid gt_mcrole-vrsio.
      sec_actvt = act_delete.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-t02
          text_question         = text-q01
          text_button_1         = text-001
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = text-002
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = gf_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK gf_answer = '1'.

      LOOP AT gt_mcrole WHERE sel = gc_select.
        ls_mchdr-contid = gt_mcrole-contid.
        MOVE-CORRESPONDING gt_mcrole TO lt_mcrole.
        APPEND lt_mcrole.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcrole            = lt_mcrole
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.            "#EC SAST_CI_GEN_CHECK
        CASE sy-subrc.
          WHEN 0.
            MESSAGE s117(/psyng/sw).  " Mitigation Deleted
          WHEN 1 OR 4.
            MESSAGE e122(/psyng/sw).  " Data Not Saved
          WHEN 2.
            MESSAGE e108(/psyng/sw) WITH text-134 /psyng/mchdr.
          WHEN 3.
            MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDCASE.
        MOVE-CORRESPONDING gt_mcrole TO gs_assingment.
        DELETE gt_mcrole.
        REFRESH lt_mcrole.

*---odubey 08/06/2022 Delete justification as well
        gs_assingment-type = '4'.
        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment = 'X'
            if_delete     = 'X'
            i_mcid        = gt_mcrole-contid
            is_assignment = gs_assingment
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             invalid_input   = 1
             not_implemented = 2
             gos_failure     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.

        CLEAR gs_assingment.
      ENDLOOP.

      CLEAR: gl_mcrole, gf_edit.
    WHEN 'SEL_ALL'.
      gt_mcrole-sel = 'X'.
      MODIFY gt_mcrole TRANSPORTING sel WHERE sel = space.

    WHEN 'DSEL_ALL'.
      CLEAR gt_mcrole-sel.
      MODIFY gt_mcrole TRANSPORTING sel WHERE sel = 'X'.

    WHEN 'PICK'.

      DATA: l_lin           TYPE i,
            l_fieldname(30) TYPE c,
            l_uname         LIKE sy-uname,
            l_contid        TYPE /psyng/mchdr-contid,
            l_parva         TYPE usr05-parva,
            l_sod           TYPE /psyng/swsodvers-vrsio,
            l_dynnr         TYPE sy-dynnr.


      GET CURSOR FIELD l_fieldname LINE l_lin.
      l_lin = l_lin + tc_mcrole-top_line - 1.
      READ TABLE gt_mcrole INDEX l_lin.
      IF l_fieldname = 'GT_MCROLE-CONID'.
        l_objid = gt_mcrole-conid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONID'
            i_objectid   = l_objid
            i_vrsio      = gt_mcrole-vrsio.
      ENDIF.

      IF l_fieldname = 'GT_MCROLE-CONTID'.
        l_objid = gt_mcrole-contid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONTID'
            i_objectid   = l_objid
            i_vrsio      = gt_mcrole-vrsio.
      ENDIF.

    WHEN 'CHANGES'.
      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH p_cont = 'X'
             WITH p_role = 'X'
             AND RETURN.

    WHEN 'CURR_VER' OR 'ALL_VER' .
      DATA lt_mcrole1 LIKE TABLE OF gt_mcrole
                   WITH HEADER LINE.

**----> when click for current version
      IF ok_code = 'CURR_VER'.
        LOOP AT gt_mcrole WHERE vrsio = g_sod_vrsio.
          MOVE-CORRESPONDING  gt_mcrole TO lt_mcrole1.
          APPEND lt_mcrole1.
        ENDLOOP.

        REFRESH  gt_mcrole.
        LOOP AT lt_mcrole1.
          MOVE-CORRESPONDING lt_mcrole1 TO gt_mcrole.
          APPEND gt_mcrole.
          CLEAR: lt_mcrole1.
        ENDLOOP.
        MESSAGE s113(/psyng/sw) WITH text-a96.
      ENDIF.
**---->when click for all version filter
      IF ok_code = 'ALL_VER'.
        SELECT * FROM /psyng/mcrole
                     INTO CORRESPONDING FIELDS OF TABLE gt_mcrole.
*        DESCRIBE TABLE gt_mcrole LINES tc_mcrole-lines.
*        SORT gt_mcrole BY agr_name conid vrsio contid from_date.
        MESSAGE s113(/psyng/sw) WITH text-a95.
      ENDIF.

    WHEN 'SEARCH' OR 'FINDNEXT'.
      IF ok_code = 'SEARCH'.
        CLEAR: gl_mcuser, gl_mcrole.
        g_call_scrn = '0224'.
        CALL SCREEN 905 STARTING AT 3 10.
        CHECK sy-ucomm = 'CONTINUE'.
        MOVE-CORRESPONDING gl_mcuser TO gl_mcrole.
      ENDIF.

      IF gl_mcrole-agr_name IS INITIAL AND gl_mcrole-conid IS INITIAL
      AND gl_mcrole-contid IS INITIAL AND gl_mcrole-auditor IS
      INITIAL AND gl_mcrole-from_date IS INITIAL AND
      gl_mcrole-to_date IS INITIAL.

        MESSAGE e106(/psyng/sw) WITH text-e01.
      ENDIF.

      LOOP AT gt_mcrole WHERE sel = gc_select.
        CLEAR gt_mcrole-sel.
        MODIFY gt_mcrole INDEX sy-tabix.
        l_tabix = sy-tabix + 1.
      ENDLOOP.

      IF ok_code = 'SEARCH'.
        l_tabix = 1.
      ENDIF.

      LOOP AT gt_mcrole FROM l_tabix.
        IF NOT gl_mcrole-agr_name IS INITIAL.
          CHECK gt_mcrole-agr_name = gl_mcrole-agr_name.
        ENDIF.
        IF NOT gl_mcrole-conid IS INITIAL.
          CHECK gt_mcrole-conid = gl_mcrole-conid.
        ENDIF.
        IF NOT gl_mcrole-vrsio IS INITIAL.
          CHECK gt_mcrole-vrsio = gl_mcrole-vrsio .
        ENDIF.
        IF NOT gl_mcrole-contid IS INITIAL.
          CHECK gt_mcrole-contid = gl_mcrole-contid.
        ENDIF.
        IF NOT gl_mcrole-auditor IS INITIAL.
          CHECK gt_mcrole-auditor = gl_mcrole-auditor.
        ENDIF.
        IF NOT gl_mcrole-from_date IS INITIAL.
          CHECK gt_mcrole-from_date = gl_mcrole-from_date.
        ENDIF.
        IF NOT gl_mcrole-to_date IS INITIAL.
          CHECK gt_mcrole-to_date = gl_mcrole-to_date.
        ENDIF.

        gt_mcrole-sel = gc_select.
        MODIFY gt_mcrole INDEX sy-tabix.
        tc_mcusrgrp-top_line = sy-tabix.
        EXIT.
      ENDLOOP.

      READ TABLE gt_mcrole WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
      ENDIF.

      CLEAR gf_edit.

*   Transport table entries
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048
             VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tvhead = gc_select
             WITH p_trasmt = gc_select
             AND RETURN.

    WHEN 'UPLD'.

*__________________________________________
*-----New upload download Functionality----
*__________________________________________

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
      AND RETURN.

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        PERFORM authority_check_mc_assign_role
                USING act_change space space space space.

        sec_actvt = act_change.
        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
      ELSE.
        PERFORM authority_check_mc_assign_role
                USING act_display space space space space.

        sec_actvt = act_display.
        gf_dispchg = gc_display.
        CLEAR gf_edit.
      ENDIF.

    WHEN 'SORTA' OR 'SORTD'.
      CLEAR ls_sort.

      LOOP AT tc_mcrole-cols INTO ll_cols WHERE selected = 'X'.
        SPLIT ll_cols-screen-name AT '-' INTO l_table l_column.
        IF ok_code = 'SORTA'.
          SORT gt_mcrole BY (l_column).
        ELSE.
          SORT gt_mcrole BY (l_column) DESCENDING.
        ENDIF.

        ls_sort-name  = l_column.
        ls_sort-ucomm = ok_code.
      ENDLOOP.
    WHEN 'SHOW_DTL'.
      DATA: l_line        TYPE i,
            lt_mitdetails TYPE TABLE OF /psyng/mitigation_assignment
                    WITH HEADER LINE,
            l_signoffid   TYPE /psyng/mcrvwsgn-signoffid.

      GET CURSOR LINE l_line.
      l_line = l_line + tc_mcrole-top_line - 1.
      READ TABLE gt_mcrole INDEX l_line.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING gt_mcrole TO lt_mitdetails.
        lt_mitdetails-type = '4'.
        APPEND lt_mitdetails.


        CALL FUNCTION '/PSYNG/SW_MIT_ASSIGN_DETAILS'
          EXPORTING
            i_contid      = gt_mcrole-contid
            if_show_role  = 'X'
            if_dispchg    = gf_dispchg
          TABLES
            it_mitdetails = lt_mitdetails.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8' OR
         'SODFUN_FC1' OR 'SODFUN_FC2' OR 'SODFUN_FC4' OR 'SODFUN_FC5' OR
         'MITCON_FC1'.

      CLEAR: gl_mcrole, gt_mcrole, gt_mcrole[], populated, i_text[],
             gf_edit.

      IF gf_dispchg = gc_change.
        IF g_sodfun-pressed_tab <> c_sodfun-tab4.
          SELECT SINGLE noedit INTO l_noedit FROM /psyng/swsodvers
                   WHERE vrsio = g_sod_vrsio.
          IF l_noedit = gc_select.
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ENDIF.

    WHEN 'FS'.
      g_fullscreen = '0224'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
  ENDCASE.
ENDFORM.                    " user_command_0224

*&---------------------------------------------------------------------*
*&      Form  validate_mcuser
*&---------------------------------------------------------------------*
*       Validate mitigating control user ID table
*----------------------------------------------------------------------*
FORM validate_mcuser.
  DATA: l_approver TYPE /psyng/mchdr-approver.
  DATA : l_conid TYPE /psyng/mcuseraud-conid.                "mbindal+
  DATA : l_contid TYPE /psyng/mcuseraud-contid,             "MBINDAL+
         lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

* Enter all fields
  IF gl_mcuser-userid IS INITIAL OR gl_mcuser-conid IS INITIAL OR
  gl_mcuser-contid IS INITIAL OR gl_mcuser-from_date IS INITIAL OR
  gl_mcuser-to_date IS INITIAL.

    MESSAGE e106(/psyng/sw) WITH text-e02.
  ENDIF.

* Validate user ID
  SELECT SINGLE mandt INTO sy-mandt FROM usr02
                WHERE bname = gl_mcuser-userid.
  IF sy-subrc <> 0.
*    MESSAGE w124(01) WITH gl_mcuser-userid.
    MESSAGE w162(/psyng/sw) WITH gl_mcuser-userid.

  ENDIF.

* Validate conflict ID
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                WHERE conid = gl_mcuser-conid
                  AND vrsio = gl_mcuser-vrsio.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e03.
  ENDIF.

* Validate mitigating control ID
  SELECT SINGLE approver INTO l_approver FROM /psyng/mchdr
                WHERE contid = gl_mcuser-contid.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e04.
  ENDIF.

*  Check for the Control id corresponds to Conflict ID
  SELECT SINGLE contid FROM /psyng/conflict INTO l_contid
  WHERE contid = gl_mcuser-contid
  AND   conid  = gl_mcuser-conid
  AND   vrsio  = gl_mcuser-vrsio.
  IF sy-subrc <> 0.
*    AND gl_mcuser-conid <> l_conid.
    MESSAGE w124(/psyng/sw) WITH gl_mcuser-conid.
*   CONTINUE.
  ELSE.
    l_contid = /psyng/mcuseraud-contid.
    l_conid  = /psyng/mcuseraud-conid.
  ENDIF.

* Check that the user ID is not the same as the approver ID
  IF gl_mcuser-userid = l_approver.
    IF g_apr_same_usr_msg IS INITIAL.
      PERFORM get_apr_msgtyp CHANGING g_apr_same_usr_msg.
    ENDIF.

    MESSAGE ID '/PSYNG/SW' TYPE g_apr_same_usr_msg NUMBER '107'
                           WITH text-e07 text-e09 gl_mcuser-contid.
  ENDIF.

  IF NOT gl_mcuser-auditor IS INITIAL.
*   Check that user ID is not the same as the auditor ID
    IF gl_mcuser-userid = gl_mcuser-auditor.
      IF g_aud_same_usr_msg IS INITIAL.
        PERFORM get_aud_msgtyp CHANGING g_aud_same_usr_msg.
      ENDIF.

      MESSAGE ID '/PSYNG/SW' TYPE g_aud_same_usr_msg NUMBER '107'
                 WITH text-e07 text-e08.
    ENDIF.

*--Check if we need to validate the auditor
    IF gf_val_mit_aud IS INITIAL.
      PERFORM get_val_mit_aud.
    ENDIF.

    IF gf_val_mit_aud = 'Y'.
*--Get the company
      lt_uinfo-bname = gl_mcuser-userid.
      APPEND lt_uinfo.
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
        EXPORTING
          i_name_only  = 'X'
          i_mr_company = 'X'
        TABLES
          sw_uinfo     = lt_uinfo.

      READ TABLE lt_uinfo INDEX 1 TRANSPORTING company.

      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                    WHERE contid  = gl_mcuser-contid
                      AND auditor = gl_mcuser-auditor
                      AND ( company = lt_uinfo-company
                         OR company = space ).
      IF NOT sy-subrc = 0.
        MESSAGE e138(/psyng/sw) WITH gl_mcuser-auditor
                    'is not a valid auditor for mitigation'(e23)
                    gl_mcuser-contid.
      ENDIF.
    ENDIF.
  ELSE.
*   Check that at least one auditor is maintained for the
*   mitigating control ID
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                  WHERE contid = gl_mcuser-contid.
    IF sy-subrc <> 0.
      MESSAGE e106(/psyng/sw) WITH text-e08.
    ENDIF.
  ENDIF.

***Validating dates before updating database

*************************************************************
***Validation for proper Date format(YYYYMMDD)
*it cant allow other date formats


  IF NOT gl_mcuser-from_date IS INITIAL.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mcuser-from_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDIF.
***RKANAKA       changes 15-10-2011
*******************************************
  IF NOT gl_mcuser-to_date IS INITIAL.


    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mcuser-to_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
***RKANAKA       changes 15-10-2011

*************************************************************



** Validate dates
  IF gl_mcuser-from_date > gl_mcuser-to_date.
    MESSAGE e106(/psyng/sw) WITH text-e05.
  ENDIF.


* Check for duplicates
*--Only if we are inserting a new record
  CHECK sy-ucomm = 'INSERT'.           "#EC SAST_CI_GEN_CHECK (HBHALLA)
  READ TABLE gt_mcuser WITH KEY contid = gl_mcuser-contid
                                conid  = gl_mcuser-conid
                                userid = gl_mcuser-userid
                                vrsio  = gl_mcuser-vrsio
                                sel    = space
                       TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MESSAGE e101(/psyng/sw).
  ENDIF.
ENDFORM.                    " validate_mcuser

*&---------------------------------------------------------------------*
*&      Form  validate_mcusrgrp
*&---------------------------------------------------------------------*
*       Validate mitigating control user group table
*----------------------------------------------------------------------*
FORM validate_mcusrgrp.
  DATA: l_approver TYPE /psyng/mchdr-approver.
  DATA : l_conid TYPE /psyng/mcugrpaud-conid.                "mbindal +
  DATA : l_contid TYPE /psyng/mcugrpaud-contid.              "mbindal +

* Enter all fields
  IF gl_mcusrgrp-class IS INITIAL OR gl_mcusrgrp-conid IS INITIAL OR
  gl_mcusrgrp-contid IS INITIAL OR gl_mcusrgrp-from_date IS INITIAL OR
  gl_mcusrgrp-to_date IS INITIAL.

    MESSAGE e106(/psyng/sw) WITH text-e02.
  ENDIF.


* Validate user Group
  SELECT SINGLE mandt INTO sy-mandt FROM usgrp
                WHERE usergroup = gl_mcusrgrp-class.
  IF sy-subrc <> 0.
    MESSAGE e124(01) WITH gl_mcusrgrp-class.
  ENDIF.

* Validate conflict ID
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                WHERE conid = gl_mcusrgrp-conid
                  AND vrsio = gl_mcusrgrp-vrsio.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e03.
  ENDIF.

* Validate approver ID
  SELECT SINGLE approver INTO l_approver FROM /psyng/mchdr
                WHERE contid = gl_mcusrgrp-contid.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e04.
  ENDIF.

  IF NOT gl_mcusrgrp-auditor IS INITIAL.
*--Check if we need to validate the auditor
    IF gf_val_mit_aud IS INITIAL.
      PERFORM get_val_mit_aud.
    ENDIF.

    IF gf_val_mit_aud = 'Y'.
      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                    WHERE contid  = gl_mcusrgrp-contid
                      AND auditor = gl_mcusrgrp-auditor.
      IF NOT sy-subrc = 0.
        MESSAGE e138(/psyng/sw) WITH gl_mcusrgrp-auditor
                    'is not a valid auditor for mitigation'(e23)
                    gl_mcusrgrp-contid.
      ENDIF.
    ENDIF.
  ELSE.
*   Check that at least one auditor is maintained for the
*   mitigating control ID
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                  WHERE contid = gl_mcusrgrp-contid.
    IF sy-subrc <> 0.
      MESSAGE e106(/psyng/sw) WITH text-e08.
    ENDIF.
  ENDIF.

*************************************************************
***Validation for proper Date format(YYYYMMDD)
*it cant allow other date formats
  IF NOT gl_mcusrgrp-from_date IS INITIAL.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mcusrgrp-from_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.


  IF NOT gl_mcusrgrp-to_date IS INITIAL.


    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mcusrgrp-to_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
*** RKANAKA      changes 15-10-2011

*************************************************************

* Validate dates
  IF gl_mcusrgrp-from_date > gl_mcusrgrp-to_date.
    MESSAGE e106(/psyng/sw) WITH text-e05.
  ENDIF.

* Check for the Conflict ID corresponds to the Control ID
  SELECT SINGLE conid FROM /psyng/conflict INTO l_conid
                  WHERE contid = gl_mcusrgrp-contid
                  AND conid = gl_mcusrgrp-conid
                  AND vrsio = gl_mcusrgrp-vrsio.
  IF sy-subrc <> 0.
    MESSAGE w124(/psyng/sw) WITH gl_mcusrgrp-conid.
  ELSE.
    l_contid = gl_mcusrgrp-contid.
    l_conid = gl_mcusrgrp-conid.
  ENDIF.

* Check for duplicates
  READ TABLE gt_mcusrgrp WITH KEY contid = gl_mcusrgrp-contid
                                  conid  = gl_mcusrgrp-conid
                                  class  = gl_mcusrgrp-class
                                  vrsio  = gl_mcusrgrp-vrsio
                                  sel    = space
                         TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MESSAGE e101(/psyng/sw).
  ENDIF.
ENDFORM.                    " validate_mcusrgrp

*&---------------------------------------------------------------------*
*&      Form  validate_mcrole
*&---------------------------------------------------------------------*
*       Validate mitigating control role table
*----------------------------------------------------------------------*
FORM validate_mcrole.
  DATA: l_approver TYPE /psyng/mchdr-approver,
        l_conid    TYPE /psyng/mcuseraud-conid,
        l_contid   TYPE /psyng/mcuseraud-contid,
        lt_uinfo   TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

* Enter all fields
  IF gl_mcrole-agr_name IS INITIAL OR gl_mcrole-conid IS INITIAL OR
  gl_mcrole-contid IS INITIAL OR gl_mcrole-from_date IS INITIAL OR
  gl_mcrole-to_date IS INITIAL.

    MESSAGE e106(/psyng/sw) WITH text-e02.
  ENDIF.

* Validate role
  SELECT SINGLE mandt INTO sy-mandt FROM agr_define
                WHERE agr_name = gl_mcrole-agr_name.
  IF sy-subrc <> 0.
    MESSAGE w410(s#) WITH gl_mcrole-agr_name.
  ENDIF.

* Validate conflict ID
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                WHERE conid = gl_mcrole-conid
                  AND vrsio = gl_mcrole-vrsio.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e03.
  ENDIF.

* Validate mitigating control ID
  SELECT SINGLE approver INTO l_approver FROM /psyng/mchdr
                WHERE contid = gl_mcrole-contid.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e04.
  ENDIF.

*  Check for the Control id corresponds to Conflict ID
  SELECT SINGLE contid FROM /psyng/conflict INTO l_contid
          WHERE contid = gl_mcrole-contid
            AND conid  = gl_mcrole-conid
            AND vrsio  = gl_mcrole-vrsio.
  IF sy-subrc <> 0.
    MESSAGE w124(/psyng/sw) WITH gl_mcrole-conid.
  ENDIF.

  IF NOT gl_mcrole-auditor IS INITIAL.
*--Check if we need to validate the auditor
    IF gf_val_mit_aud IS INITIAL.
      PERFORM get_val_mit_aud.
    ENDIF.

    IF gf_val_mit_aud = 'Y'.
      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                    WHERE contid  = gl_mcrole-contid
                      AND auditor = gl_mcrole-auditor.
      IF NOT sy-subrc = 0.
        MESSAGE e138(/psyng/sw) WITH gl_mcrole-auditor
                    'is not a valid auditor for mitigation'(e23)
                    gl_mcusrgrp-contid.
      ENDIF.
    ENDIF.
  ELSE.
*   Check that at least one auditor is maintained for the
*   mitigating control ID
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                  WHERE contid = gl_mcrole-contid.
    IF sy-subrc <> 0.
      MESSAGE e106(/psyng/sw) WITH text-e08.
    ENDIF.
  ENDIF.

***Validating dates before updating database

*************************************************************
***Validation for proper Date format(YYYYMMDD)
*it cant allow other date formats


  IF NOT gl_mcrole-from_date IS INITIAL.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mcrole-from_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
***RKANAKA       changes 15-10-2011
*******************************************
  IF NOT gl_mcrole-to_date IS INITIAL.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mcrole-to_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.

      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
***RKANAKA       changes 15-10-2011

*************************************************************

** Validate dates
  IF gl_mcrole-from_date > gl_mcrole-to_date.
    MESSAGE e106(/psyng/sw) WITH text-e05.
  ENDIF.

* Check for duplicates
*--Only if we are inserting a new record
  CHECK sy-ucomm = 'INSERT'.           "#EC SAST_CI_GEN_CHECK (HBHALLA)
  READ TABLE gt_mcrole WITH KEY contid   = gl_mcrole-contid
                                conid    = gl_mcrole-conid
                                agr_name = gl_mcrole-agr_name
                                vrsio    = gl_mcrole-vrsio
                                sel      = space
                       TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MESSAGE e101(/psyng/sw).
  ENDIF.
ENDFORM.                    " validate_mcrole

*&---------------------------------------------------------------------*
*&      Form  user_command_0301
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_command_0301.
  DATA: BEGIN OF lt_posid OCCURS 0,
          positionid TYPE /psyng/posndet-positionid,
        END OF lt_posid.

  DATA: l_long_ques(200) TYPE c.

  STATICS: lt_hdrtxt  LIKE TABLE OF i_text WITH HEADER LINE,
           lt_desctxt LIKE TABLE OF i_text WITH HEADER LINE.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_roleid
            USING sec_actvt /psyng/roletrans-roleid.
  ENDIF.

* Unlock previous role ID
  IF /psyng/rolehdr-roleid <> /psyng/roletrans-roleid.
    CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
      EXPORTING
        roleid = /psyng/rolehdr-roleid.
    CLEAR first_time.
  ENDIF.

  crt_dte = sy-datum.
  crt_tme = sy-uzeit.
  populated = 'X'.

*  IF g_rolehdr-pressed_tab = 'ROLEHDR_FC1'.
  CONCATENATE /psyng/roletrans-roleid 'HDR' INTO role_txt.
*  ENDIF.
*  IF g_rolehdr-pressed_tab = 'ROLEHDR_FC2'.
  CONCATENATE /psyng/roletrans-roleid 'DESC' INTO role_txt1.
*  ENDIF.
*
  CASE ok_code.
    WHEN 'D_PFCG'.    "Display role in PFCG

      PERFORM display_role_in_pfcg USING /psyng/rolehdr-saptechname.

    WHEN 'COPY'.
      CHECK NOT /psyng/roletrans-roleid IS INITIAL.
      PERFORM copy_role_id.
    WHEN 'ENTER'.
      PERFORM load_role.
    WHEN 'CHANGES'.
      SUBMIT /psyng/rlehdrhist VIA SELECTION-SCREEN
      AND RETURN.

    WHEN 'SYNCPOS'.
      SELECT SINGLE * FROM /psyng/rolehdr INTO /psyng/rolehdr
      WHERE roleid = /psyng/roletrans-roleid.
      IF sy-subrc = 0.
        /psyng/position-positionid = /psyng/rolehdr-roleid.
        /psyng/position-description = /psyng/rolehdr-description.
        /psyng/position-saptechname = /psyng/rolehdr-saptechname.
        /psyng/position-create_usr = g_current_user. "sy-uname. C0700
        /psyng/position-create_dat = sy-datum.
        /psyng/position-create_tim = sy-uzeit.
        INSERT /psyng/position.
        /psyng/posndet-positionid = /psyng/rolehdr-roleid.
        /psyng/posndet-roleid = /psyng/rolehdr-roleid.
        INSERT /psyng/posndet.
        IF sy-subrc <> 0.
          MESSAGE e115(/psyng/sw).
        ELSE.
          MESSAGE i114(/psyng/sw).
        ENDIF.
      ELSE.

*        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

        CONCATENATE text-012 /psyng/roletrans-roleid text-301
                    INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
        CLEAR messagetext.

      ENDIF.

    WHEN 'SAVE'.

      IF /psyng/roletrans-roleid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-012.
      ENDIF.

      PERFORM authority_check_roleid
              USING act_change /psyng/roletrans-roleid.

      sec_actvt = act_change.
      first_time = space.

      SELECT SINGLE * FROM /psyng/rolehdr INTO old_role
      WHERE roleid = /psyng/roletrans-roleid.

      IF sy-subrc <> 0 AND /psyng/roletrans-roleid > space.
*       Insert new role
        /psyng/rolehdr-create_usr = g_current_user."sy-uname. C0700
        /psyng/rolehdr-create_dat = sy-datum.
        /psyng/rolehdr-create_tim = sy-uzeit.
        /psyng/rolehdr-change_usr = g_current_user. "sy-uname. C0700
        /psyng/rolehdr-change_dat = sy-datum.
        /psyng/rolehdr-change_tim = sy-uzeit.
        /psyng/rolehdr-roleid = /psyng/roletrans-roleid.
        INSERT /psyng/rolehdr.
        IF sy-subrc <> 0.
          MESSAGE e122(/psyng/sw).
          EXIT.
        ELSE.
          MESSAGE s120(/psyng/sw).  " Data Saved
        ENDIF.

*       Populate History
        PERFORM populate_history USING '/PSYNG/ROLEHDR' 'ROLEID' space
                /psyng/roletrans-roleid space 'I'.
        PERFORM populate_history USING '/PSYNG/ROLEHDR'
                /psyng/roletrans-roleid 'IMPORTANCE'
                /psyng/rolehdr-importance space 'I'.
        PERFORM populate_history USING '/PSYNG/ROLEHDR'
                /psyng/roletrans-roleid 'APPROVAL'
                /psyng/rolehdr-approval space 'I'.
        PERFORM populate_history USING '/PSYNG/ROLEHDR'
                /psyng/roletrans-roleid 'MODULE'
                /psyng/rolehdr-rolemodule space 'I'.
        PERFORM populate_history USING '/PSYNG/ROLEHDR'
                /psyng/roletrans-roleid 'SAPTECHNAME'
                /psyng/rolehdr-saptechname space 'I'.
        PERFORM populate_history USING '/PSYNG/ROLEHDR'
                /psyng/roletrans-roleid 'OWNER' /psyng/rolehdr-owner
                space 'I'.
*       End History
      ELSE.
*       Update existing role
        roleid = old_role-roleid.
        /psyng/rolehdr-change_usr = g_current_user. "sy-uname. C0700
        /psyng/rolehdr-change_dat = sy-datum.
        /psyng/rolehdr-change_tim = sy-uzeit.
        UPDATE /psyng/rolehdr.
        IF sy-subrc <> 0.
          MESSAGE w122(/psyng/sw).  " Data Not Saved
        ELSE.
          MESSAGE s120(/psyng/sw).  " Data Saved
        ENDIF.

*       Populate History
        PERFORM populate_history USING '/PSYNG/ROLEHDR' 'ROLEID' space
                /psyng/roletrans-roleid space 'U'.

        IF old_role-importance <> /psyng/rolehdr-importance.
          PERFORM populate_history USING '/PSYNG/ROLEHDR'
                  /psyng/roletrans-roleid 'IMPORTANCE'
                  old_role-importance /psyng/rolehdr-importance 'U'.
        ENDIF.

        IF old_role-approval <> /psyng/rolehdr-approval.
          PERFORM populate_history USING '/PSYNG/ROLEHDR'
                  /psyng/roletrans-roleid 'APPROVAL' old_role-approval
                  /psyng/rolehdr-approval 'U'.
        ENDIF.

        IF old_role-rolemodule <> /psyng/rolehdr-rolemodule.
          PERFORM populate_history USING '/PSYNG/ROLEHDR'
                  /psyng/roletrans-roleid 'MODULE' old_role-rolemodule
                  /psyng/rolehdr-rolemodule 'U'.
        ENDIF.

        IF old_role-saptechname <> /psyng/rolehdr-saptechname.
          PERFORM populate_history USING '/PSYNG/ROLEHDR'
                  /psyng/roletrans-roleid 'SAPTECHNAME'
                  old_role-saptechname /psyng/rolehdr-saptechname 'U'.
        ENDIF.

        IF old_role-owner <> /psyng/rolehdr-owner.
          PERFORM populate_history USING '/PSYNG/ROLEHDR'
                  /psyng/roletrans-roleid 'OWNER' old_role-owner
                  /psyng/rolehdr-owner 'U'.
        ENDIF.
*     End History
      ENDIF.

*     Text
*      PERFORM get_editor_text.
      IF g_rolehdr-pressed_tab = c_rolehdr-tab1.
        DELETE FROM /psyng/texts WHERE textname = role_txt
                                   AND object   = 'R'
                                   AND spras    = sy-langu.

        /psyng/texts-textname = role_txt.
        /psyng/texts-object   = 'R'.
        /psyng/texts-spras    = sy-langu.
*      LOOP AT gt_hdrtxt.
*        /psyng/texts-line = sy-tabix.
*        /psyng/texts-text = gt_hdrtxt-text.
*        CLEAR /psyng/texts-vrsio.
*        INSERT /psyng/texts.
*      ENDLOOP.
*      IF sy-subrc NE 0.
        LOOP AT i_text.
          /psyng/texts-line = sy-tabix.
          /psyng/texts-text = i_text-text.
          CLEAR /psyng/texts-vrsio.
          INSERT /psyng/texts.
        ENDLOOP.
*      ENDIF.
      ENDIF.

      IF g_rolehdr-pressed_tab = c_rolehdr-tab2.
        DELETE FROM /psyng/texts WHERE textname = role_txt1
                                  AND object   = 'R'
                                  AND spras    = sy-langu.

        /psyng/texts-textname = role_txt1.
        /psyng/texts-object   = 'R'.
        /psyng/texts-spras    = sy-langu.
*      LOOP AT gt_desctxt.
*        /psyng/texts-line = sy-tabix.
*        /psyng/texts-text = gt_desctxt-text.
*        CLEAR /psyng/texts-vrsio.
*        INSERT /psyng/texts.
*      ENDLOOP.
*      IF sy-subrc NE 0.
        LOOP AT i_text.
          /psyng/texts-line = sy-tabix.
          /psyng/texts-text = i_text-text.
          CLEAR /psyng/texts-vrsio.
          INSERT /psyng/texts.
        ENDLOOP.
*      ENDIF.
      ENDIF.


      CLEAR gf_data_change.

    WHEN 'DELETE'.

      PERFORM authority_check_roleid
              USING act_delete /psyng/roletrans-roleid.
      sec_actvt = act_delete.
*     Check if role is tied to any positions
      SELECT positionid INTO TABLE lt_posid FROM /psyng/posndet
             WHERE roleid = /psyng/roletrans-roleid.

      IF NOT lt_posid[] IS INITIAL.

        LOOP AT lt_posid.
          CONCATENATE l_long_ques lt_posid-positionid
                      INTO l_long_ques SEPARATED BY space.
        ENDLOOP.

        CONCATENATE text-164 l_long_ques '.' text-q01 text-165
                    INTO l_long_ques SEPARATED BY space.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = text-027
            text_question         = l_long_ques
            text_button_1         = text-123
            icon_button_1         = 'ICON_DELETE'
            text_button_2         = text-124
            icon_button_2         = 'ICON_SYSTEM_CANCEL'
            default_button        = '2'
            display_cancel_button = ' '
          IMPORTING
            answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
        CHECK popup_answer = '1'.
      ENDIF.

      CONCATENATE text-039 /psyng/roletrans-roleid
                  INTO popup_question SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = popup_question
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

*     Delete from positions if necessary
      LOOP AT lt_posid.
        DELETE FROM /psyng/posndet                  "#EC CI_IMUD_NESTED
                    WHERE positionid = lt_posid-positionid
                      AND roleid     = /psyng/roletrans-roleid.
      ENDLOOP.

      CONCATENATE /psyng/roletrans-roleid 'HDR'
                  INTO /psyng/texts-textname.
      DELETE FROM /psyng/texts WHERE textname = /psyng/texts-textname
                               AND   object   = 'R'.
      CONCATENATE /psyng/roletrans-roleid 'DESC'
                  INTO /psyng/texts-textname.
      DELETE FROM /psyng/texts WHERE textname = /psyng/texts-textname
                               AND   object   = 'R'.
      DELETE FROM /psyng/rolehdr WHERE roleid = /psyng/roletrans-roleid.
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

        CONCATENATE text-012 /psyng/roletrans-roleid text-301
                    INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
        CLEAR messagetext.
      ELSE.
        CONCATENATE text-012 /psyng/roletrans-roleid text-126
                    INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
      ENDIF.
     DELETE FROM /psyng/roletrans WHERE roleid = /psyng/roletrans-roleid
                                                                       .
*     Populate History
      PERFORM populate_history USING '/PSYNG/ROLEHDR' 'ROLEID' space
              /psyng/roletrans-roleid space 'D'.
      PERFORM populate_history USING /psyng/roletrans-roleid
              /psyng/roletrans-roleid 'IMPORTANCE'
              /psyng/rolehdr-importance space 'D'.
      PERFORM populate_history USING '/PSYNG/ROLEHDR'
              /psyng/roletrans-roleid 'APPROVAL' /psyng/rolehdr-approval
              space 'D'.
      PERFORM populate_history USING '/PSYNG/ROLEHDR'
              /psyng/roletrans-roleid 'MODULE' /psyng/rolehdr-rolemodule
              space 'D'.
      PERFORM populate_history USING '/PSYNG/ROLEHDR'
              /psyng/roletrans-roleid 'SAPTECHNAME'
              /psyng/rolehdr-saptechname space 'D'.
      PERFORM populate_history USING '/PSYNG/ROLEHDR'
              /psyng/roletrans-roleid 'OWNER' /psyng/rolehdr-owner
              space 'D'.
*     End History

*     Unlock role ID
      CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
        EXPORTING
          roleid = /psyng/roletrans-roleid.

      CLEAR gf_data_change.
      REFRESH i_text.
      CLEAR /psyng/rolehdr.
      CLEAR /psyng/roletrans.
      CLEAR first_time.


    WHEN 'CREATE'.
      PERFORM authority_check_roleid
              USING act_create /psyng/rolehdr-roleid.
      sec_actvt = act_create.
      PERFORM exit_without_save.
      CHECK gf_answer = '1'.

      IF NOT /psyng/rolehdr-roleid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
          EXPORTING
            roleid = /psyng/roletrans-roleid.
      ENDIF.

      REFRESH : i_text,gt_hdrtxt,gt_desctxt.
      CLEAR: /psyng/rolehdr, /psyng/roletrans,

             gf_data_change.

    WHEN 'RLESOD'.
      CALL SCREEN '0901'.
      EXIT.

    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.

        PERFORM authority_check_roleid
                USING act_change /psyng/roletrans-roleid.
        sec_actvt = act_change.

        gf_dispchg = gc_change.

        IF NOT /psyng/roletrans-roleid IS INITIAL.
*         Lock role ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/ROLEHDR'
            EXPORTING
              roleid         = /psyng/roletrans-roleid
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM authority_check_roleid
                USING act_display /psyng/roletrans-roleid.
        sec_actvt = act_display.
        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.
        ok_code = 'ENTER'.
        PERFORM user_command_0301.

        gf_dispchg = gc_display.

*       Unlock role ID
        IF NOT /psyng/roletrans-roleid IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
            EXPORTING
              roleid = /psyng/roletrans-roleid.
        ENDIF.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save_new.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          CLEAR g_roles-pressed_tab.
          EXIT.
        ENDIF.
      ENDIF.

*     Unlock role ID
      IF NOT /psyng/roletrans-roleid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
          EXPORTING
            roleid = /psyng/roletrans-roleid.
      ENDIF.
      CLEAR first_time.

      IF ok_code <> 'YX_SECTAB_FC3'.

        CLEAR: gf_data_change, /psyng/roletrans,
               /psyng/rolehdr, i_text[], populated.
      ENDIF.
      CLEAR sec_actvt.
*    WHEN 'COPY'.
*      CHECK NOT /psyng/rolehdr-roleid IS INITIAL.
*      PERFORM copy_role_id.
    WHEN 'AROL'.
      IF /psyng/rolehdr-saptechname IS INITIAL.
        SET CURSOR FIELD /psyng/rolehdr-saptechname.
        MESSAGE w208(00) WITH text-041.
        EXIT.
      ENDIF.

      CHECK NOT /psyng/roletrans-roleid IS INITIAL.
      REFRESH: itcodes.  CLEAR: itcodes.
      SELECT tcode FROM /psyng/roletrans INTO itcodes-tcode
             WHERE roleid = /psyng/roletrans-roleid.
        APPEND itcodes.
      ENDSELECT.

      MOVE text-042 TO popup_question.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-043
*         DIAGNOSE_OBJECT       = '/PSYNG/SW'
          text_question         = popup_question
          text_button_1         = text-131
          icon_button_1         = 'ICON_REPLACE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF popup_answer = '1'.
        PERFORM replace_tcodes_of_pfcg_role.
        PERFORM popup_changed_role USING text-045.
      ELSE.
        MESSAGE i208(00) WITH text-044.
      ENDIF.

    WHEN 'GROL'.
      IF /psyng/rolehdr-saptechname IS INITIAL.
        SET CURSOR FIELD /psyng/rolehdr-saptechname.
        MESSAGE w208(00) WITH text-041.
        EXIT.
      ENDIF.

      CHECK NOT /psyng/rolehdr-roleid IS INITIAL.

      PERFORM generate_pfcg_role.

    WHEN 'IMPORT'.
      SUBMIT /psyng/sw_020 VIA SELECTION-SCREEN AND RETURN.
    WHEN 'FS'.
      g_fullscreen = '0301'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

    WHEN 'ROLEHDR_FC1'.
      CONCATENATE /psyng/roletrans-roleid 'HDR' INTO role_txt.
*
*      lt_desctxt[] = i_text[].
*
*      IF lt_hdrtxt[] IS INITIAL.
*        REFRESH lt_hdrtxt.
*        SELECT * FROM /psyng/texts WHERE textname = role_txt
*                                     AND object   = 'R'
*                                     AND spras    = sy-langu
*                                     AND vrsio    = '000'.
*          lt_hdrtxt-text = /psyng/texts-text.
*          APPEND lt_hdrtxt.
*        ENDSELECT.
*      ENDIF.
      IF NOT i_text[] IS INITIAL.
        REFRESH gt_desctxt.
        LOOP AT i_text.
          gt_desctxt-text = i_text.
          APPEND gt_desctxt.
        ENDLOOP.
      ENDIF.
      REFRESH i_text[].
      LOOP AT gt_hdrtxt.
        i_text = gt_hdrtxt-text.
        APPEND i_text.
      ENDLOOP.

*      DELETE ADJACENT DUPLICATES FROM i_text.


      first_time = 'X'.

    WHEN 'ROLEHDR_FC2'.
      CONCATENATE /psyng/roletrans-roleid 'DESC' INTO role_txt.

*      lt_hdrtxt[] = i_text[].
*
*      IF lt_desctxt[] IS INITIAL.
*        REFRESH lt_desctxt.
*        SELECT * FROM /psyng/texts WHERE textname = role_txt
*                                     AND object   = 'R'
*                                     AND spras    = sy-langu
*                                     AND vrsio    = '000'.
*          lt_desctxt-text = /psyng/texts-text.
*          APPEND lt_desctxt.
*        ENDSELECT.
*      ENDIF.
*
*      i_text[] = lt_desctxt[].
      IF NOT i_text[] IS INITIAL.
        REFRESH gt_hdrtxt.
        LOOP AT i_text.
          gt_hdrtxt-text = i_text.
          APPEND gt_hdrtxt.
        ENDLOOP.
      ENDIF.

      REFRESH i_text[].
      LOOP AT gt_desctxt.
        i_text = gt_desctxt-text.
        APPEND i_text.
      ENDLOOP.

*      DELETE ADJACENT DUPLICATES FROM i_text.
      first_time = 'X'.


    WHEN OTHERS.
      first_time = space.
      REFRESH g_role_trans_itab.
      REFRESH conflict.
      REFRESH conflict2.

  ENDCASE.
ENDFORM.                    " user_command_0301

*&---------------------------------------------------------------------*
*&      Form  user_command_0302
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_command_0302.
  DATA: success VALUE 'Y'.
  DATA : lt_param TYPE TABLE OF rsparams WITH HEADER LINE,
         lt_roles TYPE TABLE OF t_role,
         ls_roles TYPE t_role.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.
  PERFORM authority_check_roleid
          USING sec_actvt /psyng/rolehdr-roleid.

* Unlock previous role ID
  IF /psyng/rolehdr-roleid <> /psyng/roletrans-roleid.
    CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
      EXPORTING
        roleid = /psyng/rolehdr-roleid.
  ENDIF.



  crt_dte = sy-datum.
  crt_tme = sy-uzeit.
  populated = 'X'.
  CLEAR sod_conflict.

  CASE ok_code.
    WHEN 'CONDISP'.
      PERFORM populate_conflict2.
      PERFORM display_conflict.

    WHEN 'SYNCH'.
      REFRESH lt_param[].
      lt_param-selname = 'PROLES'.
      lt_param-sign    = 'I'.
      lt_param-low     = /psyng/roletrans-roleid.
      APPEND lt_param.
      lt_param-selname = 'ROLES'.
      lt_param-sign    = 'I'.
      lt_param-low     = 'X'.
      APPEND lt_param.
      lt_param-selname = 'POSIT'.
      lt_param-sign    = 'I'.
      lt_param-low     = space.
      APPEND lt_param.
      lt_param-selname = 'USER'.
      lt_param-sign    = 'I'.
      lt_param-low     = space.
      APPEND lt_param.
      SUBMIT /psyng/weavsync WITH SELECTION-TABLE lt_param AND RETURN.

    WHEN 'REFRESH'.
      first_time = space.
      old_trans_current_line = 0.
      REFRESH g_role_trans_itab.
      REFRESH conflict.
      CLEAR: funct1, conid.

    WHEN 'CHANGES'.
      SUBMIT /psyng/roletxnhist VIA SELECTION-SCREEN AND RETURN.

    WHEN 'DELALL'.
      count_line = 0.

      READ TABLE g_role_trans_itab WITH KEY flag = 'X'.

      IF sy-subrc NE '0'.
        MESSAGE e168(/psyng/sw).
      ENDIF.


      LOOP AT g_role_trans_itab WHERE flag = 'X'.
        count_line = count_line + 1.
      ENDLOOP.
      DELETE g_role_trans_itab WHERE flag = 'X'.

      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ELSE.
        DESCRIBE TABLE g_role_trans_itab LINES role_trans-lines.
      ENDIF.


      old_trans_current_line = old_trans_current_line - count_line.

    WHEN 'INSR'.                       "Insert lines
*      ADD 20 TO role_trans-lines.
*      IF /psyng/roletrans-roleid IS INITIAL.
*        MESSAGE e106(/psyng/sw) WITH text-012.
*      ENDIF.
      DESCRIBE TABLE g_role_trans_itab LINES
                                   role_trans-lines.

     PERFORM insert_row_into_tc USING  'ROLE_TRANS' 'G_ROLE_TRANS_ITAB'.

    WHEN 'MITCNTRL'.                   "#EC SAST_CI_GEN_CHECK (HBHALLA)
      READ TABLE conflict INDEX  cursor_line.
      /psyng/conflict-conid = conflict-conid.
      CLEAR first_mit.
      CALL SCREEN '206'.
      EXIT.
    WHEN 'SODCON'.

      PERFORM obj_check.
      sod_conflict = 'X'.
      CLEAR /psyng/rolehdr.
      CLEAR cursor_field.
      CLEAR cursor_line.
      SELECT SINGLE * FROM /psyng/rolehdr
      WHERE roleid = /psyng/roletrans-roleid.

      CHECK NOT /psyng/rolehdr-saptechname IS INITIAL.
      ls_roles-sign = 'I'.
      ls_roles-option = 'EQ'.
      ls_roles-low = /psyng/rolehdr-saptechname.
      APPEND ls_roles TO lt_roles.

      SUBMIT /psyng/sodreport_org
             WITH byrole = 'X'
             WITH byuser = ' '
             WITH role IN lt_roles
             WITH sodvrsio = g_sod_vrsio
*Sf Case 2282
             WITH comprol = 'X'
             WITH singrol = 'X'
             AND RETURN.
*      IF /psyng/rolehdr-saptechname > space.
*        PERFORM populate_sod_conflict.
*      ELSE.
*        MESSAGE w104(/psyng/sw).
*      ENDIF.
    WHEN 'ENTER'.
      IF first_time = space.
        IF itstct[] IS INITIAL.
          SELECT * FROM tstct INTO CORRESPONDING FIELDS OF TABLE itstct
                   WHERE sprsl = sy-langu.
        ENDIF.
        first_time = 'X'.
        IF /psyng/roletrans-roleid <> space.
          CLEAR: /psyng/rolehdr, g_role_trans_itab[].

          SELECT SINGLE * FROM /psyng/rolehdr
          WHERE roleid = /psyng/roletrans-roleid.

          CHECK sy-subrc = 0.

          SELECT * FROM /psyng/roletrans
          WHERE roleid = /psyng/roletrans-roleid.

            g_role_trans_itab-tcode = /psyng/roletrans-tcode.
            CLEAR itstct.
            READ TABLE itstct WITH TABLE KEY sprsl = sy-langu
                                        tcode = g_role_trans_itab-tcode.
            g_role_trans_itab-ttext = itstct-ttext.
            g_role_trans_itab-flag  = space.
            APPEND g_role_trans_itab.
          ENDSELECT.

          DESCRIBE TABLE g_role_trans_itab LINES role_trans-lines.
          role_trans-top_line = 1.

          IF gf_dispchg = gc_change.
            CALL FUNCTION 'ENQUEUE_/PSYNG/ROLEHDR'
              EXPORTING
                roleid         = /psyng/rolehdr-roleid
              EXCEPTIONS
                foreign_lock   = 1
                system_failure = 2
                OTHERS         = 3.
            IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
          ENDIF.
        ENDIF.
        DESCRIBE TABLE g_role_trans_itab LINES old_n.
      ENDIF.
* Logic for Populating Conflicts
      DESCRIBE TABLE g_role_trans_itab LINES new_n.
      PERFORM populate_conflict.


    WHEN 'DELETE'.

      PERFORM authority_check_roleid
              USING act_delete /psyng/rolehdr-roleid.
      sec_actvt = act_delete.

      PERFORM populate_history USING '/PSYNG/ROLEHDR' 'RLETXN' space
              /psyng/roletrans-roleid space 'D'.
*     Populate History
      SELECT * FROM /psyng/roletrans
      WHERE roleid = /psyng/roletrans-roleid.
        PERFORM populate_history USING '/PSYNG/ROLETRANS'
                /psyng/roletrans-roleid 'TCODE' /psyng/roletrans-tcode
                space 'D'.
      ENDSELECT.
*     End History

      DELETE FROM /psyng/roletrans
      WHERE roleid = /psyng/roletrans-roleid.
      IF sy-subrc = 0.
        REFRESH g_role_trans_itab.
        CLEAR g_role_trans_itab.
      ENDIF.

    WHEN 'SAVE'.
      IF /psyng/rolehdr-roleid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-012.
      ENDIF.

      PERFORM authority_check_roleid
              USING act_change /psyng/rolehdr-roleid.
      sec_actvt = act_change.
*     Populate History
      PERFORM populate_history USING '/PSYNG/ROLEHDR' 'RLETXN' space
              /psyng/roletrans-roleid space 'U'.
      SELECT * FROM /psyng/roletrans
      WHERE roleid = /psyng/roletrans-roleid.

        READ TABLE g_role_trans_itab WITH KEY tcode =
        /psyng/roletrans-tcode.
        IF sy-subrc <> 0.
          PERFORM populate_history USING '/PSYNG/ROLETRANS'
                  /psyng/roletrans-roleid 'TCODE'
                  g_role_trans_itab-tcode space 'D'.
        ENDIF.
      ENDSELECT.
      LOOP AT g_role_trans_itab.
        SELECT SINGLE * FROM /psyng/roletrans        "#EC CI_SEL_NESTED
        WHERE roleid = /psyng/roletrans-roleid
        AND   tcode  = g_role_trans_itab-tcode.
        IF sy-subrc <> 0.
          PERFORM populate_history USING '/PSYNG/ROLETRANS'
                  /psyng/roletrans-roleid 'TCODE'
                  g_role_trans_itab-tcode space 'I'.
        ENDIF.
      ENDLOOP.
* End History

      DELETE FROM /psyng/roletrans
      WHERE roleid = /psyng/roletrans-roleid.

      LOOP AT g_role_trans_itab.
        IF g_role_trans_itab-tcode <> space.
          /psyng/roletrans-tcode      = g_role_trans_itab-tcode.
          /psyng/roletrans-change_usr = g_current_user. "sy-uname. C0700
          INSERT /psyng/roletrans.
          IF sy-subrc NE 0.
            success = 'N'.
          ENDIF.
        ENDIF.
      ENDLOOP.

***   SE 3.1 DEVELOPEMNT ITEM C43 Code by Shekhar 17/10/2013
***   ITEM C43D Start fix

      DELETE g_role_trans_itab WHERE tcode = space.
      DESCRIBE TABLE g_role_trans_itab LINES role_trans-lines.
***   ENDFIX.

      IF success = 'Y'.
        MESSAGE s120(/psyng/sw).  " Data Saved
      ELSE.
        MESSAGE w122(/psyng/sw).  " Data Not Saved
      ENDIF.

      CLEAR gf_data_change.

    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.

        PERFORM authority_check_roleid
*                USING sec_actvt /psyng/rolehdr-roleid.
                USING act_change /psyng/rolehdr-roleid.
        sec_actvt = act_change.

        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
        CHECK gf_dispchg = gc_change.

        IF NOT /psyng/rolehdr-roleid IS INITIAL.
*         Lock role ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/ROLEHDR'
            EXPORTING
              roleid         = /psyng/rolehdr-roleid
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM authority_check_roleid
                USING act_display /psyng/rolehdr-roleid.
        sec_actvt = act_display.
        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.
        ok_code = 'ENTER'.
        PERFORM user_command_0302.

        gf_dispchg = gc_display.

*       Unlock role ID
        IF NOT /psyng/rolehdr-roleid IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
            EXPORTING
              roleid = /psyng/rolehdr-roleid.
        ENDIF.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.
      CLEAR first_time.
      IF ok_code <> 'YX_SECTAB_FC3'.
        CLEAR: gf_data_change, /psyng/functtran,
               /psyng/conflict, g_role_trans_itab[], conflict[],
               /psyng/rolehdr, /psyng/roletrans, g_role_trans_wa,
               populated, i_text[].
      ENDIF.

*     Unlock role ID
      IF NOT /psyng/rolehdr-roleid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/ROLEHDR'
          EXPORTING
            roleid = /psyng/rolehdr-roleid.
      ENDIF.
      CLEAR sec_actvt.
    WHEN 'FS'.
      g_fullscreen = '0302'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.
ENDFORM.                    " user_command_0302

*&---------------------------------------------------------------------*
*&      Form  POPULATE_CONFLICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM populate_conflict.
  REFRESH conflict.
  REFRESH g_role_trans_itab2.
  IF ift[] IS INITIAL.
    SELECT * FROM /psyng/functtran
             INTO CORRESPONDING FIELDS OF TABLE ift
             WHERE vrsio = g_sod_vrsio.
  ENDIF.
*==========================NEW logic================================
  REFRESH itab_funct1.
  LOOP AT g_role_trans_itab.
*    SELECT * FROM /psyng/functtran
*             WHERE tcode = g_role_trans_itab-tcode.
*      itab_funct1-functionid = /psyng/functtran-functionid.
    READ TABLE ift WITH KEY tcode = g_role_trans_itab-tcode
         TRANSPORTING NO FIELDS.
    ift_idx = sy-tabix.
    LOOP AT ift FROM ift_idx WHERE tcode = g_role_trans_itab-tcode.
      itab_funct1-functionid = ift-functionid.
      APPEND itab_funct1.
    ENDLOOP.
*    ENDSELECT.
  ENDLOOP.

  SORT itab_funct1.
  DELETE ADJACENT DUPLICATES FROM itab_funct1.
  REFRESH itab_con.
  LOOP AT itab_funct1.
    SELECT * FROM /psyng/confdet                     "#EC CI_SEL_NESTED
    WHERE functionid = itab_funct1-functionid
      AND vrsio      = g_sod_vrsio.

      itab_con-conid = /psyng/confdet-conid.
      APPEND itab_con.
    ENDSELECT.
  ENDLOOP.
  SORT itab_con.
  DELETE ADJACENT DUPLICATES FROM itab_con.

  LOOP AT itab_con.
    exist = space.
    SELECT * FROM /psyng/confdet                     "#EC CI_SEL_NESTED
    WHERE conid = itab_con-conid
      AND vrsio = g_sod_vrsio.

      READ TABLE itab_funct1
      WITH KEY functionid = /psyng/confdet-functionid.
      IF sy-subrc <> 0.
        exist = 'X'.
      ENDIF.
    ENDSELECT.
    IF sy-subrc <> 0.
      exist = 'X'.
    ENDIF.
    IF exist = space.
      conflict-conid = itab_con-conid.
      SELECT SINGLE * FROM /psyng/conflict           "#EC CI_SEL_NESTED
      WHERE conid = conflict-conid
        AND vrsio = g_sod_vrsio.

      conflict-description = /psyng/conflict-description.
      APPEND conflict.
    ENDIF.
  ENDLOOP.
  SORT conflict.
  DELETE ADJACENT DUPLICATES FROM conflict.
ENDFORM.                    " POPULATE_CONFLICT

*&---------------------------------------------------------------------*
*&      Form  POPULATE_TRANSACTIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM populate_transactions.
  REFRESH g_role_trans_itab[].
  LOOP AT i_prole INTO  p_role.
    SELECT * FROM /psyng/roletrans                   "#EC CI_SEL_NESTED
       INTO /psyng/roletrans
    WHERE roleid = p_role-roleid.
      g_role_trans_itab-tcode = /psyng/roletrans-tcode.
      APPEND g_role_trans_itab TO g_role_trans_itab.
    ENDSELECT.
  ENDLOOP.
ENDFORM.                    " POPULATE_TRANSACTIONS

*&---------------------------------------------------------------------*
*&      Form  POPULATE_CONFLICT2
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM populate_conflict2.

*  IF conflict[] IS INITIAL.
*    CLEAR first_time.
*    MESSAGE e350(/psyng/sw).
*  ENDIF.
  LOOP AT conflict INTO conflict.
    conflict2-conid = conflict-conid.
    conflict2-description = conflict-description.
    APPEND conflict2 TO conflict2.
  ENDLOOP.
  SORT conflict2.
  DELETE ADJACENT DUPLICATES FROM conflict2.
  CLEAR first_time.

ENDFORM.                    " POPULATE_CONFLICT2

*&---------------------------------------------------------------------*
*&      Form  REFRESH_TREE_USER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM refresh_tree_user.
****************
*Case#1939
*Prevent Refresh tree when Userid is blank.
  IF /psyng/user-userid = space AND upd_flag = space.
    CHECK ok_code NE 'FIND'.
****************
    IF NOT g_left_custom_container IS INITIAL.
      " destroy tree containers (detroys contained tree control, too)
      CALL METHOD g_left_custom_container->free
        EXCEPTIONS
          cntl_system_error = 1
          cntl_error        = 2.
      IF sy-subrc <> 0.
*          MESSAGE A000.
      ENDIF.
      CALL METHOD g_right_custom_container->free
        EXCEPTIONS
          cntl_system_error = 1
          cntl_error        = 2.
      IF sy-subrc <> 0.
*          MESSAGE A000.
      ENDIF.
      CLEAR g_left_custom_container.
      CLEAR g_left_tree.
      CLEAR g_left_custom_container.
      CLEAR g_right_tree.
      REFRESH left_node_table.
      REFRESH right_node_table.
      CLEAR left_node_table.
      CLEAR right_node_table.
      REFRESH i_prole.
      REFRESH j_prole.
    ENDIF.
  ENDIF.
ENDFORM.                    " REFRESH_TREE_USER

*&---------------------------------------------------------------------*
*&      Form  REFRESH_TREE_POSITION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM refresh_tree_position.

****************
*Case#1939
*Prevent Refresh tree when positionid is blank.
  IF /psyng/position-positionid = space AND upd_flag = space.
    CHECK ok_code NE 'FIND'.
****************
    IF NOT g_left_custom_container IS INITIAL.
      " destroy tree containers (detroys contained tree control, too)
      CALL METHOD g_left_custom_container->free
        EXCEPTIONS
          cntl_system_error = 1
          cntl_error        = 2.
      IF sy-subrc <> 0.
*          MESSAGE A000.
      ENDIF.
      CALL METHOD g_right_custom_container->free
        EXCEPTIONS
          cntl_system_error = 1
          cntl_error        = 2.
      IF sy-subrc <> 0.
*          MESSAGE A000.
      ENDIF.
      CLEAR g_left_custom_container.
      CLEAR g_left_tree.
      CLEAR g_left_custom_container.
      CLEAR g_right_tree.
      REFRESH left_node_table.
      REFRESH right_node_table.
      CLEAR left_node_table.
      CLEAR right_node_table.
      REFRESH i_prole.
      REFRESH j_prole.
    ENDIF.
  ENDIF.
ENDFORM.                    " REFRESH_TREE_POSITION

*&---------------------------------------------------------------------*
*&      Form  REFRESH_TREE_CHANGE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM refresh_tree_change.
  REFRESH conflict.
  REFRESH conflict2.
  REFRESH i_prole.
  REFRESH j_prole.
  REFRESH g_role_trans_itab2.
  REFRESH g_role_trans_itab.
ENDFORM.                    " REFRESH_TREE_CHANGE

*---------------------------------------------------------------------*
*       FORM CREATE_AND_INIT_TREES                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM create_and_init_trees.
* create containers for the tree controls
  CREATE OBJECT g_left_custom_container
    EXPORTING
      container_name              = 'LEFT_TREE_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

  CREATE OBJECT g_right_custom_container
    EXPORTING
      container_name              = 'RIGHT_TREE_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

* create left tree control
  CREATE OBJECT g_left_tree
    EXPORTING
      parent                      = g_left_custom_container
node_selection_mode         = cl_gui_simple_tree=>node_sel_mode_multiple
EXCEPTIONS
lifetime_error              = 1
cntl_system_error           = 2
create_error                = 3
failed                      = 4
illegal_node_selection_mode = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

* create right tree control
  CREATE OBJECT g_right_tree
    EXPORTING
      parent                      = g_right_custom_container
  node_selection_mode         = cl_gui_simple_tree=>node_sel_mode_single
EXCEPTIONS
  lifetime_error              = 1
  cntl_system_error           = 2
  create_error                = 3
  failed                      = 4
  illegal_node_selection_mode = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

* Events left tree control (note: no events must be registered for
* Drag & Drop)
  SET HANDLER g_application->handle_left_tree_drag FOR g_left_tree.
  SET HANDLER g_application->handle_left_tree_drop_complete
    FOR g_left_tree.

* Events right tree control
  SET HANDLER g_application->handle_right_tree_drop FOR g_right_tree.
  IF user = 'X'.                                 "#EC SAST_CI_GEN_CHECK
    PERFORM build_user_node_tables.
  ELSE.
    PERFORM build_node_tables.
  ENDIF.
* add the nodes to the controls
  CALL METHOD g_left_tree->add_nodes
    EXPORTING
      table_structure_name           = '/PSYNG/MTREES'
      node_table                     = left_node_table
    EXCEPTIONS
      failed                         = 1
      error_in_node_table            = 2
      dp_error                       = 3
      table_structure_name_not_found = 4
      OTHERS                         = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

  CALL METHOD g_right_tree->add_nodes
    EXPORTING
      table_structure_name           = '/PSYNG/MTREES'
      node_table                     = right_node_table
    EXCEPTIONS
      failed                         = 1
      error_in_node_table            = 2
      dp_error                       = 3
      table_structure_name_not_found = 4
      OTHERS                         = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

* expand the root nodes
  CALL METHOD g_left_tree->expand_node
    EXPORTING
  node_key            = 'Root'                              "#EC NOTEXT
EXCEPTIONS
  failed              = 1
  illegal_level_count = 2
  cntl_system_error   = 3
  node_not_found      = 4
  cannot_expand_leaf  = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

  CALL METHOD g_right_tree->expand_node
    EXPORTING
      node_key            = 'Root'
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.
ENDFORM.                    " CREATE_AND_INIT_TREE

*&---------------------------------------------------------------------*
*&      Form  BUILD_NODE_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_node_tables.
* define a drag & Drop behaviour for the two leaves in the left tree
  CREATE OBJECT behaviour_left.
  " add a Drag & Drop description to the behaviour
  " Flavor of the description: "Files"
  " Drag is supported, Drop is not supported
  " copy drag and move drag are possible
  effect = cl_dragdrop=>move + cl_dragdrop=>copy.
  CALL METHOD behaviour_left->add
    EXPORTING
     flavor     = 'Files'                                   "#EC NOTEXT
     dragsrc    = 'X'
     droptarget = ' '
     effect     = effect.
  CALL METHOD behaviour_left->get_handle IMPORTING handle = handle_left.

* define a drag & Drop behaviour for the folder in the right tree
  CREATE OBJECT behaviour_right.
  " add a Drag & Drop description to the behaviour
  " Flavor of the description: "Files"
  " Drop is supported, Drag is not supported
  " copy drop and move drop are possible
  effect = cl_dragdrop=>move + cl_dragdrop=>copy.
  CALL METHOD behaviour_right->add
    EXPORTING
      flavor     = 'Files'
      dragsrc    = ' '
      droptarget = 'X'
      effect     = effect.
  CALL METHOD behaviour_right->get_handle
    IMPORTING
      handle = handle_right.
*===================================================================
* node table of the left tree

  CLEAR node.
  node-node_key = 'Root'.
  node-isfolder = 'X'.
  node-text = text-132.
  APPEND node TO left_node_table.

  SELECT * FROM /psyng/rolehdr ORDER BY PRIMARY KEY.
    CLEAR node.
    node-node_key = /psyng/rolehdr-roleid.                  "#EC NOTEXT
    TRANSLATE node-node_key TO UPPER CASE.
    node-relatkey = 'Root'.
    node-relatship = cl_gui_simple_tree=>relat_last_child.

    IF gf_disp_pfcg IS INITIAL OR /psyng/rolehdr-saptechname IS INITIAL.
      CONCATENATE /psyng/rolehdr-roleid '-' /psyng/rolehdr-description
                  INTO node-text.
    ELSE.
      CONCATENATE /psyng/rolehdr-roleid '-' /psyng/rolehdr-saptechname
                  INTO node-text.
    ENDIF.

    node-dragdropid = handle_left. " handle of behaviour
    APPEND node TO left_node_table.
  ENDSELECT.
* node table of the right tree
  CLEAR node.
  node-node_key = 'Root'.
  node-isfolder = 'X'.
  node-text = text-133.
  node-dragdropid = handle_right.
  APPEND node TO right_node_table.
ENDFORM.                    " BUILD_NODE_TABLES

*&---------------------------------------------------------------------*
*&      Form  BUILD_USER_NODE_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_user_node_tables.
  DATA: node         LIKE /psyng/mtrees,
        effect       TYPE i,
        handle_left  TYPE i,
        handle_right TYPE i.

* define a drag & Drop behaviour for the two leaves in the left tree
  CREATE OBJECT behaviour_left.
  " add a Drag & Drop description to the behaviour
  " Flavor of the description: "Files"
  " Drag is supported, Drop is not supported
  " copy drag and move drag are possible
  effect = cl_dragdrop=>move + cl_dragdrop=>copy.
  CALL METHOD behaviour_left->add
    EXPORTING
     flavor     = 'Files'                                   "#EC NOTEXT
     dragsrc    = 'X'
     droptarget = ' '
     effect     = effect.
  CALL METHOD behaviour_left->get_handle IMPORTING handle = handle_left.

* define a drag & Drop behaviour for the folder in the right tree
  CREATE OBJECT behaviour_right.
  " add a Drag & Drop description to the behaviour
  " Flavor of the description: "Files"
  " Drop is supported, Drag is not supported
  " copy drop and move drop are possible
  effect = cl_dragdrop=>move + cl_dragdrop=>copy.
  CALL METHOD behaviour_right->add
    EXPORTING
      flavor     = 'Files'
      dragsrc    = ' '
      droptarget = 'X'
      effect     = effect.
  CALL METHOD behaviour_right->get_handle
    IMPORTING
      handle = handle_right.
*===================================================================
* node table of the left tree

  CLEAR node.
  node-node_key = 'Root'.
  node-isfolder = 'X'.
  node-text = text-046.
  APPEND node TO left_node_table.

  SELECT * FROM /psyng/position ORDER BY PRIMARY KEY.
    CLEAR node.
    node-node_key = /psyng/position-positionid.             "#EC NOTEXT
    TRANSLATE node-node_key TO UPPER CASE.
    node-relatkey = 'Root'.
    node-relatship = cl_gui_simple_tree=>relat_last_child.
*    node-text = /psyng/position-description.
    CONCATENATE /psyng/position-positionid ' - '
/psyng/position-description INTO node-text.
    node-dragdropid = handle_left. " handle of behaviour
    APPEND node TO left_node_table.
  ENDSELECT.
  CLEAR node.
  node-node_key = 'Root'.
  node-isfolder = 'X'.
  node-text = text-047.
  node-dragdropid = handle_right.
  APPEND node TO right_node_table.
ENDFORM.                    " BUILD_USER_NODE_TABLES

*&---------------------------------------------------------------------*
*&      Form  FREE_RIGHT_TREE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM free_right_tree.
  CALL METHOD g_right_custom_container->free
    EXCEPTIONS
      cntl_system_error = 1
      cntl_error        = 2.
*    IF SY-SUBRC <> 0.
*\*          MESSAGE A000.
*\    ENDIF.
  CLEAR g_right_tree.
  REFRESH right_node_table.
  CLEAR right_node_table.
  REFRESH i_prole.
  REFRESH j_prole.

  CREATE OBJECT g_right_custom_container
    EXPORTING
      container_name              = 'RIGHT_TREE_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
*   MESSAGE A000.
  ENDIF.

  CREATE OBJECT g_right_tree
    EXPORTING
      parent                      = g_right_custom_container
  node_selection_mode         = cl_gui_simple_tree=>node_sel_mode_single
EXCEPTIONS
  lifetime_error              = 1
  cntl_system_error           = 2
  create_error                = 3
  failed                      = 4
  illegal_node_selection_mode = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.
ENDFORM.                    " FREE_RIGHT_TREE

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_CONFLICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

*****************changed by sgottapu*************

FORM display_conflict.

  DATA:lt_tcodes TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE.
  DATA:wa_tcodes LIKE /psyng/range_tcode.
  DATA:wa_g_role_trans LIKE LINE OF g_role_trans_itab.


  LOOP AT g_role_trans_itab INTO wa_g_role_trans .

    wa_tcodes-low    = wa_g_role_trans-tcode.
    wa_tcodes-option = 'EQ'.
    wa_tcodes-sign   = 'I'.
    APPEND wa_tcodes TO lt_tcodes.
    CLEAR: wa_g_role_trans.
  ENDLOOP.


  screen_323 = space.
  stext_reload1 = space.
  REFRESH i_text.

  READ TABLE conflict2 INDEX cursor_line.
  conid = conflict2-conid.

  CALL FUNCTION '/PSYNG/SW_007'
    EXPORTING
      i_conid  = conid
      i_vrsio  = g_sod_vrsio
    TABLES
      it_tcode = lt_tcodes.

ENDFORM.                    " DISPLAY_CONFLICT

***  **changes end by sgottapu


*&---------------------------------------------------------------------*
*&      Form  FILL_IPROLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_iprole.
  REFRESH i_prole.
  LOOP AT j_prole.
    SELECT * FROM /psyng/posndet                     "#EC CI_SEL_NESTED
           WHERE positionid = j_prole-positionid.
      i_prole-roleid = /psyng/posndet-roleid.
      APPEND i_prole TO i_prole.
    ENDSELECT.
  ENDLOOP.
ENDFORM.                    " FILL_IPROLE

*&---------------------------------------------------------------------*
*&      Form  GET_EDITOR_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_editor_text.
  DATA: l_stext_modified TYPE i.
*  DATA: one(80), two(80), three(80), four(80), five(80), six(80),
*  seven(80), eight(80), nine(80), ten(80).

* retrieve table from control
*  CALL METHOD stext_editor->get_text_as_stream
*      EXPORTING
*          only_when_modified = cl_gui_textedit=>true
*      IMPORTING
*          text               = g_editor_text
*          is_modified        = l_stext_modified
*      EXCEPTIONS
*          OTHERS             = 1.
*
  CALL METHOD stext_editor->get_text_as_r3table
    IMPORTING
      table       = g_editor_text
      is_modified = l_stext_modified
    EXCEPTIONS
      OTHERS      = 1.


  IF sy-subrc NE 0.
    MESSAGE e800(bmen).
  ENDIF.

* change table if text has been modified
  IF l_stext_modified = cl_gui_textedit=>true.
    gf_data_change = gc_select.
    i_text[] = g_editor_text[].
  ENDIF.

ENDFORM.                    " GET_EDITOR_TEXT

*&---------------------------------------------------------------------*
*&      Form  INIT_SCREENS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_screens.
  CLEAR first_time.
  REFRESH funtcodes.
  REFRESH i_text[].
  REFRESH g_funct_itab.
  REFRESH g_role_trans_itab.
  REFRESH g_jobtxn_itab.
  REFRESH conflict2.
  REFRESH conflict.
  CLEAR /psyng/functtran.
  CLEAR /psyng/function.
  CLEAR /psyng/conflict.
  CLEAR /psyng/confdet.
  CLEAR /psyng/rolehdr.
  CLEAR /psyng/roleconf.
  CLEAR /psyng/roletrans.
  CLEAR /psyng/texts.
  CLEAR /psyng/swaudc2.
  CLEAR /psyng/swaudhdr.
  CLEAR /psyng/tsw_hst.
  CLEAR /psyng/tsw_grhst.
  CLEAR /psyng/mccauser.
*  CLEAR /psyng/sw_mccau.
  CLEAR upd_flag.
  SET PARAMETER ID '/PSYNG/VRSIO' FIELD g_sod_vrsio.

ENDFORM.                    " INIT_SCREENS

*&---------------------------------------------------------------------*
*&      Form  POPULATE_SOD_CONFLICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM populate_sod_conflict.
  DATA: lv_description TYPE /psyng/conflict-description.
  TABLES: agr_1251.
* Check against AGR_1251 table
  REFRESH conflict.
  REFRESH conflict2.
  REFRESH itab_tcode.
  REFRESH g_role_trans_itab2.
  LOOP AT g_role_trans_itab.
    MOVE g_role_trans_itab TO g_role_trans_itab2.
    APPEND g_role_trans_itab2.
  ENDLOOP.

  LOOP AT g_role_trans_itab.
    exist = 'X'.
    SELECT * FROM /psyng/sodobject                   "#EC CI_SEL_NESTED
           WHERE tcode = g_role_trans_itab-tcode
             AND vrsio = g_sod_vrsio.

      exist = space.

      SELECT * FROM agr_1251 INTO agr_1251
      WHERE agr_name = /psyng/rolehdr-saptechname
      AND object = /psyng/sodobject-object
      AND field = /psyng/sodobject-field
      AND deleted NE 'X'.

*      AND LOW NE '*'.
        IF agr_1251-low = '*'.
          exist = 'X'.
        ENDIF.

        IF /psyng/sodobject-val_to > space AND
            /psyng/sodobject-val_from > space.
          IF /psyng/sodobject-val_from <= agr_1251-low AND
             /psyng/sodobject-val_to >= agr_1251-low.
            exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from > space AND
           /psyng/sodobject-val_to = space.
          IF /psyng/sodobject-val_from = agr_1251-low.
            exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from = space AND
           /psyng/sodobject-val_to > space.
          IF /psyng/sodobject-val_to = agr_1251-low.
            exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from = space AND
           /psyng/sodobject-val_to = space.
          exist = 'X'.
        ENDIF.
      ENDSELECT.

      IF exist = space.
        itab_tcode-tcode = g_role_trans_itab-tcode.
        APPEND itab_tcode.
      ENDIF.

    ENDSELECT.
    IF sy-subrc <> 0.
      itab_tcode-tcode = g_role_trans_itab-tcode.
      APPEND itab_tcode.
    ENDIF.
  ENDLOOP.

  LOOP AT itab_tcode.
    DELETE g_role_trans_itab2 WHERE tcode = itab_tcode-tcode.
  ENDLOOP.

  REFRESH itab_funct1.
  LOOP AT g_role_trans_itab2.
    SELECT * FROM /psyng/functtran                   "#EC CI_SEL_NESTED
           WHERE tcode = g_role_trans_itab2-tcode
             AND vrsio = g_sod_vrsio.
      itab_funct1-functionid = /psyng/functtran-functionid.
      APPEND itab_funct1.
    ENDSELECT.
  ENDLOOP.

  SORT itab_funct1.
  DELETE ADJACENT DUPLICATES FROM itab_funct1.
  REFRESH itab_con.
  LOOP AT itab_funct1.
    SELECT * FROM /psyng/confdet                     "#EC CI_SEL_NESTED
           WHERE functionid = itab_funct1-functionid
             AND vrsio      = g_sod_vrsio.
      itab_con-conid = /psyng/confdet-conid.
      APPEND itab_con.
    ENDSELECT.
  ENDLOOP.
  SORT itab_con.
  DELETE ADJACENT DUPLICATES FROM itab_con.

  LOOP AT itab_con.
    exist = space.
    SELECT * FROM /psyng/confdet                     "#EC CI_SEL_NESTED
           WHERE conid = itab_con-conid
             AND vrsio = g_sod_vrsio.
      READ TABLE itab_funct1
      WITH KEY functionid = /psyng/confdet-functionid.
      IF sy-subrc <> 0.
        exist = 'X'.
      ENDIF.
    ENDSELECT.
    IF sy-subrc <> 0.
      exist = 'X'.
    ENDIF.
    IF exist = space.
      conflict-conid = itab_con-conid.
*      SELECT SINGLE * FROM /psyng/conflict
      SELECT SINGLE description                      "#EC CI_SEL_NESTED
         FROM /psyng/conflict
                 INTO lv_description
                    WHERE conid = conflict-conid
                      AND vrsio = g_sod_vrsio.
      conflict-description = lv_description."/psyng/conflict-description
      .
      APPEND conflict.
    ENDIF.
  ENDLOOP.
  SORT conflict.
  DELETE ADJACENT DUPLICATES FROM conflict.
ENDFORM.                    " POPULATE_SOD_CONFLICT

*&---------------------------------------------------------------------*
*&      Form  POPULATE_HISTORY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM populate_history USING i_tabname
                            i_hdrfld
                            i_dtlfld
                            i_oldval
                            i_newval
                            i_status.

  CASE i_tabname.
    WHEN '/PSYNG/ROLEHDR' OR '/PSYNG/ROLETRANS' OR '/PSYNG/POSITION' OR
         '/PSYNG/POSNDET' OR '/PSYNG/USER' OR '/PSYNG/USRDET'.
*     No version for these
    WHEN OTHERS.
      /psyng/history-vrsio = g_sod_vrsio.
  ENDCASE.

  /psyng/history-tabname = i_tabname.
  /psyng/history-hdrfld  = i_hdrfld.
  /psyng/history-dtlfld  = i_dtlfld.
  /psyng/history-oldval  = i_oldval.
  /psyng/history-newval  = i_newval.
  /psyng/history-status  = i_status.
  /psyng/history-create_dat = crt_dte.
  /psyng/history-create_tim = crt_tme.
  /psyng/history-create_usr = g_current_user."sy-uname. C0700
  INSERT /psyng/history.
  CLEAR /psyng/history.
ENDFORM.                    " POPULATE_HISTORY

*&---------------------------------------------------------------------*
*&      Form  TOGGLE_DISPLAY_CHANGE
*&---------------------------------------------------------------------*
*       Toggle screen fields between display and change modes
*----------------------------------------------------------------------*
FORM toggle_display_change.
  IF gf_dispchg = gc_change.
    IF g_sodfun-pressed_tab <> c_sodfun-tab4 AND
       g_sodfun-pressed_tab <> c_sodfun-tab1.
      PERFORM check_version_editable.
    ENDIF.
  ENDIF.

  IF gf_dispchg = gc_display.                    "Display
    LOOP AT SCREEN.
      IF screen-group1 = '001' AND screen-input = 1.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
*        IF gf_dispchg = gc_change.

*      ENDIF.
    "Change
    LOOP AT SCREEN.

      IF screen-group1 = '001' AND screen-input = 0.
        screen-input = 1.
        MODIFY SCREEN.

*      ELSEIF screen-group1 = '002' AND
*                          /psyng/functtran-functionid IS INITIAL.
*        screen-input = 1.
*        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " TOGGLE_DISPLAY_CHANGE

*&---------------------------------------------------------------------*
*&      Form  load_picture_from_db
*&---------------------------------------------------------------------*
*       Get picture data
*----------------------------------------------------------------------*
*      -->ET_PIC_DATA  Table of picture data
*      -->I_PIC_NAME   Picture name
*      <--E_PIC_SIZE   Picture size
*----------------------------------------------------------------------*
FORM load_picture_from_db      TABLES   et_pic_data STRUCTURE w3mime
                               USING    i_pic_name TYPE c
                               CHANGING e_pic_size TYPE i.

  DATA: lt_query         LIKE w3query OCCURS 1 WITH HEADER LINE,
        lt_html          LIKE w3html OCCURS 1,
        l_retcode        LIKE w3param-ret_code,
        l_content_type   LIKE w3param-cont_type,
        l_content_length LIKE w3param-cont_len.

  lt_query-name = '_OBJECT_ID'.
  lt_query-value = i_pic_name.
  APPEND lt_query.

  CALL FUNCTION 'WWW_GET_MIME_OBJECT'
    TABLES
      query_string   = lt_query
      html           = lt_html
      mime           = et_pic_data
    CHANGING
      return_code    = l_retcode
      content_type   = l_content_type
      content_length = l_content_length
    EXCEPTIONS
      OTHERS         = 1.
  IF sy-subrc = 0.
    e_pic_size = l_content_length.
  ENDIF.
ENDFORM.                    " load_picture_from_db

*&---------------------------------------------------------------------*
*&      Form  exit_without_save
*&---------------------------------------------------------------------*
*       Ask if user wants to exit without saving
*----------------------------------------------------------------------*
FORM exit_without_save.
* If data was changed, ask if user wants to exit without saving
  gf_answer = 1.
*  IF gf_data_change = gc_select.
*    CALL FUNCTION 'POPUP_TO_CONFIRM'
*         EXPORTING
*              text_question         = text-003
*              text_button_1         = text-001
*              icon_button_1         = 'ICON_CHECKED'
*              text_button_2         = text-002
*              icon_button_2         = 'ICON_INCOMPLETE'
*              default_button        = '2'
*              display_cancel_button = space
*         IMPORTING
*              answer                = gf_answer
*         EXCEPTIONS
*              text_not_found        = 1
*              OTHERS                = 2.
*    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*    ENDIF.
*  ENDIF.
  IF gf_answer > '1'.
    CLEAR: g_yx_sectab-pressed_tab, g_sodfun-pressed_tab.
*         LEAVE
  ENDIF.

ENDFORM.                    " exit_without_save

*&---------------------------------------------------------------------*
*&      Form  get_filename
*&---------------------------------------------------------------------*
*       Prompt user for file name
*----------------------------------------------------------------------*
*      <--E_FILENAME  File name
*----------------------------------------------------------------------*
FORM get_filename USING i_title
                  CHANGING e_filename TYPE rlgrap-filename.
  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      mask             = ',*.*,*.*.'
      mode             = 'O'
      title            = i_title
    IMPORTING
      filename         = e_filename
    EXCEPTIONS
      inv_winsys       = 1
      no_batch         = 2
      selection_cancel = 3
      selection_error  = 4
      OTHERS           = 5.
  IF sy-subrc <> 0 AND sy-subrc <> 3.
    MESSAGE e398(00) WITH text-e03.
  ENDIF.
ENDFORM.                    " get_filename
*&---------------------------------------------------------------------*
*&      Form  user_command_0209
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_command_0209.
  DATA: lf_ins_upd(1) TYPE c.
  DATA: t_psyng_swaudhdr LIKE /psyng/swaudhdr.

  DATA: BEGIN OF lt_tcode OCCURS 0,
          tcode TYPE /psyng/faobj2-tcode,
        END OF lt_tcode.

  DATA :lt_texts   TYPE TABLE OF /psyng/texts WITH HEADER LINE,
        lt_swaudc2 TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE.

  RANGES: lr_swaudid FOR /psyng/swaudc2-swaudid.
  RANGES: lr_swatcde FOR /psyng/swaudc2-tcode.
  RANGES: lr_audid FOR /psyng/swaudhdr-swaudid.
  RANGES: lr_vrsio FOR /psyng/swaudhdr-vrsio.

DATA : lt_mccauser       TYPE TABLE OF /psyng/mccauser WITH HEADER LINE,
       lt_mccarole       TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
       ls_mchdr          TYPE /psyng/mchdr,
       l_answer(1)       TYPE c,
       l_mandt           TYPE sy-mandt,
       l_no_valid_assign TYPE flag,
       l_question(180).

  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_cri_auth
            USING sec_actvt /psyng/swaudc2-swaudid.
  ENDIF.

  crt_dte = sy-datum.
  crt_tme = sy-uzeit.

* Unlock previous function id
  IF /psyng/swaudhdr-swaudid <> /psyng/swaudc2-swaudid.
    CALL FUNCTION 'DEQUEUE_/PSYNG/SWAUDHDR'
      EXPORTING
        swaudid = /psyng/swaudhdr-swaudid
        vrsio   = g_sod_vrsio.

    DELETE gt_locked WHERE type = 'SWAUDHDR'.
    CLEAR first_time.
  ENDIF.

  /psyng/swaudhdr-swaudid = /psyng/swaudc2-swaudid.
  populated = 'X'.
  CASE ok_code.
    WHEN 'EAOBJ'.
      eaobj_flag = space.
      t_psyng_swaudhdr = /psyng/swaudhdr.
      SELECT SINGLE * FROM /psyng/swaudhdr WHERE vrsio = g_sod_vrsio AND
                                      swaudid = /psyng/swaudhdr-swaudid.
      IF sy-subrc <> 0.
        MESSAGE i192(/psyng/sw).
        EXIT.
      ENDIF.

      /psyng/swaudhdr = t_psyng_swaudhdr.

      IF gf_dispchg = gc_change.
        g_nodsp = 'X'.
      ELSE.
        g_nodsp = ' '.
      ENDIF.

      IF NOT /psyng/swaudc2-swaudid IS INITIAL.
        lr_swaudid-sign = 'I'.
        lr_swaudid-option = 'EQ'.
        lr_swaudid-low = /psyng/swaudc2-swaudid.
        APPEND lr_swaudid.

        lr_swatcde-sign = 'I'.
        lr_swatcde-option = 'EQ'.
        lr_swatcde-low = /psyng/swaudhdr-tcode.
        APPEND lr_swatcde.

        SUBMIT /psyng/audtobj
               WITH p_vrsio  = g_sod_vrsio
               WITH swaudid IN lr_swaudid
               WITH swatcde IN lr_swatcde
               WITH p_nodsp = g_nodsp
               AND RETURN.
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
           ID 'ACTVT'      FIELD act_display
           ID 'Y&SW_AUTID' FIELD '*'
           ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
        IF sy-subrc NE 0.
          MESSAGE e108(/psyng/sw) WITH text-048.
        ENDIF.

        SUBMIT /psyng/audtobj WITH p_vrsio = g_sod_vrsio
                              WITH p_nodsp = g_nodsp
                              AND RETURN.
        lr_swaudid-sign = 'I'.
        lr_swaudid-option = 'EQ'.
        lr_swaudid-low = '*'.
        APPEND lr_swaudid.
      ENDIF.
      eaobj_flag = 'X'.

    WHEN 'CHANGES'.
      lr_vrsio-sign   = 'I'.
      lr_vrsio-option = 'EQ'.
      lr_vrsio-low    = g_sod_vrsio.
      APPEND lr_vrsio.

      IF NOT /psyng/swaudc2-swaudid IS INITIAL.
        lr_swaudid-sign = 'I'.
        lr_swaudid-option = 'EQ'.
        lr_swaudid-low = /psyng/swaudc2-swaudid.
        APPEND lr_swaudid.

      ENDIF.

      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH s_vrsio IN lr_vrsio
             WITH p_cauth  = 'X'
             WITH s_cauth IN lr_swaudid
             AND RETURN.


    WHEN 'ENTER'.
      PERFORM load_ca.

    WHEN 'DELETE'.
*--Check if CA exists
      SELECT SINGLE vrsio INTO /psyng/swaudc2-vrsio
      FROM /psyng/swaudhdr
        WHERE swaudid = /psyng/swaudc2-swaudid
        AND   vrsio   = g_sod_vrsio.
      IF sy-subrc <> 0.
        MESSAGE i022(/psyng/sw) WITH /psyng/swaudc2-swaudid.
        EXIT.
      ENDIF.

      PERFORM authority_check_cri_auth
              USING act_delete /psyng/swaudc2-swaudid.
      sec_actvt = act_delete.

      CONCATENATE text-049 /psyng/swaudc2-swaudid
          INTO popup_question SEPARATED BY space.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = popup_question
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.

      CHECK popup_answer = '1'.

** Start of 3.1 changes
**Check whether any valid assignment made to the critical authorization

      SELECT SINGLE mandt FROM /psyng/mccauser INTO l_mandt
           WHERE vrsio = g_sod_vrsio
           AND swaudid = /psyng/swaudc2-swaudid
           AND to_date GE sy-datum.
      IF sy-subrc NE 0.
        SELECT SINGLE mandt FROM /psyng/mccarole INTO l_mandt
             WHERE vrsio = g_sod_vrsio
             AND swaudid = /psyng/swaudc2-swaudid
             AND to_date GE sy-datum.
        IF sy-subrc <> 0.
          l_no_valid_assign = 'X'.
        ENDIF.
      ENDIF.

      IF l_no_valid_assign EQ space.

     CONCATENATE 'Valid MC Assignments exist for Critical Authorization'
                                                  /psyng/swaudc2-swaudid
                           '. Do you want to continue with the Delete ?'
                                     INTO l_question SEPARATED BY space.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = text-027
            text_question         = l_question
            text_button_1         = text-123
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = text-124
            icon_button_2         = 'ICON_CANCEL'
            default_button        = '2'
            display_cancel_button = space
            start_column          = 25
            start_row             = 6
          IMPORTING
            answer                = l_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ELSE.
        l_answer = 1.
      ENDIF.

      CHECK l_answer = '1'.

      CLEAR: l_answer,l_no_valid_assign.

** Delete critical auth and details
      CALL FUNCTION '/PSYNG/SW_CR_DELETE_CRI_AUTHS'
        EXPORTING
          i_vrsio   = g_sod_vrsio
          i_swaudid = /psyng/swaudc2-swaudid
        EXCEPTIONS
*         NOT_AUTHORIZED       = 1
*         NOT_EXIST = 2
*         locked    = 3
          OTHERS    = 4.
      IF sy-subrc = 0.
        CONCATENATE text-010 /psyng/swaudc2-swaudid text-126
                            INTO messagetext SEPARATED BY space.

        MESSAGE i208(00) WITH messagetext.
      ELSE.
        MESSAGE w103(/psyng/sw).
        EXIT.

      ENDIF.

*** Mitigation assignments to critical auths - users
*** Will delete all the assignments expired,current and future

      SELECT * FROM /psyng/mccauser INTO TABLE lt_mccauser
      WHERE vrsio EQ g_sod_vrsio
      AND swaudid = /psyng/swaudc2-swaudid.

      LOOP AT lt_mccauser.

        ls_mchdr-contid = lt_mccauser-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mccauser          = lt_mccauser
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        "(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDLOOP.

*** Mitigation assignments to critical auths - roles
*** Will delete all the assignments expired,current and future

      SELECT * FROM /psyng/mccarole INTO TABLE lt_mccarole
      WHERE vrsio EQ g_sod_vrsio
      AND swaudid = /psyng/swaudc2-swaudid.

      LOOP AT lt_mccarole.

        ls_mchdr-contid = lt_mccarole-contid.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mccarole          = lt_mccarole
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        "(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDLOOP.

      CALL FUNCTION 'DEQUEUE_/PSYNG/SWAUDHDR'
        EXPORTING
          swaudid = /psyng/swaudhdr-swaudid
          vrsio   = g_sod_vrsio.

      DELETE gt_locked WHERE type = 'SWAUDHDR'.
      CLEAR: /psyng/swaudhdr, /psyng/swaudc2,
             gf_data_change, i_text, i_text[],g_editor_text[].

    WHEN 'SAVE'.
      IF /psyng/swaudc2-swaudid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-010.
      ENDIF.
      PERFORM validate_tcode USING    /psyng/swaudhdr-tcode.
      PERFORM authority_check_cri_auth
              USING act_change /psyng/swaudc2-swaudid.
      sec_actvt = act_change.
      /psyng/swaudhdr-vrsio      = g_sod_vrsio.
      /psyng/swaudhdr-change_usr = g_current_user. "sy-uname. C0700
      /psyng/swaudhdr-change_dat = sy-datum.
      /psyng/swaudhdr-change_tim = sy-uzeit.


*      SELECT SINGLE swaudid  INTO /psyng/swaudhdr-swaudid
*               FROM /psyng/swaudhdr
*              WHERE swaudid  = /psyng/swaudc2-swaudid
*                AND vrsio    = g_sod_vrsio.
*
*      IF sy-subrc = 0.
*        lf_ins_upd = 'U'.
*        UPDATE /psyng/swaudhdr.
*        IF sy-subrc = 0.
*          MESSAGE s120(/psyng/sw).  " Data Saved
*        ENDIF.
*      ELSE.
*       lf_ins_upd = 'I'.
*             Lock AUDIT ID
*        CALL FUNCTION 'ENQUEUE_/PSYNG/SWAUDHDR'
*             EXPORTING
*                  swaudid        = /psyng/swaudhdr-swaudid
*                  vrsio          = g_sod_vrsio
*             EXCEPTIONS
*                  foreign_lock   = 1
*                  system_failure = 2
*                  OTHERS         = 3.
*        IF sy-subrc <> 0.
*          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ELSE.
*          gt_locked-type   = 'SWAUDHDR'.
*          gt_locked-object = /psyng/swaudhdr-swaudid.
*          APPEND gt_locked.
*        ENDIF.
*        /psyng/swaudhdr-vrsio      = g_sod_vrsio.
*        /psyng/swaudhdr-swaudid    = /psyng/swaudc2-swaudid.
*        /psyng/swaudhdr-create_usr = sy-uname.
*        /psyng/swaudhdr-create_dat = sy-datum.
*        /psyng/swaudhdr-create_tim = sy-uzeit.
*        INSERT /psyng/swaudhdr.
*        IF sy-subrc = 0.
*          MESSAGE s120(/psyng/sw).  " Data Saved
*        ENDIF.
*      ENDIF.

      PERFORM get_editor_text.

      lt_texts-vrsio    = g_sod_vrsio.
      lt_texts-textname = /psyng/swaudhdr-swaudid.
      LOOP AT i_text.
        MOVE-CORRESPONDING i_text TO lt_texts.
        APPEND lt_texts.
      ENDLOOP.



*      DELETE FROM /psyng/texts
*                  WHERE textname = /psyng/swaudhdr-swaudid
*                  AND   object   = 'T'
*                  AND   vrsio    = g_sod_vrsio
*                  AND   spras    = sy-langu.
*
*      /psyng/texts-textname = /psyng/swaudc2-swaudid.
*      /psyng/texts-object   = 'T'.
*      /psyng/texts-spras    = sy-langu.
*      /psyng/texts-vrsio    = g_sod_vrsio.
*      LOOP AT i_text.
*        /psyng/texts-line = sy-tabix.
*        /psyng/texts-text = i_text-text.
*        INSERT /psyng/texts.
*      ENDLOOP.

*     Populate History
*      IF lf_ins_upd = 'U'.             "Update
*        PERFORM populate_history USING '/PSYNG/SWAUDC2' 'SWAUDID'
*                space /psyng/swaudc2-swaudid space 'U'.
*
*
*      ELSE.                            "Insert
*        PERFORM populate_history USING '/PSYNG/SWAUDC2' 'SWAUDID'
*                       space /psyng/swaudc2-swaudid space 'I'.
*
*
*      ENDIF.
**     End History

*     Check tcodes that need to be deleted from authorization objects
      SELECT * INTO TABLE lt_swaudc2 FROM /psyng/swaudc2
                      WHERE swaudid = /psyng/swaudc2-swaudid
                        AND vrsio   = g_sod_vrsio.

      LOOP AT lt_swaudc2.
        IF /psyng/swaudhdr-tcode <> lt_swaudc2-tcode.
*          DELETE FROM /psyng/swaudc2
*                      WHERE swaudid = /psyng/swaudc2-swaudid
*                        AND tcode   = lt_tcode-tcode
*                        AND vrsio   = g_sod_vrsio.
          DELETE lt_swaudc2.
        ENDIF.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
        EXPORTING
          wa_swaudid            = /psyng/swaudhdr
          i_vrsio               = g_sod_vrsio
*           IMPORTING
*         criauth_added         =
*         criauth_hdr_added     =
*         criauth_txt_added     =
*         criauth_objs_added    =
        TABLES
          texts                 = lt_texts
          swaudc2               = lt_swaudc2
*         history               =
        EXCEPTIONS
          target_not_specified  = 1
*         not_authorized        = 2
          authid_already_exists = 3
          OTHERS                = 4.
      IF sy-subrc = 0.
        MESSAGE s120(/psyng/sw).  " Data Saved
      ENDIF.


      CLEAR gf_data_change.
      first_time = gc_select.

    WHEN 'CREATE'.
*     PERFORM exit_without_save.
*     CHECK gf_answer = 1.

*  Clear parameter ID **
      SET PARAMETER ID '/PSYNG/SW_CRIT_AUTH' FIELD space.

*     Unlock AUDIT id
      AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
        ID 'ACTVT'      FIELD act_create
        ID 'Y&SW_AUTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
        ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        MESSAGE e108(/psyng/sw) WITH text-051 text-052.
      ENDIF.

      IF NOT /psyng/swaudc2-swaudid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/SWAUDHDR'
          EXPORTING
            swaudid = /psyng/swaudhdr-swaudid
            vrsio   = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'SWAUDHDR'.
      ENDIF.

      REFRESH i_text.
      CLEAR: /psyng/swaudc2, /psyng/swaudhdr,first_time,
             gf_data_change,g_editor_text[].

*   Critical authorization upload / download
    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_data_upload_download VIA SELECTION-SCREEN
              WITH sodvrsio  = g_sod_vrsio
*             WITH p_ttcode = gc_select
              WITH f_ct = ' '
              WITH f_ctxt = ' '
              WITH f_cr = ' '
              WITH f_crtxt = ' '
              WITH f_cp = ' '
              WITH f_cptxt = ' '
              WITH f_funh = ' '
              WITH f_fund = ' '
              WITH f_funt = ' '
              WITH f_objd = ' '
              WITH f_conh = ' '
              WITH f_cond = ' '
              WITH f_cont = ' '
              WITH f_cono = ' '
              WITH f_cah = 'X'
              WITH f_cad = 'X'
              WITH f_cat = 'X'
              AND RETURN.

*   Critical authorization overview
    WHEN 'CADET'.
      SUBMIT /psyng/sw_106 WITH p_vrsio = g_sod_vrsio AND RETURN.

*   Transport table entries
    WHEN 'TRANSPORT'.
      IF /psyng/swaudhdr-swaudid IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-010.
      ENDIF.

      lr_audid-sign = 'I'.
      lr_audid-option = 'EQ'.
      lr_audid-low = /psyng/swaudhdr-swaudid.
      APPEND lr_audid.

      SUBMIT /psyng/sw_048
      VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_taudid = gc_select
             WITH p_tvhead = gc_select
             WITH s_audid IN lr_audid
             AND RETURN.

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.

        PERFORM authority_check_cri_auth
*                USING sec_actvt /psyng/swaudc2-swaudid.
                USING act_change /psyng/swaudc2-swaudid.
        sec_actvt = act_change.

        gf_dispchg = gc_change.
        PERFORM check_version_editable.
        CHECK gf_dispchg = gc_change.

        IF NOT /psyng/swaudc2-swaudid IS INITIAL.
*             Lock AUDIT ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/SWAUDHDR'
            EXPORTING
              swaudid        = /psyng/swaudhdr-swaudid
              vrsio          = g_sod_vrsio
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ELSE.
            gt_locked-type   = 'SWAUDHDR'.
            gt_locked-object = /psyng/swaudhdr-swaudid.
            APPEND gt_locked.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM authority_check_cri_auth
                USING act_display /psyng/swaudc2-swaudid.
        sec_actvt = act_display.
        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.
        ok_code = 'ENTER'.
        PERFORM user_command_0209.

        gf_dispchg = gc_display.

*       Unlock function id
        IF NOT /psyng/swaudhdr-swaudid IS INITIAL.
          CALL FUNCTION 'DEQUEUE_/PSYNG/SWAUDHDR'
            EXPORTING
              swaudid = /psyng/swaudhdr-swaudid
              vrsio   = g_sod_vrsio.
          DELETE gt_locked WHERE type = 'SWAUDHDR'.
        ENDIF.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8' OR
         'SODFUN_FC1' OR 'SODFUN_FC2' OR 'SODFUN_FC4' OR 'SODFUN_FC5'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

      IF NOT /psyng/swaudhdr-swaudid IS INITIAL.
        CALL FUNCTION 'DEQUEUE_/PSYNG/SWAUDHDR'
          EXPORTING
            swaudid = /psyng/swaudhdr-swaudid
            vrsio   = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'SWAUDHDR'.
      ENDIF.

      CLEAR: first_time, gf_data_change, g_trans_itab, g_trans_itab[],
             /psyng/function, /psyng/functtran, i_text[], populated,
g_editor_text[].
    WHEN 'FS'.
      g_fullscreen = '0209'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
    WHEN 'SYSFLTR'.
      IF NOT /psyng/swaudc2-swaudid IS INITIAL.
        CALL SCREEN '0910'.
* B8620.
      ELSE.
        MESSAGE i106(/psyng/sw) WITH text-010.
* End.
      ENDIF.
  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.

ENDFORM.                    " user_command_0209
*&---------------------------------------------------------------------*
*&      Form  authority_check_function
*&---------------------------------------------------------------------*
FORM authority_check_function USING activity functionid.
  CHECK NOT activity IS INITIAL.

  IF NOT functionid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
             ID 'ACTVT'      FIELD activity
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
             ID 'Y&SW_FUNCT' FIELD functionid.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
             ID 'ACTVT'      FIELD activity
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
             ID 'Y&SW_FUNCT' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorizied for & & &
    IF NOT functionid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-004
                                   functionid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-141.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_function
*&---------------------------------------------------------------------*
*&      Form  authority_check_functtran
*&---------------------------------------------------------------------*
*       Function transaction
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM authority_check_functtran USING activity functionid tcode.

  CHECK ( NOT activity   IS INITIAL ) AND
        ( NOT functionid IS INITIAL ) AND
        ( NOT tcode      IS INITIAL ) .

*  AUTHORITY-CHECK OBJECT 'Y&SW_FUNC'
*           ID 'ACTVT'      FIELD activity
*           ID 'Y&SW_FUNCT' FIELD functionid
*           ID 'TCD'        FIELD tcode.

  IF sy-subrc NE 0.
    miss_auths = 'Y'.
    CASE activity.
*      WHEN '01'.
*        actvt_txt = 'creating'.
      WHEN '02'.
        actvt_txt = text-142.
*      WHEN '03'.
*        actvt_txt = 'displaying'.
*      WHEN '04'.
*        actvt_txt = 'printing'.
      WHEN '06'.
        actvt_txt = text-126.
*      WHEN '22'.
*        actvt_txt = 'assigning'.
*      WHEN 'DL'.
*        actvt_txt = 'downloading'.
*      WHEN 'UL'.
*        actvt_txt = 'uploading'.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
  ENDIF.

ENDFORM.                    " authority_check_functtran
*&---------------------------------------------------------------------*
*&      Form  authority_check_conflict_h
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM authority_check_conflict_h USING activity conid.
  CHECK NOT activity IS INITIAL.

  IF NOT conid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT'      FIELD activity
             ID 'Y&SW_CONID' FIELD conid
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
       ID 'ACTVT'      FIELD activity
       ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorizied for & & &
    IF NOT conid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-054
                                   conid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-053.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_conflict
*&---------------------------------------------------------------------*
*&      Form  authority_check_mc_assign
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SEC_ACTVT  text
*      -->P_/PSYNG/CONFDET_CONID  text
*----------------------------------------------------------------------*
FORM authority_check_mc_assign USING activity userid mcid conid vrsio.
  DATA : lt_uinfo  TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
         lf_failed TYPE flag.

  CHECK NOT activity IS INITIAL.
  IF gf_mit_asgn_auth_check = 'X'.
*-- Check new Auth Object
    IF ( NOT conid  IS INITIAL ) AND
       ( NOT mcid   IS INITIAL ) AND
       ( NOT userid IS INITIAL ) .
      lt_uinfo-bname =  userid.
      APPEND lt_uinfo. CLEAR lt_uinfo.
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
        EXPORTING
          vrsio        = vrsio
*         ENHANCED_SCANTABLE       = ''
          i_name_only  = 'X'
          i_mr_company = 'X'
        TABLES
          sw_uinfo     = lt_uinfo.
      READ TABLE lt_uinfo INDEX 1.
      IF NOT lt_uinfo-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
          ID 'ACTVT'      FIELD activity
          ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_VRSIO' FIELD vrsio
          ID 'Y&SW_CNTID' FIELD mcid
          ID 'Y&SW_CONID' FIELD conid
          ID 'Y&SW_BNAME' FIELD userid
          ID 'Y&SW_COMP'  FIELD lt_uinfo-company.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
          ID 'ACTVT'      FIELD activity
          ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_VRSIO' FIELD vrsio
          ID 'Y&SW_CNTID' FIELD mcid
          ID 'Y&SW_CONID' FIELD conid
          ID 'Y&SW_BNAME' FIELD userid
          ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.
      ENDIF.

      IF NOT lt_uinfo-class IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
           ID 'ACTVT'      FIELD activity
           ID 'CLASS'      FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_CNTID' FIELD mcid
           ID 'Y&SW_CONID' FIELD conid
           ID 'Y&SW_BNAME' FIELD userid
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
           ID 'ACTVT'      FIELD activity
           ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_CNTID' FIELD mcid
           ID 'Y&SW_CONID' FIELD conid
           ID 'Y&SW_BNAME' FIELD userid
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      IF vrsio = space.
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
           ID 'ACTVT'      FIELD activity
           ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
           ID 'ACTVT'      FIELD activity
           ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
    IF ( NOT conid  IS INITIAL ) AND
        ( NOT mcid   IS INITIAL ) AND
        ( NOT userid IS INITIAL ) .
      lt_uinfo-bname =  userid.
      APPEND lt_uinfo. CLEAR lt_uinfo.
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
        EXPORTING
          vrsio        = vrsio
          i_name_only  = 'X'
          i_mr_company = 'X'
        TABLES
          sw_uinfo     = lt_uinfo.
      READ TABLE lt_uinfo INDEX 1.
      IF NOT lt_uinfo-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
                 ID 'ACTVT'      FIELD activity
                 ID 'Y&SW_VRSIO' FIELD vrsio
                 ID 'Y&SW_CNTID' FIELD mcid
                 ID 'Y&SW_CONID' FIELD conid
                 ID 'Y&SW_BNAME' FIELD userid
                 ID 'Y&SW_COMP'  FIELD lt_uinfo-company.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
           ID 'ACTVT'      FIELD activity
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_CNTID' FIELD mcid
           ID 'Y&SW_CONID' FIELD conid
           ID 'Y&SW_BNAME' FIELD userid
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ENDIF.
    ELSE.
      IF vrsio = space.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
           ID 'ACTVT'      FIELD activity
           ID 'Y&SW_VRSIO' FIELD ''
           ID 'Y&SW_CNTID' FIELD ''
           ID 'Y&SW_CONID' FIELD ''
           ID 'Y&SW_BNAME' FIELD ''
           ID 'Y&SW_COMP'  FIELD ''.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
           ID 'ACTVT'      FIELD activity
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_CNTID' FIELD ''
           ID 'Y&SW_CONID' FIELD ''
           ID 'Y&SW_BNAME' FIELD ''
           ID 'Y&SW_COMP'  FIELD ''.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF lf_failed = 'X'.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorized for & & &
    IF NOT conid IS INITIAL AND NOT mcid IS INITIAL AND
    NOT userid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt userid conid mcid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-055.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_mc_assign

*&---------------------------------------------------------------------*
*&      Form  AUTHORITY_CHECK_MC_ASSIGN_GRP
*&---------------------------------------------------------------------*
*       Check authority for Mitigating Controls user group assignment
*----------------------------------------------------------------------*
*      -->I_ACTVT   Activity
*      -->I_CLASS   User Group
*      -->I_CONTID  Mitigating Control ID
*      -->I_CONID   SOD Conflict ID
*----------------------------------------------------------------------*
FORM authority_check_mc_assign_grp USING
                                    i_actvt
                                    i_class  TYPE /psyng/mcusrgrp-class
                                    i_contid TYPE /psyng/mcusrgrp-contid
                                    i_conid  TYPE /psyng/mcusrgrp-conid
                                    i_vrsio  TYPE /psyng/mcusrgrp-vrsio.
  DATA : lf_failed TYPE flag.
  CHECK NOT i_actvt IS INITIAL.

  IF ( NOT i_conid  IS INITIAL ) AND
     ( NOT i_contid IS INITIAL ) AND
     ( NOT i_class  IS INITIAL ).

    AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
             ID 'ACTVT' FIELD i_actvt
             ID 'Y&SW_VRSIO' FIELD i_vrsio
             ID 'Y&SW_CNTID' FIELD i_contid
             ID 'Y&SW_CONID' FIELD i_conid
             ID 'Y&SW_CLASS' FIELD i_class.
    IF sy-subrc <> 0.
      lf_failed = 'X'.
    ENDIF.

  ELSE.
    IF i_vrsio IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
         ID 'ACTVT' FIELD i_actvt
         ID 'Y&SW_VRSIO' FIELD ''
         ID 'Y&SW_CNTID' FIELD ''
         ID 'Y&SW_CONID' FIELD ''
         ID 'Y&SW_CLASS' FIELD ''.
      IF sy-subrc <> 0.
        lf_failed = 'X'.
      ENDIF.

    ELSE.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCUG'
         ID 'ACTVT' FIELD i_actvt
         ID 'Y&SW_VRSIO' FIELD i_vrsio
         ID 'Y&SW_CNTID' FIELD ''
         ID 'Y&SW_CONID' FIELD ''
         ID 'Y&SW_CLASS' FIELD ''.
      IF sy-subrc <> 0.
        lf_failed = 'X'.
      ENDIF.

    ENDIF.
  ENDIF.

  IF lf_failed = 'X'.
    CASE i_actvt.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorized for & & &
    IF NOT i_conid IS INITIAL AND NOT i_contid IS INITIAL AND
    NOT i_class IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt i_class i_conid i_contid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-055.
    ENDIF.
  ENDIF.
ENDFORM.                    " authority_check_mc_assign_grp

*&---------------------------------------------------------------------*
*&      Form  AUTHORITY_CHECK_MC_ASSIGN_role
*&---------------------------------------------------------------------*
*       Check authority for Mitigating Controls role assignment
*----------------------------------------------------------------------*
*      -->I_ACTVT     Activity
*      -->I_AGR_NAME  Role
*      -->I_CONTID    Mitigating Control ID
*      -->I_CONID     SOD Conflict ID
*----------------------------------------------------------------------*
FORM authority_check_mc_assign_role USING
                                    i_actvt
                                    i_role TYPE /psyng/mcrole-agr_name
                                    i_contid TYPE /psyng/mcrole-contid
                                    i_conid  TYPE /psyng/mcrole-conid
                                    i_vrsio.  "untyped: allow for space

  CHECK NOT i_actvt IS INITIAL.

  IF ( NOT i_conid  IS INITIAL ) AND
     ( NOT i_contid IS INITIAL ) AND
     ( NOT i_role   IS INITIAL ).

    AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
             ID 'ACTVT' FIELD i_actvt
             ID 'Y&SW_VRSIO' FIELD i_vrsio
             ID 'Y&SW_CNTID' FIELD i_contid
             ID 'Y&SW_CONID' FIELD i_conid
             ID 'ACT_GROUP'  FIELD i_role.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    IF i_vrsio IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
         ID 'ACTVT' FIELD i_actvt
         ID 'Y&SW_VRSIO' FIELD ''
         ID 'Y&SW_CNTID' FIELD ''
         ID 'Y&SW_CONID' FIELD ''
         ID 'ACT_GROUP'  FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
    ELSE.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCROL'
         ID 'ACTVT' FIELD i_actvt
         ID 'Y&SW_VRSIO' FIELD i_vrsio
         ID 'Y&SW_CNTID' FIELD ''
         ID 'Y&SW_CONID' FIELD ''
         ID 'ACT_GROUP'  FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
    ENDIF.
  ENDIF.

  IF sy-subrc NE 0.
    CASE i_actvt.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorized for & & &
    IF NOT i_conid IS INITIAL AND NOT i_contid IS INITIAL AND
    NOT i_role IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt i_role i_conid i_contid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-055.
    ENDIF.
  ENDIF.
ENDFORM.                    " authority_check_mc_assign_role

*&---------------------------------------------------------------------*
*&      Form  authority_check_mc_h
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ACTIVITY  text
*      -->MCID      text
*----------------------------------------------------------------------*
FORM authority_check_mc_h USING    activity
                                   mcid.

  CHECK NOT activity IS INITIAL.
  IF NOT mcid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
      ID 'ACTVT'      FIELD activity
      ID 'Y&SW_CNTID' FIELD mcid
      ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
       ID 'ACTVT'      FIELD activity
       ID 'Y&SW_CNTID' FIELD ''
       ID 'Y&SW_VRSIO' FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorizied for & & &
    IF NOT mcid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt mcid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-055.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_mc_h
*&---------------------------------------------------------------------*
*&      Form  authority_check_cri_auth
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SEC_ACTVT  text
*      -->P_/PSYNG/SWAUDC_SWAUDID  text
*----------------------------------------------------------------------*
FORM authority_check_cri_auth USING    activity
                                       swaudid.
  CHECK NOT activity IS INITIAL.

  IF NOT swaudid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
             ID 'ACTVT'      FIELD activity
             ID 'Y&SW_AUTID' FIELD swaudid
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
             ID 'ACTVT'      FIELD activity
             ID 'Y&SW_AUTID' FIELD ''
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorizied for & & &
    IF NOT swaudid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-010
                                   swaudid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-056.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_cri_auth
*&---------------------------------------------------------------------*
*&      Form  replace_tcodes_of_pfcg_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM replace_tcodes_of_pfcg_role.
  CLEAR gf_answer.
  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
    EXPORTING
      defaultoption     = '1'
      diagnosetext1     = text-058
      diagnosetext2     = text-059
      textline1         = text-060
      text_option1      = text-143
      text_option2      = text-144
      icon_text_option1 = 'ICON_INCOMING_TASK'
      icon_text_option2 = 'ICON_OUTGOING_TASK'
      titel             = text-060
      cancel_display    = 'X'
    IMPORTING
      answer            = gf_answer.

  CASE gf_answer.
    WHEN '1'.
      PERFORM change_local_pfcg_role.
    WHEN '2'.
      PERFORM change_remote_pfcg_role.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " change_tcodes_of_pfcg_role
*&---------------------------------------------------------------------*
*&      Form  change_local_pfcg_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM change_local_pfcg_role.

  CALL FUNCTION 'PRGN_RFC_CHANGE_TRANSACTIONS'   "#EC SAST_CI_GEN_CHECK
    EXPORTING
      activity_group                = /psyng/rolehdr-saptechname
*     NO_CHECK_ON_TCODES            = ' '
    TABLES
      tcodes                        = itcodes
*     HIERARCHY_NODES               =
*     HIERARCHY_TEXTS               =
    EXCEPTIONS
      activity_group_enqueued       = 1
      activity_group_does_not_exist = 2
      namespace_problem             = 3
      tcodes_inherited_from_parent  = 4
      illegal_tcodes                = 5
      not_authorized                = 6
      OTHERS                        = 7.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e208(00) WITH text-061.
      WHEN 2.
        MESSAGE e208(00) WITH text-062.
      WHEN 3.
        MESSAGE e208(00) WITH text-063.
      WHEN 4.
        MESSAGE e208(00) WITH text-064.
      WHEN 5.
        MESSAGE e208(00) WITH text-065.
      WHEN 6.
        MESSAGE e208(00) WITH text-066.
      WHEN 7.
        MESSAGE e208(00) WITH text-067.
    ENDCASE.
  ELSE.
    MESSAGE i208(00) WITH text-068.
  ENDIF.

ENDFORM.                    " change_local_pfcg_role
*&---------------------------------------------------------------------*
*&      Form  change_remote_pfcg_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM change_remote_pfcg_role.
  DATA: dflt_rfc LIKE /psyng/swconfig-value.

  CLEAR: ifields.
  REFRESH: ifields.

  se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
  IF ifields[] IS INITIAL.
    ifields-tabname = 'RFCDES'.
    ifields-fieldname = 'RFCDEST'.
    ifields-fieldtext = text-145.
    IF NOT dflt_rfc IS INITIAL.
      ifields-value = dflt_rfc.
    ENDIF.
    APPEND ifields.
  ENDIF.

  CLEAR userresponse.
  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
      programname       = '/PSYNG/SODREPORT_ORG'
      popup_title       = text-069
      ok_pushbuttontext = text-146
    IMPORTING
      returncode        = userresponse
    TABLES
      fields            = ifields
    EXCEPTIONS
      error_in_fields   = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-070.
  ENDIF.

  CHECK userresponse NE 'A'.                     "#EC SAST_CI_GEN_CHECK
  "check to see user doesn't abort

  READ TABLE ifields WITH KEY tabname = 'RFCDES'
                              fieldname = 'RFCDEST'.

  IF ifields-value IS INITIAL.
    MESSAGE w208(00) WITH text-071  .
  ENDIF.
  SELECT SINGLE * FROM rfcdes
                  INTO irfcdes
                  WHERE rfcdest = ifields-value AND
                        rfctype = '3'.
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
    CALL FUNCTION 'PRGN_CHECK_ROLE_EXISTS'
      DESTINATION ifields-value
      EXPORTING
        role_name           = /psyng/rolehdr-saptechname
      EXCEPTIONS
        role_does_not_exist = 1
        OTHERS              = 2.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN '1'.
          CLEAR pertext.
          CONCATENATE text-147 /psyng/rolehdr-saptechname
                      text-148 ifields-value
                      INTO pertext SEPARATED BY   space.
          MESSAGE i208(00) WITH pertext.
        WHEN '2'.
          MESSAGE i208(00) WITH text-072.
        WHEN OTHERS.
      ENDCASE.
      EXIT.
    ENDIF.
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
    CALL FUNCTION 'PRGN_RFC_CHANGE_TRANSACTIONS'
      DESTINATION ifields-value
      EXPORTING
        activity_group                = /psyng/rolehdr-saptechname
      TABLES
        tcodes                        = itcodes
      EXCEPTIONS
        activity_group_enqueued       = 1
        activity_group_does_not_exist = 2
        namespace_problem             = 3
        tcodes_inherited_from_parent  = 4
        illegal_tcodes                = 5
        not_authorized                = 6
        OTHERS                        = 7.       "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE e208(00) WITH text-061  .
        WHEN 2.
          MESSAGE e208(00) WITH text-062  .
        WHEN 3.
          MESSAGE e208(00) WITH text-063.
        WHEN 4.
          MESSAGE e208(00) WITH text-064.
        WHEN 5.
          MESSAGE e208(00) WITH text-065.
        WHEN 6.
          MESSAGE e208(00) WITH text-066.
        WHEN 7.
          MESSAGE e208(00) WITH text-067.
      ENDCASE.
    ELSE.
      MESSAGE i208(00) WITH text-068.
    ENDIF.

  ELSE.   "RFC destination does not exist
    CLEAR pertext.
    CONCATENATE text-145 ifields-value text-148
                INTO pertext SEPARATED BY space.
    MESSAGE i208(00) WITH pertext.
  ENDIF.

ENDFORM.                    " change_remote_pfcg_role
*&---------------------------------------------------------------------*
*&      Form  generate_pfcg_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM generate_pfcg_role.
  CLEAR agr_desc.
  IF /psyng/rolehdr-description IS INITIAL.
    agr_desc = text-149.
  ELSE.
    MOVE /psyng/rolehdr-description TO agr_desc.
  ENDIF.

  REFRESH: itcodes.  CLEAR: itcodes.
  SELECT tcode FROM /psyng/roletrans INTO itcodes-tcode
         WHERE roleid = /psyng/rolehdr-roleid.
    APPEND itcodes.
  ENDSELECT.

  CLEAR: today, comment1, comment2.
  WRITE sy-datum TO today.
  MOVE today TO c_today.
  CONCATENATE c_today text-150
              /psyng/roletrans-roleid INTO comment1
              SEPARATED BY space.
  CONCATENATE text-151 text-152 INTO comment2
              SEPARATED BY space.

  CLEAR gf_answer.
  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
    EXPORTING
      defaultoption     = '1'
      diagnosetext1     = text-074
      diagnosetext2     = text-059
      textline1         = text-075
      text_option1      = text-143
      text_option2      = text-144
      icon_text_option1 = 'ICON_INCOMING_TASK'
      icon_text_option2 = 'ICON_OUTGOING_TASK'
      titel             = text-202
      cancel_display    = 'X'
    IMPORTING
      answer            = gf_answer.

  CASE gf_answer.
    WHEN '1'.
      PERFORM create_local_pfcg_role.
      PERFORM popup_changed_role USING text-040.
    WHEN '2'.
      PERFORM create_remote_pfcg_role.
      PERFORM popup_changed_role USING text-040.

    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " generate_pfcg_role
*&---------------------------------------------------------------------*
*&      Form  create_local_pfcg_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_local_pfcg_role.

  CALL FUNCTION 'PRGN_RFC_CREATE_ACTIVITY_GROUP' "#EC SAST_CI_GEN_CHECK
    EXPORTING
      activity_group                = /psyng/rolehdr-saptechname
      activity_group_text           = agr_desc
      comment_text_line_1           = comment1
      comment_text_line_2           = comment2
      org_levels_with_star          = ' '
      unmaintained_fields_with_star = ' '
      template                      = ' '
* The line below was commented to be compatible w/all versions of SAP
*    no_check_on_tcodes            = 'X'
    TABLES
      tcodes                        = itcodes
    EXCEPTIONS
      activity_group_already_exists = 1
      activity_group_enqueued       = 2
      namespace_problem             = 3
      illegal_characters            = 4
      error_when_creating_actgroup  = 5
      profile_name_exists           = 6
      profile_not_in_namespace      = 7
      no_tcodes_selected            = 8
      illegal_tcodes                = 9
      not_authorized                = 10
      profgen_tables_not_updated    = 11
      error_when_generating_profile = 12
      OTHERS                        = 13.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e208(00) WITH text-076.
      WHEN 2.
        MESSAGE e208(00) WITH text-061.
      WHEN 3.
        MESSAGE e208(00) WITH text-063.
      WHEN 4.
        MESSAGE e208(00) WITH text-077.
      WHEN 5.
        MESSAGE e208(00) WITH text-078.
      WHEN 6.
        MESSAGE e208(00) WITH text-079.
      WHEN 7.
        MESSAGE e208(00) WITH text-080.
      WHEN 8.
        MESSAGE e208(00) WITH text-081.
      WHEN 9.
        MESSAGE e208(00) WITH text-153.
      WHEN 10.
        MESSAGE e208(00) WITH text-066.
      WHEN 11.
        MESSAGE e208(00) WITH text-082.
      WHEN 12.
        MESSAGE e208(00) WITH text-083.
      WHEN 13.
        MESSAGE e208(00) WITH text-067.
    ENDCASE.
  ELSE.
    MESSAGE i208(00) WITH text-084.
  ENDIF.

ENDFORM.                    " create_local_pfcg_role
*&---------------------------------------------------------------------*
*&      Form  create_remote_pfcg_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_remote_pfcg_role.

  DATA: userresponse, dflt_rfc LIKE /psyng/swconfig-value.

  CLEAR: ifields.
  REFRESH: ifields.

  se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
  IF ifields[] IS INITIAL.
    ifields-tabname = 'RFCDES'.
    ifields-fieldname = 'RFCDEST'.
    ifields-fieldtext = text-145.
    IF NOT dflt_rfc IS INITIAL.
      ifields-value = dflt_rfc.
    ENDIF.
    APPEND ifields.
  ENDIF.

  CLEAR userresponse.
  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
      programname       = '/PSYNG/SODREPORT_ORG'
      popup_title       = text-069
      ok_pushbuttontext = text-146
    IMPORTING
      returncode        = userresponse
    TABLES
      fields            = ifields
    EXCEPTIONS
      error_in_fields   = 1
      OTHERS            = 2.
  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-070.
  ENDIF.

  CHECK userresponse NE 'A'.                     "#EC SAST_CI_GEN_CHECK
  "check to see user doesn't abort

  READ TABLE ifields WITH KEY tabname = 'RFCDES'
                              fieldname = 'RFCDEST'.

  IF ifields-value IS INITIAL.
    MESSAGE w208(00) WITH text-071.
  ENDIF.
  SELECT SINGLE * FROM rfcdes
                  INTO irfcdes
                  WHERE rfcdest = ifields-value AND
                        rfctype = '3'.
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
    CALL FUNCTION 'PRGN_RFC_CREATE_ACTIVITY_GROUP'
      DESTINATION ifields-value
      EXPORTING
        activity_group                = /psyng/rolehdr-saptechname
        activity_group_text           = agr_desc
        comment_text_line_1           = comment1
        comment_text_line_2           = comment2
        org_levels_with_star          = ' '
        unmaintained_fields_with_star = ' '
        template                      = ' '
      TABLES
        tcodes                        = itcodes
      EXCEPTIONS
        activity_group_already_exists = 1
        activity_group_enqueued       = 2
        namespace_problem             = 3
        illegal_characters            = 4
        error_when_creating_actgroup  = 5
        profile_name_exists           = 6
        profile_not_in_namespace      = 7
        no_tcodes_selected            = 8
        illegal_tcodes                = 9
        not_authorized                = 10
        profgen_tables_not_updated    = 11
        error_when_generating_profile = 12
        OTHERS                        = 13.      "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE e208(00) WITH text-076.
        WHEN 2.
          MESSAGE e208(00) WITH text-061.
        WHEN 3.
          MESSAGE e208(00) WITH text-063.
        WHEN 4.
          MESSAGE e208(00) WITH text-077  .
        WHEN 5.
          MESSAGE e208(00) WITH text-078.
        WHEN 6.
          MESSAGE e208(00) WITH text-079.
        WHEN 7.
          MESSAGE e208(00) WITH text-080  .
        WHEN 8.
          MESSAGE e208(00) WITH text-081.
        WHEN 9.
          MESSAGE e208(00) WITH text-153.
        WHEN 10.
          MESSAGE e208(00) WITH text-066.
        WHEN 11.
          MESSAGE e208(00) WITH text-082.
        WHEN 12.
          MESSAGE e208(00) WITH text-083.
        WHEN 13.
          MESSAGE e208(00) WITH text-067.
      ENDCASE.
    ELSE.
      MESSAGE i208(00) WITH text-084.
    ENDIF.

  ELSE.
    CLEAR pertext.
    CONCATENATE text-145 ifields-value text-154
                INTO pertext SEPARATED BY space.
    MESSAGE e208(00) WITH pertext.
  ENDIF.



ENDFORM.                    " create_remote_pfcg_role
*&---------------------------------------------------------------------*
*&      Form  COPY_ROLE_ID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM copy_role_id.

  DATA: roleid_exists, rolecopied, rolehdr, roletc, roletxt.
  DATA: targetid TYPE /psyng/rolehdr-roleid.

  CLEAR: ifields.
  REFRESH: ifields.

  IF ifields[] IS INITIAL.
    ifields-tabname = '/PSYNG/ROLEHDR'.
    ifields-fieldname = 'ROLEID'.
    ifields-fieldtext = text-085.
    APPEND ifields.
  ENDIF.

  CLEAR userresponse.
  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
*     F4_FORMNAME       = ' '
*     F4_PROGRAMNAME    = ' '
      formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
      programname       = '/PSYNG/SODREPORT_ORG'
      popup_title       = text-086
      ok_pushbuttontext = text-146
*     ICON_OK_PUSH      = 'ICON_OKAY'
*     QUICKINFO_OK_PUSH = ' '
*     FIRST_PUSHBUTTON  = ' '
*     ICON_BUTTON_1     =
*     QUICKINFO_BUTTON_1              = ' '
*     SECOND_PUSHBUTTON = ' '
*     ICON_BUTTON_2     =
*     QUICKINFO_BUTTON_2              = ' '
*     START_COLUMN      = '5'
*     START_ROW         = '5'
*     NO_CHECK_FOR_FIXED_VALUES       = ' '
    IMPORTING
      returncode        = userresponse
    TABLES
      fields            = ifields
    EXCEPTIONS
      error_in_fields   = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-070.
  ENDIF.

  CHECK userresponse NE 'A'.                     "#EC SAST_CI_GEN_CHECK
  "check to see user doesn't abort

  READ TABLE ifields WITH KEY tabname = '/PSYNG/ROLEHDR'
                              fieldname = 'ROLEID'.

  IF ifields-value IS INITIAL.
    MESSAGE e208(00) WITH text-086.
  ENDIF.

  MOVE ifields-value TO targetid.

  CALL FUNCTION '/PSYNG/SW_CHECK_SWROLE_EXISTS'
    EXPORTING
      proleid = targetid
    IMPORTING
      exists  = roleid_exists.

  IF roleid_exists EQ 'Y'.
    MESSAGE e208(00) WITH text-087.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_COPY_SW_ROLE_ID'
    EXPORTING
      from_roleid                  = /psyng/rolehdr-roleid
      to_roleid                    = targetid
    IMPORTING
      roleid_copied                = rolecopied
      role_hdr_copied              = rolehdr
      role_tc_copied               = roletc
      role_txt_copied              = roletxt
    EXCEPTIONS
      target_roleid_already_exists = 1
      not_authorized               = 2
      OTHERS                       = 3.

  CASE sy-subrc.
    WHEN 0.
      MESSAGE i208(00) WITH text-088.
    WHEN 1.
      MESSAGE e208(00) WITH text-087.
    WHEN 2.
      MESSAGE e208(00) WITH text-066.
    WHEN 3.
      MESSAGE e208(00) WITH text-067.
    WHEN OTHERS.
      MESSAGE e208(00) WITH text-067.
  ENDCASE.

  REFRESH: ifields.
  CLEAR: ifields.
ENDFORM.                    " COPY_ROLE_ID

*&---------------------------------------------------------------------*
*&      Module  FILL_AUTH_AGAIN  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fill_auth_again OUTPUT.
  exelog sy-repid 'Tab Critical Auths'.
  IF /psyng/swaudc2-swaudid <> space AND eaobj_flag = 'X'.
    eaobj_flag = space.
    SELECT SINGLE * FROM /psyng/swaudhdr INTO /psyng/swaudhdr
    WHERE swaudid  = /psyng/swaudc2-swaudid
      AND vrsio    = g_sod_vrsio.

    IF sy-subrc = 0.
      SELECT line text INTO CORRESPONDING FIELDS OF
      TABLE i_text FROM /psyng/texts
      WHERE textname = /psyng/swaudc2-swaudid
      AND   object   = 'T'
      AND   spras    = sy-langu
      AND   vrsio    = g_sod_vrsio
      ORDER BY line.
    ENDIF.
  ENDIF.

ENDMODULE.                 " FILL_AUTH_AGAIN  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  authority_check_roleid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM authority_check_roleid  USING activity roleid.

  CHECK NOT activity IS INITIAL.
  IF NOT roleid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
             ID 'ACTVT' FIELD activity
             ID 'Y&SW_ROLID' FIELD roleid.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
       ID 'ACTVT' FIELD activity
       ID 'Y&SW_ROLID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140  .
      WHEN '60'.
        actvt_txt = text-155.
      WHEN '61'.
        actvt_txt = text-156.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.

    IF NOT roleid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-090 roleid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-089.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_roleid
*&---------------------------------------------------------------------*
*&      Form  authority_check_positionid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM authority_check_positionid USING activity positionid.

  CHECK NOT activity IS INITIAL.

  IF NOT positionid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
             ID 'ACTVT' FIELD activity
             ID 'Y&SW_POSID' FIELD positionid.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_POSH'
       ID 'ACTVT' FIELD activity
       ID 'Y&SW_POSID' FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN '60'.
        actvt_txt = text-155.
      WHEN '61'.
        actvt_txt = text-156.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.

    IF NOT positionid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-007
                                   positionid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-157.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_positionid
*&---------------------------------------------------------------------*
*&      Form  copy_function_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM copy_function_id.
  DATA: funcopied, funhdr, funtc, funtxt.
  DATA: targetid          TYPE /psyng/function-function,
        l_skip_auth_check TYPE flag.

  REFRESH: ifields.  CLEAR ifields.
  ifields-tabname = '/PSYNG/FUNCTION'.
  ifields-fieldname = 'FUNCTION'.
  ifields-fieldtext = 'Target Function ID'(200).
  APPEND ifields.


  CLEAR userresponse.
  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
      programname       = '/PSYNG/SODREPORT_ORG'
      popup_title       = text-091
      ok_pushbuttontext = text-146
    IMPORTING
      returncode        = userresponse
    TABLES
      fields            = ifields
    EXCEPTIONS
      error_in_fields   = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-070.
  ENDIF.
  "check to see user doesn't abort
  CHECK userresponse NE 'A'.                     "#EC SAST_CI_GEN_CHECK


  READ TABLE ifields WITH KEY tabname = '/PSYNG/FUNCTION'
                              fieldname = 'FUNCTION'.

  IF ifields-value IS INITIAL.
    MESSAGE e208(00) WITH text-091.
  ENDIF.

  MOVE ifields-value TO targetid.

*IF gf_dispchg = gc_display.
*  l_skip_auth_check = 'X'.
*  endif.

  CALL FUNCTION '/PSYNG/SW_CR_COPY_FUNCTIONID'
    EXPORTING
      sourcefunctionid             = /psyng/function-function
      targetfunctionid             = targetid
      i_vrsio                      = g_sod_vrsio
*     I_COPY_DISPLAY_MODE          = l_skip_auth_check
    IMPORTING
      funid_copied                 = funcopied
      funid_hdr_copied             = funhdr
      funid_tc_copied              = funtc
      funid_txt_copied             = funtxt
    EXCEPTIONS
      target_not_specified         = 1
      not_authorized               = 2
      target_already_exists        = 3
      source_function_doesnt_exist = 4
      not_authorized_to_display    = 5
      OTHERS                       = 6.


  CASE sy-subrc.
    WHEN 0.
      MESSAGE i208(00) WITH text-092.
    WHEN 1.
      MESSAGE e208(00) WITH text-093.
    WHEN 2.
      MESSAGE e208(00) WITH text-094.
    WHEN 3.
      MESSAGE e208(00) WITH text-095.
    WHEN 4.
      MESSAGE e208(00) WITH text-096.
    WHEN 5.
      MESSAGE e208(00) WITH text-097  .
    WHEN OTHERS.
      MESSAGE e208(00) WITH text-067.
  ENDCASE.
  CLEAR l_skip_auth_check.
ENDFORM.                    " copy_function_id
*&---------------------------------------------------------------------*
*&      Form  copy_conflict_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM copy_conflict_id.
  DATA: concopied, conhdr, contc, contxt.
  DATA: targetid          TYPE /psyng/conflict-conid,
        l_skip_auth_check TYPE flag.

  REFRESH: ifields.  CLEAR ifields.
  ifields-tabname = '/PSYNG/CONFLICT'.
  ifields-fieldname = 'CONID'.
  ifields-fieldtext = text-158.
  APPEND ifields.


  CLEAR userresponse.
  CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
    EXPORTING
      formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
      programname       = '/PSYNG/SODREPORT_ORG'
      popup_title       = text-098
      ok_pushbuttontext = text-146
    IMPORTING
      returncode        = userresponse
    TABLES
      fields            = ifields
    EXCEPTIONS
      error_in_fields   = 1
      OTHERS            = 2.

  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-070.
  ENDIF.
  "check to see user doesn't abort
  CHECK userresponse NE 'A'.                     "#EC SAST_CI_GEN_CHECK

  READ TABLE ifields WITH KEY tabname = '/PSYNG/CONFLICT'
                              fieldname = 'CONID'.

  IF ifields-value IS INITIAL.
    MESSAGE e208(00) WITH text-098.
  ENDIF.

  MOVE ifields-value TO targetid.

*IF gf_dispchg = gc_display.
*l_skip_auth_check = 'X'.
*endif.

  CALL FUNCTION '/PSYNG/SW_CR_COPY_CONFLICTID'
    EXPORTING
      sourceconflictid             = /psyng/conflict-conid
      targetconflictid             = targetid
      i_vrsio                      = g_sod_vrsio
*     L_COPY_DISPLAY_MODE          = l_skip_auth_check
    IMPORTING
      conid_copied                 = concopied
      conid_hdr_copied             = conhdr
      conid_tc_copied              = contc
      conid_txt_copied             = contxt
    EXCEPTIONS
      target_not_specified         = 1
      target_already_exists        = 2
      not_authorized               = 3
      source_conflict_doesnt_exist = 4
      not_authorized_to_display    = 5
      dependent_funid_doesnt_exist = 6
      OTHERS                       = 7.

  CASE sy-subrc.
    WHEN 0.
      MESSAGE i208(00) WITH text-099.
    WHEN 1.
      MESSAGE e208(00) WITH text-100.
    WHEN 2.
      MESSAGE e208(00) WITH text-101.
    WHEN 3.
      MESSAGE e208(00) WITH text-066.
    WHEN 4.
      MESSAGE e208(00) WITH text-102.
    WHEN 5.
      MESSAGE e208(00) WITH text-103.
    WHEN 6.
      MESSAGE e208(00) WITH text-104.
    WHEN OTHERS.
      MESSAGE e208(00) WITH text-067.
  ENDCASE.

ENDFORM.                    " copy_conflict_id

*&---------------------------------------------------------------------*
*&      Form  retain_history
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM retain_history USING i_status
                          i_contid
                          i_conid
                          i_userid
                          i_auditor
                          i_fromdate
                          i_todate
                          i_vrsio.
*--DHORIONS 20110309 - The history is recorded by function module
* /PSYNG/SW_006, which is always used to store mitigation assignments
*  /psyng/tsw_hst-vrsio    = i_vrsio.
*  /psyng/tsw_hst-changeby = sy-uname.
*  /psyng/tsw_hst-changedate = crt_dte.
*  /psyng/tsw_hst-changetime = crt_tme.
*  /psyng/tsw_hst-action = i_status.
*  /psyng/tsw_hst-contid = i_contid.
*  /psyng/tsw_hst-conid = i_conid.
*  /psyng/tsw_hst-userid = i_userid.
*  /psyng/tsw_hst-auditor = i_auditor.
*  /psyng/tsw_hst-from_date = i_fromdate.
*  /psyng/tsw_hst-to_date = i_todate.
*  INSERT /psyng/tsw_hst.
*  CLEAR /psyng/tsw_hst.
ENDFORM.                    "retain_history

*&---------------------------------------------------------------------*
*&      Form  obj_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM  obj_check.
  DATA : i TYPE i.
  DATA : l_agrtcode TYPE STANDARD TABLE OF agr_tcodes
              WITH HEADER LINE.
  DATA : BEGIN OF l_tcode1 OCCURS 0,
           tcode LIKE /psyng/roletrans-tcode,
         END OF l_tcode1.
  DATA : BEGIN OF l_tcode2 OCCURS 0,
           tcode LIKE /psyng/roletrans-tcode,
         END OF l_tcode2.
  REFRESH : l_agrtcode, l_tcode1, l_tcode2.
  CLEAR : l_agrtcode, l_tcode1, l_tcode2.
  SELECT SINGLE * FROM /psyng/rolehdr
      WHERE roleid = /psyng/roletrans-roleid.
  IF sy-subrc = 0.
    SELECT * FROM /psyng/roletrans
           WHERE roleid = /psyng/roletrans-roleid.
      l_tcode1-tcode = /psyng/roletrans-tcode.
      APPEND l_tcode1.
    ENDSELECT.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_POPULATE_S_TCODE'
    EXPORTING
      p_agrname   = /psyng/rolehdr-saptechname
    TABLES
      iagr_tcodes = l_agrtcode.

  LOOP AT l_agrtcode.
    l_tcode2-tcode = l_agrtcode-tcode.
    APPEND l_tcode2.
  ENDLOOP.

  i = 0.
  LOOP AT l_tcode1.
    READ TABLE l_tcode2 WITH KEY tcode = l_tcode1-tcode.
    IF sy-subrc = 0.
      i = i + 1.

    ELSEIF sy-subrc <> 0.
      CALL FUNCTION 'POPUP_TO_INFORM' "Continue prog after info
        EXPORTING
          titel = text-013
          txt1  = text-014
          txt2  = text-015.


      EXIT.
    ENDIF.
  ENDLOOP.

  CLEAR : l_agrtcode, l_tcode1, l_tcode2.

**ENDIF.
ENDFORM.                              "OBJ_CHECK
*&---------------------------------------------------------------------*
*&      Form  objcheck_pos
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM objcheck_pos.
  DATA: lt_sw_roles   TYPE TABLE OF /psyng/roles3,
        lt_pfcg_roles TYPE TABLE OF /psyng/roles3.


  REFRESH gt_roles.

  CALL FUNCTION '/PSYNG/SW_039'
    EXPORTING
      i_positionid  = /psyng/posndet-positionid
    TABLES
      et_all_roles  = gt_roles
      et_sw_roles   = lt_sw_roles
      et_pfcg_roles = lt_pfcg_roles.

  IF NOT lt_sw_roles[] IS INITIAL OR NOT lt_pfcg_roles[] IS INITIAL.
    CALL FUNCTION 'POPUP_TO_INFORM' "Continue prog after info
      EXPORTING
        titel = text-013
        txt1  = text-014
        txt2  = text-015.
  ENDIF.

* Check for any roles with no PFCG role name
  READ TABLE gt_roles WITH KEY saptechname = space
             TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    CALL SCREEN 903 STARTING AT 3 3 ENDING AT 108 18.
  ENDIF.
ENDFORM.                                 "objcheck_pos

*&---------------------------------------------------------------------*
*&      Form  user_command_0223
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_command_0223.
  DATA: ll_cols         TYPE cxtab_column,
        l_table(10)     TYPE c,
        l_column(10)    TYPE c,
        l_tabix         TYPE sy-tabix,
        l_filename      TYPE rlgrap-filename,
        lt_file         LIKE gt_mccauser OCCURS 0 WITH HEADER LINE,
        l_file_mccauser TYPE string,
        ls_filename     TYPE string,
        ls_mchdr        TYPE /psyng/mchdr,
        lt_rfc          LIKE rfcdes OCCURS 0 WITH HEADER LINE,
        lt_mccauser     TYPE TABLE OF /psyng/mccauser WITH HEADER LINE,
        lt_mcuser       TYPE TABLE OF /psyng/mitigation_assignment
                        WITH HEADER LINE,
        lt_uinfo        TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
        l_noedit        TYPE /psyng/swsodvers-noedit.

  STATICS: BEGIN OF ls_sort,
             name  LIKE screen-name,
             ucomm TYPE sy-ucomm,
           END OF ls_sort.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM authority_check_mccri_assign
            USING sec_actvt space space space space.
  ENDIF.

  CASE ok_code.

*__________________________________________
*-----New upload download Functionality----

    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
                           WITH p_crassn = 'X'
      AND RETURN.

      REFRESH gt_mccauser.
*__________________________________________

    WHEN 'QCUSER'.
      CALL FUNCTION '/PSYNG/SW_CRIAUTH_QCHECK_USER'
        EXPORTING
          vrsio = g_sod_vrsio.

    WHEN 'CREATE'.

      IF gf_mit_asgn_auth_check = 'X'.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
          ID 'ACTVT'      FIELD '01'
          ID 'CLASS'      FIELD ''
          ID 'Y&SW_VRSIO' FIELD ''
          ID 'Y&SW_SWAUD' FIELD ''
          ID 'Y&SW_CNTID' FIELD ''
          ID 'Y&SW_BNAME' FIELD ''
          ID 'Y&SW_COMP'  FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
           ID 'ACTVT'      FIELD '01'
           ID 'Y&SW_VRSIO' FIELD ''
           ID 'Y&SW_SWAUD' FIELD ''
           ID 'Y&SW_CNTID' FIELD ''
           ID 'Y&SW_BNAME' FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ENDIF.
      IF sy-subrc <> 0.
        MESSAGE e108(/psyng/sw) WITH text-051
                'mitigation critical auth assignments'(e27).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      lt_mcuser-rfcdest = lt_rfc-rfcoptions.
      lt_mcuser-type    = '3'.
      APPEND lt_mcuser.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert       = 'X'
          if_show_criauth = 'X'
        TABLES
          it_mcuser       = lt_mcuser
          it_rfcdest      = lt_rfc
          it_sw_uinfo     = lt_uinfo.

      LOOP AT lt_mcuser.
        READ TABLE gt_mccauser WITH KEY contid  = lt_mcuser-contid
                                        swaudid = lt_mcuser-swaudid
                                        userid  = lt_mcuser-userid
                                        vrsio   = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mccauser.
        APPEND gt_mccauser.
        ADD 1 TO tc_mccriauth-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mccauser BY (ls_sort-name).
        ELSE.
          SORT gt_mccauser BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mccauser BY userid swaudid vrsio contid from_date.
      ENDIF.

    WHEN 'COPY'.
      sec_actvt = act_change.
      READ TABLE gt_mccauser WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mccauser WHERE sel = gc_select.
        PERFORM authority_check_mccri_assign
                             USING act_change
                                   gt_mccauser-userid
                                   gt_mccauser-contid
                                   gt_mccauser-swaudid
                                   gt_mccauser-vrsio.

        MOVE-CORRESPONDING gt_mccauser TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '3'.                 "Critical auth
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert       = 'X'
          if_show_criauth = 'X'
        TABLES
          it_mcuser       = lt_mcuser
          it_rfcdest      = lt_rfc
          it_sw_uinfo     = lt_uinfo.
      LOOP AT lt_mcuser.
        READ TABLE gt_mccauser WITH KEY contid  = lt_mcuser-contid
                                        swaudid = lt_mcuser-swaudid
                                        userid  = lt_mcuser-userid
                                        vrsio   = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mccauser.
        APPEND gt_mccauser.
        ADD 1 TO tc_mccriauth-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mccauser BY (ls_sort-name).
        ELSE.
          SORT gt_mccauser BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mccauser BY userid swaudid vrsio contid from_date.
      ENDIF.

    WHEN 'EDIT'.
      sec_actvt = act_change.
      READ TABLE gt_mccauser WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mccauser WHERE sel = gc_select.
        PERFORM authority_check_mccri_assign
                             USING act_change
                                   gt_mccauser-userid
                                   gt_mccauser-contid
                                   gt_mccauser-swaudid
                                   gt_mccauser-vrsio.

        MOVE-CORRESPONDING gt_mccauser TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '3'.                 "Critical auth
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_maint_all    = 'X'
          if_show_criauth = 'X'
        TABLES
          it_mcuser       = lt_mcuser
          it_rfcdest      = lt_rfc
          it_sw_uinfo     = lt_uinfo.

      LOOP AT gt_mccauser WHERE sel = gc_select.
        READ TABLE lt_mcuser WITH KEY contid  = gt_mccauser-contid
                                      swaudid = gt_mccauser-swaudid
                                      userid  = gt_mccauser-userid
                                      vrsio   = gt_mccauser-vrsio.
        IF sy-subrc = 0.
*         Record updated
          l_tabix = sy-tabix.
          gl_mccauser = gt_mccauser.
          gl_mccauser-auditor   = lt_mcuser-auditor.
          gl_mccauser-from_date = lt_mcuser-from_date.
          gl_mccauser-to_date   = lt_mcuser-to_date.
          gl_mccauser-approved  = lt_mcuser-approved.

          IF gl_mccauser <> gt_mccauser.
            MODIFY gt_mccauser FROM gl_mccauser
                   TRANSPORTING auditor from_date to_date approved.
          ENDIF.

          DELETE lt_mcuser INDEX l_tabix.
        ELSE.
*         Record deleted
          DELETE gt_mccauser.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcuser.
*       Record inserted
        MOVE-CORRESPONDING lt_mcuser TO gt_mccauser.
        APPEND gt_mccauser.
        ADD 1 TO tc_mccriauth-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mccauser BY (ls_sort-name).
        ELSE.
          SORT gt_mccauser BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mccauser BY userid swaudid vrsio contid from_date.
      ENDIF.

    WHEN 'DELETE'.
      READ TABLE gt_mccauser WITH KEY sel = gc_select.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      l_tabix = sy-tabix.

      PERFORM authority_check_mccri_assign
              USING act_delete
                    gt_mccauser-userid
                    gt_mccauser-contid
                    gt_mccauser-swaudid
                    gt_mccauser-vrsio.
      sec_actvt = act_delete.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-t02
          text_question         = text-q01
          text_button_1         = text-001
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = text-002
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = gf_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK gf_answer = '1'.

      LOOP AT gt_mccauser WHERE sel = gc_select.
        ls_mchdr-contid = gt_mccauser-contid.
        MOVE-CORRESPONDING gt_mccauser TO lt_mccauser.
        APPEND lt_mccauser.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mccauser          = lt_mccauser
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.            "#EC SAST_CI_GEN_CHECK
        CASE sy-subrc.
          WHEN 0.
            MESSAGE s117(/psyng/sw).  " Mitigation Deleted
          WHEN 1 OR 4.
            MESSAGE e122(/psyng/sw).  " Data Not Saved
          WHEN 2.
            MESSAGE e108(/psyng/sw) WITH text-134 /psyng/mchdr.
          WHEN 3.
            MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDCASE.
        MOVE-CORRESPONDING gt_mccauser TO gs_assingment.
        DELETE gt_mccauser.
        REFRESH lt_mccauser.

*---odubey 08/06/2022 Delete justification as well

        gs_assingment-type = '3'.
        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment = 'X'
            if_delete     = 'X'
            i_mcid        = gt_mccauser-contid
            is_assignment = gs_assingment
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             invalid_input   = 1
             not_implemented = 2
             gos_failure     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.

        CLEAR gs_assingment.
      ENDLOOP.

      CLEAR gf_edit.

    WHEN 'SEL_ALL'.
      gt_mccauser-sel = 'X'.
      MODIFY gt_mccauser TRANSPORTING sel WHERE sel = space.

    WHEN 'DSEL_ALL'.
      CLEAR gt_mccauser-sel.
      MODIFY gt_mccauser TRANSPORTING sel WHERE sel = 'X'.

    WHEN 'PICK'.

      DATA: l_lin           TYPE i,
            l_fieldname(30) TYPE c,
            l_uname         LIKE sy-uname,
            l_contid        TYPE /psyng/mchdr-contid,
            l_parva         TYPE usr05-parva,
            l_sod           TYPE /psyng/swsodvers-vrsio,
            l_dynnr         TYPE sy-dynnr,
            l_obiid         TYPE slis_entry.


      GET CURSOR FIELD l_fieldname LINE l_lin.
      l_lin = l_lin + tc_mccriauth-top_line - 1.
      READ TABLE gt_mccauser INDEX l_lin.


      IF l_fieldname = 'GT_MCCAUSER-CONTID'.
        l_obiid = gt_mccauser-contid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONTID'
            i_objectid   = l_obiid
            i_vrsio      = gt_mccauser-vrsio.
      ENDIF.

    WHEN 'CHANGES'.
      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH p_cont  = 'X'
             WITH p_audid = 'X'
             AND RETURN.

    WHEN 'CURR_VER' OR 'ALL_VER' .
      DATA lt_mccauser1 LIKE TABLE OF gt_mccauser
                WITH HEADER LINE.
**----> when click for current version
      IF ok_code = 'CURR_VER'.
        LOOP AT gt_mccauser WHERE vrsio  = g_sod_vrsio.
          MOVE-CORRESPONDING  gt_mccauser TO lt_mccauser1.
          APPEND lt_mccauser1.
        ENDLOOP.

        REFRESH  gt_mccauser.
        LOOP AT lt_mccauser1.
          MOVE-CORRESPONDING lt_mccauser1 TO gt_mccauser.
          APPEND gt_mccauser.
          CLEAR: lt_mccauser1.
        ENDLOOP.
        MESSAGE s113(/psyng/sw) WITH text-a96.
      ENDIF.

**---->when click for all version filter
      IF ok_code = 'ALL_VER'.
        SELECT *  FROM /psyng/mccauser
       INTO CORRESPONDING FIELDS OF TABLE gt_mccauser.
        MESSAGE s113(/psyng/sw) WITH text-a95.
      ENDIF.

    WHEN 'SEARCH' OR 'FINDNEXT'.
      IF ok_code = 'SEARCH'.
        CLEAR: gl_mcuser, gl_mccauser.
        g_call_scrn = '0223'.
        CALL SCREEN 905 STARTING AT 3 10.
        CHECK sy-ucomm = 'CONTINUE'.
        MOVE-CORRESPONDING gl_mcuser TO gl_mccauser.
      ENDIF.

      IF gl_mccauser-userid IS INITIAL AND
      gl_mccauser-swaudid IS INITIAL AND
      gl_mccauser-contid IS INITIAL AND
      gl_mccauser-auditor IS INITIAL AND
      gl_mccauser-from_date IS INITIAL AND
      gl_mccauser-to_date IS INITIAL.

        MESSAGE e106(/psyng/sw) WITH text-e01.
      ENDIF.

      LOOP AT gt_mccauser WHERE sel = gc_select.
        CLEAR gt_mccauser-sel.
        MODIFY gt_mccauser INDEX sy-tabix.
        l_tabix = sy-tabix + 1.
      ENDLOOP.

      IF ok_code = 'SEARCH'.
        l_tabix = 1.
      ENDIF.

      LOOP AT gt_mccauser FROM l_tabix.
        IF NOT gl_mccauser-userid IS INITIAL.
          CHECK gt_mccauser-userid = gl_mccauser-userid.
        ENDIF.
        IF NOT gl_mccauser-swaudid IS INITIAL.
          CHECK gt_mccauser-swaudid = gl_mccauser-swaudid.
        ENDIF.
        IF NOT gl_mccauser-vrsio IS INITIAL.
          CHECK gt_mccauser-vrsio = gl_mccauser-vrsio.
        ENDIF.
        IF NOT gl_mccauser-contid IS INITIAL.
          CHECK gt_mccauser-contid = gl_mccauser-contid.
        ENDIF.

        IF NOT gl_mccauser-auditor IS INITIAL.
          CHECK gt_mccauser-auditor = gl_mccauser-auditor.
        ENDIF.
        IF NOT gl_mccauser-from_date IS INITIAL.
          CHECK gt_mccauser-from_date = gl_mccauser-from_date.
        ENDIF.
        IF NOT gl_mccauser-to_date IS INITIAL.
          CHECK gt_mccauser-to_date = gl_mccauser-to_date.
        ENDIF.

        gt_mccauser-sel = gc_select.
        MODIFY gt_mccauser INDEX sy-tabix.
        tc_mccriauth-top_line = sy-tabix.


        EXIT.
      ENDLOOP.

      READ TABLE gt_mccauser WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
      ENDIF.

      CLEAR gf_edit.

*   Transport table entries
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tcasmt = gc_select
             WITH p_tvhead = gc_select
             AND RETURN.

    WHEN 'UPLD'.

*__________________________________________
*-----New upload download Functionality----
*__________________________________________

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
      AND RETURN.
*__________________________________________

    WHEN 'DWLD'.
      sec_actvt = act_download.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
        ID 'ACTVT' FIELD sec_actvt
        ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
        ID 'Y&SW_SWAUD' FIELD ''
        ID 'Y&SW_CNTID' FIELD ''
        ID 'Y&SW_BNAME' FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      IF sy-subrc NE 0.
*       You are not authorizied to & & & &
        MESSAGE e108(/psyng/sw) WITH text-037.
      ENDIF.

      PERFORM get_filename1 CHANGING l_filename.
      CHECK NOT l_filename IS INITIAL.


      l_file_mccauser = l_filename.

*BOC:HBHALLA (096)
      AUTHORITY-CHECK OBJECT  'S_GUI'
                       ID      'ACTVT'
                       FIELD   '61'.
      IF sy-subrc = 0.
        CALL FUNCTION 'GUI_DOWNLOAD'             "#EC SAST_CI_GEN_CHECK
          EXPORTING
            filename                = l_file_mccauser
            filetype                = 'ASC'
            write_field_separator   = 'X'
            dat_mode                = ' '
          TABLES
            data_tab                = gt_mccauser
          EXCEPTIONS
            file_write_error        = 1
            no_batch                = 2
            gui_refuse_filetransfer = 3
            invalid_type            = 4
            no_authority            = 5
            unknown_error           = 6
            header_not_allowed      = 7
            separator_not_allowed   = 8
            filesize_not_allowed    = 9
            header_too_long         = 10
            dp_error_create         = 11
            dp_error_send           = 12
            dp_error_write          = 13
            unknown_dp_error        = 14
            access_denied           = 15
            dp_out_of_memory        = 16
            disk_full               = 17
            dp_timeout              = 18
            file_not_found          = 19
            dataprovider_exception  = 20
            control_flush_error     = 21
            OTHERS                  = 22.
        IF sy-subrc <> 0.
        PERFORM handle_download_error USING sy-subrc l_file_mccauser ''.
        ENDIF.
      ENDIF.
*EOC:HBHALLA (096)

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        IF gf_mit_asgn_auth_check = 'X'.
          AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
            ID 'ACTVT'      FIELD act_change
            ID 'CLASS'      FIELD ''
            ID 'Y&SW_VRSIO' FIELD ''
            ID 'Y&SW_SWAUD' FIELD ''
            ID 'Y&SW_CNTID' FIELD ''
            ID 'Y&SW_BNAME' FIELD ''
            ID 'Y&SW_COMP'  FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ELSE.
          AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
             ID 'ACTVT' FIELD act_change
             ID 'Y&SW_VRSIO' FIELD ''
             ID 'Y&SW_SWAUD' FIELD ''
             ID 'Y&SW_CNTID' FIELD ''
             ID 'Y&SW_BNAME' FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ENDIF.

        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-038.
        ENDIF.

        sec_actvt = act_change.
        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
          ID 'ACTVT' FIELD act_display
          ID 'Y&SW_VRSIO' FIELD ''
          ID 'Y&SW_SWAUD' FIELD ''
          ID 'Y&SW_CNTID' FIELD ''
          ID 'Y&SW_BNAME' FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-035.
        ENDIF.

        sec_actvt = act_display.
        gf_dispchg = gc_display.
        CLEAR gf_edit.
      ENDIF.

    WHEN 'SORTA' OR 'SORTD'.
      CLEAR ls_sort.

      LOOP AT tc_mccriauth-cols INTO ll_cols WHERE selected = 'X'.
        SPLIT ll_cols-screen-name AT '-' INTO l_table l_column.
        IF ok_code = 'SORTA'.
          SORT gt_mccauser BY (l_column).
        ELSE.
          SORT gt_mccauser BY (l_column) DESCENDING.
        ENDIF.

        ls_sort-name  = l_column.
        ls_sort-ucomm = ok_code.
      ENDLOOP.

    WHEN 'SHOW_DTL'.
      DATA: l_line        TYPE i,
            lt_mitdetails TYPE TABLE OF /psyng/mitigation_assignment
                    WITH HEADER LINE.

      GET CURSOR LINE l_line.
      l_line = l_line + tc_mccriauth-top_line - 1.
      READ TABLE gt_mccauser INDEX l_line.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING gt_mccauser TO lt_mitdetails.
        lt_mitdetails-type = '3'.
        APPEND lt_mitdetails.
        CALL FUNCTION '/PSYNG/SW_MIT_ASSIGN_DETAILS'
          EXPORTING
            i_contid            = gt_mccauser-contid
            if_show_criauthuser = 'X'
            if_dispchg          = gf_dispchg
          TABLES
            it_mitdetails       = lt_mitdetails.
      ENDIF.
    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8' OR
         'SODFUN_FC1' OR 'SODFUN_FC2' OR 'SODFUN_FC4' OR 'SODFUN_FC5' OR
         'MITCON_FC1'.



      CLEAR: gl_mccauser, gt_mccauser, gt_mccauser[], populated,
                                               i_text[],gf_edit.
      IF gf_dispchg = gc_change.
        IF g_sodfun-pressed_tab <> c_sodfun-tab4.
          SELECT SINGLE noedit INTO l_noedit FROM /psyng/swsodvers
                   WHERE vrsio = g_sod_vrsio.
          IF l_noedit = gc_select.
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ENDIF.

    WHEN 'FS'.
      g_fullscreen = '0223'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

  ENDCASE.

ENDFORM.                    " user_command_0223

*&---------------------------------------------------------------------*
*&      Form  user_command_0225
*&---------------------------------------------------------------------*
*       Handle user commands for screen 225
*----------------------------------------------------------------------*
FORM user_command_0225.
  DATA: ll_cols         TYPE cxtab_column,
        l_table(10)     TYPE c,
        l_column(10)    TYPE c,
        l_tabix         TYPE sy-tabix,
        l_filename      TYPE rlgrap-filename,
        lt_file         LIKE gt_mccauser OCCURS 0 WITH HEADER LINE,
        l_file_mccarole TYPE string,
        ls_filename     TYPE string,
        ls_mchdr        TYPE /psyng/mchdr,
        lt_rfc          LIKE rfcdes OCCURS 0 WITH HEADER LINE,
        lt_mccarole     TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
        lt_mcuser       TYPE TABLE OF /psyng/mitigation_assignment
                        WITH HEADER LINE,
        lt_uinfo        TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
        l_noedit        TYPE /psyng/swsodvers-noedit.

  STATICS: BEGIN OF ls_sort,
             name  LIKE screen-name,
             ucomm TYPE sy-ucomm,
           END OF ls_sort.


  IF sec_actvt IS INITIAL.
    sec_actvt = act_display.
  ENDIF.

* Always do authority check except when leaving tab
  IF ok_code NS '_FC'.
    PERFORM auth_check_mccri_role_assign
            USING sec_actvt space space space space.
  ENDIF.

  CASE ok_code.

*__________________________________________
*-----New upload download Functionality----

    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
                           WITH p_crtrol = 'X'
      AND RETURN.

      REFRESH gt_mccarole.
*__________________________________________

    WHEN 'QCUSER'.
      CALL FUNCTION '/PSYNG/SW_CRIAUTH_QCHECK_USER'
        EXPORTING
          vrsio = g_sod_vrsio.

    WHEN 'CREATE'.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
         ID 'ACTVT'      FIELD '01'
         ID 'Y&SW_VRSIO' FIELD ''
         ID 'Y&SW_SWAUD' FIELD ''
         ID 'Y&SW_CNTID' FIELD ''
         ID 'ACT_GROUP'  FIELD ''.
      IF sy-subrc <> 0.
        MESSAGE e108(/psyng/sw) WITH text-051
                'mitigation critical auth assignments'(e27).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      lt_mcuser-rfcdest = lt_rfc-rfcoptions.
      lt_mcuser-type    = '5'.
      APPEND lt_mcuser.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert       = 'X'
          if_show_criauth = 'X'
          if_show_role    = 'X'
        TABLES
          it_mcuser       = lt_mcuser
          it_rfcdest      = lt_rfc
          it_sw_uinfo     = lt_uinfo.

      LOOP AT lt_mcuser.
        READ TABLE gt_mccarole WITH KEY contid   = lt_mcuser-contid
                                        swaudid  = lt_mcuser-swaudid
                                        agr_name = lt_mcuser-agr_name
                                        vrsio    = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mccarole.
        APPEND gt_mccarole.
        ADD 1 TO tc_mccarole-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mccarole BY (ls_sort-name).
        ELSE.
          SORT gt_mccarole BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mccarole BY agr_name swaudid vrsio contid from_date.
      ENDIF.

    WHEN  'COPY'.
      sec_actvt = act_change.
      READ TABLE gt_mccarole WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mccarole WHERE sel = gc_select.
        PERFORM auth_check_mccri_role_assign
                             USING act_change
                                   gt_mccarole-agr_name
                                   gt_mccarole-contid
                                   gt_mccarole-swaudid
                                   gt_mccarole-vrsio.

        MOVE-CORRESPONDING gt_mccarole TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '5'.                 "Critical auth for role
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_insert       = 'X'
          if_show_criauth = 'X'
          if_show_role    = 'X'
        TABLES
          it_mcuser       = lt_mcuser
          it_rfcdest      = lt_rfc
          it_sw_uinfo     = lt_uinfo.
      LOOP AT lt_mcuser.
        READ TABLE gt_mccarole WITH KEY contid   = lt_mcuser-contid
                                        swaudid  = lt_mcuser-swaudid
                                        agr_name = lt_mcuser-agr_name
                                        vrsio    = lt_mcuser-vrsio.
        IF sy-subrc = 0.
          MESSAGE e101(/psyng/sw).
        ENDIF.

        MOVE-CORRESPONDING lt_mcuser TO gt_mccarole.
        APPEND gt_mccarole.
        ADD 1 TO tc_mccarole-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mccarole BY (ls_sort-name).
        ELSE.
          SORT gt_mccarole BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mccarole BY agr_name swaudid vrsio contid from_date.
      ENDIF.


    WHEN 'EDIT'.
      sec_actvt = act_change.
      READ TABLE gt_mccarole WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      lt_rfc-rfcdest = 'LOCAL'.
      CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
      APPEND lt_rfc.

      LOOP AT gt_mccarole WHERE sel = gc_select.
        PERFORM auth_check_mccri_role_assign
                             USING act_change
                                   gt_mccarole-agr_name
                                   gt_mccarole-contid
                                   gt_mccarole-swaudid
                                   gt_mccarole-vrsio.

        MOVE-CORRESPONDING gt_mccarole TO lt_mcuser.
        lt_mcuser-rfcdest = lt_rfc-rfcoptions.
        lt_mcuser-type    = '5'.                 "Critical auth for role
        APPEND lt_mcuser.

        lt_uinfo-bname = lt_mcuser-userid.
        COLLECT lt_uinfo.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_076'
        EXPORTING
          if_maint_all    = 'X'
          if_show_criauth = 'X'
          if_show_role    = 'X'
        TABLES
          it_mcuser       = lt_mcuser
          it_rfcdest      = lt_rfc
          it_sw_uinfo     = lt_uinfo.

      LOOP AT gt_mccarole WHERE sel = gc_select.
        READ TABLE lt_mcuser WITH KEY contid   = gt_mccarole-contid
                                      swaudid  = gt_mccarole-swaudid
                                      agr_name = gt_mccarole-agr_name
                                      vrsio    = gt_mccarole-vrsio.
        IF sy-subrc = 0.
*         Record updated
          l_tabix = sy-tabix.
          gl_mccarole = gt_mccarole.
          gl_mccarole-auditor   = lt_mcuser-auditor.
          gl_mccarole-from_date = lt_mcuser-from_date.
          gl_mccarole-to_date   = lt_mcuser-to_date.
          gl_mccarole-approved  = lt_mcuser-approved.

          IF gl_mccarole <> gt_mccarole.
            MODIFY gt_mccarole FROM gl_mccarole
                   TRANSPORTING auditor from_date to_date approved.
          ENDIF.

          DELETE lt_mcuser INDEX l_tabix.
        ELSE.
*         Record deleted
          DELETE gt_mccarole.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcuser.
*       Record inserted
        MOVE-CORRESPONDING lt_mcuser TO gt_mccarole.
        APPEND gt_mccarole.
        ADD 1 TO tc_mccarole-lines.
      ENDLOOP.

      IF NOT ls_sort IS INITIAL.
        IF ls_sort-ucomm = 'SORTA'.
          SORT gt_mccarole BY (ls_sort-name).
        ELSE.
          SORT gt_mccarole BY (ls_sort-name) DESCENDING.
        ENDIF.
      ELSE.
        SORT gt_mccarole BY agr_name swaudid vrsio contid from_date.
      ENDIF.

    WHEN 'DELETE'.
      READ TABLE gt_mccarole WITH KEY sel = gc_select.
      IF sy-subrc <> 0.
        MESSAGE e161(/psyng/sw).
      ENDIF.

      l_tabix = sy-tabix.

      PERFORM auth_check_mccri_role_assign
              USING act_delete
                    gt_mccarole-agr_name
                    gt_mccarole-contid
                    gt_mccarole-swaudid
                    gt_mccarole-vrsio.
      sec_actvt = act_delete.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-t02
          text_question         = text-q01
          text_button_1         = text-001
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = text-002
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = gf_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK gf_answer = '1'.

      LOOP AT gt_mccarole WHERE sel = gc_select.
        ls_mchdr-contid = gt_mccarole-contid.
        MOVE-CORRESPONDING gt_mccarole TO lt_mccarole.
        APPEND lt_mccarole.

        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mccarole          = lt_mccarole
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.            "#EC SAST_CI_GEN_CHECK
        CASE sy-subrc.
          WHEN 0.
            MESSAGE s117(/psyng/sw).  " Mitigation Deleted
          WHEN 1 OR 4.
            MESSAGE e122(/psyng/sw).  " Data Not Saved
          WHEN 2.
            MESSAGE e108(/psyng/sw) WITH text-134 /psyng/mchdr.
          WHEN 3.
            MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDCASE.
        MOVE-CORRESPONDING gt_mccarole TO gs_assingment.
        DELETE gt_mccarole.
        REFRESH lt_mccarole.

*---odubey 08/06/2022 Delete justification as well

        gs_assingment-type = '5'.
        CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
          EXPORTING
            if_assignment = 'X'
            if_delete     = 'X'
            i_mcid        = gt_mccarole-contid
            is_assignment = gs_assingment
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             invalid_input   = 1
             not_implemented = 2
             gos_failure     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.

        CLEAR gs_assingment.
      ENDLOOP.

      CLEAR gf_edit.

    WHEN 'CHANGES'.
      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH p_cont   = 'X'
             WITH p_carole = 'X'
             AND RETURN.

    WHEN 'SEL_ALL'.
      gt_mccarole-sel = 'X'.
      MODIFY gt_mccarole TRANSPORTING sel WHERE sel = space.

    WHEN 'DSEL_ALL'.
      CLEAR gt_mccarole-sel.
      MODIFY gt_mccarole TRANSPORTING sel WHERE sel = 'X'.
    WHEN 'PICK'.

      DATA: l_lin           TYPE i,
            l_fieldname(30) TYPE c,
            l_uname         LIKE sy-uname,
            l_contid        TYPE /psyng/mchdr-contid,
            l_parva         TYPE usr05-parva,
            l_sod           TYPE /psyng/swsodvers-vrsio,
            l_dynnr         TYPE sy-dynnr,
            l_objid         TYPE slis_entry.


      GET CURSOR FIELD l_fieldname LINE l_lin.
      l_lin = l_lin + tc_mccarole-top_line - 1.
      READ TABLE gt_mccarole INDEX l_lin.
      IF l_fieldname = 'GT_MCCAROLE-CONTID'.
        l_objid = gt_mccarole-contid.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
          EXPORTING
            i_objecttype = 'CONTID'
            i_objectid   = l_objid
            i_vrsio      = gt_mccarole-vrsio.

      ENDIF.

    WHEN 'CURR_VER' OR 'ALL_VER' .
      DATA lt_mccarole1 LIKE TABLE OF gt_mccarole
                   WITH HEADER LINE.
**----> when click for current version
      IF ok_code = 'CURR_VER'.
        LOOP AT gt_mccarole WHERE vrsio = g_sod_vrsio.
          MOVE-CORRESPONDING  gt_mccarole TO lt_mccarole1.
          APPEND lt_mccarole1.
        ENDLOOP.

        REFRESH  gt_mccarole.
        LOOP AT lt_mccarole1.
          MOVE-CORRESPONDING lt_mccarole1 TO gt_mccarole.
          APPEND gt_mccarole.
          CLEAR: lt_mccarole1.
        ENDLOOP.
        MESSAGE s113(/psyng/sw) WITH text-a96.
      ENDIF.

**---->when click for all version filter
      IF ok_code = 'ALL_VER'.
        SELECT * FROM /psyng/mccarole
                   INTO CORRESPONDING FIELDS OF TABLE gt_mccarole.
*        DESCRIBE TABLE gt_mccarole LINES tc_mccarole-lines.
*        SORT gt_mccarole BY agr_name swaudid vrsio contid from_date.
        MESSAGE s113(/psyng/sw) WITH text-a95.
      ENDIF.

    WHEN 'SEARCH' OR 'FINDNEXT'.
      IF ok_code = 'SEARCH'.
        CLEAR: gl_mcuser, gl_mccarole.
        g_call_scrn = '0225'.
        CALL SCREEN 905 STARTING AT 3 10.
        CHECK sy-ucomm = 'CONTINUE'.
        MOVE-CORRESPONDING gl_mcuser TO gl_mccarole.
      ENDIF.

      IF gl_mccarole-agr_name IS INITIAL AND
      gl_mccarole-swaudid IS INITIAL AND
      gl_mccarole-contid IS INITIAL AND
      gl_mccarole-auditor IS INITIAL AND
      gl_mccarole-from_date IS INITIAL AND
      gl_mccarole-to_date IS INITIAL.

        MESSAGE e106(/psyng/sw) WITH text-e01.
      ENDIF.

      LOOP AT gt_mccarole WHERE sel = gc_select.
        CLEAR gt_mccarole-sel.
        MODIFY gt_mccarole INDEX sy-tabix.
        l_tabix = sy-tabix + 1.
      ENDLOOP.

      IF ok_code = 'SEARCH'.
        l_tabix = 1.
      ENDIF.

      LOOP AT gt_mccarole FROM l_tabix.
        IF NOT gl_mccarole-agr_name IS INITIAL.
          CHECK gt_mccarole-agr_name = gl_mccarole-agr_name.
        ENDIF.
        IF NOT gl_mccarole-swaudid IS INITIAL.
          CHECK gt_mccarole-swaudid = gl_mccarole-swaudid.
        ENDIF.
        IF NOT gl_mccarole-vrsio IS INITIAL.
          CHECK gt_mccarole-vrsio = gl_mccarole-vrsio.
        ENDIF.
        IF NOT gl_mccarole-contid IS INITIAL.
          CHECK gt_mccarole-contid = gl_mccarole-contid.
        ENDIF.

        IF NOT gl_mccarole-auditor IS INITIAL.
          CHECK gt_mccarole-auditor = gl_mccarole-auditor.
        ENDIF.
        IF NOT gl_mccarole-from_date IS INITIAL.
          CHECK gt_mccarole-from_date = gl_mccarole-from_date.
        ENDIF.
        IF NOT gl_mccarole-to_date IS INITIAL.
          CHECK gt_mccarole-to_date = gl_mccarole-to_date.
        ENDIF.

        gt_mccarole-sel = gc_select.
        MODIFY gt_mccarole INDEX sy-tabix.
        tc_mccarole-top_line = sy-tabix.


        EXIT.
      ENDLOOP.

      READ TABLE gt_mccarole WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
      ENDIF.

      CLEAR gf_edit.

*   Transport table entries
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tcarol = gc_select
             WITH p_tvhead = gc_select
             AND RETURN.

    WHEN 'UPLD'.

*__________________________________________
*-----New upload download Functionality----
*__________________________________________

      SUBMIT /psyng/sw_101 VIA SELECTION-SCREEN
      AND RETURN.
*__________________________________________

    WHEN 'DWLD'.
      sec_actvt = act_download.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
         ID 'ACTVT' FIELD sec_actvt
         ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
         ID 'Y&SW_SWAUD' FIELD ''
         ID 'Y&SW_CNTID' FIELD ''
         ID 'ACT_GROUP'  FIELD ''.

      IF sy-subrc NE 0.
*       You are not authorizied to & & & &
        MESSAGE e108(/psyng/sw) WITH text-037.
      ENDIF.

      PERFORM get_filename1 CHANGING l_filename.
      CHECK NOT l_filename IS INITIAL.


      l_file_mccarole = l_filename.

*BOC:HBHALLA (096)
      AUTHORITY-CHECK OBJECT  'S_GUI'
                       ID      'ACTVT'
                       FIELD   '61'.
      IF sy-subrc = 0.
        CALL FUNCTION 'GUI_DOWNLOAD'             "#EC SAST_CI_GEN_CHECK
          EXPORTING
            filename                = l_file_mccarole
            filetype                = 'ASC'
            write_field_separator   = 'X'
            dat_mode                = ' '
          TABLES
            data_tab                = gt_mccarole
          EXCEPTIONS
            file_write_error        = 1
            no_batch                = 2
            gui_refuse_filetransfer = 3
            invalid_type            = 4
            no_authority            = 5
            unknown_error           = 6
            header_not_allowed      = 7
            separator_not_allowed   = 8
            filesize_not_allowed    = 9
            header_too_long         = 10
            dp_error_create         = 11
            dp_error_send           = 12
            dp_error_write          = 13
            unknown_dp_error        = 14
            access_denied           = 15
            dp_out_of_memory        = 16
            disk_full               = 17
            dp_timeout              = 18
            file_not_found          = 19
            dataprovider_exception  = 20
            control_flush_error     = 21
            OTHERS                  = 22.
        IF sy-subrc <> 0.
        PERFORM handle_download_error USING sy-subrc l_file_mccarole ''.
        ENDIF.
      ENDIF.
*EOC:HBHALLA (096)

*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
           ID 'ACTVT' FIELD act_change
           ID 'Y&SW_VRSIO' FIELD ''
           ID 'Y&SW_SWAUD' FIELD ''
           ID 'Y&SW_CNTID' FIELD ''
           ID 'ACT_GROUP'  FIELD ''.

        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-038.
        ENDIF.

        sec_actvt = act_change.
        gf_dispchg = gc_change.
*        PERFORM check_version_editable.
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
           ID 'ACTVT' FIELD act_display
           ID 'Y&SW_VRSIO' FIELD ''
           ID 'Y&SW_SWAUD' FIELD ''
           ID 'Y&SW_CNTID' FIELD ''
           ID 'ACT_GROUP'  FIELD ''.

        IF sy-subrc NE 0.
*         You are not authorizied for & & & &
          MESSAGE e108(/psyng/sw) WITH text-035.
        ENDIF.

        sec_actvt = act_display.
        gf_dispchg = gc_display.
        CLEAR gf_edit.
      ENDIF.

    WHEN 'SORTA' OR 'SORTD'.
      CLEAR ls_sort.

      LOOP AT tc_mccarole-cols INTO ll_cols WHERE selected = 'X'.
        SPLIT ll_cols-screen-name AT '-' INTO l_table l_column.
        IF ok_code = 'SORTA'.
          SORT gt_mccarole BY (l_column).
        ELSE.
          SORT gt_mccarole BY (l_column) DESCENDING.
        ENDIF.

        ls_sort-name  = l_column.
        ls_sort-ucomm = ok_code.
      ENDLOOP.

    WHEN 'SHOW_DTL'.
      DATA: l_line        TYPE i,
            lt_mitdetails TYPE TABLE OF /psyng/mitigation_assignment
                    WITH HEADER LINE.
      GET CURSOR LINE l_line.
      l_line = l_line + tc_mccarole-top_line - 1.
      READ TABLE gt_mccarole INDEX l_line.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING gt_mccarole TO lt_mitdetails.
        lt_mitdetails-type = '5'.
        APPEND lt_mitdetails.
        CALL FUNCTION '/PSYNG/SW_MIT_ASSIGN_DETAILS'
          EXPORTING
            i_contid            = gt_mccarole-contid
            if_show_criauthrole = 'X'
            if_dispchg          = gf_dispchg
          TABLES
            it_mitdetails       = lt_mitdetails.
      ENDIF.
    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8' OR
         'SODFUN_FC1' OR 'SODFUN_FC2' OR 'SODFUN_FC4' OR 'SODFUN_FC5' OR
         'MITCON_FC1'.

      CLEAR: gl_mccarole, gt_mccarole, gt_mccarole[], populated,
                                               i_text[],gf_edit.
      IF gf_dispchg = gc_change.
        IF g_sodfun-pressed_tab <> c_sodfun-tab4.
          SELECT SINGLE noedit INTO l_noedit FROM /psyng/swsodvers
                   WHERE vrsio = g_sod_vrsio.
          IF l_noedit = gc_select.
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ENDIF.

    WHEN 'FS'.
      g_fullscreen = '0225'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.
  ENDCASE.
ENDFORM.                    " user_command_0225

*&---------------------------------------------------------------------*
*&      Form  authority_check_mccri_assign
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SEC_ACTVT  text
*      -->P_GL_MCCAUSER_USERID  text
*      -->P_GL_MCCAUSER_CONTID  text
*      -->P_GL_MCCAUSER_SWAUDID  text
*----------------------------------------------------------------------*
FORM authority_check_mccri_assign USING    actvt
                                           userid
                                           contid
                                           swaudid
                                           vrsio.

  DATA : lt_uinfo  TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
         lf_failed TYPE flag.

  CHECK NOT actvt IS INITIAL.

  IF gf_mit_asgn_auth_check = 'X'.

    IF NOT contid IS INITIAL AND
     NOT swaudid IS INITIAL AND
     NOT userid IS INITIAL.

      lt_uinfo-bname =  userid.
      APPEND lt_uinfo. CLEAR lt_uinfo.

      CALL FUNCTION '/PSYNG/SW_USER_INFO'
        EXPORTING
          vrsio        = vrsio
          i_name_only  = 'X'
          i_mr_company = 'X'
        TABLES
          sw_uinfo     = lt_uinfo.
      READ TABLE lt_uinfo INDEX 1.
      IF NOT lt_uinfo-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
          ID 'ACTVT'      FIELD actvt
          ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_VRSIO' FIELD vrsio
          ID 'Y&SW_CNTID' FIELD contid
          ID 'Y&SW_SWAUD' FIELD swaudid
          ID 'Y&SW_BNAME' FIELD userid
          ID 'Y&SW_COMP'  FIELD lt_uinfo-company.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
           ID 'ACTVT'      FIELD actvt
           ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_CNTID' FIELD contid
           ID 'Y&SW_SWAUD' FIELD swaudid
           ID 'Y&SW_BNAME' FIELD userid
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ENDIF.

      IF NOT lt_uinfo-class IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
           ID 'ACTVT'      FIELD actvt
           ID 'CLASS'      FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_CNTID' FIELD contid
           ID 'Y&SW_SWAUD' FIELD swaudid
           ID 'Y&SW_BNAME' FIELD userid
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
                 ID 'ACTVT'      FIELD actvt
                 ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
                 ID 'Y&SW_VRSIO' FIELD vrsio
                 ID 'Y&SW_CNTID' FIELD contid
                 ID 'Y&SW_SWAUD' FIELD swaudid
                 ID 'Y&SW_BNAME' FIELD userid
                 ID 'Y&SW_COMP'  FIELD ''.
        "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ENDIF.

    ELSE.
      IF vrsio IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
           ID 'ACTVT'      FIELD actvt
           ID 'CLASS'      FIELD ''
           ID 'Y&SW_VRSIO' FIELD ''
           ID 'Y&SW_CNTID' FIELD ''
           ID 'Y&SW_SWAUD' FIELD ''
           ID 'Y&SW_BNAME' FIELD ''
           ID 'Y&SW_COMP'  FIELD ''.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
        ID 'ACTVT'      FIELD actvt
        ID 'CLASS'      FIELD ''
        ID 'Y&SW_BNAME' FIELD ''
        ID 'Y&SW_CNTID' FIELD ''
        ID 'Y&SW_COMP'  FIELD ''
        ID 'Y&SW_VRSIO' FIELD ''
        ID 'Y&SW_SWAUD' FIELD ''.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ENDIF.
    ENDIF.
  ELSE.
    IF NOT contid IS INITIAL AND
       NOT swaudid IS INITIAL AND
       NOT userid IS INITIAL.

      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
               ID 'ACTVT' FIELD actvt
               ID 'Y&SW_VRSIO' FIELD vrsio
               ID 'Y&SW_SWAUD' FIELD swaudid
               ID 'Y&SW_CNTID' FIELD contid
               ID 'Y&SW_BNAME' FIELD userid.
      IF sy-subrc <> 0.
        lf_failed = 'X'.
      ENDIF.

    ELSE.
      IF vrsio IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
           ID 'ACTVT' FIELD actvt
           ID 'Y&SW_VRSIO' FIELD ''
           ID 'Y&SW_SWAUD' FIELD ''
           ID 'Y&SW_CNTID' FIELD ''
           ID 'Y&SW_BNAME' FIELD ''.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_MCCAU'
           ID 'ACTVT' FIELD actvt
           ID 'Y&SW_VRSIO' FIELD vrsio
           ID 'Y&SW_SWAUD' FIELD ''
           ID 'Y&SW_CNTID' FIELD ''
           ID 'Y&SW_BNAME' FIELD ''.
        IF sy-subrc <> 0.
          lf_failed = 'X'.
        ENDIF.

      ENDIF.
    ENDIF.
  ENDIF.

  IF lf_failed = 'X'.
    CASE actvt.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorized for & & &
    IF NOT contid IS INITIAL AND NOT swaudid IS INITIAL
    AND NOT userid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt userid
                                             swaudid
                                             contid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-055.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_mccri_assign

*&---------------------------------------------------------------------*
*&      Form  auth_check_mccri_role_assign
*&---------------------------------------------------------------------*
*       Check authority for Mitigating controls assignment to CA roles
*----------------------------------------------------------------------*
*      -->I_ACTVT     Activity
*      -->I_AGR_NAME  Role name
*      -->I_CONTID    Mitigating control ID
*      -->I_SWAUDID   Critical Auth ID
*      -->I_VRSIO     SOD version
*----------------------------------------------------------------------*
FORM auth_check_mccri_role_assign USING    i_actvt
                                           i_agr_name
                                           i_contid
                                           i_swaudid
                                           i_vrsio.
  CHECK NOT i_actvt IS INITIAL.

  IF NOT i_contid IS INITIAL AND
     NOT i_swaudid IS INITIAL AND
     NOT i_agr_name IS INITIAL.

    AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
             ID 'ACTVT' FIELD i_actvt
             ID 'Y&SW_VRSIO' FIELD i_vrsio
             ID 'Y&SW_SWAUD' FIELD i_swaudid
             ID 'Y&SW_CNTID' FIELD i_contid
             ID 'ACT_GROUP'  FIELD i_agr_name.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    IF i_vrsio IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
         ID 'ACTVT' FIELD i_actvt
         ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_SWAUD' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'ACT_GROUP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
    ELSE.
      AUTHORITY-CHECK OBJECT 'Y&SW_MCCAR'
         ID 'ACTVT' FIELD i_actvt
         ID 'Y&SW_VRSIO' FIELD i_vrsio
         ID 'Y&SW_SWAUD' FIELD ''
         ID 'Y&SW_CNTID' FIELD ''
         ID 'ACT_GROUP'  FIELD ''.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
    ENDIF.
  ENDIF.

  IF sy-subrc NE 0.
    CASE i_actvt.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.
*   You are not authorized for & & &
    IF NOT i_contid IS INITIAL AND NOT i_swaudid IS INITIAL
    AND NOT i_agr_name IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt i_agr_name
                                             i_swaudid
                                             i_contid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-055.
    ENDIF.
  ENDIF.

ENDFORM.                    " auth_check_mccri_role_assign

*&---------------------------------------------------------------------*
*&      Form  validate_mccauser
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM validate_mccauser.
  DATA: l_approver TYPE /psyng/mchdr-approver,
        lt_uinfo   TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

* Enter all fields
  IF gl_mccauser-userid IS INITIAL OR gl_mccauser-swaudid IS INITIAL OR
  gl_mccauser-contid IS INITIAL OR gl_mccauser-from_date IS INITIAL OR
  gl_mccauser-to_date IS INITIAL.

    MESSAGE e106(/psyng/sw) WITH text-e02.
  ENDIF.

* Validate user ID
  SELECT SINGLE mandt INTO sy-mandt FROM usr02
                WHERE bname = gl_mccauser-userid.
  IF sy-subrc <> 0.
    MESSAGE w162(/psyng/sw) WITH gl_mccauser-userid.
  ENDIF.

* Validate object ID
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swaudc2
                WHERE vrsio   = gl_mccauser-vrsio
                  AND swaudid = gl_mccauser-swaudid.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e16.
  ENDIF.

* Validate mitigating control ID
  SELECT SINGLE approver INTO l_approver FROM /psyng/mchdr
                WHERE contid = gl_mccauser-contid.
  IF sy-subrc <> 0.
    MESSAGE e106(/psyng/sw) WITH text-e04.
  ENDIF.

* Check that the user ID is not the same as the approver ID
  IF gl_mccauser-userid = l_approver.
    IF g_apr_same_usr_msg IS INITIAL.
      PERFORM get_apr_msgtyp CHANGING g_apr_same_usr_msg.
    ENDIF.

    MESSAGE ID '/PSYNG/SW' TYPE g_apr_same_usr_msg NUMBER '107'
                           WITH text-e07 text-e09 gl_mccauser-contid.
  ENDIF.

  IF NOT gl_mccauser-auditor IS INITIAL.
*   Check that user ID is not the same as the auditor ID
    IF gl_mccauser-userid = gl_mccauser-auditor.
      IF g_aud_same_usr_msg IS INITIAL.
        PERFORM get_aud_msgtyp CHANGING g_aud_same_usr_msg.
      ENDIF.

      MESSAGE ID '/PSYNG/SW' TYPE g_aud_same_usr_msg NUMBER '107'
                 WITH text-e07 text-e08.
    ENDIF.

*--Check if we need to validate the auditor
    IF gf_val_mit_aud IS INITIAL.
      PERFORM get_val_mit_aud.
    ENDIF.

    IF gf_val_mit_aud = 'Y'.
*--Get the company
      lt_uinfo-bname = gt_mccauser-userid.
      APPEND lt_uinfo.
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
        EXPORTING
          i_name_only  = 'X'
          i_mr_company = 'X'
        TABLES
          sw_uinfo     = lt_uinfo.

      READ TABLE lt_uinfo INDEX 1 TRANSPORTING company.

      SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                    WHERE contid  = gl_mccauser-contid
                      AND auditor = gl_mccauser-auditor
                      AND ( company = lt_uinfo-company
                         OR company = space ).
      IF NOT sy-subrc = 0.
        MESSAGE e138(/psyng/sw) WITH gl_mccauser-auditor
                    'is not a valid auditor for mitigation'(e23)
                    gl_mccauser-contid.
      ENDIF.
    ENDIF.
  ELSE.
*   Check that at least one auditor is maintained for the
*   mitigating control ID
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/mcauditor
                  WHERE contid = gl_mccauser-contid.
    IF sy-subrc <> 0.
      MESSAGE e106(/psyng/sw) WITH text-e08.
    ENDIF.
  ENDIF.

*************************************************************

***Validation for proper Date format(YYYYMMDD)
*it cant allow other date formats


  IF NOT  gl_mccauser-from_date IS INITIAL.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mccauser-from_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
*** RKANAKA     changes 15-10-2011


  IF NOT gl_mccauser-to_date IS INITIAL.


    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = gl_mccauser-to_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
*** RKANAKA changes 15-10-2011

*************************************************************
* Validate dates
  IF gl_mccauser-from_date > gl_mccauser-to_date.
    MESSAGE e106(/psyng/sw) WITH text-e05.
  ENDIF.

* Check for duplicates
*--Only on insert
  CHECK sy-ucomm = 'INSERT'.                     "#EC SAST_CI_GEN_CHECK
  READ TABLE gt_mccauser WITH KEY contid = gl_mccauser-contid
                                  swaudid = gl_mccauser-swaudid
                                  userid = gl_mccauser-userid
                                  vrsio  = gl_mccauser-vrsio
                                  sel    = space
                                  TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    MESSAGE e101(/psyng/sw).
  ENDIF.

ENDFORM.                    " validate_mccauser
*&---------------------------------------------------------------------*
*&      Form  get_filename1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_FILENAME  text
*----------------------------------------------------------------------*
FORM get_filename1 CHANGING e_filename TYPE rlgrap-filename.
  CALL FUNCTION 'WS_FILENAME_GET'
    EXPORTING
      mask             = ',*.*,*.*.'
      mode             = 'O'
      title            = text-t02
    IMPORTING
      filename         = e_filename
    EXCEPTIONS
      inv_winsys       = 1
      no_batch         = 2
      selection_cancel = 3
      selection_error  = 4
      OTHERS           = 5.
  IF sy-subrc <> 0 AND sy-subrc <> 3.
    MESSAGE e398(00) WITH text-e16.
  ENDIF.

ENDFORM.                    " get_filename1

*&---------------------------------------------------------------------*
*&      Form  set_version
*&---------------------------------------------------------------------*
*       Set the SOD version for viewing/maintenance
*----------------------------------------------------------------------*
FORM set_version.
  CALL SCREEN 902 STARTING AT 3 3.

* If in change mode, check if version can be edited
  IF gf_dispchg = gc_change.
    IF g_sodfun-pressed_tab <> c_sodfun-tab4.
      PERFORM check_version_editable.
    ENDIF.
  ENDIF.

  ok_code  = 'ENTER'.
  sy-ucomm = 'ENTER'.
  CLEAR: first_time, first_txn1, first_role1, first_prof1, gt_mcuser[],
         gt_mcusrgrp[], gt_mccauser[].
ENDFORM.                    " set_version

*&---------------------------------------------------------------------*
*&      Form  check_version_editable
*&---------------------------------------------------------------------*
*       Check if version can be edited
*----------------------------------------------------------------------*
FORM check_version_editable.
  DATA: l_noedit TYPE /psyng/swsodvers-noedit.

  SELECT SINGLE noedit INTO l_noedit                 "#EC CI_SEL_NESTED
       FROM /psyng/swsodvers
                WHERE vrsio = g_sod_vrsio.

  IF l_noedit = gc_select.
    MESSAGE i134(/psyng/sw) WITH g_sod_vrsio.
    gf_dispchg = gc_display.
  ENDIF.
ENDFORM.                    " check_version_editable

*&---------------------------------------------------------------------*
*&      Form  validate_tcode
*&---------------------------------------------------------------------*
*       Validate transaction
*----------------------------------------------------------------------*
*      -->I_TCODE  Transaction code
*----------------------------------------------------------------------*
FORM validate_tcode USING    i_tcode TYPE tcode.
  CHECK i_tcode <> '*'.
  IF i_tcode IS INITIAL.
*--& & cannot be initial
    MESSAGE e003(/psyng/sw) WITH 'Tcode' i_tcode.
  ELSE.
    SELECT SINGLE tcode INTO i_tcode FROM tstc       "#EC CI_SEL_NESTED
     WHERE tcode = i_tcode.
    IF sy-subrc <> 0.
*--Tcode & does not exist, only relevant for cross system analysis.
      MESSAGE w005(/psyng/sw) WITH i_tcode.
**Case# 14012
*      MESSAGE i005(/psyng/sw) WITH i_tcode.
    ENDIF.
  ENDIF.
ENDFORM.                    " validate_tcode

*&---------------------------------------------------------------------*
*&      Form  set_default_user_param
*&---------------------------------------------------------------------*
*       Set default version in the user's parameters
*----------------------------------------------------------------------*
FORM set_default_user_param.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
        lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
        ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = g_current_user."sy-uname. C0700

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = g_sod_vrsio.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE'     "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = g_current_user "sy-uname C0700
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return
  "(++)BOC UMITTAL SE VF scan-25/11/2024
       EXCEPTIONS
         OTHERS         = 1 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " set_default_user_param

*&---------------------------------------------------------------------*
*&      Form  display_role_in_pfcg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_role_in_pfcg USING agr_name LIKE agr_define-agr_name.

  DATA: l_answer,
        pertext(200).        "Progress indicator text



  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
    EXPORTING
      defaultoption     = '1'
      diagnosetext1     = text-170
      diagnosetext2     = text-171
      diagnosetext3     = text-172
      textline1         = text-173
      text_option1      = text-174
      text_option2      = text-175
      icon_text_option1 = 'ICON_INCOMING_TASK'
      icon_text_option2 = 'ICON_OUTGOING_TASK'
      titel             = text-176
      cancel_display    = 'X'
    IMPORTING
      answer            = l_answer.

  CASE l_answer.
    WHEN '1'.

      CHECK NOT agr_name IS INITIAL.
      SELECT SINGLE agr_name INTO agr_define-agr_name FROM agr_define
             WHERE agr_name = agr_name.
      IF sy-subrc NE 0.
        MESSAGE e398(00) WITH 'Role'(147) agr_name
                                       text-e21
                                       'in local system.'(e31).
      ENDIF.
*       CHECK outputdet4-rfcdest+0(3) = sy-sysid AND  "Show only if role
*          outputdet4-rfcdest+3(3) = sy-mandt.     "in current system

     CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
*          STARTING NEW TASK 'PFCG'
       EXPORTING
         agr_name = agr_name
   "(++)BOC UMITTAL SE VF scan-25/11/2024
              EXCEPTIONS
                agr_not_found = 1
                OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.

    WHEN '2'.
      DATA: userresponse, dflt_rfc LIKE /psyng/swconfig-value.
      CLEAR: ifields.
      REFRESH: ifields.
      se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
      IF ifields[] IS INITIAL.
        ifields-tabname   = 'RFCDES'.
        ifields-fieldname = 'RFCDEST'.
        ifields-fieldtext = text-177.
        IF NOT dflt_rfc IS INITIAL.
          ifields-value = dflt_rfc.
        ENDIF.
        APPEND ifields.
      ENDIF.

      CLEAR userresponse.
      CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
        EXPORTING
          formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
          programname       = '/PSYNG/SODREPORT_ORG'
          popup_title       = text-178
          ok_pushbuttontext = text-179
        IMPORTING
          returncode        = userresponse
        TABLES
          fields            = ifields
        EXCEPTIONS
          error_in_fields   = 1
          OTHERS            = 2.

      IF sy-subrc <> 0.
        MESSAGE e208(00) WITH text-180.
      ENDIF.

      CHECK userresponse NE 'A'.                 "#EC SAST_CI_GEN_CHECK
      "check to see user doesn't abort

      READ TABLE ifields WITH KEY tabname = 'RFCDES'
                                  fieldname = 'RFCDEST'.

      IF ifields-value IS INITIAL.
        MESSAGE w208(00) WITH text-181.
      ENDIF.

      SELECT SINGLE * FROM rfcdes
             INTO rfcdes
             WHERE rfcdest = ifields-value AND
                   rfctype = '3'.

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
            agr_not_found = 1
            OTHERS        = 2.                   "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF sy-subrc = 1.
          CLEAR pertext.
          CONCATENATE text-182 ifields-value
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ELSEIF sy-subrc = 2.
          CONCATENATE text-183 ifields-value text-184
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ENDIF.
      ELSE.
        CLEAR pertext.
        CONCATENATE text-185 ifields-value text-186
                                 INTO pertext SEPARATED BY space.
        MESSAGE i208(00) WITH pertext.
      ENDIF.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " display_role_in_pfcg

*&---------------------------------------------------------------------*
*&      Form  popup_changed_role
*&---------------------------------------------------------------------*
*       Popup to notify user that some role adjustments may be
*       necessary and allow them to navigate to the role.
*----------------------------------------------------------------------*
*  -->  I_ACTION  Role created/adjusted action
*----------------------------------------------------------------------*
FORM popup_changed_role USING i_action.
  DATA: l_question(500) TYPE c,
        lf_answer(1)    TYPE c.


  CONCATENATE text-187 i_action text-188 text-189 text-190
              INTO l_question SEPARATED BY space.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = text-147
      text_question         = l_question
      text_button_1         = text-001
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = text-002
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '1'
      display_cancel_button = space
    IMPORTING
      answer                = lf_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CHECK lf_answer = '1'.

  CASE gf_answer.
    WHEN '1'.
     CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
         agr_name      = /psyng/rolehdr-saptechname
       EXCEPTIONS
         agr_not_found = 1
         OTHERS        = 2.
      "(++)BOC UMITTAL SE VF scan-25/11/2024
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
    WHEN '2'.
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
          agr_name      = /psyng/rolehdr-saptechname
        EXCEPTIONS
          agr_not_found = 1
          OTHERS        = 2.                     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ENDCASE.
ENDFORM.                    " popup_changed_role

*&---------------------------------------------------------------------*
*&      Form  find_role_tree
*&---------------------------------------------------------------------*
*       Find role ID in tree
*----------------------------------------------------------------------*
FORM find_role_tree.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields     TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return     TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_node_keys  TYPE treev_nks,
        l_node_key    TYPE tv_nodekey,
        l_roleid      TYPE /psyng/rolehdr-roleid,
        l_description TYPE /psyng/rolehdr-description.


  lt_fields-tabname   = '/PSYNG/ROLEHDR'.
  lt_fields-fieldname = 'ROLEID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.

* Get values for popup
  SELECT roleid description INTO (l_roleid, l_description)
         FROM /psyng/rolehdr ORDER BY roleid.
    lt_values-line = l_roleid.
    APPEND lt_values.
    lt_values-line = l_description.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'ROLEID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  CHECK sy-subrc = 0.
  l_node_key = lt_return-fieldval.
  APPEND l_node_key TO lt_node_keys.

************************************************************
**  Case#1939
**  Changes made to clear last select operation in the tree

  CALL METHOD g_left_tree->unselect_all
    EXCEPTIONS
      failed            = 1
      cntl_system_error = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
************************************************************

  CALL METHOD g_left_tree->select_nodes
    EXPORTING
      node_key_table               = lt_node_keys
    EXCEPTIONS
      failed                       = 1
      cntl_system_error            = 2
      error_in_node_key_table      = 3
      dp_error                     = 4
      multiple_node_selection_only = 5
      OTHERS                       = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " find_role_tree

*&---------------------------------------------------------------------*
*&      Form  find_position_tree
*&---------------------------------------------------------------------*
*       Find position ID in tree
*----------------------------------------------------------------------*
FORM find_position_tree.
  DATA: BEGIN OF lt_values OCCURS 0,
*        line(255) TYPE c,
          line TYPE /psyng/text60,
        END OF lt_values.

  DATA: lt_fields     TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return     TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_node_keys  TYPE treev_nks,
        l_node_key    TYPE tv_nodekey,
        l_positionid  TYPE /psyng/position-positionid,
        l_description TYPE /psyng/position-description.


  lt_fields-tabname   = '/PSYNG/POSITION'.
  lt_fields-fieldname = 'POSITIONID'.
  APPEND lt_fields.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.

* Get values for popup
  SELECT positionid description INTO (l_positionid, l_description)
         FROM /psyng/position ORDER BY positionid.
    lt_values-line = l_positionid.
    APPEND lt_values.
    lt_values-line = l_description.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'POSITIONID'
    TABLES
      value_tab       = lt_values
      field_tab       = lt_fields
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  CHECK sy-subrc = 0.
  l_node_key = lt_return-fieldval.
  APPEND l_node_key TO lt_node_keys.

************************************************************
**  Case#1939
**  Changes made to clear last select operation in the tree

  CALL METHOD g_left_tree->unselect_all
    EXCEPTIONS
      failed            = 1
      cntl_system_error = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
************************************************************

  CALL METHOD g_left_tree->select_nodes
    EXPORTING
      node_key_table               = lt_node_keys
    EXCEPTIONS
      failed                       = 1
      cntl_system_error            = 2
      error_in_node_key_table      = 3
      dp_error                     = 4
      multiple_node_selection_only = 5
      OTHERS                       = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " find_position_tree
*---------------------------------------------------------------------*
*       FORM handle_download_error                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_SY_SUBRC                                                    *
*  -->  P_FILENAME                                                    *
*  -->  P_MSG                                                         *
*---------------------------------------------------------------------*
FORM handle_download_error USING    p_sy_subrc
                                    p_filename
                                    p_msg.
  DATA: l_msgv1 TYPE bapiret2-message_v1,
        l_msgv2 TYPE bapiret2-message_v2.


  l_msgv1 = p_filename.
  l_msgv2 = p_msg.
  CALL FUNCTION '/PSYNG/BC_003'
    EXPORTING
      i_subrc = sy-subrc
      i_msgty = 'I'
      i_msgv1 = l_msgv1
      i_msgv2 = l_msgv2.
ENDFORM.                    " handle_download_error
*---------------------------------------------------------------------*
*       FORM handle_upload_error                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_SY_SUBRC                                                    *
*  -->  P_FILENAME                                                    *
*  -->  P_MSG                                                         *
*---------------------------------------------------------------------*
FORM handle_upload_error USING    p_sy_subrc
                                  p_filename
                                  p_msg.
  DATA: l_msgv1 TYPE bapiret2-message_v1,
        l_msgv2 TYPE bapiret2-message_v2.


  l_msgv1 = p_filename.
  l_msgv2 = p_msg.
  CALL FUNCTION '/PSYNG/BC_004'
    EXPORTING
      i_subrc = sy-subrc
      i_msgty = 'I'
      i_msgv1 = l_msgv1
      i_msgv2 = l_msgv2.
ENDFORM.                    " handle_error

*&---------------------------------------------------------------------*
*&      Form  release_locked
*&---------------------------------------------------------------------*
*       Release locked records
*----------------------------------------------------------------------*
FORM release_locked.
  DATA: l_funid   TYPE /psyng/function-function,
        l_conid   TYPE /psyng/conflict-conid,
        l_swaudid TYPE /psyng/swaudhdr-swaudid,
        l_tabname TYPE /psyng/tablevers-tabname.


  CHECK gf_dispchg = gc_change.

  LOOP AT gt_locked.
    CASE gt_locked-type.
      WHEN 'FUNCTION'.
        l_funid = gt_locked-object.
        CALL FUNCTION 'DEQUEUE_/PSYNG/FUNCTION'
          EXPORTING
            function = l_funid
            vrsio    = g_sod_vrsio.

      WHEN 'CONFLICT'.
        l_conid = gt_locked-object.
        CALL FUNCTION 'DEQUEUE_/PSYNG/CONFLICT'
          EXPORTING
            conid = l_conid
            vrsio = g_sod_vrsio.

      WHEN 'SWAUDHDR'.
        l_swaudid = gt_locked-object.
        CALL FUNCTION 'DEQUEUE_/PSYNG/SWAUDHDR'
          EXPORTING
            swaudid = l_swaudid
            vrsio   = g_sod_vrsio.

      WHEN 'TABLEVERS'.
        l_tabname = gt_locked-object.
        CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
          EXPORTING
            tabname = l_tabname
            vrsio   = g_sod_vrsio.
    ENDCASE.
  ENDLOOP.
ENDFORM.                    " release_locked

*&---------------------------------------------------------------------*
*&      Form  get_aud_msgtyp
*&---------------------------------------------------------------------*
*       Get message type for mitigation auditor same as user message
*----------------------------------------------------------------------*
*      <--E_MSGTYP  Message type
*----------------------------------------------------------------------*
FORM get_aud_msgtyp CHANGING e_msgtyp TYPE /psyng/swconfig-value.
  se_config_param 'MIT_AUDT_EQ_USR_MSG' e_msgtyp.
  CASE e_msgtyp.
    WHEN 'E' OR 'W'.
*     Do nothing
    WHEN space.
      e_msgtyp = 'E'.
    WHEN OTHERS.
      e_msgtyp = 'E'.
  ENDCASE.
ENDFORM.                    " get_aud_msgtyp

*&---------------------------------------------------------------------*
*&      Form  get_apr_msgtyp
*&---------------------------------------------------------------------*
*       Get message type for mitigation approver same as user message
*----------------------------------------------------------------------*
*      <--E_MSGTYP  Message type
*----------------------------------------------------------------------*
FORM get_apr_msgtyp CHANGING e_msgtyp TYPE /psyng/swconfig-value.
  se_config_param 'MIT_APRV_EQ_USR_MSG' e_msgtyp.
  CASE e_msgtyp.
    WHEN 'E' OR 'W'.
*     Do nothing
    WHEN space.
      e_msgtyp = 'E'.
    WHEN OTHERS.
      e_msgtyp = 'E'.
  ENDCASE.
ENDFORM.                    " get_apr_msgtyp

*&---------------------------------------------------------------------*
*&      Form  get_val_mit_aud
*&---------------------------------------------------------------------*
*       Get parameter to validate mitigation auditor
*----------------------------------------------------------------------*
FORM get_val_mit_aud.
  DATA: l_value TYPE /psyng/swconfig-value.
  se_config_param 'MIT_AUDT_HDR_LIST' l_value.
  IF l_value = 'Y'.
    gf_val_mit_aud = l_value.
  ELSE.
    gf_val_mit_aud = 'N'.
  ENDIF.
ENDFORM.                    " get_val_mit_aud

*&---------------------------------------------------------------------*
*&      Form  get_comp_name
*&---------------------------------------------------------------------*
*       Get user's company name from company ID
*----------------------------------------------------------------------*
*      <->I_COMPANY    Company ID
*      <--E_COMP_NAME  Company Name
*----------------------------------------------------------------------*
FORM get_comp_name CHANGING i_company   "TYPE /psyng/mcauditor-company
                            e_comp_name ."TYPE /psyng/mcauditor-company.

  TYPES: BEGIN OF t_comp,
           comp TYPE /psyng/mcauditor-company,
           name TYPE /psyng/mcauditor-company,
         END OF t_comp.

  DATA: l_value  TYPE /psyng/swconfig-value,
        l_fmname TYPE rs38l_fnam,
        ls_comp  TYPE t_comp,
        l_comp   TYPE uscomp,
        l_text   TYPE uscomp.

  STATICS: lt_comp TYPE HASHED TABLE OF t_comp WITH UNIQUE KEY comp.


  READ TABLE lt_comp INTO ls_comp WITH TABLE KEY comp = i_company.
  IF sy-subrc = 0.
    e_comp_name = ls_comp-name.
    EXIT.
  ENDIF.

* Check what FM is configured for Company name
  SELECT SINGLE value INTO l_value FROM /psyng/swconfig
                WHERE param = 'SW_MGMT_COMP_NAME_FM'.
  IF sy-subrc = 0.
    l_fmname = l_value.
    IF NOT l_fmname IS INITIAL.
      CALL FUNCTION 'FUNCTION_EXISTS'
        EXPORTING
          funcname           = l_fmname
        EXCEPTIONS
          function_not_exist = 1
          OTHERS             = 2.
      IF sy-subrc <> 0.
        CLEAR l_fmname.
*       Configured FM does not exist, use default
        MESSAGE s113(/psyng/sw) WITH
                'Cannot determine SW_MGMT_COMP_NAME_FM with FM '
                ls_fmname '. FM doesn''t exist'.
      ENDIF.
    ENDIF.
  ELSE.
    l_fmname = '/PSYNG/SW_086'.
  ENDIF.
  IF NOT l_fmname IS INITIAL.
    l_comp = i_company.
    CALL FUNCTION l_fmname                   "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
      EXPORTING
        i_company   = l_comp
      IMPORTING
        e_comp_name = l_text.
    e_comp_name  = l_text.
    ls_comp-comp = i_company.
    ls_comp-name = e_comp_name.
    INSERT ls_comp INTO TABLE lt_comp.
  ENDIF.
ENDFORM.                    " get_comp_name

*&---------------------------------------------------------------------*
*&      Form  get_entry_point
*&---------------------------------------------------------------------*
*       Get initial entry point of transaction
*----------------------------------------------------------------------*
FORM get_entry_point.
  DATA: l_dynnr TYPE sy-dynnr.


  IMPORT g_dynnr TO l_dynnr FROM MEMORY ID '/PSYNG/DYNNR'.
  IF l_dynnr IS INITIAL.
*   Get user's start tab
    PERFORM get_start_tab.
    EXIT.
  ENDIF.
  gf_custom_tab_selected = 'X'.

  CASE l_dynnr.
    WHEN '0201'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab2.
      g_sodfun-pressed_tab    = c_sodfun-tab1.
    WHEN '0202'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab2.
      g_sodfun-pressed_tab    = c_sodfun-tab2.
    WHEN '0209'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab2.
      g_sodfun-pressed_tab    = c_sodfun-tab6.
    WHEN '0211'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab2.
      g_sodfun-pressed_tab    = c_sodfun-tab4.
      g_mitcon-pressed_tab    = c_mitcon-tab1.
    WHEN '0212'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab2.
      g_sodfun-pressed_tab    = c_sodfun-tab4.
      g_mitcon-pressed_tab    = c_mitcon-tab2.
    WHEN OTHERS.
*--Any invalid value will use HOME-tab as start tab
      g_yx_sectab-pressed_tab = c_yx_sectab-tab1.
      CLEAR gf_custom_tab_selected.

  ENDCASE.

  FREE MEMORY ID '/PSYNG/DYNNR'.
ENDFORM.                    " get_entry_point

*&---------------------------------------------------------------------*
*&      Form  get_start_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_start_tab.
  DATA: l_parva   TYPE usr05-parva,
        l_value   TYPE /psyng/swconfig-value,
        l_hometab TYPE sy-dynnr.
  gf_custom_tab_selected = 'X'.
* Get user's default version
  SELECT SINGLE parva INTO l_parva FROM usr05
                WHERE bname = g_current_user "sy-uname C0700
                  AND parid = '/PSYNG/SE_HOMETAB'.

  IF sy-subrc <> 0 OR l_parva IS INITIAL.
    l_parva = 'HOME'.
    CLEAR gf_custom_tab_selected.
  ENDIF.
  CASE l_parva.
    WHEN 'HOME'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab1.
    WHEN 'CONREP'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab2.
    WHEN 'ROLES'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab3.
    WHEN 'POSITIONS'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab4.
    WHEN 'UASSIGN' .
      g_yx_sectab-pressed_tab = c_yx_sectab-tab5.
    WHEN 'MONITOR'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab6.
    WHEN 'MISC'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab7.
    WHEN 'DASHBOARD'.
      g_yx_sectab-pressed_tab = c_yx_sectab-tab8.
    WHEN OTHERS.
*--Any invalid value will use HOME-tab as start tab
      g_yx_sectab-pressed_tab = c_yx_sectab-tab1.
      CLEAR gf_custom_tab_selected.
  ENDCASE.



ENDFORM.                    " get_start_tab

*&---------------------------------------------------------------------*
*&      Form  toggle_pfcg_desc
*&---------------------------------------------------------------------*
*       Toggle between role description and PFCG name
*----------------------------------------------------------------------*
FORM toggle_pfcg_desc.
  TYPES: BEGIN OF t_role,
           roleid      TYPE /psyng/rolehdr-roleid,
           desc        TYPE /psyng/rolehdr-description,
           saptechname TYPE /psyng/rolehdr-saptechname,
         END OF t_role.

  STATICS: lt_role TYPE TABLE OF t_role WITH HEADER LINE.

  FIELD-SYMBOLS: <node> LIKE LINE OF left_node_table.


  IF lt_role[] IS INITIAL.
    SELECT roleid description saptechname INTO TABLE lt_role
           FROM /psyng/rolehdr ORDER BY roleid.
  ENDIF.

  IF gf_disp_pfcg IS INITIAL.
    gf_disp_pfcg = 'X'.
  ELSE.
    CLEAR gf_disp_pfcg.
  ENDIF.

  LOOP AT left_node_table ASSIGNING <node> WHERE node_key <> 'Root'.
    READ TABLE lt_role WITH KEY roleid = <node>-node_key
               BINARY SEARCH.

    IF gf_disp_pfcg IS INITIAL OR lt_role-saptechname IS INITIAL.
      CONCATENATE lt_role-roleid '-' lt_role-desc INTO <node>-text.
    ELSE.
      CONCATENATE lt_role-roleid '-' lt_role-saptechname
                  INTO <node>-text.
    ENDIF.
  ENDLOOP.

  LOOP AT right_node_table ASSIGNING <node> WHERE node_key <> 'Root'.
    READ TABLE lt_role WITH KEY roleid = <node>-node_key
               BINARY SEARCH.

    IF gf_disp_pfcg IS INITIAL OR lt_role-saptechname IS INITIAL.
      CONCATENATE lt_role-roleid '-' lt_role-desc INTO <node>-text.
    ELSE.
      CONCATENATE lt_role-roleid '-' lt_role-saptechname
                  INTO <node>-text.
    ENDIF.
  ENDLOOP.

  CALL METHOD g_left_tree->delete_all_nodes
    EXCEPTIONS
      failed            = 1
      cntl_system_error = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
  ENDIF.

  CALL METHOD g_left_tree->add_nodes
    EXPORTING
      table_structure_name           = '/PSYNG/MTREES'
      node_table                     = left_node_table
    EXCEPTIONS
      error_in_node_table            = 1
      failed                         = 2
      dp_error                       = 3
      table_structure_name_not_found = 4
      OTHERS                         = 5.
  IF sy-subrc <> 0.
  ENDIF.

  CALL METHOD g_right_tree->delete_all_nodes
    EXCEPTIONS
      failed            = 1
      cntl_system_error = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
  ENDIF.

  CALL METHOD g_right_tree->add_nodes
    EXPORTING
      table_structure_name           = '/PSYNG/MTREES'
      node_table                     = right_node_table
    EXCEPTIONS
      error_in_node_table            = 1
      failed                         = 2
      dp_error                       = 3
      table_structure_name_not_found = 4
      OTHERS                         = 5.
  IF sy-subrc <> 0.
  ENDIF.

* Expand the root nodes
  CALL METHOD g_left_tree->expand_node
    EXPORTING
      node_key            = 'Root'
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.

  CALL METHOD g_right_tree->expand_node
    EXPORTING
      node_key            = 'Root'
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5.
  IF sy-subrc <> 0.
*    MESSAGE A000.
  ENDIF.
ENDFORM.                    " toggle_pfcg_desc
*&---------------------------------------------------------------------*
*&      Form  authority_check_userid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SEC_ACTVT  text
*      -->P_/PSYNG/USER_USERID  text
*----------------------------------------------------------------------*
FORM authority_check_userid  USING activity userid.
  CHECK NOT activity IS INITIAL.
  IF NOT userid IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_UASMT'
             ID 'ACTVT' FIELD activity
             ID 'Y&SW_BNAME' FIELD userid.
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_UASMT'
       ID 'ACTVT' FIELD activity
       ID 'Y&SW_BNAME' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
           IF sy-subrc <> 0.
             MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(303).
             LEAVE LIST-PROCESSING.
           ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.

  IF sy-subrc NE 0.
    CASE activity.
      WHEN '01'.
        actvt_txt = text-051.
      WHEN '02'.
        actvt_txt = text-134.
      WHEN '03'.
        actvt_txt = text-135.
      WHEN '04'.
        actvt_txt = text-136.
      WHEN '06'.
        actvt_txt = text-137.
      WHEN '22'.
        actvt_txt = text-138.
      WHEN 'DL'.
        actvt_txt = text-139.
      WHEN 'UL'.
        actvt_txt = text-140  .
      WHEN '60'.
        actvt_txt = text-155.
      WHEN '61'.
        actvt_txt = text-156.
      WHEN OTHERS.
        actvt_txt = ' '.
    ENDCASE.

    IF NOT roleid IS INITIAL.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-204 userid.
    ELSE.
      MESSAGE e108(/psyng/sw) WITH actvt_txt text-205.
    ENDIF.
  ENDIF.

ENDFORM.                    " authority_check_userid
*&---------------------------------------------------------------------*
*&      Form  init_states_0106
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_states_0106.
  DATA : l_value TYPE /psyng/swconfig-value.
*--- Check Config Param
  se_config_param 'SW_ROLES_POS_USRASGN' l_value.
  IF  l_value = 'Y'.
*-- Dont do anything with tabs
    LOOP AT SCREEN.
      IF screen-group1 = 'DOC' OR screen-group1 = 'DTU'.
        screen-invisible = 0.
        screen-input = 1.
        screen-active = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
*-- Hide
    LOOP AT SCREEN.
      IF screen-group1 = 'DOC' OR screen-group1 = 'DTU'.
        screen-invisible = 1.
        screen-input = 0.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.



  PERFORM set_most_used.

*--Load states from database
  DATA : lt_states TYPE TABLE OF /psyng/usr_displ WITH HEADER LINE.

  SELECT * FROM /psyng/usr_displ
  INTO CORRESPONDING FIELDS OF TABLE lt_states
  WHERE bname = g_current_user "sy-uname C0700
     AND repid = sy-repid.
  LOOP AT lt_states.
    MOVE-CORRESPONDING lt_states TO gt_states.
    APPEND gt_states.
  ENDLOOP.

*--Set initial status for each area in the screen
  PERFORM init_state
    USING sy-dynnr 'MOSTBUTTON'  'MOS' 'MOS' 'X'
    'Most Used Reports'(b01).

  PERFORM init_state USING
    sy-dynnr 'SODBUTTON'  'SOD' 'SOD' 'X'
    'SOD Reports'(b02).

  PERFORM init_state USING
    sy-dynnr 'CRITBUTTON' 'CRI' 'CRIT' 'X'
    'Critical Access Monitoring'(b03).
  PERFORM init_state USING
    sy-dynnr 'HISBUTTON'  'HIS' 'HIS' 'X'
    'Historical Reports'(b04).
  PERFORM init_state
    USING sy-dynnr 'MITBUTTON'  'MIT' 'MIT' 'X'
    'Mitigation Reports'(b05).
  PERFORM init_state
    USING sy-dynnr 'MGMBUTTON'  'MGM' 'MGM' 'X'
    'Management Reports'(b06).
  PERFORM init_state
    USING sy-dynnr 'USRBUTTON'  'USR' 'USR' 'X'
    'User Reports'(b07).
  PERFORM init_state
    USING sy-dynnr 'DOCBUTTON'  'DOC' 'DOC' 'X'
    'Role Documentation Reports'(b08).
  PERFORM init_state
    USING sy-dynnr 'AREBUTTON'  'ARE' 'ARE' 'X'
    'Area Menu'(b09).
  PERFORM init_state
   USING sy-dynnr 'STOBUTTON'  'STO' 'STO' 'X'
   'Stored SOD User Results'(b18).
  PERFORM init_state
   USING sy-dynnr 'STRBUTTON'  'STR' 'STR' 'X'
   'Stored SOD Role Results'(b19).

*--Set status of each screen so it corresponds with what's in the table
  LOOP AT gt_states WHERE screen =  sy-dynnr.
    PERFORM update_state USING gt_states.
  ENDLOOP.

ENDFORM.                    " init_states_0106
*&---------------------------------------------------------------------*
*&      Form  init_states_0107
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_states_0107.

  DATA : l_value TYPE /psyng/swconfig-value.
*--- Check Config Param
  se_config_param 'SW_ROLES_POS_USRASGN' l_value.

  IF  l_value = 'Y'.
*-- Dont do anything with tabs
    LOOP AT SCREEN.
      IF screen-group1 = 'RDC' OR
         screen-group1 = 'DTU' OR
         screen-group1 = 'COR'.
        screen-invisible = 0.
        screen-input = 1.
        screen-active = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
*-- Hide
    LOOP AT SCREEN.
      IF screen-group1 = 'RDC' OR
         screen-group1 = 'DTU' OR
         screen-group1 = 'COR'.
        screen-invisible = 1.
        screen-input = 0.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  se_config_param 'CFG_SET_ENABLED' l_value.
  IF NOT ( l_value EQ 'Y' OR l_value EQ 'X' ).
*--Hide Config Sets if disabled
    LOOP AT SCREEN.
      IF screen-group1  = 'SET' OR
         screen-name    = 'SETBUTTON' .
        screen-invisible = 1.
        screen-input = 0.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
*--Hide Org Areas, Variable Elements and Auto Org if enabled
    LOOP AT SCREEN.
      IF screen-name = 'CON6' OR
         screen-name = 'AORGBUT' OR
         screen-name = 'VARELBUT'.
        screen-invisible = 1.
        screen-input = 0.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
*--If org level override is not enabled, hide the button
    se_config_param 'ORG_LVL_OVERRIDE' l_value.
    IF NOT ( l_value EQ 'Y' OR l_value EQ 'X' ).
      LOOP AT SCREEN.
        IF screen-name = 'CFG_CUS'.
          screen-invisible = 1.
          screen-input = 0.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*--Hide dynamic enhancement buffering if disabled
  se_config_param 'SW_ENH_BUFFER' l_value.
  IF NOT ( l_value EQ 'Y' OR l_value EQ 'X' ).
    LOOP AT SCREEN.
      IF screen-name = 'ENHBUFFER'.
        screen-invisible = 1.
        screen-input = 0.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.



*--Load states from database
  DATA : lt_states TYPE TABLE OF /psyng/usr_displ WITH HEADER LINE.

  SELECT * FROM /psyng/usr_displ
  INTO CORRESPONDING FIELDS OF TABLE lt_states
  WHERE bname = g_current_user "sy-uname C0700
    AND repid = sy-repid.
  LOOP AT lt_states.
    MOVE-CORRESPONDING lt_states TO gt_states.
    APPEND gt_states.
  ENDLOOP.

*--Set initial status for each area in the screen
  PERFORM init_state USING
    sy-dynnr 'CONBUTTON' 'CON' 'CON' 'X'
    'Configuration'(b10).
  PERFORM init_state USING
    sy-dynnr 'CORBUTTON' 'COR' 'COR' 'X'
    'Role Configuration'(b11).
  PERFORM init_state USING
    sy-dynnr 'REPBUTTON' 'REP' 'REP' 'X'
    'Conflict Repository'(b12).
  PERFORM init_state USING
    sy-dynnr 'VERBUTTON'  'VER' 'VER' 'X'
    'Version Management'(b13).
  PERFORM init_state
    USING sy-dynnr 'DIABUTTON'  'DIA' 'DIA' 'X'
    'Diagnostics'(b14).
  PERFORM init_state
    USING sy-dynnr 'RDCBUTTON'  'RDC' 'RDC' 'X'
    'Role Management'(b15).
  PERFORM init_state
    USING sy-dynnr 'MITBUTTON'  'MIT' 'MIT' 'X'
    'Mitigations'(b16).
  PERFORM init_state
    USING sy-dynnr 'SETBUTTON'  'SET' 'SET' 'X'
    'Configuration Sets'(b17).

*--Set status of each screen so it corresponds with what's in the table
  LOOP AT gt_states WHERE screen =  sy-dynnr.
    PERFORM update_state USING gt_states.
  ENDLOOP.




ENDFORM.                    " init_states_0107

*&---------------------------------------------------------------------*
*&      Form  init_state
*&---------------------------------------------------------------------*
*       Generic code to initialize buttons
*----------------------------------------------------------------------*
*      -->P_0069   text
*      -->P_0070   text
*      -->P_0071   text
*----------------------------------------------------------------------*
FORM init_state USING    i_screen TYPE sy-dynnr
                         i_button TYPE scrfname
                         i_group  TYPE scrfname
                         i_ucomm  TYPE sy-ucomm
                         i_expanded TYPE flag
                         i_button_text TYPE string.
*--Initialize state if not yet done

  READ TABLE gt_states WITH KEY
  screen = i_screen button_name = i_button.
  IF sy-subrc <> 0.
    gt_states-screen =      i_screen.
    gt_states-ucomm =       i_ucomm.
    gt_states-button_name = i_button.
    gt_states-group_name =  i_group.
    gt_states-expanded =    i_expanded.
    gt_states-button_text = i_button_text.
    APPEND gt_states.
  ELSE.
    gt_states-button_text = i_button_text.
    MODIFY  gt_states
    TRANSPORTING button_text
    WHERE screen = i_screen AND button_name = i_button.
  ENDIF.

ENDFORM.                    " init_state
*&---------------------------------------------------------------------*
*&      Form  update_state
*&---------------------------------------------------------------------*
*        Generic code to show/hide areas
*----------------------------------------------------------------------*
*      -->P_GT_STATES  text
*----------------------------------------------------------------------*
FORM update_state USING i_state TYPE type_state.
  FIELD-SYMBOLS : <btn> TYPE any.
  ASSIGN (i_state-button_name) TO <btn>.     "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
  CHECK sy-subrc = 0.
  IF i_state-expanded = 'X'.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name                  = 'ICON_COLLAPSE'
        text                  = i_state-button_text
        info                  = 'Collapse'(cc1)
      IMPORTING
        result                = <btn>
      EXCEPTIONS
        icon_not_found        = 1
        outputfield_too_short = 2
        OTHERS                = 3.
    "(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.
    LOOP AT SCREEN .
      IF screen-name = i_state-button_name.
        screen-display_3d  = '1'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-group1 = i_state-group_name.
        screen-invisible = '0'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-group1 = 'INV'.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.
  ELSE.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name                  = 'ICON_EXPAND'
        text                  = i_state-button_text
        info                  = 'Expand'(cc2)
      IMPORTING
        result                = <btn>
      EXCEPTIONS
        icon_not_found        = 1
        outputfield_too_short = 2
        OTHERS                = 3.
    "(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.
    LOOP AT SCREEN .
      IF screen-name = i_state-button_name.
        screen-display_3d  = '1'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-group1 = i_state-group_name.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.
      IF screen-group1 = 'INV'.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.
  ENDIF.


ENDFORM.                    " update_state
*&---------------------------------------------------------------------*
*&      Form  set_state
*&---------------------------------------------------------------------*
*       Generic code to toggle state
*----------------------------------------------------------------------*
*      -->P_SY_UCOMM  text
*----------------------------------------------------------------------*
FORM set_state USING    i_ucomm TYPE sy-ucomm.
*--Toggle state
  READ TABLE gt_states WITH KEY ucomm = sy-ucomm screen = sy-dynnr.
  IF sy-subrc = 0.
    IF gt_states-expanded = 'X'.
      CLEAR gt_states-expanded.
    ELSE.
      gt_states-expanded = 'X'.
    ENDIF.
    MODIFY gt_states  TRANSPORTING expanded WHERE ucomm = i_ucomm AND
                                                  screen = sy-dynnr .
    DATA : ls_state TYPE /psyng/usr_displ.
    MOVE-CORRESPONDING gt_states TO ls_state.
    ls_state-repid = sy-repid.
    ls_state-bname = g_current_user. "sy-uname. C0700
    MODIFY /psyng/usr_displ FROM ls_state.

  ENDIF.
ENDFORM.                    " set_state

*&---------------------------------------------------------------------*
*&      Form  set_most_used
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_most_used.
  DATA : l_repid LIKE sy-repid .
  l_repid = sy-repid.
  REFRESH : gt_buttons.
  CALL FUNCTION '/PSYNG/SW_092'
    EXPORTING
      i_bname    = g_current_user "sy-uname C0700
      i_repid    = l_repid
      i_dynr     = '0106'
    TABLES
      et_buttons = gt_buttons.



  FIELD-SYMBOLS : <btn>    TYPE any,
                  <button> TYPE /psyng/sw_most_used_reports.
  CHECK sy-subrc = 0.

  DATA : l_icon       TYPE iconname,
         l_text       TYPE string,
         l_qi         TYPE iconquick,
         l_iconid     TYPE icon_d,
         l_len        TYPE i,
         l_pos        TYPE i,
         l_ismubutton TYPE flag.
  LOOP AT SCREEN.
    CLEAR l_ismubutton..

    CASE screen-name.
      WHEN 'MU_01'.
        ASSIGN mu_01 TO <btn>.
        READ TABLE gt_buttons INDEX 1 ASSIGNING <button>.
        IF sy-subrc <> 0 OR <button>-button_text IS INITIAL.
          screen-invisible = '1'.
          screen-active    = '0'.
          MODIFY SCREEN.
        ELSE.
          l_ismubutton = 'X'.
*          screen-invisible = '0'.
        ENDIF.
      WHEN 'MU_02'.
        ASSIGN mu_02 TO <btn>.
        READ TABLE gt_buttons INDEX 2 ASSIGNING <button>.
        IF sy-subrc <> 0 OR <button>-button_text IS INITIAL.
          screen-invisible = '1'.
          screen-active    = '0'.
          MODIFY SCREEN.
        ELSE.
          l_ismubutton = 'X'.
*          screen-invisible = '0'.
        ENDIF.
      WHEN 'MU_03'.
        ASSIGN mu_03 TO <btn>.
        READ TABLE gt_buttons INDEX 3 ASSIGNING <button>.
        IF sy-subrc <> 0 OR <button>-button_text IS INITIAL.
          screen-invisible = '1'.
          screen-active    = '0'.
          MODIFY SCREEN.
        ELSE.
          l_ismubutton = 'X'.
*          screen-invisible = '0'.
        ENDIF.
      WHEN 'MU_04'.
        ASSIGN mu_04 TO <btn> .
        READ TABLE gt_buttons INDEX 4 ASSIGNING <button>.
        IF sy-subrc <> 0 OR <button>-button_text IS INITIAL.
          screen-invisible = '1'.
          screen-active    = '0'.
          MODIFY SCREEN.
        ELSE.
          l_ismubutton = 'X'.
*          screen-invisible = '0'.
        ENDIF.
      WHEN 'MU_05'.
        ASSIGN mu_05 TO <btn> .
        READ TABLE gt_buttons INDEX 5 ASSIGNING <button>.
        IF sy-subrc <> 0 OR <button>-button_text IS INITIAL.
          screen-invisible = '1'.
          screen-active    = '0'.
          MODIFY SCREEN.
        ELSE.
          l_ismubutton = 'X'.
*          screen-invisible = '0'.
        ENDIF.

    ENDCASE.
    IF l_ismubutton = 'X'.
      l_pos = 1.
      IF <button>-button_text(l_pos) = '@'.
        SEARCH <button>-button_text FOR '\Q'.
        IF sy-subrc = 0.
          l_len = sy-fdpos - l_pos.
          CONCATENATE '@'
          <button>-button_text+l_pos(l_len)
          '@'
          INTO  l_iconid.
          l_pos = l_pos + l_len + 2.
          SEARCH <button>-button_text FOR '@' STARTING AT l_pos.

          l_pos = l_pos + sy-fdpos.                         " + 1.
          l_len = strlen( <button>-button_text ).
          l_len = l_len - l_pos .
          l_text = <button>-button_text+l_pos(l_len).
          CONDENSE l_text.
*          data : l_space type c.
*          if l_text(1) = l_space or l_text(1) is initial.
*            l_len = strlen( l_text ) - 1.
*            l_text = l_text+1(l_len).
*          endif.
*          Get button text
        ELSE.
          CONCATENATE '@'
          <button>-button_text+1(2)
          '@'
           INTO l_iconid .
          l_len = strlen( <button>-button_text ) - 5.
          l_text = <button>-button_text+5(l_len).
        ENDIF.

*        l_pos = l_pos + l_len.
*        l_len = strlen( <button>-button_text ) - l_pos.
*        add 2 to l_pos.
*        l_qi = <button>-button_text+l_pos(l_len).
        l_qi = <button>-uses.
        CONCATENATE l_qi 'times'(u01)
        INTO l_qi SEPARATED BY space.
        SELECT SINGLE name INTO l_icon FROM icon WHERE id = l_iconid .
        CALL FUNCTION 'ICON_CREATE'
          EXPORTING
            name                  = l_icon
            text                  = l_text
*           info                  = l_qi
            add_stdinf            = ' '
          IMPORTING
            result                = <btn>
          EXCEPTIONS
            icon_not_found        = 1
            outputfield_too_short = 2
            OTHERS                = 3.
        IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                 WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ENDIF.
      ENDIF.



      <button>-button_id = screen-name.
*      <btn> = <button>-BUTTON_TEXT.


    ENDIF.
  ENDLOOP.
ENDFORM.                    " set_most_used
*&---------------------------------------------------------------------*
*&      Form  f4_help_version
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_MCUSRGRP_VRSIO  text
*----------------------------------------------------------------------*
FORM f4_help_version
CHANGING p_version TYPE /psyng/mcusrgrp-vrsio.
  DATA : lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname           = '/PSYNG/MCUSRGRP'
      fieldname         = 'VRSIO'
      searchhelp        = '/PSYNG/SODVRSIO'
    TABLES
      return_tab        = lt_return
    EXCEPTIONS
      field_not_found   = 1
      no_help_for_field = 2
      inconsistent_help = 3
      no_values_found   = 4
      OTHERS            = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  p_version = lt_return-fieldval.

ENDFORM.                    " f4_help_version
*&---------------------------------------------------------------------*
*&      Form  f4_help_auditor
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_MCCAUSER_VRSIO  text
*----------------------------------------------------------------------*
FORM f4_help_auditor CHANGING p_auditor TYPE /psyng/mccauser-auditor.

  DATA: mit_audt_hdr_list TYPE /psyng/swconfig-value,
        ls_shlp           TYPE shlp_descr_t.
  DATA: BEGIN OF lt_auditor OCCURS 0,
          auditor TYPE /psyng/mcauditor-auditor,
          contid  TYPE /psyng/mcauditor-contid,
          company TYPE /psyng/mcauditor-company,
        END OF lt_auditor.
  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        wa_return LIKE LINE OF lt_return.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        l_repid   TYPE sy-repid.

  l_repid = sy-repid.

  se_config_param 'MIT_AUDT_HDR_LIST' mit_audt_hdr_list.
  IF mit_audt_hdr_list = 'Y'.
    SELECT auditor contid  company INTO TABLE lt_auditor FROM
  /psyng/mcauditor.
    CHECK sy-subrc EQ 0.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = 'AUDITOR'
        dynpprog        = l_repid
        dynpnr          = sy-dynnr
        window_title    = 'Auditors'
        value_org       = 'S'
      TABLES
        value_tab       = lt_auditor
        return_tab      = lt_return
      EXCEPTIONS
        parameter_error = 1
        no_values_found = 2
        OTHERS          = 3.
    "(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.
    READ TABLE lt_return INTO wa_return INDEX 1.
    p_auditor = wa_return-fieldval.
  ELSE.
    CALL FUNCTION 'F4IF_GET_SHLP_DESCR'
      EXPORTING
        shlpname = 'USER_COMP'
        shlptype = 'SH'
      IMPORTING
        shlp     = ls_shlp.


    CALL FUNCTION 'F4IF_START_VALUE_REQUEST'
      EXPORTING
        shlp          = ls_shlp
      TABLES
        return_values = lt_return.
    READ TABLE lt_return INTO wa_return INDEX 1.
    p_auditor = wa_return-fieldval.

  ENDIF.
ENDFORM.                    " f4_help_auditor
*&---------------------------------------------------------------------*
*&      Form  sort_col
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SORT_TYPE  text
*----------------------------------------------------------------------*
FORM sort_col USING  p_sort_type.

  REFRESH fld_list.
  LOOP AT tc_conowner-cols INTO col.
    IF col-selected = 'X'.
      APPEND col TO fld_list.
    ENDIF.
  ENDLOOP.
  SORT fld_list BY index.
  CLEAR:fldname.
  READ TABLE fld_list INDEX 1 INTO col.
  fldname = col-screen-name+12.
  IF p_sort_type = 'A'.
    SORT gt_conowner BY (fldname) ASCENDING.
  ELSE.
    SORT gt_conowner BY (fldname) DESCENDING.
  ENDIF.


ENDFORM.                    " sort_col
*&---------------------------------------------------------------------*
*&      Form  sort_col_mc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SORT_TYPE  text
*----------------------------------------------------------------------*
FORM sort_col_mc USING    p_sort_type.

  REFRESH fld_list.
  LOOP AT tc_mcauditor-cols INTO col WHERE selected = 'X'.
    APPEND col TO fld_list.
  ENDLOOP.
  SORT fld_list BY index.
  CLEAR:fldname.
  READ TABLE fld_list INDEX 1 INTO col.
  fldname = col-screen-name+13.
  IF p_sort_type = 'A'.
    SORT gt_mcauditor BY (fldname) ASCENDING.
  ELSE.
    SORT gt_mcauditor BY (fldname) DESCENDING.
  ENDIF.

ENDFORM.                    " sort_col_mc
*&---------------------------------------------------------------------*
*&      Form  popup_long_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_TRANS_ITAB_DESCRIPTION  text
*----------------------------------------------------------------------*
FORM popup_long_text.
  DATA: l_text     TYPE /psyng/longtextfield,
        e_desc     TYPE /psyng/longtextfield,
        texts      TYPE TABLE OF /psyng/texts WITH HEADER LINE,
        l_prev_len TYPE i,
        title(80)  TYPE c.

*  CLEAR gt_editor_text. REFRESH gt_editor_text.
*
*  IF gt_editor_text[] IS INITIAL.
*
*  ELSE.
*    READ TABLE gt_editor_text INTO l_text INDEX 1.
*    l_text(72) = e_desc(72).
*    MODIFY gt_editor_text FROM l_text INDEX 1.
*    READ TABLE gt_editor_text INTO l_text INDEX 2.
*    IF sy-subrc = 0.
*      l_text(60) = e_desc+72.
*      MODIFY gt_editor_text FROM l_text INDEX 2.
*    ELSE.
*      l_text = e_desc+72.
*      APPEND l_text TO gt_editor_text.
*    ENDIF.
*  ENDIF.

*  CONDENSE gtitle NO-GAPS.
  CALL SCREEN 300 STARTING AT 3 3 ENDING AT 85 9.
  CLEAR e_desc.
  LOOP AT gt_editor_text INTO l_text.
    IF sy-tabix = 1.
      e_desc = l_text.
      l_prev_len = strlen( l_text ).
      CONTINUE.
    ENDIF.

    IF l_prev_len < 72.
      CONCATENATE e_desc l_text INTO e_desc SEPARATED BY space.
    ELSE.
      CONCATENATE e_desc l_text INTO e_desc.
    ENDIF.

    l_prev_len = strlen( l_text ).
  ENDLOOP.

ENDFORM.                    " popup_long_text
*&---------------------------------------------------------------------*
*&      Form  display_change
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SY_DYNNR  text
*----------------------------------------------------------------------*
FORM display_change USING    p_sy_dynnr.

  CASE p_sy_dynnr.

    WHEN '0201' OR '0229' OR '0230'.

      IF gf_dispchg = gc_display.                    "Display
        LOOP AT SCREEN.
          IF screen-group1 = '001' AND screen-input = 1.
            screen-input = 0.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ELSE.                                          "Change
        LOOP AT SCREEN.

          IF screen-group1 = '208' AND
                                NOT tstct-tcode IS INITIAL. "TSTCT-TCODE
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '208' AND
                                tstct-tcode IS INITIAL.
            CHECK sy-ucomm = 'INSR'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.


          IF screen-group1 = '230' AND
                    NOT /psyng/sw_fioria-fioriid IS INITIAL.
            CHECK sy-ucomm = 'INSR'.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '230' AND
                 /psyng/sw_fioria-fioriid IS INITIAL.
            CHECK sy-ucomm = 'INSR'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.


    WHEN '0202'.

      IF gf_dispchg = gc_display.                    "Display
        LOOP AT SCREEN.
          IF screen-group1 = '001' AND screen-input = 1.
            screen-input = 0.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ELSE.                                          "Change
        LOOP AT SCREEN.

          IF screen-group1 = '202' AND
                            NOT /psyng/functtran-functionid IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '202' AND
                            /psyng/functtran-functionid IS INITIAL.
            CHECK sy-ucomm = 'INSR'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.


    WHEN '0211' OR '0227'.

      IF gf_dispchg = gc_display.                    "Display

        LOOP AT SCREEN.
          IF screen-group1 = '001' AND screen-input = 1.
            screen-input = 0.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ELSE.                                          "Change
        LOOP AT SCREEN.

          IF screen-group1 = '21T'
                      AND NOT gt_mctran-tcode IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '21T'
                      AND gt_mctran-tcode IS INITIAL.
            CHECK sy-ucomm = 'MCTRAN_INSR'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.


          IF screen-group1 = '21A'
                     AND NOT gt_mcauditor-auditor IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '21A'
                      AND gt_mcauditor-auditor IS INITIAL.
            CHECK sy-ucomm = 'MCAUDITOR_INSR'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.

          IF screen-group1 = '21R'
                     AND NOT gt_mcrepid-repid IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '21R'
                     AND gt_mcrepid-repid IS INITIAL.
            CHECK sy-ucomm = 'MCREPID_INSR'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.


        ENDLOOP.
      ENDIF.
    WHEN '0208'.

      IF gf_dispchg = gc_display.                    "Display
        LOOP AT SCREEN.
          IF screen-group1 = '001' AND screen-input = 1.
            screen-input = 0.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ELSE.                                          "Change
        LOOP AT SCREEN.

          IF screen-group1 = '208' AND
                                NOT tstct-tcode IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '208' AND
                                tstct-tcode IS INITIAL.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.

    WHEN '0210'.

      IF gf_dispchg = gc_display.                    "Display
        LOOP AT SCREEN.
          IF screen-group1 = '001' AND screen-input = 1.
            screen-input = 0.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ELSE.                                          "Change
        LOOP AT SCREEN.

          IF screen-group1 = '210' AND
                                NOT agr_texts-agr_name IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '210' AND
                                agr_texts-agr_name IS INITIAL.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.

    WHEN '0213'.

      IF gf_dispchg = gc_display.                    "Display
        LOOP AT SCREEN.
          IF screen-group1 = '001' AND screen-input = 1.
            screen-input = 0.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ELSE.                                          "Change
        LOOP AT SCREEN.

          IF screen-group1 = '213' AND
                                NOT g_profile IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '213' AND
                                g_profile IS INITIAL.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.

    WHEN '0302'.

      IF gf_dispchg = gc_display.                    "Display
        LOOP AT SCREEN.
          IF screen-group1 = '001' AND screen-input = 1.
            screen-input = 0.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ELSE.                                          "Change
        LOOP AT SCREEN.

          IF screen-group1 = '302' AND
                            NOT tstct-tcode IS INITIAL.
            screen-input = 0.
            MODIFY SCREEN.
          ELSEIF screen-group1 = '302' AND
                            tstct-tcode IS INITIAL.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.

  ENDCASE.
ENDFORM.                    " display_change

*** For Future Use
*&---------------------------------------------------------------------
*
*&      Form  update_function
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------
*
*FORM update_function.
*  DATA :l_answer TYPE c.
*  DATA l_function TYPE /psyng/function-function.
*  DATA: funcopied, funhdr, funtc, funtxt.
*
*
*  CHECK gf_dispchg = gc_change.
*  CHECK NOT /psyng/functtran-functionid IS INITIAL.
*  CHECK NOT gt_func_pop[] IS INITIAL.
*  READ TABLE gt_func_pop WITH KEY function =
*    /psyng/functtran-functionid.
*  IF sy-subrc NE 0.
*    SELECT SINGLE function INTO l_function FROM /psyng/function
*    WHERE function EQ /psyng/functtran-functionid
*    AND vrsio EQ g_sod_vrsio.
*    IF sy-subrc = 0.
**      MESSAGE i002(/psyng/sw) WITH text-213.
**      /psyng/functtran-functionid = lt_func-function.
*      CLEAR ok_code.
*      ok_code = 'ENTER'.
*      EXIT.
*    ENDIF.
*    CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
*      EXPORTING
**             DEFAULTOPTION           = '1'
*        diagnosetext1           = 'Function ID'(215)
*       diagnosetext2           = gt_func_pop-function
*       diagnosetext3           = 'Copy / Rename'(216)
*        textline1               = 'New Function ID'(217)
*       textline2               = /psyng/functtran-functionid
**             TEXTLINE3               = ' '
*        text_option1            = 'Rename'(218)
*        text_option2            = 'Copy'(219)
**             ICON_TEXT_OPTION1       =
**             ICON_TEXT_OPTION2       =
*        titel                   = 'Copy/Rename Function ID'(220)
**             START_COLUMN            = 25
**             START_ROW               = 6
**             cancel_display          = ' '
*     IMPORTING
*       answer                  = l_answer.
*  ENDIF.
*
*** For renaming function ID first we copy the existing function to new
*** function ID and then we delete the the old function ID, so for that
*** user needs create,display and delete authority.
*  IF l_answer = '1'.
*    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
*             ID 'ACTVT'      FIELD '06'
*             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
*             ID 'Y&SW_FUNCT' FIELD gt_func_pop-function.
*    IF sy-subrc <> 0.
*      MESSAGE e108(/psyng/sw) WITH text-214.
*    ENDIF.
*
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_FUNCTIONID'
*         EXPORTING
*              sourcefunctionid             = gt_func_pop-function
*              targetfunctionid             =
*/psyng/functtran-functionid
*              i_vrsio                      = g_sod_vrsio
*         IMPORTING
*              funid_copied                 = funcopied
*              funid_hdr_copied             = funhdr
*              funid_tc_copied              = funtc
*              funid_txt_copied             = funtxt
*         EXCEPTIONS
*              target_not_specified         = 1
*              not_authorized               = 2
*              target_already_exists        = 3
*              source_function_doesnt_exist = 4
*              not_authorized_to_display    = 5
*              OTHERS                       = 6.
*
*
*    CASE sy-subrc.
*      WHEN 0.
*        CALL FUNCTION '/PSYNG/SW_CR_DELETE_FUNCTION'
*             EXPORTING
*                  i_vrsio        = g_sod_vrsio
*                  i_funid        = gt_func_pop-function
*             EXCEPTIONS
*                  not_authorized = 1
*                  not_exist      = 2
*                  locked         = 3
*                  OTHERS         = 4.
*        IF sy-subrc = 0.
*          MESSAGE i208(00) WITH text-212.
*        ELSEIF sy-subrc = 1.
*          MESSAGE e108(/psyng/sw) WITH text-214 .
*        ELSE.
*          MESSAGE w103(/psyng/sw).
*          EXIT.
*        ENDIF.
*      WHEN 1.
*        MESSAGE e208(00) WITH text-093.
*      WHEN 2.
*        MESSAGE e108(/psyng/sw) WITH text-214.
*      WHEN 3.
*        MESSAGE e208(00) WITH text-095.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-096.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-097  .
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
**    ENDIF.
*
*** For copy only create & display authority is required
*  ELSEIF l_answer = '2'.
**    SELECT SINGLE function INTO l_function FROM /psyng/function
**      WHERE function EQ /psyng/functtran-functionid
**      and vrsio = g_sod_vrsio.
**    IF sy-subrc = 0.
**      MESSAGE i002(/psyng/sw) WITH text-213.
**      /psyng/functtran-functionid = gt_func_pop-function.
**      CLEAR ok_code.
**    ELSE.
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_FUNCTIONID'
*         EXPORTING
*              sourcefunctionid             = gt_func_pop-function
*              targetfunctionid             =
*/psyng/functtran-functionid
*              i_vrsio                      = g_sod_vrsio
*         IMPORTING
*              funid_copied                 = funcopied
*              funid_hdr_copied             = funhdr
*              funid_tc_copied              = funtc
*              funid_txt_copied             = funtxt
*         EXCEPTIONS
*              target_not_specified         = 1
*              not_authorized               = 2
*              target_already_exists        = 3
*              source_function_doesnt_exist = 4
*              not_authorized_to_display    = 5
*              OTHERS                       = 6.
*
*    CASE sy-subrc.
*      WHEN 0.
*        MESSAGE i208(00) WITH text-092.
*      WHEN 1.
*        MESSAGE e208(00) WITH text-093.
*      WHEN 2.
*        MESSAGE e208(00) WITH text-094.
*      WHEN 3.
*        MESSAGE e208(00) WITH text-095.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-096.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-097  .
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
**    ENDIF.
*
*  ELSE.
*    /psyng/functtran-functionid = gt_func_pop-function.
*    CLEAR ok_code.
*    ok_code = 'ENTER'.
*  ENDIF.
*ENDFORM.                    " update_function
**&---------------------------------------------------------------------
**
**&      Form  update_conflict
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------
**
*FORM update_conflict.
*  DATA :l_answer TYPE c.
*  DATA l_conid TYPE /psyng/conflict-conid.
*  DATA: concopied, conhdr, contc, contxt.
*
*  CHECK gf_dispchg = gc_change.
*  CHECK NOT /psyng/confdet-conid IS INITIAL.
*  CHECK NOT gt_conf_pop[] IS INITIAL.
*  READ TABLE gt_conf_pop WITH KEY conid =
*    /psyng/confdet-conid.
*  IF sy-subrc NE 0.
*    SELECT SINGLE conid INTO l_conid FROM /psyng/conflict
*    WHERE conid EQ /psyng/confdet-conid
*    AND vrsio = g_sod_vrsio.
*    IF sy-subrc = 0.
**      MESSAGE i002(/psyng/sw) WITH text-213.
**      /psyng/functtran-functionid = lt_func-function.
*      CLEAR ok_code.
*      ok_code = 'ENTER'.
*      EXIT.
*    ENDIF.
*    CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
*      EXPORTING
**             DEFAULTOPTION           = '1'
*        diagnosetext1           = 'Conflict ID'(221)
*       diagnosetext2           = gt_conf_pop-conid
*       diagnosetext3           = 'Copy / Rename'(216)
*        textline1               = 'New Conflict ID'(222)
*       textline2               = /psyng/confdet-conid
**             TEXTLINE3               = ' '
*        text_option1            = 'Rename'(218)
*        text_option2            = 'Copy'(219)
**             ICON_TEXT_OPTION1       =
**             ICON_TEXT_OPTION2       =
*        titel                   = 'Copy/Rename Conflict ID'(223)
**             START_COLUMN            = 25
**             START_ROW               = 6
**             cancel_display          = ' '
*     IMPORTING
*       answer                  = l_answer.
*  ENDIF.
*  IF l_answer = '1'.
*** Renaming Conflict ID
** Check whether user has acess to delete conflict id before copy
** because if user do not have access to delete then copy of conflict
** id will be created
*    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
*               ID 'ACTVT'      FIELD '06'
*               ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
*               ID 'Y&SW_CONID' FIELD gt_conf_pop-conid.
*    IF sy-subrc <> 0.
*      MESSAGE e108(/psyng/sw) WITH text-224.
*    ENDIF.
*
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_CONFLICTID'
*         EXPORTING
*              sourceconflictid             = gt_conf_pop-conid
*              targetconflictid             = /psyng/confdet-conid
*              i_vrsio                      = g_sod_vrsio
*         IMPORTING
*              conid_copied                 = concopied
*              conid_hdr_copied             = conhdr
*              conid_tc_copied              = contc
*              conid_txt_copied             = contxt
*         EXCEPTIONS
*              target_not_specified         = 1
*              target_already_exists        = 2
*              not_authorized               = 3
*              source_conflict_doesnt_exist = 4
*              not_authorized_to_display    = 5
*              dependent_funid_doesnt_exist = 6
*              OTHERS                       = 7.
*
*    CASE sy-subrc.
*      WHEN 0.
*        CALL FUNCTION '/PSYNG/SW_CR_DELETE_CONFLICT'
*             EXPORTING
*                  i_vrsio        = g_sod_vrsio
*                  i_conid        = gt_conf_pop-conid
*             EXCEPTIONS
*                  not_authorized = 1
*                  not_exist      = 2
*                  OTHERS         = 3.
*        IF sy-subrc = 0.
*          MESSAGE i208(00) WITH text-225.
*        ELSEIF sy-subrc = 2.
*          MESSAGE w103(/psyng/sw).
*          EXIT.
*        ENDIF.
*
*      WHEN 1.
*        MESSAGE e208(00) WITH text-100.
*      WHEN 2.
*        MESSAGE e208(00) WITH text-101.
*      WHEN 3.
*        MESSAGE e108(/psyng/sw) WITH text-224.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-102.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-103.
*      WHEN 6.
*        MESSAGE e208(00) WITH text-104.
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
**    ENDIF.
*
*  ELSEIF l_answer = '2'.
**    SELECT SINGLE conid INTO l_conid FROM /psyng/function
**      WHERE function EQ /psyng/functtran-functionid.
**    IF sy-subrc = 0.
**      MESSAGE i002(/psyng/sw) WITH text-213.
**      /psyng/functtran-functionid = gt_func_pop-function.
**      CLEAR ok_code.
**    ELSE.
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_CONFLICTID'
*         EXPORTING
*              sourceconflictid             = gt_conf_pop-conid
*              targetconflictid             = /psyng/confdet-conid
*              i_vrsio                      = g_sod_vrsio
*         IMPORTING
*              conid_copied                 = concopied
*              conid_hdr_copied             = conhdr
*              conid_tc_copied              = contc
*              conid_txt_copied             = contxt
*         EXCEPTIONS
*              target_not_specified         = 1
*              target_already_exists        = 2
*              not_authorized               = 3
*              source_conflict_doesnt_exist = 4
*              not_authorized_to_display    = 5
*              dependent_funid_doesnt_exist = 6
*              OTHERS                       = 7.
*
*    CASE sy-subrc.
*      WHEN 0.
*        MESSAGE i208(00) WITH text-099.
*      WHEN 1.
*        MESSAGE e208(00) WITH text-100.
*      WHEN 2.
*        MESSAGE e208(00) WITH text-101.
*      WHEN 3.
*        MESSAGE e208(00) WITH text-066.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-102.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-103.
*      WHEN 6.
*        MESSAGE e208(00) WITH text-104.
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
**    ENDIF.
*
*  ELSE.
*    /psyng/confdet-conid = gt_conf_pop-conid.
*    CLEAR ok_code.
*    ok_code = 'ENTER'.
*  ENDIF.
*ENDFORM.                    " update_conflict
**&---------------------------------------------------------------------
**
**&      Form  update_mitigation
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------
**
*FORM update_mitigation.
*  DATA :l_answer TYPE c.
*  DATA l_contid TYPE /psyng/mchdr-contid.
*  DATA: mchdrc, mcrepidc,mctranc,mcauditorc,mctextc.
*
*  CHECK gf_dispchg = gc_change.
*  CHECK NOT /psyng/mchdr-contid IS INITIAL.
*  CHECK NOT gt_mith_pop[] IS INITIAL.
*  READ TABLE gt_mith_pop WITH KEY contid =
*    /psyng/mchdr-contid.
*  IF sy-subrc NE 0.
*    SELECT SINGLE contid INTO l_contid FROM /psyng/mchdr
*    WHERE contid EQ /psyng/mchdr-contid.
*    IF sy-subrc = 0.
**      MESSAGE i002(/psyng/sw) WITH text-213.
**      /psyng/functtran-functionid = lt_func-function.
*      CLEAR ok_code.
*      ok_code = 'ENTER'.
*      EXIT.
*    ENDIF.
*    CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
*      EXPORTING
**             DEFAULTOPTION           = '1'
*        diagnosetext1           = 'Mitigation ID'(233)
*       diagnosetext2           = gt_mith_pop-contid
*       diagnosetext3           = 'Copy / Rename'(216)
*        textline1               = 'New Mitigation ID'(234)
*       textline2               = /psyng/mchdr-contid
**             TEXTLINE3               = ' '
*        text_option1            = 'Rename'(218)
*        text_option2            = 'Copy'(219)
**             ICON_TEXT_OPTION1       =
**             ICON_TEXT_OPTION2       =
*        titel                   = 'Copy/Rename Mitigation ID'(226)
**             START_COLUMN            = 25
**             START_ROW               = 6
**             cancel_display          = ' '
*     IMPORTING
*       answer                  = l_answer.
*  ENDIF.
*  IF l_answer = '1'.
**  Rename mitigation ID
** Check whether user has acess to delete mitigation id before copy
** because if user do not have access to delete then copy of mitigation
** id will be created
*    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
*            ID 'ACTVT' FIELD '06'
*            ID 'Y&SW_VRSIO' DUMMY
*            ID 'Y&SW_CNTID' FIELD gt_mith_pop-contid.
*    IF sy-subrc <> 0.
*      MESSAGE e208(00) WITH text-245.
*    ENDIF.
*
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_MIT_CONTROLS'
*         EXPORTING
*              sourcemitigationid             = gt_mith_pop-contid
*              targetmitigationid             = /psyng/mchdr-contid
*         IMPORTING
*              mitid_copied                   = mchdrc
*              mitid_rep_copied               = mcrepidc
*              mitid_aud_copied               = mcauditorc
*              mitid_tc_copied                = mctranc
*              mitid_txt_copied               = mctextc
*         EXCEPTIONS
*              target_not_specified           = 1
*              not_authorized                 = 2
*              target_already_exists          = 3
*              source_mitigation_doesnt_exist = 4
*              not_authorized_to_display      = 5
*              OTHERS                         = 6.
*    CASE sy-subrc.
*      WHEN 0.
*        CALL FUNCTION '/PSYNG/SW_CR_DELETE_MIT_CTRL'
*             EXPORTING
*                  i_contid       = gt_mith_pop-contid
*             EXCEPTIONS
*                  not_authorized = 1
*                  not_exist      = 2
*                  locked         = 3
*                  OTHERS         = 4.
*        CASE sy-subrc.
*          WHEN 0.
*            MESSAGE i208(00) WITH text-247.
*          WHEN 3.
*            MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
*                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ENDCASE.
*      WHEN 1.
*        MESSAGE e208(00) WITH text-228.
*      WHEN 2.
*        MESSAGE e208(00) WITH text-245.
*      WHEN 3.
*        MESSAGE e208(00) WITH text-230.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-231.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-232.
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
*
*  ELSEIF l_answer = '2'.
**    SELECT SINGLE conid INTO l_conid FROM /psyng/function
**      WHERE function EQ /psyng/functtran-functionid.
**    IF sy-subrc = 0.
**      MESSAGE i002(/psyng/sw) WITH text-213.
**      /psyng/functtran-functionid = gt_func_pop-function.
**      CLEAR ok_code.
**    ELSE.
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_MIT_CONTROLS'
*         EXPORTING
*              sourcemitigationid             = gt_mith_pop-contid
*              targetmitigationid             = /psyng/mchdr-contid
*         IMPORTING
*              mitid_copied                   = mchdrc
*              mitid_rep_copied               = mcrepidc
*              mitid_aud_copied               = mcauditorc
*              mitid_tc_copied                = mctranc
*              mitid_txt_copied               = mctextc
*         EXCEPTIONS
*              target_not_specified           = 1
*              not_authorized                 = 2
*              target_already_exists          = 3
*              source_mitigation_doesnt_exist = 4
*              not_authorized_to_display      = 5
*              OTHERS                         = 6.
*    CASE sy-subrc.
*      WHEN 0.
*        MESSAGE i208(00) WITH text-227.
*      WHEN 1.
*        MESSAGE e208(00) WITH text-228.
*      WHEN 2.
*        MESSAGE e208(00) WITH text-229.
*      WHEN 3.
*        MESSAGE e208(00) WITH text-230.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-231.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-232.
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
**    ENDIF.
*
*  ELSE.
*    /psyng/mchdr-contid = gt_mith_pop-contid.
*    CLEAR ok_code.
*    ok_code = 'ENTER'.
*  ENDIF.
*
*ENDFORM.                    " update_mitigation
**&---------------------------------------------------------------------
**
**&      Form  update_critical_auth
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------
**
*FORM update_critical_auth.
*  DATA :l_answer TYPE c.
*  DATA l_swaudid TYPE /psyng/swaudhdr-swaudid.
*  DATA: cahdrc,catextc,cadetc.
*
*  CHECK gf_dispchg = gc_change.
*  CHECK NOT /psyng/swaudc2-swaudid IS INITIAL.
*  CHECK NOT gt_caut_pop[] IS INITIAL.
*  READ TABLE gt_caut_pop WITH KEY swaudid =
*    /psyng/swaudc2-swaudid.
*  IF sy-subrc NE 0.
*    SELECT SINGLE swaudid INTO l_swaudid FROM /psyng/swaudhdr
*    WHERE swaudid EQ /psyng/swaudc2-swaudid.
*    IF sy-subrc = 0.
*      CLEAR ok_code.
*      ok_code = 'ENTER'.
*      EXIT.
*    ENDIF.
*    CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
*      EXPORTING
**             DEFAULTOPTION           = '1'
*        diagnosetext1           = 'Critical Auth.ID'(235)
*       diagnosetext2           = gt_caut_pop-swaudid
*       diagnosetext3           = 'Copy / Rename'(216)
*        textline1               = 'New Critical auth.ID'(236)
*       textline2               = /psyng/swaudc2-swaudid
**             TEXTLINE3               = ' '
*        text_option1            = 'Rename'(218)
*        text_option2            = 'Copy'(219)
**             ICON_TEXT_OPTION1       =
**             ICON_TEXT_OPTION2       =
*        titel                   = 'Copy/Rename Critical Auth.ID'(237)
**             START_COLUMN            = 25
**             START_ROW               = 6
**             cancel_display          = ' '
*     IMPORTING
*       answer                  = l_answer.
*  ENDIF.
*  IF l_answer = '1'.
**  Rename critical auth ID
*
** Check whether user has acess to delete CA before copy because if
** user do not have access to delete then copy of CA will be created
*    AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
*             ID 'ACTVT'      FIELD '06'
*             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio
*             ID 'Y&SW_AUTID' FIELD gt_caut_pop-swaudid.
*    IF sy-subrc <> 0.
*      MESSAGE e208(00) WITH text-244.
*    ENDIF.
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_CRIT_AUTHS'
*      EXPORTING
*        sourceswaudid                   = gt_caut_pop-swaudid
*        targetswaudid                   = /psyng/swaudc2-swaudid
*        i_vrsio                         = g_sod_vrsio
*     IMPORTING
*       caid_copied                     = cahdrc
*       caid_det_copied                 = cadetc
*       caid_txt_copied                 = catextc
**   CAID_HDR_COPIED                 =
*     EXCEPTIONS
*       target_not_specified            = 1
*       not_authorized                  = 2
*       target_already_exists           = 3
*       source_ca_doesnt_exist          = 4
*       not_authorized_to_display       = 5
*       OTHERS                          = 6
*              .
*    CASE sy-subrc.
*      WHEN 0.
*        CALL FUNCTION '/PSYNG/SW_CR_DELETE_CRI_AUTHS'
*             EXPORTING
*                  i_vrsio        = g_sod_vrsio
*                  i_swaudid      = gt_caut_pop-swaudid
*             EXCEPTIONS
*                  not_authorized = 1
*                  not_exist      = 2
*                  locked         = 3
*                  OTHERS         = 4.
*        CASE sy-subrc.
*          WHEN 0.
*            MESSAGE i208(00) WITH text-246.
*          WHEN 3.
*            MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
*                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ENDCASE.
*      WHEN 1.
*        MESSAGE e208(00) WITH text-239.
*      WHEN 2.
*        MESSAGE e208(00) WITH text-244.
*      WHEN 3.
*        MESSAGE e208(00) WITH text-241.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-242.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-243.
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
*
*  ELSEIF l_answer = '2'.
*
*    CALL FUNCTION '/PSYNG/SW_CR_COPY_CRIT_AUTHS'
*  EXPORTING
*    sourceswaudid                   = gt_caut_pop-swaudid
*    targetswaudid                   = /psyng/swaudc2-swaudid
*    i_vrsio                         = g_sod_vrsio
* IMPORTING
*   caid_copied                     = cahdrc
*   caid_det_copied                 = cadetc
*   caid_txt_copied                 = catextc
**   CAID_HDR_COPIED                 =
* EXCEPTIONS
*   target_not_specified            = 1
*   not_authorized                  = 2
*   target_already_exists           = 3
*   source_ca_doesnt_exist          = 4
*   not_authorized_to_display       = 5
*   OTHERS                          = 6
*          .
*    CASE sy-subrc.
*      WHEN 0.
*        MESSAGE i208(00) WITH text-238.
*      WHEN 1.
*        MESSAGE e208(00) WITH text-239.
*      WHEN 2.
*        MESSAGE e208(00) WITH text-240.
*      WHEN 3.
*        MESSAGE e208(00) WITH text-241.
*      WHEN 4.
*        MESSAGE e208(00) WITH text-242.
*      WHEN 5.
*        MESSAGE e208(00) WITH text-243.
*      WHEN OTHERS.
*        MESSAGE e208(00) WITH text-067.
*    ENDCASE.
*  ELSE.
*    /psyng/swaudc2-swaudid = gt_caut_pop-swaudid.
*    CLEAR ok_code.
*    ok_code = 'ENTER'.
*  ENDIF.


*ENDFORM.                    " update_critical_auth


FORM load_mitigation CHANGING es_contid.
  CHECK first_time = space.
  first_time = 'X'.
  IF gf_data_change = ' '.
    CLEAR: /psyng/mchdr-approver, /psyng/mchdr-description,
           /psyng/mchdr-type,/psyng/mchdr-inactive,
           gt_mctran[], gt_mcrepid[], gt_mcauditor[],i_text[],
           g_editor_text[].
  ENDIF.

  IF /psyng/mchdr-contid <> space.
    SELECT SINGLE * FROM /psyng/mchdr
                  WHERE contid = /psyng/mchdr-contid.
    IF sy-subrc = 0.
*       Check if Mitigation ID is used in SOD Conflicts
      IF gf_dispchg = gc_change.
        SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                      WHERE contid = /psyng/mchdr-contid
                        AND vrsio  = g_sod_vrsio.
        IF sy-subrc = 0.
          MESSAGE w113(/psyng/sw) WITH text-011 /psyng/mchdr-contid
                                       text-e14.
        ENDIF.

      ENDIF.
      REFRESH :g_editor_text[].
*       Get text
      SELECT line text INTO CORRESPONDING FIELDS OF TABLE i_text
                  FROM /psyng/texts
                  WHERE textname = /psyng/mchdr-contid
                   AND   object   = 'M'
                   AND   spras    = sy-langu
                   ORDER BY line.
*       Get Tcodes
      SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_mctran
             FROM /psyng/mctran
             WHERE contid = /psyng/mchdr-contid.

      DESCRIBE TABLE gt_mctran LINES tc_mctran-lines.
      tc_mctran-top_line = 1.

*       Get Programs
      SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_mcrepid
             FROM /psyng/mcrepid
             WHERE contid = /psyng/mchdr-contid.

      DESCRIBE TABLE gt_mcrepid LINES tc_mcrepid-lines.
      tc_mcrepid-top_line = 1.

      es_contid = /psyng/mchdr-contid.

*       Get auditors
      SELECT * INTO CORRESPONDING FIELDS OF TABLE gt_mcauditor
             FROM /psyng/mcauditor
             WHERE contid = /psyng/mchdr-contid.

      LOOP AT gt_mcauditor.
        PERFORM get_comp_name CHANGING gt_mcauditor-company
                                       gt_mcauditor-comp_name.
        MODIFY gt_mcauditor TRANSPORTING comp_name.
      ENDLOOP.

      DESCRIBE TABLE gt_mcauditor LINES tc_mcauditor-lines.
      tc_mcauditor-top_line = 1.

      IF /psyng/mchdr-inactive EQ 'X'.
        g_active_inactive = text-009.
      ELSE.
        g_active_inactive = text-008.
      ENDIF.
    ENDIF.
  ELSE.
    es_contid = /psyng/mchdr-contid.
    MESSAGE e106(/psyng/sw) WITH 'Mitigation ID'(011).
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_role                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_role.

  IF first_time = space.
    first_time = 'X'.

    CLEAR /psyng/rolehdr.
    REFRESH gt_hdrtxt[].
    REFRESH gt_desctxt[].
    REFRESH i_text[].

    IF /psyng/roletrans-roleid <> space.

      PERFORM authority_check_roleid
            USING sec_actvt /psyng/roletrans-roleid.

      SELECT SINGLE * FROM /psyng/rolehdr INTO /psyng/rolehdr
       WHERE roleid = /psyng/roletrans-roleid.

      CHECK sy-subrc = 0.

      CONCATENATE /psyng/roletrans-roleid 'HDR' INTO role_txt.

*      REFRESH i_text.
*      SELECT * FROM /psyng/texts
*             WHERE textname = role_txt
*               AND object   = 'R'
*               AND spras    = sy-langu
*               AND vrsio    = '000'.
*        i_text = /psyng/texts-text.
*        APPEND i_text.
*      ENDSELECT.

      SELECT * FROM /psyng/texts INTO TABLE gt_hdrtxt
      WHERE textname = role_txt
      AND object = 'R'
      AND spras = sy-langu
      AND vrsio = '000'
      ORDER BY line.

      IF g_rolehdr-pressed_tab = c_rolehdr-tab1.
        LOOP AT gt_hdrtxt.
          i_text = gt_hdrtxt-text.
          APPEND i_text.
        ENDLOOP.
        REFRESH : gt_hdrtxt.
      ENDIF.

      CLEAR role_txt1.
      CONCATENATE /psyng/roletrans-roleid 'DESC' INTO role_txt1.
*
*      REFRESH i_text.
*      SELECT * FROM /psyng/texts
*             WHERE textname = role_txt
*               AND object   = 'R'
*               AND spras    = sy-langu
*               AND vrsio    = '000'.
*        i_text = /psyng/texts-text.
*        APPEND i_text.
*      ENDSELECT.

      SELECT * FROM /psyng/texts INTO TABLE gt_desctxt
      WHERE textname = role_txt1
      AND object = 'R'
      AND spras = sy-langu
      AND vrsio = '000'
      ORDER BY line.

      IF g_rolehdr-pressed_tab = c_rolehdr-tab2.
        LOOP AT gt_desctxt.
          i_text = gt_desctxt-text.
          APPEND i_text.
        ENDLOOP.
        REFRESH : gt_desctxt.
      ENDIF.

      IF gf_dispchg = gc_change.
        CALL FUNCTION 'ENQUEUE_/PSYNG/ROLEHDR'
          EXPORTING
            roleid         = /psyng/rolehdr-roleid
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_ca                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_ca.
  IF first_time = space.
    first_time = 'X'.
    IF gf_data_change = ' '.
      CLEAR: /psyng/swaudhdr,g_editor_text[].
    ENDIF.

    IF /psyng/swaudc2-swaudid <> space.
      SELECT SINGLE * FROM /psyng/swaudhdr INTO /psyng/swaudhdr
      WHERE swaudid  = /psyng/swaudc2-swaudid
        AND vrsio    = g_sod_vrsio.

      IF sy-subrc = 0.
        SELECT line text INTO CORRESPONDING FIELDS OF
        TABLE i_text FROM /psyng/texts
        WHERE textname = /psyng/swaudc2-swaudid
        AND   object   = 'T'
        AND   spras    = sy-langu
        AND   vrsio    = g_sod_vrsio
        ORDER BY line.

        IF NOT /psyng/swaudc2-swaudid IS INITIAL
        AND gf_dispchg = gc_change.
*             Lock AUDIT ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/SWAUDHDR'
            EXPORTING
              swaudid        = /psyng/swaudhdr-swaudid
              vrsio          = g_sod_vrsio
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ELSE.
            gt_locked-type   = 'SWAUDHDR'.
            gt_locked-object = /psyng/swaudhdr-swaudid.
            APPEND gt_locked.
          ENDIF.
        ENDIF.
      ENDIF.
    ELSE.
      MESSAGE e106(/psyng/sw) WITH 'Critical Auth ID'(010).
    ENDIF.
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM load_conflict                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_conflict.
  IF first_time = space.
    first_time = 'X'.
    IF gf_data_change = ' '.
      CLEAR: /psyng/conflict, g_funct_itab[],i_text[],g_editor_text[].
    ENDIF.

    IF /psyng/confdet-conid <> space.
      SELECT SINGLE * FROM /psyng/conflict INTO /psyng/conflict
      WHERE conid = /psyng/confdet-conid
        AND vrsio = g_sod_vrsio.

      IF sy-subrc = 0.
        IF /psyng/conflict-inactive = space.
          g_active_inactive = text-008.
        ELSE.
          g_active_inactive = text-009.
        ENDIF.

        REFRESH: i_text, g_funct_itab,g_editor_text[].
        SELECT * FROM /psyng/texts
        WHERE textname = /psyng/confdet-conid
        AND   object   = 'C'
        AND   vrsio    = g_sod_vrsio
        AND   spras    = sy-langu
        ORDER BY line.
          i_text = /psyng/texts-text.
          APPEND i_text.
        ENDSELECT.

        SELECT * FROM /psyng/confdet
               WHERE conid = /psyng/confdet-conid
                 AND vrsio = g_sod_vrsio.

          g_funct_itab-function = /psyng/confdet-functionid.

          CLEAR /psyng/function-description.
          SELECT SINGLE * FROM /psyng/function
                        WHERE function = /psyng/confdet-functionid
                          AND vrsio    = g_sod_vrsio.
          IF sy-subrc = 0.
            g_funct_itab-description = /psyng/function-description.
          ELSE.
*--             This function doesn't exist
            CLEAR g_funct_itab-description.
          ENDIF.
          g_funct_itab-flag = space.
          APPEND g_funct_itab.
        ENDSELECT.

        DESCRIBE TABLE g_funct_itab LINES funct-lines.
        funct-top_line = 1.

*--        Get conflict Owners
        SELECT * FROM /psyng/conowner INTO TABLE gt_conowner
          WHERE vrsio = g_sod_vrsio AND
                conid = /psyng/confdet-conid.

        LOOP AT gt_conowner.
          PERFORM get_comp_name CHANGING gt_conowner-company
                                         gt_conowner-comp_name.
          MODIFY gt_conowner TRANSPORTING comp_name.
        ENDLOOP.

        DESCRIBE TABLE gt_conowner LINES tc_conowner-lines.
        tc_conowner-top_line = 1.

*--        Get conflict mitigations
        SELECT * FROM /psyng/conpmit INTO TABLE gt_conpmit
          WHERE vrsio = g_sod_vrsio AND
                conid = /psyng/confdet-conid.

        LOOP AT gt_conpmit.
          PERFORM get_comp_name CHANGING gt_conpmit-company
                                         gt_conpmit-comp_name.
          MODIFY gt_conpmit TRANSPORTING comp_name.
        ENDLOOP.

        DESCRIBE TABLE gt_conpmit LINES tc_conpmit-lines.
        tc_conpmit-top_line = 1.

        IF NOT /psyng/conflict-conid IS INITIAL
        AND gf_dispchg = gc_change.
*             Lock conflict ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/CONFLICT'
            EXPORTING
              conid          = /psyng/conflict-conid
              vrsio          = g_sod_vrsio
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ELSE.
            gt_locked-type   = 'CONFLICT'.
            gt_locked-object = /psyng/conflict-conid.
            APPEND gt_locked.
          ENDIF.
        ENDIF.
      ELSE.
*        CLEAR g_active_inactive.
*        CLEAR: /psyng/conflict,g_funct_itab[],i_text[].
*        IF gf_data_change = ' '.
*         MESSAGE e106(/psyng/sw) WITH 'Conflict ID'(006).
*        ENDIF.
      ENDIF.
    ELSE.
      MESSAGE e106(/psyng/sw) WITH 'Conflict ID'(006).
    ENDIF.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_function                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_function.
  DATA: ls_fioria TYPE /psyng/sw_fioria.
  IF first_time = space.
    first_time = 'X'.
    IF gf_data_change = ' '.
      CLEAR: g_trans_itab[],i_text[],/psyng/function,g_editor_text[],
             gt_fiori_app[].
    ENDIF.

    IF /psyng/functtran-functionid <> space.
      SELECT SINGLE * FROM /psyng/function INTO /psyng/function
      WHERE function = /psyng/functtran-functionid
        AND vrsio    = g_sod_vrsio.

      IF sy-subrc = 0.
        REFRESH :g_editor_text[].
        SELECT line text INTO CORRESPONDING FIELDS OF
        TABLE i_text FROM /psyng/texts
        WHERE textname = /psyng/functtran-functionid
        AND   object   = 'F'
        AND   vrsio    = g_sod_vrsio
        AND   spras    = sy-langu
        ORDER BY line.

        REFRESH g_trans_itab.
        SELECT * FROM /psyng/functtran
        WHERE functionid = /psyng/functtran-functionid
          AND vrsio      = g_sod_vrsio
          AND type       <> 'F'.

          g_trans_itab-tcode = /psyng/functtran-tcode.
          SELECT SINGLE * FROM tstct
          WHERE tcode = g_trans_itab-tcode
          AND sprsl = sy-langu.
*              IF sy-subrc <> 0.
*                tstct-ttext = text-129.
*              ENDIF.
          IF sy-subrc <> 0.
*            --TCOde does not exist in this system
            IF g_trans_itab-tcode  CP
                /psyng/sw_cl_constants=>placeholder_tcode_prefix.
              tstct-ttext =
              'Placeholder for objectlevel analysis'(191).
            ELSE.
              tstct-ttext =
              'Tcode for cross system analysis'(192).
            ENDIF.
          ENDIF.
          g_trans_itab-ttext = tstct-ttext.
          g_trans_itab-flag = space.
          APPEND g_trans_itab.
        ENDSELECT.

        DESCRIBE TABLE g_trans_itab LINES critrans-lines.
        critrans-top_line = 1.

*---Load fiori app
        REFRESH gt_fiori_app.
        SELECT * FROM /psyng/functtran
               WHERE functionid = /psyng/functtran-functionid
                 AND vrsio      = g_sod_vrsio
                 AND type       = 'F'.
          gt_fiori_app-fioriid = /psyng/functtran-fioriid.

          SELECT SINGLE fioriid appname FROM /psyng/sw_fioria
                INTO CORRESPONDING FIELDS OF ls_fioria WHERE
                  fioriid = gt_fiori_app-fioriid.
          gt_fiori_app-appname = ls_fioria-appname.
          APPEND gt_fiori_app.
          CLEAR ls_fioria.
        ENDSELECT.

        DESCRIBE TABLE gt_fiori_app LINES fioriapps-lines.
        fioriapps-top_line = 1.

        IF NOT /psyng/function-function IS INITIAL
         AND gf_dispchg = gc_change.
*             Lock function ID
          CALL FUNCTION 'ENQUEUE_/PSYNG/FUNCTION'
            EXPORTING
              function       = /psyng/function-function
              vrsio          = g_sod_vrsio
            EXCEPTIONS
              foreign_lock   = 1
              system_failure = 2
              OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ELSE.
            gt_locked-type   = 'FUNCTION'.
            gt_locked-object = /psyng/function-function.
            APPEND gt_locked.
          ENDIF.
*BOC:HBHALLA (27/11/24) PN-7208
          CALL FUNCTION 'ENQUEUE_/PSYNG/FAOBJ'
               EXPORTING
                    funid          = /psyng/function-function
                    vrsio          = g_sod_vrsio
               EXCEPTIONS
                    foreign_lock   = 1
                    system_failure = 2
                    OTHERS         = 3.
          IF sy-subrc <> 0.
            gf_dispchg = gc_display.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
*EOC:HBHALLA (27/11/24) PN-7208
        ENDIF.
      ELSE.
*        CLEAR :i_text[],/psyng/function.
*        REFRESH :g_editor_text[].
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
*       FORM insert_row_into_tc                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_TC_NAME                                                     *
*  -->  P_TABLE_NAME                                                  *
*---------------------------------------------------------------------*
FORM insert_row_into_tc USING    p_tc_name TYPE dynfnam
                                 p_table_name.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_selline          LIKE sy-stepl.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*



  ASSIGN (p_tc_name) TO <tc>.                "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body

  ASSIGN (l_table_name) TO <table>.          "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
  "not headerline

* get looplines of TableControl
  ASSIGN ('G_TC_LINES') TO <lines>.

* get current line
*  GET CURSOR LINE l_selline.
  l_selline = 1.
  IF sy-subrc <> 0.                   " append line to table


    l_selline = <tc>-lines + 1.

*&SPWIZARD: set top line and new cursor line                           *
    IF l_selline > <lines>.
      <tc>-top_line = l_selline - <lines> + 1 .
    ELSE.
      <tc>-top_line = 1.
    ENDIF.
  ELSE.                               " insert line into table
    l_selline = <tc>-top_line + l_selline - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  g_curr_line = l_selline.

* insert initial line
  INSERT INITIAL LINE INTO <table> INDEX l_selline.
*  APPEND INI
  <tc>-lines = <tc>-lines + 1.
*  g_curr_line = 0.
  SET CURSOR LINE g_curr_line.                              "OFFSET 0.

ENDFORM.                    " insert_row_into_tc
*&---------------------------------------------------------------------*
*&      Form  exit_without_save_new
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM exit_without_save_new.
* If data was changed, ask if user wants to exit without saving
  gf_answer = 1.
  IF gf_data_change = gc_select.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question         = text-003
        text_button_1         = text-001
        icon_button_1         = 'ICON_CHECKED'
        text_button_2         = text-002
        icon_button_2         = 'ICON_INCOMPLETE'
        default_button        = '2'
        display_cancel_button = space
      IMPORTING
        answer                = gf_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

ENDFORM.                    " exit_without_save_new
*&---------------------------------------------------------------------*
*&      Form  sort_col_mit
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SORT_TYPE  text
*----------------------------------------------------------------------*
FORM sort_col_mit USING    p_sort_type.
  REFRESH fld_list.
  LOOP AT tc_conpmit-cols INTO col.
    IF col-selected = 'X'.
      APPEND col TO fld_list.
    ENDIF.
  ENDLOOP.
  SORT fld_list BY index.
  CLEAR:fldname.
  READ TABLE fld_list INDEX 1 INTO col.
  fldname = col-screen-name+11.
  IF p_sort_type = 'A'.
    SORT gt_conpmit BY (fldname) ASCENDING.
  ELSE.
    SORT gt_conpmit BY (fldname) DESCENDING.
  ENDIF.
ENDFORM.                    " sort_col_mit
*&---------------------------------------------------------------------*
*&      Form  get_default_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_default_config.
  DATA : ls_config TYPE /psyng/swconfig.
  se_config_param 'MIT_ASGN_AUTH_CHECK' ls_config-value.
  IF ls_config-value = '2'.
    gf_mit_asgn_auth_check = 'X'.
  ELSE.
    CLEAR gf_mit_asgn_auth_check.
  ENDIF.
  se_config_param 'TA_DISPLAY_HISTORY' ls_config-value.
  IF ls_config-value = 'N'.
    CLEAR gf_use_ta_history.
  ELSE.
    gf_use_ta_history = 'X'.
  ENDIF.

*BOC UMITTAL SE-CAC Integration 17/02/2026
  CLEAR  ls_config-value.
  se_config_param 'SE_CAC_INTEGRATION' ls_config-value.
  CLEAR gv_se_cac.
  gv_se_cac = ls_config-value.

  CLEAR  ls_config-value.
  se_config_param 'DFLT_GLOBAL_VERSION' ls_config-value.
  CLEAR gv_sod_dflt.
  gv_sod_dflt = ls_config-value.
*EOC UMITTAL SE-CAC Integration 17/02/2026
ENDFORM.                    " get_default_config
*&---------------------------------------------------------------------*
*&      Form  config_dashboard
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM config_dashboard.
* CHECK WHETHER RV IS INSTALLED OR NOT.
  DATA lt_modules TYPE TABLE OF /psyng/sw_modules.
  DATA ls_modules TYPE /psyng/sw_modules.
  DATA lv_module TYPE /psyng/sw_module.
  DATA lv_installed TYPE /psyng/bapiflagx.
  DATA lv_module_name TYPE ttext_stct.
  DATA lv_module_version TYPE /psyng/prog_vrsio.
  lv_module = 'DA'.
  DATA lv_first TYPE flag.

  IF lv_first = space.
    lv_first = 'X'.
    CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
      EXPORTING
        i_module         = lv_module
      IMPORTING
        e_installed      = lv_installed
        e_module_name    = lv_module_name
        e_module_version = lv_module_version.


    IF lv_installed EQ 'X'.
      gv_module_check = 'X'.
    ELSE.
      gv_module_check = ' '.
    ENDIF.

* CHECK FOR DASHBOARD STATUS ACTIVE OR INACTIVE.

    DATA lt_parameters TYPE TABLE OF /psyng/bc_config_param.
    DATA ls_parameters TYPE /psyng/bc_config_param.
    DATA lv_param_value TYPE c.
    DATA lv_parameter TYPE /psyng/param.
    DATA lv_config_param TYPE /psyng/bc_config_param.
    lv_parameter = 'DASHBOARD_ACTIVE'.
    DATA lv_parameter_value TYPE /psyng/param_value.

    se_config_param lv_parameter lv_parameter_value.
    IF lv_parameter_value = 'Y'.
      gv_param_value_check = 'X'.

    ELSE.
      gv_param_value_check = ' '.
    ENDIF.

    IF gv_tab_flag IS INITIAL.
      IF gv_module_check = 'X' AND gv_param_value_check = 'X'.
        LOOP AT SCREEN.
          IF screen-name EQ 'YX_SECTAB_TAB1'.
            screen-active = 0.
          ENDIF.
          MODIFY SCREEN.
        ENDLOOP.
        IF gf_custom_tab_selected <> 'X'.
          g_yx_sectab-pressed_tab = c_yx_sectab-tab8.
        ENDIF.
        gt_func-fcode = 'FS'.
        APPEND gt_func.
        SET PF-STATUS 'NOEDIT' EXCLUDING gt_func.


      ELSEIF gv_module_check = ' ' OR gv_param_value_check = ' '.
        LOOP AT SCREEN.
          IF screen-name EQ 'YX_SECTAB_TAB8'.
            screen-active = '0'.
          ENDIF.
          MODIFY SCREEN.
        ENDLOOP.
        IF gf_custom_tab_selected <> 'X'.
          g_yx_sectab-pressed_tab = c_yx_sectab-tab1.
        ENDIF.
      ENDIF.
      gv_tab_flag = 'X'.
    ENDIF.
  ENDIF.

  IF gv_module_check = 'X' AND gv_param_value_check = 'X'.
    LOOP AT SCREEN.
      IF screen-name EQ 'YX_SECTAB_TAB1'.
        screen-active = '0'.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.
  ELSEIF gv_module_check NE 'X' OR gv_param_value_check NE 'X'.
    LOOP AT SCREEN.
      IF screen-name EQ 'YX_SECTAB_TAB8'.
        screen-active = '0'.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.

  ENDIF.


ENDFORM.                    " config_dashboard
*&---------------------------------------------------------------------*
*&      Form  deactivate_dashboard
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM deactivate_dashboard.

* deactives dashboard tab.
  LOOP AT SCREEN.
    CHECK screen-name EQ 'YX_SECTAB_TAB8'.
    IF gv_module_check NE 'X' OR gv_param_value_check NE 'X'.
      screen-active = 0.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.


ENDFORM.                    " deactivate_dashboard
*&---------------------------------------------------------------------*
*&      Form  sort_col_ct
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SORT_TYPE  text
*----------------------------------------------------------------------*
FORM sort_col_ct USING    p_sort_type.

  REFRESH fld_list.
  LOOP AT critran-cols INTO col.
    IF col-selected = 'X'.
      APPEND col TO fld_list.
    ENDIF.
  ENDLOOP.
  IF NOT fld_list[] IS INITIAL.
    SORT fld_list BY index.
    CLEAR:fldname.

    READ TABLE fld_list INDEX 1 INTO col.

    IF col-screen-name CS 'TSTCT'.
      fldname = col-screen-name+6.
    ELSE.
      fldname = col-screen-name+11.
    ENDIF.
    IF p_sort_type = 'A'.
      SORT g_trans_itab BY (fldname) ASCENDING.
    ELSE.
      SORT g_trans_itab BY (fldname) DESCENDING.
    ENDIF.
  ENDIF.
ENDFORM.                    " sort_col_ct
*&---------------------------------------------------------------------*
*&      Form  sort_col_cf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SORT_TYPE  text
*----------------------------------------------------------------------*
FORM sort_col_cf USING    p_sort_type.

  REFRESH fld_list.
  LOOP AT critprof-cols INTO col.
    IF col-selected = 'X'.
      APPEND col TO fld_list.
    ENDIF.
  ENDLOOP.
  SORT fld_list BY index.
  CLEAR:fldname.
  IF NOT fld_list[] IS INITIAL.
    READ TABLE fld_list INDEX 1 INTO col.

    IF col-screen-name CS 'USR11'.
      fldname = col-screen-name+6.
    ELSEIF col-screen-name = 'G_PROFILE'.
      fldname = 'PROFN'.
    ELSE.
      fldname = col-screen-name+16.
    ENDIF.
    IF p_sort_type = 'A'.
      SORT g_criprofs_itab BY (fldname) ASCENDING.
    ELSE.
      SORT g_criprofs_itab BY (fldname) DESCENDING.
    ENDIF.
  ENDIF.
ENDFORM.                    " sort_col_cf
*&---------------------------------------------------------------------*
*&      Form  sort_col_cr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SORT_TYPE  text
*----------------------------------------------------------------------*
FORM sort_col_cr USING    p_sort_type.
  REFRESH fld_list.
  LOOP AT critrole-cols INTO col.
    IF col-selected = 'X'.
      APPEND col TO fld_list.
    ENDIF.
  ENDLOOP.
  SORT fld_list BY index.
  CLEAR:fldname.
  IF NOT fld_list[] IS INITIAL.
    READ TABLE fld_list INDEX 1 INTO col.

    IF col-screen-name CS 'AGR_TEXTS'.
      fldname = col-screen-name+10.
    ELSE.
      fldname = col-screen-name+16.
    ENDIF.
    IF p_sort_type = 'A'.
      SORT g_criroles_itab BY (fldname) ASCENDING.
    ELSE.
      SORT g_criroles_itab BY (fldname) DESCENDING.
    ENDIF.
  ENDIF.
ENDFORM.                    " sort_col_cr

*&---------------------------------------------------------------------*
*&      Form  f4_help_owner
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_TRANS_ITAB_OWNER  text
*----------------------------------------------------------------------*
FORM f4_help_owner CHANGING p_owner TYPE /psyng/critcodes-owner .

  DATA: BEGIN OF lt_owner OCCURS 0,
          owner TYPE /psyng/critcodes-owner,
        END OF lt_owner.
  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        wa_return LIKE LINE OF lt_return,
        ls_shlp   TYPE shlp_descr_t.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        l_rapid   LIKE sy-repid.
  l_repid =  sy-repid.
  REFRESH : lt_owner.
  CASE g_call_scrn.
    WHEN '208'.
      SELECT owner FROM /psyng/critcodes INTO TABLE
         lt_owner WHERE vrsio = g_sod_vrsio.
    WHEN '210'.

      SELECT owner FROM /psyng/criroles INTO TABLE lt_owner
           WHERE vrsio = g_sod_vrsio.

    WHEN '213'.
      SELECT owner FROM /psyng/criprof INTO TABLE lt_owner
           WHERE vrsio = g_sod_vrsio.
  ENDCASE.

  SORT lt_owner BY owner.
  DELETE ADJACENT DUPLICATES FROM lt_owner COMPARING owner.
  DELETE lt_owner WHERE owner EQ space.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = 'EKKO'
      retfield        = 'OWNER'
*     PVALKEY         = ' '
      dynpprog        = l_repid
      dynpnr          = sy-dynnr
*     DYNPROFIELD     = 'EBELN'
*     STEPL           = 0
      window_title    = 'Owners'
*     VALUE           = ' '
      value_org       = 'S'
*     MULTIPLE_CHOICE = 'X'
*     DISPLAY         = ' '
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM   = ' '
*     MARK_TAB        =
* IMPORTING
*     USER_RESET      = ld_ret
    TABLES
      value_tab       = lt_owner
*     FIELD_TAB       = lt_fields
      return_tab      = lt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  READ TABLE lt_return INTO wa_return INDEX 1.
  gl_critrans-owner = wa_return-fieldval.

ENDFORM.                    " f4_help_owner
*&---------------------------------------------------------------------*
*&      Form  f4_help_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_TRANS_ITAB_TCODE  text
*----------------------------------------------------------------------*
FORM f4_help_tcode CHANGING p_tcode TYPE /psyng/critcodes-tcode.
  DATA: BEGIN OF lt_tcode OCCURS 0,
          tcode TYPE /psyng/critcodes-tcode,
        END OF lt_tcode.
  DATA: BEGIN OF lt_ttcode OCCURS 0,
          tcode TYPE tstc-tcode,
          text  TYPE tstct-ttext,
        END OF lt_ttcode.

  DATA: lt_return    TYPE STANDARD TABLE OF ddshretval,
        wa_return    LIKE LINE OF lt_return,
        ls_shlp      TYPE shlp_descr_t,
        lt_tcodetext TYPE TABLE OF tstct WITH HEADER LINE.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        l_rapid   LIKE sy-repid.
  l_rapid =  sy-repid.

  SELECT tcode FROM /psyng/critcodes INTO TABLE
     lt_tcode WHERE vrsio = g_sod_vrsio.

  IF NOT lt_tcode[] IS INITIAL.
    SELECT tcode ttext FROM tstct INTO
    CORRESPONDING FIELDS OF TABLE lt_tcodetext
           FOR ALL ENTRIES IN lt_tcode
          WHERE tcode = lt_tcode-tcode
          AND   sprsl = sy-langu.

  ENDIF.

  LOOP AT lt_tcode.
    READ TABLE lt_tcodetext WITH KEY tcode = lt_tcode-tcode.
    IF sy-subrc = 0.
      lt_ttcode-text  = lt_tcodetext-ttext.
    ELSE.
      lt_ttcode-text  = 'Tcode for cross system analysis'(192).
    ENDIF.
    lt_ttcode-tcode = lt_tcode-tcode.
    APPEND lt_ttcode.
  ENDLOOP.
  SORT lt_ttcode BY tcode.
  DELETE ADJACENT DUPLICATES FROM lt_ttcode COMPARING tcode.
  DELETE lt_ttcode WHERE tcode EQ space.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = 'EKKO'
      retfield        = 'TCODE'
*     PVALKEY         = ' '
      dynpprog        = l_rapid
      dynpnr          = sy-dynnr
*     DYNPROFIELD     = 'EBELN'
*     STEPL           = 0
      window_title    = 'Transaction Code'
*     VALUE           = ' '
      value_org       = 'S'
*     MULTIPLE_CHOICE = 'X'
*     DISPLAY         = ' '
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM   = ' '
*     MARK_TAB        =
* IMPORTING
*     USER_RESET      = ld_ret
    TABLES
      value_tab       = lt_ttcode
*     FIELD_TAB       = lt_fields
      return_tab      = lt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  READ TABLE lt_return INTO wa_return INDEX 1.
  gl_critrans-tcode = wa_return-fieldval.

ENDFORM.                    " f4_help_tcode
*&---------------------------------------------------------------------*
*&      Form  f4_help_imp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_TRANS_ITAB_IMP  text
*----------------------------------------------------------------------*
FORM f4_help_imp CHANGING p_imp TYPE /psyng/critcodes-imp.
  DATA: BEGIN OF lt_imp OCCURS 0,
          imp TYPE /psyng/critcodes-imp,
        END OF lt_imp.
  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        wa_return LIKE LINE OF lt_return,
        ls_shlp   TYPE shlp_descr_t.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        l_rapid   LIKE sy-repid.
  l_repid =  sy-repid.
  CASE g_call_scrn.
    WHEN '208'.
      SELECT imp FROM /psyng/critcodes INTO TABLE
          lt_imp WHERE vrsio = g_sod_vrsio.
    WHEN '210'.
      SELECT imp FROM /psyng/criroles INTO TABLE
          lt_imp WHERE vrsio = g_sod_vrsio.
    WHEN '213'.
      SELECT imp FROM /psyng/criprof INTO TABLE
          lt_imp WHERE vrsio = g_sod_vrsio.
  ENDCASE.

  SORT lt_imp BY imp.
  DELETE ADJACENT DUPLICATES FROM lt_imp COMPARING imp.
  DELETE lt_imp WHERE imp EQ space.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = 'EKKO'
      retfield        = 'IMP'
*     PVALKEY         = ' '
      dynpprog        = l_repid
      dynpnr          = sy-dynnr
*     DYNPROFIELD     = 'EBELN'
*     STEPL           = 0
      window_title    = 'Sensitivity'
*     VALUE           = ' '
      value_org       = 'S'
*     MULTIPLE_CHOICE = 'X'
*     DISPLAY         = ' '
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM   = ' '
*     MARK_TAB        =
* IMPORTING
*     USER_RESET      = ld_ret
    TABLES
      value_tab       = lt_imp
*     FIELD_TAB       = lt_fields
      return_tab      = lt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  READ TABLE lt_return INTO wa_return INDEX 1.
  gl_critrans-imp = wa_return-fieldval.

ENDFORM.                    " f4_help_imp
*&---------------------------------------------------------------------*
*&      Form  f4_help_busarea
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_TRANS_ITAB_BUSAREA  text
*----------------------------------------------------------------------*
FORM f4_help_busarea CHANGING p_busarea TYPE /psyng/critcodes-busarea.
  DATA: BEGIN OF lt_busarea OCCURS 0,
          busarea TYPE /psyng/critcodes-busarea,
        END OF lt_busarea.
  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        wa_return LIKE LINE OF lt_return,
        ls_shlp   TYPE shlp_descr_t.
  DATA: lt_fields TYPE TABLE OF dfies WITH HEADER LINE,
        l_rapid   LIKE sy-repid.
  l_repid =  sy-repid.

  SELECT busarea FROM /psyng/critcodes INTO TABLE
     lt_busarea WHERE vrsio = g_sod_vrsio.
  SORT lt_busarea BY busarea.
  DELETE ADJACENT DUPLICATES FROM lt_busarea COMPARING busarea.
  DELETE lt_busarea WHERE busarea EQ space.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = 'EKKO'
      retfield        = 'BUSAREA'
*     PVALKEY         = ' '
      dynpprog        = l_repid
      dynpnr          = sy-dynnr
*     DYNPROFIELD     = 'EBELN'
*     STEPL           = 0
      window_title    = 'Application Area'
*     VALUE           = ' '
      value_org       = 'S'
*     MULTIPLE_CHOICE = 'X'
*     DISPLAY         = ' '
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM   = ' '
*     MARK_TAB        =
* IMPORTING
*     USER_RESET      = ld_ret
    TABLES
      value_tab       = lt_busarea
*     FIELD_TAB       = lt_fields
      return_tab      = lt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  READ TABLE lt_return INTO wa_return INDEX 1.
  gl_critrans-busarea = wa_return-fieldval.

ENDFORM.                    " f4_help_busarea
*&---------------------------------------------------------------------*
*&      Form  f4_help_agr_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_CRIROLES_ITAB_AGR_NAME  text
*----------------------------------------------------------------------*
FORM f4_help_agr_name CHANGING p_agr_name TYPE /psyng/criroles-agr_name.
  DATA: BEGIN OF lt_agr_name OCCURS 0,
          agr_name TYPE /psyng/criroles-agr_name,
        END OF lt_agr_name.

  DATA: BEGIN OF lt_roletext OCCURS 0,
          agr_name TYPE agr_define-agr_name,
          text     TYPE agr_texts-text,
        END OF lt_roletext.
  DATA: lt_agr_text TYPE TABLE OF agr_texts WITH HEADER LINE.

  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
        wa_return LIKE LINE OF lt_return,
        ls_shlp   TYPE shlp_descr_t.
  DATA: lt_fields TYPE TABLE OF dfies WITH HEADER LINE,
        l_rapid   LIKE sy-repid.
  l_repid =  sy-repid.

  SELECT agr_name FROM /psyng/criroles INTO TABLE
     lt_agr_name WHERE vrsio = g_sod_vrsio.

*-- get text from agr_texts table
  IF NOT lt_agr_name[] IS INITIAL.
    SELECT agr_name text FROM agr_texts
    INTO CORRESPONDING FIELDS OF TABLE lt_agr_text
     FOR ALL ENTRIES IN lt_agr_name
     WHERE agr_name = lt_agr_name-agr_name
     AND   spras    = sy-langu.
  ENDIF.


  LOOP AT lt_agr_name.
    READ TABLE lt_agr_text WITH KEY agr_name = lt_agr_name-agr_name.
    IF sy-subrc = 0.
      lt_roletext-text = lt_agr_text-text.
    ELSE.
      lt_roletext-text = 'Role for cross system analysis'(299).
    ENDIF.
    lt_roletext-agr_name = lt_agr_name-agr_name.
    APPEND lt_roletext.
  ENDLOOP.

  SORT lt_roletext BY agr_name.
  DELETE ADJACENT DUPLICATES FROM lt_roletext COMPARING agr_name.
  DELETE lt_roletext WHERE agr_name EQ space.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = 'EKKO'
      retfield        = 'AGR_NAME'
*     PVALKEY         = ' '
      dynpprog        = l_repid
      dynpnr          = sy-dynnr
*     DYNPROFIELD     = 'EBELN'
*     STEPL           = 0
      window_title    = 'Role Name'
*     VALUE           = ' '
      value_org       = 'S'
*     MULTIPLE_CHOICE = 'X'
*     DISPLAY         = ' '
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM   = ' '
*     MARK_TAB        =
* IMPORTING
*     USER_RESET      = ld_ret
    TABLES
      value_tab       = lt_roletext
*     FIELD_TAB       = lt_fields
      return_tab      = lt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  READ TABLE lt_return INTO wa_return INDEX 1.
  gl_critrole-agr_name = wa_return-fieldval.
ENDFORM.                    " f4_help_agr_name

*---------------------------------------------------------------------*
*       FORM edit_text                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  REV_TEXT                                                      *
*  -->  L_LANG                                                        *
*---------------------------------------------------------------------*
FORM edit_text USING i_text_name
                     i_lang.
  CONSTANTS: lc_funcname LIKE rs38l-name VALUE 'CREATE_TEXT'.

  DATA: l_langname TYPE spras,
        l_tdname   LIKE thead-tdname,
        ls_thead   TYPE thead.


* Check if a language can be used
  l_langname = i_lang.
  CATCH SYSTEM-EXCEPTIONS localization_errors = 1.
    SET LOCALE LANGUAGE l_langname.
  ENDCATCH.
  IF sy-subrc <> 0.
*    MESSAGE i113 WITH l_langname
*            'Language is not set - cannot be used'(M10).
    EXIT.
  ENDIF.

  l_tdname = i_text_name.

* Read text name and language
  SELECT SINGLE mandt INTO sy-mandt FROM stxh
               WHERE tdname   = i_text_name
                 AND tdspras  = l_langname
                 AND tdid     = 'ST'
                 AND tdobject = 'TEXT'.

* Check whether text ID exists or not
  IF sy-subrc NE 0.
*   Check if FM CREATE_TEXT exists or not
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = lc_funcname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.

    IF sy-subrc EQ 0.
      CALL FUNCTION lc_funcname              "#EC PATHLOCK_CI_DYN_ACCES
        EXPORTING
          fid         = 'ST'
          flanguage   = l_langname
          fname       = l_tdname
          fobject     = 'TEXT'
          save_direct = 'X'
          fformat     = '*'
        TABLES
          flines      = gt_tline
        EXCEPTIONS
          no_init     = 1
          no_save     = 2
          OTHERS      = 3.

      IF sy-subrc EQ 0.
        CALL FUNCTION 'READ_TEXT'
          EXPORTING
    client   = sy-mandt                "#EC SAST_CI_GEN_CHECK (HBHALLA)
    object   = 'TEXT'
    name     = l_tdname
    id       = 'ST'
    language = l_langname
          IMPORTING
            header   = ls_thead
          TABLES
            lines    = gt_tline
          EXCEPTIONS
            OTHERS   = 1.

*       If it fails we will get script message for text
        IF sy-subrc NE 0.
          CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
          EXIT.
        ENDIF.

*       Check authority to open in "edit mode"
        CALL FUNCTION 'CHECK_TEXT_AUTHORITY'
          EXPORTING
            activity     = 'SHOW'
            id           = 'ST'
            language     = l_langname
            name         = l_tdname
            object       = 'TEXT'
          EXCEPTIONS
            no_authority = 1
            OTHERS       = 2.
        IF sy-subrc NE 0.
          MESSAGE s613(td) WITH l_langname
                                'ST'
                                l_tdname.
          EXIT.
        ENDIF.

        CALL FUNCTION 'EDIT_TEXT'
          EXPORTING
            header        = ls_thead
          TABLES
            lines         = gt_tline
          EXCEPTIONS
            id            = 1
            language      = 2
            linesize      = 3
            name          = 4
            object        = 5
            textformat    = 6
            communication = 7
            OTHERS        = 8.

*       If it is fails it will give script message for that text
        IF sy-subrc NE 0.
          CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
        ENDIF.

        REFRESH: gt_tline.
        EXIT.
      ENDIF.

*************************************************************
*   FM CREATE_TEXT does not exist
    ELSE.
*Begin of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SO10'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
      IF sy-subrc = 1.
        CALL TRANSACTION 'SO10'.
      ELSE.
        MESSAGE e077(s#) WITH 'SO10'.
      ENDIF.
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
    ENDIF.
  ENDIF.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      client   = sy-mandt              "#EC SAST_CI_GEN_CHECK (HBHALLA)
      object   = 'TEXT'
      name     = l_tdname
      id       = 'ST'
      language = l_langname
    IMPORTING
      header   = ls_thead
    TABLES
      lines    = gt_tline
    EXCEPTIONS
      OTHERS   = 1.

* If it fails we will get script message for text
  IF sy-subrc NE 0.
    CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
    EXIT.                              " Exit Form
  ENDIF.

* Check authority to open in "edit mode"
  CALL FUNCTION 'CHECK_TEXT_AUTHORITY'
    EXPORTING
      activity     = 'SHOW'
      id           = 'ST'
      language     = l_langname
      name         = l_tdname
      object       = 'TEXT'
    EXCEPTIONS
      no_authority = 1
      OTHERS       = 2.
  IF sy-subrc NE 0.
    MESSAGE s613(td) WITH l_langname 'ST'
                          l_tdname.
    EXIT.
  ENDIF.

  CALL FUNCTION 'EDIT_TEXT'
    EXPORTING
      display       = space
      header        = ls_thead
    TABLES
      lines         = gt_tline
    EXCEPTIONS
      id            = 1
      language      = 2
      linesize      = 3
      name          = 4
      object        = 5
      textformat    = 6
      communication = 7
      OTHERS        = 8.

* If it is fails it will give script message for that text
  IF sy-subrc NE 0.
    CALL FUNCTION 'SAPSCRIPT_MESSAGE'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  init_rfc_dest
*&---------------------------------------------------------------------*
*       Ensure a destination pointing to the local system in
*       /psyng/sw_rfcdes
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_rfc_dest.
  DATA : l_local_sys TYPE /psyng/sysid,
         ls_sys      TYPE /psyng/sw_rfcdes.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  SELECT SINGLE * FROM /psyng/sw_rfcdes
  INTO ls_sys
  WHERE systid  = l_local_sys AND
        rfcdest = ''.
  IF sy-subrc <> 0.
    ls_sys-rfcdest = ''.
    CONCATENATE 'Local System'(r01) l_local_sys INTO ls_sys-rfcname
    SEPARATED BY space .
    ls_sys-description = ls_sys-rfcname.
    ls_sys-systid      =  l_local_sys.
    INSERT  /psyng/sw_rfcdes FROM ls_sys .
    COMMIT WORK.
    MESSAGE s002(/psyng/sw) WITH
    'Registered local system'(r02)
    'in System List'(r03).
*   & & & &

  ENDIF.
ENDFORM.                    " init_rfc_dest
*&---------------------------------------------------------------------*
*&      Form  check_tab_visible
*&---------------------------------------------------------------------*
*      Hide tabs based on table /PSYNG/SWINVISBL for all users
*      or based on object Y&SW_TAB for specific users
*      Also hides related menu items
*----------------------------------------------------------------------*
FORM check_tab_visible
USING    i_tab
         i_type
         i_desc
         i_screengroup
         i_hide_men_1
         i_hide_men_2
         i_hide_men_3
         i_hide_men_4
         i_hide_men_5
CHANGING
         ef_hidden TYPE flag.
  DATA : lf_hide      TYPE flag,
         ls_swbuttabs TYPE /psyng/swbuttabs.
  STATICS : lt_invisible TYPE TABLE OF /psyng/swinvisbl,
            lt_swbuttabs TYPE TABLE OF /psyng/swbuttabs,
            lf_loaded    TYPE flag.
  CLEAR ef_hidden.
  IF lf_loaded IS INITIAL.
*--Only load this data the first time
    SELECT * FROM /psyng/swinvisbl INTO TABLE lt_invisible.
    SORT lt_invisible.
    SELECT * FROM /psyng/swbuttabs INTO TABLE lt_swbuttabs.
    SORT lt_swbuttabs BY element_name.
    lf_loaded = 'X'.
  ENDIF.
  READ TABLE lt_swbuttabs WITH KEY element_name = i_tab
  BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc NE 0.
    ls_swbuttabs-element_name = i_tab.
    ls_swbuttabs-element_type = i_type.
    ls_swbuttabs-description = i_desc.
*Call FM to insert button or tab name in DB
    CALL FUNCTION '/PSYNG/SW_130'
      EXPORTING
        is_swbuttabs = ls_swbuttabs.
  ENDIF.
  READ TABLE lt_invisible WITH KEY swprogram = i_tab
  BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
*-Hidden for all users
    lf_hide = 'X'.
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_TAB'
             ID 'Y&SW_TAB' FIELD i_tab.
    IF sy-subrc <> 0.
*--Hidden because user isn't authorized
      lf_hide = 'X'.
    ENDIF.
  ENDIF.
  IF lf_hide = 'X'.
*--Hide the tab
    LOOP AT SCREEN.
      IF screen-group1 = i_screengroup.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
*--Hide associated menu items
    DEFINE hide_tab_men.
      if not &1 is initial.
        gt_func-fcode = &1.
        collect gt_func.
      endif.
    END-OF-DEFINITION.
    hide_tab_men :
   i_hide_men_1, i_hide_men_2, i_hide_men_3, i_hide_men_4, i_hide_men_5.
  ENDIF.
  ef_hidden = lf_hide.
ENDFORM.                    " check_tab_visible
*&---------------------------------------------------------------------*
*&      Form  check_button_visible
*&---------------------------------------------------------------------*
*      Hide buttons based on table /PSYNG/SWINVISBL for all users
*----------------------------------------------------------------------*

FORM check_button_visible
USING    i_tab
         i_type
         i_desc
         i_screengroup.
  STATICS : lt_invisible TYPE TABLE OF /psyng/swinvisbl,
            lt_swbuttabs TYPE TABLE OF /psyng/swbuttabs,
            lf_loaded    TYPE flag.

  DATA: lf_hide      TYPE flag,
        ls_swbuttabs TYPE /psyng/swbuttabs.

  IF lf_loaded IS INITIAL.
*--Only load this data the first time
    SELECT * FROM /psyng/swinvisbl INTO TABLE lt_invisible.
    SORT lt_invisible.
    SELECT * FROM /psyng/swbuttabs INTO TABLE lt_swbuttabs.
    SORT lt_swbuttabs BY element_name.
    lf_loaded = 'X'.
  ENDIF.
  READ TABLE lt_swbuttabs WITH KEY element_name = i_tab
  BINARY SEARCH TRANSPORTING NO FIELDS.      "#EC PATHLOCK_CI_DYN_ACCES
  IF sy-subrc NE 0.
    ls_swbuttabs-element_name = i_tab.       "#EC PATHLOCK_CI_DYN_ACCES
    ls_swbuttabs-element_type = i_type.
    ls_swbuttabs-description = i_desc.
*Call FM to insert button or tab name in DB
    CALL FUNCTION '/PSYNG/SW_130'
      EXPORTING
        is_swbuttabs = ls_swbuttabs.
  ENDIF.
  READ TABLE lt_invisible WITH KEY swprogram = i_tab
  BINARY SEARCH TRANSPORTING NO FIELDS.      "#EC PATHLOCK_CI_DYN_ACCES
  IF sy-subrc = 0.
*-Hidden for all users
    lf_hide = 'X'.
  ENDIF.
  IF lf_hide = 'X'.
*--Hide the button
    LOOP AT SCREEN.
      IF screen-group2    = i_screengroup.
        screen-invisible  = '1'.
        screen-input      = 0.
        screen-active    = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " check_tab_visible
*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND_0210
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_CR_FLAG  text
*      <--P_L_INDEX  text
*      <--P_L_LINE  text
*----------------------------------------------------------------------*
*BOC:HBHALLA (08/07/24)
*Critical Role bug fixes same as Critical txns bugs(PN-4990)
FORM user_command_0210  CHANGING l_cr_flag
                                 l_index
                                 l_line.

  DATA: l_filename      LIKE rlgrap-filename,
        lt_file         LIKE g_criroles_itab OCCURS 0 WITH HEADER LINE,
        success         VALUE 'Y',
        l_file_criroles TYPE string,
        ls_filename     TYPE string,
        lt_criroles_itab LIKE TABLE OF g_criroles_itab
        WITH HEADER LINE. "HBHALLA

  RANGES : lr_vrsio FOR /psyng/critcodes-vrsio.

  crt_dte = sy-datum.
  crt_tme = sy-uzeit.
  populated = 'X'.


  CASE ok_code.
    WHEN 'INSR'.

      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                  ID 'ACTVT' FIELD '01'
                  ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH text-120.
      ENDIF.

      LOOP AT g_criroles_itab WHERE flag = 'X'.
        CLEAR g_criroles_itab-flag.
        MODIFY g_criroles_itab.
      ENDLOOP..


*      ADD 20 TO critrole-lines.
      DESCRIBE TABLE g_criroles_itab LINES critrole-lines.
      PERFORM insert_row_into_tc USING  'CRITROLE' 'G_CRIROLES_ITAB'.

    WHEN 'DELL'.


      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                  ID 'ACTVT' FIELD '06'
                  ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH text-121.
      ENDIF.

      READ TABLE g_criroles_itab WITH KEY flag = 'X'.
      IF sy-subrc <> 0.
        MESSAGE i161(/psyng/sw).
        EXIT.
      ENDIF.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = text-q01
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

*BOC: HBHALLA
      l_cr_flag = 'Y'.
*END OF CHANGE: HBHALLA

*BOC: HBHALLA
      LOOP AT g_criroles_itab WHERE flag = 'X'.
        MOVE-CORRESPONDING g_criroles_itab TO lt_criroles_itab.
        APPEND lt_criroles_itab.
      ENDLOOP.
*END OF CHANGE: HBHALLA

      DELETE g_criroles_itab WHERE flag = 'X'.

**BOC:HBHALLA
      IF gt_criroles_bckup[] IS NOT INITIAL.
        LOOP AT lt_criroles_itab.
          DELETE gt_criroles_bckup WHERE agr_name =
          lt_criroles_itab-agr_name.
        ENDLOOP.
      ENDIF.
**END OF CHANGE: HBHALLA
      DESCRIBE TABLE g_criroles_itab LINES critrole-lines.
      MESSAGE s121(/psyng/sw) WITH 'Role(s)'.

    WHEN 'SAVE'.

*      DELETE FROM /psyng/criroles WHERE agr_name > space
*                                    AND vrsio    = g_sod_vrsio.

*BOC:HBHALLA
      LOOP AT g_criroles_itab.
        MODIFY gt_criroles_bckup FROM g_criroles_itab
        TRANSPORTING owner imp
        WHERE agr_name = g_criroles_itab-agr_name.
      ENDLOOP.
*END OF CHANGE:HBHALLA

*BOC: HBHALLA
      IF gt_criroles_bckup[] IS INITIAL.
        LOOP AT g_criroles_itab.
          gt_crit_roles-agr_name = g_criroles_itab-agr_name.
          gt_crit_roles-vrsio = g_sod_vrsio.
          gt_crit_roles-owner = g_criroles_itab-owner.
          gt_crit_roles-imp = g_criroles_itab-imp.
          APPEND gt_crit_roles.
        ENDLOOP.
      ELSE.
        LOOP AT gt_criroles_bckup.
          gt_crit_roles-agr_name = gt_criroles_bckup-agr_name.
          gt_crit_roles-vrsio = g_sod_vrsio.
          gt_crit_roles-owner = gt_criroles_bckup-owner.
          gt_crit_roles-imp = gt_criroles_bckup-imp.
          APPEND gt_crit_roles.
        ENDLOOP.
      ENDIF.
*END OF CHANGE: HBHALLA

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_ROLES'
        EXPORTING
          i_vrsio             = g_sod_vrsio
          append_flag         = l_cr_flag    "HBHALLA
* IMPORTING
*         CRIROLE_ADDED       =
*         CRIROLE_MODIF       =
*         CRIROLE_DEL         =
        TABLES
          criroles            = gt_crit_roles
          texts               = gt_texts_cr
        EXCEPTIONS
          empty_list_provided = 1
          OTHERS              = 2.
      IF sy-subrc = 0.
        MESSAGE s120(/psyng/sw).  " Data Saved
      ENDIF.

      l_cr_flag = 'X'. "HBHALLA

***   SE 3.1 DEVELOPEMNT ITEM C43 Code by Shekhar 17/10/2013
***   ITEM C47 Start fix

      DELETE g_criroles_itab WHERE agr_name = space.
*BOC:HBHALLA
      IF gt_criroles_bckup[] IS INITIAL.
        DESCRIBE TABLE g_criroles_itab LINES critrole-lines.
      ELSE.
        DESCRIBE TABLE gt_criroles_bckup LINES critrole-lines.
      ENDIF.
*EOC:HBHALLA


    WHEN 'CHANGES'.

      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH s_vrsio = g_sod_vrsio
             WITH p_crole  = 'X'
*             WITH s_cauth IN lr_swaudid
             AND RETURN.

    WHEN 'ENTER'.
*     Do nothing

*   Transport table entries
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_vrsio  = g_sod_vrsio
             WITH p_tagrnm = gc_select
             AND RETURN.

** Critical role / upload download

    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_data_upload_download VIA SELECTION-SCREEN
              WITH sodvrsio  = g_sod_vrsio
*             WITH p_ttcode = gc_select
              WITH f_ct = ' '
              WITH f_ctxt = ' '
              WITH f_cr = 'X'
              WITH f_crtxt = 'X'
              WITH f_cp = ' '
              WITH f_cptxt = ' '
              WITH f_funh = ' '
              WITH f_fund = ' '
              WITH f_funt = ' '
              WITH f_objd = ' '
              WITH f_conh = ' '
              WITH f_cond = ' '
              WITH f_cont = ' '
              WITH f_cono = ' '
              WITH f_cah = ' '
              WITH f_cad = ' '
              WITH f_cat = ' '
              AND RETURN.


*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        sec_actvt = act_change.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                 ID 'ACTVT' FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
        IF sy-subrc NE 0.
          CLEAR : ok_code, sy-ucomm.
          MESSAGE e108(/psyng/sw) WITH text-019.
        ENDIF.

        gf_dispchg = gc_change.
        PERFORM check_version_editable.
        CHECK gf_dispchg = gc_change.

        CALL FUNCTION 'ENQUEUE_/PSYNG/TABLEVERS'
          EXPORTING
*           mode_/psyng/tablevers = 'X'
            tabname        = '/PSYNG/CRIROLES'
            vrsio          = g_sod_vrsio
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          gf_dispchg = gc_display.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          gt_locked-type   = 'TABLEVERS'.
          gt_locked-object = '/PSYNG/CRIROLES'.
          APPEND gt_locked.
        ENDIF.
      ELSE.
        sec_actvt = act_display.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
                 ID 'ACTVT' FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
        IF sy-subrc NE 0.
          CLEAR : ok_code, sy-ucomm.
          MESSAGE e108(/psyng/sw) WITH text-016.
        ENDIF.

        PERFORM exit_without_save.
        CHECK gf_answer = 1.
        CLEAR: first_time, gf_data_change.

        CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
          EXPORTING
*           mode_/psyng/tablevers = 'X'
            tabname = '/PSYNG/CRIROLES'
            vrsio   = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'TABLEVERS'.
        COMMIT WORK.
        gf_dispchg = gc_display.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> 1.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

      CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
        EXPORTING
          tabname = '/PSYNG/CRIROLES'
          vrsio   = g_sod_vrsio.

      DELETE gt_locked WHERE type = 'TABLEVERS'.
      CLEAR: gf_data_change, g_criroles_itab, g_criroles_itab[],
      agr_texts, populated, first_role1.

    WHEN 'FS'.
      g_fullscreen = '0210'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

    WHEN 'LTEXT'.
      DATA  : lt_texts_cr  TYPE TABLE OF /psyng/texts WITH HEADER LINE,
              lt_texts_cr1 TYPE TABLE OF /psyng/texts WITH HEADER LINE.

      REFRESH: i_text.
      DATA : l_idx LIKE sy-tabix.

      READ TABLE g_criroles_itab WITH KEY flag = 'X'.
      l_index = sy-tabix.
      IF sy-subrc NE 0.
        MESSAGE i161(/psyng/sw).
        EXIT.
      ENDIF.

      LOOP AT gt_texts_cr WHERE textname = g_criroles_itab-agr_name.
        i_text-text = gt_texts_cr-text.
        APPEND i_text.
      ENDLOOP.
      IF sy-subrc = 0.
        gt_editor_text[] = i_text[].
      ELSE.

        SELECT line text FROM /psyng/texts
           INTO CORRESPONDING FIELDS OF TABLE i_text
           WHERE textname = g_criroles_itab-agr_name
           AND   object   = 'Q'
           AND   vrsio    = g_sod_vrsio
           AND   spras    = sy-langu
           ORDER BY line.
        IF sy-subrc = 0.
          gt_editor_text[] = i_text[].
        ELSE.
          REFRESH gt_editor_text.
          CLEAR gt_editor_text.
        ENDIF.
      ENDIF.


      CONCATENATE 'Role' g_criroles_itab-agr_name '- SOD Version -'
       g_sod_vrsio INTO gtitle SEPARATED BY space.

      PERFORM popup_long_text.
      CLEAR gtitle.
      CLEAR g_criroles_itab-flag.
      REFRESH : lt_texts_cr.
      CLEAR i_text.
      REFRESH i_text.
      i_text[] = gt_editor_text[].

      FREE : gt_editor_text.
      CLEAR : gt_editor_text.

      lt_texts_cr-vrsio    = g_sod_vrsio.
      lt_texts_cr-textname = g_criroles_itab-agr_name.
      lt_texts_cr-object = 'Q'.
      IF i_text[] IS INITIAL.
        SELECT SINGLE line FROM /psyng/texts
        INTO l_line WHERE textname = g_criroles_itab-agr_name
        AND vrsio = g_sod_vrsio
        AND object = 'Q'.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts
                    WHERE textname = g_criroles_itab-agr_name
                                       AND vrsio = g_sod_vrsio
                                       AND object = 'Q'.
          MODIFY g_criroles_itab INDEX l_index TRANSPORTING flag.
          CLEAR g_criroles_itab.
          EXIT.
        ELSE.
          MODIFY g_criroles_itab INDEX l_index TRANSPORTING flag.
          CLEAR g_criroles_itab.
          EXIT.
        ENDIF.

      ELSE.

        LOOP AT i_text.
          lt_texts_cr-line =  lt_texts_cr-line + 1.
          MOVE-CORRESPONDING i_text TO lt_texts_cr.
          APPEND lt_texts_cr.
        ENDLOOP.
      ENDIF.

      lt_texts_cr[] = lt_texts_cr[].
      SORT lt_texts_cr1 BY textname.
      DELETE ADJACENT DUPLICATES FROM lt_texts_cr1 COMPARING textname.

      LOOP AT lt_texts_cr1.
        DELETE gt_texts_cr WHERE textname = lt_texts_cr1-textname.
      ENDLOOP.


      APPEND LINES OF lt_texts_cr TO gt_texts_cr.
      CLEAR lt_texts_cr.
      REFRESH lt_texts_cr.
      SORT gt_texts_cr.
      DELETE ADJACENT DUPLICATES FROM gt_texts_cr COMPARING ALL FIELDS.
      MODIFY g_criroles_itab INDEX l_index TRANSPORTING flag.
      CLEAR g_criroles_itab.

    WHEN 'CADET'.
      sec_actvt = act_print.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
               ID 'ACTVT' FIELD sec_actvt
               ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH text-050.
      ENDIF.

      SUBMIT /psyng/sw_117 WITH sodvrsio = g_sod_vrsio AND RETURN.

    WHEN 'SORT_A'.
      sort_type = 'A'.
      PERFORM sort_col_cr USING sort_type.

    WHEN 'SORT_D'.
      sort_type = 'D'.
      PERFORM sort_col_cr USING sort_type.

**    WHEN 'SEARCH'.
    WHEN 'FILTER'.

      DATA: l_tabix    LIKE sy-tabix,
            lt_crirole LIKE TABLE OF g_criroles_itab WITH HEADER LINE.

      CLEAR: gl_critrole,
             gl_critrole,
             gl_critrans.
      g_call_scrn = '0210'.
      CALL SCREEN 907 STARTING AT 3 10.
      CHECK sy-ucomm = 'CONTINUE'.

      l_cr_flag = 'X'. "HBHALLA

      RANGES: r_rrole FOR /psyng/criroles-agr_name,
                   r_rowner FOR /psyng/criroles-owner,
                   r_rimp FOR /psyng/criroles-imp.

      REFRESH: lt_crirole, r_rrole, r_rowner, r_rimp.
*--- Collect search input in ranges
      IF NOT  gl_critrole-agr_name IS INITIAL.
        IF gl_critrole-agr_name CS '*'.

          r_rrole-sign = 'I'.
          r_rrole-option = 'CP'.
        ELSE.
          r_rrole-sign = 'I'.
          r_rrole-option = 'EQ'.
        ENDIF.
        r_rrole-low =  gl_critrole-agr_name.
        COLLECT r_rrole.
      ENDIF.

      IF NOT gl_critrans-owner IS INITIAL.
        IF gl_critrans-owner CS '*'.
          r_rowner-sign = 'I'.
          r_rowner-option = 'CP'.
        ELSE.
          r_rowner-sign = 'I'.
          r_rowner-option = 'EQ'.
        ENDIF.
        r_rowner-low = gl_critrans-owner.
        COLLECT r_rowner.
      ENDIF.

      IF NOT gl_critrans-imp IS INITIAL.
        IF gl_critrans-imp CS '*'.
          r_rimp-sign = 'I'.
          r_rimp-option = 'CP'.
        ELSE.
          r_rimp-sign = 'I'.
          r_rimp-option = 'EQ'.
        ENDIF.
        r_rimp-low = gl_critrans-imp.
        COLLECT r_rimp.
      ENDIF.


*   Filter data from tc table acc. to intput
      LOOP AT g_criroles_itab WHERE agr_name IN r_rrole
                                 AND owner   IN r_rowner
                                 AND imp     IN r_rimp.

        MOVE-CORRESPONDING  g_criroles_itab TO lt_crirole.
        APPEND lt_crirole.
      ENDLOOP.
      APPEND LINES OF g_criroles_itab TO gt_criroles_bckup. "HBHALLA
      REFRESH g_criroles_itab.
      LOOP AT lt_crirole.
        MOVE-CORRESPONDING lt_crirole TO g_criroles_itab.
        APPEND g_criroles_itab.
        CLEAR lt_crirole.
      ENDLOOP.

      IF g_criroles_itab[] IS INITIAL.
        CLEAR g_filtertext.
*      ELSE.
      ENDIF.
      g_filtertext = 'Filter applied'(248).

*---->when no input in search screen
      IF gl_critrole-agr_name IS INITIAL
               AND gl_critrans-owner IS INITIAL
               AND gl_critrans-imp IS INITIAL.
        REFRESH g_criroles_itab.
        SELECT * FROM /psyng/criroles WHERE vrsio = g_sod_vrsio.
          g_criroles_itab-agr_name =  /psyng/criroles-agr_name.
          g_criroles_itab-imp     =   /psyng/criroles-imp.
          g_criroles_itab-owner = /psyng/criroles-owner.
          g_criroles_itab-flag = space.
          SELECT SINGLE text INTO g_criroles_itab-text FROM agr_texts
          WHERE agr_name =  g_criroles_itab-agr_name
          AND   spras    = sy-langu
          AND   line     = 0.
          IF sy-subrc = 0.
            APPEND g_criroles_itab.
          ELSE.
           g_criroles_itab-text = 'Role for cross system analysis'(299).
            APPEND g_criroles_itab.
          ENDIF.
          ADD 1 TO critrole-current_line.
        ENDSELECT.
        CLEAR g_filtertext.
      ENDIF.

    WHEN 'UNFILTER'.
      CLEAR: g_filtertext, g_criroles_itab[].
      SELECT * FROM /psyng/criroles WHERE vrsio = g_sod_vrsio.
        g_criroles_itab-agr_name =  /psyng/criroles-agr_name.
        g_criroles_itab-imp     =   /psyng/criroles-imp.
        g_criroles_itab-owner = /psyng/criroles-owner.
        g_criroles_itab-flag = space.
        SELECT SINGLE text INTO g_criroles_itab-text FROM agr_texts
        WHERE agr_name =  g_criroles_itab-agr_name
        AND   spras    = sy-langu
        AND   line     = 0.
        IF sy-subrc = 0.
          APPEND g_criroles_itab.
        ELSE.
          g_criroles_itab-text = 'Role for cross system analysis'(299).
          APPEND g_criroles_itab.
        ENDIF.
*        ADD 1 TO critrole-current_line. "HBHALLA
      ENDSELECT.

*BOC:HBHALLA
      IF gt_criroles_bckup[] IS NOT INITIAL.
        DESCRIBE TABLE gt_criroles_bckup LINES critrole-lines.
      ENDIF.
*EOC:HBHALLA

      REFRESH: gt_criroles_bckup. "HBHALLA
      CLEAR: gt_criroles_bckup. "HBHALLA
      DESCRIBE TABLE g_criroles_itab LINES critrole-current_line.
      "HBHALLA
      SORT g_criroles_itab BY agr_name.

    WHEN OTHERS.

      CLEAR populated.

  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.

ENDFORM.
*EOC:HBHALLA
*&---------------------------------------------------------------------*
*&      Form  USER_COMMAND_0213
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_CP_FLAG  text
*----------------------------------------------------------------------*
FORM user_command_0213  CHANGING p_l_cp_flag.

* DATA: l_filename LIKE rlgrap-filename,
  DATA: lt_file1        LIKE g_criprofs_itab OCCURS 0 WITH HEADER LINE,
        l_file_criprofs TYPE string,
        ls_filename1    TYPE string,
        lt_criprofs_itab LIKE TABLE OF g_criprofs_itab
        WITH HEADER LINE. "HBHALLA
*  RANGES : lr_vrsio FOR /psyng/criprof-vrsio.
  crt_dte = sy-datum.
  crt_tme = sy-uzeit.
  populated = 'X'.


  CASE ok_code.
    WHEN 'INSR'.

      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
                  ID 'ACTVT' FIELD '01'
                  ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH text-118.
      ENDIF.

*      ADD 20 TO critprof-lines.
      DESCRIBE TABLE g_criprofs_itab LINES critprof-lines.
      PERFORM insert_row_into_tc USING  'CRITPROF' 'G_CRIPROFS_ITAB'.


    WHEN 'DELL'.

      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
              ID 'ACTVT' FIELD '06'
              ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH text-119.
      ENDIF.

      READ TABLE g_criprofs_itab WITH KEY flag = 'X'.
      IF sy-subrc <> 0.
        MESSAGE i161(/psyng/sw).
        EXIT.
      ENDIF.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-027
          text_question         = text-q01
          text_button_1         = text-123
          icon_button_1         = 'ICON_DELETE'
          text_button_2         = text-124
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = popup_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK popup_answer = '1'.

*BOC: HBHALLA
      l_cp_flag = 'Y'.
*END OF CHANGE: HBHALLA

*BOC: HBHALLA
      LOOP AT g_criprofs_itab WHERE flag = 'X'.
        MOVE-CORRESPONDING g_criprofs_itab TO lt_criprofs_itab.
        APPEND lt_criprofs_itab.
      ENDLOOP.
*END OF CHANGE: HBHALLA

      DELETE g_criprofs_itab WHERE flag = 'X'.

**BOC:HBHALLA
      IF gt_criprofs_bckup[] IS NOT INITIAL.
        LOOP AT lt_criprofs_itab.
          DELETE gt_criprofs_bckup WHERE profn = lt_criprofs_itab-profn.
        ENDLOOP.
      ENDIF.
**END OF CHANGE: HBHALLA

      DESCRIBE TABLE g_criprofs_itab LINES critprof-lines.
      MESSAGE s121(/psyng/sw) WITH 'Profile(s)'. "deleted

    WHEN 'SAVE'.

*      DELETE FROM /psyng/criprof WHERE profile > space
*                                   AND vrsio   = g_sod_vrsio.

*BOC:HBHALLA
      LOOP AT g_criprofs_itab.
        MODIFY gt_criprofs_bckup FROM g_criprofs_itab
        TRANSPORTING owner imp
        WHERE profn = g_criprofs_itab-profn.
      ENDLOOP.
*END OF CHANGE:HBHALLA

*BOC: HBHALLA
      IF gt_criprofs_bckup[] IS INITIAL.
        LOOP AT g_criprofs_itab.
          gt_crit_profs-profile = g_criprofs_itab-profn.
          gt_crit_profs-vrsio = g_sod_vrsio.
          gt_crit_profs-owner = g_criprofs_itab-owner.
          gt_crit_profs-imp = g_criprofs_itab-imp.
          APPEND gt_crit_profs.
        ENDLOOP.
      ELSE.
        LOOP AT gt_criprofs_bckup.
          gt_crit_profs-profile = gt_criprofs_bckup-profn.
          gt_crit_profs-vrsio = g_sod_vrsio.
          gt_crit_profs-owner = gt_criprofs_bckup-owner.
          gt_crit_profs-imp = gt_criprofs_bckup-imp.
          APPEND gt_crit_profs.
        ENDLOOP.
      ENDIF.
*END OF CHANGE: HBHALLA

      CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_PROFILES'
        EXPORTING
          i_vrsio             = g_sod_vrsio
          append_flag         = l_cp_flag       "HBHALLA
*     IMPORTING
*         CRIPROF_ADDED       =
*         CRIPROF_MODIF       =
*         CRIPROF_DEL         =
        TABLES
          criprof             = gt_crit_profs
          texts               = gt_texts_cp
        EXCEPTIONS
          empty_list_provided = 1
          OTHERS              = 2.
      IF sy-subrc = 0.
        MESSAGE s120(/psyng/sw).  " Data Saved
      ENDIF.


***   SE 3.1 DEVELOPEMNT ITEM C43 Code by Shekhar 17/10/2013
***   ITEM C48 Start fix

      DELETE g_criprofs_itab WHERE profn = space.

*BOC:HBHALLA
      IF gt_criprofs_bckup[] IS INITIAL.
        DESCRIBE TABLE g_criprofs_itab LINES critprof-lines.
      ELSE.
        DESCRIBE TABLE gt_criprofs_bckup LINES critprof-lines.
      ENDIF.
*EOC:HBHALLA

***   ENDFIX.


*      success = 'Y'.
*      LOOP AT g_criprofs_itab.
*        /psyng/criprof-profile = g_criprofs_itab-profn.
*        /psyng/criprof-vrsio   = g_sod_vrsio.
*        /psyng/criprof-imp = g_criprofs_itab-imp.
*        /psyng/criprof-owner = g_criprofs_itab-owner.
*        /psyng/criprof-description = g_criprofs_itab-description.
*        INSERT /psyng/criprof.
*        IF sy-subrc NE 0.
*          success = 'N'.
*        ENDIF.
*      ENDLOOP.
*      IF success = 'Y'.
*        MESSAGE s120(/psyng/sw).  " Data Saved
*      ELSE.
*        MESSAGE s122(/psyng/sw).  " Data Not Saved
*      ENDIF.


    WHEN 'CHANGES'.

*      Clear: lr_vrsio.
*      lr_vrsio-sign   = 'I'.
*      lr_vrsio-option = 'EQ'.
*      lr_vrsio-low    = g_sod_vrsio.
*      APPEND lr_vrsio.

*      IF NOT /psyng/swaudc2-swaudid IS INITIAL.
*        lr_swaudid-sign = 'I'.
*        lr_swaudid-option = 'EQ'.
*        lr_swaudid-low = /psyng/swaudc2-swaudid.
*        APPEND lr_swaudid.

*    ENDIF.

      SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
             WITH s_vrsio = g_sod_vrsio
             WITH p_cprof  = 'X'
*             WITH s_cauth IN lr_swaudid
             AND RETURN.


    WHEN 'ENTER'.
*     Do nothing

*   Transport table entries
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_vrsio = g_sod_vrsio
             WITH p_tprof = gc_select
             AND RETURN.


**  Critical profile Upload / Download

    WHEN 'UPDOWN'.

      SUBMIT /psyng/sw_data_upload_download VIA SELECTION-SCREEN
              WITH sodvrsio  = g_sod_vrsio
*             WITH p_ttcode = gc_select
              WITH f_ct = ' '
              WITH f_ctxt = ' '
              WITH f_cr = ' '
              WITH f_crtxt = ' '
              WITH f_cp = 'X'
              WITH f_cptxt = 'X'
              WITH f_funh = ' '
              WITH f_fund = ' '
              WITH f_funt = ' '
              WITH f_objd = ' '
              WITH f_conh = ' '
              WITH f_cond = ' '
              WITH f_cont = ' '
              WITH f_cono = ' '
              WITH f_cah = ' '
              WITH f_cad = ' '
              WITH f_cat = ' '
              AND RETURN.


*   Toggle between display and change modes
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.
        sec_actvt = act_change.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
                 ID 'ACTVT' FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
        IF sy-subrc NE 0.
          CLEAR : ok_code, sy-ucomm.
          MESSAGE e108(/psyng/sw) WITH text-025.
        ENDIF.

        gf_dispchg = gc_change.
        PERFORM check_version_editable.
        CHECK gf_dispchg = gc_change.

        CALL FUNCTION 'ENQUEUE_/PSYNG/TABLEVERS'
          EXPORTING
            tabname        = '/PSYNG/CRIPROF'
            vrsio          = g_sod_vrsio
          EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
        IF sy-subrc <> 0.
          gf_dispchg = gc_display.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          gt_locked-type   = 'TABLEVERS'.
          gt_locked-object = '/PSYNG/CRIPROF'.
          APPEND gt_locked.
        ENDIF.
      ELSE.
        sec_actvt = act_display.
        AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
                 ID 'ACTVT' FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
        IF sy-subrc NE 0.
          CLEAR : ok_code, sy-ucomm.
          MESSAGE e108(/psyng/sw) WITH text-210.
        ENDIF.

        PERFORM exit_without_save.
        CHECK gf_answer = '1'.
        CLEAR: first_time, gf_data_change.

        CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
          EXPORTING
            tabname = '/PSYNG/CRIPROF'
            vrsio   = g_sod_vrsio.

        DELETE gt_locked WHERE type = 'TABLEVERS'.
        gf_dispchg = gc_display.
      ENDIF.

    WHEN 'YX_SECTAB_FC1' OR 'YX_SECTAB_FC2' OR 'YX_SECTAB_FC3' OR
         'YX_SECTAB_FC4' OR 'YX_SECTAB_FC5' OR 'YX_SECTAB_FC6' OR
         'YX_SECTAB_FC7' OR 'YX_SECTAB_FC8'.
*     If data was changed, ask if user wants to exit without saving
      IF gf_dispchg = gc_change.
        PERFORM exit_without_save.

        IF gf_answer <> '1'.
          CLEAR ok_code.
          EXIT.
        ENDIF.
      ENDIF.

      CALL FUNCTION 'DEQUEUE_/PSYNG/TABLEVERS'
        EXPORTING
          tabname = '/PSYNG/CRIPROF'
          vrsio   = g_sod_vrsio.

      DELETE gt_locked WHERE type = 'TABLEVERS'.
      CLEAR: gf_data_change, g_criprofs_itab, g_criprofs_itab[],
      agr_texts, populated, first_prof1.

    WHEN 'FS'.
      g_fullscreen = '0213'.
      CLEAR: ok_code, sy-ucomm.
      CALL SCREEN '9000'.

    WHEN 'LTEXT'.
      CLEAR l_index.
      DATA : lt_texts_cp  TYPE TABLE OF /psyng/texts WITH HEADER LINE,
             lt_texts_cp1 TYPE TABLE OF /psyng/texts WITH HEADER LINE.

      REFRESH: i_text.
      READ TABLE g_criprofs_itab WITH KEY flag = 'X'.
      l_index = sy-tabix.
      IF sy-subrc NE 0.
        MESSAGE i161(/psyng/sw).
        EXIT.
      ENDIF.

      LOOP AT gt_texts_cp WHERE textname = g_criprofs_itab-profn.
        i_text-text = gt_texts_cp-text.
        APPEND i_text.
      ENDLOOP.
      IF sy-subrc = 0.
        gt_editor_text[] = i_text[].
      ELSE.
        SELECT line text FROM /psyng/texts
           INTO CORRESPONDING FIELDS OF TABLE i_text
           WHERE textname = g_criprofs_itab-profn
           AND   object   = 'P'
           AND   vrsio    = g_sod_vrsio
           AND   spras    = sy-langu
           ORDER BY line.
        IF sy-subrc = 0.
          gt_editor_text[] = i_text[].
        ELSE.
          REFRESH gt_editor_text.
          CLEAR gt_editor_text.
        ENDIF.
      ENDIF.

      CONCATENATE 'Profile' g_criprofs_itab-profn  '- SOD Version -'
      g_sod_vrsio INTO gtitle SEPARATED BY space.
      PERFORM popup_long_text.
      CLEAR gtitle.
      CLEAR g_criprofs_itab-flag.
      CLEAR i_text.
      REFRESH i_text.
      REFRESH lt_texts_cp.

      i_text[] = gt_editor_text[].


      FREE : gt_editor_text.
      CLEAR : gt_editor_text.

      lt_texts_cp-vrsio    = g_sod_vrsio.
      lt_texts_cp-textname = g_criprofs_itab-profn.
      lt_texts_cp-object = 'P'.
      IF i_text[] IS INITIAL.
        SELECT SINGLE line FROM /psyng/texts
        INTO l_line WHERE textname = g_criprofs_itab-profn
        AND vrsio = g_sod_vrsio
        AND object = 'P'.
        IF sy-subrc = 0.
          DELETE FROM /psyng/texts
                       WHERE textname = g_criprofs_itab-profn
                          AND vrsio = g_sod_vrsio
                          AND object = 'P'.
          MODIFY g_criprofs_itab INDEX l_index TRANSPORTING flag.
          CLEAR g_criprofs_itab.
          EXIT.
        ELSE.
          MODIFY g_criprofs_itab INDEX l_index TRANSPORTING flag.
          CLEAR g_criprofs_itab.
          EXIT.
        ENDIF.
      ELSE.
        LOOP AT i_text.
          lt_texts_cp-line = lt_texts_cp-line + 1.
          MOVE-CORRESPONDING i_text TO lt_texts_cp.
          APPEND lt_texts_cp.
        ENDLOOP.
      ENDIF.

      lt_texts_cp1[] = lt_texts_cp[].
      SORT lt_texts_cp1 BY textname.
      DELETE ADJACENT DUPLICATES FROM lt_texts_cp1 COMPARING textname.

      LOOP AT lt_texts_cp1.
        DELETE gt_texts_cp WHERE textname = lt_texts_cp1-textname.
      ENDLOOP.



      APPEND LINES OF lt_texts_cp TO gt_texts_cp.
      CLEAR lt_texts_cp.
      REFRESH lt_texts_cp.

      SORT gt_texts_cp.
      DELETE ADJACENT DUPLICATES FROM gt_texts_cp COMPARING ALL FIELDS.


      MODIFY g_criprofs_itab INDEX l_index TRANSPORTING flag.
      CLEAR g_criprofs_itab.

    WHEN 'CADET'.
      sec_actvt = act_print.
      AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
               ID 'ACTVT' FIELD sec_actvt
               ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
      IF sy-subrc NE 0.
        CLEAR : ok_code, sy-ucomm.
        MESSAGE e108(/psyng/sw) WITH text-108.
      ENDIF.

      SUBMIT /psyng/sw_118 WITH sodvrsio = g_sod_vrsio AND RETURN.

    WHEN 'SORT_A'.
      sort_type = 'A'.
      PERFORM sort_col_cf USING sort_type.
      first_prof1 = 'X'.

    WHEN 'SORT_D'.
      sort_type = 'D'.
      PERFORM sort_col_cf USING sort_type.
      first_prof1 = 'X'.

*    WHEN 'SEARCH'.
    WHEN 'FILTER'.
      DATA: lt_critprof LIKE TABLE OF g_criprofs_itab WITH HEADER LINE.

      CLEAR: gl_criprofs,
             gl_critrans,
             gl_critrole.
      g_call_scrn = '0213'.
      CALL SCREEN 907 STARTING AT 3 10.
      CHECK sy-ucomm = 'CONTINUE'.

      l_cp_flag = 'X'. "HBHALLA

      RANGES: r_prof FOR /psyng/criprof-profile,
              r_owner FOR /psyng/criprof-owner,
              r_imp FOR /psyng/criprof-imp.
* --- Collect search input in Ranges
      REFRESH: lt_critprof, r_prof, r_owner, r_imp.
      IF NOT  gl_criprofs-profn IS INITIAL.
        IF gl_criprofs-profn CS '*'.

          r_prof-sign = 'I'.
          r_prof-option = 'CP'.
        ELSE.
          r_prof-sign = 'I'.
          r_prof-option = 'EQ'.
        ENDIF.
        r_prof-low =  gl_criprofs-profn.
        COLLECT r_prof.
      ENDIF.

      IF NOT gl_critrans-owner IS INITIAL.
        IF gl_critrans-owner CS '*'.
          r_owner-sign = 'I'.
          r_owner-option = 'CP'.
        ELSE.
          r_owner-sign = 'I'.
          r_owner-option = 'EQ'.
        ENDIF.
        r_owner-low = gl_critrans-owner.
        COLLECT r_owner.
      ENDIF.

      IF NOT gl_critrans-imp IS INITIAL.
        IF gl_critrans-imp CS '*'.
          r_imp-sign = 'I'.
          r_imp-option = 'CP'.
        ELSE.
          r_imp-sign = 'I'.
          r_imp-option = 'EQ'.
        ENDIF.
        r_imp-low = gl_critrans-imp.
        COLLECT r_imp.
      ENDIF.

**** Filter data from tc table acc. to Search input
      LOOP AT g_criprofs_itab WHERE   profn    IN r_prof
                                 AND  owner   IN r_owner
                                 AND imp    IN r_imp.

        MOVE-CORRESPONDING  g_criprofs_itab TO lt_critprof.
        APPEND lt_critprof.
      ENDLOOP.
      APPEND LINES OF g_criprofs_itab TO gt_criprofs_bckup. "HBHALLA
      REFRESH g_criprofs_itab.
      LOOP AT lt_critprof.
        MOVE-CORRESPONDING lt_critprof TO g_criprofs_itab.
        APPEND g_criprofs_itab.
        CLEAR: lt_critprof.
      ENDLOOP.

      IF g_criprofs_itab[] IS INITIAL.
        CLEAR g_filtertext_p.
*      ELSE.
      ENDIF.
      g_filtertext_p = 'Filter applied'(248).

*---->when no input in search screen
      IF gl_criprofs-profn IS INITIAL
               AND gl_critrans-owner IS INITIAL
               AND gl_critrans-imp IS INITIAL.
        REFRESH g_criprofs_itab.

        SELECT * FROM /psyng/criprof WHERE vrsio = g_sod_vrsio.
          g_criprofs_itab-profn =  /psyng/criprof-profile.
          g_criprofs_itab-imp     =   /psyng/criprof-imp.
          g_criprofs_itab-flag = space.
          g_criprofs_itab-owner = /psyng/criprof-owner.

          SELECT SINGLE ptext INTO  g_criprofs_itab-ptext FROM usr11
          WHERE profn =  g_criprofs_itab-profn
          AND   langu    = sy-langu
          AND   aktps    = 'A'.
          IF sy-subrc = 0.
            APPEND g_criprofs_itab.
          ELSE.
       g_criprofs_itab-ptext = 'Profile for cross system analysis'(300).
            APPEND g_criprofs_itab.
          ENDIF.
          ADD 1 TO critprof-current_line.
        ENDSELECT.

        CLEAR g_filtertext_p.
      ENDIF.

    WHEN 'PUNFILTER'.
      CLEAR: g_filtertext_p, g_criprofs_itab[].

      SELECT * FROM /psyng/criprof WHERE vrsio = g_sod_vrsio.
        g_criprofs_itab-profn =  /psyng/criprof-profile.
        g_criprofs_itab-imp     =   /psyng/criprof-imp.
        g_criprofs_itab-flag = space.
        g_criprofs_itab-owner = /psyng/criprof-owner.

        SELECT SINGLE ptext INTO  g_criprofs_itab-ptext FROM usr11
        WHERE profn =  g_criprofs_itab-profn
        AND   langu    = sy-langu
        AND   aktps    = 'A'.
        IF sy-subrc = 0.
          APPEND g_criprofs_itab.
        ELSE.
       g_criprofs_itab-ptext = 'Profile for cross system analysis'(300).
          APPEND g_criprofs_itab.
        ENDIF.
*        ADD 1 TO critprof-current_line. "HBHALLA
      ENDSELECT.

*BOC:HBHALLA
      IF gt_criprofs_bckup[] IS NOT INITIAL.
        DESCRIBE TABLE gt_criprofs_bckup LINES critprof-lines.
      ENDIF.
*EOC:HBHALLA

      REFRESH: gt_criprofs_bckup. "HBHALLA
      CLEAR: gt_criprofs_bckup. "HBHALLA
      DESCRIBE TABLE g_criprofs_itab LINES critprof-current_line.
      "HBHALLA
      SORT g_criprofs_itab BY profn.

    WHEN OTHERS.
      CLEAR populated.
  ENDCASE.

* Clear OK_CODE unless other tabs are selected
  IF ok_code NS '_FC'.
    CLEAR ok_code.
  ENDIF.

ENDFORM.
