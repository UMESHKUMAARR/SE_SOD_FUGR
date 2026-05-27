FUNCTION-POOL /psyng/sw_auto_org.         "MESSAGE-ID ..
INCLUDE /psyng/sw_config.
TYPE-POOLS : rsds,shlp.
CONSTANTS :
ct_t001   TYPE tabname VALUE 'T001',
ct_t001b  TYPE tabname VALUE 'T001B',
ct_t024e  TYPE tabname VALUE 'T024E',
ct_t024w  TYPE tabname VALUE 'T024W',
ct_tfacd  TYPE tabname VALUE 'TFACD',
ct_tvko   TYPE tabname VALUE 'TVKO',
ct_tvkot  TYPE tabname VALUE 'TVKOT',
ct_t001w  TYPE tabname VALUE 'T001W',
ct_t001k  TYPE tabname VALUE 'T001K',
ct_tvkos  TYPE tabname VALUE 'TVKOS',
ct_tvta   TYPE tabname VALUE 'TVTA',
ct_tspat  TYPE tabname VALUE 'TSPAT',
ct_tvkov  TYPE tabname VALUE 'TVKOV',
ct_tvtwt  TYPE tabname VALUE 'TVTWT',
ct_tgsbt  TYPE tabname VALUE 'TGSBT',
ct_t134g  TYPE tabname VALUE 'T134G',
ct_t134h  TYPE tabname VALUE 'T134H',
ct_tka02  TYPE tabname VALUE 'TKA02',
ct_tka01  TYPE tabname VALUE 'TKA01',
ct_t014t  TYPE tabname VALUE 'T014T',
ct_t001cm TYPE tabname VALUE 'T001CM',
ct_tvswz  TYPE tabname VALUE 'TVSWZ',
ct_tvst   TYPE tabname VALUE 'TVST',
ct_tvstt  TYPE tabname VALUE 'TVSTT',


cf_bukrs_validate TYPE rs38l_fnam VALUE 'BAPI_COMPANYCODE_GET_PERIOD'.

TYPES :

BEGIN OF t_t001,
bukrs(4) TYPE c,
butxt(25) TYPE c,
kkber(4) TYPE c,
opvar(4) TYPE c,
ktopl(4) TYPE c,
END OF t_t001,

BEGIN OF t_t024e,
ekorg(4) TYPE c,
bukrs(4) TYPE c,
ekotx(20) TYPE c,
END OF t_t024e,

BEGIN OF t_t024w,
ekorg(4) TYPE c,
werks(4) TYPE c,
END OF t_t024w,



BEGIN OF t_tfacd,
ident(2) TYPE c,
vjahr(4) TYPE c,
bjahr(4) TYPE c,
END OF t_tfacd,

BEGIN OF t_t001w,
werks(4) TYPE c,
ekorg(4) TYPE c,
vkorg(4) TYPE c ,
name1(30) TYPE c,
fabkl(2) TYPE c ,
bwkey(4) TYPE c,
END OF t_t001w,

BEGIN OF t_t001k,
bukrs(4) TYPE c,
bwkey(4) TYPE c,
END OF t_t001k,

BEGIN OF t_tvkos,
spart(2) TYPE c,
vkorg(4) TYPE c,
END OF t_tvkos,

BEGIN OF t_tspat,
spart(2) TYPE c,
vtext(20) TYPE c,
END OF t_tspat,

BEGIN OF t_tvkov,
vtweg(2) TYPE c,
vkorg(4) TYPE c,
END OF t_tvkov,

BEGIN OF t_tvtwt,
vtweg(2) TYPE c,
vtext(20) TYPE c,
END OF t_tvtwt,

BEGIN OF t_tgsbt,
gsber(4) TYPE c,
gtext(30) TYPE c,
END OF t_tgsbt,

BEGIN OF t_t134h,
bwkey(4) TYPE c,
spart(2) TYPE c,
gsber(4) TYPE c,
END OF t_t134h,

BEGIN OF t_t134g,
spart(2) TYPE c,
gsber(4) TYPE c,
werks(4) TYPE c,
END OF t_t134g,

BEGIN OF t_tka01,
kokrs(4) TYPE c,
bezei(25) TYPE c,
lmona(2) TYPE c,
END OF t_tka01,

BEGIN OF t_tka02,
bukrs(4) TYPE c,
kokrs(4) TYPE c,
END OF t_tka02,

BEGIN OF t_t014t,
kkber(4) TYPE c,
kkbtx(35) TYPE c,
END OF t_t014t,

BEGIN OF t_t001cm,
kkber(4) TYPE c,
bukrs(4) TYPE c,
END OF t_t001cm,

BEGIN OF t_tvswz,
werks(4) TYPE c,
vstel(4) TYPE c,
END OF t_tvswz,

BEGIN OF t_tvst,
vstel(4) TYPE c,
fabkl(2) TYPE c,
END OF t_tvst,

BEGIN OF t_tvstt,
vstel(4) TYPE c,
vtext(30) TYPE c,
END OF t_tvstt,

BEGIN OF t_tvta,
  vkorg(4) TYPE c,
  spart(2) TYPE c,
  vtweg(2) TYPE c,
END OF t_tvta.


DATA : BEGIN OF gt_join OCCURS 0,
         table     TYPE tabname,
         field     TYPE fieldname,
         jointable TYPE tabname,
         joinfield TYPE fieldname,
       END OF gt_join.


DATA : gt_varel TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE.
*define log.
*  &1-TYPE    = &2.
*  concatenate &3 &4 &5 into  &1-message separated by space.
*  append &1.
*end-of-definition.

DEFINE where.
  concatenate &2 &3 into  &1-line .
  append &1.
END-OF-DEFINITION.
DEFINE wherefield.
*&2 = field
*&3 = condition
*&4 = value
  concatenate '''' &4 '''' into &4.
  concatenate &2 &3 &4 into  &1-line separated by space.
  append &1.
END-OF-DEFINITION.
*--Macro for Logging into a structure of type BAPIRET2
* &1 : table of type BAPIRET2 with header line
* &2 : Message type: S Success, E Error, W Warning, I Info, A Abort
* &3 : ID, Message class
* &4 : Message text part 1
* &5 : Message text part 2
* &6 : Message text part 3
* &7 : Message text part 4

DEFINE log.
  &1-TYPE    = &2.
  &1-ID      = &3.
  concatenate &4 &5 &6 &7 into &1-MESSAGE separated by space.
  append &1.
END-OF-DEFINITION.


*--Variables for screen 100
DATA :
g_100_setid           TYPE  /psyng/seconfid,
g_100_vrsio           TYPE  /psyng/sodvrsio,
g_100_show_warning    TYPE  flag ,
g_100_valid           TYPE  flag,
g_100_wrong_version   TYPE  flag,
g_100_unpublished     TYPE  flag,
g_100_missingsystem   TYPE  flag,
g_system_mismatch     TYPE  flag,
g_100_msg_1           TYPE string,
g_100_msg_2           TYPE string,
g_100_msg_3           TYPE string.

*--Variables for /psyng/sw_configset_save
DATA: g_set_id TYPE /psyng/seconfid.
