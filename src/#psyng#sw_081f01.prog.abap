*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_081F01                                           *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  compare_functions
*&---------------------------------------------------------------------*
*       Select and compare functions
*----------------------------------------------------------------------*
FORM compare_functions.
  DATA: lf_diff         TYPE /psyng/bapiflagx,
        lf_func_written TYPE /psyng/bapiflagx,
        lf_hdr_written  TYPE /psyng/bapiflagx,
        l_func_idx      TYPE i,
        l_tran_idx      TYPE i,
        l_obj_idx       TYPE i,
        l_lcount        TYPE i,
        l_rcount        TYPE i,
        lt_lfuncttran   TYPE TABLE OF /psyng/functtran, "Left tcodes
        lt_rfuncttran   TYPE TABLE OF /psyng/functtran, "Right tcodes
        lt_lfaobj       TYPE TABLE OF /psyng/faobj2,    "Left objects
        lt_rfaobj       TYPE TABLE OF /psyng/faobj2,    "Right objects
        lt_ltexts       TYPE TABLE OF /psyng/texts,     "Left texts
        lt_rtexts       TYPE TABLE OF /psyng/texts.     "Right texts

  FIELD-SYMBOLS: <lfunc> TYPE /psyng/function,
                 <rfunc> TYPE /psyng/function,
                 <tran>  TYPE /psyng/functtran,
                 <lobj>  TYPE /psyng/faobj2,
                 <robj>  TYPE /psyng/faobj2,
                 <text>  TYPE /psyng/texts.


  CHECK p_cfunc = 'X'.

***********************************************
**Authorization check for Displaying SW Functions
**SF 1665
  AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
            ID 'ACTVT' FIELD '03'
            ID 'Y&SW_VRSIO' FIELD p_lvrsio
            ID 'Y&SW_FUNCT' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
            ID 'ACTVT' FIELD '03'
            ID 'Y&SW_VRSIO' FIELD p_rvrsio
            ID 'Y&SW_FUNCT' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc EQ 0.
    ELSE.
      MESSAGE e113(/psyng/sw) WITH text-e03 p_rvrsio.
      STOP.
    ENDIF.
  ELSE.
    MESSAGE e113(/psyng/sw) WITH text-e03 p_lvrsio.
    STOP.
  ENDIF.
***SF 1665
***********************************************

  PERFORM write_section_heading USING text-h12.

*  SELECT * INTO TABLE gt_lfunction FROM /psyng/function
*         WHERE vrsio = p_lvrsio.
*  SELECT * INTO TABLE gt_rfunction FROM /psyng/function
*         WHERE vrsio = p_rvrsio.

  SELECT function description owner busarea
         INTO CORRESPONDING FIELDS OF TABLE gt_lfunction
          FROM /psyng/function
          WHERE vrsio = p_lvrsio.

  SELECT function description owner busarea
   INTO CORRESPONDING FIELDS OF TABLE gt_rfunction
      FROM /psyng/function
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_lfuncttran FROM /psyng/functtran
         WHERE vrsio = p_lvrsio.
  SELECT * INTO TABLE lt_rfuncttran FROM /psyng/functtran
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_lfaobj FROM /psyng/faobj2
         WHERE vrsio = p_lvrsio.
  SELECT * INTO TABLE lt_rfaobj FROM /psyng/faobj2
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_ltexts FROM /psyng/texts
         WHERE object = 'F'
           AND vrsio  = p_lvrsio.
  SELECT * INTO TABLE lt_rtexts FROM /psyng/texts
         WHERE object = 'F'
           AND vrsio  = p_rvrsio.

  SORT: gt_lfunction  BY function,
        gt_rfunction  BY function,
        lt_lfuncttran BY functionid tcode,
        lt_rfuncttran BY functionid tcode,
        lt_lfaobj     BY funid tcode object valueset field val_from
                         val_to,
        lt_rfaobj     BY funid tcode object valueset field val_from
                         val_to,
        lt_ltexts     BY textname spras line,
        lt_rtexts     BY textname spras line.

* Compare headers
  LOOP AT gt_lfunction ASSIGNING <lfunc>.
    CLEAR: lf_diff, lf_hdr_written, lf_func_written.

    READ TABLE gt_rfunction ASSIGNING <rfunc>
               WITH KEY function = <lfunc>-function BINARY SEARCH.
    l_func_idx = sy-tabix.

    IF sy-subrc <> 0.
      APPEND <lfunc> TO gt_lmfunction.

      IF g_format <> 'LIST'.
*       Save tcodes, objects and texts for tree
        LOOP AT lt_lfuncttran ASSIGNING <tran>
                WHERE functionid = <lfunc>-function.
          MOVE-CORRESPONDING <tran> TO gt_ldtran.
          APPEND gt_ldtran.
        ENDLOOP.
        LOOP AT lt_lfaobj ASSIGNING <lobj>
                WHERE funid = <lfunc>-function.
          APPEND <lobj> TO gt_ldfaobj.
        ENDLOOP.
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lfunc>-function.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
      ENDIF.                      "List output

      DELETE gt_lfunction.
      CONTINUE.
    ENDIF.

*   Compare each header field
    PERFORM compare_header_field USING <lfunc> <rfunc> 'FUNCTION'
                                       'DESCRIPTION' text-h02
                                 CHANGING lf_func_written lf_hdr_written
                                          lf_diff.
    PERFORM compare_header_field USING <lfunc> <rfunc> 'FUNCTION'
                                       'OWNER' text-h03
                                 CHANGING lf_func_written lf_hdr_written
                                          lf_diff.
    PERFORM compare_header_field USING <lfunc> <rfunc> 'FUNCTION'
                                       'BUSAREA' text-h04
                                 CHANGING lf_func_written lf_hdr_written
                                          lf_diff.

*   Compare transactions
    LOOP AT lt_lfuncttran ASSIGNING <tran>
            WHERE functionid = <lfunc>-function.

      READ TABLE lt_rfuncttran WITH KEY functionid = <tran>-functionid
                                        tcode      = <tran>-tcode
                 BINARY SEARCH TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        lf_diff = 'X'.
        gt_ldtran-functionid = <tran>-functionid.
        gt_ldtran-tcode      = <tran>-tcode.
        APPEND gt_ldtran.
      ELSE.
        l_tran_idx = sy-tabix.

        LOOP AT lt_lfaobj ASSIGNING <lobj>
                WHERE funid = <tran>-functionid
                  AND tcode = <tran>-tcode.

          READ TABLE lt_rfaobj WITH KEY funid    = <lobj>-funid
                                        tcode    = <lobj>-tcode
                                        object   = <lobj>-object
                                        valueset = <lobj>-valueset
                                        field    = <lobj>-field
                                        val_from = <lobj>-val_from
                                        val_to   = <lobj>-val_to
                                        obj_or   = <lobj>-obj_or
                                        fld_and  = <lobj>-fld_and
                     BINARY SEARCH TRANSPORTING NO FIELDS.

          IF sy-subrc <> 0.
            lf_diff = 'X'.
            APPEND <lobj> TO gt_ldfaobj.
          ELSE.
            l_obj_idx = sy-tabix.
            DELETE lt_lfaobj.
            DELETE lt_rfaobj INDEX l_obj_idx.
          ENDIF.
        ENDLOOP.

*       Check for object records that are missing from the left version
        LOOP AT lt_rfaobj ASSIGNING <robj>
                          WHERE funid = <lfunc>-function
                            AND tcode = <tran>-tcode.
          APPEND <robj> TO gt_rdfaobj.
        ENDLOOP.

        IF sy-subrc = 0.
          lf_diff = 'X'.
        ENDIF.

        DELETE lt_lfuncttran.
        DELETE lt_rfuncttran INDEX l_tran_idx.
      ENDIF.
    ENDLOOP.

*   Check for any tcode records that are missing from the left version
    LOOP AT lt_rfuncttran ASSIGNING <tran>
            WHERE functionid = <lfunc>-function.
      gt_rdtran-functionid = <tran>-functionid.
      gt_rdtran-tcode      = <tran>-tcode.
      APPEND gt_rdtran.
    ENDLOOP.

    IF sy-subrc = 0.
      lf_diff = 'X'.
    ENDIF.

    IF g_format = 'LIST'.         "List output
      DO.
        READ TABLE gt_ldtran INDEX sy-index.
        IF sy-subrc = 0.
          PERFORM write_header USING <lfunc> <rfunc> 'FUNCTION'
                               CHANGING lf_func_written.

          IF sy-index = 1.
            WRITE: /5   text-h05,
                    135 sy-vline,
                    141 text-h05.
          ENDIF.

          WRITE: /10  gt_ldtran-tcode,
                  135 sy-vline.

          READ TABLE gt_rdtran INDEX sy-index.
          CHECK sy-subrc = 0.
          WRITE: 146 gt_rdtran-tcode.
        ELSE.
          READ TABLE gt_rdtran INDEX sy-index.
          IF sy-subrc = 0.
            PERFORM write_header USING <lfunc> <rfunc> 'FUNCTION'
                                 CHANGING lf_func_written.

            IF sy-index = 1.
              WRITE: /5   text-h05,
                      135 sy-vline,
                      141 text-h05.
            ENDIF.

            WRITE: /135 sy-vline,
                    146 gt_rdtran-tcode.
          ELSE.
            EXIT.
          ENDIF.
        ENDIF.
      ENDDO.

      DO.
        READ TABLE gt_ldfaobj ASSIGNING <lobj> INDEX sy-index.
        IF sy-subrc = 0.
          PERFORM write_header USING <lfunc> <rfunc> 'FUNCTION'
                               CHANGING lf_func_written.

          IF sy-index = 1.
            WRITE: /5   text-h06,
                    135 sy-vline,
                    141 text-h06.
          ENDIF.

          WRITE: /10 <lobj>-tcode,
                     <lobj>-object,
                     <lobj>-valueset,
                     <lobj>-field,
                     <lobj>-val_from,
                     <lobj>-val_to,
                 135 sy-vline.

          READ TABLE gt_rdfaobj ASSIGNING <robj> INDEX sy-index.
          CHECK sy-subrc = 0.
          WRITE: 146 <robj>-tcode,
                     <robj>-object,
                     <robj>-valueset,
                     <robj>-field,
                     <robj>-val_from,
                     <robj>-val_to.
        ELSE.
          READ TABLE gt_rdfaobj ASSIGNING <robj> INDEX sy-index.
          IF sy-subrc = 0.
            PERFORM write_header USING <lfunc> <rfunc> 'FUNCTION'
                                 CHANGING lf_func_written.

            IF sy-index = 1.
              WRITE: /5   text-h06,
                      135 sy-vline,
                      141 text-h06.
            ENDIF.

            WRITE: /135 sy-vline,
                    146 <robj>-tcode,
                        <robj>-object,
                        <robj>-valueset,
                        <robj>-field,
                        <robj>-val_from,
                        <robj>-val_to.
          ELSE.
            EXIT.
          ENDIF.
        ENDIF.
      ENDDO.

