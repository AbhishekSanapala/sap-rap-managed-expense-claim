@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root Interface View - Expense Claim'
define root view entity ZR_JT_ExpClaim
  as select from zjt_exp_claim
  composition [0..*] of ZR_JT_ExpItem as _Item
{
  key claim_uuid            as ClaimUuid,
      claim_id              as ClaimId,
      employee              as Employee,
      description           as Description,
      total_amount          as TotalAmount,
      currency_code         as CurrencyCode,
      overall_status        as OverallStatus,
      created_by            as CreatedBy,
      created_at            as CreatedAt,
      last_changed_by       as LastChangedBy,
      last_changed_at       as LastChangedAt,
      local_last_changed_at as LocalLastChangedAt,

      _Item
}
