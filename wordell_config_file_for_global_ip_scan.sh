#!/bin/bash

# Hey you! Yes you, dont mess with this file if you dont understand the following shell code.
# The Wordell script needs to use it to execute a global IP scan for the flag '-g'
# So dont mess with this script or else Wordell's '-g' flag option wont work.

for ip_range in {1..1000}; do
	ips=$(printf "%d.%d.%d.%d\n" "$((RANDOM % 256 ))" "$((RANDOM % 256 ))" "$((RANDOM % 256 ))" "$((RANDOM % 256 ))")
	ping -c 1 "$ips" | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" &
done
