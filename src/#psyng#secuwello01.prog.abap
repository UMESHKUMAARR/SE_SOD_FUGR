*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECUWELLO01
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
*   INCLUDE /PSYNG/SECUWELLO01                                         *
*----------------------------------------------------------------------*
* OUTPUT MODULE FOR TABLECONTROL 'JOBTXN':
* COPY DDIC-TABLE TO ITAB
MODULE jobtxn_init OUTPUT.
  exelog sy-repid 'Tab Position'.
  PERFORM toggle_display_change.
  DESCRIBE TABLE g_jobtxn_itab LINES jobtxn-lines.
  DESCRIBE TABLE conflict2 LINES jobconflict-lines.
  CLEAR /psyng/user.
ENDMODULE.




MODULE yx_sectab_active_tab_set OUTPUT.
*Dashboard Tab configurations.
  PERFORM config_dashboard.

  SET TITLEBAR '100' WITH g_sod_vrsio g_sod_vrsio_desc.
  yx_sectab-activetab = g_yx_sectab-pressed_tab.
  CASE g_yx_sectab-pressed_tab.
*   Home
    WHEN c_yx_sectab-tab1.
      g_yx_sectab-subscreen = '0101'.

      gt_func-fcode = 'FS'.
      APPEND gt_func.
      SET PF-STATUS 'NOEDIT' EXCLUDING gt_func.

*   Conflict repository
    WHEN c_yx_sectab-tab2.
      g_yx_sectab-subscreen = '0102'.

      IF gf_dispchg = gc_display.
        gt_func-fcode = 'SAVE'.
        APPEND gt_func.
        gt_func-fcode = 'CREATE'.
        APPEND gt_func.
        gt_func-fcode = 'COPY'.
        APPEND gt_func.
        gt_func-fcode = 'DELETE'.
        APPEND gt_func.
        gt_func-fcode = 'IMPORT'.
        APPEND gt_func.
        gt_func-fcode = 'TRANSPORT'.
        APPEND gt_func.
        gt_func-fcode = 'ACTIVATE'.
        APPEND gt_func.
        gt_func-fcode = 'DEACTIVATE'.
        APPEND gt_func.
        gt_func-fcode = 'UPLD'.
        APPEND gt_func.
        gt_func-fcode = 'EDIT'.
        APPEND gt_func.
        gt_func-fcode = 'FROMMENU'.
        APPEND gt_func.
        gt_func-fcode = 'ADDATTACH'.
        APPEND gt_func.

        CASE g_sodfun-pressed_tab.
          WHEN c_sodfun-tab1  .
            delete gt_func where fcode = 'COPY'.

            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'CADET'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'LTEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.

          WHEN c_sodfun-tab2  .
             delete gt_func where fcode = 'COPY'.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'CADET'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'LTEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.

            SELECT * FROM /psyng/swinvisbl INTO TABLE ivsble.
            LOOP AT ivsble.
              CASE ivsble-swprogram.
                WHEN 'MONI'.
                  gt_func-fcode = 'QCUSER'.
                  APPEND gt_func.
              ENDCASE.
            ENDLOOP.

          WHEN c_sodfun-tab4  .
            CASE g_mitcon-pressed_tab.
              WHEN c_mitcon-tab1  .
                gt_func-fcode = 'QCUSER'.
                APPEND gt_func.
                gt_func-fcode = 'DWLD'.
                APPEND gt_func.
                gt_func-fcode = 'SORTA'.
                APPEND gt_func.
                gt_func-fcode = 'SORTD'.
                APPEND gt_func.
                gt_func-fcode = 'SEARCH'.
                APPEND gt_func.
                gt_func-fcode = 'FINDNEXT'.
                APPEND gt_func.
                se_config_param 'MIT_ATTACH_URL' g_value.
                IF g_value IS INITIAL.
                  gt_func-fcode = 'ATTACH'.
                  APPEND gt_func.
                ENDIF.
                gt_func-fcode = 'LTEXT'.
                APPEND gt_func.
                gt_func-fcode = 'SYSFLTR'.
                APPEND gt_func.
                gt_func-fcode = 'CURR_VER'.
                APPEND gt_func.
                gt_func-fcode = 'ALL_VER'.
                APPEND gt_func.
                gt_func-fcode = 'SEL_ALL'.
                APPEND gt_func.
                gt_func-fcode = 'DSEL_ALL'.
                APPEND gt_func.
                gt_func-fcode = 'MIT_REPORT'.
                APPEND gt_func.

              WHEN c_mitcon-tab7  .
                gt_func-fcode = 'DISPCHG'.
                APPEND gt_func.
                gt_func-fcode = 'FS'.
                APPEND gt_func.
                gt_func-fcode = 'CHANGES'.
                APPEND gt_func.
                gt_func-fcode = 'QCUSER'.
                APPEND gt_func.
                gt_func-fcode = 'UPLD'.
                APPEND gt_func.
                gt_func-fcode = 'DWLD'.
                APPEND gt_func.
                gt_func-fcode = 'UPDOWN'.
                APPEND gt_func.
                gt_func-fcode = 'PLIST'.
                APPEND gt_func.
                gt_func-fcode = 'CADET'.
                APPEND gt_func.
                gt_func-fcode = 'EAOBJ'.
                APPEND gt_func.
                gt_func-fcode = 'EDIT'.
                APPEND gt_func.
                gt_func-fcode = 'SORTA'.
                APPEND gt_func.
                gt_func-fcode = 'SORTD'.
                APPEND gt_func.
                gt_func-fcode = 'FROMMENU'.
                APPEND gt_func.
                gt_func-fcode = 'SEARCH'.
                APPEND gt_func.
                gt_func-fcode = 'FINDNEXT'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'LTEXT'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACHMENT'.
                APPEND gt_func.
                gt_func-fcode = 'ADDATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'CURR_VER'.
                APPEND gt_func.
                gt_func-fcode = 'ALL_VER'.
                APPEND gt_func.
                gt_func-fcode = 'SEL_ALL'.
                APPEND gt_func.
                gt_func-fcode = 'DSEL_ALL'.
                APPEND gt_func.

              WHEN OTHERS.
                gt_func-fcode = 'AUDIT'.
                APPEND gt_func.
*                gt_func-fcode = 'UPDOWN'.
*                APPEND gt_func.
                gt_func-fcode = 'DWLD'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'LTEXT'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACHMENT'.
                APPEND gt_func.
                gt_func-fcode = 'ADDATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'MIT_REPORT'.
                APPEND gt_func.

            ENDCASE.

            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'CADET'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'SYSFLTR'.
            APPEND gt_func.

          WHEN c_sodfun-tab5  .
*            gt_func-fcode = 'CHANGES'.
*            APPEND gt_func.
            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'UPLD'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'QCUSER'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.

          WHEN c_sodfun-tab6  .
*            gt_func-fcode = 'CHANGES'.
*            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'QCUSER'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'LTEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.

          WHEN c_sodfun-tab7 OR c_sodfun-tab8  .
*            gt_func-fcode = 'CHANGES'.
*            APPEND gt_func.
            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'QCUSER'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'SYSFLTR'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.
        ENDCASE.
      ELSE.
        CASE g_sodfun-pressed_tab .
          WHEN c_sodfun-tab1  .
            gt_func-fcode = 'ACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'DEACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'AUDIT'.
            APPEND gt_func.
            gt_func-fcode = 'UPLD'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'CADET'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'EDIT'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'LTEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.

          WHEN c_sodfun-tab2  .
            IF /psyng/conflict-inactive IS INITIAL.
              gt_func-fcode = 'ACTIVATE'.
              APPEND gt_func.
            ELSE.
              gt_func-fcode = 'DEACTIVATE'.
              APPEND gt_func.
            ENDIF.

            gt_func-fcode = 'UPLD'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'CADET'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'EDIT'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'FROMMENU'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'LTEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.

          WHEN c_sodfun-tab4  .
            CASE g_mitcon-pressed_tab .
              WHEN c_mitcon-tab1  .
                gt_func-fcode = 'QCUSER'.
                APPEND gt_func.
                gt_func-fcode = 'UPLD'.
                APPEND gt_func.
                gt_func-fcode = 'DWLD'.
                APPEND gt_func.
                gt_func-fcode = 'EDIT'.
                APPEND gt_func.
                gt_func-fcode = 'SORTA'.
                APPEND gt_func.
                gt_func-fcode = 'SORTD'.
                APPEND gt_func.
                gt_func-fcode = 'SEARCH'.
                APPEND gt_func.
                gt_func-fcode = 'FINDNEXT'.
                APPEND gt_func.
                se_config_param 'MIT_ATTACH_URL' g_value.
                IF g_value IS INITIAL.
                  gt_func-fcode = 'ATTACH'.
                  APPEND gt_func.
                ENDIF.
                gt_func-fcode = 'CURR_VER'.
                APPEND gt_func.
                gt_func-fcode = 'ALL_VER'.
                APPEND gt_func.
                gt_func-fcode = 'SEL_ALL'.
                APPEND gt_func.
                gt_func-fcode = 'DSEL_ALL'.
                APPEND gt_func.
                gt_func-fcode = 'COPY'.
                APPEND gt_func.
                gt_func-fcode = 'MIT_REPORT'.
                APPEND gt_func.
              WHEN c_mitcon-tab7  .
                gt_func-fcode = 'CREATE'.
                APPEND gt_func.
                gt_func-fcode = 'COPY'.
                APPEND gt_func.
                gt_func-fcode = 'DELETE'.
                APPEND gt_func.
                gt_func-fcode = 'TRANSPORT'.
                APPEND gt_func.
                gt_func-fcode = 'DEACTIVATE'.
                APPEND gt_func.
                gt_func-fcode = 'DISPCHG'.
                APPEND gt_func.
                gt_func-fcode = 'FS'.
                APPEND gt_func.
                gt_func-fcode = 'CHANGES'.
                APPEND gt_func.
                gt_func-fcode = 'QCUSER'.
                APPEND gt_func.
                gt_func-fcode = 'UPLD'.
                APPEND gt_func.
                gt_func-fcode = 'DWLD'.
                APPEND gt_func.
                gt_func-fcode = 'UPDOWN'.
                APPEND gt_func.
                gt_func-fcode = 'PLIST'.
                APPEND gt_func.
                gt_func-fcode = 'CADET'.
                APPEND gt_func.
                gt_func-fcode = 'EAOBJ'.
                APPEND gt_func.
                gt_func-fcode = 'EDIT'.
                APPEND gt_func.
                gt_func-fcode = 'SORTA'.
                APPEND gt_func.
                gt_func-fcode = 'SORTD'.
                APPEND gt_func.
                gt_func-fcode = 'FROMMENU'.
                APPEND gt_func.
                gt_func-fcode = 'SEARCH'.
                APPEND gt_func.
                gt_func-fcode = 'FINDNEXT'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'LTEXT'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACHMENT'.
                APPEND gt_func.
                gt_func-fcode = 'ADDATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'CURR_VER'.
                APPEND gt_func.
                gt_func-fcode = 'ALL_VER'.
                APPEND gt_func.
                gt_func-fcode = 'SEL_ALL'.
                APPEND gt_func.
                gt_func-fcode = 'DSEL_ALL'.
                APPEND gt_func.


              WHEN OTHERS.
                gt_func-fcode = 'SAVE'.
                APPEND gt_func.
                gt_func-fcode = 'UPLD'.
                APPEND gt_func.
                gt_func-fcode = 'DWLD'.
                APPEND gt_func.
                gt_func-fcode = 'ACTIVATE'.
                APPEND gt_func.
                gt_func-fcode = 'DEACTIVATE'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'LTEXT'.
                APPEND gt_func.
                gt_func-fcode = 'ATTACHMENT'.
                APPEND gt_func.
                gt_func-fcode = 'ADDATTACH'.
                APPEND gt_func.
                gt_func-fcode = 'MIT_REPORT'.
                APPEND gt_func.

            ENDCASE.


            DATA l_inactive.
            SELECT SINGLE inactive FROM /psyng/mchdr INTO l_inactive
            WHERE contid = /psyng/mchdr-contid.
            IF l_inactive IS INITIAL.
              gt_func-fcode = 'ACTIVATE'.
              APPEND gt_func.
            ELSE.
              gt_func-fcode = 'DEACTIVATE'.
              APPEND gt_func.
            ENDIF.


*            gt_func-fcode = 'COPY'.
*            APPEND gt_func.
            gt_func-fcode = 'IMPORT'.
            APPEND gt_func.
*            gt_func-fcode = 'ACTIVATE'.
*            APPEND gt_func.
*            gt_func-fcode = 'DEACTIVATE'.
*            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'CADET'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'FROMMENU'.
            APPEND gt_func.
            gt_func-fcode = 'LTEXT'.
            APPEND gt_func.
            gt_func-fcode = 'SYSFLTR'.
            APPEND gt_func.
*            gt_func-fcode = 'MIT_REPORT'.
*            APPEND gt_func.


          WHEN c_sodfun-tab5  .
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'COPY'.
            APPEND gt_func.
            gt_func-fcode = 'CREATE'.
            APPEND gt_func.
            gt_func-fcode = 'DELETE'.
            APPEND gt_func.
*            gt_func-fcode = 'CHANGES'.
*            APPEND gt_func.
            gt_func-fcode = 'ACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'DEACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'UPLD'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
*            APPEND gt_func.
*            gt_func-fcode = 'UPDOWN'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'QCUSER'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'EDIT'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'FROMMENU'.
            APPEND gt_func.
*            gt_func-fcode = 'SEARCH'.
*            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'UPLD'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.


          WHEN c_sodfun-tab6  .
            gt_func-fcode = 'COPY'.
            APPEND gt_func.
            gt_func-fcode = 'IMPORT'.
            APPEND gt_func.
*            gt_func-fcode = 'CHANGES'.
*            APPEND gt_func.
            gt_func-fcode = 'ACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'DEACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'UPLD'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
