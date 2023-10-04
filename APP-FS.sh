swp=sdb
disk=(3 sdc sdd sde) 
VG=(vg_tools vg_tools_sap vg_sap_P8P)
LV0=(lv_tools)
SIZE0=(990M)
MOUNT0=(/lv_tools)
LV1=(lv_avantra lv_usrsap_DAA lv_usrsap_hostctrl)
SIZE1=(5G 4G 5G)
MOUNT1=(/opt/avantra /usr/sap/DAA /usr/sap/hostctrl)
LV2=(lv_usrsap lv_usrsap_P8P lv_coredumps_P8P lv_usrsap_P8P_audit)
SIZE2=(6G 50G 20G 20G)
MOUNT2=(/usr/sap /usr/sap/P8P /usr/sap/P8P/core-dumps /usr/sap/P8P/audit)



diskz() {
#read -p "$(tput setaf 5)Enter no.of disks and disk names without swap disk $(tput setaf 6)Example: 3 sdc sdd sde:$(tput sgr 0)" -a disk
#read -p "$(tput setaf 5)Enter VG Names of $(tput setaf 6)${disk[0]} $(tput setaf 5)disks with space $(tput setaf 6)Example: vgbin datavg:$(tput sgr 0)" -a VG
#for (( i=0,v=0,c=0; i<${disk[0]}; i++,v++,c++ ));
#do
#read -p "$(tput setaf 5)Enter LV's  Names of $(tput setaf 6)${VG[v]} $(tput setaf 5)with space $(tput setaf 6)Example: lvsplunk lvtivoli etc:$(tput sgr 0)" -a LV$c
#read -p "$(tput setaf 5)Enter size of LV's for $(tput setaf 6)${VG[v]} $(tput setaf 5)with space  $(tput setaf 6)Example:10 20 30:$(tput sgr 0)" -a SIZE$c
#read -p "$(tput setaf 5)Enter mount of LV's for $(tput setaf 6)${VG[v]} $(tput setaf 5)with space $(tput setaf 6)Example:/splunk /tivoli:$(tput sgr 0)" -a MOUNT$c
#done
count=0
## First VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[1]}
echo "$(tput setaf 1) =====  PV $d and VG $v CREATION STARTED ===== $(tput sgr 0)"
pvcreate /dev/$d
vgcreate $v /dev/$d
echo "$(tput setaf 2) =====  PV $d and VG $v CREATION DONE ===== $(tput sgr 0)"
for (( i=0; i<${#LV0[@]}; i++ ));do
s=${SIZE0[i]}
n=${LV0[i]}
m=${MOUNT0[i]}
echo "$(tput setaf 1) =====  LV $n CREATION STARTED ===== $(tput sgr 0)"
lvcreate -L +$s -n $n $v
mkfs.xfs /dev/$v/$n &
sleep 2
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults      0 0
EOF
echo "$(tput setaf 2) ===== LV $n  CREATED and MOUNTED SUCESSFULLY DONE ===== $(tput sgr 0)"
done
fi
count=$((count+1))
## Second VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[2]}
echo "$(tput setaf 1) =====  PV $d and VG $v CREATION STARTED ===== $(tput sgr 0)"
pvcreate /dev/$d
vgcreate $v /dev/$d
echo "$(tput setaf 2) =====  PV $d and VG $v CREATION DONE ===== $(tput sgr 0)"
for (( i=0; i<${#LV1[@]}; i++ ));do
s=${SIZE1[i]}
n=${LV1[i]}
m=${MOUNT1[i]}
echo "$(tput setaf 1) =====  LV $n CREATION STARTED ===== $(tput sgr 0)"
lvcreate -L +$s -n $n $v
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
echo "$(tput setaf 2) ===== LV $n CREATED and MOUNTED SUCESSFULLY DONE ===== $(tput sgr 0)"
done
fi
count=$((count+1))
## Third VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[3]}
echo "$(tput setaf 1) =====  PV $d and VG $v CREATION STARTED ===== $(tput sgr 0)"
pvcreate /dev/$d
vgcreate $v /dev/$d
echo "$(tput setaf 2) =====  PV $d and VG $v CREATION DONE ===== $(tput sgr 0)"
for (( i=0; i<${#LV2[@]}; i++ ));do
s=${SIZE2[i]}
n=${LV2[i]}
m=${MOUNT2[i]}
echo "$(tput setaf 1) =====  LV $n CREATION STARTED ===== $(tput sgr 0)"
lvcreate -L +$s -n $n $v
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
echo "$(tput setaf 2) ===== LV $n CREATED and MOUNTED SUCESSFULLY DONE ===== $(tput sgr 0)"
done
fi
count=$((count+1))
## Fourth VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[4]}
echo "$(tput setaf 1) =====  PV $d and VG $v CREATION STARTED ===== $(tput sgr 0)"
pvcreate /dev/$d
vgcreate $v /dev/$d
echo "$(tput setaf 2) =====  PV $d and VG $v CREATION DONE ===== $(tput sgr 0)"
for (( i=0; i<${#LV3[@]}; i++ ));do
s=${SIZE3[i]}
n=${LV3[i]}
m=${MOUNT3[i]}
echo "$(tput setaf 1) =====  LV $n CREATION STARTED ===== $(tput sgr 0)"
lvcreate -L +$s -n $n $v
sleep 1
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
echo "$(tput setaf 2) ===== LV $n CREATED and MOUNTED SUCESSFULLY DONE ===== $(tput sgr 0)"
done
fi
count=$((count+1))
## Fifth VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[5]}
echo "$(tput setaf 1) =====  PV $d and VG $v CREATION STARTED ===== $(tput sgr 0)"
pvcreate /dev/$d
vgcreate $v /dev/$d
echo "$(tput setaf 2) =====  PV $d and VG $v CREATION DONE ===== $(tput sgr 0)"
for (( i=0; i<${#LV4[@]}; i++ ));do
s=${SIZE4[i]}
n=${LV4[i]}
m=${MOUNT4[i]}
echo "$(tput setaf 1) =====  LV $n CREATION STARTED ===== $(tput sgr 0)"
lvcreate -L +$s -n $n $v
sleep 1
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
echo "$(tput setaf 2) ===== LV $n CREATED and MOUNTED SUCESSFULLY DONE ===== $(tput sgr 0)"
done
fi
menu
}
swapz() {
#read -p  "$(tput setaf 5)Enter the swap disk name $(tput setaf 6)Example:sdb:$(tput sgr 0)" swp
#echo "$(tput setaf 1) =====  SWAP $swp CREATION STARTED ===== $(tput sgr 0)"
pvcreate /dev/$swp
vgcreate vgswap /dev/$swp
lvcreate -l 100%FREE -n lvswap vgswap
mkswap /dev/vgswap/lvswap
swapon /dev/vgswap/lvswap
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/vgswap/lvswap)   swap    swap    defaults    0   0
EOF
echo "$(tput setaf 2) ===== SWAP $swp CREATED and MOUNTED SUCESSFULLY DONE ===== $(tput sgr 0)"
menu
}

menu(){
echo "$(tput setaf 3)====Enter your choice====$(tput sgr 0)"
echo "$(tput setaf 3)1. VG, LV creation for Disks$(tput sgr 0)"
echo "$(tput setaf 3)2. Swap creation$(tput sgr 0)"
echo "$(tput setaf 3)3. Wipe the VG,LV on all disks$(tput sgr 0)"
echo "$(tput setaf 3)4. Exit$(tput sgr 0)"
read answer
case $answer in
 1) diskz;;
 2) swapz;;
 3) wipez;;
 4) exit 1  ;;
 *)
    echo "$(tput setaf 1)Incorrect Entry:$(tput sgr 0)"
    menu;;
esac
}

menu