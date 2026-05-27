class /PSYNG/SW_CL_EXTRACTOR definition
  public
  final
  create public .

*"* public components of class /PSYNG/SW_CL_EXTRACTOR
*"* do not include other source files here!!!
public section.

  class-methods GET_SOD_MATRIX
    importing
      !I_VRSIO type /PSYNG/SODVRSIO
    exporting
      !ET_FUNHDR type /PSYNG/SW_FUNHDR_T
      !ET_FUNDTL type /PSYNG/SW_FUNDTL_T
      !ET_FAOBJ type /PSYNG/SW_FAOBJ_T
      !ET_CONHDR type /PSYNG/SW_CONHDR_T
      !ET_CONDTL type /PSYNG/SW_CONDTL_T
    exceptions
      INVALID_VERSION .
protected section.
*"* protected components of class /PSYNG/SW_CL_EXTRACTOR
*"* do not include other source files here!!!
private section.
*"* private components of class /PSYNG/SW_CL_EXTRACTOR
*"* do not include other source files here!!!
ENDCLASS.



CLASS /PSYNG/SW_CL_EXTRACTOR IMPLEMENTATION.


METHOD get_sod_matrix.
  data : l_mandt type sy-mandt.
* Validate version
  SELECT SINGLE mandt INTO l_mandt FROM /psyng/swsodvers
                WHERE vrsio = i_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e156(/psyng/sw) RAISING invalid_version.
  ENDIF.

* Function header
  SELECT function description owner busarea INTO TABLE et_funhdr
         FROM /psyng/function
         WHERE vrsio = i_vrsio.

* Function details
  SELECT functionid tcode INTO TABLE et_fundtl FROM /psyng/functtran
         WHERE vrsio = i_vrsio.

* Authorization objects
  SELECT funid tcode object valueset field val_from val_to
         INTO TABLE et_faobj
         FROM /psyng/faobj2
         WHERE vrsio = i_vrsio.

* Conflict header
  SELECT conid description owner imp busarea INTO TABLE et_conhdr
         FROM /psyng/conflict
         WHERE vrsio    = i_vrsio
           AND inactive = space.

* Conflict details
  SELECT conid functionid INTO TABLE et_condtl FROM /psyng/confdet
         WHERE vrsio = i_vrsio.
ENDMETHOD.
ENDCLASS.
