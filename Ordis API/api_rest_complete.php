<?php
	include_once "operationConnections/codeConnection.php";
	include_once "operationConnections/usrConnection.php";
	include_once "BasicApi/log.php";

	class Code {

		private static $MINIMO_NODOS=1;
		private static $MAXIMO_NODOS_GPU=31;
		private static $MAXIMO_NODOS_CPU=62;

		public static function addNewCode($user) {

			$ldap = new LDAPConnection();
			$usrData = $ldap->buscar($user);
			
			
			if($usrData != "ERROR: No such user" && UsrConnection::notBanned($usrData['uid'])) { //No ha habido error
				//checks if user exist if not create user in the system
				shell_exec("/export/scripts/maintenance/checkUser.sh ".$usrData["uid"]);
				
				$success = false;
				$tipo = $_POST['tipo_operacion'];
				$n_nodos = $_POST['n_nodos'];

				$MAXIMO_NODOS_AUX= self::$MAXIMO_NODOS_CPU;
				if($tipo === "cuda" || $tipo === "mpi-cuda") 
					$MAXIMO_NODOS_AUX= self::$MAXIMO_NODOS_GPU;
				if($n_nodos <  self::$MINIMO_NODOS || $n_nodos > $MAXIMO_NODOS_AUX) {
					echo "ERROR: Numero de nodos incorrecto. Ha de estar entre ".self::$MINIMO_NODOS." y ".$MAXIMO_NODOS_AUX." para el tipo de operacion: ".$tipo;
					return;
			} 

				//Trying to upload and unzip the file
				if($_FILES["zip_file"]["name"]) {
					$filename = $_FILES["zip_file"]["name"];
					$source = $_FILES["zip_file"]["tmp_name"];
					$type = $_FILES["zip_file"]["type"];

					$name = explode(".", $filename);
					
					if(!self::checkFileUploaded($filename, $type, $name)) {
						echo "The file you are trying to upload is not a .zip file. Please try again.";
						//console($message, 1, 5);
					}
					else {
						$target_path = "uploads/".$filename; 
						//$extract_path = "./uploads/".$user."/".$name[0];
						$extract_path = "/export/home/".$user."/"."projects/".$name[0];
						if(self::extractFile($filename, $name, $user, $source, $target_path, $extract_path)) { //If the file was upload and unzipped succesfully
							
							////////////
							// Escribimos fichero con los datos del cliente
							////////////
							//file_put_contents
							$parsedUserData = $usrData["uid"].":".$usrData["gidnumber"]." mailto --> ".$usrData["mail"];
							$dataFilePath = $extract_path."/datos.txt";
							file_put_contents($dataFilePath, $parsedUserData);

							//Get priority from BD

							if(self::checkFileSystem($extract_path)) {
								echo "The filesystem on the zip file is valid.";
								echo "<br/>";
								echo "Uploading a ".$tipo." code operation.<br/>";
								$tipo_valido = true;

								switch($tipo) {
									case "mpi":
										break;
									case "cuda":
										break;
									case "other-parallel":
										break;
									case "mpi-cuda":
										break;
									case "no-parallel":
										break;
									default:
										$tipo_valido = false;
								}

								if($tipo_valido) {
									//Here adding operation to BD
									$codeConn = new CodeConnection();

									//($user, $opID, $tipo, $estado, $fecha_inicio, $fecha_fin, $fecha_subida, $directorio)
									$opID = intval($codeConn->getLastOpID($user));
									//echo "Last operation value: ".$opID."<br>";
									$opID++;
									//echo "Incremented: ".$opID."<br>";
									$fecha_subida = self::getHoraActual();

									$codeConn->addCodeOperation($user, $opID, "subido", '', '', $fecha_subida, $extract_path);


									//Ask for usr priority
									$usrConn = new UsrConnection();
									$priority = $usrConn->getUserPriority($usrData["uid"]);
									echo $usrData["uid"].":".$usrData["gidnumber"]." prority --> ".$priority."<br/>";

									//TODO Call script to move code and compile it
									//Call with necessary params: usr, email, priority, type...		

									//Recibe el usuario (sistema), nombre_carpeta_proyecto, email_usr, tipo_code (cpu/gpu), tipo_paralelismo (mpi/otro), prioridad, n nodos
									$output=[];
									//echo "User that execes this is: ";
									//echo shel_exec("set")."</br>";
									//echo "Moving files...";
									//echo exec("/export/scripts/compile/movedata.sh ".$user." ".$name[0]." 2>&1 1> /dev/null", $output);
									//print_r($output);
									//echo "Moved?";
									switch($tipo) {
										case "mpi":
											echo "Compiling MPI code";
											//Script de MPI
											shell_exec("/export/scripts/compile/compileStdCode.sh "
													.$usrData['uid']
													." ".$name[0]
													." ".$usrData['mail']
													." 'cpu'"
													." 'mpi'"
													." ".$priority
													." ".$n_nodos
													." &> /dev/null &");

											break;
										case "cuda":
											echo "Compiling CUDA code";
											//Script de CUDA
											shell_exec("/export/scripts/compile/compileStdCode.sh "
													.$usrData['uid']
													." ".$name[0]
													." ".$usrData['mail']
													." 'gpu'"
													." 'other'"
													." ".$priority
													." ".$n_nodos
													." &> /dev/null &");							
											break;
										case "mpi-cuda":
											echo "Compiling MPI-CUDA code";
											shell_exec("/export/scripts/compile/compileStdCode.sh "
													.$usrData['uid']
													." ".$name[0]
													." ".$usrData['mail']
													." 'gpu'"
													." 'mpi'"
													." ".$priority
													." ".$n_nodos
													." &> /dev/null &");
											break;
										case "other-parallel":
											echo "Compiling other-parallel code";
											shell_exec("/export/scripts/compile/compileStdCode.sh "
													.$usrData['uid']
													." ".$name[0]
													." ".$usrData['mail']
													." 'cpu'"
													." 'other'"
													." ".$priority
													." ".$n_nodos
													." &> /dev/null &");
											break;
										case "no-parallel":
											echo "Compiling non-parallel code";
											//Script de non-parallel
											break;
									}


									//Add log
									$res = Log::addLog($usrData['uid'], "Se ha subido el trabajo $name[0]", 1);

									if(!$res) {
										echo "ERROR: No se ha podido poner el log<br>";
									}

									echo "Done!<br/>";
								}
								else {
									echo "El tipo no es valido.<br/>";

									//Add log
									Log::addLog($usrData['uid'], "ERROR: Se ha intentado subir un trabajo de tipo $tipo", 2);
								}

							} else {
								echo "The filesystem on the zip file is invalid. Remember that you have to compress at least the following: makefile & src, lib, include folders.";
								system('rm -rf ' . escapeshellarg($extract_path), $retval);
							}
							echo "<br />";
						}
					}
				}
			} else {
				echo $usrData;
				echo "<br/>";
			}
		}

		public static function updateCode($user, $operation) {
			
			$ldap = new LDAPConnection();
			$usrData = $ldap->buscar($user);

			if($usrData != "ERROR: No such user") { //No ha habido error

				//Comprobamos que la operacion existe y es updateable
				$codeConn = new CodeConnection();
				$state = $codeConn->getOperationState($user, $operation);
				$path = $codeConn->getOperationPath($user, $operation);

				if($state === "subido" || $state === "make_error" || $state === "make" || $state === "finished_with_errors") { //la operacion es updateable
					$success = false;

					//Trying to upload and unzip the file
					if($_FILES["zip_file"]["name"]) {
						$filename = $_FILES["zip_file"]["name"];
						$source = $_FILES["zip_file"]["tmp_name"];
						$type = $_FILES["zip_file"]["type"];

						$name = explode(".", $filename);
						
						if(!self::checkFileUploaded($filename, $type, $name)) {
							$message = "The file you are trying to upload is not a .zip file. Please try again.";
							//console($message, 1, 5);
						}
						else {
							$target_path = "uploads/".$filename; 
							$extract_path = $path;

							if(self::extractFile($filename, $name, $user, $source, $target_path, $extract_path)) { //If the file was upload and unzipped succesfully
								////////////
								// Escribimos fichero con los datos del cliente
								////////////
								//file_put_contents
								$parsedUserData = $usrData["uid"].":".$usrData["gidnumber"]." mailto --> ".$usrData["mail"];
								$dataFilePath = $extract_path."/datos.txt";
								file_put_contents($dataFilePath, $parsedUserData);

								if(self::checkFileSystem($extract_path)) {
									echo "The filesystem on the zip file is valid. ";
									
									//Here updating the BD
									echo "Updated ".self::getHoraActual()."\n";
									$codeConn->updateOperation($user, $operation, "subido", self::getHoraActual());

									
									//Ask for usr priority
									$usrConn = new UsrConnection();
									$priority = $usrConn->getUserPriority($usrData["gidnumber"]);
									echo $usrData["uid"].":".$usrData["gidnumber"]." prority --> ".$priority."<br/>";

									//TODO Call script to move code and compile it
									

								} else {
									echo "The filesystem on the zip file is invalid. Remember that you have to compress at least the following: makefile & src, lib, include folders.";
								}
								echo "<br/>";
							}
						}
					}

				} else {
					echo "Sorry, the operation ".$operation." is not updateable.<br>";
				}
			} else {
				echo $usrData."<br/>";
			}
		}

		public static function postCodeHome() {
			echo "To add new code, call to ordis/operation/code/add/[user] and upload the zip file in the podt body as \"zip_file\"<br>";
			echo "To update code, call to ordis/operation/code/update/[user]/[number of operation] and upload the zip file in the podt body as \"zip_file\"<br>";
		}

		public static function codeHome() {
			echo "To add new code, call to ordis/operation/code/add/[user] and upload the zip file in the podt body as \"zip_file\"<br>";
			echo "To update code, call to ordis/operation/code/update/[user]/[number of operation] and upload the zip file in the podt body as \"zip_file\"<br>";
		}

		public static function deleteCode($user, $opID) {

			$codeConn = new CodeConnection();
			$path = $codeConn->getOperationPath($user, $opID);

			if($path !== NULL) {

				system('rm -rf ' . escapeshellarg($path), $retval); //Delete folder
				$codeConn->deleteOperation($user, $opID);
				echo "Operation deleted.<br>";
			}
			else {
				echo "The operation is not in the system.<br>";
			}	
		}

		private static function checkFileUploaded($filename, $type, $name) {
			$accepted_types = array('application/zip', 'application/x-zip-compressed', 'multipart/x-zip', 'application/x-compressed');
			foreach($accepted_types as $mime_type) {
				if($mime_type == $type) {
					$okay = true;
					break;
				} 
			}
		
			$continue = strtolower($name[1]) == 'zip' ? true : false;

			return $continue;
		}

		private static function getHoraActual() {
			return date("Y-m-d H:i:s");
		}

		//Checks if the folder contains an src, lib, and include folder, plus a makefile
		private static function checkFileSystem($fileSystem) {
			echo "Testing if filesystem has all the neccessary...";
			echo "<br />";
			
			$content = scandir($fileSystem);
			$checking = 0;

			foreach ($content as $file) {
				if($file != "." && $file != "..") {
					//$path.'/'.$item
					if(is_dir($fileSystem."/".$file)) {
						echo "<br />";
						//It's a directory
						switch($file) {
							case "src":;
								$checking++;
								break;
							case "lib":
								$checking++;
								break;
							case "include":
								$checking++;
								break;
						}
					}
					else {
						if($file == "makefile" || $file == "Makefile") {
							$checking++;
						}
					}
				}
			}

			if($checking == 4) { //All 4 need items are there
				return true;
			}
			else {
				return false;
			}
		}
		
		private static function extractFile($filename, $name, $user, $source, $target_path, $extract_path) {
			$success = false;

			if(move_uploaded_file($source, $target_path)) {
				
				echo "Extracting path ".$extract_path;
				system('rm -rf ' . escapeshellarg($extract_path), $retval); //Delete folder, to override all
				mkdir($extract_path, 0770);
				chmod($extract_path, 0770);
				$zip = new ZipArchive();
				$x = $zip->open($target_path);
				if ($x === true) {
					$zip->extractTo($extract_path); 
					$zip->close();

					$message = "Sucess!";
					$success = true;
				}
				else {
					$message = "There was a problem with the upload. Please try again. File couldn't be uploaded to ".$target_path;
				}

				unlink($target_path); //We delete the file, even if there was an error
			}
			else {
				$message = "There was a problem with the upload. Please try again. File couldn't be uploaded to ".$target_path;
			}

			echo "Uploading and unzipping file ".$filename." to ".$target_path;
			echo "<br />";
			echo $message; //Last, we print the final message
			echo "<br />";

			return $success;
		}
	}

?>