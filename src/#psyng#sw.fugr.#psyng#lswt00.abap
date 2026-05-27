*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 24.10.2013 at 03:18:06 by user HSHARMA
*---------------------------------------------------------------------*
*...processing: /PSYNG/BUSAREA..................................*
DATA:  BEGIN OF STATUS_/PSYNG/BUSAREA                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/BUSAREA                .
CONTROLS: TCTRL_/PSYNG/BUSAREA
            TYPE TABLEVIEW USING SCREEN '0002'.
*...processing: /PSYNG/BUS_PROCE................................*
DATA:  BEGIN OF STATUS_/PSYNG/BUS_PROCE              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/BUS_PROCE              .
CONTROLS: TCTRL_/PSYNG/BUS_PROCE
            TYPE TABLEVIEW USING SCREEN '0012'.
*...processing: /PSYNG/SOD_VRSIO................................*
DATA:  BEGIN OF STATUS_/PSYNG/SOD_VRSIO              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SOD_VRSIO              .
CONTROLS: TCTRL_/PSYNG/SOD_VRSIO
            TYPE TABLEVIEW USING SCREEN '0005'.
*...processing: /PSYNG/SWCONFIG.................................*
DATA:  BEGIN OF STATUS_/PSYNG/SWCONFIG               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SWCONFIG               .
CONTROLS: TCTRL_/PSYNG/SWCONFIG
            TYPE TABLEVIEW USING SCREEN '0001'.
*...processing: /PSYNG/SWCUSVERS................................*
DATA:  BEGIN OF STATUS_/PSYNG/SWCUSVERS              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SWCUSVERS              .
CONTROLS: TCTRL_/PSYNG/SWCUSVERS
            TYPE TABLEVIEW USING SCREEN '0008'.
*...processing: /PSYNG/SWSODORGM................................*
DATA:  BEGIN OF STATUS_/PSYNG/SWSODORGM              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SWSODORGM              .
CONTROLS: TCTRL_/PSYNG/SWSODORGM
            TYPE TABLEVIEW USING SCREEN '0007'.
*...processing: /PSYNG/SW_PRJ01.................................*
DATA:  BEGIN OF STATUS_/PSYNG/SW_PRJ01               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SW_PRJ01               .
CONTROLS: TCTRL_/PSYNG/SW_PRJ01
            TYPE TABLEVIEW USING SCREEN '0004'.
*...processing: /PSYNG/SW_STA01.................................*
DATA:  BEGIN OF STATUS_/PSYNG/SW_STA01               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SW_STA01               .
CONTROLS: TCTRL_/PSYNG/SW_STA01
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: /PSYNG/SW_VRSIO.................................*
DATA:  BEGIN OF STATUS_/PSYNG/SW_VRSIO               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_/PSYNG/SW_VRSIO               .
CONTROLS: TCTRL_/PSYNG/SW_VRSIO
            TYPE TABLEVIEW USING SCREEN '0006'.
*.........table declarations:.................................*
TABLES: */PSYNG/BUSAREA                .
TABLES: */PSYNG/BUS_PROCE              .
TABLES: */PSYNG/SOD_VRSIO              .
TABLES: */PSYNG/SWCONFIG               .
TABLES: */PSYNG/SWCUSVERS              .
TABLES: */PSYNG/SWSODORGM              .
TABLES: */PSYNG/SW_PRJ01               .
TABLES: */PSYNG/SW_STA01               .
TABLES: */PSYNG/SW_VRSIO               .
TABLES: /PSYNG/BUSAREA                 .
TABLES: /PSYNG/BUS_PROCE               .
TABLES: /PSYNG/SOD_VRSIO               .
TABLES: /PSYNG/SWCONFIG                .
TABLES: /PSYNG/SWCUSVERS               .
TABLES: /PSYNG/SWSODORGM               .
TABLES: /PSYNG/SW_PRJ01                .
TABLES: /PSYNG/SW_STA01                .
TABLES: /PSYNG/SW_VRSIO                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
