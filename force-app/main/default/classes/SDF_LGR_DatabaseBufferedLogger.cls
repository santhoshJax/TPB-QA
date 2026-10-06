/**
 * Created by Wenbo on 7/1/2017.
 * SDF_LGR_DatabaseBufferedLogger - Allow user to defer the commit of the logs by placing logs in to a buffer.
 * This is useful when DML is not permitted before certain statements.
 * For example: HTTP request / call outs.
 *
 * Users can use this logger to buffer all the logs and explicitly inserting into the logging table by calling
 * the flush method.
 *
 * It is recommended to use a try catch statement where possible failures could occur and flush the logger's
 * buffer in the FINALLY block to persist the logged data.
 */

global without sharing class SDF_LGR_DatabaseBufferedLogger extends SDF_LGR_DatabaseLogger {
    private List<SDF_LGR_Log__c> buffer;

    /*
     * Constructor
     */
    global SDF_LGR_DatabaseBufferedLogger() {
        super();
        this.buffer = new List<SDF_LGR_Log__c>();
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
    protected override SDF_LGR_Log__c createLog(LoggingLevel level, String logMessage, Object logObject, String reference,
            String data, String dataOutbound, Id parentId) {
        SDF_LGR_Log__c newLog = super.createLogEntry(level, logMessage, logObject, reference, data, dataOutbound, parentId);
        this.buffer.add(newlog);
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
    protected override SDF_LGR_Log__c createLog(LoggingLevel level, String logMessage, Object logObject, String reference,
            String data, String dataOutbound) {
        return this.createLog(level, logMessage, logObject, reference, data, dataOutbound, null);
    }

    /*
     * Flush all buffered contents by inserting them into the logging table.
     * This method must be called or the logged content will not be persisted.
     */
    global void flush() {
        try {
            SDF_LGR_LoggerUtils.throwTestException();
            insert buffer;
            buffer.clear();
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Failed to commit log buffer. Log size: ' + buffer.size() + '\n' + buffer);
            System.debug(LoggingLevel.ERROR, ex);
        }
    }
}