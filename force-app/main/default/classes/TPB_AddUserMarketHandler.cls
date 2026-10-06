/**
* @author Jie Yu
* @date 8/1/2023
* @description Assign the perssion of market user
*/
public without sharing class TPB_AddUserMarketHandler extends SDF_TGF_TriggerHandler{
    /**
     * @description the flag to disable Trigger use
     */
    public static boolean disableTriggerUsed = false;
    /**
     * @description beforeInsert description
     */
    protected override void beforeInsert() {
        if(disableTriggerUsed){
            return;
        }
        //Select processed users
        List<User> lstUserProcessed = selectProcessedUser((List<User>)Trigger.new, (Map<Id, User>)Trigger.oldMap, true, false);
        //Process the logic
        processDataBefore(lstUserProcessed);
    }
    /**
     * @description beforeUpdate description
     */
    protected override void beforeUpdate() {
        if(disableTriggerUsed){
            return;
        }
        //Select processed users
        List<User> lstUserProcessed = selectProcessedUser((List<User>)Trigger.new, (Map<Id, User>)Trigger.oldMap, false, false);
        //Process the logic
        processDataBefore(lstUserProcessed);
    }

    /**
     * @description afterUpdate description
     *
     */
    protected override void afterInsert() {
        if(disableTriggerUsed){
            return;
        }
        //Select processed users
        List<User> lstUserProcessed = selectProcessedUser((List<User>)Trigger.new, (Map<Id, User>)Trigger.oldMap, true, true);
        //Process the logic
        processDataAfter(lstUserProcessed);
    }
    /**
     * @description afterUpdate description
     */
    protected override void afterUpdate() {
        if(disableTriggerUsed){
            return;
        }
        //Select processed users
        List<User> lstUserProcessed = selectProcessedUser((List<User>)Trigger.new, (Map<Id, User>)Trigger.oldMap, false, true);
        //Process the logic
        processDataAfter(lstUserProcessed);
    }
    /**
     * @description select processed user
     * @param  lstUser list user description
     */
    private List<User> selectProcessedUser(List<User> lstUser, Map<Id, User> mapUser, Boolean isInsert, Boolean isAfter){
        List<User> lstUserProcessed =  new List<User>();
        //System admin should enable market user
        List<Profile> lstProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        //For role name in label, the user should enable market user
        String strRoles = System.Label.TPB_Campaign_Member_Role;
        List<UserRole> lstRole = null;
        if(!String.isBlank(strRoles)){
            String[] arrRoles = strRoles.split(',');
            lstRole = [ SELECT Id FROM UserRole WHERE Name IN :arrRoles ];
        }
        for(User objUser : lstUser){
            if(objUser.IsActive == false){
                //Not active user
                continue;
            }
            if(lstProfile.size()>0 && objUser.ProfileId == lstProfile[0].Id){
                //Admin
                if(isAfter && !isInsert && objUser.ProfileId == mapUser.get(objUser.Id).ProfileId){
                    //no profile change
                    //Admin no need add permission set so no need before trigger
                    continue;
                }
                lstUserProcessed.add(objUser);
            } else {
                //Role in the list
                for(UserRole objRole : lstRole){
                    if(objUser.UserRoleId == objRole.Id){
                        if(!isInsert && objUser.UserRoleId == mapUser.get(objUser.Id).UserRoleId){
                            //No role change
                            //Not admin, it need enable market user and permission and so before and after triger both needed
                            continue;
                        }
                        lstUserProcessed.add(objUser);
                    }
                }
            }
        }
        return lstUserProcessed;
    }

    /**
     * @description processDataBefore description
     * @param  lstUser list user description
     */
    private void processDataBefore(List<User> lstUser) {
        //Before trigger, Enable Market User
        for(User objUser : lstUser){
            objUser.UserPermissionsMarketingUser = true;
        }
    }

    /**
     * @description processDataAfter description
     * @param  lstUser list user description
     */
    private void processDataAfter(List<User> lstUser) {
        //After trigger, Add permission set
        List<PermissionSet> lstPermission = [ SELECT ID FROM PermissionSet WHERE Name = 'TPB_Add_Campaign_Member' ];
        Set<Id> setPermission = new Set<Id>();
        if(lstPermission.size()>0){
            setPermission.add(lstPermission[0].Id);
        } else {
            return;
        }
        Set<Id> setUser = new Set<Id>();
        for(User objUser : lstUser){
            setUser.add(objUser.Id);
        }
        //Select permission set
        List<PermissionSetAssignment> lstAssigned = [ SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN :setPermission AND AssigneeId IN :setUser ];
        Set<Id> setUserAssigned = new Set<Id>();
        for(PermissionSetAssignment objAssigned : lstAssigned){
            setUserAssigned.add(objAssigned.AssigneeId);
        }
        //Create assign list
        List<PermissionSetAssignment> lstAssignProcessed = new List<PermissionSetAssignment>();
        for(User objUser : lstUser){
            if(!setUserAssigned.contains(objUser.Id)){
                PermissionSetAssignment objPsa = new PermissionSetAssignment();
                objPsa.PermissionSetId = lstPermission[0].Id;
                objPsa.AssigneeId = objUser.Id;
                lstAssignProcessed.add(objPsa);
            }
        }
        //Insert assign list
        insert lstAssignProcessed;
    }
}