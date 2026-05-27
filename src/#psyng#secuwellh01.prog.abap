*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SECUWELLH01                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_FOR_POSDES_FIELD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f1_help_for_posdes_field INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_POS_DESC'.


ENDMODULE.                 " F1_HELP_FOR_POSDES_FIELD  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_FOR_ROLE_FIELD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f1_help_for_role_field INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_PFCGROLE'.


ENDMODULE.                 " F1_HELP_FOR_ROLE_FIELD  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_FOR_USERID_FIELD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f1_help_for_userid_field INPUT.

  PERFORM show_help USING '/PSYNG/SECUWELL_USERID'.

ENDMODULE.                 " F1_HELP_FOR_USERID_FIELD  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_FOR_VALIDDTE_FIELD  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f1_help_for_validdte_field INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_VALIDDTE'.

ENDMODULE.                 " F1_HELP_FOR_VALIDDTE_FIELD  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_APP_AREA  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Application Area in Function tab
*----------------------------------------------------------------------*
MODULE f1_help_app_area INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_BUSAREA'.



ENDMODULE.                 " F1_HELP_APP_AREA  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_OWNER  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Owner in Function tab
*----------------------------------------------------------------------*
MODULE f1_help_owner INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_OWNER'.

ENDMODULE.                 " F1_HELP_OWNER  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_APPL_AREA  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Owner in SOD Conflict tab
*----------------------------------------------------------------------*
MODULE f1_help_appl_area INPUT.

  PERFORM show_help USING '/PSYNG/SECUWELL_CON_BUSAREA'.


ENDMODULE.                 " F1_HELP_APPL_AREA  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_CON_OWNER  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Owner in SOD Conflict tab
*----------------------------------------------------------------------*
MODULE f1_help_con_owner INPUT.

  PERFORM show_help USING '/PSYNG/SECUWELL_CON_OWNER'.


ENDMODULE.                 " F1_HELP_CON_OWNER  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_APPROVER  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Approver in Mitication Controls
*----------------------------------------------------------------------*
MODULE f1_help_approver INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_APPROVER'.


ENDMODULE.                 " F1_HELP_APPROVER  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_TCODE  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Tcode in Critical Txns
*----------------------------------------------------------------------*
MODULE f1_help_tcode INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_TCODE'.

ENDMODULE.                 " F1_HELP_TCODE  INPUT


*&---------------------------------------------------------------------
*
*&      Module  F1_HELP_AUDITIOR  INPUT
*&---------------------------------------------------------------------
*
*       F1 help for Auditor in Mitication Controls
*----------------------------------------------------------------------
*
MODULE f1_help_auditior INPUT.

  PERFORM show_help USING '/PSYNG/SECUWELL_AUDITOR'.



ENDMODULE.                 " F1_HELP_AUDITIOR  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_OBJECTID  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Object Id in Mitication Controls
*----------------------------------------------------------------------*
MODULE f1_help_objectid INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_OBJECTID'.


ENDMODULE.                 " F1_HELP_OBJECTID  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_SWAUDID  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Auth Obj Id in Critical Auths
*----------------------------------------------------------------------*
MODULE f1_help_swaudid INPUT.


  PERFORM show_help USING '/PSYNG/SECUWELL_SWAUDID'.


ENDMODULE.                 " F1_HELP_SWAUDID  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_SW_TCODE  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Tcode in Critical Auths
*----------------------------------------------------------------------*
MODULE f1_help_sw_tcode INPUT.

  PERFORM show_help USING '/PSYNG/SECUWELL_SW_TCODE'.


ENDMODULE.                 " F1_HELP_SW_TCODE  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_DESCRIPTION  INPUT
*&---------------------------------------------------------------------*
*       F1 help for Description in Critical Auths
*----------------------------------------------------------------------*
MODULE f1_help_description INPUT.

  PERFORM show_help USING  '/PSYNG/SECUWELL_DESCRIPTION'.

ENDMODULE.                 " F1_HELP_DESCRIPTION  INPUT

*&---------------------------------------------------------------------*
*&      Module  F1_HELP_ROLE_OWNER  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f1_help_role_owner INPUT.

  PERFORM show_help USING  '/PSYNG/SECUWELL_ROLE_OWNER'.


