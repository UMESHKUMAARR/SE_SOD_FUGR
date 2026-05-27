*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_COMPAREF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  compare
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<PAIR>_AUTH_FROM  text
*      -->P_<PAIR>_AUTH_TO    text
*      -->P_<PAIR>_SOD_FROM   text
*      -->P_<PAIR>_SOD_TO     text
*      <--P_<PAIR>_MATCH      text
*----------------------------------------------------------------------*
FORM compare USING    auth_from
                      auth_to
                      sod_from
                      sod_to
             CHANGING match.
  STATICS :sod  TYPE TABLE OF /psyng/auth_range WITH HEADER LINE,
           auth TYPE TABLE OF /psyng/auth_range WITH HEADER LINE.
*"----------------------------------------------------------------------
*" Fastest possible comparison
*" Do a simple compare and exit when sod and auth are identical
*"----------------------------------------------------------------------
  if SOD_FROM = AUTH_FROM and
     SOD_TO   = AUTH_TO.
       match = 'X'.
       exit.
  endif.


  REFRESH : sod, auth.
  CLEAR : sod, auth.


* Exception - if SOD_FROM = '*', then it is not meant as a wildcard
* character but must have a matching '*' in AUTH_FROM.
  IF sod_from = '*'.
    IF auth_from = '*'.
      match = 'X'.
    ELSE.
      CLEAR match.
    ENDIF.

    EXIT.
  ENDIF.
* Exception - "+" is a single character wild card in ABAP, but it is not
*             in authorizations.  When any of the fields contains a "+",
*             a different comparison is required
  IF auth_from CS '+' OR auth_to CS '+' OR
     sod_from  CS '+' OR sod_to  CS '+' .
    PERFORM compare_plus USING auth_from
                    auth_to
                    sod_from
                    sod_to
           CHANGING match.
    EXIT.
  ENDIF.

*"----------------------------------------------------------------------
*" Create Ranges Table
*"----------------------------------------------------------------------
  IF sod_to IS INITIAL.    "If SOD TO is not filled
    IF  sod_from CS '*'.
      sod-sign = 'I'.
      sod-option = 'CP'.
      sod-low =  sod_from.
      APPEND sod.
    ELSE.
      IF NOT sod_from IS INITIAL.
        sod-sign = 'I'.
        sod-option = 'EQ'.
        sod-low =  sod_from.
        APPEND sod.
      ENDIF.
    ENDIF.
  ELSE.                 "If SOD TO is filled
    sod-sign = 'I'.
    sod-option = 'BT'.
    sod-low =  sod_from.
    sod-high =  sod_to.
    APPEND sod.
  ENDIF.
  IF  auth_to IS INITIAL.    "If AUTH TO is not filled 4/30/09
    IF  auth_from CS '*'.
      auth-sign = 'I'.
      auth-option = 'CP'.
      auth-low =  auth_from.
      APPEND auth.
    ELSE.
      auth-sign = 'I'.
      auth-option = 'EQ'.
      auth-low =  auth_from.
      APPEND auth.
    ENDIF.
  ELSE.                 "if Auth TO is filled
    auth-sign = 'I'.
    auth-option = 'BT'.
    auth-low =  auth_from.
    auth-high =  auth_to.
    APPEND auth.
  ENDIF.
*"----------------------------------------------------------------------
*" Compare the ranges
*"----------------------------------------------------------------------
*--DHORIONS 20101123 - SAP allows ranges where the HIGH value
*                                 comes before the LOW value
  IF NOT auth-high IS INITIAL AND auth-high < auth-low. "#EC PORTABLE
    IF sod-low  IN auth       OR  sod-high  IN auth OR
       auth-low IN sod        OR  auth-high IN sod.
      match = 'X'.
    ELSE.
      CLEAR match .
    ENDIF.
  ELSE.
*  If values in range using SAP standard range functionality
    IF sod-low  IN auth       OR  sod-high  IN auth OR
       auth-low IN sod        OR  auth-high IN sod  OR
*  Contains pattern ranges
       sod-low   CP auth-low  OR  sod-low  CP auth-high OR
       auth-low  CP sod-low   OR  auth-low CP sod-high  OR
       auth-high CP sod-low   OR  sod-high CP auth-low  OR
*  "TO" Ranges
      ( sod-high   CP auth-high AND NOT sod-high  IS INITIAL ) OR
      ( auth-high  CP sod-high  AND NOT auth-high IS INITIAL ) .
      match = 'X'.
    ELSE.
      CLEAR match .
    ENDIF.
  ENDIF.
*--Special Scenario for when a Variable Element did not contain any values, but the user had a * authorization
  if match =  'X' and auth_from = '*' and sod_from EQ '/PSYNG/$INVALIDVE$'.
    clear match.
  endif.

ENDFORM.                    " compare
*&---------------------------------------------------------------------*
*&      Form  compare_plus
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_AUTH_FROM  text
*      -->P_AUTH_TO  text
*      -->P_SOD_FROM  text
*      -->P_SOD_TO  text
*      <--P_MATCH  text
*----------------------------------------------------------------------*
FORM compare_plus USING    auth_from
                           auth_to
                           sod_from
                           sod_to
                  CHANGING match.
  DATA : l_auth_from TYPE string,
         l_auth_to   TYPE string,
         l_sod_from  TYPE string,
         l_sod_to    TYPE string.
  CONSTANTS lc_replace(1) TYPE c VALUE '#'.
  l_auth_from = auth_from.
  l_auth_to   = auth_to.
  l_sod_from  = sod_from.
  l_sod_to    = sod_to.


  REPLACE '+' WITH lc_replace INTO   l_auth_from.
  REPLACE '+' WITH lc_replace INTO   l_auth_to.
  REPLACE '+' WITH lc_replace INTO   l_sod_from.
  REPLACE '+' WITH lc_replace INTO   l_sod_to.
  PERFORM compare
              USING
                 l_auth_from
                 l_auth_to
                 l_sod_from
                 l_sod_to
              CHANGING
                 match.
ENDFORM.                    " compare_plusDFORM.
