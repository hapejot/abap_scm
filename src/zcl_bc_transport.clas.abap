CLASS zcl_bc_transport DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: mtt_transports TYPE STANDARD TABLE OF e070,
           mtt_trans_refs TYPE STANDARD TABLE OF REF TO zcl_bc_transport WITH EMPTY KEY,
           mtt_keys       TYPE STANDARD TABLE OF e071k.

    CLASS-METHODS:
      read_keys                         IMPORTING
                                          iv_trkorr TYPE trkorr
                                        CHANGING
                                          lt_keys   TYPE mtt_keys,
      read_transport                    IMPORTING
                                          iv_trkorr TYPE trkorr
                                        CHANGING
                                          lt_korr   TYPE mtt_transports,
      record                            IMPORTING
                                          iv_request TYPE trkorr OPTIONAL,
      test                              IMPORTING
                                          iv_request TYPE trkorr DEFAULT 'IDXK901078'
                                        EXPORTING
                                          et_obj     TYPE trwbo_t_e071
                                          rv_req_cnt TYPE i,
      find_by_object                    IMPORTING
                                          iv_obj               TYPE trobj_name
                                        RETURNING
                                          VALUE(rt_transports) TYPE mtt_trans_refs,
      find_request                      IMPORTING
                                          iv_request      TYPE trkorr
                                        RETURNING
                                          VALUE(r_result) TYPE REF TO zcl_bc_transport
                                        RAISING
                                          zcx_bc_not_found.
    METHODS:
      init                              IMPORTING
                                          iv_request TYPE trkorr,
      read                              RAISING zcx_bc_not_found,
      save,
      lock,
      copy_from,
      release,
      unlock.
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: mv_request  TYPE trkorr,
          mt_tasks    TYPE trwbo_request_headers,
          mt_requests TYPE trwbo_requests,
          mx_cofile   TYPE ctslg_cofile,
          mv_type     TYPE trfunction,
          mv_text     TYPE as4text.
    METHODS get_objects
      CHANGING
        ct_object TYPE STANDARD TABLE.
    METHODS read_status.
ENDCLASS.



CLASS ZCL_BC_TRANSPORT IMPLEMENTATION.


  METHOD copy_from.
    DATA: iv_request   TYPE e070-trkorr,
          iv_with_docs TYPE trpari-w_no_docu.
    CALL FUNCTION 'TR_COPY_COMM'
      EXPORTING
*       wi_dialog                = 'X'              " Flag, whether information messages sent
        wi_trkorr_from           = iv_request       " Initial correction number
        wi_trkorr_to             = mv_request       " Target correction number
        wi_without_documentation = iv_with_docs     " Flag, documentation is not to be copied
      EXCEPTIONS
        db_access_error          = 1
        trkorr_from_not_exist    = 2
        trkorr_to_is_repair      = 3
        trkorr_to_locked         = 4
        trkorr_to_not_exist      = 5
        trkorr_to_released       = 6
        user_not_owner           = 7
        no_authorization         = 8
        wrong_client             = 9
        wrong_category           = 10
        object_not_patchable     = 11
        OTHERS                   = 12.
    IF sy-subrc <> 0.
* MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.


  METHOD find_by_object.
    DATA: lv_obj    TYPE e071,
          " TRFUNCTION
          " K   Workbench Request
          " W   Customizing Request
          " C   Relocation of Objects Without Package Change
          " O   Relocation of Objects with Package Change
          " E   Relocation of complete package
          " T   Transport of Copies
          " S   Development/Correction
          " R   Repair
          " X   Unclassified Task
          " Q   Customizing Task
          " G   Piece List for CTS Project
          " M   Client Transport Request
          " P   Piece List for Upgrade
          " D   Piece List for Support Package
          " F Piece List
          " L Deletion transport
          lv_types  TYPE char0016 VALUE 'WKTSXQ',
          " TRSTATUS
          " D Modifiable
          " L Modifiable, Protected
          " O Release Started
          " R Released
          " N Released (with Import Protection for Repaired Objects)
          lv_states TYPE char0016 VALUE 'DLORN',
          lt_req    TYPE cts_trkorrs.

    lv_obj = VALUE #(
     pgmid = 'R3TR'
     object = 'VDAT'  " View Maintenance: Data
     obj_name = iv_obj
     ).

    CALL FUNCTION 'TR_SEARCH_OBJECT_IN_REQUESTS'
      EXPORTING
        is_object         = lv_obj    " Change & Transport System: Object Entries of Requests/Tasks
