class /PSYNG/CL_IM_SW_REQT_CHECK definition
  public
  final
  create public .

*"* public components of class /PSYNG/CL_IM_SW_REQT_CHECK
*"* do not include other source files here!!!
public section.

  interfaces IF_EX_CTS_REQUEST_CHECK .
protected section.
*"* protected components of class /PSYNG/CL_IM_SW_REQT_CHECK
*"* do not include other source files here!!!
private section.
*"* private components of class /PSYNG/CL_IM_SW_REQT_CHECK
*"* do not include other source files here!!!
ENDCLASS.



CLASS /PSYNG/CL_IM_SW_REQT_CHECK IMPLEMENTATION.


  method IF_EX_CTS_REQUEST_CHECK~CHECK_BEFORE_ADD_OBJECTS.
  endmethod.


method IF_EX_CTS_REQUEST_CHECK~CHECK_BEFORE_CHANGING_OWNER.
* ...
endmethod.


method IF_EX_CTS_REQUEST_CHECK~CHECK_BEFORE_CREATION.
* ...
endmethod.


method IF_EX_CTS_REQUEST_CHECK~CHECK_BEFORE_RELEASE.
*--------------------------------------------------
* If the transport contains roles, Separations Enforcer
* will check if there are issues with these roles.
* This can be enables/disabled by changing the value of
* Configuration Parameter SW_TRANSPORT_CHECK in the misc.
* Tab of Separations Enforcer (/PSYNG/SE).
* N or <Blank> means, no check is executed
* Y or X means : The roles in the request are analyzed
*--------------------------------------------------
CALL FUNCTION '/PSYNG/SW_TRANSPORT_CHECK'
  EXPORTING
    i_request           = request
    i_owner             = owner
    i_type              = type
  tables
    it_attributes       = attributes
    it_objects          = objects
  changing
    text                = text
 EXCEPTIONS
   CANCEL              = 1
   OTHERS              = 2
          .
IF sy-subrc  = 1.
  raise CANCEL.
ENDIF.
endmethod.


  method IF_EX_CTS_REQUEST_CHECK~CHECK_BEFORE_RELEASE_SLIN.
  endmethod.
ENDCLASS.