*            gt_func-fcode = 'UPDOWN'.
*            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'QCUSER'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'EDIT'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'FROMMENU'.
            APPEND gt_func.
            gt_func-fcode = 'SEARCH'.
            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'LTEXT'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.

          WHEN c_sodfun-tab7 OR c_sodfun-tab8  .
            gt_func-fcode = 'COPY'.
            APPEND gt_func.
            gt_func-fcode = 'IMPORT'.
            APPEND gt_func.
            gt_func-fcode = 'CREATE'.
            APPEND gt_func.
            gt_func-fcode = 'DELETE'.
            APPEND gt_func.
*            gt_func-fcode = 'CHANGES'.
*            APPEND gt_func.
            gt_func-fcode = 'ACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'DEACTIVATE'.
            APPEND gt_func.
            gt_func-fcode = 'UPLD'.
            APPEND gt_func.
            gt_func-fcode = 'DWLD'.
            APPEND gt_func.
*            gt_func-fcode = 'UPDOWN'.
*            APPEND gt_func.
            gt_func-fcode = 'PLIST'.
            APPEND gt_func.
            gt_func-fcode = 'EAOBJ'.
            APPEND gt_func.
            gt_func-fcode = 'QCUSER'.
            APPEND gt_func.
            gt_func-fcode = 'LUKUP'.
            APPEND gt_func.
            gt_func-fcode = 'LMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'DMTRX'.
            APPEND gt_func.
            gt_func-fcode = 'SHTCOD'.
            APPEND gt_func.
            gt_func-fcode = 'EDIT'.
            APPEND gt_func.
            gt_func-fcode = 'SORTA'.
            APPEND gt_func.
            gt_func-fcode = 'SORTD'.
            APPEND gt_func.
            gt_func-fcode = 'FROMMENU'.
            APPEND gt_func.
*            gt_func-fcode = 'SEARCH'.
*            APPEND gt_func.
            gt_func-fcode = 'FINDNEXT'.
            APPEND gt_func.

            gt_func-fcode = 'ATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'SYSFLTR'.
            APPEND gt_func.
            gt_func-fcode = 'ATTACHMENT'.
            APPEND gt_func.
            gt_func-fcode = 'ADDATTACH'.
            APPEND gt_func.
            gt_func-fcode = 'CURR_VER'.
            APPEND gt_func.
            gt_func-fcode = 'ALL_VER'.
            APPEND gt_func.
            gt_func-fcode = 'SEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'DSEL_ALL'.
            APPEND gt_func.
            gt_func-fcode = 'MIT_REPORT'.
            APPEND gt_func.
        ENDCASE.
      ENDIF.
*--If no subtabs are shown, show a status without buttons
      IF  (
        g_yx_sectab-pressed_tab = c_yx_sectab-tab2 AND
        g_sodfun-pressed_tab   IS INITIAL )
     OR
         ( g_yx_sectab-pressed_tab = c_yx_sectab-tab2 AND
           g_sodfun-pressed_tab    = c_sodfun-tab4 AND
           g_mitcon-pressed_tab    IS INITIAL ).
        SET PF-STATUS '100'.
      ELSE.
        SET PF-STATUS 'CONFREP' EXCLUDING gt_func.
      ENDIF.

*   Roles
    WHEN c_yx_sectab-tab3.
      g_yx_sectab-subscreen = '0103'.

      IF gf_dispchg = gc_display.
        IF g_roles-pressed_tab = c_roles-tab1.
          gt_func-fcode = 'SYNCH'.
          APPEND gt_func.
          gt_func-fcode = 'SODCON'.
          APPEND gt_func.
          gt_func-fcode = 'CONDISP'.
          APPEND gt_func.
        ELSE.
          gt_func-fcode = 'IMPORT'.
          APPEND gt_func.
          gt_func-fcode = 'D_PFCG'.
          APPEND gt_func.
        ENDIF.

        gt_func-fcode = 'DISPLAY'.
        APPEND gt_func.
        gt_func-fcode = 'GROL'.
        APPEND gt_func.
        gt_func-fcode = 'AROL'.
        APPEND gt_func.
        gt_func-fcode = 'SAVE'.
        APPEND gt_func.
        gt_func-fcode = 'CREATE'.
        APPEND gt_func.
        gt_func-fcode = 'COPY'.
        APPEND gt_func.
        gt_func-fcode = 'DELETE'.
        APPEND gt_func.
        gt_func-fcode = 'SYNCPOS'.
        APPEND gt_func.
        gt_func-fcode = 'REFRESH'.
        APPEND gt_func.
      ELSE.
        IF g_roles-pressed_tab = c_roles-tab1.
          gt_func-fcode = 'REFRESH'.
          APPEND gt_func.
          gt_func-fcode = 'SYNCH'.
          APPEND gt_func.
          gt_func-fcode = 'DISPLAY'.
          APPEND gt_func.
          gt_func-fcode = 'CONDISP'.
          APPEND gt_func.

*         Hide Generate & Adjust buttons if user has no access
          AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
                   ID 'ACTVT' FIELD '64'
                   ID 'Y&SW_ROLID' FIELD /psyng/roletrans-roleid.
          IF sy-subrc <> 0.
            gt_func-fcode = 'GROL'.
            APPEND gt_func.
            gt_func-fcode = 'AROL'.
            APPEND gt_func.
          ENDIF.
        ELSE.
          gt_func-fcode = 'IMPORT'.
          APPEND gt_func.
          gt_func-fcode = 'CREATE'.
          APPEND gt_func.
          gt_func-fcode = 'COPY'.
          APPEND gt_func.
          gt_func-fcode = 'SYNCPOS'.
          APPEND gt_func.
          gt_func-fcode = 'D_PFCG'.
          APPEND gt_func.
          gt_func-fcode = 'DISPLAY'.
          APPEND gt_func.
          gt_func-fcode = 'GROL'.
          APPEND gt_func.
          gt_func-fcode = 'AROL'.
          APPEND gt_func.
        ENDIF.
      ENDIF.

      gt_func-fcode = 'FIND'.
      APPEND gt_func.
      gt_func-fcode = 'UPDOWN'.
      APPEND gt_func.
      gt_func-fcode = 'TOG_PFCG'.
      APPEND gt_func.
      gt_func-fcode = 'UPDT'.
      APPEND gt_func.
      gt_func-fcode = 'DELNODE'.
      APPEND gt_func.
      gt_func-fcode = 'DELALL'.
      APPEND gt_func.
      SET PF-STATUS '100' EXCLUDING gt_func.

*   Positions
    WHEN c_yx_sectab-tab4.
      g_yx_sectab-subscreen = '0104'.

      IF gf_dispchg = gc_display.
        gt_func-fcode = 'SAVE'.
        APPEND gt_func.
        gt_func-fcode = 'CREATE'.
        APPEND gt_func.
        gt_func-fcode = 'DELETE'.
        APPEND gt_func.
        gt_func-fcode = 'UPDT'.
        APPEND gt_func.
        gt_func-fcode = 'DELNODE'.
        APPEND gt_func.
        gt_func-fcode = 'DELALL'.
        APPEND gt_func.
      ENDIF.

      gt_func-fcode = 'COPY'.
      APPEND gt_func.
      gt_func-fcode = 'IMPORT'.
      APPEND gt_func.
      gt_func-fcode = 'SYNCPOS'.
      APPEND gt_func.
      gt_func-fcode = 'REFRESH'.
      APPEND gt_func.
      gt_func-fcode = 'D_PFCG'.
      APPEND gt_func.
      gt_func-fcode = 'GROL'.
      APPEND gt_func.
      gt_func-fcode = 'AROL'.
      APPEND gt_func.
      SET PF-STATUS '100' EXCLUDING gt_func.

*   User Assignment
    WHEN c_yx_sectab-tab5.
      g_yx_sectab-subscreen = '0105'.

      IF gf_dispchg = gc_display.
        gt_func-fcode = 'SAVE'.
        APPEND gt_func.
        gt_func-fcode = 'CREATE'.
        APPEND gt_func.
        gt_func-fcode = 'DELETE'.
        APPEND gt_func.
        gt_func-fcode = 'UPDT'.
        APPEND gt_func.
        gt_func-fcode = 'DELNODE'.
        APPEND gt_func.
        gt_func-fcode = 'DELALL'.
        APPEND gt_func.
      ENDIF.

      gt_func-fcode = 'COPY'.
      APPEND gt_func.
      gt_func-fcode = 'IMPORT'.
      APPEND gt_func.
      gt_func-fcode = 'SYNCPOS'.
      APPEND gt_func.
      gt_func-fcode = 'REFRESH'.
      APPEND gt_func.
      gt_func-fcode = 'UPDOWN'.
      APPEND gt_func.
      gt_func-fcode = 'TOG_PFCG'.
      APPEND gt_func.
      gt_func-fcode = 'D_PFCG'.
      APPEND gt_func.
      gt_func-fcode = 'DISPLAY'.
      APPEND gt_func.
      gt_func-fcode = 'GROL'.
      APPEND gt_func.
      gt_func-fcode = 'AROL'.
      APPEND gt_func.
      SET PF-STATUS '100' EXCLUDING gt_func.

*   Monitoring
    WHEN c_yx_sectab-tab6.
      g_yx_sectab-subscreen = '0106'.
      SET PF-STATUS 'NOEDIT' EXCLUDING gt_func.

*   Misc.
    WHEN c_yx_sectab-tab7.
      g_yx_sectab-subscreen = '0107'.
      SET PF-STATUS 'NOEDIT' EXCLUDING gt_func.
*  Dashboard.
    WHEN c_yx_sectab-tab8.
      g_yx_sectab-subscreen = '0109'.
      gt_func-fcode = 'FS'.
      APPEND gt_func.
      SET PF-STATUS 'NOEDIT' EXCLUDING gt_func.

    WHEN OTHERS.
      CLEAR populated.
  ENDCASE.
* Deactivate dashboard.
  PERFORM deactivate_dashboard.
  REFRESH gt_func.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  INIT0202  OUTPUT
*&---------------------------------------------------------------------*
*       Initialization for screen 202
*----------------------------------------------------------------------*
MODULE init0202 OUTPUT.
  exelog sy-repid 'Tab Conflicts'.
  CLEAR:gv_process.
  DATA : l_owners TYPE i,
         l_pmits  TYPE i.
**********************************************************
**rkanaka added on 17-04-2010
**displaying subarea (processids (02c,p2p))adjacent to process area text

  SELECT SINGLE subarea FROM /psyng/bus_proce INTO gv_process
  WHERE subarea = /psyng/conflict-subarea.
**********************************************************
  LOOP AT SCREEN.
*--Displaying correct icon for Conflict Owner Button
    CASE screen-name.

      WHEN 'BTN_OWNER'.
        CLEAR l_owners.
        IF NOT /psyng/confdet-conid IS INITIAL.
          SELECT COUNT(*) FROM /psyng/conowner       "#EC CI_SEL_NESTED
           INTO l_owners
          WHERE vrsio = g_sod_vrsio AND
                  conid = /psyng/confdet-conid.
          IF sy-subrc <> 0.
            CLEAR l_owners.
          ENDIF.
        ENDIF.
        IF l_owners > 0.
*--Owners already defined
          CALL FUNCTION 'ICON_CREATE'
            EXPORTING
              name                  = 'ICON_MASTER_DATA_ACT'
              text                  = 'Owners'(c01)
              info                  = 'Display Conflict Owners'(c02)
            IMPORTING
              result                = btn_owner
            EXCEPTIONS
              icon_not_found        = 1
              outputfield_too_short = 2
              OTHERS                = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ELSE.
*--No Owners defined yet
          CALL FUNCTION 'ICON_CREATE'
            EXPORTING
              name                  = 'ICON_MASTER_DATA_INA'
              text                  = 'Owners'(c01)
              info                  =
                                      'No Conflict Owners defined'(c04)
            IMPORTING
              result                = btn_owner
            EXCEPTIONS
              icon_not_found        = 1
              outputfield_too_short = 2
              OTHERS                = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

        ENDIF.

      WHEN 'BTN_PMIT'.
        CLEAR l_pmits.
        IF NOT /psyng/confdet-conid IS INITIAL.
          SELECT COUNT(*) FROM /psyng/conpmit        "#EC CI_SEL_NESTED
           INTO l_pmits
          WHERE vrsio = g_sod_vrsio AND
                  conid = /psyng/confdet-conid.
          IF sy-subrc <> 0.
            CLEAR l_pmits.
          ENDIF.
        ENDIF.
        IF l_pmits > 0.
*--Owners already defined
          CALL FUNCTION 'ICON_CREATE'
            EXPORTING
              name                  = 'ICON_MASTER_DATA_ACT'
*             text                  = 'Mitigations'(c10)
              info                  = 'Display Conflict Mitigations'(c09)
            IMPORTING
              result                = btn_pmit
            EXCEPTIONS
              icon_not_found        = 1
              outputfield_too_short = 2
              OTHERS                = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ELSE.
*--No Owners defined yet
          CALL FUNCTION 'ICON_CREATE'
            EXPORTING
              name                  = 'ICON_MASTER_DATA_INA'
*             text                  = 'Mitigations'(c10)
              info                  =
                                      'No Prop. Mitigations defined'(c11)
            IMPORTING
              result                = btn_pmit
            EXCEPTIONS
              icon_not_found        = 1
              outputfield_too_short = 2
              OTHERS                = 3.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

        ENDIF.



    ENDCASE.
  ENDLOOP.

  CHECK gf_dispchg = gc_change AND NOT /psyng/conflict IS INITIAL.

  LOOP AT SCREEN.
    IF /psyng/conflict-inactive = 'X'.
      CASE screen-name.
        WHEN 'ACTIVATE'.
          CHECK screen-input = 0.
          screen-input = 1.
        WHEN 'DEACTIVATE'.
          CHECK screen-input = 1.
          screen-input = 0.
      ENDCASE.
    ELSE.
      CASE screen-name.
        WHEN 'ACTIVATE'.
          CHECK screen-input = 1.
          screen-input = 0.
        WHEN 'DEACTIVATE'.
          CHECK screen-input = 0.
          screen-input = 1.
      ENDCASE.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " INIT0202  OUTPUT



