/**
 * TPB_AddChildAccountTeamsQueueable
 * @author RZ
 * @date 2023-09-21
 * @description Create AddUsersIntoChildAccountTeams by flow
 *
 */
public class TPB_AddChildAccountTeamsQueueable implements Queueable {
    // child retailer account id
    public List<String> lstChildAccIds = new List<String>();
    // has current user member's account id
    public List<String> lstHasChildAccIds = new List<String>();
    // String strUserId
    public String strUserId;

    /**
     * @description TPB_AddChildAccountTeamsQueueable description
     * @param  lstChildAccIds    lstChildAccIds description
     * @param  lstHasChildAccIds lstHasChildAccIds description
     * @param  strUserId         strUserId description
     *
     */
    public TPB_AddChildAccountTeamsQueueable(List<String> lstChildAccIds, List<String> lstHasChildAccIds, String strUserId) {
        // child retailer account id
        this.lstChildAccIds = lstChildAccIds;
        // has current user member's account id
        this.lstHasChildAccIds = lstHasChildAccIds;
        // user id
        this.strUserId = strUserId;
    }

    /**
     * @description execute description
     * @param  context context description
     */
    public void execute(QueueableContext context){
        // new team member
        List<AccountTeamMember> lstNewMembers = new List<AccountTeamMember>();
        List<String> lstExtraChildAccIds = new List<String>();
        // loop the child account
        for (String childAccId : lstChildAccIds) {
            if (!lstHasChildAccIds.contains(childAccId)) {
                if (lstNewMembers.size() < 10000) {
                    AccountTeamMember childMember = new AccountTeamMember();
                    // member
                    childMember.UserId = strUserId;
                    // accountid
                    childMember.AccountId = childAccId;
                    //access level
                    childMember.AccountAccessLevel = 'Edit';
                    // team role
                    childMember.TeamMemberRole = 'Account Manager';
                    lstNewMembers.add(childMember);
                }else{
                    lstExtraChildAccIds.add(childAccId);
                }
            }
        }

        if (lstNewMembers.size() > 0) {
            insert lstNewMembers;
        }
        if(lstExtraChildAccIds.size() > 0){
            System.enqueuejob(new TPB_AddChildAccountTeamsQueueable(lstExtraChildAccIds, lstHasChildAccIds, strUserId));
        }
    }
}