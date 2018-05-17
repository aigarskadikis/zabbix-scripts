yum install zabbix-java-gateway -yum install tomcat -y

vi /etc/zabbix/zabbix_java_gateway_logback.xml

        <root level="debug">
                <appender-ref ref="FILE" />
        </root>

		
#define 
JavaGateway=127.0.0.1
JavaGatewayPort=10052
StartJavaPollers=5


 vi /etc/zabbix/zabbix_java_gateway.conf

START_POLLERS=5

find / -name server

vim /usr/libexec/tomcat/server
add 
-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.port=12345 \
-Dcom.sun.management.jmxremote.rmi.port=12345 \
-Dcom.sun.management.jmxremote.ssl=false \
-Dcom.sun.management.jmxremote.authenticate=false

systemctl start tomcat

yum install wget -yum


wget https://github.com/jiaqi/jmxterm/releases/download/v1.0.0/jmxterm-1.0.0-uber.jar


java -jar jmxterm-1.0.0-uber.jar
open 127.0.0.1:12345

beans

#list the beens










		