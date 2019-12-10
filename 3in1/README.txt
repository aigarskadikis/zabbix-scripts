1) 
Replace 10.132.148.248 with the IP address of database server (zdbs)
Replace 10.132.175.115 with the IP address of database server (zcs)
Replace 10.132.159.105 with the IP address of database server (zrws)


2)

Execute on database server:
chmod +x 1.database.sh
./1.database.sh
# file mysql.partitioning.sql must be side by side with 1.database.sh

Execute on core server:
chmod +x 2.backend.sh
./2.backend.sh

Execute on frontend server:
chmod +x 3.frontend.sh
./3.frontend.sh

