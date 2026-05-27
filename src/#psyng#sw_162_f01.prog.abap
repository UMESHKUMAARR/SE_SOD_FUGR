*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_162_F01
*&---------------------------------------------------------------------*


*&---------------------------------------------------------------------*
*&      Form  fetch_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fetch_data CHANGING lt_functtran TYPE tt_functtran
                         lt_faobj2    TYPE tt_faobj2.



*  Fetch data from table /psyng/functtran
  SELECT mandt
         functionid
         tcode
         vrsio
         type
         fioriid
         FROM /psyng/functtran
         INTO TABLE lt_functtran
         WHERE vrsio      = p_vrsion AND
               functionid IN so_fun.


  IF  NOT lt_functtran[] IS INITIAL.
    "There is no data in SOD matrix.
*  Fetch data from table /psyng/faobj2
    SELECT mandt
           vrsio
           funid
           tcode
           FROM /psyng/faobj2
           INTO TABLE lt_faobj2
      FOR ALL ENTRIES IN lt_functtran
           WHERE vrsio  = p_vrsion AND
                 funid  IN so_fun  AND
                 tcode  = lt_functtran-tcode      .
    IF sy-subrc <> 0.
      "There is no data in SOD matrix.
    ENDIF.

  ELSE.
    MESSAGE : 'Nothing to update.'(002) TYPE 'S'.
    LEAVE LIST-PROCESSING.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DATA_PROCESSING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LT_FUNCTTRAN  text
*----------------------------------------------------------------------*
FORM data_processing  USING    lt_functtran TYPE tt_functtran
                               lt_faobj2    TYPE tt_faobj2
                      CHANGING lt_logs            TYPE tt_logs
                               l_total_count      TYPE n
                               l_count            TYPE n
                               l_functtran_count  TYPE n
                               l_faobj2_count     TYPE n .

  FIELD-SYMBOLS: <fs_ft>     TYPE /psyng/functtran,
                 <fs_faobj2> TYPE ty_faobj2.         "HBHALLA


  DATA: ls_logs        TYPE ty_logs,
        lv_fioriid_len TYPE i,
        lv_new_fidtcd  TYPE tcode,
        lv_init_fid    TYPE string,
        lv_slash_match TYPE match_result_tab,
        lv_flag        TYPE flag.

CLEAR : ls_logs, lt_logs[].
  LOOP AT lt_functtran ASSIGNING <fs_ft>.

* Only update type if values are blank instead (p,t, f)
    IF <fs_ft>-type IS INITIAL.

      "HBHALLA BOC (15/12/23)
      IF <fs_ft>-fioriid IS NOT INITIAL.
        <fs_ft>-type = 'F'.

        ls_logs-sodvers = p_vrsion.
        ls_logs-table = '/PSYNG/FUNCTTRAN'.
        ls_logs-field = 'TYPE'.
        ls_logs-funid = <fs_ft>-functionid.
        ls_logs-tcode = <fs_ft>-tcode.
        ls_logs-old_val = ''.
        ls_logs-new_val = 'F'.
        APPEND ls_logs TO lt_logs.
        CLEAR ls_logs.
      "END OF CHANGE

      ELSEIF <fs_ft>-tcode                                      "Placeholder
                   CP /psyng/sw_cl_constants=>placeholder_tcode_prefix.
        <fs_ft>-type = 'P'.

        ls_logs-sodvers = p_vrsion.
        ls_logs-table = '/PSYNG/FUNCTTRAN'.
        ls_logs-field = 'TYPE'.
        ls_logs-funid = <fs_ft>-functionid.
        ls_logs-tcode = <fs_ft>-tcode.
        ls_logs-old_val = ''.
        ls_logs-new_val = 'P'.
        APPEND ls_logs TO lt_logs.
        CLEAR ls_logs.

      ELSE.                                                      "Tcode
        <fs_ft>-type = 'T'.

        ls_logs-sodvers = p_vrsion.
        ls_logs-table = '/PSYNG/FUNCTTRAN'.
        ls_logs-field = 'TYPE'.
        ls_logs-funid = <fs_ft>-functionid.
        ls_logs-tcode = <fs_ft>-tcode.
        ls_logs-old_val = ''.
        ls_logs-new_val = 'T'.
        APPEND ls_logs TO lt_logs.
        CLEAR ls_logs.

      ENDIF.
      DESCRIBE TABLE lt_logs LINES l_count.
    ENDIF.

