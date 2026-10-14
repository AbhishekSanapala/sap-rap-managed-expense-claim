CLASS lhc_Claim DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Claim RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Claim RESULT result.

    METHODS approve FOR MODIFY
      IMPORTING keys FOR ACTION Claim~approve RESULT result.

    METHODS reject FOR MODIFY
      IMPORTING keys FOR ACTION Claim~reject RESULT result.

    METHODS copyClaim FOR MODIFY
      IMPORTING keys FOR ACTION Claim~copyClaim.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Claim~setInitialStatus.

    METHODS calculateClaimId FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Claim~calculateClaimId.

    METHODS validateDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Claim~validateDate.

    METHODS validateAmount FOR VALIDATE ON SAVE
      IMPORTING keys FOR Claim~validateAmount.

    METHODS validateItems FOR VALIDATE ON SAVE
      IMPORTING keys FOR Claim~validateItems.

    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Claim~validateDescription.

ENDCLASS.

CLASS lhc_Claim IMPLEMENTATION.

  METHOD get_global_authorizations.
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        FIELDS ( OverallStatus ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    result = VALUE #( FOR ls_claim IN lt_claims (
      %tky                  = ls_claim-%tky
      %action-approve       = COND #( WHEN ls_claim-OverallStatus = 'O' OR ls_claim-OverallStatus IS INITIAL THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
      %action-reject        = COND #( WHEN ls_claim-OverallStatus = 'O' OR ls_claim-OverallStatus IS INITIAL THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
    ) ).
  ENDMETHOD.

  METHOD approve.
    MODIFY ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky OverallStatus = 'A' ) ).

    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    result = VALUE #( FOR ls_claim IN lt_claims ( %tky = ls_claim-%tky %param = ls_claim ) ).
  ENDMETHOD.

  METHOD reject.
    MODIFY ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky OverallStatus = 'R' ) ).

    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    result = VALUE #( FOR ls_claim IN lt_claims ( %tky = ls_claim-%tky %param = ls_claim ) ).
  ENDMETHOD.

  METHOD copyClaim.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    DATA: lt_create_claim TYPE TABLE FOR CREATE zr_jt_expclaim.

    LOOP AT lt_claims INTO DATA(ls_claim).
      DATA(lv_cid) = |CID_{ sy-tabix }|.
      APPEND VALUE #(
        %cid           = lv_cid
        %is_draft      = if_abap_behv=>mk-on
        Employee       = ls_claim-Employee
        Description    = |Copy of: { ls_claim-Description }|
        CurrencyCode   = ls_claim-CurrencyCode
        OverallStatus  = 'O'
      ) TO lt_create_claim.
    ENDLOOP.

    MODIFY ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        CREATE FIELDS ( Employee Description CurrencyCode OverallStatus )
        WITH lt_create_claim
      MAPPED DATA(lt_mapped).

    mapped-claim = lt_mapped-claim.
  ENDMETHOD.

  METHOD setInitialStatus.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        FIELDS ( OverallStatus ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    DELETE lt_claims WHERE OverallStatus IS NOT INITIAL.
    IF lt_claims IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        UPDATE FIELDS ( OverallStatus )
        WITH VALUE #( FOR ls_claim IN lt_claims ( %tky = ls_claim-%tky OverallStatus = 'O' ) ).
  ENDMETHOD.

  METHOD calculateClaimId.
    " Filter to process ONLY draft instances that don't have a ClaimId set yet
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        FIELDS ( ClaimId ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    " Do not calculate or re-modify if ClaimId is already populated
    DELETE lt_claims WHERE ClaimId IS NOT INITIAL.
    IF lt_claims IS INITIAL.
      RETURN.
    ENDIF.

    " Select max IDs from both active and draft tables
    SELECT MAX( claim_id ) FROM zjt_exp_claim INTO @DATA(lv_max_pers).
    SELECT MAX( claimid ) FROM zjt_exp_claim_d INTO @DATA(lv_max_draft).

    DATA(lv_max) = COND string( WHEN lv_max_pers > lv_max_draft THEN lv_max_pers ELSE lv_max_draft ).

    DATA lv_num TYPE i VALUE 1000.
    IF lv_max IS NOT INITIAL AND strlen( lv_max ) >= 7.
      DATA(lv_str_num) = substring( val = lv_max off = 3 ).
      IF lv_str_num CO '0123456789'.
        lv_num = CONV i( lv_str_num ).
      ENDIF.
    ENDIF.

    LOOP AT lt_claims ASSIGNING FIELD-SYMBOL(<fs_claim>).
      lv_num += 1.
      <fs_claim>-ClaimId = |CLM{ lv_num }|.
    ENDLOOP.

    " Perform update inside local mode using draft key (%tky)
    MODIFY ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        UPDATE FIELDS ( ClaimId )
        WITH VALUE #( FOR ls_c IN lt_claims ( %tky = ls_c-%tky ClaimId = ls_c-ClaimId ) ).
  ENDMETHOD.

  METHOD validateDate.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim BY \_Item
        FIELDS ( ExpenseDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-ExpenseDate > lv_today.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-item.
        APPEND VALUE #(
          %tky        = ls_item-%tky
          %state_area = 'VALIDATE_DATE'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Expense date cannot be in the future'
                        )
          %element-ExpenseDate = if_abap_behv=>mk-on
        ) TO reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateAmount.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim BY \_Item
        FIELDS ( Amount ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    LOOP AT lt_items INTO DATA(ls_item).
      IF ls_item-Amount <= 0.
        APPEND VALUE #( %tky = ls_item-%tky ) TO failed-item.
        APPEND VALUE #(
          %tky        = ls_item-%tky
          %state_area = 'VALIDATE_AMOUNT'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Amount must be greater than zero'
                        )
          %element-Amount = if_abap_behv=>mk-on
        ) TO reported-item.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateItems.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim BY \_Item
        FIELDS ( ItemUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_items).

    " Read parent claims explicitly to preserve transactional draft keys (%tky)
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        FIELDS ( ClaimUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    LOOP AT lt_claims INTO DATA(ls_claim).
      IF NOT line_exists( lt_items[ ParentUuid = ls_claim-ClaimUuid ] ).
        APPEND VALUE #( %tky = ls_claim-%tky ) TO failed-claim.
        APPEND VALUE #(
          %tky        = ls_claim-%tky
          %state_area = 'VALIDATE_ITEMS'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'At least one line item is required'
                        )
        ) TO reported-claim.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDescription.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim
        FIELDS ( Description ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    LOOP AT lt_claims INTO DATA(ls_claim).
      IF ls_claim-Description IS INITIAL.
        APPEND VALUE #( %tky = ls_claim-%tky ) TO failed-claim.
        APPEND VALUE #(
          %tky        = ls_claim-%tky
          %state_area = 'VALIDATE_DESC'
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Description is mandatory'
                        )
          %element-Description = if_abap_behv=>mk-on
        ) TO reported-claim.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Item DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS recalculateTotalAmount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Item~recalculateTotalAmount.
ENDCLASS.

CLASS lhc_Item IMPLEMENTATION.

  METHOD recalculateTotalAmount.
    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Item BY \_Claim
        FIELDS ( ClaimUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_claims).

    IF lt_claims IS INITIAL.
      RETURN.
    ENDIF.

    READ ENTITIES OF zr_jt_expclaim IN LOCAL MODE
      ENTITY Claim BY \_Item
        FIELDS ( Amount ) WITH CORRESPONDING #( lt_claims )
      RESULT DATA(lt_items).

    LOOP AT lt_claims INTO DATA(ls_claim).
      DATA(lv_total) = VALUE zjt_exp_claim-total_amount( ).
      LOOP AT lt_items INTO DATA(ls_item) WHERE ParentUuid = ls_claim-ClaimUuid.
        lv_total += ls_item-Amount.
      ENDLOOP.

      MODIFY ENTITIES OF zr_jt_expclaim IN LOCAL MODE
        ENTITY Claim
          UPDATE FIELDS ( TotalAmount )
          WITH VALUE #( ( %tky = ls_claim-%tky TotalAmount = lv_total ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
