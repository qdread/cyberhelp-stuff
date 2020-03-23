workflow work {
  foreach -parallel ($i in 1..3) { 
    sleep 5 
    "$i done" 
  }
}

work
