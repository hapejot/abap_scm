FUNCTION Z_BC_TMS_CLAS_FIND.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_PACKAGE) TYPE  TADIR-DEVCLASS
*"  TABLES
*"      ET_CLASS STRUCTURE  ZBC_CLASSINFO_S
*"----------------------------------------------------------------------

  SELECT
        obj_name AS name,
        object AS kind
    FROM tadir
    INTO CORRESPONDING FIELDS OF TABLE @et_class
    UP TO 1000 ROWS
    WHERE pgmid = 'R3TR'
    AND   ( object   = 'CLAS' OR object = 'INTF' )
*    AND   obj_name IN r_clas
    AND   devclass = @iv_package.

ENDFUNCTION.
