CLASS zcl_jt_exp_data_gen DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_jt_exp_data_gen IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA: lt_claims TYPE TABLE OF zjt_exp_claim,
          lt_items  TYPE TABLE OF zjt_exp_item.

    DELETE FROM zjt_exp_claim.
    DELETE FROM zjt_exp_item.
    DELETE FROM zjt_exp_claim_d.
    DELETE FROM zjt_exp_item_d.

    DATA(lv_ts) = utclong_current( ).

    TRY.
        DO 10 TIMES.
          DATA(i) = sy-index.
          DATA(lv_claim_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
          DATA(lv_claim_id)   = CONV string( |CLM{ i WIDTH = 4 PAD = '0' }| ).

          APPEND VALUE #(
            claim_uuid            = lv_claim_uuid
            claim_id              = lv_claim_id
            employee              = CONV string( |EMP{ 100 + i }| )
            description           = |Expense claim for business trip { i }|
            total_amount          = i * 150
            currency_code         = 'EUR'
            overall_status        = COND #( WHEN i MOD 2 = 0 THEN 'O' ELSE 'A' )
            created_by            = sy-uname
            created_at            = lv_ts
            last_changed_by       = sy-uname
            last_changed_at       = lv_ts
            local_last_changed_at = lv_ts
          ) TO lt_claims.

          DO 2 TIMES.
            DATA(j) = sy-index.
            APPEND VALUE #(
              item_uuid       = cl_system_uuid=>create_uuid_x16_static( )
              parent_uuid     = lv_claim_uuid
              item_no         = j * 10
              expense_type    = COND #( WHEN j = 1 THEN 'TRAVEL' ELSE 'MEAL' )
              expense_date    = cl_abap_context_info=>get_system_date( ) - j
              amount          = i * 75
              currency_code   = 'EUR'
              remark          = |Expense line item { j } for claim { lv_claim_id }|
              last_changed_at = lv_ts
            ) TO lt_items.
          ENDDO.
        ENDDO.

        INSERT zjt_exp_claim FROM TABLE @lt_claims.
        INSERT zjt_exp_item  FROM TABLE @lt_items.

        out->write( |Successfully generated { lines( lt_claims ) } claims and { lines( lt_items ) } items.| ).

      CATCH cx_uuid_error INTO DATA(lx_uuid).
        out->write( |Error generating UUID: { lx_uuid->get_text( ) }| ).
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
