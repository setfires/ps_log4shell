# ps_log4shell
PowerShell script to search PCs for all log4j* existinance and locations

Copy repository to a directory.

Edit ou.txt with your target OU.

Edit prefix.txt with what you want the logs (results) prefixed with.

For first run, create a file named first.txt
If first.txt exists, running 100.ps1 will create the reports directory, the succesfull log, the error log, the ongoing client list file, the list of PCs that probably need PSRemoting enabled.
After the first run and generating initial lists, rename first.txt to update.txt to append to the successful log or rename first.txt to new.txt to create new successful log every run.

The process will start a job on each PC in the list (initially from AD) searching for the referenced files. If the job is successfull, it updates the success log and doesn't add the client to the ongoing scans. If the scan fails, it will add that client to the generated clients list for re-scan after he issue is remediated. A successful subsequent scan will purge the client from the ongoing list to re-scan.

The failure descriptions are specific to my environment (anonomized in this draft) and you should edit/remove/add to suit your environment.
