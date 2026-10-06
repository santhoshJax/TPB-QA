/**
 * Created by Wenbo on 6/24/2017.
 * SDF_LGR_DatabaseLogger -  For logging error in the database
 *
 * NOTE: Consider governer limit if you intend to use this logger among iterable control flows. E.g. for loop
 * Do not use this logger if you intend to call log among multiple system call out or http request, as DML is not allow
 * prior to any call out.
 */

global virtual without sharing class SDF_LGR_DatabaseLogger implements SDF_LGR_LoggerDatabaseInterface {
    private LoggingLevel level { get; set; }
    private Boolean isEnabled { get; set; }

    /*
     * Constructor
     */
    global SDF_LGR_DatabaseLogger() {
       level = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
       isEnabled = SDF_LGR_LoggerSetting.isLoggingEnabled();
    }

    /*
     * Sets the maximum logging level
     * @param level the maximum logging level
     */
    global void setLevel(LoggingLevel level) {
        if (level == null) { return; }
        this.level = level;
    }

    protected SDF_LGR_Log__c createLogEntry(LoggingLevel level, String logMessage, Object logObject, String reference,
            String data, String dataOutbound, Id parentId) {
        SDF_LGR_Log__c newlog = new SDF_LGR_Log__c();
        newLog.Level__c = level.name();
        newLog.Message__c =
                String.isNotBlank(logMessage) ? logMessage.abbreviate(SDF_LGR_LoggerSetting.MAX_STRING_LOG_LENGTH) : null;
        newLog.Class__c = SDF_LGR_LoggerUtils.getObjectType(logObject);
        newLog.Reference__c = reference;
        newLog.Parent_Log__c = parentId;
        newlog.Data__c =
                String.isNotBlank(data) ? data.abbreviate(SDF_LGR_LoggerSetting.MAX_STRING_LOG_LENGTH) : null;
        newlog.Data_Outbound__c =
                String.isNotBlank(dataOutbound) ? dataOutbound.abbreviate(SDF_LGR_LoggerSetting.MAX_STRING_LOG_LENGTH) : null;
        newLog.Parent_Log__c = parentId;
        return newlog;
    }

    /*
     * Creates a new log entry object for insertion later
     * @param level Logging level
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     * @param data data inbound data to be logged
     * @param dataOutbound outbound data to be logged
     * @param parentId a SDF_LGR_Log__c ID of the parent Log
     * @return a new instance of logger object to be persisted
     */
    protected virtual SDF_LGR_Log__c createLog(LoggingLevel level, String logMessage, Object logObject, String reference,
            String data, String dataOutbound, Id parentId) {
        SDF_LGR_Log__c newLog = this.createLogEntry(level, logMessage, logObject, reference, data, dataOutbound, parentId);
        insert newLog;
        return newlog;
    }

    /*
     * Creates a new log entry object for insertion later
     * @param level Logging level
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     * @param data data inbound data to be logged
     * @param dataOutbound outbound data to be logged
     * @return a new instance of logger object to be persisted
     */
    protected virtual SDF_LGR_Log__c createLog(LoggingLevel level, String logMessage, Object logObject, String reference,
            String data, String dataOutbound) {
        return createLog(level, logMessage, logObject, reference, data, dataOutbound, null);
    }

    /***** Interface methods *****/

    /*
     * Log an info message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void info(String logMessage, Object logObject, String reference) {
        if (!isEnabled) { return; }
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.INFO.ordinal() < level.ordinal()) { return; }
            createLog(LoggingLevel.INFO, logMessage, logObject, reference, null, null);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /*
     * Log a debug message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void debug(String logMessage, Object logObject, String reference) {
        if (!isEnabled) { return; }
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.DEBUG.ordinal() < level.ordinal()) { return; }
            createLog(LoggingLevel.DEBUG, logMessage, logObject, reference, null, null);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /*
     * Log a warning message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void warn(String logMessage, Object logObject, String reference) {
        if (!isEnabled) { return; }
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.WARN.ordinal() < level.ordinal()) { return; }
            createLog(LoggingLevel.WARN, logMessage, logObject, reference, null, null);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /*
     * Log an error message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void error(String logMessage, Object logObject, String reference) {
        if (!isEnabled) { return; }
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            createLog(LoggingLevel.ERROR, logMessage, logObject, reference, null, null);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /*
     * Log an error exception
     * @param ex Exception object to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void error(Exception ex, Object logObject, String reference) {
        if (!isEnabled) { return; }
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            String exceptionMessage = SDF_LGR_LoggerUtils.formatExceptionTree(ex);
            createLog(LoggingLevel.ERROR, exceptionMessage, logObject, reference, null, null);
        } catch (Exception ex1) {
            System.debug(LoggingLevel.ERROR, ex1);
        }
    }

    /*
     * Log an error exception with a custom log message
     * @param logMessage message to be logged
     * @param ex Exception object to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void error(String logMessage, Exception ex, Object logObject, String reference) {
        if (!isEnabled) { return; }
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            String exceptionMessage = SDF_LGR_LoggerUtils.formatExceptionTree(ex);
            String outputMessage = logMessage + '\n' + exceptionMessage;
            createLog(LoggingLevel.ERROR, outputMessage, logObject, reference, null, null);
        } catch (Exception ex1) {
            System.debug(LoggingLevel.ERROR, ex1);
        }
    }

    /***** Logger methods for intergration *****/

    global Id info(String logMessage, String data, String dataOutbound, Object logObject, String reference) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.INFO.ordinal() < level.ordinal()) { return null;}
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.INFO, logMessage, logObject, reference, data, dataOutbound);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    global Id debug(String logMessage, String data, String dataOutbound, Object logObject, String reference) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.DEBUG.ordinal() < level.ordinal()) { return null;}
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.DEBUG, logMessage, logObject, reference, data, dataOutbound);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    global Id warn(String logMessage, String data, String dataOutbound, Object logObject, String reference) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.WARN.ordinal() < level.ordinal()) { return null;}
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.WARN, logMessage, logObject, reference, data, dataOutbound);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    global Id error(String logMessage, String data, String dataOutbound, Object logObject, String reference) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.ERROR, logMessage, logObject, reference, data, dataOutbound);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    global Id info(String logMessage, String data, String dataOutbound, Object logObject, String reference,
            Id parentId) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.INFO.ordinal() < level.ordinal()) { return null;}
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.DEBUG, logMessage, logObject, reference, data, dataOutbound, parentId);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    global Id debug(String logMessage, String data, String dataOutbound, Object logObject, String reference,
            Id parentId) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.DEBUG.ordinal() < level.ordinal()) { return null;}
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.DEBUG, logMessage, logObject, reference, data, dataOutbound, parentId);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    global Id warn(String logMessage, String data, String dataOutbound, Object logObject, String reference,
            Id parentId) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.WARN.ordinal() < level.ordinal()) { return null;}
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.DEBUG, logMessage, logObject, reference, data, dataOutbound, parentId);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    global Id error(String logMessage, String data, String dataOutbound, Object logObject, String reference,
            Id parentId) {
        if (!isEnabled) { return null;}
        try {
            SDF_LGR_LoggerUtils.throwTestException('');
            SDF_LGR_Log__c newLog = createLog(LoggingLevel.DEBUG, logMessage, logObject, reference, data, dataOutbound, parentId);
            return newLog.Id;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }
}