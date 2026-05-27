*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_002
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_002.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(ROLENAME) LIKE  AGR_1251-AGR_NAME OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      OUTPUT STRUCTURE  /PSYNG/OUTPUT OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_002'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  DATA: iagr_1251 TYPE STANDARD TABLE OF agr_1251 WITH HEADER LINE.
  DATA: jagr_1251 TYPE STANDARD TABLE OF agr_1251 WITH HEADER LINE.
  DATA: iswaudc TYPE STANDARD TABLE OF /psyng/swaudc WITH HEADER LINE.

  DATA: outputflag,
        fprocess.
  DATA: BEGIN OF oswaudc.
          INCLUDE STRUCTURE /psyng/swaudc.
  DATA:     uflag.
  DATA:      END OF oswaudc.

  DATA  t_oswaudc LIKE oswaudc OCCURS 0 WITH HEADER LINE.

  SELECT * FROM /psyng/swaudc INTO CORRESPONDING FIELDS OF TABLE
  iswaudc
  WHERE vrsio = vrsio.



  SELECT * FROM agr_1251 INTO CORRESPONDING FIELDS OF TABLE iagr_1251
  WHERE agr_name = rolename
  AND   deleted  = space.

  SORT iswaudc BY swaudid.
  DELETE ADJACENT DUPLICATES FROM iswaudc COMPARING swaudid.

  SORT iagr_1251 BY auth.
  DELETE ADJACENT DUPLICATES FROM iagr_1251 COMPARING auth.

  LOOP AT iswaudc.
    outputflag = space.
    REFRESH t_oswaudc. CLEAR t_oswaudc.
    SELECT * FROM /psyng/swaudc           "#EC CI_SEL_NESTED
      INTO TABLE t_oswaudc
    WHERE swaudid = iswaudc-swaudid.

    LOOP AT iagr_1251.
      SELECT * FROM agr_1251 INTO TABLE jagr_1251
      WHERE  agr_name = rolename
      AND deleted = space
*      AND OBJECT  = ISWAUDC-OBJECT
      AND auth    = iagr_1251-auth.
      IF sy-subrc = 0.

        LOOP AT t_oswaudc.
          t_oswaudc-uflag = space.
          MODIFY t_oswaudc.
          IF t_oswaudc-tcode = '*'.
            READ TABLE jagr_1251 WITH KEY
            object = t_oswaudc-object
            field = t_oswaudc-field.
            IF sy-subrc = 0.
              IF jagr_1251-high = space.
                IF jagr_1251-low = t_oswaudc-val_from
                OR jagr_1251-low = '*'
                OR jagr_1251-low = t_oswaudc-val_to.
                  t_oswaudc-uflag = 'X'.
                  MODIFY t_oswaudc.
                ENDIF.
                IF jagr_1251-field <> 'ACTVT'.
                  IF jagr_1251-low(1) = t_oswaudc-val_from(1).
                    IF jagr_1251-low >= t_oswaudc-val_from.
                      t_oswaudc-uflag = 'X'.
                      MODIFY t_oswaudc.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ELSE.
                IF  jagr_1251-low        >= t_oswaudc-val_from
                    AND jagr_1251-high    <= t_oswaudc-val_to.
                  t_oswaudc-uflag = 'X'.
                  MODIFY t_oswaudc.
                ENDIF.
              ENDIF.

            ENDIF.
          ELSE.
* Logic to get the TCODE first from AGR_1251 table, if present then go
*forward, otherwise EXIT.
            READ TABLE jagr_1251 WITH KEY
              object = 'S_TCODE'
              field = 'TCD'.

            fprocess = space.

            IF jagr_1251-low(1) = t_oswaudc-tcode(1)
               OR jagr_1251-high(1) = t_oswaudc-tcode(1).

              IF jagr_1251-high > space.
                IF t_oswaudc-tcode >= jagr_1251-low AND
                t_oswaudc-tcode <= jagr_1251-high.
                  fprocess = 'X'.
                ENDIF.
              ELSE.
                IF t_oswaudc-tcode >= jagr_1251-low.

                  "T_OSWAUDC-TCODE= PFCG and JAGR_1251-LOW = P*

                  fprocess = 'X'.
                ENDIF.
              ENDIF.
            ENDIF.
*==================================================================
*            READ TABLE JAGR_1251 WITH KEY
*              OBJECT = 'S_TCODE'
*              FIELD = 'TCD'.
*              LOW   =  T_OSWAUDC-TCODE.
*             IF SY-SUBRC = 0.
            IF fprocess = 'X'.
              READ TABLE jagr_1251 WITH KEY
              object = t_oswaudc-object
              field = t_oswaudc-field.
              IF sy-subrc = 0.
                IF jagr_1251-high = space.
                  IF jagr_1251-low = t_oswaudc-val_from
                  OR jagr_1251-low = '*'
                  OR jagr_1251-low = t_oswaudc-val_to.
                    t_oswaudc-uflag = 'X'.
                    MODIFY t_oswaudc.
                  ENDIF.
                  IF jagr_1251-field <> 'ACTVT'.
                    IF jagr_1251-low(1) = t_oswaudc-val_from(1).
                      IF jagr_1251-low >= t_oswaudc-val_from.
                        t_oswaudc-uflag = 'X'.
                        MODIFY t_oswaudc.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                ELSE.
                  IF  jagr_1251-low        >= t_oswaudc-val_from
                      AND jagr_1251-high    <= t_oswaudc-val_to.
                    t_oswaudc-uflag = 'X'.
                    MODIFY t_oswaudc.
                  ENDIF.
                ENDIF.

              ENDIF.
            ENDIF.
*=======================================================================


          ENDIF. "TCODE = '*'

        ENDLOOP.
      ENDIF.
      outputflag = 'X'.
      LOOP AT t_oswaudc.
        IF t_oswaudc-uflag = space.
          outputflag = space.
        ENDIF.
      ENDLOOP.
      IF outputflag = 'X'.
        output-swaudid = t_oswaudc-swaudid.
        APPEND output.
      ENDIF.
    ENDLOOP.

  ENDLOOP.

ENDFUNCTION.
