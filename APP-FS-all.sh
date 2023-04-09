diskz() {
read -p "Enter no.of disks and disk names without count of swap disk Example: 3 sdc sdd sde:" -a disk
read -p "Enter VG Names of ${disk[0]} disks with space:" -a VG
for (( i=0,v=0,c=0; i<${disk[0]}; i++,v++,c++ ));
do
read -p "Enter LV's  Names of ${VG[v]} with space Example: lv_var lv_product etc:" -a LV$c
read -p "Enter size of LV's for ${VG[v]} with space  Example:10 20 30:" -a SIZE$c
read -p "Enter mount of LV's for ${VG[v]} with space Example:/var /product /free_sod:" -a MOUNT$c
done
count=0
## First VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[1]}
pvcreate /dev/$d
vgcreate $v /dev/$d
for (( i=0; i<${#LV0[@]}; i++ ));do
s=${SIZE0[i]}G
n=${LV0[i]}
m=${MOUNT0[i]}
lvcreate -L +$s -n $n $v
mkfs.xfs /dev/$v/$n &
sleep 2
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
done
fi
count=$((count+1))
## Second VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[2]}
pvcreate /dev/$d
vgcreate $v /dev/$d
for (( i=0; i<${#LV1[@]}; i++ ));do
s=${SIZE1[i]}G
n=${LV1[i]}
m=${MOUNT1[i]}
lvcreate -L +$s -n $n $v
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
done
fi
count=$((count+1))
## Third VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[3]}
pvcreate /dev/$d
vgcreate $v /dev/$d
for (( i=0; i<${#LV2[@]}; i++ ));do
s=${SIZE2[i]}G
n=${LV2[i]}
m=${MOUNT2[i]}
lvcreate -L +$s -n $n $v
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
done
fi
count=$((count+1))
## Fourth VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[4]}
pvcreate /dev/$d
vgcreate $v /dev/$d
for (( i=0; i<${#LV3[@]}; i++ ));do
s=${SIZE3[i]}G
n=${LV3[i]}
m=${MOUNT3[i]}
lvcreate -L +$s -n $n $v
sleep 1
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
done
fi
count=$((count+1))
## Fifth VG Starts
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[5]}
pvcreate /dev/$d
vgcreate $v /dev/$d
for (( i=0; i<${#LV4[@]}; i++ ));do
s=${SIZE4[i]}G
n=${LV4[i]}
m=${MOUNT4[i]}
lvcreate -L +$s -n $n $v
sleep 1
mkfs.xfs /dev/$v/$n &
sleep 1
mkdir -p $m
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/$v/$n)       $m      xfs     defaults        0 0
EOF
done
fi
menu
}
wipez(){
count=0
## First VG Remove
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[1]}
for (( i=0; i<${#LV0[@]}; i++ ));do
n=${LV0[i]}
m=${MOUNT0[i]}
umount -f $m
lvremove /dev/$v/$n -y
sed -i '/\$m/d' /etc/fstab
rm -rf $m
done
vgremove $v -y
pvremove /dev/$d
fi
count=$((count+1))

## Second  VG remove
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[2]}
for (( i=0; i<${#LV1[@]}; i++ ));do
n=${LV1[i]}
m=${MOUNT1[i]}
umount -f $m
lvremove /dev/$v/$n -y
sed -i '/\$m/d' /etc/fstab
rm -rf $m
done
vgremove $v -y
pvremove /dev/$d
fi
count=$((count+1))

## Third VG Remove
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[3]}
for (( i=0; i<${#LV2[@]}; i++ ));do
n=${LV2[i]}
m=${MOUNT2[i]}
umount -f $m
lvremove /dev/$v/$n -y
sed -i '/\$m/d' /etc/fstab
rm -rf $m
done
vgremove $v -y
pvremove /dev/$d
fi
count=$((count+1))

## Fourth VG Remove
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[4]}
for (( i=0; i<${#LV3[@]}; i++ ));do
n=${LV3[i]}
m=${MOUNT3[i]}
umount -f $m
lvremove /dev/$v/$n -y
sed -i '/\$m/d' /etc/fstab
rm -rf $m
done
vgremove $v -y
pvremove /dev/$d
fi
count=$((count+1))

## Fifth VG Remove
if [ $count -lt ${disk[0]} ]
then
v=${VG[$count]};d=${disk[5]}
for (( i=0; i<${#LV4[@]}; i++ ));do
n=${LV4[i]}
m=${MOUNT4[i]}
umount -f $m
lvremove /dev/$v/$n -y
sed -i '/\$m/d' /etc/fstab
rm -rf $m
done
vgremove $v -y
pvremove /dev/$d
fi
#for i in ${VG[@]}; do
#vgremove $i -y
#done
#for (( i=1; i<=${#disk[@]}; i++ ));do
#dd=${disk[i]}
#pvremove /dev/$dd
#done
menu
}

swapz() {
read -p  "Enter the swap disk name Example:sdb :" swp
pvcreate /dev/$swp
vgcreate vgswap /dev/$swp
lvcreate -l 100%FREE -n lvswap vgswap
mkswap /dev/vgswap/lvswap
swapon /dev/vgswap/lvswap
cat <<EOF >> /etc/fstab
UUID=$(blkid -s UUID -o value /dev/vgswap/lvswap)       swap      swap     defaults        0 0
EOF
menu
}
wipez() {


    
}

menu(){
echo "Enter your choice"
echo "1. VG, LV creation for Disks"
echo "2. Swap creation"
echo "3. Wipe the VG,LV on all disks"
echo "4. Exit"
read answer
case $answer in
 1) diskz;;
 2) swapz;;
 3) wipez;;
 4) exit 1  ;;
 *)
    echo "Incorrect Entry:"
    menu;;
esac
}

menu
