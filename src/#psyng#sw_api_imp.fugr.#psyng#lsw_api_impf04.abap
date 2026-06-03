*&---------------------------------------------------------------------*
*&  Include           /PSYNG/LSW_API_IMPF04
*&  Function Group    /PSYNG/SW_API_IMP
*&  Description       SE API - Batch Paginated Read (FM3 subroutines)
*&---------------------------------------------------------------------*
*&  PN-XXXXX  FM3 /PSYNG/SW_API_RESDET_READ_ALL helper FORMs
*&  Author  : UMITTAL
*&  Date    : 02.06.2026
*&---------------------------------------------------------------------*
*&  build_seq_range and transfer_to_output are intentionally inline
*&  in the FM body. Both are 4-5 lines and involve ECC-incompatible
*&  FORM parameter typing when separated. build_success_message is
*&  here because it has real char-conversion logic worth isolating.
*&---------------------------------------------------------------------*


*======================================================================*
* FORM build_success_message
* Composes the success message string for both modes.
* INT4 inputs must be written to char vars before CONCATENATE —
* CONCATENATE requires character-type operands in ECC (C/N/D/T/STRING).
* iv_mode: 'R' = range mode, 'C' = cursor mode.
*======================================================================*
FORM build_success_message
  USING    iv_mode   TYPE c
           iv_from   TYPE i
           iv_to     TYPE i
           iv_rows   TYPE i
           iv_cursor TYPE i
  CHANGING ev_msg    TYPE string.

  DATA: lv_from_c   TYPE char10,
        lv_to_c     TYPE char10,
        lv_rows_c   TYPE char20,
        lv_cursor_c TYPE char10.

  WRITE iv_from   TO lv_from_c   LEFT-JUSTIFIED.
  WRITE iv_to     TO lv_to_c     LEFT-JUSTIFIED.
  WRITE iv_rows   TO lv_rows_c   LEFT-JUSTIFIED.
  WRITE iv_cursor TO lv_cursor_c LEFT-JUSTIFIED.

  CONDENSE lv_from_c.
  CONDENSE lv_to_c.
  CONDENSE lv_rows_c.
  CONDENSE lv_cursor_c.

  IF iv_mode = 'R'.
    CONCATENATE 'Range mode: SEQ' lv_from_c '-' lv_to_c
                '| Rows:' lv_rows_c
                '| Cursor unchanged at:' lv_cursor_c
      INTO ev_msg SEPARATED BY ' '.
  ELSE.
    CONCATENATE 'Cursor mode: SEQ' lv_from_c '-' lv_to_c
                '| Rows:' lv_rows_c
                '| Cursor now at:' lv_cursor_c
      INTO ev_msg SEPARATED BY ' '.
  ENDIF.

ENDFORM.