*     Only refresh when using list output
      REFRESH: gt_ldtran, gt_rdtran, gt_ldfaobj, gt_rdfaobj.
    ENDIF.                        "List output

*   Compare texts
    REFRESH: gt_ldtexts, gt_rdtexts.
    LOOP AT lt_ltexts ASSIGNING <text>
            WHERE textname = <lfunc>-function.
      MOVE-CORRESPONDING <text> TO gt_ldtexts.
      APPEND gt_ldtexts.
    ENDLOOP.
    LOOP AT lt_rtexts ASSIGNING <text>
            WHERE textname = <lfunc>-function.
      MOVE-CORRESPONDING <text> TO gt_rdtexts.
      APPEND gt_rdtexts.
    ENDLOOP.

    IF gt_ldtexts[] <> gt_rdtexts[].
      lf_diff = 'X'.
      IF g_format = 'LIST'.       "List output
        PERFORM write_header USING <lfunc> <rfunc> 'FUNCTION'
                             CHANGING lf_func_written.
        WRITE: /5   text-h09,
                135 sy-vline,
                141 text-h09.
        DO.
          READ TABLE gt_ldtexts INDEX sy-index.
          IF sy-subrc = 0.
            WRITE: /10 gt_ldtexts-spras,
                       gt_ldtexts-text,
                       135 sy-vline.

            READ TABLE gt_rdtexts INDEX sy-index.
            CHECK sy-subrc = 0.
            WRITE: 146 gt_rdtexts-spras,
                       gt_rdtexts-text.
          ELSE.
            READ TABLE gt_rdtexts INDEX sy-index.
            IF sy-subrc = 0.
              WRITE: /135 sy-vline,
                      146 gt_rdtexts-spras,
                          gt_rdtexts-text.
            ELSE.
              EXIT.
            ENDIF.
          ENDIF.
        ENDDO.
      ELSE.                       "Tree output
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lfunc>-function.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
        LOOP AT lt_rtexts ASSIGNING <text>
                WHERE textname = <lfunc>-function.
          APPEND <text> TO gt_rdisptext.
        ENDLOOP.
      ENDIF.                      "List output
    ENDIF.

    IF lf_diff IS INITIAL.
      APPEND <lfunc> TO gt_sfunction.
      DELETE gt_lfunction.
      DELETE gt_rfunction INDEX l_func_idx.
    ENDIF.
  ENDLOOP.

* Check for any records that are missing from the left version
  LOOP AT gt_rfunction ASSIGNING <rfunc>.
    READ TABLE gt_lfunction WITH KEY function = <rfunc>-function
               BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    APPEND <rfunc> TO gt_rmfunction.

    IF g_format <> 'LIST'.
*     Save tcodes, objects and texts for tree
      LOOP AT lt_rfuncttran ASSIGNING <tran>
              WHERE functionid = <rfunc>-function.
        MOVE-CORRESPONDING <tran> TO gt_rdtran.
        APPEND gt_rdtran.
      ENDLOOP.
      LOOP AT lt_rfaobj ASSIGNING <robj>
              WHERE funid = <rfunc>-function.
        APPEND <robj> TO gt_rdfaobj.
      ENDLOOP.
      LOOP AT lt_rtexts ASSIGNING <text>
              WHERE textname = <rfunc>-function.
        APPEND <text> TO gt_rdisptext.
      ENDLOOP.
    ENDIF.

    DELETE gt_rfunction.
  ENDLOOP.

* Output missing rows from each version
  CHECK g_format = 'LIST'.
  DESCRIBE TABLE gt_lmfunction LINES l_lcount.
  DESCRIBE TABLE gt_rmfunction LINES l_rcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h07,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h07,
              p_lvrsio,
              '(',
              l_rcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  DO.
    READ TABLE gt_lmfunction ASSIGNING <lfunc> INDEX sy-index.
    IF sy-subrc = 0.
      WRITE: /10 <lfunc>-function,
                 <lfunc>-description,
             135 sy-vline.

      READ TABLE gt_rmfunction ASSIGNING <rfunc> INDEX sy-index.
      CHECK sy-subrc = 0.
      WRITE: 146 <rfunc>-function,
                 <rfunc>-description.
    ELSE.
      READ TABLE gt_rmfunction ASSIGNING <rfunc> INDEX sy-index.
      IF sy-subrc = 0.
        WRITE: /135 sy-vline,
                146 <rfunc>-function,
                    <rfunc>-description.
      ELSE.
        EXIT.
      ENDIF.
    ENDIF.
  ENDDO.

* Output identical functions
  DESCRIBE TABLE gt_sfunction LINES l_lcount.
  WRITE: /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h08,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h08,
              p_lvrsio,
              '(',
              l_lcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  LOOP AT gt_sfunction ASSIGNING <lfunc>.
    WRITE: /10  <lfunc>-function,
                <lfunc>-description,
            135 sy-vline,
            146 <lfunc>-function,
                <lfunc>-description.
  ENDLOOP.
ENDFORM.                    " compare_functions

*&---------------------------------------------------------------------*
*&      Form  compare_conflicts
*&---------------------------------------------------------------------*
*       Select and compare conflicts
*----------------------------------------------------------------------*
FORM compare_conflicts.
  DATA: lf_diff         TYPE /psyng/bapiflagx,
        lf_conf_written TYPE /psyng/bapiflagx,
        lf_func_written TYPE /psyng/bapiflagx,
        lf_hdr_written  TYPE /psyng/bapiflagx,
        l_con_idx       TYPE i,
        l_func_idx      TYPE i,
        l_lcount        TYPE i,
        l_rcount        TYPE i,
        lt_lconfdet     TYPE TABLE OF /psyng/confdet,   "Left functions
        lt_rconfdet     TYPE TABLE OF /psyng/confdet,   "Right functions
        lt_ltexts       TYPE TABLE OF /psyng/texts,     "Left texts
        lt_rtexts       TYPE TABLE OF /psyng/texts.     "Right texts

  FIELD-SYMBOLS: <lconf> TYPE /psyng/conflict,
                 <rconf> TYPE /psyng/conflict,
                 <det>   TYPE /psyng/confdet,
                 <text>  TYPE /psyng/texts.


  CHECK p_cconf = 'X'.

***********************************************
**Authorization check for Displaying SW Conflicts
**SF 1665
  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD p_lvrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
               ID 'ACTVT' FIELD '03'
               ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_VRSIO' FIELD p_rvrsio.
    IF sy-subrc EQ 0.
    ELSE.
      MESSAGE e113(/psyng/sw) WITH text-e04 p_rvrsio.
      STOP.
    ENDIF.
  ELSE.
    MESSAGE e113(/psyng/sw) WITH text-e04 p_lvrsio.
    STOP.
  ENDIF.
***SF 1665
***********************************************

  PERFORM write_section_heading USING text-h13.

*  SELECT * INTO TABLE gt_lconflict FROM /psyng/conflict
*         WHERE vrsio = p_lvrsio.
*  SELECT * INTO TABLE gt_rconflict FROM /psyng/conflict
*         WHERE vrsio = p_rvrsio.

  SELECT conid description inactive owner busarea imp contid
   INTO CORRESPONDING FIELDS OF TABLE gt_lconflict
    FROM /psyng/conflict
         WHERE vrsio = p_lvrsio.
  SELECT conid description inactive owner busarea imp contid
   INTO CORRESPONDING FIELDS OF TABLE gt_rconflict
     FROM /psyng/conflict
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_lconfdet FROM /psyng/confdet
         WHERE vrsio = p_lvrsio.
  SELECT * INTO TABLE lt_rconfdet FROM /psyng/confdet
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_ltexts FROM /psyng/texts
         WHERE object = 'C'
           AND vrsio  = p_lvrsio.
  SELECT * INTO TABLE lt_rtexts FROM /psyng/texts
         WHERE object = 'C'
           AND vrsio  = p_rvrsio.

  SORT: gt_lconflict BY conid,
        gt_rconflict BY conid,
        lt_lconfdet  BY conid functionid,
        lt_rconfdet  BY conid functionid,
        lt_ltexts    BY textname spras line,
        lt_rtexts    BY textname spras line.

* Compare headers
  LOOP AT gt_lconflict ASSIGNING <lconf>.
    CLEAR: lf_diff, lf_hdr_written, lf_func_written.

    READ TABLE gt_rconflict ASSIGNING <rconf>
               WITH KEY conid = <lconf>-conid BINARY SEARCH.
    l_con_idx = sy-tabix.

    IF sy-subrc <> 0.
      APPEND <lconf> TO gt_lmconflict.

      IF g_format <> 'LIST'.
*       Save functions and texts for tree
        LOOP AT lt_lconfdet ASSIGNING <det>
                WHERE conid = <lconf>-conid.
          gt_lddet-conid = <det>-conid.
          gt_lddet-funid = <det>-functionid.
          APPEND gt_lddet.
        ENDLOOP.
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lconf>-conid.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
      ENDIF.

      DELETE gt_lconflict.
      CONTINUE.
    ENDIF.

*   Compare each header field
    PERFORM compare_header_field USING <lconf> <rconf> 'CONID'
                                       'DESCRIPTION' text-h02
                                 CHANGING lf_conf_written lf_hdr_written
                                          lf_diff.
    PERFORM compare_header_field USING <lconf> <rconf> 'CONID' 'OWNER'
                                       text-h03
                                 CHANGING lf_conf_written lf_hdr_written
                                          lf_diff.
   PERFORM compare_header_field USING <lconf> <rconf> 'CONID' 'BUSAREA'
                                               text-h04
                                CHANGING lf_conf_written lf_hdr_written
                                                  lf_diff.
    PERFORM compare_header_field USING <lconf> <rconf> 'CONID' 'IMP'
                                       text-h10
                                 CHANGING lf_conf_written lf_hdr_written
                                          lf_diff.
    PERFORM compare_header_field USING <lconf> <rconf> 'CONID' 'CONTID'
                                       text-h11
                                 CHANGING lf_conf_written lf_hdr_written
                                          lf_diff.
    IF <lconf>-inactive <> <rconf>-inactive.
      lf_diff = 'X'.

      IF g_format = 'LIST'.       "List output
        PERFORM write_header USING <lconf> <rconf> 'CONID'
                             CHANGING lf_hdr_written.
        IF lf_hdr_written IS INITIAL.
          lf_hdr_written = 'X'.
          WRITE: /5   text-h01,
                  135 sy-vline,
                  141 text-h01.
        ENDIF.

        IF <lconf>-inactive = 'X'.
          WRITE: /10  text-004,
                  135 sy-vline,
                  146 text-003.
        ELSE.
          WRITE: /10  text-003,
                  135 sy-vline,
                  146 text-004.
        ENDIF.
      ENDIF.                      "List output
    ENDIF.

