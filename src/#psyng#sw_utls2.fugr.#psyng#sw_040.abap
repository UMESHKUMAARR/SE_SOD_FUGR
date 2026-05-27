FUNCTION /psyng/sw_040.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_FIELD) TYPE  CHAR35
*"     REFERENCE(I_BNAME) TYPE  USR02-BNAME
*"     REFERENCE(I_AGR_NAME) TYPE  AGR_DEFINE-AGR_NAME
*"     REFERENCE(I_LANGU) TYPE  SPRAS OPTIONAL
*"  TABLES
*"      ET_VALUES STRUCTURE  TLINE
*"----------------------------------------------------------------------
CONSTANTS: lc_erconfig TYPE tabname VALUE '/PSYNG/ER_CONFIG'.

DATA: l_value            TYPE /psyng/param_value,
      l_vrsio            TYPE /psyng/sodvrsio,
      l_class            TYPE usr02-class,
      l_contid           TYPE /psyng/mchdr-contid,
      l_mcdesc           TYPE /psyng/mchdr-description,
      lt_user            TYPE TABLE OF /psyng/sw_sel_opts_xubname
                         WITH HEADER LINE,
      lt_simu_role       TYPE TABLE OF /psyng/sw_sod_remote_roles
                         WITH HEADER LINE,
      lt_output          TYPE TABLE OF /PSYNG/SW_SOD_OUTPUT_ORG
                         WITH HEADER LINE,
      lt_output_critcode TYPE TABLE OF /psyng/sw_critcode_output
                         WITH HEADER LINE.

* Get SOD version from ER config
  SELECT SINGLE value INTO l_value FROM (lc_erconfig)
              WHERE param = 'CONFIG_SOD_VRSIO'."#EC SAST_CI_GEN_CHECK
  l_vrsio = l_value.

  IF i_field = '[S:SOD_VRSIO]'.
    et_values-tdline = l_vrsio.
    APPEND et_values.
    EXIT.
  ENDIF.

  lt_user-sign   = 'I'.
  lt_user-option = 'EQ'.
  lt_user-low    = i_bname.
  APPEND lt_user.

  lt_simu_role-rfcdest  = 'LOCAL'.
  lt_simu_role-agr_name = i_agr_name.
  APPEND lt_simu_role.


  CASE i_field.
    WHEN '[M:SOD_CONFLICT_TEXT]' OR
         '[M:SOD_CONFLICT_ID_AND_TEXT]' OR
         '[M:SOD_CONFLICT_ID]' OR
         '[M:SOD_MITIGATION_ID]' OR
         '[M:SOD_MITIGATION_ID_TEXT]' OR
         '[M:SOD_MITIGATION_ID_AND_TEXT]'.

      CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
           EXPORTING
                i_vrsio            = l_vrsio
                I_SHOMIT           = 'X'
*                I_ANALYZE_SAP_ALL  = 'X'
                I_OUTPUT           = 'X'
           TABLES
                it_users         = lt_user
                ET_OUTPUTDET     = lt_output
*                simu_role_rfc_fm = lt_simu_role.
                IT_SIMU_ROLE_RFC = lt_simu_role.

      CASE i_field.

        WHEN '[M:SOD_CONFLICT_ID]'.
          LOOP AT lt_output.
            et_values-tdline = lt_output-conid.
            APPEND et_values.
          ENDLOOP.


        WHEN '[M:SOD_CONFLICT_TEXT]'.
          LOOP AT lt_output.
            et_values-tdline = lt_output-CONDESC.
            APPEND et_values.
          ENDLOOP.

        WHEN '[M:SOD_CONFLICT_ID_AND_TEXT]'.
          LOOP AT lt_output.
            CONCATENATE lt_output-conid lt_output-CONDESC
                        INTO et_values-tdline SEPARATED BY space.
            APPEND et_values.
          ENDLOOP.

        WHEN '[M:SOD_MITIGATION_ID]' OR '[M:SOD_MITIGATION_ID_TEXT]'
          OR '[M:SOD_MITIGATION_ID_AND_TEXT]'.

          LOOP AT lt_output.
