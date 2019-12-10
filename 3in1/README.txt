Execute on database server:
chmod +x 1.database.sh
./1.database.sh
# file mysql.partitioning.sql must be side by side with 1.database.sh

Execute on core server:
chmod +x 2.backend.sh
./2.backend.sh

# to install SeriveNow dependecies
chmod +x 2a.alertscript.sh
./2a.alertscript.sh

Execute on frontend server:
chmod +x 3.frontend.sh
./3.frontend.sh
