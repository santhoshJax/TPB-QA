/**
 * TPB_AddUsersIntoChildAccountTeams
 * @author RZ
 * @date 2023-09-21
 * @description Create AddUsersIntoChildAccountTeams by flow
 *
 */
public with sharing class TPB_AddUsersIntoChildAccountTeams {

    /**
     * @description AddUsersIntoChildAccountTeams description
     * @param  inputs inputs description
     *
     */
    @InvocableMethod(label='TPB_AddUsersIntoChildAccountTeams' category='AccountTeamMember')
    public static void addUsersIntoChildAccountTeams(List<InputParameters> inputs) {
        // 2048: Skip if it is run in batch context
        if (System.isBatch()) {
            return;
        }

        // trigged hq account
        AccountTeamMember hqMember = new AccountTeamMember();
        // child retailer account id
        List<String> lstChildAccIds = new List<String>();
        // has current user member's account id
        List<String> lstHasChildAccIds = new List<String>();
        if (inputs.size() > 0) {
            hqMember = inputs[0].accountTeamMember;
            List<Account> lstChildAcc = [SELECT Id FROM Account WHERE ParentId = :hqMember.AccountId];
            for (Account child : lstChildAcc) {
                lstChildAccIds.add(child.Id);
            }
        }else{
            return;
        }
        // check child account size
        if (lstChildAccIds.size() > 0) {
            List<AccountTeamMember> lstChildMember = [SELECT Id, AccountId FROM AccountTeamMember WHERE AccountId IN :lstChildAccIds and UserId = :hqMember.UserId];
            for (AccountTeamMember childMember : lstChildMember) {
                lstHasChildAccIds.add(childMember.AccountId);
            }
            System.enqueuejob(new TPB_AddChildAccountTeamsQueueable(lstChildAccIds, lstHasChildAccIds, hqMember.UserId));
        }
    }

    /**
     * @description InputParameters
     */
    public class InputParameters {
        /**
         * @description accountTeamMember
         */
        @InvocableVariable(required=true)
        public AccountTeamMember accountTeamMember;
    }
}