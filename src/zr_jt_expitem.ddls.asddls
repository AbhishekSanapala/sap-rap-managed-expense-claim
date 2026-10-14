@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Child Interface View - Expense Item'
define view entity ZR_JT_ExpItem
  as select from zjt_exp_item
  association to parent ZR_JT_ExpClaim as _Claim on $projection.ParentUuid = _Claim.ClaimUuid
{
  key item_uuid       as ItemUuid,
      parent_uuid     as ParentUuid,
      item_no         as ItemNo,
      expense_type    as ExpenseType,
      expense_date    as ExpenseDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      amount          as Amount,
      currency_code   as CurrencyCode,
      remark          as Remark,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at as LastChangedAt,

      _Claim
}
