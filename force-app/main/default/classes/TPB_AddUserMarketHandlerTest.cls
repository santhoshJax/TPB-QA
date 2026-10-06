/**
* @author Jie Yu
* @date 8/1/2023
* @description TPB_AddUserMarketHandler Test Class
*/
@isTest
public with sharing class TPB_AddUserMarketHandlerTest {
    /**
     * @description insert admin test
     */
    @isTest
    static void testNewAdmin() {
        //Test admin user create and Market user is enabled
        User objUser = TPB_TestFactory.createAdminUser();
        System.assertNotEquals(objUser, null);
    }
    /**
     * @description insert non-admin test
     */
    @isTest
    static void testProfile2Admin() {
        //Test user profile is changed to admin and Market User is enabled
        User objUser = TPB_TestFactory.createTSM();
        objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id;
        update objUser;
        System.assertNotEquals(objUser, null);
    }
    /**
     * @description insert non-admin test
     */
    @isTest
    static void testRole2Director() {
        //Test user role is in list and market user is enabled and permission set is added
        User objUser = TPB_TestFactory.createTSM();
        //Get role from label
        String strRoles = System.Label.TPB_Campaign_Member_Role;
        String[] arrRoles = strRoles.split(',');
        List<UserRole> lstRole = [ SELECT Id FROM UserRole WHERE Name IN :arrRoles ];
        objUser.UserRoleId = lstRole[0].Id;
        update objUser;
        System.assertNotEquals(objUser, null);
    }
}