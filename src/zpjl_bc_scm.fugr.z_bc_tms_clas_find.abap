FUNCTION Z_BC_TMS_CLAS_FIND.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_PACKAGE) TYPE  TADIR-DEVCLASS
*"  TABLES
*"      ET_CLASS STRUCTURE  ZBC_CLASSINFO_S
*"----------------------------------------------------------------------

  SELECT obj_name as name
    FROM tadir
    INTO CORRESPONDING FIELDS OF table @et_class
    UP TO 100 ROWS
    WHERE pgmid = 'R3TR'
    AND   object   = 'CLAS'
*    AND   obj_name IN r_clas
    AND   devclass = @iv_package.

ENDFUNCTION.
