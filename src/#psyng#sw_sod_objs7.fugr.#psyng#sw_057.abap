FUNCTION /psyng/sw_057.
*"----------------------------------------------------------------------
*"*"Local interface:
*"----------------------------------------------------------------------
*-release the memory that was used for User Buffer data
  FREE:
  gt_usrbf2,
  gt_ust12_buffer,
  gt_usrbf3,
  gf_usrbf3_loaded,
  gf_usrbf2_loaded,
  gt_refusers,
  gt_ust10s.


ENDFUNCTION.
