*&---------------------------------------------------------------------*
*& Module pool       /PSYNG/SECUCPS                                    *
*&                                                                     *
*&---------------------------------------------------------------------*
*& Program to capture Corporate Security Policy on Security            *
*&
*&                                                                     *
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECUCPS
* AUTHOR                : Principal Synergy LLC
* RELEASE               : 1.0
* DATE OF RELEASE       : 10/19/2004
* TRANSPORT REQUEST #   :
*----------------------------------------------------------------------*
*
* COPYRIGHTS Principal Synergy LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

INCLUDE /PSYNG/SECTOP.
*&---------------------------------------------------------------------*
*&      Module  init_editor312  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  INIT_0311  OUTPUT
*&---------------------------------------------------------------------*
MODULE INIT0311 OUTPUT.
  DESCRIBE TABLE I_TEXT LINES TEXT_FILL.
ENDMODULE.                             " INIT_0311  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  INIT_0312  OUTPUT
*&---------------------------------------------------------------------*
MODULE INIT0312 OUTPUT.
  SET PF-STATUS '100'.
  SET TITLEBAR '100'.
  DATA POLICY LIKE /PSYNG/POLICY-POLICY.
  SELECT * FROM /PSYNG/POLICY INTO /PSYNG/POLICY
  WHERE POLICY = 'CPOS'.
  ENDSELECT.

  IF SY-SUBRC = 0.
    EXIST = 'X'.
  ELSE.
    EXIST = ' '.
  ENDIF.

  SELECT * FROM /PSYNG/TEXTS WHERE TEXTNAME = 'CPOS'.
    I_TEXT = /PSYNG/TEXTS-TEXT.
    APPEND I_TEXT.
  ENDSELECT.

  DESCRIBE TABLE I_TEXT LINES TEXT_FILL.

ENDMODULE.                             " INIT_0312  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  INIT_EDITOR312  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE INIT_EDITOR312 OUTPUT.

  DATA: SEDITOR_CONTAINER TYPE REF TO CL_GUI_CUSTOM_CONTAINER.
  DATA: STEXT_EDITOR TYPE REF TO CL_GUI_TEXTEDIT.
  DATA: G_EDITOR_TEXT TYPE TABLE OF CHAR80.
  DATA: STEXT_RELOAD TYPE CHAR1.


  IF STEXT_EDITOR IS INITIAL.

*   create control container
    CREATE OBJECT SEDITOR_CONTAINER
        EXPORTING
            CONTAINER_NAME = 'STEXTEDITOR'
*            repid          = g_repid
        EXCEPTIONS
            CNTL_ERROR = 1
            CNTL_SYSTEM_ERROR = 2
            CREATE_ERROR = 3
            LIFETIME_ERROR = 4
            LIFETIME_DYNPRO_DYNPRO_LINK = 5.

    IF SY-SUBRC NE 0.
*      break liemke.
      MESSAGE E802(BMEN).
    ENDIF.


*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
    CREATE OBJECT STEXT_EDITOR
      EXPORTING
         PARENT = SEDITOR_CONTAINER
         WORDWRAP_MODE = CL_GUI_TEXTEDIT=>WORDWRAP_AT_FIXED_POSITION
         WORDWRAP_TO_LINEBREAK_MODE = CL_GUI_TEXTEDIT=>TRUE
         WORDWRAP_POSITION = 80
      EXCEPTIONS
          OTHERS = 1.

    IF SY-SUBRC NE 0.
*      break liemke.
      MESSAGE E802(BMEN).
    ENDIF.

    STEXT_RELOAD = 'X'.

  ENDIF.

  IF STEXT_RELOAD = 'X'.

*   copy text
    G_EDITOR_TEXT[] = I_TEXT[].

*   fill with text
    CALL METHOD STEXT_EDITOR->SET_TEXT_AS_R3TABLE
      EXPORTING
        TABLE           = G_EDITOR_TEXT
      EXCEPTIONS
        ERROR_DP        = 1
        ERROR_DP_CREATE = 2
        OTHERS          = 3.

    IF SY-SUBRC NE 0.
