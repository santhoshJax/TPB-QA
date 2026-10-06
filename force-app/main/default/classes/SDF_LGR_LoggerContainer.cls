/**
 * Created by Wenbo on 7/1/2017.
 * SDF_LGR_LoggerContainer - register or unregister a collection of SDF_LGR_LoggerInterface's instances. Then use the container to log a single
 * message to multiple registered loggers at once.
 */

global virtual without sharing class SDF_LGR_LoggerContainer implements SDF_LGR_LoggerInterface {
    private LoggingLevel maxLoggingLevel { get; set; }
    private Map<String, SDF_LGR_LoggerInterface> loggerDictionary = new Map<String, SDF_LGR_LoggerInterface>();

    /*
     * Constructor
     */
    global SDF_LGR_LoggerContainer() {
        init();
    }

    /*
     * Initialize the logger namager
     */
    private void init() {
        maxLoggingLevel = SDF_LGR_LoggerSetting.getDefaultLoggingLevel();
    }

    /*
     * Register a logger instance by its name
     * @param loggerName Logger name to register
     */
    global SDF_LGR_LoggerContainer register(String loggerName) {
        if (loggerDictionary.containsKey(loggerName)) {
            return this;
        }
        SDF_LGR_LoggerInterface newLogger = SDF_LGR_LoggerUtils.getLogger(loggerName);
        newLogger.setLevel(maxLoggingLevel);
        if (newLogger == null) { return this;}
        loggerDictionary.put(loggerName, newLogger);
        return this;
    }

    /*
     * Unregister a logger instance
     * @param loggerName Logger name to unregister
     * @return a boolean to indicate whether a logger is unregistered.
     */
    global SDF_LGR_LoggerContainer unregister(String loggerName) {
        if (!loggerDictionary.containsKey(loggerName)) { return this;}
        loggerDictionary.remove(loggerName);
        return this;
    }

    /*
     * Gets a set of registered logger's names.
     * @return a set of registered logger's names
     */
    global Set<String> getAllRegisteredNames() {
        return this.loggerDictionary.keySet();
    }

    /*
     * Sets the maxium logging level for the logger container and all registered loggers
     * @param level a logging level
     */
    global void setLevel(LoggingLevel level) {
        if (level == null) { return;}
        maxLoggingLevel = level;
        for (SDF_LGR_LoggerInterface logger : loggerDictionary.values()) {
            logger.setLevel(level);
        }
    }

    /***** Interface methods *****/

    /*
     * Log an info message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void info(String logMessage, Object logObject, String reference) {
        for (SDF_LGR_LoggerInterface loggerInstance : loggerDictionary.values()) {
            loggerInstance.info(logMessage, logObject, reference);
        }
    }

    /*
     * Log a debug message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void debug(String logMessage, Object logObject, String reference) {
        for (SDF_LGR_LoggerInterface loggerInstance : loggerDictionary.values()) {
            loggerInstance.debug(logMessage, logObject, reference);
        }
    }

    /*
     * Log a warning message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void warn(String logMessage, Object logObject, String reference) {
        for (SDF_LGR_LoggerInterface loggerInstance : loggerDictionary.values()) {
            loggerInstance.warn(logMessage, logObject, reference);
        }
    }

    /*
     * Log an error message
     * @param logMessage message to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void error(String logMessage, Object logObject, String reference) {
        for (SDF_LGR_LoggerInterface loggerInstance : loggerDictionary.values()) {
            loggerInstance.error(logMessage, logObject, reference);
        }
    }

    /*
     * Log an error exception
     * @param ex Exception object to be logged
     * @param logObject object for which the log is originated
     * @param reference an user reference for identification
     */
    global void error(Exception ex, Object logObject, String reference) {
        for (SDF_LGR_LoggerInterface loggerInstance : loggerDictionary.values()) {
            loggerInstance.error(ex, logObject, reference);
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
        for (SDF_LGR_LoggerInterface loggerInstance : loggerDictionary.values()) {
            loggerInstance.error(logMessage, ex, logObject, reference);
        }
    }
}