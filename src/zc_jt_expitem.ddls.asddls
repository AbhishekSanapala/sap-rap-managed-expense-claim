@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View - Expense Item'
@Metadata.allowExtensions: true
define view entity ZC_JT_ExpItem
  as projection on ZR_JT_ExpItem
{
  key ItemUuid,
      ParentUuid,
      ItemNo,
      @Consumption.valueHelpDefinition: [{
        entity: { name: 'ZI_JT_ExpenseTypeVH', element: 'ExpenseType' }
      }]
      ExpenseType,
      ExpenseDate,
      Amount,
      CurrencyCode,
      Remark,
      LastChangedAt,

      _Claim : redirected to parent ZC_JT_ExpClaim
}
