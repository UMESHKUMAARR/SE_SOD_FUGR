*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: /PSYNG/VRS_AND..................................*
DATA:  BEGIN OF STATUS_/PSYNG/VRS_AND                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/VRS_AND                .
CONTROLS: TCTRL_/PSYNG/VRS_AND
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: */PSYNG/VRS_AND                .
TABLES: /PSYNG/VRS_AND                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
