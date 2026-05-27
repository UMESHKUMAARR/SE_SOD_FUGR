*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/CAR_TOP                                             *
*----------------------------------------------------------------------*
DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
        yusloc   TYPE x VALUE '40',     "Locked by Administrator
        yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
DATA : l_uflagx TYPE x.

DATA: iusr02 LIKE usr02 OCCURS 0 WITH HEADER LINE,
      gt_uidn TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.

DATA: tvdia TYPE i,    "total valid dialog users
      tvndia TYPE i,   "total valid non-dialog users
      tvusers TYPE i,  "total valid users

      tldia TYPE i,    "total locked dialog users
      tlndia TYPE i,   "total locked non-dialog users
      tlusers TYPE i,  "total locked dialog users

      teusers TYPE i,  "total expired users
      tedia TYPE i,    "total expired dialog users
      tendia TYPE i,   "total expired non-dialog users

      tusers TYPE i,   "total users.
      tdia  TYPE i,    "total dialog
      tcomm TYPE i,    "total communication
      tsys  TYPE i,    "total system (background)
      tservice TYPE i, "total service
      tref  TYPE i,    "total reference

      comp LIKE uscompany-company,   "company name
      usname LIKE adrp-name_text.    "execution user name

   DATA: sodcount(100). " type n.