*   Compare functions
    LOOP AT lt_lconfdet ASSIGNING <det> WHERE conid = <lconf>-conid.

      READ TABLE lt_rconfdet WITH KEY conid      = <det>-conid
                                      functionid = <det>-functionid
                 BINARY SEARCH TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        lf_diff = 'X'.
        gt_lddet-conid = <det>-conid.
        gt_lddet-funid = <det>-functionid.
        APPEND gt_lddet.
      ELSE.
        l_func_idx = sy-tabix.
        DELETE lt_lconfdet.
        DELETE lt_rconfdet INDEX l_func_idx.
      ENDIF.
    ENDLOOP.

*   Check for any tcode records that are missing from the left version
    LOOP AT lt_rconfdet ASSIGNING <det> WHERE conid = <lconf>-conid.
      gt_rddet-conid = <det>-conid.
      gt_rddet-funid = <det>-functionid.
      APPEND gt_rddet.
    ENDLOOP.

    IF sy-subrc = 0.
      lf_diff = 'X'.
    ENDIF.

    IF g_format = 'LIST'.         "List output
      DO.
        READ TABLE gt_lddet INDEX sy-index.
        IF sy-subrc = 0.
          PERFORM write_header USING <lconf> <rconf> 'CONID'
                                        CHANGING lf_func_written.

          IF sy-index = 1.
            WRITE: /5   text-h05,
                    135 sy-vline,
                    141 text-h05.
          ENDIF.

          WRITE: /10  gt_lddet-funid,
                  135 sy-vline.

          READ TABLE gt_rddet INDEX sy-index.
          CHECK sy-subrc = 0.
          WRITE: 146 gt_rddet-funid.
        ELSE.
          READ TABLE gt_rddet INDEX sy-index.
          IF sy-subrc = 0.
            PERFORM write_header USING <lconf> <rconf> 'CONID'
                                 CHANGING lf_func_written.

            IF sy-index = 1.
              WRITE: /5   text-h05,
                      135 sy-vline,
                      141 text-h05.
            ENDIF.

            WRITE: /135 sy-vline,
                    146 gt_rddet-funid.
          ELSE.
            EXIT.
          ENDIF.
        ENDIF.
      ENDDO.

*     Only refresh when using list output
      REFRESH: gt_lddet, gt_rddet.
    ENDIF.                        "List output

*   Compare texts
    REFRESH: gt_ldtexts, gt_rdtexts.
    LOOP AT lt_ltexts ASSIGNING <text>
            WHERE textname = <lconf>-conid.
      MOVE-CORRESPONDING <text> TO gt_ldtexts.
      APPEND gt_ldtexts.
    ENDLOOP.
    LOOP AT lt_rtexts ASSIGNING <text>
            WHERE textname = <lconf>-conid.
      MOVE-CORRESPONDING <text> TO gt_rdtexts.
      APPEND gt_rdtexts.
    ENDLOOP.

    IF gt_ldtexts[] <> gt_rdtexts[].
      lf_diff = 'X'.

      IF g_format = 'LIST'.       "List output
        PERFORM write_header USING <lconf> <rconf> 'CONID'
                             CHANGING lf_func_written.
        WRITE: /5   text-h09,
                135 sy-vline,
                141 text-h09.
        DO.
          READ TABLE gt_ldtexts INDEX sy-index.
          IF sy-subrc = 0.
            WRITE: /10  gt_ldtexts-spras,
                        gt_ldtexts-text,
                    135 sy-vline.

            READ TABLE gt_rdtexts INDEX sy-index.
            CHECK sy-subrc = 0.
            WRITE: 146 gt_rdtexts-spras,
                       gt_rdtexts-text.
          ELSE.
            READ TABLE gt_rdtexts INDEX sy-index.
            IF sy-subrc = 0.
              WRITE: /135 sy-vline,
                      146 gt_rdtexts-spras,
                          gt_rdtexts-text.
            ELSE.
              EXIT.
            ENDIF.
          ENDIF.
        ENDDO.
      ELSE.                       "Tree output
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lconf>-conid.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
        LOOP AT lt_rtexts ASSIGNING <text>
                WHERE textname = <lconf>-conid.
          APPEND <text> TO gt_rdisptext.
        ENDLOOP.
      ENDIF.                      "List output
    ENDIF.

    IF lf_diff IS INITIAL.
      APPEND <lconf> TO gt_sconflict.
      DELETE gt_lconflict.
      DELETE gt_rconflict INDEX l_con_idx.
    ENDIF.
  ENDLOOP.

* Check for any records that are missing from the left version
  LOOP AT gt_rconflict ASSIGNING <rconf>.
    READ TABLE gt_lconflict WITH KEY conid = <rconf>-conid
               BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    APPEND <rconf> TO gt_rmconflict.

    IF g_format <> 'LIST'.
*     Save functions and texts for tree
      LOOP AT lt_rconfdet ASSIGNING <det>
              WHERE conid = <rconf>-conid.
        gt_rddet-conid = <det>-conid.
        gt_rddet-funid = <det>-functionid.
        APPEND gt_rddet.
      ENDLOOP.
      LOOP AT lt_rtexts ASSIGNING <text>
              WHERE textname = <rconf>-conid.
        APPEND <text> TO gt_rdisptext.
      ENDLOOP.
    ENDIF.

    DELETE gt_rconflict.
  ENDLOOP.

* Output missing rows from each version
  CHECK g_format = 'LIST'.
  DESCRIBE TABLE gt_lmconflict LINES l_lcount.
  DESCRIBE TABLE gt_rmconflict LINES l_rcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h07,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h07,
              p_lvrsio,
              '(',
              l_rcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  DO.
    READ TABLE gt_lmconflict ASSIGNING <lconf> INDEX sy-index.
    IF sy-subrc = 0.
      WRITE: /10  <lconf>-conid,
                  <lconf>-description,
              135 sy-vline.

      READ TABLE gt_rmconflict ASSIGNING <rconf> INDEX sy-index.
      CHECK sy-subrc = 0.
      WRITE: 146 <rconf>-conid,
                 <rconf>-description.
    ELSE.
      READ TABLE gt_rmconflict ASSIGNING <rconf> INDEX sy-index.
      IF sy-subrc = 0.
        WRITE: /135 sy-vline,
                146 <rconf>-conid,
                    <rconf>-description.
      ELSE.
        EXIT.
      ENDIF.
    ENDIF.
  ENDDO.

* Output identical conflicts
  DESCRIBE TABLE gt_sconflict LINES l_lcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h08,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h08,
              p_lvrsio,
              '(',
              l_lcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  LOOP AT gt_sconflict ASSIGNING <lconf>.
    WRITE: /10  <lconf>-conid,
                <lconf>-description,
            135 sy-vline,
            146 <lconf>-conid,
                <lconf>-description.
  ENDLOOP.
ENDFORM.                    " compare_conflicts

*&---------------------------------------------------------------------*
*&      Form  compare_crit_tcodes
*&---------------------------------------------------------------------*
*       Select and compare critical tcodes
*----------------------------------------------------------------------*
FORM compare_crit_tcodes.
  DATA: lf_diff         TYPE /psyng/bapiflagx,
        lf_hdr_written  TYPE /psyng/bapiflagx,
        lf_dummy        TYPE /psyng/bapiflagx,
        l_tran_idx      TYPE i,
        l_lcount        TYPE i,
        l_rcount        TYPE i,
        lt_ltran        TYPE TABLE OF /psyng/critcodes, "Left header
        lt_rtran        TYPE TABLE OF /psyng/critcodes, "Right header
        lt_ltexts       TYPE TABLE OF /psyng/texts, "left text
        lt_rtexts       TYPE TABLE OF /psyng/texts. " right texts

  FIELD-SYMBOLS: <ltran> TYPE /psyng/critcodes,
                 <rtran> TYPE /psyng/critcodes,
                 <text>  TYPE /psyng/texts.


  CHECK p_ctran = 'X'.

***********************************************
**Authorization check for Displaying SW Critical TCodes
**SF 1665
  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_VRSIO' FIELD p_lvrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_VRSIO' FIELD p_rvrsio.
    IF sy-subrc EQ 0.
    ELSE.
      MESSAGE e113(/psyng/sw) WITH text-e05 p_rvrsio.
      STOP.
    ENDIF.
  ELSE.
    MESSAGE e113(/psyng/sw) WITH text-e05 p_lvrsio.
    STOP.
  ENDIF.
***SF 1665
***********************************************

  PERFORM write_section_heading USING text-h14.

*  SELECT * INTO TABLE lt_ltran FROM /psyng/critcodes
*         WHERE vrsio = p_lvrsio.
*  SELECT * INTO TABLE lt_rtran FROM /psyng/critcodes
*         WHERE vrsio = p_rvrsio.

  SELECT tcode imp owner busarea
  INTO CORRESPONDING FIELDS OF TABLE lt_ltran FROM /psyng/critcodes
         WHERE vrsio = p_lvrsio.
  SELECT tcode imp owner busarea
  INTO CORRESPONDING FIELDS OF TABLE lt_rtran FROM /psyng/critcodes
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_ltexts FROM /psyng/texts
         WHERE object = 'X'
           AND vrsio  = p_lvrsio.

  SELECT * INTO TABLE lt_rtexts FROM /psyng/texts
         WHERE object = 'X'
           AND vrsio  = p_rvrsio.

  SORT: lt_ltran BY tcode,
        lt_rtran BY tcode,
        lt_ltexts     BY textname spras line,
        lt_rtexts     BY textname spras line..

* Compare headers
  LOOP AT lt_ltran ASSIGNING <ltran>.
    CLEAR: lf_diff, lf_hdr_written.

    READ TABLE lt_rtran ASSIGNING <rtran>
               WITH KEY tcode = <ltran>-tcode BINARY SEARCH.
    l_tran_idx = sy-tabix.

    IF sy-subrc <> 0.
      APPEND <ltran> TO gt_lmtran.
      IF g_format <> 'LIST'.
