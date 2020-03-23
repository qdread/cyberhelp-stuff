workflow run_hec {
  $script_names = "testcontrolscript","foo","bar","baz"
  foreach -parallel ($name in $script_names) { 
    InlineScript {
	  & "C:\Program Files (x86)\HEC\HEC-HMS\4.3\hec-hms.cmd" -s "Z:\scripts\$($name).script" # Z: should be mapped to /nfs/scho-data/ 
	}
    "$($name) done" 
  }
}

run_hec
