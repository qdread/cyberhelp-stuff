

workflow run_hec {
  $script_names = "foo","bar","baz"
  #cd "C:\Users\qread\Documents"
  foreach -parallel ($name in $script_names) { 
    echo "Z:\scripts\$($name).script" # Z: should be mapped to /nfs/scho-data/ 
    echo "$name done" 
  }
}

run_hec
