@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View - Expense Claim Header'
@Metadata.allowExtensions: true
define root view entity ZC_JT_ExpClaim
  provider contract transactional_query
  as projection on ZR_JT_ExpClaim
{
  key ClaimUuid,
      ClaimId,
      Employee,
      Description,
      TotalAmount,
      CurrencyCode,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_JT_ClaimStatusVH', element: 'Status' } }]
      OverallStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      _Item : redirected to composition child ZC_JT_ExpItem
}
