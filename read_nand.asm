ISFS_Init();
r4 = len
r3 = ISFS_Open("/0.rkg", 1)
r5 = malloc(r4, 32, 0)
ISFS_Read(r3, r5, r4);
ISFS_Close();