*-- checking the lenght of FIORI ID i.e. it is less then 13 or not.
*-- If less then 13, update the value of Tcode in both tables else do nothing.
    CLEAR : lv_fioriid_len,lv_init_fid.
    lv_fioriid_len = strlen( <fs_ft>-fioriid ).

    IF lv_fioriid_len < 13 AND <fs_ft>-type = 'F'.

      lv_init_fid = <fs_ft>-tcode.

      CLEAR lv_new_fidtcd.
      CONCATENATE '/PSYNG/-' <fs_ft>-fioriid INTO lv_new_fidtcd.
      IF lv_init_fid <> lv_new_fidtcd.
        ls_logs-sodvers = p_vrsion.
        ls_logs-table = '/PSYNG/FUNCTTRAN'.
        ls_logs-field = 'TYPE'.
        ls_logs-funid = <fs_ft>-functionid.
        ls_logs-field = 'FIORIID'.
        ls_logs-tcode = lv_init_fid.
        ls_logs-old_val = lv_init_fid.
        ls_logs-new_val = lv_new_fidtcd.
        APPEND ls_logs TO lt_logs.
        CLEAR ls_logs.

        CLEAR lv_flag.
        LOOP AT lt_faobj2 ASSIGNING <fs_faobj2> WHERE
                                    vrsio = p_vrsion AND
                                    funid = <fs_ft>-functionid AND
                                    tcode = <fs_ft>-tcode.

          lv_flag = 'X'.

          <fs_faobj2>-tcode = lv_new_fidtcd.
          IF p_test IS INITIAL.
            UPDATE /psyng/faobj2
            SET tcode = <fs_faobj2>-tcode
            WHERE  vrsio = <fs_faobj2>-vrsio AND
                   funid = <fs_faobj2>-funid AND
                   tcode = lv_init_fid.


            IF sy-subrc = 0.
              l_faobj2_count = l_faobj2_count + 1.
            ENDIF.
          ENDIF.
        ENDLOOP.

        <fs_ft>-tcode = lv_new_fidtcd.

        IF p_test IS INITIAL.
          UPDATE /psyng/functtran
            SET tcode = <fs_ft>-tcode
            WHERE  vrsio = <fs_ft>-vrsio AND
                   functionid = <fs_ft>-functionid AND
                   fioriid = <fs_ft>-fioriid.
          IF sy-subrc = 0.
            l_functtran_count = l_functtran_count + 1.
          ENDIF.
        ENDIF.

        IF lv_flag EQ 'X'.
          ls_logs-sodvers = p_vrsion.
          ls_logs-table = '/PSYNG/FAOBJ2'.
          ls_logs-field = 'TYPE'.
          ls_logs-funid = <fs_ft>-functionid.
          ls_logs-field = 'FIORIID'.
          ls_logs-tcode = lv_init_fid.
          ls_logs-old_val = lv_init_fid.
          ls_logs-new_val = lv_new_fidtcd.
          APPEND ls_logs TO lt_logs.
          CLEAR ls_logs.
        ENDIF.

      ENDIF.
    ENDIF.
    CLEAR lv_flag.
  ENDLOOP.

  "Total count is for records to be update in /psyng/functtran table
  l_total_count = l_count + l_functtran_count.


  IF <fs_ft> IS ASSIGNED.
    UNASSIGN <fs_ft>.
  ENDIF.


  IF <fs_faobj2> IS ASSIGNED.
    UNASSIGN <fs_faobj2>.
  ENDIF.


ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  UPDATE_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_FUNCTTRAN  text
*      -->P_GT_FAOBJ2  text
*----------------------------------------------------------------------*
FORM update_table  USING    lt_functtran       TYPE tt_functtran
                            lt_faobj2          TYPE tt_faobj2
                            l_total_count      TYPE n
                            l_count            TYPE n
                            l_functtran_count  TYPE n
                            l_faobj2_count     TYPE n .


  IF l_count IS NOT INITIAL.
    UPDATE /psyng/functtran FROM TABLE lt_functtran.
    IF sy-subrc = 0.