*&---------------------------------------------------------------------*
*&      Module  INIT0206  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init0206 OUTPUT.
  exelog sy-repid 'Tab Functions'.

  SET PF-STATUS '200'.
  SET TITLEBAR '205'.
  IF first_mit = space.
    first_mit = 'X'.
    IF /psyng/roletrans-roleid NE space.
      IF /psyng/conflict-conid NE space.
        CONCATENATE /psyng/roletrans-roleid  /psyng/conflict-conid
        INTO usr_mit.
        REFRESH i_text.
        SELECT * FROM /psyng/texts
               WHERE textname = usr_mit
                 AND vrsio    = g_sod_vrsio
                 AND spras    = sy-langu
                 ORDER BY line.
          i_text = /psyng/texts-text.
          APPEND i_text.
        ENDSELECT.
      ENDIF.
    ENDIF.
  ENDIF.
ENDMODULE.                 " INIT0206 OUTPUT



*---------------------------------------------------------------------*
*       MODULE init_editor312 OUTPUT                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE init_editor312 OUTPUT.
  DATA: seditor_container TYPE REF TO cl_gui_custom_container.
  DATA: stext_editor TYPE REF TO cl_gui_textedit.
  DATA: g_editor_text TYPE TABLE OF char80.
  DATA: stext_reload TYPE char1.
* IF  screen_323 = 'X'.
*   CLEAR stext_editor.
* ENDIF.


  IF stext_editor IS INITIAL.

*   create control container
    CREATE OBJECT seditor_container
      EXPORTING
        container_name              = 'STEXTEDITOR'
*       repid                       = g_repid
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.


*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
    CREATE OBJECT stext_editor
      EXPORTING
        parent                     = seditor_container
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true
      EXCEPTIONS
        OTHERS                     = 1.
**    CREATE OBJECT stext_editor
**      EXPORTING
**         parent = seditor_container
**         wordwrap_to_linebreak_mode = cl_gui_textedit=>true
**      EXCEPTIONS
**          others = 1.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.

    stext_reload = 'X'.

  ENDIF.

*  IF STEXT_RELOAD = 'X'.

*   copy text
  IF g_editor_text[] IS INITIAL.
    g_editor_text[] = i_text[].
  ENDIF.

*   fill with text
  CALL METHOD stext_editor->set_text_as_r3table
    EXPORTING
      table           = g_editor_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.
  CASE g_sodfun-pressed_tab.
    WHEN c_sodfun-tab1.
      g_memory_text[] = g_editor_text[].
      EXPORT g_memory_text TO MEMORY ID c_e378.
    WHEN OTHERS.
  ENDCASE.

*   finally flush
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

  stext_reload = space.

*  ENDIF.

  IF gf_dispchg = gc_change.
    CALL METHOD stext_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>false
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.
  ELSE.
    CALL METHOD stext_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>true
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.
  ENDIF.
ENDMODULE.                 " INIT_EDITOR312  OUTPUT

*---------------------------------------------------------------------*
*       MODULE init_editor323 OUTPUT                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE init_editor323 OUTPUT.

  DATA: seditor_containe1 TYPE REF TO cl_gui_custom_container.
  DATA: stext_edito1 TYPE REF TO cl_gui_textedit.
  DATA: g_editor_tex1 TYPE TABLE OF char80.

  IF stext_reload1 = space.
    stext_reload1 = 'X'.
*   create control container
    IF stext_edito1 IS INITIAL.

      CREATE OBJECT seditor_containe1
        EXPORTING
          container_name              = 'STEXTEDITO1'
*         repid                       = g_repid
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.


*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
      CREATE OBJECT stext_edito1
        EXPORTING
          parent                     = seditor_containe1
          wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
          wordwrap_to_linebreak_mode = cl_gui_textedit=>false
        EXCEPTIONS
          OTHERS                     = 1.
**    CREATE OBJECT stext_editor
**      EXPORTING
**         parent = seditor_container
**         wordwrap_to_linebreak_mode = cl_gui_textedit=>true
**      EXCEPTIONS
**          others = 1.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.
    ENDIF.
    g_editor_tex1[] = i_text[].

*   fill with text
    CALL METHOD stext_edito1->set_text_as_r3table
      EXPORTING
        table           = g_editor_tex1
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.

*   finally flush
*    CALL METHOD cl_gui_cfw=>flush
*           EXCEPTIONS
*             OTHERS = 1.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.

    CALL METHOD stext_edito1->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>true
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.
ENDMODULE.                 " INIT_EDITOR323  OUTPUT


* Toggle display <-> change
MODULE dispchg OUTPUT.
  PERFORM toggle_display_change.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE disable_ins_del OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE disable_ins_del OUTPUT.
  LOOP AT SCREEN.
    IF gf_dispchg = gc_display.
      IF screen-group1 = '01E'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE TRANS_INIT_CRIT OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE trans_init_crit OUTPUT.
  exelog sy-repid 'Tab Critical Tcodes'.

*BOC:HBHALLA 03/07/24 (PN-5236)
* To remove filter text when switch back to screen.
  IF sy-ucomm = 'SODFUN_FC5' OR sy-ucomm = 'YX_SECTAB_FC2'.
    CLEAR g_filtertext_t.
  ENDIF.
*EOC:HBHALLA

  IF first_txn1 = space.
    first_txn1 = 'X'.

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
    SORT g_trans_itab BY tcode.
  ENDIF.
*  B8620.
  g_trans_itab-flag = space.
  MODIFY g_trans_itab TRANSPORTING flag WHERE flag = 'X'.
  CLEAR g_trans_itab.
* End.
  IF gf_dispchg = gc_display.
    sec_actvt = act_display.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
             ID 'ACTVT' FIELD sec_actvt
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
    IF sy-subrc NE 0.
      MESSAGE e108(/psyng/sw) WITH text-016.
    ENDIF.
  ENDIF.

  IF gf_dispchg = gc_change.
    sec_actvt = act_change.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
             ID 'ACTVT' FIELD sec_actvt
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
    IF sy-subrc NE 0.
      MESSAGE e108(/psyng/sw) WITH text-017.
    ENDIF.

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
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      gt_locked-type   = 'TABLEVERS'.
      gt_locked-object = '/PSYNG/CRITCODES'.
      APPEND gt_locked.
    ENDIF.
  ENDIF.

*  Display unfilter button
  LOOP AT SCREEN.
    CHECK screen-name = 'TUNFILTER'.
    IF g_filtertext_t IS INITIAL.
      screen-invisible = 1.
    ELSE.
      screen-invisible = 0.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

  PERFORM toggle_display_change.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE ROLE_INIT_CRIT OUTPUT                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE role_init_crit OUTPUT.
  exelog sy-repid 'Tab Critical Roles'.
  IF gf_dispchg = gc_display.
    sec_actvt = act_display.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
             ID 'ACTVT' FIELD sec_actvt
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
    IF sy-subrc NE 0.
      MESSAGE i108(/psyng/sw) WITH text-018.
      EXIT.
    ENDIF.
  ENDIF.

*BOC:HBHALLA 03/07/24 (PN-5236)
* To remove filter text when switch back to screen.
  IF sy-ucomm = 'SODFUN_FC7' OR sy-ucomm = 'YX_SECTAB_FC2'.
    CLEAR g_filtertext.
  ENDIF.
*EOC:HBHALLA

  IF first_role1 = space.
    REFRESH g_criroles_itab.
    first_role1 = 'X'.
    critrole-lines = 0.
    SELECT * FROM /psyng/criroles WHERE vrsio = g_sod_vrsio.
      g_criroles_itab-agr_name =  /psyng/criroles-agr_name.
      g_criroles_itab-imp     =   /psyng/criroles-imp.
      g_criroles_itab-owner = /psyng/criroles-owner.
      g_criroles_itab-flag = space.
*      g_criroles_itab-description = /psyng/criroles-description.
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
      critrole-lines = critrole-lines + 1.
    ENDSELECT.
  ENDIF.


  IF gf_dispchg = gc_change.
    sec_actvt = act_change.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
             ID 'ACTVT' FIELD sec_actvt
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
    IF sy-subrc NE 0.
      MESSAGE i108(/psyng/sw) WITH text-019.
      REFRESH g_criroles_itab.
      EXIT.
    ENDIF.

    CALL FUNCTION 'ENQUEUE_/PSYNG/TABLEVERS'
      EXPORTING
        tabname        = '/PSYNG/CRIROLES'
        vrsio          = g_sod_vrsio
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
      gf_dispchg = gc_display.
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      gt_locked-type   = 'TABLEVERS'.
      gt_locked-object = '/PSYNG/CRIROLES'.
      APPEND gt_locked.
    ENDIF.
  ENDIF.

  LOOP AT SCREEN.
    CHECK screen-name = 'UNFILTER'.
    IF g_filtertext IS INITIAL.
      screen-invisible = 1.
    ELSE.
      screen-invisible = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

  PERFORM toggle_display_change.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE prof_init_crit OUTPUT                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE prof_init_crit OUTPUT.
  exelog sy-repid 'Tab Critical Profiles'.
  IF first_prof1 = space.
    REFRESH g_criprofs_itab.
    first_prof1 = 'X'.
    critprof-lines = 0.
    SELECT * FROM /psyng/criprof WHERE vrsio = g_sod_vrsio.
      g_criprofs_itab-profn =  /psyng/criprof-profile.
      g_criprofs_itab-imp     =   /psyng/criprof-imp.
      g_criprofs_itab-flag = space.
      g_criprofs_itab-owner = /psyng/criprof-owner.
*      g_criprofs_itab-description = /psyng/criprof-description.

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
      critprof-lines = critprof-lines + 1.
    ENDSELECT.
    SORT g_criprofs_itab BY profn.
  ENDIF.

  IF gf_dispchg = gc_display.
    sec_actvt = act_display.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
             ID 'ACTVT' FIELD sec_actvt
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
    IF sy-subrc NE 0.
      MESSAGE e108(/psyng/sw) WITH text-210.
    ENDIF.
  ENDIF.

*BOC:HBHALLA 03/07/24 (PN-5236)
* To remove filter text when switch back to screen.
  IF sy-ucomm = 'SODFUN_FC8' OR sy-ucomm = 'YX_SECTAB_FC2'.
    CLEAR g_filtertext_p.
  ENDIF.
*EOC:HBHALLA

  IF gf_dispchg = gc_change.
    sec_actvt = act_change.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
             ID 'ACTVT' FIELD sec_actvt
             ID 'Y&SW_VRSIO' FIELD g_sod_vrsio.
    IF sy-subrc NE 0.
      MESSAGE e108(/psyng/sw) WITH text-025.
    ENDIF.

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
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      gt_locked-type   = 'TABLEVERS'.
      gt_locked-object = '/PSYNG/CRIPROF'.
      APPEND gt_locked.
    ENDIF.
  ENDIF.


  LOOP AT SCREEN.
    CHECK screen-name = 'PUNFILTER'.
    IF g_filtertext_p IS INITIAL.
      screen-invisible = 1.
    ELSE.
      screen-invisible = 0.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.

  PERFORM toggle_display_change.
ENDMODULE.


*MODULE empty_count OUTPUT.
*IF g_trans_wa IS INITIAL.
* g_empt_lines = g_empt_lines + 1.
*ENDIF.
*ENDMODULE.

* OUTPUT MODULE FOR TABLECONTROL 'TRANS':
* MOVE ITAB TO DYNPRO
MODULE trans_move OUTPUT.
  MOVE-CORRESPONDING g_trans_wa TO tstct.
*  PERFORM toggle_display_change.
  PERFORM display_change USING sy-dynnr.
ENDMODULE.

MODULE fiori_move OUTPUT.
  MOVE-CORRESPONDING gs_fiori_wa TO /psyng/sw_fioria.
  PERFORM display_change USING sy-dynnr.
ENDMODULE.


* OUTPUT MODULE FOR TABLECONTROL 'CRITROLE
* MOVE ITAB TO DYNPRO
MODULE critrole_move OUTPUT.
  agr_texts-agr_name = g_critrole_wa-agr_name.
  agr_texts-text     = g_critrole_wa-text.
  g_criroles_itab-imp =  g_critrole_wa-imp.
  g_criroles_itab-owner = g_critrole_wa-owner.
*  g_criroles_itab-description = g_critrole_wa-description.
*  MOVE-CORRESPONDING g_critrole_wa TO /psyng/criroles.
  PERFORM toggle_display_change.
  PERFORM display_change USING sy-dynnr.

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE critprof_move OUTPUT                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE critprof_move OUTPUT.
  g_profile   = g_critprof_wa-profn.
  usr11-profn = g_critprof_wa-profn.
  usr11-ptext = g_critprof_wa-ptext.
  g_criprofs_itab-imp =  g_critprof_wa-imp.
  g_criprofs_itab-owner =  g_critprof_wa-owner.
*  MOVE-CORRESPONDING g_critrole_wa TO /psyng/criroles.
  PERFORM toggle_display_change.
  PERFORM display_change USING sy-dynnr.
ENDMODULE.

* OUTPUT MODULE FOR TABLECONTROL 'FUNCT':
* MOVE ITAB TO DYNPRO
MODULE funct_move OUTPUT.
  /psyng/functtran-functionid = g_funct_wa-function.
  /psyng/function-description = g_funct_wa-description.

*  PERFORM toggle_display_change.
  PERFORM display_change USING sy-dynnr.


*  MOVE-CORRESPONDING G_FUNCT_WA TO /PSYNG/FUNCTTRAN.
ENDMODULE.

* OUTPUT MODULE FOR TABSTRIP 'ROLEHDR': SETS ACTIVE TAB
MODULE rolehdr_active_tab_set OUTPUT.
  rolehdr-activetab = g_rolehdr-pressed_tab.
  CASE g_rolehdr-pressed_tab.
    WHEN c_rolehdr-tab1.
      g_rolehdr-subscreen = '0312'.
    WHEN c_rolehdr-tab2.
      g_rolehdr-subscreen = '0313'.
  ENDCASE.

  PERFORM toggle_display_change.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  INIT0313  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init0313 OUTPUT.
  role_txt = 'DESC'.