ENDMODULE.                 " F1_HELP_ROLE_OWNER  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_ROLEMODULE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f1_help_rolemodule INPUT.


  PERFORM show_help USING  '/PSYNG/SECUWELL_ROLEMODULE'.


ENDMODULE.                 " F1_HELP_ROLEMODULE  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_AUDITOR  INPUT
*&---------------------------------------------------------------------*
*       text:Mitigation auditor
*----------------------------------------------------------------------*
MODULE f1_help_auditor INPUT.

  PERFORM show_help USING  '/PSYNG/SECUWELL_AUDITOR'.

ENDMODULE.                 " F1_HELP_AUDITOR  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_MCUSER  INPUT
*&---------------------------------------------------------------------*
*       text:mitigation user in 211 screen
*----------------------------------------------------------------------*
MODULE f1_help_mcuser INPUT.

  PERFORM show_help USING  '/PSYNG/SECUWELL_MCUSER'.

ENDMODULE.                 " F1_HELP_MCUSER  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_MCUGROUP  INPUT
*&---------------------------------------------------------------------*
*       text:mitigation usergroup in 222 screen
*----------------------------------------------------------------------*
MODULE f1_help_mcugroup INPUT.

  PERFORM show_help USING  '/PSYNG/SECUWELL_MCUGROUP'.

ENDMODULE.                 " F1_HELP_MCUGROUP  INPUT


*&---------------------------------------------------------------------*
*&      Module  F1_HELP_CRI_AUTH_USER  INPUT
*&---------------------------------------------------------------------*
*       text:mitigation assignment for criauth user for screen 223
*----------------------------------------------------------------------*
MODULE f1_help_cri_auth_user INPUT.

  PERFORM show_help USING  '/PSYNG/SECUWELL_CRIAUTH USER'.

ENDMODULE.                 " F1_HELP_CRI_AUTH_USER  INPUT

************************************************************************
**Common form for all f1 help fields in SW Product******************
*******************************************************************
*&---------------------------------------------------------------------*
*&      Form  show_help
*&---------------------------------------------------------------------*
*       Show f1 help for fields in SW Product
*----------------------------------------------------------------------*
*      -->I_DOKNAME  Document name
*----------------------------------------------------------------------*
FORM show_help USING    i_dokname.

  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
       EXPORTING
            dokname = i_dokname.

ENDFORM.                    " show_help
*&---------------------------------------------------------------------*
*&      Module  f4_subarea_dropdown_box  INPUT
*&---------------------------------------------------------------------*
*  Getting Subarea text values dynamically in Dropdown box
*----------------------------------------------------------------------*
MODULE f4_subarea_dropdown_box INPUT.
* getting text values for subarea of conflcit
*table dynamically
  TYPE-POOLS :vrm .
  DATA: BEGIN OF lt_bus OCCURS 0,
          l_subarea TYPE /psyng/bus_proce-subarea,
          l_text TYPE /psyng/bus_proce-text,
        END OF lt_bus.

  DATA: l_name TYPE vrm_id,
  lt_list TYPE vrm_values,
  ls_value LIKE LINE OF lt_list.


  l_name = '/psyng/conflict-subarea'.

  REFRESH:lt_bus.
  REFRESH:lt_list.

*  SELECT DISTINCT subarea text FROM  /psyng/bus_proce INTO TABLE lt_bus
*.

  SELECT subarea text FROM  /psyng/bus_proce INTO TABLE lt_bus.
  SORT lt_bus BY l_subarea.
  DELETE ADJACENT DUPLICATES FROM lt_bus.

  LOOP AT lt_bus.

    ls_value-key = lt_bus-l_subarea .
    ls_value-text = lt_bus-l_text.
    APPEND ls_value TO lt_list.
    CLEAR:ls_value.
  ENDLOOP.


  CALL FUNCTION 'VRM_SET_VALUES'
       EXPORTING
            id     = l_name
            values = lt_list
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             id_illegal_name = 1
             OTHERS         = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDMODULE.                 " f4_subarea_dropdown_box  INPUT
