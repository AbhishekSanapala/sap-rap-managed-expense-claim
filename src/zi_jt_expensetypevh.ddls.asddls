@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help - Expense Type'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_JT_ExpenseTypeVH
  as select from zjt_exp_claim
{
  @UI.textArrangement: #TEXT_ONLY
  @ObjectModel.text.element: ['ExpenseTypeText']
  key 'TRAVEL' as ExpenseType,
      'Travel Expenses' as ExpenseTypeText
}
where claim_uuid is not null

union select from zjt_exp_claim
{
  key 'MEAL' as ExpenseType,
      'Meal & Entertainment' as ExpenseTypeText
}
where claim_uuid is not null

union select from zjt_exp_claim
{
  key 'HOTEL' as ExpenseType,
      'Hotel Accommodation' as ExpenseTypeText
}
where claim_uuid is not null

union select from zjt_exp_claim
{
  key 'OTHER' as ExpenseType,
      'Other Expenses' as ExpenseTypeText
}
where claim_uuid is not null