ENDMODULE.                 " INIT0313  OUTPUT

* OUTPUT MODULE FOR TABLECONTROL 'ROLE_TRANS':
* COPY DDIC-TABLE TO ITAB
MODULE role_trans_init OUTPUT.
  PERFORM toggle_display_change.

  g_transroleid = /psyng/roletrans-roleid.

  IF NOT g_transroleid IS INITIAL.
    ok_code = 'ENTER'.
    PERFORM user_command_0302.
  ENDIF.

  DESCRIBE TABLE conflict LINES conflict_disp-lines.
ENDMODULE.

* OUTPUT MODULE FOR TABLECONTROL 'ROLE_TRANS':
* MOVE ITAB TO DYNPRO
MODULE role_trans_move OUTPUT.
  MOVE-CORRESPONDING g_role_trans_wa TO tstct.
  PERFORM toggle_display_change.
  PERFORM display_change USING sy-dynnr.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  SET_FIELD_CURSOR  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_field_cursor OUTPUT.
  SET CURSOR FIELD cursor_field LINE cursor_line  .
ENDMODULE.                 " SET_FIELD_CURSOR  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  PBO_100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_100 OUTPUT.
  PERFORM refresh_tree_position.
  IF g_left_tree IS INITIAL.
    CREATE OBJECT g_application.
    user = space.
    PERFORM create_and_init_trees.
  ENDIF.
ENDMODULE.                 " PBO_100  OUTPUT

* OUTPUT MODULE FOR TABLECONTROL 'JOBTXN':
* MOVE ITAB TO DYNPRO
MODULE jobtxn_move OUTPUT.
  MOVE-CORRESPONDING g_jobtxn_wa TO tstct.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  PBO_105  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_105 OUTPUT.
  PERFORM toggle_display_change.
  PERFORM refresh_tree_user.
  IF g_left_tree IS INITIAL.
    CREATE OBJECT g_application.
    user = 'X'. "#EC SAST_CI_GEN_CHECK
    PERFORM create_and_init_trees.
  ENDIF.
ENDMODULE.                 " PBO_105  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  USER_INIT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_init OUTPUT.
  exelog sy-repid 'Tab User Assignment'.
  CLEAR /psyng/position.
ENDMODULE.                 " USER_INIT  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  SODFUN_ACTIVE_TAB_SET  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE sodfun_active_tab_set OUTPUT.
*  FIRST_TIME = SPACE.
  DATA: l_noedit TYPE /psyng/swsodvers-noedit.
  IF gf_dispchg = gc_change.                    "Change mode
*  change to display mode when the current version is not editable.
*  This does not apply for mitigation tab
    IF g_sodfun-pressed_tab <> c_sodfun-tab4.
      PERFORM check_version_editable.
    ENDIF.
  ENDIF.

  sodfun-activetab = g_sodfun-pressed_tab.
  CASE g_sodfun-pressed_tab.
    WHEN c_sodfun-tab1.
      g_sodfun-subscreen = '0201'.
    WHEN c_sodfun-tab2.
      g_sodfun-subscreen = '0202'.
    WHEN c_sodfun-tab4.
      g_sodfun-subscreen = '0203'.
    WHEN c_sodfun-tab5.
      g_sodfun-subscreen = '0208'.
    WHEN c_sodfun-tab6.
      g_sodfun-subscreen = '0209'.
    WHEN c_sodfun-tab7.
      g_sodfun-subscreen = '0210'.
    WHEN c_sodfun-tab8.
      g_sodfun-subscreen = '0213'.
    WHEN OTHERS.
*--If no tabs are found to display, show an empty screen
      g_sodfun-subscreen = '8000'.
  ENDCASE.
ENDMODULE.                 " SODFUN_ACTIVE_TAB_SET  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  MITCON_ACTIVE_TAB_SET  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE mitcon_active_tab_set OUTPUT.
  mitcon-activetab = g_mitcon-pressed_tab.
  CASE g_mitcon-pressed_tab.
    WHEN c_mitcon-tab1.
      g_mitcon-subscreen = '0211'.
    WHEN c_mitcon-tab2.
      g_mitcon-subscreen = '0212'.
    WHEN c_mitcon-tab3.
      g_mitcon-subscreen = '0222'.
    WHEN c_mitcon-tab4.
      g_mitcon-subscreen = '0223'.
    WHEN c_mitcon-tab5.
      g_mitcon-subscreen = '0224'.
    WHEN c_mitcon-tab6.
      g_mitcon-subscreen = '0225'.
    WHEN c_mitcon-tab7.
      g_mitcon-subscreen = '0228'.
    WHEN OTHERS.
*--If no tabs are found to display, show an empty screen
      g_mitcon-subscreen = '8000'.
  ENDCASE.
ENDMODULE.                 " MITCON_ACTIVE_TAB_SET  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  ROLES_ACTIVE_TAB_SET  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE roles_active_tab_set OUTPUT.
  roles-activetab = g_roles-pressed_tab.
  CASE g_roles-pressed_tab.
    WHEN c_roles-tab1.
      g_roles-subscreen = '0301'.
    WHEN c_roles-tab2.
      g_roles-subscreen = '0302'.
  ENDCASE.
ENDMODULE.                 " ROLES_ACTIVE_TAB_SET  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  INIT_SCREENS  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_screens OUTPUT.
  IF populated = space.
    PERFORM init_screens.
  ENDIF.
  populated = space.
*CLEAR FIRST_TIME.
ENDMODULE.                 " INIT_SCREENS  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  SET_TOTAL_CONFLICT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_total_conflict OUTPUT.
  DESCRIBE TABLE conflict LINES tot_lines.
ENDMODULE.                 " SET_TOTAL_CONFLICT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  SET_TOTAL_CONFLICT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_total_conflict2 OUTPUT.
  DESCRIBE TABLE conflict2 LINES tot_lines.
ENDMODULE.                 " SET_TOTAL_CONFLICT2  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  init_0211  OUTPUT
*&---------------------------------------------------------------------*
*       Initialize screen 211
*----------------------------------------------------------------------*
MODULE init_0211 OUTPUT.
*--Always do authority check

*-- 3.1PS4 Change.

*  IF sec_actvt IS INITIAL.
*    sec_actvt = act_display.
*  ENDIF.
  exelog sy-repid 'Tab Mitigation Definition'.

  PERFORM authority_check_mc_h
          USING sec_actvt /psyng/mchdr-contid.

*  CLEAR  sec_actvt.
ENDMODULE.                 " init_0211  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  init_0212  OUTPUT
*&---------------------------------------------------------------------*
*       Get Mitigating user ID's from /PSYNG/MCUSER
*----------------------------------------------------------------------*
MODULE init_0212 OUTPUT.

  exelog sy-repid 'Tab Mitigation Assign User'.


* Always do authority check
  sec_actvt = act_display.
  PERFORM authority_check_mc_assign USING sec_actvt space space
                                                    space space.

  IF gt_mcuser[] IS INITIAL.
    SELECT * FROM /psyng/mcuser INTO TABLE gt_mcuser
    WHERE vrsio = g_sod_vrsio.
    SORT gt_mcuser BY userid conid vrsio contid from_date.
  ENDIF.
  DESCRIBE TABLE gt_mcuser LINES tc_mcuser-lines.

*---justification and attachment available
*-- odubey 2022/02/28
  if not gt_mcuser[] is INITIAL.
    loop at gt_mcuser.
      MOVE-CORRESPONDING gt_mcuser to gs_assingment.
      gs_assingment-type = '1'.

*----attachment
      CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
       EXPORTING
         IF_ASSIGNMENT            = 'X'
         IF_CHECK                 = 'X'
         I_MCID                   = gt_mcuser-contid
         IS_ASSIGNMENT            = gs_assingment
       IMPORTING
         EF_HAS_ATTACHMENTS       = g_exist
       EXCEPTIONS
         INVALID_INPUT            = 1
         NOT_IMPLEMENTED          = 2
         GOS_FAILURE              = 3
         OTHERS                   = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mcuser-attach_avl = 'Available'.
      else.
        gt_mcuser-attach_avl = 'Not Available'.
      ENDIF.

*--- justification
      clear g_exist.
      CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
       EXPORTING
         IF_ASSIGNMENT              = 'X'
         IF_CHECK                   = 'X'
         I_MCID                     = gt_mcuser-contid
         IS_ASSIGNMENT              = gs_assingment
       IMPORTING
         EF_HAS_JUSTIFICATION       = g_exist
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INVALID_INPUT   = 1
             NOT_IMPLEMENTED = 2
             GOS_FAILURE     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mcuser-just_avl = 'Available'.
      else.
        gt_mcuser-just_avl = 'Not Available'.
      ENDIF.
       modify gt_mcuser TRANSPORTING  just_avl attach_avl.
      endloop.
    endif.


  LOOP AT SCREEN.
    CHECK screen-group2 = '001'.

    IF gf_edit = gc_select.
      screen-input = 1.
    ELSE.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

*--Hide Org ABB column if MIT_BY_ORG is not enabbled.
  FIELD-SYMBOLS: <cols> TYPE cxtab_column.
  data : lf_mit_by_org type flag.
  se_config_param 'MIT_BY_ORG' lf_mit_by_org.
  if lf_mit_by_org <> 'Y'.
    LOOP AT tc_mcuser-cols ASSIGNING <cols>.
     if <cols>-screen-name = 'GT_MCUSER-ORG_ABB'.
      <cols>-invisible = 'X'.
     endif.
    ENDLOOP.
  endif.
  CLEAR ok_code.
ENDMODULE.                 " init_0212  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  init_0222  OUTPUT
*&---------------------------------------------------------------------*
*       Get Mitigating user groups from /PSYNG/MCUSRGRP
*----------------------------------------------------------------------*
MODULE init_0222 OUTPUT.
  exelog sy-repid 'Tab Mitigation Assign Usergroup'.

* Always do authority check
  PERFORM authority_check_mc_assign_grp
          USING sec_actvt space space space 0.

  IF gt_mcusrgrp[] IS INITIAL.
    SELECT *  FROM /psyng/mcusrgrp
    INTO CORRESPONDING FIELDS OF TABLE gt_mcusrgrp
    WHERE vrsio = g_sod_vrsio.
    SORT gt_mcusrgrp BY class conid vrsio contid from_date.
  ENDIF.
  DESCRIBE TABLE gt_mcusrgrp LINES tc_mcusrgrp-lines.

*---justification and attachment available
*-- odubey 2022/02/28
  if not gt_mcusrgrp[] is INITIAL.
    loop at gt_mcusrgrp.
      MOVE-CORRESPONDING gt_mcusrgrp to gs_assingment.
      gs_assingment-type = '2'.

*----attachment
      CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
       EXPORTING
         IF_ASSIGNMENT            = 'X'
         IF_CHECK                 = 'X'
         I_MCID                   = gt_mcusrgrp-contid
         IS_ASSIGNMENT            = gs_assingment
       IMPORTING
         EF_HAS_ATTACHMENTS       = g_exist
       EXCEPTIONS
         INVALID_INPUT            = 1
         NOT_IMPLEMENTED          = 2
         GOS_FAILURE              = 3
         OTHERS                   = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mcusrgrp-attach_avl = 'Available'.
      else.
        gt_mcusrgrp-attach_avl = 'Not Available'.
      ENDIF.

*--- justification
      clear g_exist.
      CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
       EXPORTING
         IF_ASSIGNMENT              = 'X'
         IF_CHECK                   = 'X'
         I_MCID                     = gt_mcusrgrp-contid
         IS_ASSIGNMENT              = gs_assingment
       IMPORTING
         EF_HAS_JUSTIFICATION       = g_exist
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INVALID_INPUT   = 1
             NOT_IMPLEMENTED = 2
             GOS_FAILURE     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mcusrgrp-just_avl = 'Available'.
      else.
        gt_mcusrgrp-just_avl = 'Not Available'.
      ENDIF.
       modify gt_mcusrgrp TRANSPORTING  just_avl attach_avl.
      endloop.
    endif.

  LOOP AT SCREEN.
    CHECK screen-group2 = '001'.

    IF gf_edit = gc_select.
      screen-input = 1.
    ELSE.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

  CLEAR ok_code.
ENDMODULE.                 " init_0222  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  init_0224  OUTPUT
*&---------------------------------------------------------------------*
*       Get Mitigating roles from /PSYNG/MCROLE
*----------------------------------------------------------------------*
MODULE init_0224 OUTPUT.
  exelog sy-repid 'Tab Mitigation Assign Role'.

* Always do authority check
  PERFORM authority_check_mc_assign_role
          USING sec_actvt space space space 0.

  IF gt_mcrole[] IS INITIAL.
    SELECT * FROM /psyng/mcrole
           INTO CORRESPONDING FIELDS OF TABLE gt_mcrole
           WHERE vrsio = g_sod_vrsio.
    SORT gt_mcrole BY agr_name conid vrsio contid from_date.
  ENDIF.
  DESCRIBE TABLE gt_mcrole LINES tc_mcrole-lines.

*---justification and attachment available
*-- odubey 2022/02/28
  if not gt_mcrole[] is INITIAL.
    loop at gt_mcrole.
      MOVE-CORRESPONDING gt_mcrole to gs_assingment.
      gs_assingment-type = '4'.

*----attachment
      CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
       EXPORTING
         IF_ASSIGNMENT            = 'X'
         IF_CHECK                 = 'X'
         I_MCID                   = gt_mcrole-contid
         IS_ASSIGNMENT            = gs_assingment
       IMPORTING
         EF_HAS_ATTACHMENTS       = g_exist
       EXCEPTIONS
         INVALID_INPUT            = 1
         NOT_IMPLEMENTED          = 2
         GOS_FAILURE              = 3
         OTHERS                   = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mcrole-attach_avl = 'Available'.
      else.
        gt_mcrole-attach_avl = 'Not Available'.
      ENDIF.

