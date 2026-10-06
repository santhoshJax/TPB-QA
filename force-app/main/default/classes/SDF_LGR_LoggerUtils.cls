/**
 * @class_description Utility class for loggers
 * @class_version 0.1
 */

global without sharing class SDF_LGR_LoggerUtils {
    public static Boolean isThrow = false;
    /**
     * @description Gets an instance of the logger by its name
     * @param loggerName:A logger's class name
     * @return SDF_LGR_LoggerInterface:An instance of the logger with the class name provided
     */
    global static SDF_LGR_LoggerInterface getLogger(String loggerName) {
        try {
            throwTestException();
            Type instanceType = Type.forName(loggerName);
            if (instanceType == null) { return null;}
            return (SDF_LGR_LoggerInterface) instanceType.newInstance();
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex);
        }
        return null;
    }

    /**
     * @description Gets the object type name
     * @param logObject:An object instance
     * @return String:The name for the object
     */
    global static String getObjectType(Object logObject) {
        if (logObject == null) { return '';}

        if (logObject instanceof ID) {
            return 'ID';
        } else if (logObject instanceof String
                   || logObject instanceof Type) {
            return String.valueOf(logObject);
        } else if (logObject instanceof Blob) {
            return 'Blob';
        } else if (logObject instanceof Boolean) {
            return 'Boolean';
        } else if (logObject instanceof Date) {
            return 'Date';
        } else if (logObject instanceof Datetime) {
            return 'DateTime';
        } else if (logObject instanceof Integer) {
            return 'Integer';
        } else if (logObject instanceof Long) {
            return 'Long';
        } else if (logObject instanceof Decimal) {
            return 'Decimal';
        }  else if (logObject instanceof Time) {
            return 'Time';
        } else {
            String[] tokens = String.valueOf(logObject).split(':');
            return tokens[0];
        }
    }

    /**
     * @description Format an exception
     * @param ex:An exception to be formated
     * @return String:A string that is formatted from an exception
     */
    global static String formatException(Exception ex) {
        return String.format('Exception - {0}: {1}\n' +
        'Stack trace:\n{2}\n', new List<String> {
            ex.getTypeName(),
            ex.getMessage(),
            ex.getStackTraceString()
        });
    }

    /**
     * @description Format an exception recursively. If an exception contains sub-cause exceptions, concatenate them and return
     * @param ex:An exception to be formated
     * @return String:A string that is formatted from an exception
     */
    global static String formatExceptionTree(Exception ex) {
        if (ex == null) { return '';}
        String exceptionLog = formatException(ex);
        Exception causeException = ex.getCause();
        if (causeException == null) { return exceptionLog;}
        return exceptionLog + '\nCaused by: ' + formatExceptionTree(causeException);
    }

    /**
     * @description Throw a exception in test code
     */
    global static void throwTestException() {
        if (Test.isRunningTest() && isThrow) {
            throw new SDF_LGR_GeneralException();
        }
    }

    /**
     * @description Throw a Message of Exception in test code
     * @param strExMsg:The Message of Excception
     */
    global static void throwTestException(String strExMsg) {
        if (Test.isRunningTest() && isThrow) {
            throw new SDF_LGR_GeneralException(strExMsg);
        }
    }
}