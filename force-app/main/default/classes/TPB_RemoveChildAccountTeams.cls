/**
 * TPB_AddUsersIntoChildAccountTeams
 * @author RZ
 * @date 2023-09-21
 * @description Create AddUsersIntoChildAccountTeams by flow
 *
 */
public with sharing class TPB_RemoveChildAccountTeams {
    /**
     * @description removeUsersIntoChildAccountTeams description
     * @param  inputs inputs description
     *
     */
    @InvocableMethod(label='TPB_RemoveChildAccountTeams' category='AccountTeamMember')
    public static void removeUsersIntoChildAccountTeams(List<InputParameters> inputs) {
        // 2048: Skip if it is run in batch context
        if (System.isBatch()) {
            return;
        }

        // trigged hq account
        AccountTeamMember hqMember = new AccountTeamMember();
        // child retailer account id
        List<String> lstChildAccIds = new List<String>();
        // has current user member's account id
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
            System.enqueuejob(new TPB_RemoveChildAccountTeamsQueueable(lstChildMember));
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