*       Save tcodes, objects and texts for tree
*        LOOP AT lt_lfuncttran ASSIGNING <tran>
*                WHERE functionid = <lfunc>-function.
*          MOVE-CORRESPONDING <tran> TO gt_ldtran.
*          APPEND gt_ldtran.
*        ENDLOOP.
*        LOOP AT lt_lfaobj ASSIGNING <lobj>
*                WHERE funid = <lfunc>-function.
*          APPEND <lobj> TO gt_ldfaobj.
*        ENDLOOP.
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <ltran>-tcode.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
      ENDIF.
      DELETE lt_ltran.
      CONTINUE.
    ENDIF.

*   Compare each header field
    PERFORM compare_header_field USING <ltran> <rtran> 'TCODE' 'IMP'
                                       text-h10
                                 CHANGING lf_dummy lf_hdr_written
                                          lf_diff.

    PERFORM compare_header_field USING <ltran> <rtran> 'TCODE' 'OWNER'
                                       text-h03
                                 CHANGING lf_dummy lf_hdr_written
                                          lf_diff.

   PERFORM compare_header_field USING <ltran> <rtran> 'TCODE' 'BUSAREA'
                                               text-h04
                                       CHANGING lf_dummy lf_hdr_written
                                                  lf_diff.


    IF NOT lf_diff IS INITIAL.
      APPEND <ltran> TO gt_ldcritcodes.
      APPEND <rtran> TO gt_rdcritcodes.
    ENDIF.
*  ENDLOOP.

*   Compare texts
    REFRESH: gt_ldtexts, gt_rdtexts.
    LOOP AT lt_ltexts ASSIGNING <text>
            WHERE textname = <ltran>-tcode.
      MOVE-CORRESPONDING <text> TO gt_ldtexts.
      APPEND gt_ldtexts.
    ENDLOOP.
    LOOP AT lt_rtexts ASSIGNING <text>
            WHERE textname = <rtran>-tcode.
      MOVE-CORRESPONDING <text> TO gt_rdtexts.
      APPEND gt_rdtexts.
    ENDLOOP.

    IF gt_ldtexts[] <> gt_rdtexts[].
      lf_diff = 'X'.
      IF g_format = 'LIST'.       "List output
        PERFORM write_header USING <ltran> <rtran> 'TCODE'
                             CHANGING lf_hdr_written.
        WRITE: /5   text-h09,
                135 sy-vline,
                141 text-h09.
        DO.
          READ TABLE gt_ldtexts INDEX sy-index.
          IF sy-subrc = 0.
            WRITE: /10 gt_ldtexts-spras,
                       gt_ldtexts-text,
                       135 sy-vline.

            READ TABLE gt_rdtexts INDEX sy-index.
            CHECK sy-subrc = 0.
            WRITE: 146 gt_rdtexts-spras,
                       gt_rdtexts-text.
          ELSE.
            READ TABLE gt_rdtexts INDEX sy-index.
            IF sy-subrc = 0.
              WRITE: /135 sy-vline,
                      146 gt_rdtexts-spras,
                          gt_rdtexts-text.
            ELSE.
              EXIT.
            ENDIF.
          ENDIF.
        ENDDO.
      ELSE.                       "Tree output
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <ltran>-tcode.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
        LOOP AT lt_rtexts ASSIGNING <text>
                WHERE textname = <rtran>-tcode.
          APPEND <text> TO gt_rdisptext.
        ENDLOOP.
      ENDIF.                      "List output
    ENDIF.

    IF lf_diff IS INITIAL.
      APPEND <ltran> TO gt_stran.
      DELETE lt_ltran.
      DELETE lt_rtran INDEX l_tran_idx.
    ENDIF.
  ENDLOOP.


* Check for any records that are missing from the left version
  LOOP AT lt_rtran ASSIGNING <rtran>.
    READ TABLE lt_ltran WITH KEY tcode = <rtran>-tcode
               BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    APPEND <rtran> TO gt_rmtran.

    IF g_format <> 'LIST'.
*     Save tcodes, objects and texts for tree
*      LOOP AT lt_rfuncttran ASSIGNING <tran>
*              WHERE functionid = <rfunc>-function.
*        MOVE-CORRESPONDING <tran> TO gt_rdtran.
*        APPEND gt_rdtran.
*      ENDLOOP.
*      LOOP AT lt_rfaobj ASSIGNING <robj>
*              WHERE funid = <rfunc>-function.
*        APPEND <robj> TO gt_rdfaobj.
*      ENDLOOP.
      LOOP AT lt_rtexts ASSIGNING <text>
              WHERE textname = <rtran>-tcode.
        APPEND <text> TO gt_rdisptext.
      ENDLOOP.
    ENDIF.


    DELETE lt_rtran.
  ENDLOOP.

* Output missing rows from each version
  CHECK g_format = 'LIST'.
  DESCRIBE TABLE gt_lmtran LINES l_lcount.
  DESCRIBE TABLE gt_rmtran LINES l_rcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h07,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h07,
              p_lvrsio,
              '(',
              l_rcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  DO.
    READ TABLE gt_lmtran ASSIGNING <ltran> INDEX sy-index.
    IF sy-subrc = 0.
      WRITE: /10  <ltran>-tcode,
              135 sy-vline.

      READ TABLE gt_rmtran ASSIGNING <rtran> INDEX sy-index.
      CHECK sy-subrc = 0.
      WRITE: 146 <rtran>-tcode.
    ELSE.
      READ TABLE gt_rmtran ASSIGNING <rtran> INDEX sy-index.
      IF sy-subrc = 0.
        WRITE: /135 sy-vline,
                146 <rtran>-tcode.
      ELSE.
        EXIT.
      ENDIF.
    ENDIF.
  ENDDO.

* Output identical critical tcodes
  DESCRIBE TABLE gt_stran LINES l_lcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h08,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h08,
              p_lvrsio,
              '(',
              l_lcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  LOOP AT gt_stran ASSIGNING <ltran>.
    WRITE: /10  <ltran>-tcode,
            135 sy-vline,
            146 <ltran>-tcode.
  ENDLOOP.
ENDFORM.                    " compare_crit_tcodes

*&---------------------------------------------------------------------*
*&      Form  compare_crit_auths
*&---------------------------------------------------------------------*
*       Select and compare critical authorizations
*----------------------------------------------------------------------*
FORM compare_crit_auths.
  DATA: lf_diff         TYPE /psyng/bapiflagx,
        lf_auth_written TYPE /psyng/bapiflagx,
        lf_hdr_written  TYPE /psyng/bapiflagx,
        l_auth_idx      TYPE i,
        l_obj_idx       TYPE i,
        l_lcount        TYPE i,
        l_rcount        TYPE i,
        lt_lauth        TYPE TABLE OF /psyng/swaudhdr,  "Left header
        lt_rauth        TYPE TABLE OF /psyng/swaudhdr,  "Right header
        lt_laudc        TYPE TABLE OF /psyng/swaudc2,   "Left objects
        lt_raudc        TYPE TABLE OF /psyng/swaudc2,   "Right objects
        lt_ltexts       TYPE TABLE OF /psyng/texts,     "Left texts
        lt_rtexts       TYPE TABLE OF /psyng/texts.     "Right texts

  FIELD-SYMBOLS: <lauth> TYPE /psyng/swaudhdr,
                 <rauth> TYPE /psyng/swaudhdr,
                 <laudc> TYPE /psyng/swaudc2,
                 <raudc> TYPE /psyng/swaudc2,
                 <text>  TYPE /psyng/texts.


  CHECK p_cauth = 'X'.

***********************************************
**Authorization check for Displaying SW Critical Authorizations
**SF 1665
  AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
            ID 'ACTVT' FIELD '03'
            ID 'Y&SW_AUTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
            ID 'Y&SW_VRSIO' FIELD p_lvrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
              ID 'ACTVT' FIELD '03'
              ID 'Y&SW_AUTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
              ID 'Y&SW_VRSIO' FIELD p_rvrsio.
    IF sy-subrc EQ 0.
    ELSE.
      MESSAGE e113(/psyng/sw) WITH text-e06 p_rvrsio.
      STOP.
    ENDIF.
  ELSE.
    MESSAGE e113(/psyng/sw) WITH text-e06 p_lvrsio.
    STOP.
  ENDIF.
***SF 1665
***********************************************

  PERFORM write_section_heading USING text-h15.

*  SELECT * INTO TABLE lt_lauth FROM /psyng/swaudhdr
*         WHERE vrsio = p_lvrsio.
*  SELECT * INTO TABLE lt_rauth FROM /psyng/swaudhdr
*         WHERE vrsio = p_rvrsio.

  SELECT swaudid tcode description imp owner
    INTO CORRESPONDING FIELDS OF TABLE lt_lauth FROM /psyng/swaudhdr
         WHERE vrsio = p_lvrsio.
  SELECT swaudid tcode description imp owner
    INTO CORRESPONDING FIELDS OF TABLE lt_rauth FROM /psyng/swaudhdr
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_laudc FROM /psyng/swaudc2
         WHERE vrsio = p_lvrsio.
  SELECT * INTO TABLE lt_raudc FROM /psyng/swaudc2
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_ltexts FROM /psyng/texts
         WHERE object = 'T'
           AND vrsio  = p_lvrsio.
  SELECT * INTO TABLE lt_rtexts FROM /psyng/texts
         WHERE object = 'T'
           AND vrsio  = p_rvrsio.

  SORT: lt_lauth  BY swaudid,
        lt_rauth  BY swaudid,
        lt_laudc  BY swaudid tcode object valueset field val_from
                     val_to,
        lt_raudc  BY swaudid tcode object valueset field val_from
                     val_to,
        lt_ltexts BY textname spras line,
        lt_rtexts BY textname spras line.

* Compare headers
  LOOP AT lt_lauth ASSIGNING <lauth>.
    CLEAR: lf_diff, lf_hdr_written, lf_auth_written.

    READ TABLE lt_rauth ASSIGNING <rauth>
               WITH KEY swaudid = <lauth>-swaudid BINARY SEARCH.
    l_auth_idx = sy-tabix.

    IF sy-subrc <> 0.
      APPEND <lauth> TO gt_lmauth.

      IF g_format <> 'LIST'.