*           Check if conflict is assigned to this user
            SELECT hdr~contid hdr~description      "#EC CI_SEL_NESTED
                  INTO (l_contid, l_mcdesc)
              FROM /psyng/mcuser AS user
             INNER JOIN /psyng/mchdr AS hdr
                ON user~contid = hdr~contid
             WHERE user~conid      = lt_output-conid
               AND user~userid     = i_bname
               AND user~vrsio      = l_vrsio
               AND user~from_date <= sy-datum
               AND user~to_date   >= sy-datum.

              CASE i_field.
                WHEN '[M:SOD_MITIGATION_ID]'.
                  et_values-tdline = l_contid.
                WHEN '[M:SOD_MITIGATION_ID_TEXT]'.
              SELECT SINGLE description             "#EC CI_SEL_NESTED
                        INTO l_mcdesc FROM /psyng/mchdr
                                WHERE contid = l_contid.
                  et_values-tdline = l_mcdesc.
                WHEN '[M:SOD_MITIGATION_ID_AND_TEXT]'.
                  CONCATENATE l_contid l_mcdesc
                              INTO et_values-tdline SEPARATED BY space.
              ENDCASE.

              CHECK NOT et_values-tdline IS INITIAL.
              APPEND et_values.
            ENDSELECT.

            CHECK sy-subrc <> 0.

*           Check if conflict is assigned to user group
            SELECT SINGLE class                      "#EC CI_SEL_NESTED
                      INTO l_class FROM usr02
                          WHERE bname = i_bname.

            SELECT hdr~contid hdr~description         "#EC CI_SEL_NESTED
                       INTO (l_contid, l_mcdesc)
              FROM /psyng/mcusrgrp AS ugrp
             INNER JOIN /psyng/mchdr AS hdr
                ON ugrp~contid = hdr~contid
             WHERE ugrp~conid      = lt_output-conid
               AND ugrp~class      = l_class
               AND ugrp~vrsio      = l_vrsio
               AND ugrp~from_date <= sy-datum
               AND ugrp~to_date   >= sy-datum.

              CASE i_field.
                WHEN '[M:SOD_MITIGATION_ID]'.
                  et_values-tdline = l_contid.
                WHEN '[M:SOD_MITIGATION_ID_TEXT]'.
              SELECT SINGLE description              "#EC CI_SEL_NESTED
                      INTO l_mcdesc FROM /psyng/mchdr
                                WHERE contid = l_contid.
                  et_values-tdline = l_mcdesc.
                WHEN '[M:SOD_MITIGATION_ID_AND_TEXT]'.
                  CONCATENATE l_contid l_mcdesc
                              INTO et_values-tdline SEPARATED BY space.
              ENDCASE.

              CHECK NOT et_values-tdline IS INITIAL.
              APPEND et_values.
            ENDSELECT.
          ENDLOOP.
      ENDCASE.

    WHEN '[M:CRI_TCODE]' OR '[M:CRI_TCODE_TEXT]'
      OR '[M:CRI_TCODE_AND_TEXT]'.

      CALL FUNCTION '/PSYNG/SW_042'
           EXPORTING
                i_sodvrsio       = l_vrsio
                i_userid         = i_bname
                i_langu          = i_langu
           TABLES
                ot_output        = lt_output_critcode
                it_simu_role_rfc = lt_simu_role.

      CASE i_field.
        WHEN '[M:CRI_TCODE]'.
          LOOP AT lt_output_critcode.
            et_values-tdline = lt_output_critcode-tcode.
            APPEND et_values.
          ENDLOOP.

        WHEN '[M:CRI_TCODE_TEXT]'.
          LOOP AT lt_output_critcode.
            et_values-tdline = lt_output_critcode-ttext.
            APPEND et_values.
          ENDLOOP.

        WHEN '[M:CRI_TCODE_AND_TEXT]'.
          LOOP AT lt_output_critcode.
            CONCATENATE lt_output_critcode-tcode
                        lt_output_critcode-ttext
                        INTO et_values-tdline SEPARATED BY space.
            APPEND et_values.
          ENDLOOP.

      ENDCASE.
  ENDCASE.
ENDFUNCTION.
