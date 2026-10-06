/**
 * Created by Wenbo on 6/22/2017.
 * SDF_LGR_LoggerInterface - Interface defines the method signatures of all the loggers
 */

global interface SDF_LGR_LoggerInterface {
    void setLevel(LoggingLevel level);
    void info(String logMessage, Object logObject, String reference);
    void debug(String logMessage, Object logObject, String reference);
    void warn(String logMessage, Object logObject, String reference);
    void error(String logMessage, Object logObject, String reference);
    void error(Exception ex, Object logObject, String reference);
    void error(String logMessage, Exception ex, Object logObject, String reference);
}