*       Save objects and texts for tree
        LOOP AT lt_laudc ASSIGNING <laudc>
                WHERE swaudid = <lauth>-swaudid.
          APPEND <laudc> TO gt_ldaudc.
        ENDLOOP.
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lauth>-swaudid.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
      ENDIF.                      "List output

      DELETE lt_lauth.
      CONTINUE.
    ENDIF.

*   Compare each header field
   PERFORM compare_header_field USING <lauth> <rauth> 'SWAUDID' 'TCODE'
                                               text-h05
                                CHANGING lf_auth_written lf_hdr_written
                                                  lf_diff.
    PERFORM compare_header_field USING <lauth> <rauth> 'SWAUDID'
                                       'DESCRIPTION' text-h02
                                 CHANGING lf_auth_written lf_hdr_written
                                          lf_diff.

    PERFORM compare_header_field USING <lauth> <rauth> 'SWAUDID' 'IMP'
                                        text-h10
                                CHANGING lf_auth_written lf_hdr_written
                                           lf_diff.

   PERFORM compare_header_field USING <lauth> <rauth> 'SWAUDID' 'OWNER'
                                         text-h03
                                CHANGING lf_auth_written lf_hdr_written
                                            lf_diff.


*   Compare objects
    LOOP AT lt_laudc ASSIGNING <laudc>
            WHERE swaudid = <lauth>-swaudid
              AND tcode   = <lauth>-tcode.

      READ TABLE lt_raudc WITH KEY swaudid  = <laudc>-swaudid
                                   tcode    = <laudc>-tcode
                                   object   = <laudc>-object
                                   valueset = <laudc>-valueset
                                   field    = <laudc>-field
                                   val_from = <laudc>-val_from
                                   val_to   = <laudc>-val_to
                 BINARY SEARCH TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.
        lf_diff = 'X'.
        APPEND <laudc> TO gt_ldaudc.
      ELSE.
        l_obj_idx = sy-tabix.
        DELETE lt_laudc.
        DELETE lt_raudc INDEX l_obj_idx.
      ENDIF.
    ENDLOOP.

*   Check for any object records that are missing from the left version
    LOOP AT lt_raudc ASSIGNING <raudc>
            WHERE swaudid = <lauth>-swaudid.
      APPEND <raudc> TO gt_rdaudc.
    ENDLOOP.

    IF sy-subrc = 0.
      lf_diff = 'X'.
    ENDIF.

    IF g_format = 'LIST'.         "List output
      DO.
        READ TABLE gt_ldaudc ASSIGNING <laudc> INDEX sy-index.
        IF sy-subrc = 0.
          PERFORM write_header USING <lauth> <rauth> 'SWAUDID'
                               CHANGING lf_auth_written.

          IF sy-index = 1.
            WRITE: /5   text-h06,
                    135 sy-vline,
                    141 text-h06.
          ENDIF.

          WRITE: /10  <laudc>-tcode,
                      <laudc>-object,
                      <laudc>-valueset,
                      <laudc>-field,
                      <laudc>-val_from,
                      <laudc>-val_to,
                  135 sy-vline.

          READ TABLE gt_rdaudc ASSIGNING <raudc> INDEX sy-index.
          CHECK sy-subrc = 0.
          WRITE: 146 <raudc>-tcode,
                     <raudc>-object,
                     <raudc>-valueset,
                     <raudc>-field,
                     <raudc>-val_from,
                     <raudc>-val_to.
        ELSE.
          READ TABLE gt_rdaudc ASSIGNING <raudc> INDEX sy-index.
          IF sy-subrc = 0.
            PERFORM write_header USING <lauth> <rauth> 'SWAUDID'
                                 CHANGING lf_auth_written.

            IF sy-index = 1.
              WRITE: /5   text-h06,
                      135 sy-vline,
                      141 text-h06.
            ENDIF.

            WRITE: /135 sy-vline,
                    146 <raudc>-tcode,
                        <raudc>-object,
                        <raudc>-valueset,
                        <raudc>-field,
                        <raudc>-val_from,
                        <raudc>-val_to.
          ELSE.
            EXIT.
          ENDIF.
        ENDIF.
      ENDDO.

*     Only refresh when using list output
      REFRESH: gt_ldaudc, gt_rdaudc.
    ENDIF.                        "List output

*   Compare texts
    REFRESH: gt_ldtexts, gt_rdtexts.
    LOOP AT lt_ltexts ASSIGNING <text>
            WHERE textname = <lauth>-swaudid.
      MOVE-CORRESPONDING <text> TO gt_ldtexts.
      APPEND gt_ldtexts.
    ENDLOOP.
    LOOP AT lt_rtexts ASSIGNING <text>
            WHERE textname = <lauth>-swaudid.
      MOVE-CORRESPONDING <text> TO gt_rdtexts.
      APPEND gt_rdtexts.
    ENDLOOP.

    IF gt_ldtexts[] <> gt_rdtexts[].
      lf_diff = 'X'.

      IF g_format = 'LIST'.       "List output
        PERFORM write_header USING <lauth> <rauth> 'SWAUDID'
                             CHANGING lf_auth_written.
        WRITE: /5   text-h09,
                135 sy-vline,
                141 text-h09.
        DO.
          READ TABLE gt_ldtexts INDEX sy-index.
          IF sy-subrc = 0.
            WRITE: /10  gt_ldtexts-spras,
                        gt_ldtexts-text,
                    135 sy-vline.

            READ TABLE gt_rdtexts INDEX sy-index.
            CHECK sy-subrc = 0.
            WRITE: 146 gt_rdtexts-spras,
                       gt_rdtexts-text.
          ELSE.
            READ TABLE gt_rdtexts INDEX sy-index.
            IF sy-subrc = 0.
              WRITE: /135 sy-vline,
                      146 gt_rdtexts-spras,
                          gt_rdtexts-text.
            ELSE.
              EXIT.
            ENDIF.
          ENDIF.
        ENDDO.
      ELSE.
        LOOP AT lt_ltexts ASSIGNING <text>
               WHERE textname = <lauth>-swaudid.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
        LOOP AT lt_rtexts ASSIGNING <text>
                WHERE textname = <lauth>-swaudid.
          APPEND <text> TO gt_rdisptext.
        ENDLOOP.

      ENDIF.                      "List output
    ENDIF.

    IF lf_diff IS INITIAL.
      APPEND <lauth> TO gt_sauth.
      DELETE lt_lauth.
      DELETE lt_rauth INDEX l_auth_idx.
    ELSE.
      APPEND <lauth> TO gt_ldauth.
      APPEND <rauth> TO gt_rdauth.
    ENDIF.
  ENDLOOP.

* Check for any records that are missing from the left version
  LOOP AT lt_rauth ASSIGNING <rauth>.
    READ TABLE lt_lauth WITH KEY swaudid = <rauth>-swaudid
               BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    APPEND <rauth> TO gt_rmauth.

    IF g_format <> 'LIST'.
*     Save objects and for tree
      LOOP AT lt_raudc ASSIGNING <raudc>
              WHERE swaudid = <rauth>-swaudid.
        APPEND <raudc> TO gt_rdaudc.
      ENDLOOP.
      LOOP AT lt_rtexts ASSIGNING <text>
              WHERE textname = <rauth>-swaudid.
        APPEND <text> TO gt_rdisptext.
      ENDLOOP.
    ENDIF.                      "List output

    DELETE lt_rauth.
  ENDLOOP.

* Output missing rows from each version
  CHECK g_format = 'LIST'.
  DESCRIBE TABLE gt_lmauth LINES l_lcount.
  DESCRIBE TABLE gt_rmauth LINES l_rcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h07,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h07,
              p_lvrsio,
              '(',
              l_rcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  DO.
    READ TABLE gt_lmauth ASSIGNING <lauth> INDEX sy-index.
    IF sy-subrc = 0.
      WRITE: /10  <lauth>-swaudid,
                  <lauth>-description,
              135 sy-vline.

      READ TABLE gt_rmauth ASSIGNING <rauth> INDEX sy-index.
      CHECK sy-subrc = 0.
      WRITE: 146 <rauth>-swaudid,
                 <rauth>-description.
    ELSE.
      READ TABLE gt_rmauth ASSIGNING <rauth> INDEX sy-index.
      IF sy-subrc = 0.
        WRITE: /135 sy-vline,
                146 <rauth>-swaudid,
                    <rauth>-description.
      ELSE.
        EXIT.
      ENDIF.
    ENDIF.
  ENDDO.

* Output identical critical auths
  DESCRIBE TABLE gt_sauth LINES l_lcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h08,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h08,
              p_lvrsio,
              '(',
              l_lcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  LOOP AT gt_sauth ASSIGNING <lauth>.
    WRITE: /10  <lauth>-swaudid,
                <lauth>-description,
            135 sy-vline,
            146 <lauth>-swaudid,
                <lauth>-description.
  ENDLOOP.
ENDFORM.                    " compare_crit_auths

*&---------------------------------------------------------------------*
*&      Form  compare_crit_roles
*&---------------------------------------------------------------------*
*       Select and compare critical roles
*----------------------------------------------------------------------*
FORM compare_crit_roles.
  DATA: lf_diff         TYPE /psyng/bapiflagx,
        lf_role_written TYPE /psyng/bapiflagx,
        lf_hdr_written  TYPE /psyng/bapiflagx,
        l_role_idx      TYPE i,
        l_lcount        TYPE i,
        l_rcount        TYPE i,
        lt_lrole        TYPE TABLE OF /psyng/criroles,  "Left header
        lt_rrole        TYPE TABLE OF /psyng/criroles,   "Right objects
        lt_ltexts       TYPE TABLE OF /psyng/texts,     "Left texts
        lt_rtexts       TYPE TABLE OF /psyng/texts.     "Right texts

  FIELD-SYMBOLS: <lrole> TYPE /psyng/criroles,
                 <rrole> TYPE /psyng/criroles,
                 <text> TYPE /psyng/texts.


  CHECK p_crole = 'X'.

  AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_VRSIO'  FIELD p_lvrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_VRSIO'  FIELD p_rvrsio.
    IF sy-subrc EQ 0.
    ELSE.
      MESSAGE e113(/psyng/sw) WITH text-e07 p_rvrsio.
      STOP.
    ENDIF.
  ELSE.
    MESSAGE e113(/psyng/sw) WITH text-e07 p_lvrsio.
    STOP.
  ENDIF.

  PERFORM write_section_heading USING text-h16.

  SELECT * INTO TABLE lt_lrole FROM /psyng/criroles
         WHERE vrsio = p_lvrsio.
  SELECT * INTO TABLE lt_rrole FROM /psyng/criroles
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_ltexts FROM /psyng/texts
         WHERE object = 'Q'
           AND vrsio  = p_lvrsio.

  SELECT * INTO TABLE lt_rtexts FROM /psyng/texts
         WHERE object = 'Q'
           AND vrsio  = p_rvrsio.


  SORT: lt_lrole BY agr_name,
        lt_rrole BY agr_name,
        lt_ltexts     BY textname spras line,
        lt_rtexts     BY textname spras line.

