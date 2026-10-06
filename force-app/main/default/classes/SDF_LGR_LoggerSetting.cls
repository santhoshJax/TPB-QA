/**
 * @class_description Contains a set of static methods and constants for loggers' configuration.
 * Usually these settings will be retrieved from external configuration source.
 * @class_version 0.1
 */

global without sharing class SDF_LGR_LoggerSetting {
    public static final String PARAM_ENABLED = 'Enabled';
    public static final String PARAM_LOG_LEVEL = 'Log_Level';
    public static final String PARAM_DB_LOGGER = 'Class_DBLogger';
    public static final String PARAM_STD_Logger = 'Classes_STD_Logger';
    public static final String PARAM_MAX_LOG_LENGTH = 'Max_Log_Length';
    global static final Integer MAX_STRING_LOG_LENGTH;

    static {
        try {
            SDF_LGR_Log_Setting__c setting = [
                    SELECT Value__c
                    FROM SDF_LGR_Log_Setting__c
                    WHERE Name = :SDF_LGR_LoggerSetting.PARAM_MAX_LOG_LENGTH
            ];
            Integer maxLogLength = Integer.valueOf(setting.Value__c);
            if (maxLogLength > 255) {
                MAX_STRING_LOG_LENGTH = maxLogLength;
            } else {
                MAX_STRING_LOG_LENGTH = 131072;
            }
        } catch (Exception ex) {
            System.debug(ex);
            MAX_STRING_LOG_LENGTH = 131072;
        }
    }

    /**
     * @description A kill switch to turn off the custom logging
     * @return Boolean:A boolean value indicate whether logging activities should be enabled
     */
    global static Boolean isLoggingEnabled() {
        try {
            SDF_LGR_Log_Setting__c setting = [
                    SELECT Value__c
                    FROM SDF_LGR_Log_Setting__c
                    WHERE Name = :SDF_LGR_LoggerSetting.PARAM_ENABLED
            ];
            return Boolean.valueOf(setting.Value__c);
        } catch (Exception ex) {
            System.debug(ex);
        }
        return true;
    }

    /**
     * @description Gets the default logging level
     * @return LoggingLevel:The default logging level
     */
    global static LoggingLevel getDefaultLoggingLevel() {
        // damn Apex is tedious in terms of enum parsing
        try {
            SDF_LGR_Log_Setting__c setting = [
                    SELECT Value__c
                    FROM SDF_LGR_Log_Setting__c
                    WHERE Name = :SDF_LGR_LoggerSetting.PARAM_LOG_LEVEL
            ];
            String level = setting.Value__c;
            if (level.toUpperCase() == 'DEBUG') {
                return LoggingLevel.DEBUG;
            }
            if (level.toUpperCase() == 'ERROR') {
                return LoggingLevel.ERROR;
            }
            if (level.toUpperCase() == 'FINE') {
                return LoggingLevel.FINE;
            }
            if (level.toUpperCase() == 'FINER') {
                return LoggingLevel.FINER;
            }
            if (level.toUpperCase() == 'FINEST') {
                return LoggingLevel.FINEST;
            }
            if (level.toUpperCase() == 'INFO') {
                return LoggingLevel.INFO;
            }
            if (level.toUpperCase() == 'INTERNAL') {
                return LoggingLevel.INTERNAL;
            }
            if (level.toUpperCase() == 'NONE') {
                return LoggingLevel.NONE;
            }
            if (level.toUpperCase() == 'WARN') {
                return LoggingLevel.WARN;
            }
        } catch (Exception ex) {
            System.debug(ex);
        }
        return LoggingLevel.ERROR;
    }

    /**
     * @description Gets a list of available logger's names
     * @return List<String>:A list of logger's names
     */
    global static List<String> getLoggerNames() {
        try {
            List<String> loggerClasses = new List<String>();
            SDF_LGR_Log_Setting__c setting = [
                    SELECT Value__c
                    FROM SDF_LGR_Log_Setting__c
                    WHERE Name = :SDF_LGR_LoggerSetting.PARAM_STD_Logger
            ];
            if (setting.Value__c.contains(',')) {
                loggerClasses = setting.Value__c.split(',');
            } else {
                loggerClasses = new List<String>{
                        setting.Value__c
                };
            }

            // check if type exists. If not, use the default logger
            Boolean allClassesAreValid = true;
            for (String className : loggerClasses) {
                Type classType = Type.forName(className);
                if (classType == null) {
                    allClassesAreValid = false;
                }
            }
            if (allClassesAreValid) {
                return loggerClasses;
            }
        } catch (Exception ex) {
            System.debug(ex);
        }

        return new List<String>{
                SDF_LGR_ConsoleLogger.class.getName()
                //SDF_LGR_DatabaseLogger.class.getName()
        };
    }

    /**
     * @description Gets a class of the DB logger
     * @return String:The name of the DB logger
     */
    global static String getDBLoggerName() {
        try {
            SDF_LGR_Log_Setting__c setting = [
                    SELECT Value__c
                    FROM SDF_LGR_Log_Setting__c
                    WHERE Name = :SDF_LGR_LoggerSetting.PARAM_DB_LOGGER
            ];
            String className = setting.Value__c;
            Type classType = Type.forName(className);
            if (classType != null) {
                return className;
            }
        } catch (Exception ex) {
            System.debug(ex);
        }
        return SDF_LGR_DatabaseLogger.class.getName();
    }
}