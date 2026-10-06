/**
 * Created by Wenbo on 6/25/2017.
 * SDF_LGR_ConsoleLoggerTest
 */

@isTest
public class SDF_LGR_ConsoleLoggerTest {

    static testMethod void testConsoleLogger() {
        SDF_LGR_LoggerInterface logger;
        logger = SDF_LGR_LoggerUtils.getLogger('SDF_LGR_ConsoleLogger');
        System.assert(logger != null);

        logger.setLevel(LoggingLevel.INFO);

        logger.info('Test logging', SDF_LGR_ConsoleLogger.class, null);
        logger.debug('Test logging', SDF_LGR_ConsoleLogger.class, null);
        logger.warn('Test logging', SDF_LGR_ConsoleLogger.class, null);
        logger.error('Test logging', SDF_LGR_ConsoleLogger.class, null);

        try {
            throw new SDF_LGR_GeneralException('My exception');
        } catch (Exception ex) {
            logger.error(ex, SDF_LGR_ConsoleLogger.class, null);
            logger.error('Test loggin', ex, SDF_LGR_ConsoleLogger.class, null);
        }
    }

    static testMethod void testConsoleLogger1() {
        SDF_LGR_LoggerInterface logger;
        logger = SDF_LGR_LoggerUtils.getLogger('SDF_LGR_ConsoleLogger');
        System.assert(logger != null);

        SDF_LGR_LoggerUtils.isThrow = true;
        logger.info('Test logging', SDF_LGR_ConsoleLogger.class, null);
        logger.debug('Test logging', SDF_LGR_ConsoleLogger.class, null);
        logger.warn('Test logging', SDF_LGR_ConsoleLogger.class, null);
        logger.error('Test logging', SDF_LGR_ConsoleLogger.class, null);
        logger.error(new DmlException(), SDF_LGR_ConsoleLogger.class, null);
        logger.error('Test logging', new DmlException(),  SDF_LGR_ConsoleLogger.class, null);
    }
}