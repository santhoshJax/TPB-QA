/**
 * Created by wzhou039 on 9/4/2017.
 */

@IsTest
public with sharing class SDF_LGR_LoggerSettingTest {

    static testMethod void testDefaultSettings() {
        System.assertEquals(true, SDF_LGR_LoggerSetting.isLoggingEnabled());
        System.assert(LoggingLevel.ERROR == SDF_LGR_LoggerSetting.getDefaultLoggingLevel());

        List<String> returnStringList = SDF_LGR_LoggerSetting.getLoggerNames();
        System.assertEquals(SDF_LGR_ConsoleLogger.class.getName(), returnStringList.get(0));

        SDF_LGR_Log_Setting__c stdLogger = new SDF_LGR_Log_Setting__c();
        stdLogger.Name = 'Classes_STD_Logger';
        stdLogger.Value__c = SDF_LGR_ConsoleLogger.class.getName();
        insert stdLogger;
        returnStringList = SDF_LGR_LoggerSetting.getLoggerNames();
        System.assertEquals(SDF_LGR_ConsoleLogger.class.getName(), returnStringList.get(0));

        System.assertEquals(SDF_LGR_DatabaseLogger.class.getName(), SDF_LGR_LoggerSetting.getDBLoggerName());
    }

    static testMethod void testLoggerMaxLengthSmallerThanThreshold() {
        SDF_LGR_Log_Setting__c maxLogLengthSetting = new SDF_LGR_Log_Setting__c();
        maxLogLengthSetting.Name = 'Max_Log_Length';
        maxLogLengthSetting.Value__c = '100';
        maxLogLengthSetting.Short_Description__c = 'Maximum length for the log message';
        insert maxLogLengthSetting;
        System.assertEquals(131072, SDF_LGR_LoggerSetting.MAX_STRING_LOG_LENGTH);
    }

    static testMethod void testLoggerSettings() {
        Test.startTest();

        SDF_LGR_Log_Setting__c stdLoggerSetting = new SDF_LGR_Log_Setting__c();
        stdLoggerSetting.Name = 'Classes_STD_Logger';
        stdLoggerSetting.Value__c = 'Account,Case';
        stdLoggerSetting.Short_Description__c = 'Demo data only';
        insert stdLoggerSetting;

        SDF_LGR_Log_Setting__c enabledSetting = new SDF_LGR_Log_Setting__c();
        enabledSetting.Name = 'Enabled';
        enabledSetting.Value__c = 'TRUE';
        enabledSetting.Short_Description__c = 'Turn the loggers on if the value is TRUE, FALSE otherwise';
        insert enabledSetting;

        SDF_LGR_Log_Setting__c maxLogLengthSetting = new SDF_LGR_Log_Setting__c();
        maxLogLengthSetting.Name = 'Max_Log_Length';
        maxLogLengthSetting.Value__c = '131072';
        maxLogLengthSetting.Short_Description__c = 'Maximum length for the log message';
        insert maxLogLengthSetting;

        SDF_LGR_Log_Setting__c logLevelSetting = new SDF_LGR_Log_Setting__c();
        logLevelSetting.Name = 'Log_Level';
        logLevelSetting.Value__c = 'DEBUG';
        logLevelSetting.Short_Description__c = 'Default log currentLoggingLevel for loggers. Values from LoggingLevel enum class';
        insert logLevelSetting;

        SDF_LGR_Log_Setting__c dbLoggerSetting = new SDF_LGR_Log_Setting__c();
        dbLoggerSetting.Name = 'Class_DBLogger';
        dbLoggerSetting.Value__c = 'Account';
        dbLoggerSetting.Short_Description__c = 'Demo data only';
        insert dbLoggerSetting;

        // test logging enable
        System.assert(SDF_LGR_LoggerSetting.isLoggingEnabled());
        enabledSetting.Value__c = 'false';
        update enabledSetting;
        System.assert(!SDF_LGR_LoggerSetting.isLoggingEnabled());

        // test default logging currentLoggingLevel
        LoggingLevel currentLoggingLevel;
        logLevelSetting.Value__c = 'DEBUG';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.DEBUG == currentLoggingLevel);

        logLevelSetting.Value__c = 'ERROR';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.ERROR == currentLoggingLevel);

        logLevelSetting.Value__c = 'FINE';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.FINE == currentLoggingLevel);

        logLevelSetting.Value__c = 'FINER';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.FINER == currentLoggingLevel);

        logLevelSetting.Value__c = 'FINEST';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.FINEST == currentLoggingLevel);

        logLevelSetting.Value__c = 'INFO';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.INFO == currentLoggingLevel);

        logLevelSetting.Value__c = 'INTERNAL';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.INTERNAL == currentLoggingLevel);

        logLevelSetting.Value__c = 'NONE';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.NONE == currentLoggingLevel);

        logLevelSetting.Value__c = 'WARN';
        update logLevelSetting;
        currentLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
        System.assert(LoggingLevel.WARN == currentLoggingLevel);

        // test get default log name - use only test class type
        List<String> returnStringList = SDF_LGR_LoggerSetting.getLoggerNames();
        System.assertEquals(2, returnStringList.size());
        System.assertEquals('Account', returnStringList.get(0));
        System.assertEquals('Case', returnStringList.get(1));
        stdLoggerSetting.Value__c = 'abc,Account';
        update stdLoggerSetting;
        returnStringList = SDF_LGR_LoggerSetting.getLoggerNames();
        System.assertEquals(SDF_LGR_ConsoleLogger.class.getName(), returnStringList.get(0));
        stdLoggerSetting.Value__c = '';
        update stdLoggerSetting;
        System.assertEquals(SDF_LGR_ConsoleLogger.class.getName(), returnStringList.get(0));

        // test get default DB logger name - use only test class type
        String returnString = SDF_LGR_LoggerSetting.getDBLoggerName();
        System.assertEquals('Account', returnString);
        dbLoggerSetting.Value__c = '';
        update dbLoggerSetting;
        returnString = SDF_LGR_LoggerSetting.getDBLoggerName();
        System.assertEquals(SDF_LGR_DatabaseLogger.class.getName(), returnString);

        Test.stopTest();
    }
}