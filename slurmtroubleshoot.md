# Rebooting Slurm node instructions

`scontrol show node nodename` to see its status.

If node is drained, `sudo scontrol update NodeName=nodename State=down Reason=undrain`

Then `sudo scontrol update NodeName=nodename State=resume` or `State=idle`.

If node is down:

`ping nodename` to see if it can respond.

You can try `sudo scontrol update NodeName=nodename State=resume` but it may not work. 

To reboot the node, `ssh nodename` then login as root with `sudo -i`, then stop and start slurm as follows:

```
/usr/sbin/slurmd stop
/usr/sbin/slurmd startclean
```