* Compare headers
  LOOP AT lt_lrole ASSIGNING <lrole>.
    CLEAR: lf_diff, lf_hdr_written.

    READ TABLE lt_rrole ASSIGNING <rrole>
               WITH KEY agr_name = <lrole>-agr_name BINARY SEARCH.
    l_role_idx = sy-tabix.

    IF sy-subrc <> 0.
      APPEND <lrole> TO gt_lmrole.
      IF g_format <> 'LIST'.
*       Save tcodes, objects and texts for tree
*        LOOP AT lt_lfuncttran ASSIGNING <tran>
*                WHERE functionid = <lfunc>-function.
*          MOVE-CORRESPONDING <tran> TO gt_ldtran.
*          APPEND gt_ldtran.
*        ENDLOOP.
*        LOOP AT lt_lfaobj ASSIGNING <lobj>
*                WHERE funid = <lfunc>-function.
*          APPEND <lobj> TO gt_ldfaobj.
*        ENDLOOP.
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lrole>-agr_name.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
      ENDIF.
      DELETE lt_lrole.
      CONTINUE.
    ENDIF.

*   Compare each header field
    PERFORM compare_header_field USING <lrole> <rrole> 'AGR_NAME' 'IMP'
                                       text-h10
                                 CHANGING lf_role_written lf_hdr_written
                                          lf_diff.

  PERFORM compare_header_field USING <lrole> <rrole> 'AGR_NAME' 'OWNER'
                                                 text-h10
                                CHANGING lf_role_written lf_hdr_written
                                                    lf_diff.



*   Compare texts
    REFRESH: gt_ldtexts, gt_rdtexts.
    LOOP AT lt_ltexts ASSIGNING <text>
            WHERE textname = <lrole>-agr_name.
      MOVE-CORRESPONDING <text> TO gt_ldtexts.
      APPEND gt_ldtexts.
    ENDLOOP.
    LOOP AT lt_rtexts ASSIGNING <text>
            WHERE textname = <lrole>-agr_name.
      MOVE-CORRESPONDING <text> TO gt_rdtexts.
      APPEND gt_rdtexts.
    ENDLOOP.

    IF gt_ldtexts[] <> gt_rdtexts[].
      lf_diff = 'X'.
      IF g_format = 'LIST'.       "List output
        PERFORM write_header USING <lrole> <rrole> 'AGR_NAME'
                             CHANGING lf_hdr_written.
        WRITE: /5   text-h09,
                135 sy-vline,
                141 text-h09.
        DO.
          READ TABLE gt_ldtexts INDEX sy-index.
          IF sy-subrc = 0.
            WRITE: /10 gt_ldtexts-spras,
                       gt_ldtexts-text,
                       135 sy-vline.

            READ TABLE gt_rdtexts INDEX sy-index.
            CHECK sy-subrc = 0.
            WRITE: 146 gt_rdtexts-spras,
                       gt_rdtexts-text.
          ELSE.
            READ TABLE gt_rdtexts INDEX sy-index.
            IF sy-subrc = 0.
              WRITE: /135 sy-vline,
                      146 gt_rdtexts-spras,
                          gt_rdtexts-text.
            ELSE.
              EXIT.
            ENDIF.
          ENDIF.
        ENDDO.
      ELSE.                       "Tree output
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lrole>-agr_name.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
        LOOP AT lt_rtexts ASSIGNING <text>
                WHERE textname = <lrole>-agr_name.
          APPEND <text> TO gt_rdisptext.
        ENDLOOP.
      ENDIF.                      "List output
    ENDIF.

    IF lf_diff IS INITIAL.
      APPEND <lrole> TO gt_srole.
      DELETE lt_lrole.
      DELETE lt_rrole INDEX l_role_idx.
    ELSE.
      APPEND <lrole> TO gt_ldrole.
      APPEND <rrole> TO gt_rdrole.
    ENDIF.
  ENDLOOP.

* Check for any records that are missing from the left version
  LOOP AT lt_rrole ASSIGNING <rrole>.
    READ TABLE lt_lrole WITH KEY agr_name = <rrole>-agr_name
               BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    APPEND <rrole> TO gt_rmrole.

    IF g_format <> 'LIST'.
*     Save tcodes, objects and texts for tree
*      LOOP AT lt_rfuncttran ASSIGNING <tran>
*              WHERE functionid = <rfunc>-function.
*        MOVE-CORRESPONDING <tran> TO gt_rdtran.
*        APPEND gt_rdtran.
*      ENDLOOP.
*      LOOP AT lt_rfaobj ASSIGNING <robj>
*              WHERE funid = <rfunc>-function.
*        APPEND <robj> TO gt_rdfaobj.
*      ENDLOOP.
      LOOP AT lt_rtexts ASSIGNING <text>
              WHERE textname = <rrole>-agr_name .
        APPEND <text> TO gt_rdisptext.
      ENDLOOP.
    ENDIF.

    DELETE lt_rrole.
  ENDLOOP.

* Output missing rows from each version
  CHECK g_format = 'LIST'.
  DESCRIBE TABLE gt_lmrole LINES l_lcount.
  DESCRIBE TABLE gt_rmrole LINES l_rcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h07,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h07,
              p_lvrsio,
              '(',
              l_rcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  DO.
    READ TABLE gt_lmrole ASSIGNING <lrole> INDEX sy-index.
    IF sy-subrc = 0.
      WRITE: /10  <lrole>-agr_name,
              135 sy-vline.

      READ TABLE gt_rmrole ASSIGNING <rrole> INDEX sy-index.
      CHECK sy-subrc = 0.
      WRITE: 146 <rrole>-agr_name.
    ELSE.
      READ TABLE gt_rmrole ASSIGNING <rrole> INDEX sy-index.
      IF sy-subrc = 0.
        WRITE: /135 sy-vline,
                146 <rrole>-agr_name.
      ELSE.
        EXIT.
      ENDIF.
    ENDIF.
  ENDDO.

* Output identical critical roles
  DESCRIBE TABLE gt_srole LINES l_lcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h08,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h08,
              p_lvrsio,
              '(',
              l_lcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  LOOP AT gt_srole ASSIGNING <lrole>.
    WRITE: /10  <lrole>-agr_name,
            135 sy-vline,
            146 <lrole>-agr_name.
  ENDLOOP.
ENDFORM.                    " compare_crit_roles

*&---------------------------------------------------------------------*
*&      Form  compare_crit_profs
*&---------------------------------------------------------------------*
*       Select and compare critical profiles
*----------------------------------------------------------------------*
FORM compare_crit_profs.
  DATA: lf_diff         TYPE /psyng/bapiflagx,
        lf_prof_written TYPE /psyng/bapiflagx,
        lf_hdr_written  TYPE /psyng/bapiflagx,
        l_prof_idx      TYPE i,
        l_lcount        TYPE i,
        l_rcount        TYPE i,
        lt_lprof        TYPE TABLE OF /psyng/criprof,   "Left header
        lt_rprof        TYPE TABLE OF /psyng/criprof, "Right header
        lt_ltexts       TYPE TABLE OF /psyng/texts, "left text
        lt_rtexts       TYPE TABLE OF /psyng/texts. " right texts

  FIELD-SYMBOLS: <lprof> TYPE /psyng/criprof,
                 <rprof> TYPE /psyng/criprof,
                 <text>  TYPE /psyng/texts.


  CHECK p_cprof = 'X'.

  AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_VRSIO'  FIELD p_lvrsio.
  IF sy-subrc EQ 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_CTPRO'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_VRSIO'  FIELD p_rvrsio.
    IF sy-subrc EQ 0.
    ELSE.
      MESSAGE e113(/psyng/sw) WITH text-e08 p_rvrsio.
      STOP.
    ENDIF.
  ELSE.
    MESSAGE e113(/psyng/sw) WITH text-e08 p_lvrsio.
    STOP.
  ENDIF.

  PERFORM write_section_heading USING text-h17.

  SELECT * INTO TABLE lt_lprof FROM /psyng/criprof
         WHERE vrsio = p_lvrsio.
  SELECT * INTO TABLE lt_rprof FROM /psyng/criprof
         WHERE vrsio = p_rvrsio.

  SELECT * INTO TABLE lt_ltexts FROM /psyng/texts
         WHERE object = 'P'
           AND vrsio  = p_lvrsio.

  SELECT * INTO TABLE lt_rtexts FROM /psyng/texts
         WHERE object = 'P'
           AND vrsio  = p_rvrsio.

  SORT: lt_lprof BY profile,
        lt_rprof BY profile,
        lt_ltexts     BY textname spras line,
        lt_rtexts     BY textname spras line.

* Compare headers
  LOOP AT lt_lprof ASSIGNING <lprof>.
    CLEAR: lf_diff, lf_hdr_written.

    READ TABLE lt_rprof ASSIGNING <rprof>
               WITH KEY profile = <lprof>-profile BINARY SEARCH.
    l_prof_idx = sy-tabix.

    IF sy-subrc <> 0.
      APPEND <lprof> TO gt_lmprof.
      IF g_format <> 'LIST'.
*       Save tcodes, objects and texts for tree
*        LOOP AT lt_lfuncttran ASSIGNING <tran>
*                WHERE functionid = <lfunc>-function.
*          MOVE-CORRESPONDING <tran> TO gt_ldtran.
*          APPEND gt_ldtran.
*        ENDLOOP.
*        LOOP AT lt_lfaobj ASSIGNING <lobj>
*                WHERE funid = <lfunc>-function.
*          APPEND <lobj> TO gt_ldfaobj.
*        ENDLOOP.
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lprof>-profile.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
      ENDIF.

      DELETE lt_lprof.
      CONTINUE.
    ENDIF.

*   Compare each header field
    PERFORM compare_header_field USING <lprof> <rprof> 'PROFILE' 'IMP'
                                       text-h10
                                 CHANGING lf_prof_written lf_hdr_written
                                          lf_diff.
   PERFORM compare_header_field USING <lprof> <rprof> 'PROFILE' 'OWNER'
                                         text-h03
                                CHANGING lf_prof_written lf_hdr_written
                                            lf_diff.

