/**
 * TPB_RemoveChildAccountTeamsQueueable
 * @author RZ
 * @date 2023-09-21
 * @description RemoveChildAccountTeams by flow
 *
 */
public class TPB_RemoveChildAccountTeamsQueueable implements Queueable {
    // child retailer account team
    List<AccountTeamMember> lstChildMember = new List<AccountTeamMember>();

    /**
     * @description TPB_RemoveChildAccountTeamsQueueable description
     * @param  lstChildMember lstChildMember description
     * 
     */
    public TPB_RemoveChildAccountTeamsQueueable(List<AccountTeamMember> lstChildMember) {
        // child retailer account team
        this.lstChildMember = lstChildMember;
    }

    /**
     * @description execute description
     * @param  context context description
     */
    public void execute(QueueableContext context){
        // new delete team member
        List<AccountTeamMember> lstDeleteMembers = new List<AccountTeamMember>();
        List<AccountTeamMember> lstExtraDeleteMembers = new List<AccountTeamMember>();
        // loop the child account team
        for (AccountTeamMember childAccTeam : lstChildMember) {
            if (lstdeleteMembers.size() < 10000) {
                lstdeleteMembers.add(childAccTeam);
            }else{
                lstExtraDeleteMembers.add(childAccTeam);
            }
        }

        if (lstdeleteMembers.size() > 0) {
            delete lstdeleteMembers;
        }
        if(lstExtraDeleteMembers.size() > 0){
            System.enqueuejob(new TPB_RemoveChildAccountTeamsQueueable(lstExtraDeleteMembers));
        }
    }
}