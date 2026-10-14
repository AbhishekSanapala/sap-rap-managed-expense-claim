@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help - Expense Claim Status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.resultSet.sizeCategory: #XS
define view entity ZI_JT_ClaimStatusVH
  as select from zjt_exp_claim
{
  @UI.textArrangement: #TEXT_ONLY
  @ObjectModel.text.element: ['StatusText']
  key overall_status as Status,
      case overall_status
        when 'O' then 'Open'
        when 'A' then 'Approved'
        when 'R' then 'Rejected'
        else 'Unknown'
      end            as StatusText
}
group by
  overall_status
