*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_USER_AUTH_CHANG_DATE
* AUTHOR                : Security Weaver LLC
* RELEASE               :
* DATE OF RELEASE       :
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
FUNCTION /psyng/sw_user_auth_chang_date.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      IUSR02 STRUCTURE  USR02
*"----------------------------------------------------------------------
* 1) User Master Record changed date
* 2) Profiles changed date
* 3) Authorizations changed date

  DATA: iust04 TYPE SORTED TABLE OF ust04 WITH UNIQUE KEY
               bname profile
               WITH HEADER LINE.
  DATA: wa_ust04 TYPE ust04.
  DATA: wa_usr04 TYPE usr04.

  DATA: iusr10 TYPE HASHED TABLE OF usr10 WITH UNIQUE KEY
               profn
               WITH HEADER LINE.
  DATA: wa_usr10 TYPE usr10.

  DATA: iust10s TYPE SORTED TABLE OF ust10s WITH UNIQUE KEY
                profn aktps objct auth
                WITH HEADER LINE.
  DATA: wa_ust10s.

  data: iusr12 type hashed table of usr12 with unique key
               OBJCT AUTH AKTPS
               with header line.
  data: wa_usr12 type usr12.

  DATA: syscandt TYPE HASHED TABLE OF /psyng/syscandt
                  WITH UNIQUE KEY bname conid scandate vrsio
                  WITH HEADER LINE.
  DATA: wa_syscandt TYPE /psyng/syscandt.

  data: iust10s_idx type i,
        iusr12_idx type i.


  SELECT * FROM /psyng/syscandt INTO TABLE syscandt
  WHERE    vrsio = vrsio.

  SELECT profn modda modti
         INTO CORRESPONDING FIELDS OF wa_usr10
         FROM usr10.
    INSERT wa_usr10 INTO TABLE iusr10.
  ENDSELECT.
  SELECT * FROM ust10s INTO TABLE iust10s WHERE aktps = 'A'.

  select OBJCT AUTH AKTPS MODDA MODTI
         into corresponding fields of wa_usr12
         from usr12
         where aktps = 'A'.
    insert wa_usr12 into table iusr12.
  endselect.

*For the purpose of this FM, USR02 fields are used in the following way
*GLTGV = User Scan Run Date    GLTGB = last change of user's auth
  LOOP AT iusr02.
    READ TABLE syscandt WITH KEY bname = iusr02-bname.
    IF sy-subrc = 0.
      iusr02-gltgv = syscandt-scandate.
      MODIFY iusr02.
      DELETE syscandt WHERE bname = iusr02-bname.
    ELSE.
      iusr02-gltgv = '00000000'.
      MODIFY iusr02.
      DELETE syscandt WHERE bname = iusr02-bname.
    ENDIF.
    SELECT * FROM ust04
             INTO CORRESPONDING FIELDS OF wa_ust04
             WHERE bname = iusr02-bname.
      INSERT wa_ust04 INTO TABLE iust04.
    ENDSELECT.

    LOOP AT iust04.
      CALL FUNCTION '/PSYNG/SW_GET_SINGLE_PROFS_W_C'
           EXPORTING
                profname = iust04-profile
           TABLES
                profinfo = profinfo.
      LOOP AT profinfo.
*       get last profile changed date
        READ TABLE iusr10 WITH TABLE KEY profn = profinfo-profn.
        IF sy-subrc = 0.
          IF iusr02-gltgb <= iusr10-modda.
            iusr02-gltgb = iusr10-modda.
            MODIFY iusr02.
          ENDIF.
        ENDIF.
*      get last changed date of authorization
        read table iust10s with key profn = profinfo-profn.
        if sy-subrc = 0.
          iust10s_idx = sy-tabix.
          loop at iust10s from iust10s_idx where profn = profinfo-profn.
            read table iusr12 with table key objct = iust10s-objct
                                             auth = iust10s-auth
                                             aktps = iust10s-aktps.
          endloop. "iust10s.
        endif.

      ENDLOOP.   "profinfo
    ENDLOOP.                                                "iust04
    CLEAR: iust04.
    REFRESH: iust04.

*   get last changed date of user master record
    SELECT modda
           INTO CORRESPONDING FIELDS OF wa_usr04
           FROM usr04
           WHERE bname = iusr02-bname.
      IF sy-subrc = 0.
        IF iusr02-gltgb <= wa_usr04-modda.
          iusr02-gltgb = wa_usr04-modda.
          MODIFY iusr02.
        ENDIF.
      ENDIF.
      EXIT.
    ENDSELECT.

  ENDLOOP.                                                  "iusr02

ENDFUNCTION.
