FUNCTION-POOL /PSYNG/SW_TC_AUTH            MESSAGE-ID /psyng/sw.
types :
       BEGIN OF typ_xust12,
         objct LIKE ust12-objct,
         field LIKE ust12-field,
         auth  LIKE ust12-auth,
         von   LIKE ust12-von,
         bis   LIKE ust12-bis,
       END OF typ_xust12,
       BEGIN OF typ_matching_auths,
         funid TYPE /psyng/function_id,
         tcode LIKE tstc-tcode,
         objct LIKE ust12-objct,
         auth  LIKE ust12-auth,
         field LIKE ust12-field,
         von   LIKE ust12-von,
         bis   LIKE ust12-bis,
       END OF typ_matching_auths,
       BEGIN OF typ_no_field_match,
         funid TYPE /psyng/function_id,
         tcode LIKE tstc-tcode,
         objct LIKE ust12-objct,
         auth  LIKE ust12-auth,
         field LIKE ust12-field,
       END OF typ_no_field_match.

.
data : gt_ust12 type sorted table of typ_xust12 with header line
       with unique key objct field auth von bis,
       gt_faobj  TYPE SORTED TABLE OF /psyng/faobj2 WITH UNIQUE KEY
                 funid tcode object valueset field val_from val_to
                 WITH HEADER LINE,
       gt_faobj_match
                 TYPE SORTED TABLE OF /psyng/faobj2 WITH UNIQUE KEY
                 funid tcode object valueset field val_from val_to
                 WITH HEADER LINE,

       gt_tcd    type hashed table of /PSYNG/PSSWTCD with unique key
                 tcode rfcdest,
       gt_matches
                 type table of typ_matching_auths with header line,
       gt_matching_auths type  sorted table of typ_matching_auths
                         with header line with unique key
                         funid tcode objct auth field von bis,
       gt_no_field_match type sorted table of typ_no_field_match
                         with header line with unique key
                         funid tcode objct auth field.
.
