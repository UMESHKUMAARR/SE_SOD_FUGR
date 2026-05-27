FUNCTION-POOL /psyng/sw_mit.                "MESSAGE-ID ..
INCLUDE /psyng/sw_config.
type-pools : slis.
DATA :
BEGIN OF gs_mc_freq OCCURS 0,
   contid        TYPE /psyng/contid,
   frequency     TYPE /PSYNG/FREQ,
   numdays(3)    TYPE c,
   AUTO_AM       TYPE /PSYNG/SE_MC_AUTO_AM,
   AUTO_TCODE    TYPE /PSYNG/SE_MC_AUTO_TCODE,
   AUTO_CHANGES   TYPE /PSYNG/SE_MC_AUTO_CHANGES,
END OF gs_mc_freq,
gt_mc_freq like hashed table of gs_mc_freq with unique key contid with
header line,
gt_functtran    type table of /PSYNG/FUNCTTRAN with header line,
gt_confdet      type table of /psyng/confdet   with header line,
gt_faobj        type table of /psyng/faobj2    with header line,
gt_ca_functtran type table of /PSYNG/FUNCTTRAN with header line,
gt_ca_confdet   type table of /psyng/confdet   with header line,
gt_ca_faobj     type table of /psyng/faobj2    with header line,
BEGIN OF NEW_LINE,
        x(2) TYPE x VALUE '0D0A',
END OF NEW_LINE,
S_NEW_LINE(2)   type c,
gf_mit_by_org type flag.

define log.
*--Add message to log, if it doesn't exist yet
read table &1 with key
   type       = &2
   message    = &3
   message_v1 = &4
   message_v2 = &5
   message_v3 = &6
   transporting no fields.
  if sy-subrc <> 0.
    &1-type       = &2.
    &1-message    = &3.
    &1-message_v1 = &4.
    &1-message_v2 = &5.
    &1-message_v3 = &6.
    append &1.
  endif.
  clear &1.
end-of-definition.
