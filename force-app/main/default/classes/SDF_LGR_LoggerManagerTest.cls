/**
 * Created by Wenbo on 6/25/2017.
 * SDF_LGR_LoggerManagerTest
 */

@IsTest
private class SDF_LGR_LoggerManagerTest {
    static testMethod void testLoggerManager() {
        System.assert(SDF_LGR_LoggerManager.DBLogger != null);
        System.assert(SDF_LGR_LoggerManager.DBufLogger != null);

        System.assert(SDF_LGR_LoggerManager.Logger != null);
        SDF_LGR_LoggerManager.Logger.info('Test logging', SDF_LGR_LoggerManagerTest.class, null);
        SDF_LGR_LoggerManager.Logger.debug('Test logging', SDF_LGR_LoggerManagerTest.class, null);
        SDF_LGR_LoggerManager.Logger.warn('Test logging', SDF_LGR_LoggerManagerTest.class, null);
        SDF_LGR_LoggerManager.Logger.error('Test logging', SDF_LGR_LoggerManagerTest.class, null);

        try {
            throw new SDF_LGR_GeneralException('My exception');
        } catch (Exception ex) {
            SDF_LGR_LoggerManager.Logger.error(ex, SDF_LGR_LoggerManagerTest.class, null);
            SDF_LGR_LoggerManager.Logger.error('Test loggin', ex, SDF_LGR_LoggerManagerTest.class, null);
        }

        SDF_LGR_LoggerUtils.isThrow = true;
        SDF_LGR_LoggerDatabaseInterface logger =SDF_LGR_LoggerManager.DBLogger;
        Boolean islogger = logger != null;
        System.assertEquals(true, islogger);
    }

    static testMethod void testIntegrationLogger() {
        SDF_LGR_Log_Setting__c setting = new SDF_LGR_Log_Setting__c();
        setting.Name = 'Log_Level';
        setting.Value__c = 'DEBUG';
        insert setting;

        System.assert(SDF_LGR_LoggerManager.DBLogger != null);
        System.assert(
            SDF_LGR_LoggerManager.DBLogger.info(
                'Test logging',
                '{ jsonData: true }',
                '{ jsonData: true }',
                SDF_LGR_LoggerManagerTest.class, // replace with "this" if used in an instance class
                'ref0001') != null
        );
        System.assert(
            SDF_LGR_LoggerManager.DBLogger.debug(
                'Test logging',
                '{ jsonData: true }',
                '{ jsonData: true }',
                SDF_LGR_LoggerManagerTest.class, // replace with "this" if used in an instance class
                'ref0001') != null
        );
        System.assert(
            SDF_LGR_LoggerManager.DBLogger.warn(
                'Test logging',
                '{ jsonData: true }',
                '{ jsonData: true }',
                SDF_LGR_LoggerManagerTest.class, // replace with "this" if used in an instance class
                'ref0001') != null
        );
        System.assert(
            SDF_LGR_LoggerManager.DBLogger.error(
                'Test logging',
                '{ jsonData: true }',
                '{ jsonData: true }',
                SDF_LGR_LoggerManagerTest.class, // replace with "this" if used in an instance class
                'ref0001') != null
        );
    }
}