*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 19.11.2019 at 00:51:15 by user DDHIMAN
*---------------------------------------------------------------------*
*...processing: /PSYNG/SWSODORGO................................*
DATA:  BEGIN OF STATUS_/PSYNG/SWSODORGO              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SWSODORGO              .
CONTROLS: TCTRL_/PSYNG/SWSODORGO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */PSYNG/SWSODORGO              .
TABLES: /PSYNG/SWSODORGO               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
