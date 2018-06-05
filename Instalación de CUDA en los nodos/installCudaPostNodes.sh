if [ "$#" -lt 1 ]; then
        echo "USO <host1> .... <hostN>"
        exit
else
    	for host in "${@:1}"
        do
          	echo "Terminando la instalacion de cuda en nodo $host"
	        scp -r /export/rocks/install/contrib/6.2/x86_64/cudasdk8.0.run $host:/tmp
	        scp -r /export/rocks/install/contrib/6.2/x86_64/cudasdk8.0_patch.run $host:/tmp
                rocks run host $host "chmod 755 /tmp/cudasdk8.0.run"
                rocks run host $host "chmod 755 /tmp/cudasdk8.0_patch.run"
                rocks run host $host "/tmp/cudasdk8.0.run --silent --toolkit --driver --samples"
                rocks run host $host "/tmp/cudasdk8.0_patch.run --silent --accept-eula"
                echo "Terminada en $host"
        done
fi
