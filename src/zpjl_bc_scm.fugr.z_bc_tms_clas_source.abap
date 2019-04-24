FUNCTION Z_BC_TMS_CLAS_SOURCE.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_CLASSNAME) TYPE  SEOCLSNAME
*"  EXPORTING
*"     VALUE(EV_SUPER) TYPE  SEOCLSNAME
*"     VALUE(ET_METHODS) TYPE  SEO_METHODS
*"  TABLES
*"      ET_TEST STRUCTURE  PROGTAB
*"      ET_SOURCE STRUCTURE  PROGTAB
*"----------------------------------------------------------------------
  DATA:
    lv_sep   TYPE c,
    lt_main  TYPE stringtab,
    lt_test  TYPE stringtab,
    lt_macro TYPE stringtab,
    lt_local TYPE stringtab.
  lv_sep = |\n|.
  TRY.
      DATA(cls) = zcl_bc_scm_class_adapter=>find_by_name( iv_classname ).
      CALL METHOD cls->read_source
        IMPORTING
          et_main  = lt_main
          et_test  = lt_test
          et_macro = lt_macro
          et_local = lt_local.
      CLEAR et_source[].
      CLEAR et_test[].
      APPEND LINES OF  zcl_bc_scm_class_adapter=>convert_to_char72( lt_main ) TO et_source.
      APPEND LINES OF zcl_bc_scm_class_adapter=>convert_to_char72( lt_test ) TO et_test.

      cls->get_methods( CHANGING ct_methods = et_methods[] ).

      ev_super = cls->get_super( ).
    CATCH cx_class_not_existent.
  ENDTRY.
ENDFUNCTION.
