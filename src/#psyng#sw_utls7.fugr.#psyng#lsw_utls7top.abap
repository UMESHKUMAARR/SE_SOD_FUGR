FUNCTION-POOL /PSYNG/SW_UTLS7.              "MESSAGE-ID ..
CONSTANTS : gc_ta_func TYPE rs38l-name value '/PSYNG/BC_USRHIS_018',
            gc_ta_func_21 TYPE rs38l-name value '/PSYNG/BC_USRHIS_030'.
DATA: BEGIN OF months OCCURS 0.
DATA:   month LIKE sy-datum.
DATA: END OF months.



DATA:BEGIN OF gt_keys OCCURS 0,
     objectid TYPE cdpos-objectid,
     tabname TYPE ddobjname,
     old_key(250) TYPE c,
     new_key(250) TYPE c,
     END OF gt_keys.
DATA:BEGIN OF gt_tab_info OCCURS 0,
      tabname TYPE dfies-tabname,
      fieldname TYPE dfies-fieldname,
      leng TYPE dfies-leng,
      fieldtext TYPE dfies-fieldtext,
      keyflag TYPE dfies-keyflag,
      END OF gt_tab_info.
