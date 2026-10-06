/**
 * @class_description Serve as an access point for all the loggers and maintaining the logging instances throughout a client session
 * @class_version 0.1
 */

global without sharing class SDF_LGR_LoggerManager {
    private static SDF_LGR_LoggerContainer container { get; set; }
    private static SDF_LGR_LoggerDatabaseInterface dbaseLogger { get; set; }
    private static SDF_LGR_DatabaseBufferedLogger dbuffLogger { get; set; }

    /**
     * @description Gets an logger container instance implemented with standard logger interface
     */
    global static SDF_LGR_LoggerContainer Logger {
        get {
            if (container != null) { return container;}
            container = new SDF_LGR_LoggerContainer();
            // Gets the logger from the logger setting for registration`
            for (String loggerName : SDF_LGR_LoggerSetting.getLoggerNames()) {
                container.register(loggerName);
            }
            return container;
        }
    }

    /**
     * @description Gets an instance of database logger
     */
    global static SDF_LGR_LoggerDatabaseInterface DBLogger {
        get {
            if (dbaseLogger != null) { return dbaseLogger;}
            String loggerName = SDF_LGR_LoggerSetting.getDBLoggerName();
            if (String.isNotBlank(loggerName)) {
                SDF_LGR_LoggerInterface logger = SDF_LGR_LoggerUtils.getLogger(loggerName);
                if (logger instanceof SDF_LGR_LoggerDatabaseInterface) {
                    return (SDF_LGR_LoggerDatabaseInterface) logger;
                }
            }
            // Use default database logger
            dbaseLogger = new SDF_LGR_DatabaseLogger();
            return dbaseLogger;
        }
    }

    /**
     * @description Gets and instance of buffered database logger
     */
    global static SDF_LGR_DatabaseBufferedLogger DBufLogger {
        get {
            if (dbuffLogger != null) { return dbuffLogger;}
            dbuffLogger = new SDF_LGR_DatabaseBufferedLogger();
            return dbuffLogger;
        }
    }
}