*--- justification
      clear g_exist.
      CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
       EXPORTING
         IF_ASSIGNMENT              = 'X'
         IF_CHECK                   = 'X'
         I_MCID                     = gt_mcrole-contid
         IS_ASSIGNMENT              = gs_assingment
       IMPORTING
         EF_HAS_JUSTIFICATION       = g_exist
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
              INVALID_INPUT   = 1
              NOT_IMPLEMENTED = 2
              GOS_FAILURE     = 3
              OTHERS           = 4 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mcrole-just_avl = 'Available'.
      else.
        gt_mcrole-just_avl = 'Not Available'.
      ENDIF.
       modify gt_mcrole TRANSPORTING  just_avl attach_avl.
      endloop.
    endif.

  LOOP AT SCREEN.
    CHECK screen-group2 = '001'.

    IF gf_edit = gc_select.
      screen-input = 1.
    ELSE.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

  CLEAR ok_code.
ENDMODULE.                 " init_0224  OUTPUT

*---------------------------------------------------------------------*
*       MODULE init_0228 OUTPUT                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE init_0228 OUTPUT.
  DATA: lt_mcaudit TYPE TABLE OF /psyng/sw_mc_audit_overview
         WITH HEADER LINE.
  REFRESH: gt_mcaudit, lt_mcaudit.
  IF gt_mcaudit[] IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_MC_AUDIT_OVERVIEW'
      TABLES
        et_overview = lt_mcaudit.
  ENDIF.

  LOOP AT lt_mcaudit.
    MOVE-CORRESPONDING lt_mcaudit TO gt_mcaudit.
    APPEND gt_mcaudit.
  ENDLOOP.
  SORT gt_mcaudit BY contid auditor from_date to_date.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ICON  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_icon OUTPUT.
  IF tot_lines > 0.
    color = 'RED'.
    CONCATENATE 'ICON_LED_' color INTO icon_name .
    IF sod_conflict = space.
      CONCATENATE text-114  tot_lines INTO icon_text.
    ELSE.
      CONCATENATE text-115  tot_lines INTO icon_text.
    ENDIF.
    CALL FUNCTION 'ICON_CREATE'
      EXPORTING
        name                  = icon_name
        text                  = icon_text
        info                  = icon_info
*       ADD_STDINF            = 'X'
      IMPORTING
        result                = icon5
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
* Button ausblenden.
    LOOP AT SCREEN .
      IF screen-name = 'ICON5' .
        screen-invisible = '0' .
        MODIFY SCREEN .
      ENDIF .
    ENDLOOP.
  ENDIF.
ENDMODULE.                 " DISPLAY_ICON  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  LOAD_LOGO_0101  OUTPUT
*&---------------------------------------------------------------------*
*       Load SW logo
*----------------------------------------------------------------------*
MODULE load_logo_0101 OUTPUT.
  DATA: lt_pic_data LIKE w3mime OCCURS 0,
        l_pic_size  TYPE i,
        l_url(255)  TYPE c.

  IF gcl_pic_container IS INITIAL.
*   Create controls
    CREATE OBJECT gcl_pic_container
      EXPORTING
        container_name = 'GCL_PIC_CONTROL'.

    CREATE OBJECT gcl_pic_control
      EXPORTING
        parent = gcl_pic_container.

*   Set the display mode to 'normal' (0)
    CALL METHOD gcl_pic_control->set_display_mode
      EXPORTING
        display_mode = 1.
*   Set frame
    CALL METHOD gcl_pic_control->set_3d_border
      EXPORTING
        border = 0.

*   Load the picture data from the WebRFC database into the internal
*   table pic_data.
    PERFORM load_picture_from_db   TABLES   lt_pic_data
                                   USING    '/PSYNG/SE_LOGO'
                                   CHANGING l_pic_size.

*   Request an URL from the data provider by exporting the pic_data.
    CLEAR l_url.
    CALL FUNCTION 'DP_CREATE_URL'
      EXPORTING
        type     = 'image'
        subtype  = 'X-UNKNOWN'
        size     = l_pic_size
        lifetime = 'T'  "cndp_lifetime_transaction
      TABLES
        data     = lt_pic_data
      CHANGING
        url      = l_url
      EXCEPTIONS
        OTHERS   = 1.
*   Load the picture by using the url generated by the data provider.
    IF sy-subrc = 0.
      CALL METHOD gcl_pic_control->load_picture_from_url
        EXPORTING
          url = l_url.
    ENDIF.
  ENDIF.
ENDMODULE.                 " LOAD_LOGO_0101  OUTPUT

*&spwizard: output module for tc 'CRITROLE'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
MODULE critrole_change_tc_attr OUTPUT.
  DESCRIBE TABLE g_criroles_itab LINES critrole-lines.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  init_0223  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_0223 OUTPUT.
  exelog sy-repid 'Tab Mitigation Assign User CA'.


* Always do authority check
  sec_actvt = act_display.
  PERFORM authority_check_mccri_assign
          USING sec_actvt space space space space.

  IF gt_mccauser[] IS INITIAL.
    SELECT *  FROM /psyng/mccauser
     INTO CORRESPONDING FIELDS OF TABLE gt_mccauser
     WHERE vrsio = g_sod_vrsio.
    SORT gt_mccauser BY userid swaudid vrsio contid from_date.
  ENDIF.
  DESCRIBE TABLE gt_mccauser LINES tc_mccriauth-lines.

*---justification and attachment available
*-- odubey 2022/02/28
  if not gt_mccauser[] is INITIAL.
    loop at gt_mccauser.
      MOVE-CORRESPONDING gt_mccauser to gs_assingment.
      gs_assingment-type = '3'.

*----attachment
      CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
       EXPORTING
         IF_ASSIGNMENT            = 'X'
         IF_CHECK                 = 'X'
         I_MCID                   = gt_mccauser-contid
         IS_ASSIGNMENT            = gs_assingment
       IMPORTING
         EF_HAS_ATTACHMENTS       = g_exist
       EXCEPTIONS
         INVALID_INPUT            = 1
         NOT_IMPLEMENTED          = 2
         GOS_FAILURE              = 3
         OTHERS                   = 4.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

      IF g_exist = 'X'.
      gt_mccauser-attach_avl = 'Available'.
      else.
        gt_mccauser-attach_avl = 'Not Available'.
      ENDIF.

*--- justification
      clear g_exist.
      CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
       EXPORTING
         IF_ASSIGNMENT              = 'X'
         IF_CHECK                   = 'X'
         I_MCID                     = gt_mccauser-contid
         IS_ASSIGNMENT              = gs_assingment
       IMPORTING
         EF_HAS_JUSTIFICATION       = g_exist
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INVALID_INPUT   = 1
             NOT_IMPLEMENTED = 2
             GOS_FAILURE     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mccauser-just_avl = 'Available'.
      else.
        gt_mccauser-just_avl = 'Not Available'.
      ENDIF.
       modify gt_mccauser TRANSPORTING  just_avl attach_avl.
      endloop.
    endif.

  LOOP AT SCREEN.
    CHECK screen-group2 = '001'.

    IF gf_edit = gc_select.
      screen-input = 1.
    ELSE.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

  CLEAR ok_code.

ENDMODULE.                 " init_0223  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  init_0225  OUTPUT
*&---------------------------------------------------------------------*
*       Initialize screen 225
*----------------------------------------------------------------------*
MODULE init_0225 OUTPUT.
  exelog sy-repid 'Tab Mitigation Assign Role CA'.

* Always do authority check
  PERFORM auth_check_mccri_role_assign
          USING sec_actvt space space space space.

  IF gt_mccarole[] IS INITIAL.
    SELECT * FROM /psyng/mccarole
           INTO CORRESPONDING FIELDS OF TABLE gt_mccarole
           WHERE vrsio = g_sod_vrsio.
    SORT gt_mccarole BY agr_name swaudid vrsio contid from_date.
  ENDIF.
  DESCRIBE TABLE gt_mccarole LINES tc_mccarole-lines.

*---justification and attachment available
*-- odubey 2022/02/28
  if not gt_mccarole[] is INITIAL.
    loop at gt_mccarole.
      MOVE-CORRESPONDING gt_mccarole to gs_assingment.
      gs_assingment-type = '5'.

*----attachment
      CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
       EXPORTING
         IF_ASSIGNMENT            = 'X'
         IF_CHECK                 = 'X'
         I_MCID                   = gt_mccarole-contid
         IS_ASSIGNMENT            = gs_assingment
       IMPORTING
         EF_HAS_ATTACHMENTS       = g_exist
       EXCEPTIONS
         INVALID_INPUT            = 1
         NOT_IMPLEMENTED          = 2
         GOS_FAILURE              = 3
         OTHERS                   = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mccarole-attach_avl = 'Available'.
      else.
        gt_mccarole-attach_avl = 'Not Available'.
      ENDIF.

*--- justification
      clear g_exist.
      CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
       EXPORTING
         IF_ASSIGNMENT              = 'X'
         IF_CHECK                   = 'X'
         I_MCID                     = gt_mccarole-contid
         IS_ASSIGNMENT              = gs_assingment
       IMPORTING
         EF_HAS_JUSTIFICATION       = g_exist
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INVALID_INPUT   = 1
             NOT_IMPLEMENTED = 2
             GOS_FAILURE     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      IF g_exist = 'X'.
      gt_mccarole-just_avl = 'Available'.
      else.
        gt_mccarole-just_avl = 'Not Available'.
      ENDIF.
       modify gt_mccarole TRANSPORTING  just_avl attach_avl.
      endloop.
    endif.

  LOOP AT SCREEN.
    CHECK screen-group2 = '001'.

    IF gf_edit = gc_select.
      screen-input = 1.
    ELSE.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

  CLEAR ok_code.
ENDMODULE.                 " init_0225  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  IMPORT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE import OUTPUT.
  IMPORT g_memory_text FROM MEMORY ID c_e378.
ENDMODULE.                 " IMPORT  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  IMPORT_211  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE import_211 OUTPUT.
  IMPORT itab1 FROM MEMORY ID c_e377.
ENDMODULE.                 " IMPORT_211  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_invisible  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_invisible OUTPUT.
  DATA : ls_config   TYPE /psyng/swconfig,
         lf_useroles TYPE flag.

  se_config_param 'USE_ROLES' ls_config-value.
  IF ls_config-value = 'N'.
    CLEAR lf_useroles.
  ELSE.
    lf_useroles = 'X'.
  ENDIF.


  LOOP AT SCREEN.
    IF lf_useroles = 'X'.
      CASE screen-group2.
        WHEN '040'.
          screen-invisible = 1.
          screen-input = 0.
          screen-active = 0.
          MODIFY SCREEN.
      ENDCASE.
    ELSE.
      CASE screen-group2.
        WHEN '029'.
          screen-invisible = 1.
          screen-input = 0.
          screen-active = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDIF.
  ENDLOOP.


  DEFINE check_hide_button.
    perform check_button_visible using &1 &2 &3 &4.
  END-OF-DEFINITION.

  check_hide_button :
*--Group Buttons

    'MOSTBOX' gc_type_box 'Most Used Reports' '901',
    'SODBOX'  gc_type_box 'SOD Reports' '902',
    'STORBOX' gc_type_box 'Stored SOD User Results' '903',
    'HISTBOX' gc_type_box 'Historical Reports' '904',
    'MITBOX'  gc_type_box 'Mitigation Reports' '905',
    'MGMTBOX' gc_type_box 'Management Reports' '906',
    'USERBOX' gc_type_box 'User Reports' '907',
    'CRITBOX' gc_type_box 'Critical Access Monitoring' '908',
    'DOCBOX'  gc_type_box 'Documentation Reports -hidden by default' '909',
    'AREABOX' gc_type_box 'Area Menu' '910',
    'STORROLEBOX' gc_type_box 'Stored SOD Role Results' '911',