*       is_key            =     " Change & Transport System: Key Entries of Requests/Tasks
*       iv_trkorr_pattern = '*'    " Request/Task
        iv_request_types  = lv_types
        iv_request_states = lv_states
*       iv_request_owner  =     " Owner of a Request or Task
*       iv_fromdate       =     " Date of Last Change
*       iv_todate         =     " Date of Last Change
*       iv_allclients     = 'X'    " Boolean
*       iv_locked_objects_only = SPACE    " Boolean
      IMPORTING
        et_requests       = lt_req.    " Table of Request Numbers

    LOOP AT lt_req INTO DATA(ls_req).
      TRY.
          APPEND find_request( ls_req-trkorr ) TO rt_transports.
        CATCH zcx_bc_not_found.
          "handle exception
      ENDTRY.
    ENDLOOP.

  ENDMETHOD.


  METHOD find_request.

    DATA(req) = NEW zcl_bc_transport( ).
    req->init( iv_request ).
    req->read( ).
    r_result = req.
  ENDMETHOD.


  METHOD get_objects.
    DATA: lr_req TYPE REF TO trwbo_request,
          ls_obj TYPE trwbo_s_e071.
    FIELD-SYMBOLS: <ls_line> TYPE any.
    LOOP AT mt_requests REFERENCE INTO lr_req.
      LOOP AT lr_req->objects INTO ls_obj.
        APPEND INITIAL LINE TO ct_object ASSIGNING <ls_line>.
        MOVE-CORRESPONDING ls_obj TO <ls_line>.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD init.
    mv_request = iv_request.
  ENDMETHOD.


  METHOD lock.
    CALL FUNCTION 'ENQUEUE_E_TRKORR'
      EXPORTING
*       mode_e070      = 'E'    " Lock mode for table E070
        trkorr         = mv_request    " 01th enqueue argument
*       x_trkorr       = SPACE    " Fill argument 01 with initial value?
*       _scope         = '2'
*       _wait          = SPACE
*       _collect       = ' '    " Initially only collect lock
      EXCEPTIONS
        foreign_lock   = 1
        system_failure = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
* MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.


  METHOD read.
    CALL FUNCTION 'TR_READ_REQUEST_WITH_TASKS'
      EXPORTING
        iv_trkorr          = mv_request    " Request or task
      IMPORTING
        et_request_headers = mt_tasks    " Request including tasks (header data only)
        et_requests        = mt_requests    " Request including tasks
      EXCEPTIONS
        invalid_input      = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_bc_not_found
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    read_status( ).

  ENDMETHOD.


  METHOD read_keys.
    SELECT * FROM e071k WHERE trkorr = @iv_trkorr
            INTO TABLE @lt_keys.
  ENDMETHOD.


  METHOD read_status.
    DATA: lv_settings TYPE ctslg_settings.
    CALL FUNCTION 'TR_READ_GLOBAL_INFO_OF_REQUEST'
      EXPORTING
        iv_trkorr                 = mv_request    " Request number
*       iv_dir_type               = 'T'
        iv_suppress_deleted_steps = 'X'
      IMPORTING
        es_cofile                 = mx_cofile