*    Compare texts
    REFRESH: gt_ldtexts, gt_rdtexts.
    LOOP AT lt_ltexts ASSIGNING <text>
            WHERE textname = <lprof>-profile.
      MOVE-CORRESPONDING <text> TO gt_ldtexts.
      APPEND gt_ldtexts.
    ENDLOOP.
    LOOP AT lt_rtexts ASSIGNING <text>
            WHERE textname = <lprof>-profile.
      MOVE-CORRESPONDING <text> TO gt_rdtexts.
      APPEND gt_rdtexts.
    ENDLOOP.

    IF gt_ldtexts[] <> gt_rdtexts[].
      lf_diff = 'X'.
      IF g_format = 'LIST'.       "List output
        PERFORM write_header USING <lprof> <rprof> 'PROFILE'
                             CHANGING lf_hdr_written.
        WRITE: /5   text-h09,
                135 sy-vline,
                141 text-h09.
        DO.
          READ TABLE gt_ldtexts INDEX sy-index.
          IF sy-subrc = 0.
            WRITE: /10 gt_ldtexts-spras,
                       gt_ldtexts-text,
                       135 sy-vline.

            READ TABLE gt_rdtexts INDEX sy-index.
            CHECK sy-subrc = 0.
            WRITE: 146 gt_rdtexts-spras,
                       gt_rdtexts-text.
          ELSE.
            READ TABLE gt_rdtexts INDEX sy-index.
            IF sy-subrc = 0.
              WRITE: /135 sy-vline,
                      146 gt_rdtexts-spras,
                          gt_rdtexts-text.
            ELSE.
              EXIT.
            ENDIF.
          ENDIF.
        ENDDO.
      ELSE.                       "Tree output
        LOOP AT lt_ltexts ASSIGNING <text>
                WHERE textname = <lprof>-profile.
          APPEND <text> TO gt_ldisptext.
        ENDLOOP.
        LOOP AT lt_rtexts ASSIGNING <text>
                WHERE textname = <lprof>-profile.
          APPEND <text> TO gt_rdisptext.
        ENDLOOP.
      ENDIF.                      "List output
    ENDIF.

    IF lf_diff IS INITIAL.
      APPEND <lprof> TO gt_sprof.
      DELETE lt_lprof.
      DELETE lt_rprof INDEX l_prof_idx.
    ELSE.
      APPEND <lprof> TO gt_ldprof.
      APPEND <rprof> TO gt_rdprof.
    ENDIF.

  ENDLOOP.

* Check for any records that are missing from the left version
  LOOP AT lt_rprof ASSIGNING <rprof>.
    READ TABLE lt_lprof WITH KEY profile = <rprof>-profile
               BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    APPEND <rprof> TO gt_rmprof.
    IF g_format <> 'LIST'.
*     Save tcodes, objects and texts for tree
*      LOOP AT lt_rfuncttran ASSIGNING <tran>
*              WHERE functionid = <rfunc>-function.
*        MOVE-CORRESPONDING <tran> TO gt_rdtran.
*        APPEND gt_rdtran.
*      ENDLOOP.
*      LOOP AT lt_rfaobj ASSIGNING <robj>
*              WHERE funid = <rfunc>-function.
*        APPEND <robj> TO gt_rdfaobj.
*      ENDLOOP.
      LOOP AT lt_rtexts ASSIGNING <text>
              WHERE textname = <rprof>-profile.
        APPEND <text> TO gt_rdisptext.
      ENDLOOP.
    ENDIF.

    DELETE lt_rprof.
  ENDLOOP.

* Output missing rows from each version
  CHECK g_format = 'X'.
  DESCRIBE TABLE gt_lmprof LINES l_lcount.
  DESCRIBE TABLE gt_rmprof LINES l_rcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h07,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h07,
              p_lvrsio,
              '(',
              l_rcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  DO.
    READ TABLE gt_lmprof ASSIGNING <lprof> INDEX sy-index.
    IF sy-subrc = 0.
      WRITE: /10  <lprof>-profile,
              135 sy-vline.

      READ TABLE gt_rmprof ASSIGNING <rprof> INDEX sy-index.
      CHECK sy-subrc = 0.
      WRITE: 146 <rprof>-profile.
    ELSE.
      READ TABLE gt_rmprof ASSIGNING <rprof> INDEX sy-index.
      IF sy-subrc = 0.
        WRITE: /135 sy-vline,
                146 <rprof>-profile.
      ELSE.
        EXIT.
      ENDIF.
    ENDIF.
  ENDDO.

* Output identical critical profiles
  DESCRIBE TABLE gt_sprof LINES l_lcount.
  WRITE /135 sy-vline.
  FORMAT COLOR COL_TOTAL.
  WRITE: /5   text-h08,
              p_rvrsio,
              '(',
              l_lcount,
              ')',
          135 sy-vline,
          141 text-h08,
              p_lvrsio,
              '(',
              l_lcount,
              ')'.
  FORMAT COLOR COL_BACKGROUND.
  LOOP AT gt_sprof ASSIGNING <lprof>.
    WRITE: /10  <lprof>-profile,
            135 sy-vline,
            146 <lprof>-profile.
  ENDLOOP.
ENDFORM.                    " compare_crit_profs

*&---------------------------------------------------------------------*
*&      Form  write_section_heading
*&---------------------------------------------------------------------*
*       Write the heading for each section
*----------------------------------------------------------------------*
*      -->I_HEADING  Type of section
*----------------------------------------------------------------------*
FORM write_section_heading USING    i_heading.
  CHECK g_format = 'LIST'.
  NEW-PAGE.
  WRITE: /    i_heading COLOR COL_HEADING,
          135 sy-vline.
  ULINE.
  FORMAT COLOR COL_TOTAL.
  WRITE: /(250) text-h18,
          135    sy-vline.
  FORMAT COLOR COL_BACKGROUND.
ENDFORM.                    " write_section_heading

*&---------------------------------------------------------------------*
*&      Form  compare_header_field
*&---------------------------------------------------------------------*
*       Compare a single field from the header
*----------------------------------------------------------------------*
*      -->IS_LEFT         Structure for left version
*      -->IS_RIGHT        Structure for right version
*      -->I_ID_FIELD      Object ID field name
*      -->I_FIELD         Field name
*      -->I_HEADING       Heading text
*      <--EF_ID_WRITTEN   Object written flag
*      <--EF_HDR_WRITTEN  Heading written flag
*----------------------------------------------------------------------*
FORM compare_header_field USING    is_left
                                   is_right
                                   i_id_field TYPE string
                                   i_field TYPE string
                                   i_heading TYPE string
                          CHANGING ef_id_written TYPE /psyng/bapiflagx
                                   ef_hdr_written TYPE /psyng/bapiflagx
                                   ef_diff TYPE /psyng/bapiflagx.
  FIELD-SYMBOLS: <left>  TYPE ANY,
                 <right> TYPE ANY.

  ASSIGN COMPONENT i_field OF STRUCTURE is_left TO <left>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
  ASSIGN COMPONENT i_field OF STRUCTURE is_right TO <right>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
  IF <left> <> <right>.
    ef_diff = 'X'.
    CHECK g_format = 'LIST'.
    PERFORM write_header USING is_left is_right i_id_field
                               CHANGING ef_id_written.

    IF ef_hdr_written IS INITIAL.
      ef_hdr_written = 'X'.
      WRITE: /5   text-h01,
              135 sy-vline,
              141 text-h01.
    ENDIF.
    WRITE: /10  i_heading,
                <left>,
            135 sy-vline,
            146 i_heading,
                <right>.
  ENDIF.
ENDFORM.                    " compare_header_field

*&---------------------------------------------------------------------*
*&      Form  write_header
*&---------------------------------------------------------------------*
*       Write heading
*----------------------------------------------------------------------*
*      -->IS_LEFT     Left header
*      -->IS_RIGHT    Right header
*      -->I_ID_FIELD  Object ID field name
*      <--EF_WRITTEN  Header written flag
*----------------------------------------------------------------------*
FORM write_header USING    is_left
                           is_right
                           i_id_field TYPE string
                  CHANGING ef_written TYPE /psyng/bapiflagx.
  FIELD-SYMBOLS: <id>   TYPE ANY,
                 <desc> TYPE ANY.

  CHECK ef_written IS INITIAL.
  ef_written = 'X'.

  ASSIGN COMPONENT i_id_field OF STRUCTURE is_left TO <id>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
  ASSIGN COMPONENT 'DESCRIPTION' OF STRUCTURE is_left TO <desc>.
  WRITE: /135 sy-vline.
  FORMAT COLOR COL_GROUP.
  WRITE / <id>.
  IF <desc> IS ASSIGNED.
    WRITE <desc>.
  ENDIF.
  WRITE 135 sy-vline.

  ASSIGN COMPONENT i_id_field OF STRUCTURE is_right TO <id>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
  ASSIGN COMPONENT 'DESCRIPTION' OF STRUCTURE is_right TO <desc>.
  WRITE 136 <id>.
  IF <desc> IS ASSIGNED.
    WRITE <desc>.
  ENDIF.
  FORMAT COLOR COL_BACKGROUND.
ENDFORM.                    " write_header