*--Report Buttons
    '/PSYNG/SODREPORT_SYS_WIDE' gc_type_button 'SOD User Analysis' '001',
    '/PSYNG/SODREPORT' gc_type_button '' '003',
    '/PSYNG/SW_022'    gc_type_button 'SW Documented Roles' '004',
    '/PSYNG/SW_023'    gc_type_button 'Positions' '005',
    '/PSYNG/SW_024'    gc_type_button 'Users' '006',
    '/PSYNG/CNFLTRPT'  gc_type_button 'Conflicts in Doc' '007',
    '/PSYNG/SW_030'    gc_type_button 'Critical Profiles' '008',
    '/PSYNG/SW_031'    gc_type_button 'Critical Roles' '009',
    '/PSYNG/SW_032'    gc_type_button 'Newly Created User IDs' '010',
    '/PSYNG/SUMRYRPT'  gc_type_button 'Summary Report' '011',
    '/PSYNG/USER_EXE_TCODE' gc_type_button 'Executable Transactions by Users' '012',
    '/PSYNG/CRI_TCODE_LIST' gc_type_button 'Critical Tran User Analysis' '013',
    '/PSYNG/SW_CRIT_AUTHS'  gc_type_button 'Critical Auth User Analysis' '014',
    '/PSYNG/SW_AUTH_COUNT'  gc_type_button 'SW: Authorization Count in Users' '015',
    '/PSYNG/SOD_MANG_REPO'  gc_type_button 'Management SOD Graphs' '016',
    '/PSYNG/SODREPORT_BY_HISTORY' gc_type_button 'Conflicts By History' '017',
    '/PSYNG/SW_017'         gc_type_button 'View Tcode Execution History' '018',
    '/PSYNG/USER_LOGON_MONITOR' gc_type_button 'User Logon Monitor'  '019',
    '/PSYNG/SW_015'             gc_type_button 'Background Job user ID’s'  '020',
    '/PSYNG/SW_016'             gc_type_button 'User with multiple User IDs' '021',
    '/PSYNG/SW_018'             gc_type_button 'SW: Dual User Analysis' '022',
    '/PSYNG/SW_SOD_SUM_RP'      gc_type_button 'User SOD Summary' '023',
    '/PSYNG/SW_033'             gc_type_button 'SOD by User Group'  '024',
    '/PSYNG/SW_034'             gc_type_button 'SOD by pers Area'  '025',
    '/PSYNG/SW_040'             gc_type_button 'Ran Executable Transactions'  '027',
    '/PSYNG/BC_USRHIS_05'       gc_type_button 'Role Efficiency'  '028',
    '/PSYNG/SW_082'             gc_type_button 'Role Efficiency'  '028',
    '/PSYNG/SOD_SYSWIDE_BYROLE' gc_type_button 'SOD Role Analysis' '029',
    '/PSYNG/SW_080'             gc_type_button 'Advanced Role Simulation'  '030',
    '/PSYNG/SW_099'             gc_type_button 'SOD & Critical Auth' '031',
    '/PSYNG/SW_095'             gc_type_button 'Function User Analysis' '032',
    '/PSYNG/SW_CRIT_AUTHS_BYROLE' gc_type_button 'Critical Auth Role Analysis' '033',
    '/PSYNG/SW_035'             gc_type_button 'SOD By App Area'  '034',
    'AREA_MENU'                 gc_type_button 'Area Menu' '035',
    '/PSYNG/SW_102'             gc_type_button 'Mitigation Review' '036',
    '/PSYNG/SW_003'             gc_type_button 'Mitigation Controls' '037',
    '/PSYNG/SW_105'             gc_type_button 'Mitigation Details' '038',
    '/PSYNG/SW_043'             gc_type_button 'Monitor Mitigations' '039',
    '/PSYNG/SODREPORT_BY_PROFILE' gc_type_button '' '040',
    '/PSYNG/SW_129'             gc_type_button 'Function Role Analysis' '041',
    '/PSYNG/SW_132'             gc_type_button '' '132',
    '/PSYNG/SW_137'             gc_type_button 'View Stored SOD User Results' '042',
    '/PSYNG/SW_138'             gc_type_button 'Manage Stored SOD User Results' '043',
    '/PSYNG/SW_140'             gc_type_button 'Store SOD User Results' '044',
    '/PSYNG/SW_150'             gc_type_button 'View Stored SOD Role Results' '045',
    '/PSYNG/SW_149'             gc_type_button 'Manage Stored SOD Role Results' '046',
    '/PSYNG/SW_148'             gc_type_button 'Store SOD Role Results' '047',
    '/PSYNG/SW_SOD_SUM_ROLE'    gc_type_button 'Role SOD Summary' '048',
    '/PSYNG/CRI_TCODE_LIST_BYROLE' gc_type_button 'Critical Transactions Role Analysis' '049'.

ENDMODULE.                 " init_invisible  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  INIT_100_SCREENS  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_100_screens OUTPUT.
  DATA : l_value_config TYPE /psyng/swconfig-value.

  IF g_upgrade_check_done IS INITIAL.
* Upgrade check
    CALL FUNCTION '/PSYNG/UPGRADE_CHECK'
      EXPORTING
        i_transaction = sy-tcode
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             upgrade_required = 1
             OTHERS           = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    g_upgrade_check_done = 'X'.
  ENDIF.

*--- Check Config Param
  se_config_param 'SW_ROLES_POS_USRASGN' l_value.

  IF  l_value = 'Y'.
*-- Dont do anything with tabs
  ELSE.
*-- Hide
    LOOP AT SCREEN.
      IF screen-group1 = '111'.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.

*       Exclude from menu
      gt_func-fcode = 'ROLES_FC1'.
      APPEND gt_func.
      gt_func-fcode = 'ROLES_FC2'.
      APPEND gt_func.

      IF screen-group1 = '222'.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.

*       Exclude from menu
      gt_func-fcode = 'SECTAB_FC4'.
      APPEND gt_func.

      IF screen-group1 = '333'.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

*       Exclude from menu
    gt_func-fcode = 'SECTAB_FC5'.
    APPEND gt_func.
  ENDIF.


** Check if maintenance of SOD versions is to be excluded
*  log_exc_vers_100.

*g_yx_sectab-pressed_tab
  DATA : lf_hidden TYPE flag.

*--Hide any tabs based on table /psyng/swinvisbl
*  and auth object Y&SW_TAB
  PERFORM check_tab_visible USING 'ROLES' gc_type_tab 'Roles' '111'
                           'ROLES_FC1' 'ROLES_FC2' '' '' ''
                           CHANGING lf_hidden.
  PERFORM check_tab_visible USING 'REPOSITORY' gc_type_tab 'Conflict Repository' '444'
                            'SODFUN_FC1' 'SODFUN_FC2'
                            'SODFUN_FC5' 'SODFUN_FC6' 'SODFUN_FC7'
                            CHANGING lf_hidden.
*--do the repository one again, for the remaining menu items
  PERFORM check_tab_visible USING 'REPOSITORY' gc_type_tab 'Conflict Repository' '444'
                            'MITCON_FC1' 'MITCON_FC2'
                            'MITCON_FC3' 'MITCON_FC4' 'SODFUN_FC8'
                            CHANGING lf_hidden.

  PERFORM check_tab_visible USING 'POSITION' gc_type_tab 'Positions' '222'
                            'SECTAB_FC4' '' '' '' ''
                            CHANGING lf_hidden.
  PERFORM check_tab_visible USING 'USER' gc_type_tab 'Users' '333'
                            'SECTAB_FC5' '' '' '' ''
                            CHANGING lf_hidden.
  PERFORM check_tab_visible USING 'MONI' gc_type_tab 'Monitoring' '666'
                            'SECTAB_FC6' '' '' '' ''
                            CHANGING lf_hidden.
  PERFORM check_tab_visible USING 'MISC' gc_type_tab 'Misc' '999'
                            'SECTAB_FC7' '' '' '' ''
                            CHANGING lf_hidden.
ENDMODULE.                 " INIT_100_SCREENS  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  get_sw_vrsio  OUTPUT
*&---------------------------------------------------------------------*
*       Get Security Weaver version
*----------------------------------------------------------------------*
MODULE get_sw_vrsio OUTPUT.
  data l_version type /PSYNG/PROG_VRSIO.

  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
   EXPORTING
     I_MODULE               = 'SE'
   IMPORTING
     E_MODULE_VERSION       = l_version.

*  SELECT SINGLE vrsio INTO g_sw_vrsio FROM /psyng/sw_vrsio.
g_sw_vrsio = l_version.
  CONCATENATE text-159 g_sw_vrsio INTO g_sw_vrsio SEPARATED BY space.
* Customer maintainable version
  DATA : lt_cusvers TYPE TABLE OF /psyng/swcusvers WITH HEADER LINE,
         spaces     TYPE i.
  SELECT * INTO TABLE lt_cusvers FROM /psyng/swcusvers ORDER BY linenr.
  IF sy-subrc = 0.
    LOOP AT lt_cusvers.
      IF lt_cusvers-linenr = 1 AND NOT lt_cusvers-text IS INITIAL.
*center text
        spaces = strlen( lt_cusvers-text ).
        spaces = ( 60 - spaces ) / 2.
        g_sw_custvrsio1+spaces =  lt_cusvers-text.
        LOOP AT SCREEN.
          IF screen-name = 'G_SW_CUSTVRSIO1'.
            screen-invisible = '0'.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
      IF lt_cusvers-linenr = 2 AND NOT lt_cusvers-text IS INITIAL.
        spaces = strlen( lt_cusvers-text ).
        spaces = ( 60 - spaces ) / 2.
        g_sw_custvrsio2+spaces =  lt_cusvers-text .
        LOOP AT SCREEN.
          IF screen-name = 'G_SW_CUSTVRSIO2'.
            screen-invisible = '0'.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
      IF lt_cusvers-linenr = 3 AND NOT lt_cusvers-text IS INITIAL.
        spaces = strlen( lt_cusvers-text ).
        spaces = ( 60 - spaces ) / 2.
        g_sw_custvrsio3+spaces =  lt_cusvers-text .
        LOOP AT SCREEN.
          IF screen-name = 'G_SW_CUSTVRSIO3'.
            screen-invisible = '0'.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDMODULE.                 " get_sw_vrsio  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  validate_tcode  INPUT
*&---------------------------------------------------------------------*
*       Validate transaction
*----------------------------------------------------------------------*
MODULE validate_tcode INPUT.
  PERFORM validate_tcode USING /psyng/swaudhdr-tcode.
ENDMODULE.                 " validate_tcode  INPUT

*&---------------------------------------------------------------------*
*&      Module  pbo_107  OUTPUT
*&---------------------------------------------------------------------*
*       PBO for screen 107
*----------------------------------------------------------------------*
MODULE pbo_107 OUTPUT.
  SELECT SINGLE name INTO g_prog_name FROM trdir
       WHERE name = 'RPR_ABAP_SOURCE_SCAN'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      CHECK screen-name = 'ABAP_SCAN'.
      screen-invisible = '1'.
      MODIFY SCREEN.
      EXIT.
    ENDLOOP.
  ENDIF.
ENDMODULE.                 " pbo_107  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  pbo_902  OUTPUT
*&---------------------------------------------------------------------*
*       PBO for screen 902
*----------------------------------------------------------------------*
MODULE pbo_902 OUTPUT.
  gt_func-fcode = 'FS'.
  APPEND gt_func.
  SET PF-STATUS 'NOEDIT' EXCLUDING gt_func.
ENDMODULE.                 " pbo_902  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  pbo_0903  OUTPUT
*&---------------------------------------------------------------------*
*       PBO for screen 903
*----------------------------------------------------------------------*
MODULE pbo_0903 OUTPUT.
  SET PF-STATUS '0903'.
  LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 903.

  WRITE: / text-193,
         / text-194,
         / text-195.
  SKIP.
  LOOP AT gt_roles WHERE saptechname = space.
    WRITE: / gt_roles-roleid, gt_roles-description.
  ENDLOOP.

  LEAVE SCREEN.
ENDMODULE.                 " pbo_0903  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0904  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0904 OUTPUT.
  IF gf_dispchg = gc_display.
    SET PF-STATUS '0904' EXCLUDING 'SAVE'.
  ELSE.
    SET PF-STATUS '0904' .
  ENDIF.

ENDMODULE.                 " STATUS_0904  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9000 OUTPUT.
ENDMODULE.                 " STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0106  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0106 OUTPUT.
  exelog sy-repid 'Tab Monitoring'.
  PERFORM init_states_0106.
ENDMODULE.                 " STATUS_0106  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0107  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0107 OUTPUT.
  exelog sy-repid 'Tab Misc'.
  PERFORM init_states_0107.
ENDMODULE.                 " STATUS_0107  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  status_0905  OUTPUT
*&---------------------------------------------------------------------*
*       Set status for popup mitigation assignment find screen
*----------------------------------------------------------------------*
MODULE status_0905 OUTPUT.
  SET PF-STATUS '0903'.

  LOOP AT SCREEN.
    IF g_mit_vrsio_fld = 'X'.
      IF screen-name = 'GL_MCUSER-VRSIO'.
        screen-input = 0.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.
  CLEAR g_mit_vrsio_fld.

  LOOP AT SCREEN.
    CHECK screen-name = 'GL_MCUSER-VRSIO'
    OR screen-name = 'GL_MCUSER-USERID'
    OR screen-name = 'GL_MCUSRGRP-CLASS'
    OR screen-name = 'GL_MCCAUSER-SWAUDID'
    OR screen-name = 'GL_MCROLE-AGR_NAME'
    OR screen-name = 'GL_MCUSER-CONID'.

    CASE g_call_scrn.
      WHEN '0212'.
        CHECK screen-name = 'GL_MCUSRGRP-CLASS'
        OR screen-name = 'GL_MCCAUSER-SWAUDID'
        OR screen-name = 'GL_MCROLE-AGR_NAME'.

        screen-active = 0.

      WHEN '0222'.
        CHECK screen-name = 'GL_MCUSER-USERID'
        OR screen-name = 'GL_MCCAUSER-SWAUDID'
        OR screen-name = 'GL_MCROLE-AGR_NAME'.

        screen-active = 0.

      WHEN '0223'.
        CHECK screen-name = 'GL_MCUSRGRP-CLASS'
        OR screen-name = 'GL_MCROLE-AGR_NAME'
        OR screen-name = 'GL_MCUSER-CONID'.

        screen-active = 0.

      WHEN '0224'.
        CHECK screen-name = 'GL_MCUSER-USERID'
        OR screen-name = 'GL_MCUSRGRP-CLASS'
        OR screen-name = 'GL_MCCAUSER-SWAUDID'.

        screen-active = 0.

      WHEN '0225'.
        CHECK screen-name = 'GL_MCUSRGRP-CLASS'
        OR screen-name = 'GL_MCUSER-USERID'
        OR screen-name = 'GL_MCUSER-CONID'.

        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " status_0905  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS '300'.
  SET TITLEBAR 'TITLE' WITH gtitle.
ENDMODULE.                 " STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_editor  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_editor OUTPUT.
  IF go_text_edit IS INITIAL.
*   create control container
    CREATE OBJECT go_text_editor
      EXPORTING
        container_name              = 'G_TEXT_CONTAINER'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.

*   Create calls constructor, which initializes, creates and links a
*   TextEdit Control
    CREATE OBJECT go_text_edit
      EXPORTING
        parent                     = go_text_editor
        wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true
        max_number_chars           = 255
      EXCEPTIONS
        OTHERS                     = 1.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.

* Fill with text
  CALL METHOD go_text_edit->set_text_as_r3table
    EXPORTING
      table           = gt_editor_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* Finally flush
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

  IF gf_dispchg = gc_change.
    CALL METHOD go_text_edit->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>false
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.
  ELSE.
    CALL METHOD go_text_edit->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>true
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.
  ENDIF.

ENDMODULE.                 " init_editor  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  display_change  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_change OUTPUT.

  PERFORM display_change USING sy-dynnr.

