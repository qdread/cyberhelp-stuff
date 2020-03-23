$script_names = "foo","bar","baz"

workflow run_hec {
  cd "C:\Program Files (x86)\HEC\HEC-HMS\4.3"
  foreach -parallel ($name in $script_names) { 
    hec-hms.cmd –s "Z:\scripts\$($name).script" # Z: should be mapped to /nfs/scho-data/ 
    "$($name) done" 
  }
}

run_hec