*--Message -- Table: /psyng/functtran updated with entries: &
      MESSAGE : s211 WITH l_total_count  .
      LEAVE LIST-PROCESSING.
    ELSE.
*--MESSAGE -- 'Table /psyng/functtran not updated correctly'
      MESSAGE : e212.
      LEAVE LIST-PROCESSING.
    ENDIF.

  "HBHALLA BOC (27-12-23)
  ELSEIF l_functtran_count IS NOT INITIAL
       OR l_faobj2_count IS NOT INITIAL.
*--MESSAGE -- /psyng/functtran and /psyng/faobj2 updated with & and & respectively.
      MESSAGE : s213 WITH l_total_count l_faobj2_count.
      LEAVE LIST-PROCESSING.

  ELSE.
    MESSAGE : 'Nothing to update.'(002) TYPE 'S'.
    LEAVE LIST-PROCESSING.
  ENDIF.
  "END OF CHANGE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'PF_STATUS_100'.
  SET TITLEBAR 'TITLE_100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ALV  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv OUTPUT.
  DATA : ls_layout TYPE lvc_s_layo.

  PERFORM create_fieldcat CHANGING gt_fieldcat.

*Layout
  ls_layout-zebra = 'X'.
  ls_layout-cwidth_opt = 'X'.

  IF g_alv_grid IS INITIAL.

    PERFORM create_objects CHANGING g_cust_cont g_alv_grid.

    CALL METHOD g_alv_grid->set_table_for_first_display
      EXPORTING
        is_layout                     = ls_layout
      CHANGING
        it_outtab                     = gt_logs
        it_fieldcatalog               = gt_fieldcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSEIF sy-subrc EQ 0.
      MESSAGE : 'Report executed in Test Mode'(013) TYPE 'S'.
    ENDIF.


  ENDIF.


ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  CREATE_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM create_fieldcat  CHANGING gt_fieldcat TYPE lvc_t_fcat.

  DATA : ls_fieldcatalog TYPE lvc_s_fcat.
  CLEAR: gt_fieldcat[].

  CLEAR  ls_fieldcatalog.
  ls_fieldcatalog-fieldname   = 'SODVERS'.
  ls_fieldcatalog-scrtext_l   = text-003.
  APPEND ls_fieldcatalog TO gt_fieldcat.

  CLEAR  ls_fieldcatalog.
  ls_fieldcatalog-fieldname   = 'TABLE'.
  ls_fieldcatalog-scrtext_l   = text-004.
  APPEND ls_fieldcatalog TO gt_fieldcat.

  CLEAR  ls_fieldcatalog.
  ls_fieldcatalog-fieldname   = 'FUNID'.
  ls_fieldcatalog-scrtext_l   = text-005.
  APPEND ls_fieldcatalog TO gt_fieldcat.

  CLEAR  ls_fieldcatalog.
  ls_fieldcatalog-fieldname   = 'TCODE'.
  ls_fieldcatalog-scrtext_m   = text-006.
  APPEND ls_fieldcatalog TO gt_fieldcat.

  CLEAR  ls_fieldcatalog.
  ls_fieldcatalog-fieldname   = 'FIELD'.
  ls_fieldcatalog-scrtext_m   = text-007.
  APPEND ls_fieldcatalog TO gt_fieldcat.

  CLEAR  ls_fieldcatalog.
  ls_fieldcatalog-fieldname   = 'OLD_VAL'.
  ls_fieldcatalog-scrtext_m   = text-008.
  APPEND ls_fieldcatalog TO gt_fieldcat.

  CLEAR  ls_fieldcatalog.
  ls_fieldcatalog-fieldname   = 'NEW_VAL'.
  ls_fieldcatalog-scrtext_m   = text-009.
  APPEND ls_fieldcatalog TO gt_fieldcat.
  CLEAR  ls_fieldcatalog.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_OBJECTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_CUST_CONT  text
*      <--P_G_ALV_GRID  text
*----------------------------------------------------------------------*
FORM create_objects
              CHANGING g_cust_cont TYPE REF TO cl_gui_custom_container
                       g_alv_grid TYPE REF TO cl_gui_alv_grid.

  CREATE OBJECT g_cust_cont
    EXPORTING
      container_name = 'CUST_CONT'.

  CREATE OBJECT g_alv_grid
    EXPORTING
      i_parent = g_cust_cont.

ENDFORM.