ENDMODULE.                 " display_change  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  load_data  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE load_data OUTPUT.

  DATA : l_funid   LIKE /psyng/functtran-functionid,
         l_conid   LIKE /psyng/conflict-conid,
         l_contid  LIKE /psyng/mchdr-contid,
         l_swaudid LIKE /psyng/swaudc2-swaudid,
         l_roleid  LIKE /psyng/roletrans-roleid,
         l_vrsio   LIKE /psyng/functtran-vrsio.
*  refresh g_editor_text.
  CASE sy-dynnr.
    WHEN '0201'.
      IF /psyng/functtran-functionid IS INITIAL.
        GET PARAMETER ID '/PSYNG/FUN'
          FIELD l_funid. "#EC SAST_CI_GEN_CHECK
        IF NOT l_funid IS INITIAL.
          /psyng/functtran-functionid = l_funid.
        ENDIF.
      ENDIF.
      IF NOT /psyng/functtran-functionid IS INITIAL.
        PERFORM load_function.
      ENDIF.
    WHEN '0202'.
      IF /psyng/confdet-conid IS INITIAL.
        GET PARAMETER ID '/PSYNG/CON'
          FIELD l_conid."#EC SAST_CI_GEN_CHECK
        IF NOT l_conid IS INITIAL.
          /psyng/confdet-conid = l_conid.
        ENDIF.
      ENDIF.
      IF NOT /psyng/confdet-conid IS INITIAL.
        PERFORM load_conflict.
      ENDIF.
    WHEN '0211'.
      IF /psyng/mchdr-contid IS INITIAL.
        GET PARAMETER ID '/PSYNG/SW_MIT'
          FIELD l_contid. "#EC SAST_CI_GEN_CHECK
        IF NOT l_contid IS INITIAL.
          /psyng/mchdr-contid = l_contid.
        ENDIF.
      ENDIF.
      IF NOT /psyng/mchdr-contid IS INITIAL.
        PERFORM load_mitigation CHANGING l_contid.
      ENDIF.
    WHEN '0209'.
      IF /psyng/swaudc2-swaudid IS INITIAL.
        GET PARAMETER ID '/PSYNG/SW_CRIT_AUTH'
          FIELD l_swaudid. "#EC SAST_CI_GEN_CHECK
        IF NOT l_swaudid IS INITIAL.
          /psyng/swaudc2-swaudid = l_swaudid.
        ENDIF.
      ENDIF.
      IF NOT /psyng/swaudc2-swaudid IS INITIAL.
        PERFORM load_ca.
      ENDIF.
    WHEN '0301'.
      IF /psyng/roletrans-roleid IS INITIAL.
        GET PARAMETER ID '/PSYNG/ROLE'
          FIELD l_roleid. "#EC SAST_CI_GEN_CHECK
        IF NOT l_roleid IS INITIAL.
          /psyng/roletrans-roleid = l_roleid.
        ENDIF.
      ENDIF.
      IF NOT /psyng/roletrans-roleid IS INITIAL.
        PERFORM load_role.
      ENDIF.

  ENDCASE.

ENDMODULE.                 " load_data  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  critrans_get_lines  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

*MODULE initial OUTPUT.
*g_tc_lines = 0.
*ENDMODULE.


MODULE get_lines OUTPUT.
  g_tc_lines = sy-loopc.
ENDMODULE.                 " gt_freqtxt_get_lines  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  dashboard_0109  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE dashboard_0109 OUTPUT.
  exelog sy-repid 'Tab Dashboard'.

  DATA : lv_url(255) TYPE c.
  DATA : lv_url_s TYPE string.

  DATA : lv_url1(255) TYPE c.
  DATA : lv_url1_s TYPE string.
  DATA : BEGIN OF ls_token,
           mandt           TYPE  mandt,
           bname           TYPE  xubname,
           token(25)       TYPE  c,
           tokenkey(12)    TYPE c,
           expiration_date TYPE sy-datum,
           expiration_time TYPE sy-uzeit,
         END OF ls_token.

  DATA : lv_flag     TYPE flag,
         lv_flag1    TYPE flag,
         lv_flag2    TYPE flag,
         lv_funcname TYPE tfdir-funcname.
  DATA : lv_widget1_value(30) TYPE c.
  DATA : lv_widget2_value(30) TYPE c.

*** Create a single token for all widgets we'll display here.
  IF gv_module_check = 'X' AND gv_param_value_check = 'X'.
** check whether widget values are changed.
    IF lv_flag1 = 'X' OR lv_flag2 = 'X'.
** get widget1 value.
      se_config_param 'DASHBOARD_WIDGET1' lv_widget1_value.
** get widget2 value.
      se_config_param 'DASHBOARD_WIDGET2' lv_widget2_value.
      IF lv_widget1_value <> gv_widget1_value.
        lv_flag1 = ' '.
        gv_widget1_value = lv_widget1_value.
      ENDIF.
      IF lv_widget2_value <> gv_widget2_value.
        lv_flag2 = ' '.
        gv_widget2_value = lv_widget2_value.
      ENDIF.

    ENDIF.


    IF lv_flag IS INITIAL OR lv_flag1 EQ ' ' OR lv_flag2 EQ ' '.
** create token when lv_flag is initial.
      SELECT SINGLE funcname FROM tfdir INTO lv_funcname WHERE funcname EQ
                                                   '/PSYNG/DA_CREATETOKEN'.

      IF sy-subrc EQ 0.
        CALL FUNCTION lv_funcname "#EC PATHLOCK_CI_DYN_ACCES
          EXPORTING
            i_username                = g_current_user"sy-uname C0700
            i_validity                = 20
          IMPORTING
            e_token                   = ls_token
          EXCEPTIONS
            e_token_generation_failed = 1
            e_key_generation_failed   = 2
            e_token_insert_failure    = 3
            OTHERS                    = 4.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        CLEAR lv_funcname.
      ENDIF.
      lv_flag = 'X'.
    ENDIF.

** load widget1 when lv_flag1 is initial.
    IF lv_flag1 IS INITIAL.
**RV Widget1.
** get widget1 value.
      se_config_param 'DASHBOARD_WIDGET1' lv_widget1_value.
      IF NOT lv_widget1_value IS INITIAL.
        SELECT SINGLE funcname FROM tfdir
        INTO lv_funcname WHERE
        funcname EQ '/PSYNG/DA_GET_URL_FOR_USER'.

        IF sy-subrc EQ 0.
          CALL FUNCTION lv_funcname "#EC PATHLOCK_CI_DYN_ACCES
            EXPORTING
              i_bname  = g_current_user"sy-uname C0700
              i_module = 'SE'
              i_widget = lv_widget1_value
              i_token  = ls_token
            IMPORTING
              e_url    = lv_url_s.

          lv_url = lv_url_s.

          CLEAR lv_funcname.

        ENDIF.
      ENDIF.

      IF go_emp_status IS INITIAL.

        CREATE OBJECT go_emp_status
          EXPORTING
            container_name              = 'WIDGET1'
          EXCEPTIONS
            cntl_error                  = 1
            cntl_system_error           = 2
            create_error                = 3
            lifetime_error              = 4
            lifetime_dynpro_dynpro_link = 5
            OTHERS                      = 6.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        CREATE OBJECT go_emp_status_html
          EXPORTING
            parent             = go_emp_status
          EXCEPTIONS
            cntl_error         = 1
            cntl_install_error = 2
            dp_install_error   = 3
            dp_error           = 4
            OTHERS             = 5.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.


      ENDIF.

      CALL METHOD go_emp_status_html->show_url
        EXPORTING
          url                    = lv_url
        EXCEPTIONS
          cntl_error             = 1
          cnht_error_not_allowed = 2
          cnht_error_parameter   = 3
          dp_error_general       = 4
          OTHERS                 = 5.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      lv_flag1 = 'X'.
    ENDIF.

**RV Widget2.
** load widget2 when lv_flag2 is initial.

    IF lv_flag2 IS INITIAL.
      se_config_param 'DASHBOARD_WIDGET2' lv_widget2_value.
      IF NOT lv_widget2_value IS INITIAL.
        SELECT SINGLE funcname FROM tfdir
        INTO lv_funcname WHERE
        funcname EQ '/PSYNG/DA_GET_URL_FOR_USER'.
        IF sy-subrc EQ 0.
          CALL FUNCTION lv_funcname "#EC PATHLOCK_CI_DYN_ACCES
            EXPORTING
              i_bname  = g_current_user"sy-uname C0700
              i_module = 'SE'
              i_widget = lv_widget2_value
              i_token  = ls_token
            IMPORTING
              e_url    = lv_url1_s.

          lv_url1 = lv_url1_s.

          CLEAR lv_funcname.

        ENDIF.
      ENDIF.
      IF go_emp_pie_conflicts IS INITIAL.
        CREATE OBJECT go_emp_pie_conflicts
          EXPORTING
            container_name              = 'WIDGET2'
          EXCEPTIONS
            cntl_error                  = 1
            cntl_system_error           = 2
            create_error                = 3
            lifetime_error              = 4
            lifetime_dynpro_dynpro_link = 5
            OTHERS                      = 6.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        CREATE OBJECT go_pie_conflicts_html
          EXPORTING
            parent             = go_emp_pie_conflicts
          EXCEPTIONS
            cntl_error         = 1
            cntl_install_error = 2
            dp_install_error   = 3
            dp_error           = 4
            OTHERS             = 5.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ENDIF.

**html view for RV Widget2.
      CALL METHOD go_pie_conflicts_html->show_url
        EXPORTING
          url                    = lv_url1
        EXCEPTIONS
          cntl_error             = 1
          cnht_error_not_allowed = 2
          cnht_error_parameter   = 3
          dp_error_general       = 4
          OTHERS                 = 5.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      lv_flag2 = 'X'.
    ENDIF.
  ENDIF.

ENDMODULE.                 " dashboard_0109  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0907  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0907 OUTPUT.
  SET PF-STATUS '0903'.

  LOOP AT SCREEN.
    CHECK screen-name = 'GL_CRITRANS-TCODE'
    OR screen-name = 'GL_CRIPROFS-PROFN'
    OR screen-name = 'GL_CRITROLE-AGR_NAME'
    OR screen-name = 'GL_CRITRANS-BUSAREA'.

    CASE g_call_scrn.
      WHEN '0208'.
        CHECK screen-name = 'GL_CRIPROFS-PROFN'
        OR screen-name = 'GL_CRITROLE-AGR_NAME'.
        screen-active = 0.

      WHEN '0210'.
        CHECK screen-name = 'GL_CRIPROFS-PROFN'
        OR screen-name = 'GL_CRITRANS-TCODE'
        OR screen-name = 'GL_CRITRANS-BUSAREA'.
        screen-active = 0.

      WHEN '0213'.
        CHECK screen-name = 'GL_CRITROLE-AGR_NAME'
              OR screen-name = 'GL_CRITRANS-TCODE'
              OR screen-name = 'GL_CRITRANS-BUSAREA'.
        screen-active = 0.

    ENDCASE.

    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " STATUS_0907  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_0201  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_0201 OUTPUT.
  exelog sy-repid 'Tab Functions'.
ENDMODULE.                 " init_0201  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  STATUS_0908 OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0908 OUTPUT.
  SET PF-STATUS 'SYSFLTR'.
  SET TITLEBAR 'SYSTIT' WITH
          'Conflicts'(s93).

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE status_0228 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0228 OUTPUT.
*  SET PF-STATUS 'SYSFLTR' EXCLUDING 'SAVE'.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE display_confltr_alv OUTPUT                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_confltr_alv OUTPUT.
  PERFORM display_confltr_alv .
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_confltr OUTPUT                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_confltr OUTPUT.
  PERFORM fill_syscon_header.
  PERFORM get_syscon_existing_data.
  gf_dispchg1 = gf_dispchg.
ENDMODULE.


*---------------------------------------------------------------------*
*       MODULE display_audit_alv OUTPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_audit_alv OUTPUT.
  PERFORM display_audit_alv .
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE status_0909 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0909 OUTPUT.
  SET PF-STATUS 'SYSFLTR'.
  SET TITLEBAR 'SYSTIT' WITH
    'Functions'(s90).
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_funfltr_alv OUTPUT                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_funfltr_alv OUTPUT.
  PERFORM display_funfltr_alv .
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_funfltr OUTPUT                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_funfltr OUTPUT.
  PERFORM fill_sysfun_header.
  PERFORM get_sysfun_existing_data.
  gf_dispchg1 = gf_dispchg.
ENDMODULE.


*---------------------------------------------------------------------*
*       MODULE status_0910 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0910 OUTPUT.
  SET PF-STATUS 'SYSFLTR'.
  SET TITLEBAR 'SYSTIT' WITH
      'Critical Authorizations'(s91).
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_cafltr_alv OUTPUT                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_cafltr_alv OUTPUT.
  PERFORM display_cafltr_alv .
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_cafltr OUTPUT                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_cafltr OUTPUT.
  PERFORM fill_sysca_header.
  PERFORM get_sysca_existing_data.
  gf_dispchg1 = gf_dispchg.
ENDMODULE.


*---------------------------------------------------------------------*
*       MODULE status_0911 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0911 OUTPUT.
  SET PF-STATUS 'SYSFLTR'.
  SET TITLEBAR 'SYSTIT' WITH
       'Critical Transaction'(s92).
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_funfltr_alv OUTPUT                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_tcdfltr_alv OUTPUT.
  PERFORM display_tcdfltr_alv .
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_funfltr OUTPUT                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_tcdfltr OUTPUT.
  PERFORM fill_systcd_header.
  PERFORM get_systcd_existing_data.
  gf_dispchg1 = gf_dispchg.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE mc_active_tab_set OUTPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE mc_active_tab_set OUTPUT.
  tc_md-activetab = g_tc_md-pressed_tab.
  CASE g_tc_md-pressed_tab.
    WHEN c_tc_md-tab1.
      g_tc_md-subscreen = '0226'.
    WHEN c_tc_md-tab2.
      g_tc_md-subscreen = '0227'.
  ENDCASE.
