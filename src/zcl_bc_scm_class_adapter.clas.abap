CLASS zcl_bc_scm_class_adapter DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
             mtt_progtab TYPE STANDARD TABLE OF progtab WITH DEFAULT KEY.
    CLASS-METHODS test
      IMPORTING
        iv_class        TYPE seoclsname DEFAULT 'ZCL_BC_BAPI_MAPPER'
      RETURNING
        VALUE(r_result) TYPE stringtab.
    CLASS-METHODS find_by_package.
    CLASS-METHODS find_by_name
      IMPORTING
        iv_classname      TYPE seoclsname
      RETURNING
        VALUE(ro_adapter) TYPE REF TO zcl_bc_scm_class_adapter.
    CLASS-METHODS convert_to_char72
      IMPORTING
        lt_src           TYPE stringtab
      RETURNING
        VALUE(rt_source) TYPE  mtt_progtab.
    METHODS read_source
      EXPORTING
        et_main  TYPE stringtab
        et_test  TYPE stringtab
        et_macro TYPE stringtab
        et_local TYPE stringtab.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS read_source_include
      IMPORTING
        progname      TYPE programm
      RETURNING
        VALUE(source) TYPE stringtab.
    DATA m_name TYPE seoclsname.
    METHODS init
      IMPORTING
        iv_classname TYPE seoclsname.
ENDCLASS.



CLASS ZCL_BC_SCM_CLASS_ADAPTER IMPLEMENTATION.


  METHOD convert_to_char72.
    DATA: lv_source TYPE string,
          lv_sep    TYPE string.
    lv_sep = |\n|.
    CONCATENATE LINES OF lt_src INTO lv_source SEPARATED BY lv_sep.
    CALL FUNCTION 'CONVERT_STRING_TO_TABLE'
      EXPORTING
        i_string         = lv_source    " String that is to be cut into the table
        i_tabline_length = 72    " Length of the table lines
      TABLES
        et_table         = rt_source.     " Character field lines (pass length in import parameter)

  ENDMETHOD.


  METHOD find_by_name.

    ro_adapter = NEW zcl_bc_scm_class_adapter( ).
    ro_adapter->init( iv_classname ).

  ENDMETHOD.


  METHOD find_by_package.
  ENDMETHOD.


  METHOD init.
    m_name = iv_classname.
  ENDMETHOD.


  METHOD read_source.
    DATA: source  TYPE stringtab,
          lv_part TYPE trobjtype VALUE 'CPUB' ##NO_TEXT.
    TRY.
        DATA(imp) = CAST if_oo_class_incl_naming( cl_oo_include_naming=>get_instance_by_name( name = m_name ) ).
*        APPEND LINES OF read_source_include(  progname = imp->class_pool        ) TO r_result.
*        APPEND LINES OF read_source_include(  progname = imp->public_section    ) TO r_result.
*        APPEND LINES OF read_source_include(  progname = imp->protected_section ) TO r_result.
*        APPEND LINES OF read_source_include(  progname = imp->private_section   ) TO r_result.
*        APPEND |endclass.| TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->main_source       ) TO et_main.
        APPEND LINES OF read_source_include(  progname = imp->locals_old        ) TO et_local.
        APPEND LINES OF read_source_include(  progname = imp->locals_def        ) TO et_local.
        APPEND LINES OF read_source_include(  progname = imp->locals_imp        ) TO et_local.
        APPEND LINES OF read_source_include(  progname = imp->macros            ) TO et_macro.
        APPEND LINES OF read_source_include(  progname = imp->tests             ) TO et_test.
*        APPEND LINES OF read_source_include(  progname = imp->type_dep          ) TO r_result.
      CATCH cx_class_not_existent.
        "handle exception
    ENDTRY.
  ENDMETHOD.


  METHOD read_source_include.

    READ REPORT progname INTO source.

  ENDMETHOD.


  METHOD test.
    DATA: source  TYPE stringtab,
          lv_part TYPE trobjtype VALUE 'CPUB' ##NO_TEXT.
    TRY.
        DATA(cls) = cl_oo_class=>get_instance( clsname = iv_class ).
        DATA(imp) = CAST if_oo_class_incl_naming( cl_oo_include_naming=>get_instance_by_name( name = iv_class ) ).
        APPEND LINES OF read_source_include(  progname = imp->class_pool        ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->public_section    ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->locals_old        ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->locals_def        ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->locals_imp        ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->macros            ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->tests             ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->main_source       ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->protected_section ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->private_section   ) TO r_result.
        APPEND LINES OF read_source_include(  progname = imp->type_dep          ) TO r_result.
      CATCH cx_class_not_existent.
        "handle exception
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
