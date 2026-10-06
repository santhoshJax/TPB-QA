/**
 * Created by Wenbo on 7/1/2017.
 * SDF_LGR_DatabaseBufferedLoggerTest
 */

@IsTest
private class SDF_LGR_DatabaseBufferedLoggerTest {
    static testMethod void testBufferedLogging() {
        SDF_LGR_Log_Setting__c logLevelSetting = new SDF_LGR_Log_Setting__c();
        logLevelSetting.Name = 'Log_Level';
        logLevelSetting.Value__c = 'DEBUG';
        logLevelSetting.Short_Description__c = 'Default log currentLoggingLevel for loggers. Values from LoggingLevel enum class';
        insert logLevelSetting;

        SDF_LGR_DatabaseBufferedLogger logger = new SDF_LGR_DatabaseBufferedLogger();
        logger.info('Test logging', '{ jsonData: true }', '{ jsonData: true }',
                SDF_LGR_DatabaseBufferedLoggerTest.class, 'ref0001');
        logger.debug('Test logging', '{ jsonData: true }', '{ jsonData: true }',
                SDF_LGR_DatabaseBufferedLoggerTest.class, 'ref0001');
        logger.warn('Test logging', '{ jsonData: true }', '{ jsonData: true }',
                SDF_LGR_DatabaseBufferedLoggerTest.class, 'ref0001');
        logger.error('Test logging', '{ jsonData: true }', '{ jsonData: true }',
                SDF_LGR_DatabaseBufferedLoggerTest.class, 'ref0001');

        try {
            throw new SDF_LGR_GeneralException('My exception');
        } catch (Exception ex) {
            logger.error(ex, SDF_LGR_DatabaseBufferedLoggerTest.class, null);
            logger.error('Test loggin', ex, SDF_LGR_DatabaseBufferedLoggerTest.class, null);
        }

        List<SDF_LGR_Log__c> logList = [SELECT Id FROM SDF_LGR_Log__c WHERE Id<>null LIMIT 50000];
        System.assertEquals(0, logList.size());

        logger.flush();

        logList = [SELECT Id FROM SDF_LGR_Log__c WHERE Id<>null LIMIT 50000];
        System.assertEquals(6, logList.size());

        SDF_LGR_LoggerUtils.isThrow = true;
        logger.flush();
    }
}