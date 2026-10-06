/**
 * Created by Wenbo on 7/1/2017.
 * SDF_LGR_LoggerContainerTest
 */

@IsTest
private class SDF_LGR_LoggerContainerTest {
    static testMethod void testContainer() {
        SDF_LGR_LoggerContainer container = new SDF_LGR_LoggerContainer();
        container.setLevel(LoggingLevel.DEBUG);
        container.register(SDF_LGR_ConsoleLogger.class.getName())
        .register(SDF_LGR_DatabaseLogger.class.getName())
        .unregister(SDF_LGR_ConsoleLogger.class.getName());

        System.assertEquals(1, container.getAllRegisteredNames().size());

        SDF_LGR_Log_Setting__c debugSetting = new SDF_LGR_Log_Setting__c();
        debugSetting.Name = 'Log_Level';
        debugSetting.Value__c = 'DEBUG';
        insert debugSetting;

        SDF_LGR_Log_Setting__c loggerSetting = new SDF_LGR_Log_Setting__c();
        loggerSetting.Name = 'Classes_STD_Logger';
        loggerSetting.Value__c = 'SDF_LGR_DatabaseLogger';
        insert loggerSetting;

        SDF_LGR_LoggerManager.Logger.info('Test logging', SDF_LGR_ConsoleLogger.class, null);
        SDF_LGR_LoggerManager.Logger.debug('Test logging', SDF_LGR_ConsoleLogger.class, null);
        SDF_LGR_LoggerManager.Logger.warn('Test logging', SDF_LGR_ConsoleLogger.class, null);
        SDF_LGR_LoggerManager.Logger.error('Test logging', SDF_LGR_ConsoleLogger.class, null);

        try {
            throw new SDF_LGR_GeneralException('My exception');
        } catch (Exception ex) {
            SDF_LGR_LoggerManager.Logger.error(ex, SDF_LGR_ConsoleLogger.class, null);
            SDF_LGR_LoggerManager.Logger.error('Test loggin', ex, SDF_LGR_ConsoleLogger.class, null);
        }

        List<SDF_LGR_Log__c> logList = [SELECT Id FROM SDF_LGR_Log__c WHERE Id<>null LIMIT 50000];
        System.assertEquals(6, logList.size());
    }

    static testMethod void testContainerMutiRegister() {
        SDF_LGR_LoggerContainer container = new SDF_LGR_LoggerContainer();
        container.setLevel(LoggingLevel.DEBUG);
        container.register(SDF_LGR_ConsoleLogger.class.getName());
        container.register(SDF_LGR_ConsoleLogger.class.getName());

        System.assertEquals(1, container.getAllRegisteredNames().size());
        container.setLevel(LoggingLevel.DEBUG);
    }
}