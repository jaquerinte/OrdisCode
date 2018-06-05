echo "Terminando la instalacion de cuda..."
rocks iterate host compute "scp -r /export/rocks/install/contrib/6.2/x86_64/cudasdk8.0.run %:/tmp"
rocks iterate host compute "scp -r /export/rocks/install/contrib/6.2/x86_64/cudasdk8.0_patch.run %:/tmp"
rocks run host "chmod 755 /tmp/cudasdk8.0.run"
rocks run host "chmod 755 /tmp/cudasdk8.0_patch.run"
rocks run host "/tmp/cudasdk8.0.run --silent --toolkit --driver --samples"
rocks run host "/tmp/cudasdk8.0_patch.run --silent --accept-eula"
echo "Terminada!