*       ev_user                   =     " Owner of a Request or Task
*       ev_project                =     " Request/Task
      .

  ENDMETHOD.


  METHOD read_transport.
    SELECT * FROM e070
            WHERE trkorr = @iv_trkorr
            INTO TABLE @lt_korr.
  ENDMETHOD.


  METHOD record.

    " CALL FUNCTION 'TR_RECORD_OBJ_CHANGE_TO_REQ'

    CALL FUNCTION 'TR_RECORD_OBJ_CHANGE_TO_REQ'
      EXPORTING
        iv_request = iv_request
*       it_objects =     " Objects for Processing (Correction Interface)
*       it_keys    =     " Table Keys for Processing (Correction Interface)
*       it_e071k_str    =
*       it_obj_entries  =
*  IMPORTING
*       ev_no_recording =
*       et_tadir   =     " Object Directory
      EXCEPTIONS
        cancel     = 1
        OTHERS     = 2.
    IF sy-subrc <> 0.
* MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.


  METHOD release.
    CALL FUNCTION 'TRINT_RELEASE_REQUEST'
      EXPORTING
        iv_trkorr = mv_request    " Request/Task
*       iv_dialog = 'X'    " Dialog
*       iv_as_background_job        = ' '
*       iv_success_message          = 'X'
*       iv_without_objects_check    = ' '
*       iv_called_by_adt            = ' '
*       iv_called_by_perforce       = ' '
*       iv_without_docu             = ' '
*       iv_without_locking          = ' '
*       iv_display_export_log       = 'X'    " Boolean
*       iv_ignore_warnings          = ' '
*       iv_simulation               = ' '
*  IMPORTING
*       es_request                  =     " Request
*       et_deleted_tasks            =
*       et_messages                 =     " Object-Related Error Messages when Recording Changes
*  EXCEPTIONS
*       cts_initialization_failure  = 1
*       enqueue_failed              = 2
*       no_authorization            = 3
*       invalid_request             = 4
*       request_already_released    = 5
*       repeat_too_early            = 6
*       object_lock_error           = 7
*       object_check_error          = 8
*       docu_missing                = 9
*       db_access_error             = 10
*       action_aborted_by_user      = 11
*       export_failed               = 12
*       execute_objects_check       = 13
*       release_in_bg_mode          = 14
*       release_in_bg_mode_w_objchk = 15
*       error_in_export_methods     = 16
*       object_lang_error           = 17
*       others    = 18
      .
    IF sy-subrc <> 0.
* MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.


  METHOD save.
    DATA: ls_req   TYPE trwbo_request_header,
          lt_tasks TYPE trwbo_request_headers.

    CALL FUNCTION 'TR_INSERT_REQUEST_WITH_TASKS'
      EXPORTING
        iv_type           = mv_type
        iv_text           = mv_text
*       iv_owner          = SY-UNAME
*       iv_target         =
*       it_attributes     =
*       it_users          =
*       iv_tardevcl       =
*       iv_devclass       =
*       iv_tarlayer       =
*       iv_with_badi_check =
      IMPORTING
        es_request_header = ls_req
        et_task_headers   = lt_tasks
      EXCEPTIONS
        insert_failed     = 1
        enqueue_failed    = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
* MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.


  METHOD test.

    TRY.
        DATA(req) = find_request( iv_request ).
        rv_req_cnt = lines( req->mt_requests ).
        req->get_objects( CHANGING ct_object = et_obj ).
      CATCH zcx_bc_not_found.
        rv_req_cnt = -1.
    ENDTRY.
  ENDMETHOD.


  METHOD unlock.
    CALL FUNCTION 'DEQUEUE_E_TRKORR'
*    EXPORTING
*      mode_e070 = 'E'    " Lock mode for table E070
*      trkorr    =     " 01th enqueue argument
*      x_trkorr  = SPACE    " Fill argument 01 with initial value?
*      _scope    = '3'
*      _synchron = SPACE    " Synchonous unlock
*      _collect  = ' '    " Initially only collect lock
      .
  ENDMETHOD.
ENDCLASS.
