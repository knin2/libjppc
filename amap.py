from os import system as cmd
lines = open("pal.amap", "r").readlines()
addresses = [l.split(":")[1].replace("\n", "").strip() for l in lines]
funcs = [l.split(":")[0].replace("\n", "").strip() for l in lines]
usa_addresses = dict()
i = 0
la = len(lines)
for addr in addresses:
	com = f"CMD.exe /c wstrt port {addr} > add.txt"
	cmd(com)
	al = open("add.txt", "r").readlines()
	usa_addr = al[4][14:22]
	usa_addresses[funcs[i]] = usa_addr
	i += 1
	print(f"{i} / {la}")
import json
open("usa_amap.json", "w").write(json.dumps(usa_addresses, indent = 4))

