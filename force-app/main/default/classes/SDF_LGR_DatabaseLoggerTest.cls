/**
 * Created by Wenbo on 6/25/2017.
 * SDF_LGR_DatabaseLoggerTest
 */

@IsTest
private class SDF_LGR_DatabaseLoggerTest {
    static SDF_LGR_DatabaseLogger logger;

    static {
        logger = (SDF_LGR_DatabaseLogger) SDF_LGR_LoggerUtils.getLogger('SDF_LGR_DatabaseLogger');
    }

    static testMethod void testDatabaseLoggerStandardMethods() {
        Test.startTest();
        logger.setLevel(LoggingLevel.DEBUG);
        logger.info('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testInfo');
        logger.debug('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testDebug');
        logger.warn('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testWarn');
        logger.error('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testError');
        try {
            throw new SDF_LGR_GeneralException('My exception');
        } catch (Exception ex) {
            logger.error(ex, SDF_LGR_ConsoleLogger.class, 'testErrExcept');
            logger.error('Test loggin', ex, SDF_LGR_ConsoleLogger.class, 'testErrExceptMsg');
        }

        assertSingleLog('testInfo');
        assertSingleLog('testDebug');
        assertSingleLog('testWarn');
        assertSingleLog('testError');
        assertSingleLog('testErrExcept');
        assertSingleLog('testErrExceptMsg');

        Test.stopTest();
    }

    static testMethod void testDatabaseLoggerExtendedMethods() {
        Test.startTest();
        logger.setLevel(LoggingLevel.DEBUG);
        Id logId;
        Id childLogId;
        List<SDF_LGR_Log__c> logList;
        List<SDF_LGR_Log__c> childLogList;

        logId = logger.info('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                            SDF_LGR_DatabaseLoggerTest.class, 'testInfo');
        logList = [SELECT Id, Data__c FROM SDF_LGR_Log__c WHERE Id = :logId];
        System.assertEquals(1, logList.size());
        System.assert(String.isNotBlank(logList[0].Data__c));

        childLogId =
            logger.info('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                        SDF_LGR_DatabaseLoggerTest.class, 'testInfoChild', logId);
        childLogList = [SELECT Id FROM SDF_LGR_Log__c WHERE Parent_Log__c = :logId];
        System.assertEquals(1, childLogList.size());

        logId = logger.debug('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                             SDF_LGR_DatabaseLoggerTest.class, 'testDebug');
        logList = [SELECT Id, Data__c FROM SDF_LGR_Log__c WHERE Id = :logId];
        System.assertEquals(1, logList.size());
        System.assert(String.isNotBlank(logList[0].Data__c));

        childLogId =
            logger.debug('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                         SDF_LGR_DatabaseLoggerTest.class, 'testInfoChild', logId);
        childLogList = [SELECT Id FROM SDF_LGR_Log__c WHERE Parent_Log__c = :logId];
        System.assertEquals(1, childLogList.size());

        logId = logger.warn('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                            SDF_LGR_DatabaseLoggerTest.class, 'testWarn');
        logList = [SELECT Id, Data__c FROM SDF_LGR_Log__c WHERE Id = :logId];
        System.assertEquals(1, logList.size());
        System.assert(String.isNotBlank(logList[0].Data__c));

        childLogId =
            logger.warn('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                        SDF_LGR_DatabaseLoggerTest.class, 'testInfoChild', logId);
        childLogList = [SELECT Id, Data__c FROM SDF_LGR_Log__c WHERE Parent_Log__c = :logId];
        System.assertEquals(1, childLogList.size());

        logId = logger.error('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                             SDF_LGR_DatabaseLoggerTest.class, 'testError');
        logList = [SELECT Id, Data__c FROM SDF_LGR_Log__c WHERE Id = :logId];
        System.assertEquals(1, logList.size());
        System.assert(String.isNotBlank(logList[0].Data__c));

        childLogId =
            logger.error('Test message', '{ samepleJsonData: "hello" }', '{ samepleJsonData: "hello" }',
                         SDF_LGR_DatabaseLoggerTest.class, 'testInfoChild', logId);
        childLogList = [SELECT Id, Data__c FROM SDF_LGR_Log__c WHERE Parent_Log__c = :logId];
        System.assertEquals(1, childLogList.size());

        Test.stopTest();
    }

    static testMethod void testDatabaseLoggerWithWarningLevel() {
        Test.startTest();
        logger.setLevel(LoggingLevel.WARN);
        logger.info('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW');
        logger.debug('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testDebugW');
        logger.warn('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testWarnW');
        logger.error('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testErrorW');

        assertSingleLogNotExist('testInfoW');
        assertSingleLogNotExist('testDebugW');
        assertSingleLog('testWarnW');
        assertSingleLog('testErrorW');

        Test.stopTest();
    }

    static void assertSingleLog(String reference) {
        List<SDF_LGR_Log__c> logList = [SELECT Id FROM SDF_LGR_Log__c WHERE Reference__c = :reference];
        System.assertEquals(1, logList.size());
    }

    static void assertSingleLogNotExist(String reference) {
        List<SDF_LGR_Log__c> logList = [SELECT Id FROM SDF_LGR_Log__c WHERE Reference__c = :reference];
        System.assertEquals(0, logList.size());
    }

    static testMethod void testException() {
        Test.startTest();
        SDF_LGR_LoggerUtils.isThrow = true;
        logger.setLevel(LoggingLevel.DEBUG);
        logger.info('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW');
        logger.debug('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testDebugW');
        logger.warn('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testWarnW');
        logger.error('Test logging', SDF_LGR_DatabaseLoggerTest.class, 'testErrorW');
        logger.error(new DmlException(), SDF_LGR_DatabaseLoggerTest.class, 'testErrorW');
        logger.error('Test logging', new DmlException(), SDF_LGR_DatabaseLoggerTest.class, 'testErrorW');

        logger.info('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW');
        logger.debug('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW');
        logger.warn('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW');
        logger.error('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW');

        ID oId = '0010o00002FEfbyAAD';
        logger.info('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW', oId);
        logger.debug('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW', oId);
        logger.warn('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW', oId);
        logger.error('Test logging', 'test', 'test', SDF_LGR_DatabaseLoggerTest.class, 'testInfoW', oId);
        Test.stopTest();
    }
}