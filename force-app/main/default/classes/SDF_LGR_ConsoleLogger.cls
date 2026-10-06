/**
 * @class_description For logging error in the developer console and SF log entries
 * @class_version 0.1
 */

global virtual without sharing class SDF_LGR_ConsoleLogger implements SDF_LGR_LoggerInterface {
    global static final String DEFAULT_CONSOLE_LOG_FORMAT
        = '[{0}][{1}][{2}][{3}({4})][5] --- \n{6}';
    global static final String DEFAULT_CONSOLE_DATETIME_FORMAT
        = 'yyyy-MM-dd HH:mm:ss z';
    private LoggingLevel level { get; set; }
    global String logFormat { get; set; }
    global String timeFormat { get; set; }
    global String userId {
        get {
            return UserInfo.getUserId();
        }
    }
    global String userName {
        get {
            return UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
        }
    }

    /**
     * @description Creates a new instance of the SDF_LGR_ConsoleLogger class
     */
    global SDF_LGR_ConsoleLogger() {
        logFormat = DEFAULT_CONSOLE_LOG_FORMAT;
        timeFormat = DEFAULT_CONSOLE_DATETIME_FORMAT;
        level = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
    }

    /**
     * @description Sets the maximum logging level
     * @param level:The maximum logging level
     */
    global void setLevel(LoggingLevel level) {
        if (level == null) { return; }
        this.level = level;
    }

    /**
     * @description Formats the log
     * @param level:The logging level
     * @param logMessage:A message to be logged
     * @param logObject:Object for which the log is originated
     * @param reference:An user reference for identification
     * @return String:A formatted log message
     */
    private String formatLog(LoggingLevel level, String logMessage, Object logObject, String reference) {
        if(String.isBlank(reference)) { reference = '';}
        String log = String.format(this.logFormat, new List<String> {
            DateTime.now().formatGMT(this.timeFormat),
            String.valueOf(level),
            SDF_LGR_LoggerUtils.getObjectType(logObject),
            this.userName,
            this.userId,
            reference,
            logMessage
        });
        return log;
    }

    /**
     * @description Log an info message
     * @param logMessage:Message to be logged
     * @param logObject:Object for which the log is originated
     * @param reference:An user reference for identification
     */
    global void info(String logMessage, Object logObject, String reference) {
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.INFO.ordinal() < level.ordinal()) { return; }
            System.debug(LoggingLevel.INFO, formatLog(LoggingLevel.INFO, logMessage, logObject, reference));
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /**
     * @description Log a debug message
     * @param logMessage:Message to be logged
     * @param logObject:Object for which the log is originated
     * @param reference:An user reference for identification
     */
    global void debug(String logMessage, Object logObject, String reference) {
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.DEBUG.ordinal() < level.ordinal()) { return; }
            System.debug(LoggingLevel.DEBUG, formatLog(LoggingLevel.DEBUG, logMessage, logObject, reference));
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /**
     * @description Log a warning message
     * @param logMessage:Message to be logged
     * @param logObject:Object for which the log is originated
     * @param reference:An user reference for identification
     */
    global void warn(String logMessage, Object logObject, String reference) {
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            if (LoggingLevel.WARN.ordinal() < level.ordinal()) { return; }
            System.debug(LoggingLevel.WARN, formatLog(LoggingLevel.WARN, logMessage, logObject, reference));
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /**
     * @description Log an error message
     * @param logMessage:Message to be logged
     * @param logObject:Object for which the log is originated
     * @param reference:An user reference for identification
     */
    global void error(String logMessage, Object logObject, String reference) {
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            System.debug(LoggingLevel.ERROR, formatLog(LoggingLevel.ERROR, logMessage, logObject, reference));
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
    }

    /**
     * @description Log an error exception
     * @param ex:Exception object to be logged
     * @param logObject:Object for which the log is originated
     * @param reference:An user reference for identification
     */
    global void error(Exception ex, Object logObject, String reference) {
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            String exceptionMessage = SDF_LGR_LoggerUtils.formatExceptionTree(ex);
            System.debug(LoggingLevel.ERROR, formatLog(LoggingLevel.ERROR, exceptionMessage, logObject, reference));
        } catch (Exception ex1) {
            System.debug(LoggingLevel.ERROR, ex1);
        }
    }

    /**
     * @description Log an error exception with a custom log message
     * @param logMessage:Message to be logged
     * @param ex:Exception object to be logged
     * @param logObject:Object for which the log is originated
     * @param reference:An user reference for identification
     */
    global void error(String logMessage, Exception ex, Object logObject, String reference) {
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            String exceptionMessage = SDF_LGR_LoggerUtils.formatExceptionTree(ex);
            String outputMessage = logMessage + '\n' + exceptionMessage;
            System.debug(LoggingLevel.ERROR, formatLog(LoggingLevel.ERROR, outputMessage, logObject, reference));
        } catch (Exception ex1) {
            System.debug(LoggingLevel.ERROR, ex1);
        }
    }
}