*      break liemke.
      MESSAGE E802(BMEN).
    ENDIF.

*   finally flush
    CALL METHOD CL_GUI_CFW=>FLUSH
           EXCEPTIONS
             OTHERS = 1.

    IF SY-SUBRC NE 0.
*      break liemke.
      MESSAGE E802(BMEN).
    ENDIF.

    STEXT_RELOAD = SPACE.

  ENDIF.

  CALL METHOD STEXT_EDITOR->SET_READONLY_MODE
       EXPORTING
         READONLY_MODE = CL_GUI_TEXTEDIT=>FALSE
       EXCEPTIONS
         ERROR_CNTL_CALL_METHOD = 1
         INVALID_PARAMETER = 2.



ENDMODULE.                             " INIT_EDITOR312  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.
* BOC by RGUPTA on 28.03.22 for C0700
   DATA: l_current_user type sy-uname.

  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
  CASE OK_CODE.
    WHEN 'SAVE'.
      IF EXIST = 'X'.
        /PSYNG/POLICY-POLICY = 'CPOS'.
        /PSYNG/POLICY-CHANGE_USR = l_current_user."SY-UNAME. C0700
        /PSYNG/POLICY-CHANGE_DAT = SY-DATUM.
        /PSYNG/POLICY-CHANGE_TIM = SY-UZEIT.
        UPDATE /PSYNG/POLICY.
      ELSE.
        /PSYNG/POLICY-POLICY = 'CPOS'.
        /PSYNG/POLICY-CREATE_USR = l_current_user."SY-UNAME. C0700
        /PSYNG/POLICY-CREATE_DAT = SY-DATUM.
        /PSYNG/POLICY-CREATE_TIM = SY-UZEIT.
        /PSYNG/POLICY-CHANGE_USR = l_current_user."SY-UNAME. C0700
        /PSYNG/POLICY-CHANGE_DAT = SY-DATUM.
        /PSYNG/POLICY-CHANGE_TIM = SY-UZEIT.
        INSERT /PSYNG/POLICY.
      ENDIF.

      DELETE FROM /PSYNG/TEXTS WHERE TEXTNAME = 'CPOS'.
      LOOP AT I_TEXT.
        IF SY-TABIX > 0.
          /PSYNG/TEXTS-TEXTNAME = 'CPOS'.
          /PSYNG/TEXTS-LINE = SY-TABIX.
          /PSYNG/TEXTS-SPRAS = 'E'.
          /PSYNG/TEXTS-TEXT = I_TEXT-TEXT.
          INSERT /PSYNG/TEXTS.
        ENDIF.
      ENDLOOP.
    WHEN 'EXIT'.
      LEAVE TO TRANSACTION '/PSYNG/SW'.
      EXIT.

    WHEN 'CANCEL'.

      LEAVE TO SCREEN 0.
      EXIT.

    WHEN 'BACK'.

      LEAVE TO TRANSACTION '/PSYNG/SW'.
      EXIT.

    WHEN OTHERS.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT

*&---------------------------------------------------------------------*
*&      Module  command_editor312  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE command_editor312 INPUT.
* move text from edit control to table i_text
  PERFORM GET_EDITOR_TEXT.

ENDMODULE.                 " command_editor312  INPUT
*&---------------------------------------------------------------------*
*&      Form  GET_EDITOR_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM GET_EDITOR_TEXT.

  data: l_stext_modified type i.

* retrieve table from control
  call method stext_editor->get_text_as_r3table
      exporting
          only_when_modified = cl_gui_textedit=>true
      importing
          table = g_editor_text
          is_modified = l_stext_modified
      exceptions
          others = 1.

  if sy-subrc ne 0.
    message e800(bmen).
  endif.

* change table if text has been modified
  if l_stext_modified = cl_gui_textedit=>true.
    modified = 'X'.
    i_text[] = g_editor_text[].
  endif.

ENDFORM.                    " GET_EDITOR_TEXT