ENDMODULE.

MODULE fn_active_tab_set OUTPUT.
  tc_fiori-activetab = g_tc_md-pressed_tab.
  CASE g_tc_md-pressed_tab.
    WHEN c_tc_md-tab1.
      g_tc_md-subscreen = '0229'.
    WHEN c_tc_md-tab2.
      g_tc_md-subscreen = '0230'.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE load_default_text OUTPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE load_default_text OUTPUT.

  DATA: BEGIN OF lt_txt_lang OCCURS 0,
          spras LIKE stxh-tdspras,
        END OF lt_txt_lang.

  DATA: l_full_lang(2) TYPE c,
        l_cnt_txt(3)   TYPE c,
        ls_mcrvwhdr    TYPE /psyng/mcrvwhdr.
  IF gf_data_change IS INITIAL.
    CLEAR: /psyng/mcrvwhdr.
  ENDIF.
*load review settings
  IF NOT /psyng/mchdr-contid IS INITIAL.
    SELECT SINGLE * FROM /psyng/mcrvwhdr INTO
      /psyng/mcrvwhdr WHERE contid = /psyng/mchdr-contid.

**** default text name
    IF /psyng/mcrvwhdr-dflt_review IS INITIAL.
      se_config_param 'MIT_DFLT_REV_TEXT' g_value.
      /psyng/mcrvwhdr-dflt_review = g_value.
    ENDIF.

    IF NOT /psyng/mcrvwhdr-dflt_review IS INITIAL.
* Determine all languages for text name
* to do add available lang
      SELECT DISTINCT tdspras FROM stxh
             INTO TABLE lt_txt_lang
             WHERE tdname   = /psyng/mcrvwhdr-dflt_review
               AND tdid     = 'ST'
               AND tdobject = 'TEXT'.

      READ TABLE lt_txt_lang WITH KEY spras = sy-langu.
      IF sy-subrc = 0.
        DELETE lt_txt_lang INDEX sy-tabix.
        INSERT lt_txt_lang INDEX 1.
      ENDIF.

      SORT lt_txt_lang BY spras.
      LOOP AT lt_txt_lang FROM 0 TO 3.
        CALL FUNCTION 'CONVERSION_EXIT_ISOLA_OUTPUT'
          EXPORTING
            input  = lt_txt_lang-spras
          IMPORTING
            output = l_full_lang.

        IF sy-tabix = 1.
          lang = l_full_lang.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  set_screen_fields  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_screen_fields OUTPUT.
  DATA : ln TYPE i.
  CASE sy-dynnr.
    WHEN '0212'.
      ln = tc_mcuser-lines.
    WHEN '0222'.
      ln = tc_mcusrgrp-lines.
    WHEN '0223'.
      ln = tc_mccriauth-lines.
    WHEN '0224'.
      ln = tc_mcrole-lines.
    WHEN '0225'.
      ln =   tc_mccarole-lines.
  ENDCASE.
  LOOP AT SCREEN.
    IF ln EQ 0.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.                 " set_screen_fields  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_102_screens  OUTPUT
*&---------------------------------------------------------------------*
*  Hide any tabs based on table /psyng/swinvisbl
*  and auth object Y&SW_TAB
*----------------------------------------------------------------------*
MODULE init_102_screens OUTPUT.

*    clear g_sodfun-pressed_tab.
  PERFORM check_tab_visible USING 'FUNCTIONS' gc_type_tab 'Functions' '201'
                           'SODFUN_FC1' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_sodfun-pressed_tab IS INITIAL.
    g_sodfun-pressed_tab = c_sodfun-tab1.
  ENDIF.

  PERFORM check_tab_visible USING 'CONFLICTS' gc_type_tab 'Conflicts' '202'
                           'SODFUN_FC2' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_sodfun-pressed_tab IS INITIAL.
    g_sodfun-pressed_tab = c_sodfun-tab2.
  ENDIF.

  PERFORM check_tab_visible USING 'MITIGATION' gc_type_tab 'Mitigationg Controls' '204'
                           'MITCON_FC1' 'MITCON_FC2'
                           'MITCON_FC3' 'MITCON_FC4' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_sodfun-pressed_tab IS INITIAL.
    g_sodfun-pressed_tab = c_sodfun-tab4.
  ENDIF.

  PERFORM check_tab_visible USING 'CRITTCODE' gc_type_tab 'Critical Transactions' '205'
                           'SODFUN_FC5' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_sodfun-pressed_tab IS INITIAL.
    g_sodfun-pressed_tab = c_sodfun-tab5.
  ENDIF.

  PERFORM check_tab_visible USING 'CRITAUTH'  gc_type_tab 'Critical Authorizations' '206'
                           'SODFUN_FC6' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_sodfun-pressed_tab IS INITIAL.
    g_sodfun-pressed_tab = c_sodfun-tab6.
  ENDIF.

  PERFORM check_tab_visible USING 'CRITROLE' gc_type_tab  'Critical Roles' '207'
                           'SODFUN_FC7' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_sodfun-pressed_tab IS INITIAL.
    g_sodfun-pressed_tab = c_sodfun-tab7.
  ENDIF.

  PERFORM check_tab_visible USING 'CRITPROF'  gc_type_tab 'Critical Profiles' '208'
                           'SODFUN_FC8' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_sodfun-pressed_tab IS INITIAL.
    g_sodfun-pressed_tab = c_sodfun-tab8.
  ENDIF.


ENDMODULE.                 " init_102_screens  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_invisible_0107  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_invisible_0107 OUTPUT.
  DEFINE check_hide_button.
    perform check_button_visible using &1 &2 &3 &4.
  END-OF-DEFINITION.

  check_hide_button :
*--Group Buttons
    'CONBOX' gc_type_box 'Configuration' '801',
    'REPBOX' gc_type_box 'Conflict Repository' '802',
    'VERBOX' gc_type_box 'Version Management' '803',
    'CMITBOX' gc_type_box 'Mitigations' '804',
    'DIABOX' gc_type_box 'Diagnostics' '805',
    'CORBOX' gc_type_box 'Role Configuration - Hidden by default' '806',
    'RDCBOX' gc_type_box 'Role Management -hidden by default' '807',
    'SETBOX' gc_type_box '' '808',
*--Report Buttons
    '/PSYNG/SW_107'  gc_type_button  'Config Params' '001',
    '/PSYNG/SW_DATA_UPLOAD_DOWNLOAD' gc_type_button 'Upload/Download' '002',
    '/PSYNG/SW_084'  gc_type_button  'Maintain Version Header' '003',
    '/PSYNG/BUSAREA' gc_type_button  'Application Areas' '004',
    '/PSYNG/SW_048'  gc_type_button  'Transport Objects' '005',
    '/PSYNG/SW_080'  gc_type_button  'Copy Versions' '006',
    '/PSYNG/PROCAREA' gc_type_button 'Process Areas' '007',
    '/PSYNG/SW_DELETE_SYSCANDT' gc_type_button 'Delete Scan Details' '008',
    '/PSYNG/SW_081'  gc_type_button 'Compare Versions' '009',
    '/PSYNG/SW_098'  gc_type_button 'Risk Scenarios'   '010',
    '/PSYNG/SW_139'  gc_type_button 'Delete Stored User Results'        '011',
    '/PSYNG/SW_100'  gc_type_button 'Mitigation Types'                  '012',
    '/PSYNG/SW_010'  gc_type_button 'Compare Tcode Roles vs Matrix'     '013',
    '/PSYNG/SW_135'  gc_type_button 'Configuration Sets'                '014',
    '/PSYNG/SW_063'  gc_type_button 'Custom Conflicts'                  '015',
    '/PSYNG/SW_126'  gc_type_button 'Variable Elements in Functions'    '016',
    '/PSYNG/SW_RFC_MAINTAIN_ALV' gc_type_button 'RFC Destinations'      '017',
    '/PSYNG/SW_RFC_MAINTAIN_ALV' gc_type_button 'Systems'               '018',
    '/PSYNG/SW_133'  gc_type_button 'Create Signoff Records'            '019',
    '/PSYNG/SW_FREQUENCY_MAINT' gc_type_button 'Mitigations Frequency'  '020' ,
    '/PSYNG/SW_091'  gc_type_button 'Mitigations Reminder'              '021',
    '/PSYNG/SW_MITIGATION_MONITOR'  gc_type_button 'Mitigations Monitor Job'   '022',
    'RPR_ABAP_SOURCE_SCAN'   gc_type_button 'Finds Strings in ABAP'     '023',
    '/PSYNG/SW_UNUSED_AUTHS' gc_type_button 'List Unused Auths'         '024',
    '/PSYNG/SW_093'          gc_type_button 'Performance Diagnostics'   '025',
    '/PSYNG/CAR'             gc_type_button 'Customer Audit Report'     '026',
    '/PSYNG/SW_050'          gc_type_button 'Org Level Values'          '030',
    '/PSYNG/SW_AUTO_ORG'     gc_type_button 'Auto determine Org Values' '031',
    '/PSYNG/SW_126'          gc_type_button 'Variable Element Rules'    '032',
    '/PSYNG/SW_PRJ01'        gc_type_button 'Project'                   '041',
    '/PSYNG/WEAVSYNC'        gc_type_button 'Synchronize Summary'       '042',
    '/PSYNG/SYNCH_ROLE_POSITION'  gc_type_button 'Copy Roles to positions' '043',
    '/PSYNG/SW_021'          gc_type_button 'Delete role ID’s'          '044',
    '/PSYNG/SW_STA01'        gc_type_button 'Statuses'                  '045',
    '/PSYNG/SE_MAINTAIN_CORG'   gc_type_button 'Custom Org Logic'       '046',
    '/PSYNG/BASIS_LOG_API'     gc_type_button 'Display API Logging'     '047',
    '/PSYNG/BASIS_DEL_LOG_API'  gc_type_button 'Delete API Logging'     '048',
    '/PSYNG/SW_146'          gc_type_button 'Validate Config Set'       '049',
    '/PSYNG/SW_145'          gc_type_button 'Distribute Configuration'  '050',
    '/PSYNG/SW_141'          gc_type_button 'Administrative Overview'   '051',
    '/PSYNG/SW_147'          gc_type_button 'Dynamic Enhancement Buffering' '052',
    '/PSYNG/SW_151'          gc_type_button 'Delete Stored Role Results' '053',
    '/PSYNG/SW_SYSTYP'       gc_type_button 'System Types'               '054',
    '/PSYNG/SW_SYSCAT'       gc_type_button 'System Categories'          '055',
    '/PSYNG/SW_107_2000'     gc_type_button ''                           '056',
    '/PSYNG/BC_BA_MNT'       gc_type_button ''                           '057',
    "BOC UMITTAL 11 Dec 2023
    '/PSYNG/SW_162'          gc_type_button 'Synchronize Matrix'         '058'.
    "EOC UMITTAL 11 Dec 2023


ENDMODULE.                 " init_invisible_0107  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_203_screens  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_203_screens OUTPUT.


*--These checks needs to be done in the order the tabs are displayed
*    clear g_mitcon-pressed_tab.

  PERFORM check_tab_visible USING 'MIT_DEFINE' gc_type_tab
                            'Mitigationg Controls – Define' '211'
                           'MITCON_FC1' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_mitcon-pressed_tab IS INITIAL.
    g_mitcon-pressed_tab = c_mitcon-tab1.
  ENDIF.
  PERFORM check_tab_visible USING 'MIT_A_USER' gc_type_tab
                            'Mitigationg Controls – Assign User' '212'
                           'MITCON_FC2' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_mitcon-pressed_tab IS INITIAL.
    g_mitcon-pressed_tab = c_mitcon-tab2.
  ENDIF.
  PERFORM check_tab_visible USING 'MIT_A_GRP' gc_type_tab
                           'Mitigationg Controls -Assign User Group' '222'
                           'MITCON_FC3' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_mitcon-pressed_tab IS INITIAL.
    g_mitcon-pressed_tab = c_mitcon-tab3.
  ENDIF.

  PERFORM check_tab_visible USING 'MIT_A_ROLE' gc_type_tab
                            'Mitigationg Controls – Assign Role' '224'
                           'MITCON_FC5' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_mitcon-pressed_tab IS INITIAL.
    g_mitcon-pressed_tab = c_mitcon-tab4.
  ENDIF.
  PERFORM check_tab_visible USING 'MIT_A_C_US' gc_type_tab
                            'Mitigationg Controls – Cri Auth Assign User' '223'
                           'MITCON_FC4' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_mitcon-pressed_tab IS INITIAL.
    g_mitcon-pressed_tab = c_mitcon-tab5.
  ENDIF.

  PERFORM check_tab_visible USING 'MIT_A_C_RO' gc_type_tab
                            'Mitigationg Controls – Cri Auth Assign Role' '225'
                           'MITCON_FC6' '' '' '' ''
                           CHANGING lf_hidden.
  IF NOT lf_hidden = 'X' AND g_mitcon-pressed_tab IS INITIAL.
    g_mitcon-pressed_tab = c_mitcon-tab6.
  ENDIF.

  PERFORM check_tab_visible USING 'MIT_AUDIT' gc_type_tab
                            'Mitigationg Controls - Audit' '228'
                           'MITCON_FC7' '' '' '' ''
                           CHANGING lf_hidden.

  IF NOT lf_hidden = 'X' AND g_mitcon-pressed_tab IS INITIAL.
    g_mitcon-pressed_tab = c_mitcon-tab7.
  ENDIF.

ENDMODULE.                 " init_203_screens  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_invisible_101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_invisible_101 OUTPUT.
*--Hide SUPPORT Button?
  check_hide_button :'SUPPORT' gc_type_button 'Security Weaver Support' '100'.
*  check_hide_button :'SUPPORT1' gc_type_button 'Pathlock Support' '100'.

ENDMODULE.                 " init_invisible_101  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  CLEAR_OKCODE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE clear_okcode OUTPUT.
  CLEAR: ok_code, sy-ucomm.
ENDMODULE.
