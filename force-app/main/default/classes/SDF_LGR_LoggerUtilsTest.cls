/**
 * Created by Wenbo on 6/25/2017.
 * SDF_LGR_LoggerUtilsTest
 */

@IsTest
private class SDF_LGR_LoggerUtilsTest {
    static final String DEFAULT_LOGGER = 'SDF_LGR_ConsoleLogger';
    static testMethod void testGetLogger() {
        SDF_LGR_LoggerInterface consoleLogger = SDF_LGR_LoggerUtils.getLogger(DEFAULT_LOGGER);
        System.assert(consoleLogger != null);

        SDF_LGR_LoggerUtils.isThrow = true;
        SDF_LGR_LoggerUtils.getLogger(DEFAULT_LOGGER);
    }

    static testMethod void testGetObjectType() {
        User obj1 = new User(CommunityNickname='la');
        String accountType = SDF_LGR_LoggerUtils.getObjectType(obj1);
        System.assertEquals(obj1.getSobjectType().getDescribe().getName(), accountType);

        String primitiveType = SDF_LGR_LoggerUtils.getObjectType(12345.12);
        System.assertEquals('Decimal', primitiveType);

        String stringType = SDF_LGR_LoggerUtils.getObjectType('String');
        System.assertEquals('String', stringType);

        String booleanType = SDF_LGR_LoggerUtils.getObjectType(false);
        System.assertEquals('Boolean', booleanType);

        String dateType = SDF_LGR_LoggerUtils.getObjectType(Date.today());
        System.assertEquals('Date', dateType);

        String timeType = SDF_LGR_LoggerUtils.getObjectType(Time.newInstance(0, 0, 0, 0));
        System.assertEquals('Time', timeType);

        String dateTimeType = SDF_LGR_LoggerUtils.getObjectType(Datetime.now());
        System.assertEquals('DateTime', dateTimeType);

        String blobType = SDF_LGR_LoggerUtils.getObjectType(Blob.valueof('Blob'));
        System.assertEquals('Blob', blobType);

        ID i = '0010o00002FEfbyAAD';
        String idType = SDF_LGR_LoggerUtils.getObjectType(i);
        System.assertEquals('ID', idType);

        String integerType = SDF_LGR_LoggerUtils.getObjectType(Integer.valueOf('1'));
        System.assertEquals('Integer', integerType);

        String longType = SDF_LGR_LoggerUtils.getObjectType(Long.valueOf('4271990'));
        System.assertEquals('Long', longType);

    }

    static testMethod void testFormatExceptionTree() {
        try {
            doTest();
        } catch (SDF_LGR_GeneralException me) {
            String logInfo = SDF_LGR_LoggerUtils.formatExceptionTree(me);
            System.assert(logInfo!=null);
        }
    }

    static void doTest() {
        try {
            throw new DmlException();
        } catch (DmlException ex) {
            throw new SDF_LGR_GeneralException('test', ex);
        }
    }

     static testMethod void testThrowTestException() {
        try{
            SDF_LGR_LoggerUtils.isThrow=true;
            SDF_LGR_LoggerUtils.throwTestException();
        }catch(Exception ex){
            Boolean exTypeMatch = ex instanceof SDF_LGR_GeneralException;
            System.assertEquals(true, exTypeMatch);
        }
    }

    static testMethod void testThrowTestExceptionString() {
        try{
            SDF_LGR_LoggerUtils.isThrow=true;
            SDF_LGR_LoggerUtils.throwTestException('');
        }catch(Exception ex){
            Boolean exTypeMatch = ex instanceof SDF_LGR_GeneralException;
            System.assertEquals(true, exTypeMatch);
        }
    }
}