*&---------------------------------------------------------------------*
*&      Form  init_alv_detail
*&---------------------------------------------------------------------*
*       Initialize ALV for TCodes and Functions
*----------------------------------------------------------------------*
*  -->  I_NODE_KEY  Node key from tree
*----------------------------------------------------------------------*
FORM init_alv_detail USING i_node_key.
  CLEAR: gs_fieldcat, gt_detfieldcat[].

  IF go_ldetail IS INITIAL.
    CREATE OBJECT go_ldetail
           EXPORTING container_name = g_ldetcontainer.
    CREATE OBJECT go_ldetgrid
           EXPORTING i_parent = go_ldetail.
  ENDIF.

  gs_fieldcat-col_pos   = 1.
  gs_fieldcat-fieldname = 'TCODE'.
  gs_fieldcat-tabname   = '/PSYNG/FUNCTTRAN'.
  gs_fieldcat-scrtext_l = text-h05.
  gs_fieldcat-scrtext_m = text-h05.
  gs_fieldcat-scrtext_s = text-h05.

  IF i_node_key(1) <> 'F'.
    gs_fieldcat-no_out = 'X'.
  ENDIF.

  APPEND gs_fieldcat TO gt_detfieldcat.
  CLEAR gs_fieldcat.

  gs_fieldcat-col_pos   = 2.
  gs_fieldcat-fieldname = 'FUNCTIONID'.
  gs_fieldcat-tabname   = '/PSYNG/FUNCTTRAN'.
  gs_fieldcat-scrtext_l = text-h12.
  gs_fieldcat-scrtext_m = text-h12.
  gs_fieldcat-scrtext_s = text-h12.

  IF i_node_key(1) <> 'C'.
    gs_fieldcat-no_out = 'X'.
  ENDIF.

  APPEND gs_fieldcat TO gt_detfieldcat.
  CLEAR gs_fieldcat.

  IF go_rdetail IS INITIAL.
    CREATE OBJECT go_rdetail
           EXPORTING container_name = g_rdetcontainer.
    CREATE OBJECT go_rdetgrid
           EXPORTING i_parent = go_rdetail.
  ENDIF.

  CASE i_node_key(1).
    WHEN 'F'.
      gs_layout-grid_title = text-h05.
    WHEN 'C'.
      gs_layout-grid_title = text-h12.
    WHEN OTHERS.
      CLEAR gs_layout-grid_title.
  ENDCASE.

  CALL METHOD go_ldetgrid->set_table_for_first_display
       EXPORTING is_layout        = gs_layout
       CHANGING  it_fieldcatalog  = gt_detfieldcat
                 it_outtab        = gt_ldetail.

  CALL METHOD go_rdetgrid->set_table_for_first_display
       EXPORTING is_layout        = gs_layout
       CHANGING  it_fieldcatalog  = gt_detfieldcat
                 it_outtab        = gt_rdetail.
ENDFORM.                    " init_alv_detail

*&---------------------------------------------------------------------*
*&      Form  init_alv_object
*&---------------------------------------------------------------------*
*       Initialize ALV for auth objects
*----------------------------------------------------------------------*
*  -->  I_NODE_KEY  Node key from tree
*----------------------------------------------------------------------*
FORM init_alv_object USING i_node_key.
  CLEAR: gs_fieldcat, gt_objfieldcat[].

  IF go_lobject IS INITIAL.
    CREATE OBJECT go_lobject
           EXPORTING container_name = g_lobjcontainer.
    CREATE OBJECT go_lobjgrid
           EXPORTING i_parent = go_lobject.
  ENDIF.

  gs_fieldcat-col_pos   = 1.
  gs_fieldcat-fieldname = 'TCODE'.
  gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
  gs_fieldcat-scrtext_l = text-h05.
  gs_fieldcat-scrtext_m = text-h05.
  gs_fieldcat-scrtext_s = text-h05.
  APPEND gs_fieldcat TO gt_objfieldcat.
  CLEAR gs_fieldcat.
  gs_fieldcat-col_pos   = 2.
  gs_fieldcat-fieldname = 'OBJECT'.
  gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
  gs_fieldcat-scrtext_l = text-h06.
  gs_fieldcat-scrtext_m = text-h06.
  gs_fieldcat-scrtext_s = text-h06.
  APPEND gs_fieldcat TO gt_objfieldcat.
  CLEAR gs_fieldcat.
  gs_fieldcat-col_pos   = 3.
  gs_fieldcat-fieldname = 'VALUESET'.
  gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
  gs_fieldcat-scrtext_l = text-h20.
  gs_fieldcat-scrtext_m = text-h20.
  gs_fieldcat-scrtext_s = text-h20.
  APPEND gs_fieldcat TO gt_objfieldcat.
  CLEAR gs_fieldcat.
  gs_fieldcat-col_pos   = 4.
  gs_fieldcat-fieldname = 'FIELD'.
  gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
  gs_fieldcat-scrtext_l = text-h21.
  gs_fieldcat-scrtext_m = text-h21.
  gs_fieldcat-scrtext_s = text-h21.
  APPEND gs_fieldcat TO gt_objfieldcat.
  CLEAR gs_fieldcat.
  gs_fieldcat-col_pos   = 5.
  gs_fieldcat-fieldname = 'VAL_FROM'.
  gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
  gs_fieldcat-scrtext_l = text-h22.
  gs_fieldcat-scrtext_m = text-h22.
  gs_fieldcat-scrtext_s = text-h22.
  APPEND gs_fieldcat TO gt_objfieldcat.
  CLEAR gs_fieldcat.
  gs_fieldcat-col_pos   = 6.
  gs_fieldcat-fieldname = 'VAL_TO'.
  gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
  gs_fieldcat-scrtext_l = text-h23.
  gs_fieldcat-scrtext_m = text-h23.
  gs_fieldcat-scrtext_s = text-h23.
  APPEND gs_fieldcat TO gt_objfieldcat.
  CLEAR gs_fieldcat.

  IF i_node_key(1) = 'F'.
    gs_fieldcat-col_pos   = 7.
    gs_fieldcat-fieldname = 'OBJ_OR'.
    gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
    gs_fieldcat-scrtext_l = text-h24.
    gs_fieldcat-scrtext_m = text-h24.
    gs_fieldcat-scrtext_s = text-h24.
    APPEND gs_fieldcat TO gt_objfieldcat.
    CLEAR gs_fieldcat.

    gs_fieldcat-col_pos   = 8.
    gs_fieldcat-fieldname = 'FLD_AND'.
    gs_fieldcat-tabname   = '/PSYNG/FAOBJ2'.
    gs_fieldcat-scrtext_l = text-h25.
    gs_fieldcat-scrtext_m = text-h25.
    gs_fieldcat-scrtext_s = text-h25.
    APPEND gs_fieldcat TO gt_objfieldcat.
    CLEAR gs_fieldcat.
  ENDIF.

  IF i_node_key(1) = 'F' OR i_node_key(1) = 'A'.
    gs_fieldcat-no_out = space.
    MODIFY gt_objfieldcat FROM gs_fieldcat TRANSPORTING no_out
           WHERE no_out = 'X'.
  ELSE.
    gs_fieldcat-no_out = 'X'.
    MODIFY gt_objfieldcat FROM gs_fieldcat TRANSPORTING no_out
           WHERE no_out = space.
  ENDIF.

  IF go_robject IS INITIAL.
    CREATE OBJECT go_robject
           EXPORTING container_name = g_robjcontainer.
    CREATE OBJECT go_robjgrid
           EXPORTING i_parent = go_robject.
  ENDIF.

  CASE i_node_key(1).
    WHEN 'F' OR 'A'.
      gs_layout-grid_title = text-h06.
    WHEN OTHERS.
      CLEAR gs_layout-grid_title.
  ENDCASE.

  CALL METHOD go_lobjgrid->set_table_for_first_display
       EXPORTING is_layout        = gs_layout
       CHANGING  it_fieldcatalog  = gt_objfieldcat
                 it_outtab        = gt_lobject.

  CALL METHOD go_robjgrid->set_table_for_first_display
       EXPORTING is_layout        = gs_layout
       CHANGING  it_fieldcatalog  = gt_objfieldcat
                 it_outtab        = gt_robject.
ENDFORM.                    " init_alv_object

*&---------------------------------------------------------------------*
*&      Form  init_text
*&---------------------------------------------------------------------*
*       Initialize text editor
*----------------------------------------------------------------------*
*  -->  I_OBJECT  Text object ID
*----------------------------------------------------------------------*
FORM init_text USING i_object TYPE /psyng/texts-object.
  DATA: lt_text  TYPE TABLE OF /psyng/texts-text,
        l_object TYPE /psyng/texts-object.

  FIELD-SYMBOLS: <text> TYPE /psyng/texts.


  IF go_ltxtedit IS INITIAL.
    CREATE OBJECT go_ltxtcontainer
        EXPORTING
            container_name = 'G_LTEXT'
        EXCEPTIONS
            cntl_error = 1
            cntl_system_error = 2
            create_error = 3
            lifetime_error = 4
            lifetime_dynpro_dynpro_link = 5.
    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.

    CREATE OBJECT go_ltxtedit
      EXPORTING
         parent = go_ltxtcontainer
         wordwrap_mode = cl_gui_textedit=>wordwrap_at_fixed_position
         wordwrap_to_linebreak_mode = cl_gui_textedit=>true
      EXCEPTIONS
          others = 1.
    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.

  IF go_rtxtedit IS INITIAL.
    CREATE OBJECT go_rtxtcontainer
        EXPORTING
            container_name = 'G_RTEXT'
        EXCEPTIONS
            cntl_error = 1
            cntl_system_error = 2
            create_error = 3
            lifetime_error = 4
            lifetime_dynpro_dynpro_link = 5.
    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.

    CREATE OBJECT go_rtxtedit
      EXPORTING
         parent = go_rtxtcontainer
         wordwrap_mode = cl_gui_textedit=>wordwrap_at_fixed_position
         wordwrap_to_linebreak_mode = cl_gui_textedit=>true
      EXCEPTIONS
          others = 1.
    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.

* Object = T for critical auths.  Otherwise I_OBJECT is correct
  IF i_object = 'A'.
    l_object = 'T'.
  ELSEIF i_object = 'T'.
* Object = X for critical tcodes.  Otherwise I_OBJECT is correct
    l_object = 'X'.
  ELSEIF i_object = 'R'.
* Object = Q for critical roles.  Otherwise I_OBJECT is correct
    l_object = 'Q'.
  ELSE.
    l_object = i_object.
  ENDIF.


  LOOP AT gt_ldisptext ASSIGNING <text> WHERE textname = g_lid
                                          AND object   = l_object.
    APPEND <text>-text TO lt_text.
  ENDLOOP.

* Fill with text
  CALL METHOD go_ltxtedit->set_text_as_r3table
    EXPORTING
      table           = lt_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.
  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

  REFRESH lt_text.
  LOOP AT gt_rdisptext ASSIGNING <text> WHERE textname = g_rid
                                          AND object   = l_object.
    APPEND <text>-text TO lt_text.
  ENDLOOP.

* Fill with text
  CALL METHOD go_rtxtedit->set_text_as_r3table
    EXPORTING
      table           = lt_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.
  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

  CALL METHOD cl_gui_cfw=>flush
         EXCEPTIONS
           OTHERS = 1.
  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

  CALL METHOD go_ltxtedit->set_readonly_mode
       EXPORTING
         readonly_mode = cl_gui_textedit=>true
       EXCEPTIONS
         error_cntl_call_method = 1
         invalid_parameter = 2.

  CALL METHOD go_rtxtedit->set_readonly_mode
       EXPORTING
         readonly_mode = cl_gui_textedit=>true
       EXCEPTIONS
         error_cntl_call_method = 1
         invalid_parameter = 2.
ENDFORM.                    " init_text
