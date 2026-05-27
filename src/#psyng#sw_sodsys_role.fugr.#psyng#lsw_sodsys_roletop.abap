FUNCTION-POOL /psyng/sw_sodsys_role.        "MESSAGE-ID ..

tables: ust12.

TYPES:

       BEGIN OF typ_iagrprof,
         profile LIKE agr_prof-profile,
         agr_name LIKE agr_prof-agr_name,
       END OF typ_iagrprof

.

DATA:
      iagrprof TYPE SORTED TABLE OF typ_iagrprof WITH UNIQUE KEY
               profile agr_name
               WITH HEADER LINE,

      wa_iagrprof TYPE typ_iagrprof,

      fr_low          TYPE ust12-von,
      to_high         TYPE ust12-von,
      first_char      TYPE c,

      dbtstc          TYPE SORTED TABLE OF tstc WITH UNIQUE KEY tcode
                      WITH HEADER LINE,
      wa_dbtstc       TYPE tstc,

      BEGIN OF faobj1 OCCURS 100,              "Table to do binary
        object LIKE /psyng/faobj2-object,   "searches on object
*        funid LIKE /psyng/faobj2-funid,
*        tcode LIKE /psyng/faobj2-tcode,
*        field LIKE /psyng/faobj2-field,
*        val_from LIKE /psyng/faobj2-val_from,
*        val_to LIKE /psyng/faobj2-val_to,
      END OF faobj1,

      BEGIN OF ftcodes OCCURS 0,  "Unique list of tcodes in SOD matrix
        tcode LIKE sy-tcode,      "used to perfrom binary searches
      END OF ftcodes


.
