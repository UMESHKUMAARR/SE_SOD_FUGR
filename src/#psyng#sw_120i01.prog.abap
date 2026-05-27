**----------------------------------------------------------------------*
****INCLUDE /PSYNG/SW_120I01 .
**----------------------------------------------------------------------*
**&---------------------------------------------------------------------*
**&      Module  USER_COMMAND_0100  INPUT
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*MODULE user_command_0100 INPUT.
*  CASE sy-ucomm.
*    WHEN 'EXIT'.
*      SET SCREEN 0.
*      EXIT.
*    WHEN 'ANALYZE'.
*      SUBMIT /psyng/sw_119 VIA SELECTION-SCREEN AND RETURN.
*    WHEN 'UPDATE'.
*      SUBMIT /psyng/sw_116 VIA SELECTION-SCREEN AND RETURN.
*    WHEN 'DELETE'.
*      SUBMIT /psyng/sw_121 VIA SELECTION-SCREEN AND RETURN.
*    WHEN 'MAINT'.
*      SUBMIT /psyng/sw_rfc_maintain_alv AND RETURN.
*    WHEN 'VERIF'.
*      PERFORM verify_configuration.
*    WHEN 'HIGHL'.
*      PERFORM update_alv.
*  ENDCASE.
*
*ENDMODULE.                 " USER_COMMAND_0100  INPUT
**&---------------------------------------------------------------------*
**&      Form  verify_configuration
**&---------------------------------------------------------------------*
**       Verify the Configuration Settings are ok.
**----------------------------------------------------------------------*
*FORM verify_configuration.
* DATA : lt_destinations TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
*              lt_names TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.
*  DATA: BEGIN OF itab OCCURS 10,
*          msgty TYPE msgty,
*          msg   TYPE msgv1,
*        END OF itab,
*        l_sysclient TYPE string,
*        l_system_msg(80) TYPE c,
*        l_local_sys TYPE rfcdest,
*        ls_config TYPE /psyng/swconfig,
*        lf_no_central_rfc TYPE flag,
*        l_msg TYPE string,
*        lf_success TYPE flag,
*        l_rfc TYPE rfcdest.
*  CALL FUNCTION 'MESSAGES_INITIALIZE'.
*
**--Get name of RFC destination pointing from remote system
**  back to central system
*  se_config_param 'SE_CENTRAL_RFC' ls_config-value.
*
*  IF ls_config-value IS INITIAL.
*    itab-msgty = 'E'.
*    CONCATENATE 'Configuration parameter '
*                'SE_CENTRAL_RFC'
*                'not configured'
*        INTO itab-msg SEPARATED BY space.
*    APPEND itab.
*    lf_no_central_rfc = 'X'.
*  ELSE.
*    g_central_system = ls_config-value.
*  ENDIF.
*
*
*  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
*
**--Get all systems for which we have results
**--Functions
*  SELECT DISTINCT sysclient AS rfcname    "#EC CI_NOWHERE
*                                          "#EC CI_NOFIELD
*                                          "#EC CI_NOFIRST
*  FROM /psyng/sw_cntfun
*  INTO CORRESPONDING FIELDS OF TABLE lt_names
*  WHERE sysclient IS not NULL.
**--Critical Auths
*  SELECT DISTINCT sysclient AS rfcname  "#EC CI_NOWHERE
*                                        "#EC CI_NOFIELD
*                                        "#EC CI_NOFIRST
*  FROM /psyng/sw_cntca
*  APPENDING CORRESPONDING FIELDS OF TABLE lt_names
*  WHERE sysclient IS not NULL.
**--Critical Tcode
*  SELECT DISTINCT sysclient AS rfcname     "#EC CI_NOWHERE
*                                           "#EC CI_NOFIELD
*                                           "#EC CI_NOFIRST
*  FROM /psyng/sw_cnttcd
*  INTO CORRESPONDING FIELDS OF TABLE lt_names
*  WHERE sysclient IS not NULL.
*
*  SORT lt_names BY rfcname.
*  DELETE ADJACENT DUPLICATES FROM lt_names COMPARING rfcname.
*
*  IF NOT lt_names[] IS INITIAL.
**--Select rfc destinations
*    SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_destinations
*    FOR ALL ENTRIES IN lt_names WHERE rfcname = lt_names-rfcname.
*  ENDIF.
*
*
*  LOOP AT lt_names WHERE rfcname <> l_local_sys.
*    READ TABLE lt_destinations WITH KEY rfcname = lt_names-rfcname.
*    IF sy-subrc = 0.
**--Test if RFC destination can be reached, and the name is SYSID MANDT.
*      CALL FUNCTION '/PSYNG/SW_062' DESTINATION lt_destinations-rfcdest
*       IMPORTING
*         e_rfcdest       = l_sysclient
*        EXCEPTIONS
*              communication_failure = 1 MESSAGE l_system_msg
*              system_failure        = 2 MESSAGE l_system_msg
*              OTHERS                = 3.
*      l_rfc = l_sysclient.
*      IF sy-subrc = 0.
*        IF l_rfc = lt_destinations-rfcname.
*          itab-msgty = 'S'.
*          CONCATENATE 'Destination valid for'
*                      lt_destinations-rfcname
*                      ' ('
*                      lt_destinations-rfcdest
*                      ')'
*          INTO itab-msg SEPARATED BY space.
*          APPEND itab.
*        ELSE.
*          itab-msgty = 'E'.
*          CONCATENATE 'Destination  '
*                      lt_destinations-rfcdest
*                      'not valid for '
*                      lt_destinations-rfcname
*              INTO itab-msg SEPARATED BY space.
*          APPEND itab.
*          itab-msgty = 'E'.
*          CONCATENATE 'Destination '
*                      lt_destinations-rfcdest
*                      ' points to  '
*                      l_sysclient
*          INTO itab-msg SEPARATED BY space.
*          APPEND itab.
*        ENDIF.
*      ELSE.
*        itab-msgty = 'E'.
*        CONCATENATE 'Destination  '
*                    lt_destinations-rfcdest
*                    'not valid for'
*                    lt_destinations-rfcname
*      INTO itab-msg SEPARATED BY space.
*        APPEND itab.
*        IF sy-subrc = 1 OR sy-subrc = 2.
*          itab-msgty = 'E'.
*          itab-msg = l_system_msg.
*          APPEND itab.
*        ENDIF.
*
*      ENDIF.
**--Test if the remote system can reach this system using the
**  rfc destination configured in SE_CENTRAL_RFC configuration parameters
**
*      CALL FUNCTION '/PSYNG/RFC_WALKTHROUGH_TEST'
*      DESTINATION lt_destinations-rfcdest
*        EXPORTING
*          i_rfcdest         = g_central_system
*       IMPORTING
*         e_message         = l_msg
*         e_success         = lf_success
*         e_sysclient       = l_sysclient.
*      l_rfc = l_sysclient.
*      IF lf_success = 'X'.
*        IF l_rfc = l_local_sys.
*          itab-msgty = 'S'.
*          CONCATENATE ls_config-value
*                      'on ' lt_destinations-rfcname
*                      'correct (->' l_local_sys ')'
*        INTO itab-msg SEPARATED BY space.
*          APPEND itab.
*        ELSE.
*          itab-msgty = 'E'.
*          CONCATENATE g_central_system
*                      'on' lt_destinations-rfcname
*                      '->' l_sysclient
*        INTO itab-msg SEPARATED BY space.
*          APPEND itab.
*        ENDIF.
*      ELSE.
*        itab-msgty = 'E'.
*        CONCATENATE g_central_system
*                    'on' lt_destinations-rfcname
*                    'not reachable'
*      INTO itab-msg SEPARATED BY space.
*        APPEND itab.
*        IF NOT l_msg IS INITIAL.
*          itab-msgty = 'E'.
*          itab-msg = l_system_msg.
*          APPEND itab.
*        ENDIF.
*      ENDIF.
*
*    ELSE.
*      itab-msgty = 'E'.
*      CONCATENATE 'No destination  for'
*                  lt_names-rfcname
*                  INTO itab-msg SEPARATED BY space.
*      APPEND itab.
*    ENDIF.
*  ENDLOOP.
*  LOOP AT itab.
*    CALL FUNCTION 'MESSAGE_STORE'
*         EXPORTING
*              arbgb                  = '/PSYNG/SW'
*              msgty                  = itab-msgty
*              msgv1                  = itab-msg
*              txtnr                  = '140'
*         EXCEPTIONS
*              message_type_not_valid = 1
*              not_active             = 2
*              OTHERS                 = 3.
*  ENDLOOP.
*  CALL FUNCTION 'MESSAGES_STOP'
*       EXCEPTIONS
*            a_message = 1
*            e_message = 2
*            i_message = 3
*            w_message = 4
*            OTHERS    = 5.
*
*  CALL FUNCTION 'MESSAGES_SHOW'
*       EXPORTING
*            show_linno         = ' '
*       EXCEPTIONS
*            inconsistent_range = 1
*            no_messages        = 2
*            OTHERS             = 3.
*
*  REFRESH : itab.
*
*
*
*ENDFORM.                    " verify_configuration
**&---------------------------------------------------------------------*
**&      Module  USER_COMMAND_0200  INPUT
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*MODULE user_command_0200 INPUT.
*  IF sy-ucomm = 'OK'.
*    DATA : lt_names TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.
*    SELECT SINGLE * FROM /psyng/sw_rfcdes INTO  lt_names
*     WHERE rfcname = gt_overview-sysclient.
*    IF sy-subrc = 0.
**--read select options from subscreen
*
*      CALL FUNCTION '/PSYNG/SW_119' DESTINATION lt_names-rfcdest
*       EXPORTING
*         i_rfcdest                      = rfcs
*         if_sod                         = p_sod
*         if_ca                          = p_ca
*         if_tcode                       = p_tc
*         if_activeonly                  = p_active
*         i_wp                           = upp
*         i_upp                          = 5000
*         i_group                        = pgroup
*         i_vrsio                        = p_vrsio
*         i_server                       = pserver
**       I_JOBNAME                      =
*         if_direct                      = g_job_immediate
*         if_update                      = p_updat
*         if_initialize                  = p_init
*         i_period_type                  = g_job_period
*         i_period_number                = g_job_period_number
*         i_start_date                   = g_job_start_date
*         i_start_time                   = g_job_start_time
*       TABLES
*         it_users                       = s_bname
*       EXCEPTIONS
*         failed_to_schedule             = 1
*         failed_to_create_variant       = 2
*         OTHERS                         = 3
*                .
*      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*      ENDIF.
*    ELSE.
*      MESSAGE e002(/psyng/sw) WITH
*      'No destination  for'
*      lt_names-rfcname.
*    ENDIF.
*
*  ENDIF.
*  IF sy-ucomm = 'OK' OR  sy-ucomm = 'CANCEL'.
**--Close Popup
*    SET SCREEN 0.
*    LEAVE  SCREEN.
*  ENDIF.
*ENDMODULE.                 " USER_COMMAND_0200  INPUT
