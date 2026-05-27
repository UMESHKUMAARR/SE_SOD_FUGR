*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_082_EVT_CLS
*
*----------------------------------------------------------------------*
class lcl_tree_event_receiver definition.

  public section.


    methods handle_button_click
      for event button_click of cl_gui_alv_tree
      importing node_key
                fieldname
                sender.

endclass.

*---------------------------------------------------------------------*
*       CLASS lcl_tree_event_receiver IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
class lcl_tree_event_receiver implementation.

  method handle_button_click.

    DATA: ls_outtab TYPE GT_FINAL_TAB .
    IF ( fieldname = 'PSHBTN_SOD' ).

      CALL METHOD SENDER->get_outtab_line
        EXPORTING
          i_node_key     = node_key
        IMPORTING
          e_outtab_line  = ls_outtab
*          e_node_text    =
*          et_item_layout =
*          es_node_layout =
        EXCEPTIONS
          node_not_found = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
*       MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                  WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
      IF ls_outtab-CHILD_AGR = 'COMPOSITE ROLE' AND
ls_outtab-FLAG_COM_ROLE = 'X'.

        SUBMIT /PSYNG/SODREPORT_ORG WITH ROLE = ls_outtab-agr_name
                                    WITH BYROLE = 'X'
                                    WITH BYUSER = ' '
                                     AND RETURN.
      ELSEIF ls_outtab-FLAG_COM_ROLE = 'X'.

        SUBMIT /PSYNG/SODREPORT_ORG WITH ROLE = ls_outtab-CHILD_AGR
                                       WITH BYROLE = 'X'
                                       WITH BYUSER = ' '
                                              AND RETURN.
     ELSE.

               SUBMIT /PSYNG/SODREPORT_ORG WITH ROLE  =
                                                     ls_outtab-agr_name
                                       WITH BYROLE = 'X'
                                       WITH BYUSER = ' '
                                              AND RETURN.

      ENDIF.
*
    ENDIF.
  endmethod.




endclass.
