class ZCL_SCM_TR_TASK definition
  public
  final
  create public .

public section.

  methods SELECT_TASKS .
  methods RELEASE .
protected section.
private section.
ENDCLASS.



CLASS ZCL_SCM_TR_TASK IMPLEMENTATION.


  METHOD release.

    CALL FUNCTION 'TR_RELEASE_REQUEST'
      EXPORTING
        iv_trkorr                  = VALUE trkorr( )   " Request/Task
*       iv_dialog                  = 'X'
*       iv_as_background_job       = ' '
*       iv_success_message         = 'X'
*       iv_display_export_log      = 'X'    " Boolean
*       iv_simulation              = ' '
*       iv_without_locking         = ' '
*  IMPORTING
*       es_request                 =
*       et_deleted_tasks           =
      EXCEPTIONS
        cts_initialization_failure = 1
        enqueue_failed             = 2
        no_authorization           = 3
        invalid_request            = 4
        request_already_released   = 5
        repeat_too_early           = 6
        error_in_export_methods    = 7
        object_check_error         = 8
        docu_missing               = 9
        db_access_error            = 10
        action_aborted_by_user     = 11
        export_failed              = 12
        OTHERS                     = 13.
    IF sy-subrc <> 0.
* MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.


  METHOD select_tasks.

    SELECT * FROM  e070 INTO TABLE @DATA(tasks)
      WHERE as4user = 'DEVELOPER'
      AND trfunction <> 'K'
      AND trstatus <> 'R'.


  ENDMETHOD.
ENDCLASS.
