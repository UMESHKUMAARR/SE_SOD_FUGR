FUNCTION /psyng/sw_038.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_BNAME) TYPE  XUBNAME
*"  EXPORTING
*"     VALUE(EF_HAS_CONFLICT) TYPE  /PSYNG/BAPIFLAGX
*"  TABLES
*"      IT_SIMUAGRS STRUCTURE  AGR_DEFINE OPTIONAL
*"----------------------------------------------------------------------
  DATA: l_function TYPE adcp-function.


  CHECK NOT it_simuagrs[] IS INITIAL.

* Get function from user master
  SELECT SINGLE adcp~function INTO l_function
    FROM usr21 INNER JOIN adcp
      ON usr21~addrnumber = adcp~addrnumber
     AND usr21~persnumber = adcp~persnumber
   WHERE usr21~bname = i_bname.

  CHECK NOT l_function IS INITIAL.

* Compare function to simulation role names
*  LOOP AT it_simuagrs.
*    IF it_simuagrs-agr_name+10(2) <> l_function.
*      ef_has_conflict = 'X'.
*      EXIT.
*    ENDIF.
*  ENDLOOP.

* For getting the Org abb of simulated AGRs
  TYPES: BEGIN OF typ_agr_auths,
           rfcdest LIKE rfcdes-rfcdest,
           agr_name LIKE agr_define-agr_name,
           app LIKE /psyng/swsodorgm-abb,
           authh LIKE agr_1251-auth,
         END OF typ_agr_auths.

  DATA: lt_agr_auths TYPE STANDARD TABLE OF typ_agr_auths
        WITH HEADER LINE.

  DATA: lt_swsodorgm TYPE STANDARD TABLE OF /psyng/swsodorgm
        WITH HEADER LINE.
  DATA: lt_uniqueauths TYPE STANDARD TABLE OF /psyng/swsodorgm
        WITH HEADER LINE.
  DATA: lt_systemauths TYPE STANDARD TABLE OF /PSYNG/SWSODORGAUTH
        WITH HEADER LINE.

  IF lt_agr_auths[] IS INITIAL.
* If the auths of simulated roles are not already collected
    LOOP AT it_simuagrs.
      SELECT * FROM /psyng/swsodorgm                 "#EC CI_SEL_NESTED
          INTO TABLE lt_swsodorgm.                   "#EC CI_NOWHERE

      CALL FUNCTION '/PSYNG/SW_024'
           TABLES
                swsodorgm   = lt_swsodorgm
                uniqueauths = lt_uniqueauths
                systemauths = lt_systemauths.


    ENDLOOP.
  ENDIF.


ENDFUNCTION.
